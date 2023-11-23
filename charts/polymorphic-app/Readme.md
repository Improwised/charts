# Polymorphic Application Chart

This chart provides an abstraction layer over Kubernetes resources to easily represent wide ranges of different cloud-native applications. It is designed to be very flexible and can be used to various configurations. The primary aim for this chart is to make it easy to deploy and maintain cloud native applications on top of Kubernetes.

This chart is ideal for deploying applications that support polymorphic container pattern. A polymorphic container has multiple entrypoints and behaves differently depending on the entrypoint. This is particularly useful in creating event-driven monolithic applications, where some of the codebase (interfaces etc.) is shared, and the application needs to have multiple, independently scalable "workers" that process these events.

## Features

* Supports the following kind of deployments:
  * API: Consists of a kubernetes `Deployment`, `Service`, and optionally `Ingress` and `HorizontalPodAutoscaler`. Typically used to deploy REST/gRPC API services.
  * Worker: Consists of a kubernetes `Deployment` and optionally a `HorizontalPodAutoscaler`. Typically used to deploy long-running services that are not consumed through a TCP/HTTP server. e.g. Queue Workers and Stream Processors
  * Jobs: Typically used to run one-off jobs, mostly helm hooks, to be run when installing/uninstalling/upgrading the helm deployment. Used to run database migrations by default. Backed by Kubernetes `Job`.
  * CronJobs: Typically used to run scheduled jobs. Used for triggering events and batch processing jobs at a regular interval. Backed by Kubernetes `CronJob`.
* Designed to be used with [Flux Helm Controller](https://github.com/fluxcd/helm-controller), [Helmfile](https://github.com/roboll/helmfile), and any other mechanism that is backed by helm values-file override.

## Prerequisites
- Kubernetes 1.19+
- Helm 3.8.0+

## Installing the Chart
To install the chart with the release name `my-release`:

    helm repo add improwised https://improwised.github.io/charts/
    helm install my-release improwised/polymorphic-app --values <your-value-file.yaml>

## Uninstalling the Chart
To uninstall/delete the `my-release` deployment:

    helm uninstall my-release

## Parameters

### Global Parameters

| Name | Description | Value |
| - | - | - |
| nameOverride |  | `""` |
| fullnameOverride |  | `""` |
| image.repository |  | `""` |
| image.tag |  | `""` |
| image.pullPolicy |  | `""` |
| imagePullSecrets |  | `[]` |
| volumeMounts |  | `[]` |
| volumes |  | `[]` |
| env |  | `[]` |
| envFrom |  | `[]` |

### ServiceTemplate Parameters
| Name | Description | Value |
| - | - | - |
| serviceTemplate.name |  | `svc` |
| serviceTemplate.annotations |  | `{}` |
| serviceTemplate.imagePullSecrets |  | `[]` |
| serviceTemplate.terminationGracePeriodSeconds |  | `""` |
| serviceTemplate.initContainers |  | `[]` |
| serviceTemplate.image.repository |  | `""` |
| serviceTemplate.image.tag |  | `""` |
| serviceTemplate.env |  | `[]` |
| serviceTemplate.envFrom |  | `[]` |
| serviceTemplate.command |  | `[]` |
| serviceTemplate.args |  | `[]` |
| serviceTemplate.ports |  | `[]` |
| serviceTemplate.resources |  | `{}` |
| serviceTemplate.lifecycleHooks |  | `{}` |
| serviceTemplate.volumeMounts |  | `[]` |
| serviceTemplate.healthcheck.enabled |  | `false` |
| serviceTemplate.healthcheck.type |  | `httpGet` |
| serviceTemplate.healthcheck.path |  | `""` |
| serviceTemplate.healthcheck.port |  | `""` |
| serviceTemplate.healthcheck.initialDelaySeconds |  | `""` |
| serviceTemplate.healthcheck.periodSeconds |  | `""` |
| serviceTemplate.dnsConfig |  | `{}` |
| serviceTemplate.securityContext |  | `{}` |
| serviceTemplate.volumes |  | `[]` |
| serviceTemplate.nodeSelector |  | `{}` |
| serviceTemplate.affinity |  | `{}` |
| serviceTemplate.tolerations |  | `{}` |
| serviceTemplate.volumeClaimTemplates |  | `[]` |
| serviceTemplate.autoscaling |  | `false` |
| serviceTemplate.minReplicaCount |  | `1` |
| serviceTemplate.maxReplicaCount |  | `1` |
| serviceTemplate.service.enabled |  | `true` |
| serviceTemplate.service.annotations |  | `{}` |
| serviceTemplate.service.type |  | `ClusterIP` |
| serviceTemplate.service.ports |  | `[]` |
| serviceTemplate.ingress.enabled |  | `false` |
| serviceTemplate.ingress.annotations |  | `{}` |
| serviceTemplate.ingress.className |  | `""` |
| serviceTemplate.ingress.tls |  | `[]` |
| serviceTemplate.ingress.hosts |  | `[]` |
### Services Parameters
| Name | Description | Value |
| - | - | - |
| services.type |  | `Deployment` |
| services.name |  | `""` |
| services.annotations |  | `{}` |
| services.imagePullSecrets |  | `[]` |
| services.terminationGracePeriodSeconds |  | `""` |
| services.initContainers |  | `[]` |
| services.image.repository |  | `""` |
| services.image.tag |  | `""` |
| services.env |  | `[]` |
| services.envFrom |  | `[]` |
| services.command |  | `[]` |
| services.args |  | `[]` |
| services.ports |  | `[]` |
| services.resources |  | `{}` |
| services.lifecycleHooks |  | `{}` |
| services.volumeMounts |  | `[]` |
| services.healthcheck.enabled |  | `false` |
| services.healthcheck.type |  | `httpGet` |
| services.healthcheck.path |  | `""` |
| services.healthcheck.port |  | `""` |
| services.healthcheck.initialDelaySeconds |  | `""` |
| services.healthcheck.periodSeconds |  | `""` |
| services.dnsConfig |  | `{}` |
| services.securityContext |  | `{}` |
| services.volumes |  | `[]` |
| services.nodeSelector |  | `{}` |
| services.affinity |  | `{}` |
| services.tolerations |  | `{}` |
| services.volumeClaimTemplates |  | `[]` |
| services.autoscaling |  | `false` |
| services.minReplicaCount |  | `1` |
| services.maxReplicaCount |  | `1` |
| services.service.enabled |  | `true` |
| services.service.annotations |  | `{}` |
| services.service.type |  | `ClusterIP` |
| services.service.ClusterIP |  | `""` |
| services.service.ports |  | `[]` |
| services.ingress.enabled |  | `false` |
| services.ingress.annotations |  | `{}` |
| services.ingress.className |  | `""` |
| services.ingress.tls |  | `[]` |
| services.ingress.hosts |  | `[]` |
| services.ingress.hosts.host |  | `""` |
| services.ingress.hosts.paths |  | `[]` |
| services.ingress.hosts.paths.path |  | `""` |
| services.ingress.hosts.paths.pathType |  | `""` |
| services.ingress.hosts.paths.servicePort |  | `""` |
