# ApexKube Agent Helm Chart

A Helm chart for deploying the ApexKube agent: one container that brings up the WireGuard tunnel
and then runs the Envoy proxy.

## Overview

This chart deploys:

- **Agent** — single container running WireGuard (tunnel) and Envoy (JWT authentication, TLS termination)
- **RBAC** — ServiceAccount, ClusterRole, and ClusterRoleBinding

## Deployment profiles

One release can run one or two agents from the same image. They differ only in Envoy's
listener/upstream settings and in their WireGuard identity.

| | `access` | `metrics` |
|---|---|---|
| Default | on | off |
| Downstream listener | TLS, certificate from `tls.*` | plain HTTP |
| Client auth | JWT verified against `envoy.config.jwt.publicKey` | none |
| Upstream | `kubernetes.default.svc:443`, TLS | `metrics.envoy.backend` (default `thanos-receive:10908`), plain HTTP |
| Service account token | injected as `Authorization: Bearer` | not injected, not mounted |
| Cluster-wide RBAC | ClusterRole + binding | none |
| Resources | `envoy.resources` (64Mi/50m → 128Mi/100m) | `metrics.resources` (128Mi/100m → 256Mi/500m) |

Defaults deploy the access agent exactly as chart 2.0.0 did, so existing installs need
no values change.

### Adding a metrics agent

Set `metrics.enabled: true` and give it a WireGuard identity of its own:

```yaml
metrics:
  enabled: true
  wireguard:
    existingSecret: metrics-wireguard-privatekey
  envoy:
    backend:
      host: thanos-receive
      port: 10908
```

That renders a second Deployment `<fullname>-metrics` next to the access one, with its
own ServiceAccount, envoy ConfigMap, WireGuard ConfigMap and private-key Secret:

```
WireGuard server
├── peer A → <fullname>          : wg0, envoy TLS + JWT + SA token → kubernetes.default.svc:443
└── peer B → <fullname>-metrics  : wg0, envoy plain HTTP           → thanos-receive:10908
```

The tunnel lives inside the pod, so isolation is real: a scrape flood only consumes the
metrics pod's CPU and memory limits and never shares the access tunnel's queues. The
metrics pod carries no service account token and no cluster-wide RBAC, so it cannot reach
the Kubernetes API even if the tunnel were mis-scoped.

Requirements:

- **A dedicated WireGuard peer for the metrics agent** — its own key pair and tunnel
  address (`metrics.wireguard.config.*`, or `metrics.wireguard.existingSecret` /
  `existingConfigMap`). Two agents sharing a key or address will collide.
- **Scope that peer's `AllowedIPs` server-side** to the Thanos endpoint only.
- Do not raise `metrics.replicas` above 1 unless each replica gets its own identity:
  replicas share the configured key and address.

`metrics.envoy.config` is merged over `envoy.config`, so set only the timeouts or retries
that should differ, for example `metrics.envoy.config.routeTimeout: 5s`.

### Metrics-only install

For a cluster that should run a metrics agent and no access agent, ship
`values-metrics.yaml` (or set the two toggles yourself):

```bash
helm upgrade --install apexkube-agent improwised/apexkube-agent \
  -n apexkube-metrics -f values-metrics.yaml
```

```yaml
access:
  enabled: false
metrics:
  enabled: true
```

At least one of the two must be enabled; the chart fails to render otherwise.

### Tuning the access agent

The access agent keeps the keys it always had. `envoy.tls.enabled`,
`envoy.jwt.enabled`, `envoy.injectServiceAccountToken`, `envoy.backend.*` and
`envoy.backend.tls.enabled` let a single-pod install point somewhere else, for example a
small cluster that only needs one agent in front of a plain-HTTP backend. Disabling
`envoy.tls.enabled` also drops the certificate Secret and its volume mount; disabling
`envoy.injectServiceAccountToken` sets `automountServiceAccountToken: false`.

## Installation


### Quick Start (Development)

```bash
helm install apexkube-agent ./charts/apexkube-agent -f values.yaml
```

### Production Installation

1. Create WireGuard ConfigMap and Secret:

```bash
kubectl apply -f wireguard-config.yaml
kubectl apply -f wireguard-secret.yaml
```

2. Install with existing resources:

```bash
helm install apexkube-agent ./charts/apexkube-agent \
  --set wireguard.existingConfigMap=wireguard-config \
  --set wireguard.existingSecret=wireguard-privatekey
```

## Upgrading from 1.x

Chart 2.0.0 ships one container (`agent`) built from the public image
`improwised/apexkube-agent`, replacing the separate `envoy` and `wireguard` containers.
This is a breaking change for chart values.

| 1.x key | 2.x |
|---|---|
| `envoy.image.*`, `wireguard.image.*` | `image.*` (one combined image) |
| `wireguard.securityContext.*` | `securityContext.*` (only `NET_ADMIN`; `privileged` is no longer needed) |
| `wireguard.resources.*` | `envoy.resources.*` — one container now runs both, so size for the sum |
| `wireguard.healthcheck.*` | removed — readiness now checks the WireGuard handshake age |
| `wireguard.env` | removed (no equivalent) |
| `kubectl logs -c envoy` / `-c wireguard` | `kubectl logs -c agent` |

`wireguard.config`, `wireguard.existingConfigMap`, `wireguard.existingSecret`, `envoy.config`,
`envoy.replicas`, `envoy.resources`, `tls.*` and the RBAC keys are unchanged.

Upgrading an existing 1.x release with `--reuse-values` is not supported, because the 1.x release
values have no `image` key:

```
Error: UPGRADE FAILED: ... at <.Values.image.repository>: nil pointer evaluating interface {}.repository
```

`--set image=null` or `--set readinessProbe=null` fail the same way. Pass the values file explicitly
instead:

