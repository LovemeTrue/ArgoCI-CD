{{/*
Expand the name of the chart.
*/}}
{{- define "calculator.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "calculator.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "calculator.labels" -}}
helm.sh/chart: {{ include "calculator.chart" . }}
{{- range $k,$v := .Values.global.labels }}
{{ $k }}: {{ $v | quote }}
{{- end }}
{{ include "calculator.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "calculator.selectorLabels" -}}
app: {{ include "calculator.name" . }}
tier: elma365
app.kubernetes.io/name: {{ include "calculator.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Return the target Kubernetes version
*/}}
{{- define "kubeVersion" -}}
{{- if .Values.global }}
    {{- if .Values.global.kubeVersion }}
    {{- .Values.global.kubeVersion -}}
    {{- else }}
    {{- default .Capabilities.KubeVersion.Version .Values.kubeVersion -}}
    {{- end -}}
{{- else }}
{{- default .Capabilities.KubeVersion.Version .Values.kubeVersion -}}
{{- end -}}
{{- end -}}
