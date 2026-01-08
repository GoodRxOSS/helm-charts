{{/* vim: set filetype=mustache: */}}
{{/*
Copyright 2025 GoodRx, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/}}

{{/*
Expand the name of the chart.
*/}}
{{- define "lifecycle-ui.helper.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Determine the image tag to use: either from .Values.image.tag or .Chart.AppVersion.
*/}}
{{- define "lifecycle-ui.helper.appVersion" -}}
{{ default .Chart.AppVersion .Values.image.tag }}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "lifecycle-ui.helper.fullname" -}}
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
{{- define "lifecycle-ui.helper.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "lifecycle-ui.helper.labels" -}}
helm.sh/chart: {{ include "lifecycle-ui.helper.chart" . }}
{{ include "lifecycle-ui.helper.selectorLabels" . }}
app.kubernetes.io/version: {{ include "lifecycle-ui.helper.appVersion" . | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- with .Values.extraLabels }}
{{- toYaml . | nindent 0 }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "lifecycle-ui.helper.selectorLabels" -}}
app.kubernetes.io/name: {{ include "lifecycle-ui.helper.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "lifecycle-ui.helper.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
    {{- default (include "lifecycle-ui.helper.fullname" .) .Values.serviceAccount.name }}
{{- else }}
    {{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create the name of the secret
*/}}
{{- define "lifecycle-ui.helper.secretName" -}}
{{- if .Values.secrets.fullnameOverride }}
    {{- .Values.secrets.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
    {{- printf "%s-%s" (include "lifecycle-ui.helper.fullname" .) "secrets" | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{/*
Create the name of the configmap
*/}}
{{- define "lifecycle-ui.helper.configName" -}}
{{- if .Values.config.fullnameOverride }}
    {{- .Values.config.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
    {{- printf "%s-%s" (include "lifecycle-ui.helper.fullname" .) "config" | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
