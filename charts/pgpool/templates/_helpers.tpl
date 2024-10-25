{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "pgpool.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "pgpool.fullname" -}}
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
{{- define "pgpool.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Return the appropriate apiVersion for deployment.
*/}}
{{- define "apiVersion.policy" -}}
{{- if .Capabilities.APIVersions.Has "policy/v1beta1" -}}
{{- print "policy/v1beta1" -}}
{{- else if .Capabilities.APIVersions.Has "policy/v1" -}}
{{- print "policy/v1" -}}
{{- end -}}
{{- end -}}

{{/*
Return the appropriate apiVersion for deployment.
*/}}
{{- define "apiVersion.deployment" -}}
{{- if .Capabilities.APIVersions.Has "apps/v1/Deployment" -}}
{{- print "apps/v1" -}}
{{- else if .Capabilities.APIVersions.Has "apps/v1beta1/Deployment" -}}
{{- print "apps/v1beta1" -}}
{{- else if .Capabilities.APIVersions.Has "apps/v1beta2/Deployment" -}}
{{- print "apps/v1beta2" -}}
{{- else if .Capabilities.APIVersions.Has "extensions/v1beta1/Deployment" -}}
{{- print "extensions/v1beta1" -}}
{{- end -}}
{{- end -}}