```bash
helm upgrade apexkube-agent ./charts/apexkube-agent -n apexkube-agent -f my-values.yaml
```

## Rollouts and Configuration Drift

The pod template carries `checksum/*` annotations for the ConfigMaps and Secrets this chart renders,
so changing `wireguard.config`, `wireguard.privateKey`, `envoy.config` or `tls.certData` rolls the pod.

Two cases have no checksum, because the resource is not rendered by the chart:

- `wireguard.existingConfigMap`, `wireguard.existingSecret`, `tls.existingSecret`
- any ConfigMap or Secret written by Vault, External Secrets, Sealed Secrets or `kubectl apply`

All data mounts use `subPath`, and Kubernetes never propagates updates through a `subPath` mount, so
edits to those resources do not reach a running pod. Restart the pod explicitly:

```bash
kubectl rollout restart deployment/apexkube-agent -n apexkube-agent
```

With `existing*` resources the checksums are constant for every install, so nothing else triggers a
rollout. Set `podAnnotations` to attach a [Reloader](https://github.com/stakater/Reloader)
annotation if those resources are managed outside Helm.

## Configuration

### WireGuard Configuration

#### Option 1: Inline Configuration (Development)

```yaml
wireguard:
  config:
    address: "192.168.10.2"
    privateKey: "<example-private-key>"
    peer:
      publicKey: "<example-public-key>"
      endpoint: "wireguard.example.com"
      allowedIPs: "192.168.10.1"
      persistentKeepalive: 5
```

**Warning**: Not secure for production. Private keys stored in values files may be committed to Git.

#### Endpoint Resolution

The endpoint is resolved inside the agent pod, using the cluster's DNS. When it is a hostname,
every cluster running an agent must resolve it to the gateway's WireGuard address, otherwise
`wg-quick` brings up an interface whose handshake never completes.

k3s generates the `NodeHosts` block of `kube-system/coredns` from node names; extra entries are
added by hand. On hydra11:

```
10.20.1.100 management-dev.pride.improwised.dev
```

Confirm with `wg show wg0` in the pod: `latest handshake` must be recent and `transfer` must show
bytes received. A tunnel stuck at `0 B received` means the endpoint resolved somewhere that does
not serve UDP on the WireGuard port.

`wg-quick` resolves the endpoint hostname once, when it configures the peer. Changing the DNS entry
or the gateway address therefore needs an explicit `kubectl rollout restart` — nothing in the chart
restarts the pod on a DNS change.

#### When the tunnel is down

A wrong-but-resolvable endpoint, a stopped gateway or a rejected key all let `wg-quick` succeed (the
endpoint is only stored), while the handshake never completes. Envoy keeps listening, so the pod
stays `Running` but `NotReady`, with no restart and no Kubernetes event — the readiness probe is the
handshake check. Diagnose with:

```bash
kubectl exec deploy/apexkube-agent -c agent -- wg show wg0
```

Readiness also needs `persistentKeepalive` greater than 0 on the peer (the default is 5); without it
an idle tunnel stops handshaking and the pod goes `NotReady`. For `existingConfigMap`, that
guarantee is yours to keep.

#### Option 2: Existing Resources (Production - Recommended)

**Step 1**: Create ConfigMap (`wireguard-config.yaml`):

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: wireguard-config
  namespace: apexkube-agent
data:
  wg0.conf: |
    [Interface]
    Address = 192.168.10.2

    [Peer]
    PublicKey = <example-public-key>
    Endpoint = wireguard.example.com
    AllowedIPs = 192.168.10.1
    PersistentKeepalive = 5
```

**Step 2**: Create Secret (`wireguard-secret.yaml`):

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: wireguard-privatekey
  namespace: apexkube-agent
type: Opaque
stringData:
  privatekey: <example-private-key>
```

**Step 3**: Apply and install:

```bash
kubectl apply -f wireguard-config.yaml
kubectl apply -f wireguard-secret.yaml

helm install apexkube-agent ./charts/apexkube-agent \
  --set wireguard.existingConfigMap=wireguard-config \
  --set wireguard.existingSecret=wireguard-privatekey
```

### Priority Order

- `existingConfigMap` overrides inline `config` values
- `existingSecret` overrides inline `privateKey`
- `tls.existingSecret` overrides `tls.certData`

## Security Best Practices

1. **Use existingSecret for production** - Never commit private keys to Git
2. **Separate sensitive and non-sensitive data** - ConfigMaps for config, Secrets for keys
3. **Use external secret management** - Integrate with Vault, SealedSecrets, or External Secrets Operator
4. **Apply RBAC** - Control access to secrets
5. **Encrypt secrets at rest** - Enable Kubernetes secret encryption

### Runtime requirements

The agent container needs `CAP_NET_ADMIN` to create the tunnel interface, and it runs as root (the
image sets no `USER`). `NET_ADMIN` is not in the set of capabilities the `baseline` Pod Security
Standard allows, so the namespace must not enforce `baseline` or `restricted`.

`wg-quick` uses the in-tree kernel WireGuard module when the node has one (`/sys/module/wireguard`).
On a node without it the image falls back to `wireguard-go`
(`WG_QUICK_USERSPACE_IMPLEMENTATION`), which needs `/dev/net/tun`; the image does not contain that
device and the chart does not mount it, so such nodes are not supported.

## Common Operations

### Upgrade Configuration

```bash
kubectl apply -f wireguard-config.yaml
helm upgrade apexkube-agent ./charts/apexkube-agent
```

### View Generated Manifests

```bash
helm template apexkube-agent ./charts/apexkube-agent -f values.yaml
```

### Validate Configuration

```bash
helm lint ./charts/apexkube-agent
```

### Uninstall

```bash
helm uninstall apexkube-agent
```
