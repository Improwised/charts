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
