{{/*
Expand the name of the chart.
*/}}
{{- define "intercluster.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "intercluster.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
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

{{/*
Составление списка хостов для tls правил,
зависит от того - передан 1 хост или массив
*/}}
{{- define "ingress-host" -}}
  {{- $hostInput := . -}}
  {{- if kindIs "slice" $hostInput -}}
    {{- range $host := $hostInput -}}
    {{- printf "- '%s'\n" $host -}}
    {{- end -}}
  {{- else -}}
    - '{{ $hostInput }}'
  {{- end -}}
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
Common labels
*/}}
{{- define "intercluster.labels" -}}
helm.sh/chart: {{ include "intercluster.chart" . }}
{{- range $k,$v := .Values.global.labels }}
{{ $k }}: {{ $v | quote }}
{{- end }}
{{ include "intercluster.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "intercluster.selectorLabels" -}}
app: {{ include "intercluster.name" . }}
tier: elma365
app.kubernetes.io/name: {{ include "intercluster.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "intercluster.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "intercluster.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Create rabbitmq user basen on namespace
*/}}
{{- define "intercluster.rmquser" -}}
{{- printf "%s-%s" .Release.Namespace .Chart.Name | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}
