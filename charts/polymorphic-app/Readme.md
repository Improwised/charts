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
