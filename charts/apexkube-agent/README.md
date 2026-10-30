# ApexKube Agent Helm Chart

A Helm chart for deploying the ApexKube agent with Envoy proxy and WireGuard VPN.

## Overview

This chart deploys:

- **Envoy**: Proxy with JWT authentication and TLS termination
- **WireGuard**: VPN client for secure communication
- **RBAC**: ServiceAccount, ClusterRole, and ClusterRoleBinding

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
| `wireguard.resources.*` | `envoy.resources.*` |
| `wireguard.healthcheck.*` | removed — readiness now checks the WireGuard handshake age |
| `wireguard.env` | removed (no equivalent) |

`wireguard.config`, `wireguard.existingConfigMap`, `wireguard.existingSecret`, `envoy.config`,
`envoy.replicas`, `envoy.resources`, `tls.*` and the RBAC keys are unchanged.

Upgrading an existing 1.x release with `--reuse-values` fails, because the 1.x release values have
no `image` key:

```
Error: UPGRADE FAILED: ... at <.Values.image.repository>: nil pointer evaluating interface {}.repository
```

Pass the values file explicitly instead:

```bash
helm upgrade apexkube-agent ./charts/apexkube-agent -n apexkube-agent -f my-values.yaml
```

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
