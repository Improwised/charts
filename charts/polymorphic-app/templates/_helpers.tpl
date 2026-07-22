{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "polymorphic-app.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "polymorphic-app.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "polymorphic-app.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "polymorphic-app.labels" -}}
helm.sh/chart: {{ include "polymorphic-app.chart" . }}
{{ include "polymorphic-app.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "polymorphic-app.selectorLabels" -}}
app.kubernetes.io/name: {{ include "polymorphic-app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "polymorphic-app.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "polymorphic-app.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}


{{/*
Files that would be mounted inside all of the components

{{- define "polymorphic-app.filesAsSecrets" -}}
{{- if .Values.certificate.enabled }}
{{- range $key, $value := .Values.certificate.files }}
  {{ $key }}: {{ $value | b64enc }}
{{- end }}
{{- end }}
{{- end -}}
*/}}

{{/*
Root Env secrets name

{{- define "polymorphic-app.rootEnvSecrets" -}}
{{- $root := . -}}
{{- range $key, $value := .Values.envSecrets.name }}
  envFrom:
    - secretRef:
        name: {{ $value }}
{{- end }}
{{- end -}}
*/}}

{{/*
WorkerTemplate Env secrets name

{{- define "polymorphic-app.workerTemplateEnvSecrets" -}}
{{- $root := . -}}
{{- range $key, $value := .Values.workerTemplate.envSecrets }}
    envFrom:
      - secretRef:
          name: {{ $value }}
{{- end }}
{{- end -}}
*/}}

{{/*
Individual Workers Env secrets name

{{- define "polymorphic-app.workerEnvSecrets" -}}
{{- $root := .Values -}}
  {{- range $root.workers.envSecrets }}
    envFrom:
      - secretRef:
          name: {{ $.Values.workers.name }}
  {{- end }}
{{- end -}}
*/}}

{{/*
Return the appropriate apiVersion for deployment.
*/}}
{{- define "deployment.apiVersion" -}}
{{- if semverCompare "<1.14-0" .Capabilities.KubeVersion.Version -}}
{{- print "extensions/v1beta1" -}}
{{- else -}}
{{- print "apps/v1" -}}
{{- end -}}
{{- end -}}

{{- define "hpa.apiVersion" -}}
{{- if semverCompare ">1.25-0" .Capabilities.KubeVersion.Version -}}
{{- print "autoscaling/v2" -}}
{{- else -}}
{{- print "autoscaling/v2beta2" -}}
{{- end -}}
{{- end -}}

{{/*
Return the appropriate apiVersion for ingress.
*/}}
{{- define "ingress.apiVersion" -}}
{{- if semverCompare "<1.14-0" .Capabilities.KubeVersion.Version -}}
{{- print "extensions/v1beta1" -}}
{{- else if semverCompare "<1.19-0" .Capabilities.KubeVersion.Version -}}
{{- print "networking.k8s.io/v1beta1" -}}
{{- else -}}
{{- print "networking.k8s.io/v1" -}}
{{- end -}}
{{- end -}}

{{- define "ingress.backend" -}}
{{- $apiVersion := (include "ingress.apiVersion" .context) -}}
{{- if or (eq $apiVersion "extensions/v1beta1") (eq $apiVersion "networking.k8s.io/v1beta1") -}}
serviceName: {{ .serviceName }}
servicePort: {{ .servicePort }}
{{- else -}}
service:
  name: {{ .serviceName }}
  port:
    {{- if typeIs "string" .servicePort }}
    name: {{ .servicePort }}
    {{- else if or (typeIs "int" .servicePort) (typeIs "float64" .servicePort) }}
    number: {{ .servicePort | int }}
    {{- end }}
{{- end -}}
{{- end -}}

{{- define "ingress.pathtype" -}}
{{- $apiVersion := (include "ingress.apiVersion" .) -}}
{{- if (eq $apiVersion "networking.k8s.io/v1") -}}
pathType: ImplementationSpecific
{{- end -}}
{{- end -}}

{{/*
Return the appropriate apiVersion for cronjob.
*/}}
{{- define "cronjob.apiVersion" -}}
{{- if semverCompare "<1.21-0" .Capabilities.KubeVersion.Version -}}
{{- print "batch/v1beta1" -}}
{{- else -}}
{{- print "batch/v1" -}}
{{- end -}}
{{- end -}}

{{/*
Core probe configuration
*/}}
{{- define "polymorphic-app.probe-core" -}}
{{- $health := .healthcheck -}}
{{- $probe := .probe -}}
{{- if $health -}}
  {{- $cfg := $probe | default $health -}}
  {{- $type := $health.type | default "httpGet" -}}
  {{- if eq $type "httpGet" -}}
httpGet:
  path: {{ $cfg.path | default $health.path }}
  port: {{ $cfg.port | default $health.port }}
  {{- else if eq $type "tcpSocket" -}}
tcpSocket:
  port: {{ $cfg.port | default $health.port }}
  {{- else if eq $type "exec" -}}
exec:
  command: {{ toYaml ($cfg.command | default $health.command) | nindent 4 }}
  {{- end }}
timeoutSeconds: {{ $cfg.timeoutSeconds | default $health.timeoutSeconds | default 7 }}
initialDelaySeconds: {{ $cfg.initialDelaySeconds | default $health.initialDelaySeconds | default 20 }}
periodSeconds: {{ $cfg.periodSeconds | default $health.periodSeconds | default 20 }}
failureThreshold: {{ $cfg.failureThreshold | default $health.failureThreshold | default 3 }}
{{- end -}}
{{- end -}}

{{/*
Liveness and readiness probes
*/}}
{{- define "polymorphic-app.healthchecks" -}}
{{- $health := . -}}
{{- if $health -}}
  {{- $p := $health.probes | default dict -}}
  {{- $liveness := $health.liveness | default $p.liveness -}}
  {{- $readiness := $health.readiness | default $p.readiness -}}
  {{- if or $liveness $readiness -}}
    {{- if $liveness }}
livenessProbe:
{{- include "polymorphic-app.probe-core" (dict "healthcheck" $health "probe" $liveness) | nindent 2 }}
    {{- end }}
    {{- if $readiness }}
readinessProbe:
{{- include "polymorphic-app.probe-core" (dict "healthcheck" $health "probe" $readiness) | nindent 2 }}
    {{- end }}
  {{- else if or $health.path $health.port $health.command -}}
    {{- range $type := list "liveness" "readiness" }}
{{ $type }}Probe:
{{- include "polymorphic-app.probe-core" (dict "healthcheck" $health) | nindent 2 }}
    {{- end }}
  {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Container spec template - generates a single container definition
Context: {
  container: container definition,
  root: root values,
  defaultImage: default image repository and tag,
  defaultEnv: default env vars,
  defaultEnvFrom: default envFrom,
  defaultVolumeMounts: default volume mounts
}
*/}}
{{- define "polymorphic-app.container" -}}
name: {{ .container.name | required "Container name is required" }}
  {{- if .container.image }}
image: "{{ .container.image.repository }}:{{ .container.image.tag }}"
  {{- else if .defaultImage }}
image: "{{ .defaultImage.repository }}:{{ .defaultImage.tag }}"
  {{- else }}
image: "{{ .root.Values.image.repository }}:{{ .root.Values.image.tag }}"
  {{- end }}
imagePullPolicy: {{ .root.Values.image.pullPolicy }}
  {{- if or .container.env .defaultEnv .root.Values.env }}
env:
  {{- if .container.env }}
{{ toYaml .container.env | indent 2 }}
  {{- end }}
  {{- if .defaultEnv }}
{{ toYaml .defaultEnv | indent 2 }}
  {{- end }}
  {{- if .root.Values.env }}
{{ toYaml .root.Values.env | indent 2 }}
  {{- end }}
  {{- end }}
  {{- if or .container.envFrom .defaultEnvFrom .root.Values.envFrom }}
envFrom:
  {{- if .container.envFrom }}
{{ toYaml .container.envFrom | indent 2 }}
  {{- end }}
  {{- if .defaultEnvFrom }}
{{ toYaml .defaultEnvFrom | indent 2 }}
  {{- end }}
  {{- if .root.Values.envFrom }}
{{ toYaml .root.Values.envFrom | indent 2 }}
  {{- end }}
  {{- end }}
  {{- if .container.command }}
command:
{{ toYaml .container.command | indent 2 }}
  {{- end }}
  {{- if .container.args }}
args:
{{ toYaml .container.args | indent 2 }}
  {{- end }}
  {{- with .container.ports }}
ports:
{{ toYaml . | indent 2 }}
  {{- end }}
  {{- with .container.resources }}
resources:
{{ toYaml . | indent 2 }}
  {{- end }}
  {{- with .container.containerSecurityContext }}
securityContext:
{{ toYaml . | indent 2 }}
  {{- end }}
  {{- if .container.lifecycleHooks }}
lifecycle:
{{ toYaml .container.lifecycleHooks | indent 2 }}
  {{- end }}
  {{- if or .container.volumeMounts .defaultVolumeMounts .root.Values.volumeMounts }}
volumeMounts:
  {{- if .container.volumeMounts }}
{{ toYaml .container.volumeMounts | indent 2 }}
  {{- end }}
  {{- if .defaultVolumeMounts }}
{{ toYaml .defaultVolumeMounts | indent 2 }}
  {{- end }}
  {{- if .root.Values.volumeMounts }}
{{ toYaml .root.Values.volumeMounts | indent 2 }}
  {{- end }}
  {{- end }}
  {{- $health := .container.healthcheck -}}
  {{- if and $health (ne $health.enabled false) }}
{{- include "polymorphic-app.healthchecks" $health | nindent 0 }}
  {{- end }}
{{- end -}}

{{/*
Pod spec template - generates the full pod spec (without initial 'spec:' key)
Context: {
  item: service/worker item definition,
  root: root context ($),
  template: template defaults (serviceTemplate or workerTemplate),
  type: "service" or "worker"
}
*/}}
{{- define "polymorphic-app.podSpec" -}}
{{- if .item.imagePullSecrets }}
imagePullSecrets:
{{ toYaml .item.imagePullSecrets | indent 2 }}
{{- else if .template.imagePullSecrets }}
imagePullSecrets:
{{ toYaml .template.imagePullSecrets | indent 2 }}
{{- else if .root.Values.imagePullSecrets }}
imagePullSecrets:
{{ toYaml .root.Values.imagePullSecrets | indent 2 }}
{{- end }}
terminationGracePeriodSeconds: {{ .item.terminationGracePeriodSeconds | default .template.terminationGracePeriodSeconds }}
{{- if or .template.initContainers .item.initContainers }}
  {{- with .item.initContainers | default .template.initContainers }}
initContainers:
{{ toYaml . | indent 2 }}
  {{- end }}
{{- end }}
containers:
{{- $containers := .item.containers -}}
{{- if not $containers -}}
  {{- fail "containers array is required. Please define containers for your deployment." -}}
{{- end -}}
{{- range $container := $containers }}
  - name: {{ $container.name | required "Container name is required" }}
    {{- if $container.image }}
    image: "{{ $container.image.repository }}:{{ $container.image.tag }}"
    {{- else if $.template.image }}
    image: "{{ $.template.image.repository }}:{{ $.template.image.tag }}"
    {{- else }}
    image: "{{ $.root.Values.image.repository }}:{{ $.root.Values.image.tag }}"
    {{- end }}
    imagePullPolicy: {{ $.root.Values.image.pullPolicy }}
    {{- if or $container.env $.template.env $.root.Values.env }}
    env:
    {{- if $container.env }}
{{ toYaml $container.env | indent 6 }}
    {{- end }}
    {{- if $.template.env }}
{{ toYaml $.template.env | indent 6 }}
    {{- end }}
    {{- if $.root.Values.env }}
{{ toYaml $.root.Values.env | indent 6 }}
    {{- end }}
    {{- end }}
    {{- if or $container.envFrom $.template.envFrom $.root.Values.envFrom }}
    envFrom:
    {{- if $container.envFrom }}
{{ toYaml $container.envFrom | indent 6 }}
    {{- end }}
    {{- if $.template.envFrom }}
{{ toYaml $.template.envFrom | indent 6 }}
    {{- end }}
    {{- if $.root.Values.envFrom }}
{{ toYaml $.root.Values.envFrom | indent 6 }}
    {{- end }}
    {{- end }}
    {{- if $container.command }}
    command:
{{ toYaml $container.command | indent 6 }}
    {{- end }}
    {{- if $container.args }}
    args:
{{ toYaml $container.args | indent 6 }}
    {{- end }}
    {{- with $container.ports }}
    ports:
{{ toYaml . | indent 6 }}
    {{- end }}
    {{- with $container.resources }}
    resources:
{{ toYaml . | indent 6 }}
    {{- end }}
    {{- with $container.containerSecurityContext }}
    securityContext:
{{ toYaml . | indent 6 }}
    {{- end }}
    {{- if $container.lifecycleHooks }}
    lifecycle:
{{ toYaml $container.lifecycleHooks | indent 6 }}
    {{- end }}
    {{- if or $container.volumeMounts $.template.volumeMounts $.root.Values.volumeMounts }}
    volumeMounts:
    {{- if $container.volumeMounts }}
{{ toYaml $container.volumeMounts | indent 6 }}
    {{- end }}
    {{- if $.template.volumeMounts }}
{{ toYaml $.template.volumeMounts | indent 6 }}
    {{- end }}
    {{- if $.root.Values.volumeMounts }}
{{ toYaml $.root.Values.volumeMounts | indent 6 }}
    {{- end }}
    {{- end }}
    {{- $health := $container.healthcheck -}}
    {{- if and $health (ne $health.enabled false) }}
{{- include "polymorphic-app.healthchecks" $health | nindent 4 }}
    {{- end }}
{{- end }}
{{- with .item.dnsConfig | default .template.dnsConfig }}
dnsConfig:
{{ toYaml . | indent 2 }}
{{- end }}
{{- with .item.securityContext | default .template.securityContext }}
securityContext:
{{ toYaml . | indent 2 }}
{{- end }}
volumes:
{{- if .item.volumes }}
{{ toYaml .item.volumes | indent 2 }}
{{- end }}
{{- if .root.Values.volumes }}
{{ toYaml .root.Values.volumes | indent 2 }}
{{- end }}
{{- if .template.volumes }}
{{ toYaml .template.volumes | indent 2 }}
{{- end }}
{{- with .item.nodeSelector | default .template.nodeSelector }}
nodeSelector:
{{ toYaml . | indent 2 }}
{{- end }}
affinity:
  podAntiAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
    - weight: 1
      podAffinityTerm:
        topologyKey: kubernetes.io/hostname
        labelSelector:
          matchLabels:
            {{- include "polymorphic-app.labels" $.root | nindent 12 }}
            app.kubernetes.io/component: "{{ .item.name | default .template.name }}"
{{- with .item.affinity | default .template.affinity }}
{{ toYaml . | indent 2 }}
{{- end }}
{{- with .item.tolerations | default .template.tolerations }}
tolerations:
{{ toYaml . | indent 2 }}
{{- end }}
{{- end -}}
