{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "worker.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Шаблон для создания имени пула. Ожидается, что в качестве параметров шаблона переданы
параметры пула воркеров.
*/}}
{{- define "worker.pool.name" -}}
{{- $workerName := include "worker.name" .GlobalContext -}}
{{- printf "%s-pool-%s" $workerName .poolKey | trunc 63 -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "worker.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}


{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "worker.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "worker.labels" -}}
helm.sh/chart: {{ include "worker.chart" . }}
{{- range $k,$v := .Values.global.labels }}
{{ $k }}: {{ $v }}
{{- end }}
{{ include "worker.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "worker.selectorLabels" -}}
app: {{ include "worker.name" . }}
tier: elma365
app.kubernetes.io/name: {{ include "worker.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Common pool labels
*/}}
{{- define "worker.pool.labels" -}}
{{- $dot := required "GlobalContext should be passed" .GlobalContext -}}
helm.sh/chart: {{ include "worker.chart" $dot }}
{{- range $k,$v := $dot.Values.global.labels }}
{{ $k }}: {{ $v }}
{{- end }}
{{ include "worker.pool.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ $dot.Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ $dot.Release.Service }}
{{- end }}

{{/*
Selector pool labels
*/}}
{{- define "worker.pool.selectorLabels" -}}
{{- $localContext := required "LocalContext should be passed" .LocalContext -}}
{{- $name := required "Name should be passed" $localContext.name -}}
app: {{ $name }}
tier: elma365
app.kubernetes.io/name: {{ $name }}
app.kubernetes.io/instance: {{ .Release.Name }}
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
