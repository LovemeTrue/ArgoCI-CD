{{/*
Expand the name of the chart.
*/}}
{{- define "todolist.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "todolist.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "todolist.labels" -}}
helm.sh/chart: {{ include "todolist.chart" . }}
{{- range $k,$v := .Values.global.labels }}
{{ $k }}: {{ $v | quote }}
{{- end }}
{{ include "todolist.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "todolist.selectorLabels" -}}
app: {{ include "todolist.name" . }}
tier: elma365
app.kubernetes.io/name: {{ include "todolist.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "todolist.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "todolist.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Create rabbitmq user basen on namespace
*/}}
{{- define "todolist.rmquser" -}}
{{- printf "%s-%s" .Release.Namespace .Chart.Name | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}
