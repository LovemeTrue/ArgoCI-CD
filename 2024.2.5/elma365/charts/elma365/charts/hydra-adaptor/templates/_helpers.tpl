{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "hydra-adaptor.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "hydra-adaptor.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create rabbitmq user based on namespace
*/}}
{{- define "hydra-adaptor.rmquser" -}}
{{- printf "%s-%s" .Release.Namespace .Chart.Name | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "hydra-adaptor.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}


{{/*
Common labels
*/}}
{{- define "hydra-adaptor.labels" -}}
helm.sh/chart: {{ include "hydra-adaptor.chart" . }}
{{ include "hydra-adaptor.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "hydra-adaptor.selectorLabels" -}}
app: {{ .Chart.Name }}
tier: elma365
app.kubernetes.io/name: {{ include "hydra-adaptor.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}


{{/*
Определение ingress TLS
Если секрет уже существует - подставляем его
Секрет должен содержать и $host и *.$host домены
*/}}
{{- define "ingressTLS" -}}
{{- $root :=  . | first }}
{{- $hostInput := index . 1 }}
{{- if $root.Values.global.ingress.existingTLSSecret -}}
tls:
  - secretName: {{ $root.Values.global.ingress.existingTLSSecret }}
    hosts:
      {{- include "ingress-host" $hostInput | nindent 6 }}
{{- end }}
{{- /*это на всяк случай */}}
{{- if or (index $root.Values.ingress.annotations "ingress.elma365.com/acme-tls") (index $root.Values.global.ingress.annotations "ingress.elma365.com/acme-tls") -}}
    {{- $secretName := "elma365-tls" -}}
    {{- if kindIs "slice" $hostInput -}}
    {{- $secretName = "elma365-subdomain-tls" -}}
    {{- end -}}
tls:
  - secretName: {{ $secretName }}
    hosts:
      {{- include "ingress-host" $hostInput | nindent 6 }}
{{- end -}}
{{- end }}

{{/*
Составление списка хостов для tls правил,
зависит от того - передан 1 хост или массив
*/}}
{{- define "ingress-host" -}}
  {{- $hostInput := . -}}
  {{- if kindIs "slice" $hostInput -}}
    {{- range $host := $hostInput -}}
    - '{{ $host }}'
    {{- end -}}
  {{- else -}}
    - '{{ $hostInput }}'
  {{- end -}}
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

{{/*
Returns true if the ingressClassname field is supported
Usage:
{{ include "hydra-adaptor.supportsIngressClassname" . }}
*/}}
{{- define "hydra-adaptor.supportsIngressClassname" -}}
{{- if semverCompare "<1.18-0" (include "kubeVersion" .) -}}
{{- print "false" -}}
{{- else -}}
{{- print "true" -}}
{{- end -}}
{{- end -}}
