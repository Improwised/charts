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
Unified container specification template.
Usage:
{{ include "polymorphic-app.containerSpec" (dict "item" . "template" $.Values.serviceTemplate "root" $ "containerName" "svc" "healthcheck" $health "ports" .ports "probeConfig" .probe) }}

Parameters:
  .item         - The individual array item (service/worker/cronJob/job entry)
  .template     - The corresponding *Template values (e.g. $.Values.serviceTemplate)
  .root         - Root context ($)
  .containerName - Base name for the container
  .healthcheck  - Optional healthcheck config (for services)
  .ports        - Optional ports list (for services)
  .probeConfig  - Optional probe config (for workers - .probe with .aliveCommand)

Merge order for env/envFrom/volumeMounts: global -> template -> item (item overrides, last-wins).
*/}}
{{- define "polymorphic-app.containerSpec" -}}
{{- $item := .item -}}
{{- $tmpl := .template -}}
{{- $root := .root -}}
{{- $containerName := .containerName -}}
{{- $health := .healthcheck -}}
{{- $ports := .ports -}}
{{- $probeConfig := .probeConfig -}}
- name: "{{ if $root.Values.prefixWithReleaseName.enabled }}{{ $root.Release.Name }}-{{ end }}{{ $containerName }}"
  {{- if $item.image }}
  image: "{{ $item.image.repository }}:{{ $item.image.tag }}"
  {{- else if $tmpl.image }}
  image: "{{ $tmpl.image.repository }}:{{ $tmpl.image.tag }}"
  {{- else }}
  image: "{{ $root.Values.image.repository }}:{{ $root.Values.image.tag }}"
  {{- end }}
  imagePullPolicy: {{ $root.Values.image.pullPolicy }}
  {{- if or $item.env $root.Values.env $tmpl.env }}
  env:
  {{- if $root.Values.env }}
{{ toYaml $root.Values.env | indent 4 }}
  {{- end }}
  {{- if $tmpl.env }}
{{ toYaml $tmpl.env | indent 4 }}
  {{- end }}
  {{- if $item.env }}
{{ toYaml $item.env | indent 4 }}
  {{- end }}
  {{- end }}
  {{- if or $item.envFrom $root.Values.envFrom $tmpl.envFrom }}
  envFrom:
  {{- if $root.Values.envFrom }}
{{ toYaml $root.Values.envFrom | indent 4 }}
  {{- end }}
  {{- if $tmpl.envFrom }}
{{ toYaml $tmpl.envFrom | indent 4 }}
  {{- end }}
  {{- if $item.envFrom }}
{{ toYaml $item.envFrom | indent 4 }}
  {{- end }}
  {{- end }}
  {{- if $item.command }}
  command:
{{ toYaml $item.command | indent 4 }}
  {{- else if $tmpl.command }}
  command:
{{ toYaml $tmpl.command | indent 4 }}
  {{- end }}
  {{- if $item.args }}
  args:
{{ toYaml $item.args | indent 4 }}
  {{- else if $tmpl.args }}
  args:
{{ toYaml $tmpl.args | indent 4 }}
  {{- end }}
  {{- if $ports }}
  ports:
{{ toYaml $ports | indent 4 }}
  {{- end }}
  {{- $resources := ($item.resources | default $tmpl.resources) -}}
  {{- if $resources }}
  resources:
{{ toYaml $resources | indent 4 }}
  {{- end }}
  {{- with ($item.containerSecurityContext | default $tmpl.containerSecurityContext) }}
  securityContext:
{{ toYaml . | indent 4 }}
  {{- end }}
  {{- if or $tmpl.lifecycleHooks $item.lifecycleHooks }}
  lifecycle:
{{ toYaml ($item.lifecycleHooks | default $tmpl.lifecycleHooks) | indent 4 }}
  {{- end }}
  {{- if and $health (ne $health.enabled false) }}
  {{- include "polymorphic-app.healthchecks" $health | nindent 2 }}
  {{- end }}
  {{- if $probeConfig }}
  {{- $probe := dict "enabled" true "type" "exec" "command" $probeConfig.aliveCommand
      "timeoutSeconds" ($probeConfig.timeoutSeconds | default 10)
      "initialDelaySeconds" ($probeConfig.initialDelaySeconds | default 10)
      "periodSeconds" ($probeConfig.periodSeconds | default 20)
      "failureThreshold" ($probeConfig.failureThreshold | default 3) -}}
  {{- include "polymorphic-app.healthchecks" $probe | nindent 2 }}
  {{- end }}
  {{- if or $item.volumeMounts $root.Values.volumeMounts $tmpl.volumeMounts }}
  volumeMounts:
  {{- if $root.Values.volumeMounts }}
{{ toYaml $root.Values.volumeMounts | indent 4 }}
  {{- end }}
  {{- if $tmpl.volumeMounts }}
{{ toYaml $tmpl.volumeMounts | indent 4 }}
  {{- end }}
  {{- if $item.volumeMounts }}
{{ toYaml $item.volumeMounts | indent 4 }}
  {{- end }}
  {{- end }}
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
