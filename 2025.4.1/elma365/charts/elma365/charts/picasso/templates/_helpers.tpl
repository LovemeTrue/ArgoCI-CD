{{/*
Expand the name of the chart.
*/}}
{{- define "picasso.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "picasso.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "picasso.labels" -}}
helm.sh/chart: {{ include "picasso.chart" . }}
{{- range $k,$v := .Values.global.labels }}
{{ $k }}: {{ $v | quote }}
{{- end }}
{{ include "picasso.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "picasso.selectorLabels" -}}
app: {{ include "picasso.name" . }}
tier: elma365
app.kubernetes.io/name: {{ include "picasso.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "picasso.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "picasso.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Create rabbitmq user basen on namespace
*/}}
{{- define "picasso.rmquser" -}}
{{- printf "%s-%s" .Release.Namespace .Chart.Name | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

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
