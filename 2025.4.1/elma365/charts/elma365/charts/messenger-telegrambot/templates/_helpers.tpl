{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "messenger-telegrambot.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "messenger-telegrambot.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}


{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "messenger-telegrambot.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}


{{/*
Common labels
*/}}
{{- define "messenger-telegrambot.labels" -}}
helm.sh/chart: {{ include "messenger-telegrambot.chart" . }}
{{- range $k,$v := .Values.global.labels }}
{{ $k }}: {{ $v }}
{{- end }}
{{ include "messenger-telegrambot.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "messenger-telegrambot.selectorLabels" -}}
app: {{ include "messenger-telegrambot.name" . }}
tier: elma365
app.kubernetes.io/name: {{ include "messenger-telegrambot.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
