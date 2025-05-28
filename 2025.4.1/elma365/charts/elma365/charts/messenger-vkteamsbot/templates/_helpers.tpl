{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "messenger-vkteamsbot.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "messenger-vkteamsbot.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}


{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "messenger-vkteamsbot.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}


{{/*
Common labels
*/}}
{{- define "messenger-vkteamsbot.labels" -}}
helm.sh/chart: {{ include "messenger-vkteamsbot.chart" . }}
{{- range $k,$v := .Values.global.labels }}
{{ $k }}: {{ $v }}
{{- end }}
{{ include "messenger-vkteamsbot.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "messenger-vkteamsbot.selectorLabels" -}}
app: {{ include "messenger-vkteamsbot.name" . }}
tier: elma365
app.kubernetes.io/name: {{ include "messenger-vkteamsbot.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
