{{/*
Expand the name of the chart.
*/}}
{{- define "telemetrist.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "telemetrist.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "telemetrist.labels" -}}
helm.sh/chart: {{ include "telemetrist.chart" . }}
{{- range $k,$v := .Values.global.labels }}
{{ $k }}: {{ $v | quote }}
{{- end }}
{{ include "telemetrist.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "telemetrist.selectorLabels" -}}
app: {{ include "telemetrist.name" . }}
tier: elma365
app.kubernetes.io/name: {{ include "telemetrist.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "telemetrist.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "telemetrist.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Create rabbitmq user basen on namespace
*/}}
{{- define "telemetrist.rmquser" -}}
{{- printf "%s-%s" .Release.Namespace .Chart.Name | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}
