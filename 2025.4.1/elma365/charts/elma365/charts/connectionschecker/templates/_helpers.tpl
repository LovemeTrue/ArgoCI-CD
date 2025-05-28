{{/*
Expand the name of the chart.
*/}}
{{- define "connectionschecker.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "connectionschecker.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "connectionschecker.labels" -}}
helm.sh/chart: {{ include "connectionschecker.chart" . }}
{{- range $k,$v := .Values.global.labels }}
{{ $k }}: {{ $v | quote }}
{{- end }}
{{ include "connectionschecker.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "connectionschecker.selectorLabels" -}}
app: {{ include "connectionschecker.name" . }}
tier: elma365
app.kubernetes.io/name: {{ include "connectionschecker.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
