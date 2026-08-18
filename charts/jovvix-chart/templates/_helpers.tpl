{{/*
Return the database password. Uses the external database password when
database.host is set, otherwise the internal PostgreSQL secret password.
Both must be provided at install time via --set.
*/}}
{{- define "jovvix.dbPassword" -}}
{{- if .Values.database.host -}}
  {{- .Values.database.password | required "database.password is required when using an external database (helm install --set database.password=...)" -}}
{{- else -}}
  {{- .Values.postgres.secret.password | required "postgres.secret.password is required (helm install --set postgres.secret.password=...)" -}}
{{- end -}}
{{- end }}

{{/*
Return the database host. Uses the internal StatefulSet service when
database.host is empty, otherwise returns the configured external host.
*/}}
{{- define "jovvix.databaseHost" -}}
{{- default (printf "%s-db-rw" (include "jovvix.fullname" .)) .Values.database.host -}}
{{- end }}

{{/*
Return the Redis password. Uses the external Redis password when redis.host
is set, otherwise the internal Valkey secret password. Both must be provided
at install time via --set.
*/}}
{{- define "jovvix.redisPassword" -}}
{{- if .Values.redis.host -}}
  {{- .Values.redis.password | required "redis.password is required when using an external Redis (helm install --set redis.password=...)" -}}
{{- else -}}
  {{- .Values.valkey.secret.password | required "valkey.secret.password is required (helm install --set valkey.secret.password=...)" -}}
{{- end -}}
{{- end }}

{{/*
Return the Redis host. Uses the internal Valkey service when redis.host is
empty, otherwise returns the configured external host.
*/}}
{{- define "jovvix.redisHost" -}}
{{- if .Values.redis.host -}}
{{- .Values.redis.host -}}
{{- else -}}
{{- include "valkey.fullname" .Subcharts.valkey -}}
{{- end -}}
{{- end }}

{{/*
Return the Kratos service prefix (e.g. "jovvix-kratos-admin").
*/}}
{{- define "jovvix.kratosServicePrefix" -}}
{{- include "kratos.fullname" .Subcharts.kratos -}}
{{- end }}

{{/*
Expand the name of the chart.
*/}}
{{- define "jovvix.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "jovvix.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "jovvix.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "jovvix.labels" -}}
helm.sh/chart: {{ include "jovvix.chart" . }}
{{ include "jovvix.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "jovvix.selectorLabels" -}}
app.kubernetes.io/name: {{ include "jovvix.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "jovvix.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "jovvix.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
API selector labels
*/}}
{{- define "jovvix.api.selectorLabels" -}}
app.kubernetes.io/name: {{ include "jovvix.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: api
{{- end }}

{{/*
UI selector labels
*/}}
{{- define "jovvix.ui.selectorLabels" -}}
app.kubernetes.io/name: {{ include "jovvix.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: ui
{{- end }}

{{/*
API name
*/}}
{{- define "jovvix.api.fullname" -}}
{{- printf "%s-api" (include "jovvix.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
UI name
*/}}
{{- define "jovvix.ui.fullname" -}}
{{- printf "%s-ui" (include "jovvix.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Return the appropriate apiVersion for ingress
*/}}
{{- define "jovvix.ingress.apiVersion" -}}
{{- if semverCompare ">=1.19-0" .Capabilities.KubeVersion.GitVersion -}}
{{- print "networking.k8s.io/v1" -}}
{{- else if semverCompare ">=1.14-0" .Capabilities.KubeVersion.GitVersion -}}
{{- print "networking.k8s.io/v1beta1" -}}
{{- else -}}
{{- print "extensions/v1beta1" -}}
{{- end -}}
{{- end }}

{{/*
Return the appropriate ingress backend
*/}}
{{- define "jovvix.ingress.backend" -}}
{{- if semverCompare ">=1.19-0" .Capabilities.KubeVersion.GitVersion -}}
paths:
  - path: {{ .path }}
    pathType: {{ .pathType | default "ImplementationSpecific" }}
    backend:
      service:
        name: {{ .serviceName }}
        port:
          number: {{ .servicePort }}
{{- else -}}
paths:
  - path: {{ .path }}
    backend:
      serviceName: {{ .serviceName }}
      servicePort: {{ .servicePort }}
{{- end -}}
{{- end }}

{{/*
Return the appropriate ingress pathType
*/}}
{{- define "jovvix.ingress.pathtype" -}}
{{- if semverCompare ">=1.19-0" .Capabilities.KubeVersion.GitVersion -}}
{{- print "ImplementationSpecific" -}}
{{- else -}}
{{- print "" -}}
{{- end -}}
{{- end }}


{{/* Kratos secrets, required via --set at install time */}}
{{- define "jovvix.kratos.secretsDefault" -}}
{{- .Values.kratos.secrets.secretsDefault | required "kratos.secrets.secretsDefault is required (helm install --set kratos.secrets.secretsDefault=...)" -}}
{{- end -}}

{{- define "jovvix.kratos.secretsCookie" -}}
{{- .Values.kratos.secrets.secretsCookie | required "kratos.secrets.secretsCookie is required (helm install --set kratos.secrets.secretsCookie=...)" -}}
{{- end -}}

{{- define "jovvix.kratos.secretsCipher" -}}
{{- .Values.kratos.secrets.secretsCipher | required "kratos.secrets.secretsCipher is required (helm install --set kratos.secrets.secretsCipher=...)" -}}
{{- end -}}

{{/* API secrets */}}
{{- define "jovvix.api.jwtSecret" -}}
{{- .Values.api.secret.jwtSecret | required "api.secret.jwtSecret is required (helm install --set api.secret.jwtSecret=...)" -}}
{{- end -}}
