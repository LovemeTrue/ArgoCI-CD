{{/*
Expand the name of the chart.
*/}}
{{- define "helm-library.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "helm-library.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "helm-library.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "helm-library.labels" -}}
helm.sh/chart: {{ include "helm-library.chart" . }}
{{- range $k,$v := .Values.global.labels }}
{{ $k }}: {{ $v | quote }}
{{- end }}
{{ include "helm-library.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "helm-library.selectorLabels" -}}
app: {{ include "helm-library.name" . }}
tier: elma365
app.kubernetes.io/name: {{ include "helm-library.name" . }}
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

{{- define "resource-quantity" -}}
{{- $value := . }}
{{- $unit := 1.0 }}
{{- if typeIs "string" . }}
{{- $base2 := dict "Ki" 0x1p10 "Mi" 0x1p20 "Gi" 0x1p30 "Ti" 0x1p40 "Pi" 0x1p50 "Ei" 0x1p60 }}
{{- $base10 := dict "m" 1e-3 "k" 1e3 "M" 1e6 "G" 1e9 "T" 1e12 "P" 1e15 "E" 1e18 }}
{{- range $k, $v := merge $base2 $base10 }}
{{- if hasSuffix $k $ }}
{{- $value = trimSuffix $k $ }}
{{- $unit = $v }}
{{- end }}
{{- end }}
{{- end }}
{{- mulf (float64 $value) $unit }}
{{- end -}}

{{- define "gomemlimit" -}}
{{- if or .Values.global.autoscaling.enabled .Values.autoscaling.enabled .Values.global.resourceLimits }}
  {{- if ne (len .Values.resources) 0 }}
    {{- with .Values.resources }}{{- with .limits }}{{- with .memory }}
    {{- include "resource-quantity" . | float64 | mulf 0.90 | ceil | int }}
    {{- end }}{{- end }}{{- end }}
  {{- else }}
    {{- with .Values.global.resources }}{{- with .limits }}{{- with .memory }}
    {{- include "resource-quantity" . | float64 | mulf 0.90 | ceil | int }}
    {{- end }}{{- end }}{{- end }}
  {{- end }}
{{- else }}
  {{- $memory := "1024Mi" }}
  {{- include "resource-quantity" $memory | float64 | mulf 0.90 | ceil | int }}
{{- end }}
{{- end -}}

{{- define "gomemlimit-worker-gateway" -}}
{{- if or .Values.global.autoscaling.enabled .Values.autoscaling.enabled .Values.global.resourceLimits }}
  {{- if ne (len .Values.gatewayresources) 0 }}
    {{- with .Values.gatewayresources }}{{- with .limits }}{{- with .memory }}
    {{- include "resource-quantity" . | float64 | mulf 0.90 | ceil | int }}
    {{- end }}{{- end }}{{- end }}
  {{- else }}
    {{- with .Values.global.gatewayresources }}{{- with .limits }}{{- with .memory }}
    {{- include "resource-quantity" . | float64 | mulf 0.90 | ceil | int }}
    {{- end }}{{- end }}{{- end }}
  {{- end }}
{{- else }}
  {{- $memory := "1024Mi" -}}
  {{- include "resource-quantity" $memory | float64 | mulf 0.90 | ceil | int }}
{{- end }}
{{- end -}}
