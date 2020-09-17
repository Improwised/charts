# n8n-helm chart:chart_with_upwards_trend:
----

![n8n.io - Workflow Automation](https://raw.githubusercontent.com/n8n-io/n8n/master/assets/n8n-logo.png)

[n8n](https://n8n.io/) is an extendable workflow automation tool. With a fair-code distribution model, n8n will always have visible source code, be available to self-host, and allow you to add your own custom functions, logic and apps. n8n's node-based approach makes it highly versatile, enabling you to connect anything to everything. this is unofficial helm chart of n8n

----
## Prerequisites
- Kubernetes 1.12+
- Helm 3.0+
- PV provisioner support in the underlying infrastructure
- ----
## Installing the Chart

To install the chart with the release name `myn8n`:
```sh
$ git clone https://github.com/n8n-helm/n8n-helm.git
$ helm install myn8n ./n8n-helm
# to test chart
$ helm test myn8n
```

These commands deploy n8n on the Kubernetes cluster in the default configuration.

> **Tip**: List all releases using `helm list`
----
## Uninstalling the Chart

To uninstall/delete the `myn8n` deployment:

```bash
$ helm delete myn8n
```

The command removes all the Kubernetes components associated with the chart and deletes the release.

> **note**: Deleting the release will delete attached PVC containing n8n encryption key. Please be cautious before doing it.

----
## Parameters

The following tables lists the configurable parameters of the NGINX Open Source chart and their default values.

| Parameter| Description| Default|
|--------------------------------------------|----------------------------------------------------------------------------------------------|-----------------------------------------------------------|
| `global.imageRegistry` | Global Docker image registry | haha |
| `image.repository` | n8n Image | `n8nio/n8n` | 
| `image.restartPolicy` | n8n Image restart policy | `Always` | 
| `image.pullPolicy` | n8n Image pull policy | `IfNotPresent` | 
| `image.tag` | tag of Image | `latest` | 
| `nameOverride` | String to partially override n8n.fullname template with a string (will prepend the release name) | `nil` | 
| `fullnameOverride` | String to fully override postgresql.fullname template with a string | `nil` |
| `commonannotations` | Annotations that will added to all the Kubernetes objects | `{}`(evaluated as a template) | 
| `atuh.enabled` | Enbale basic authentication | `false` |
| `atuh.n8nAuthUsername`| Basuc Auth username | `nil` |
| `atuh.n8nAuthPass`| Basuc Auth password | `nil` |
| `existingSecret`| Name of an existing secrets | `nil` |
| `networkPolicy.enabled`| creation of NetworkPolicy | `false` |
| `networkPolicy.explicitNamespacesSelector`| Explicitly Namespaces for Network policy | `{}`(evaluated as a template) |
| `service.type` | Kubernetes Service type | `ClusterIP` |
| `service.port` | n8n port | `5678` |
| `service.annotations` | Annotations for n8n service | `{}`(evaluated as a template) |
| `testFramework.enabled` | enable n8n connection test | `true` |
| `persistence.enabled` | Enable persistence using PVC | `true` |
| `persistence.mountPath` | Path to mount the volume at | `/mnt/n8n/.n8n` |
| `persistence.accessModes` | PVC Access Mode for n8n volume | `[ReadWriteOnce]` |
| `persistence.size` | PVC Storage Request for n8n volume | `2Gi` |
| `ingress.enabled` | Switch to create ingress for n8n deployment | `true` |
| `ingress.hostname` | hostname for ingress | `nil` |
| `ingress.tls` | TLS for ingress | `[]`(evaluated as a template) |
| `ingress.tls.hosts[]` | Array of TLS hosts for ingress record  | `[]` |
| `ingress.tls.secretName` | TLS secret name | `n8n.local-tls` |
| `ingress.annotations` | Ingress annotations | `{}`(evaluated as a template) |
| `ingress.certManager` | Annotations for cert-manager | `true` |
| `ingress.secrets[]` | Provide own certificates | `nil` |
| `ingress.secrets[].name` | TLS Secret Name | `nil` |
| `ingress.secrets[].key` | TLS Secret Key  | `nil` |
| `ingress.secrets[].certificate` | TLS Secret Name Certificate | `nil` |
| `resources` | 'CPU/Memory resource requests/limits' | Memory: `500Mi`, CPU: `500Mi`(evaluated as a template) |
| `schedulerName` | Name of the k8s scheduler (other than default) | `nil` |
| `nodeSelector` | Node labels for pod assignment for n8n deployment | `{}`(evaluated as a template) |
| `affinity` | Affinity labels for pod assignment for n8n deployment | `{}`(evaluated as a template) |
| `tolerations` | Toleration labels for pod assignment for n8n deployment | `[]` (evaluated as a template) |
| `livenessProbe` | livenessProbe for n8n deployment | `{}`(evaluated as a template) |
| `readinessProbe` | readinessProbe for n8n deployment | `{}`(evaluated as a template) |
| `postgresql.testFramework.enabled` | enable postgres connection test | `true` |
| `postgresql.enabled` | (override) enable or disable postgress | `true` |
| `postgresql.postgresqlUsername` | (override) Postgresql default username | `nodemation` |
| `postgresql.postgresqlDatabase` | (override) Postgresql default database | `nodemation` |
| `postgresql.postgresqlPassword` | (override) Postgresql default password for username | `nodemation` |


Specify each parameter using the `--set key=value[,key=value]` argument to `helm install`. For example,

```bash
$ helm install myn8n \
  --set imagePullPolicy=Always \
    ./n8n-helm
```

The above command sets the `imagePullPolicy` to `Always`.

Alternatively, a YAML file that specifies the values for the parameters can be provided while installing the chart. For example,

```bash
$ helm install myn8n -f values.yaml ./n8n-helm
```

> **Tip**: You can use the default [values.yaml](values.yaml) or override your own values.yaml
----