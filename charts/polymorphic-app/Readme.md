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

## Compatibility

Values that render with one 2.x version render the same objects with the next, unless the release notes say
otherwise. CI enforces this: `.ci/scripts/render-compat.py` renders the files in `ci/compat/values/` with the
released chart and with the change, and fails on any difference that is not declared, with a reason, in
`ci/compat/allowed-changes.yaml`. New features are opt-in and render nothing until they are set.

## Upgrading to 2.10.0

* **Pods roll once.** Pod templates no longer carry the `helm.sh/chart` label (the chart version), so this
  upgrade restarts workloads one last time; later chart upgrades only restart pods when the workload changes,
  and plain (non-hook) Jobs no longer fail with "field is immutable" on chart upgrades.
* **Delete completed plain Jobs first.** A `jobs[]` entry without a `helm.sh/hook` annotation is a plain Job,
  and a Job's pod template cannot change, so this upgrade fails on it, as every chart upgrade so far has.
  Delete those Jobs before upgrading (`kubectl -n <ns> delete job <release>-<job>`), or make them hooks with
  `hook: {}`. With Flux, do it before the HelmRelease picks up 2.10.0, otherwise the failed upgrade has to
  be retried (`flux reconcile helmrelease <name> --force`).
* **Values that were silently ignored now apply.** If you set any of these, check that you still want them:
  `image.pullPolicy` on an item or `*Template`, `serviceTemplate.podAnnotations`,
  `workerTemplate.averageUtilization`, and `enabled: false` on an item's `ingress` / `httpRoute` / `service`
  when the template enables it (the resource is now removed, as the value asked).
* **PodDisruptionBudgets** now select only this release's pods (name + instance + component).
* CronJobs with `tolerations` / `affinity`, and services with `httpRoute` but no `matches` or `service` block,
  render now; they failed before.

## Newer Kubernetes features

First-class values cover the common cases: `healthcheck.probes.startup`, `hpa.metrics` / `hpa.behavior`,
`topologySpread`, `jobs[].hook`, `cronJobs[].timeZone` / `concurrencyPolicy`, and `initContainers` with
`restartPolicy: Always` (native sidecars) on every kind.

Any other field goes through an escape hatch, set on the `*Template` or the item (item wins, maps deep-merge):

| Value | Rendered into | Examples |
|---|---|---|
| `extraPodSpec` | pod `spec` | `hostUsers: false`, `serviceAccountName`, `automountServiceAccountToken`, `priorityClassName`, `runtimeClassName`, pod-level `resources`, `hostNetwork` |
| `extraContainerSpec` | the main container | `resizePolicy`, `restartPolicyRules`, `workingDir` |
| `extraJobSpec` | Job `spec` (jobs and cronJobs) | `backoffLimit`, `ttlSecondsAfterFinished`, `activeDeadlineSeconds`, `podFailurePolicy`, `successPolicy` |

Keys the chart renders itself (e.g. `containers`, `volumes`, `affinity`, `probes`) are rejected with an error
that names the value to use instead. Some features also pass through existing values unchanged:
`lifecycleHooks: {preStop: {sleep: {seconds: 5}}}`, image volumes in `volumes`, `env[].valueFrom.fileKeyRef`
in `env`, and `podDisruptionBudget.unhealthyPodEvictionPolicy`. Whether a field works depends on your cluster's
Kubernetes version and feature gates; the API server rejects or drops what it does not support.

```yaml
services:
  - name: api
    healthcheck:
      enabled: true
      path: /healthz
      port: http
      probes:
        startup: {periodSeconds: 5, failureThreshold: 60}
    topologySpread:
      - topologyKey: kubernetes.io/hostname
    extraPodSpec:
      hostUsers: false
      serviceAccountName: api
jobs:
  - name: migrate
    args: ["migrate", "up"]
    hook: {}              # pre-install,pre-upgrade; before-hook-creation
    extraJobSpec:
      backoffLimit: 1
```

## Update strategy

Deployments (services and workers) default to `RollingUpdate` with `maxUnavailable: 50%` and `maxSurge: 100%`.
Override it per service/worker, or for all of them through `serviceTemplate.strategy` / `workerTemplate.strategy`:

```yaml
services:
  - name: web
    strategy:
      type: Recreate
```

* The value is used as a whole object and is never merged with the default, so `type: Recreate` does not inherit a `rollingUpdate` block (Kubernetes rejects that combination).
* Use `Recreate` for single-replica apps that mount a `ReadWriteOnce` volume. With `RollingUpdate` the new pod can be scheduled on another node and wait forever for the volume still held by the old pod, which stalls the release. `Recreate` trades that for a short, bounded outage on every rollout.
* StatefulSet services (`type: StatefulSet`) do not render a `strategy`.
* **Changing an existing Deployment from `RollingUpdate` to `Recreate`**: Helm/Flux server-side apply keeps the API-defaulted `rollingUpdate` block and the upgrade fails with `spec.strategy.rollingUpdate: Forbidden: may not be specified when strategy type is 'Recreate'`. Clear it once on the live object, then reconcile again:

  ```bash
  kubectl -n <ns> patch deployment <name> --type=merge -p '{"spec":{"strategy":{"type":"Recreate","rollingUpdate":null}}}'
  ```
