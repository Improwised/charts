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
