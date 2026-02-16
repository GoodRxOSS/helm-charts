{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "lifecycle-keycloak.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "lifecycle-keycloak.fullname" -}}
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
{{- define "lifecycle-keycloak.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "lifecycle-keycloak.labels" -}}
helm.sh/chart: {{ include "lifecycle-keycloak.chart" . }}
{{ include "lifecycle-keycloak.selectorLabels" . }}
app.kubernetes.io/component: {{ .component }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- if .Values.extraLabels }}
{{- range $key, $value := .Values.extraLabels }}
{{ $key }}: {{ $value | quote }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "lifecycle-keycloak.selectorLabels" -}}
app.kubernetes.io/name: {{ include "lifecycle-keycloak.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "lifecycle-keycloak.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
    {{- default (include "lifecycle-keycloak.fullname" .) .Values.serviceAccount.name }}
{{- else }}
    {{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Namespace Hostname
*/}}
{{- define "lifecycle-keycloak.namespaceHostname" -}}
{{ $.Release.Namespace }}.svc.cluster.local
{{- end }}

{{- define "lifecycle-keycloak.bootstrapAdminSecretName" -}}
{{- if .Values.secrets.bootstrapAdmin.fullnameOverride -}}
    {{- .Values.secrets.bootstrapAdmin.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
    {{- $prefix := include "lifecycle-keycloak.fullname" . -}}
    {{- printf "%s-%s" $prefix "bootstrap-admin" | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "lifecycle-keycloak.githubIdpSecretName" -}}
{{- if .Values.secrets.githubIdp.fullnameOverride -}}
    {{- .Values.secrets.githubIdp.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
    {{- $prefix := include "lifecycle-keycloak.fullname" . -}}
    {{- printf "%s-%s" $prefix "github-idp" | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "lifecycle-keycloak.postgresSecretName" -}}
{{- if contains "lifecycle-keycloak" .Release.Name }}
    {{- printf "%s-%s" .Release.Name "postgres" | trunc 63 | trimSuffix "-" }}
{{- else }}
    {{- printf "%s-%s-%s" .Release.Name "keycloak" "postgres" | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end -}}

{{- define "lifecycle-keycloak.lifecycleUiSecretName" -}}
{{- if .Values.secrets.lifecycleUi.fullnameOverride -}}
    {{- .Values.secrets.lifecycleUi.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
    {{- $prefix := include "lifecycle-keycloak.fullname" . -}}
    {{- printf "%s-%s" $prefix "lifecycle-ui" | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "lifecycle-keycloak.postgresSvcPrefix" -}}
{{- if .Values.keycloakPostgres.fullnameOverride }}
    {{- printf "%s.%s" .Values.keycloakPostgres.fullnameOverride (include "lifecycle-keycloak.namespaceHostname" .) }}
{{- else }}
    {{- $prefix := include "lifecycle-keycloak.fullname" . -}}
    {{- printf "%s-%s.%s" $prefix "postgres" (include "lifecycle-keycloak.namespaceHostname" .) -}}
{{- end }}
{{- end -}}

{{- define "lifecycle-keycloak.parentChartPrefix" -}}
{{- if contains .Values.parentChartName .Release.Name -}}
    {{- .Release.Name -}}
{{- else -}}
    {{- printf "%s-%s" .Release.Name .Values.parentChartName -}}
{{- end -}}
{{- end -}}
