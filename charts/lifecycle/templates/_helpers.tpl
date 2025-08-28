{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "..helper.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Determine the image tag to use: either from .Values.global.image.tag or .Chart.AppVersion.
*/}}
{{- define "..helper.appVersion" -}}
{{ default .Chart.AppVersion .Values.global.image.tag }}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "..helper.fullname" -}}
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
{{- define "..helper.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "..helper.labels" -}}
helm.sh/chart: {{ include "..helper.chart" . }}
{{ include "..helper.selectorLabels" . }}
app.kubernetes.io/version: {{ include "..helper.appVersion" . | quote }}
app.kubernetes.io/component: {{ .component }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: {{ .Values.global.scope | default "core" }}
{{- if .Values.global.extraLabels }}
{{- range $key, $value := .Values.global.extraLabels }}
{{ $key }}: {{ $value | quote }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "..helper.selectorLabels" -}}
app.kubernetes.io/name: {{ include "..helper.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "..helper.serviceAccountName" -}}
{{- if .Values.global.serviceAccount.create }}
    {{- default (include "..helper.fullname" .) .Values.global.serviceAccount.name }}
{{- else }}
    {{- default "default" .Values.global.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Namespace Hostname
*/}}
{{- define "..helper.namespaceHostname" -}}
{{ $.Release.Namespace }}.svc.cluster.local
{{- end }}

{{- define "..helper.postgresSecretName" -}}
{{- if contains "lifecycle" .Release.Name }}
    {{- printf "%s-%s" .Release.Name "postgres" | trunc 63 | trimSuffix "-" }}
{{- else }}
    {{- printf "%s-%s-%s" .Release.Name "lifecycle" "postgres" | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end -}}

{{- define "..helper.redisSecretName" -}}
{{- if contains "lifecycle" .Release.Name }}
    {{- printf "%s-%s" .Release.Name "redis" | trunc 63 | trimSuffix "-" }}
{{- else }}
    {{- printf "%s-%s-%s" .Release.Name "lifecycle" "redis" | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end -}}

{{- define "..helper.postgresSvcPrefix" -}}
{{- if .Values.postgres.fullnameOverride }}
    {{- printf "%s.%s" .Values.postgres.fullnameOverride (include "..helper.namespaceHostname" .) }}
{{- else }}
    {{- printf "%s-%s.%s" .Release.Name "postgres" (include "..helper.namespaceHostname" .) }}
{{- end }}
{{- end -}}

{{- define "..helper.redisSvcPrefix" -}}
{{- if .Values.redis.fullnameOverride }}
    {{- printf "%s-master.%s" .Values.redis.fullnameOverride (include "..helper.namespaceHostname" .) }}
{{- else }}
    {{- printf "%s-%s-master.%s" .Release.Name "redis" (include "..helper.namespaceHostname" .) }}
{{- end }}
{{- end -}}

{{- define "..helper.buildkitSvcUrl" -}}
{{- if .Values.buildkit.fullnameOverride }}
    {{- printf "tcp://%s.%s:1234" .Values.buildkit.fullnameOverride (include "..helper.namespaceHostname" .) }}
{{- else }}
    {{- printf "tcp://%s-%s.%s:1234" .Release.Name "buildkit" (include "..helper.namespaceHostname" .) }}
{{- end }}
{{- end -}}
