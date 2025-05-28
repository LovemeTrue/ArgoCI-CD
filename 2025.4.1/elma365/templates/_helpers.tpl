{{- define "calculateResources" -}}
{{- $totalRequestsMemory := 0 -}}
{{- $totalRequestsCPU := 0 -}}
{{- $totalLimitsMemory := 0 -}}
{{- $totalLimitsCPU := 0 -}}
{{- $totalRequestsMemoryMax := 0 -}}
{{- $totalRequestsCPUMax := 0 -}}
{{- $totalLimitsMemoryMax := 0 -}}
{{- $totalLimitsCPUMax := 0 -}}
{{- $autoscalingMin := 1 -}}
{{- $autoscalingMax := 1 -}}
{{- $replicaCount := .Values.elma365.global.replicaCount | default 1 -}}
{{- $reqmemory := .Values.elma365.global.resources.requests.memory | default "0Mi" | trimSuffix "Mi" -}}
{{- $reqcpu := .Values.elma365.global.resources.requests.cpu | default "0m" | trimSuffix "m" -}}
{{- $limmemory := .Values.elma365.global.resources.limits.memory | default "0Mi" | trimSuffix "Mi" -}}
{{- $limcpu := .Values.elma365.global.resources.limits.cpu | default "0m" | trimSuffix "m"  -}}
{{- $autoscalingServiceMin := 1 -}}
{{- $autoscalingServiceMax := 1 -}}
{{- $totalmicroservices := 59 -}}
{{- $countmicroservices := 0 -}}
{{- $replicaCountService:= 1 }}


  {{- if .Values.elma365.global.autoscaling.enabled -}}
    {{- $autoscalingMin = .Values.elma365.global.autoscaling.minReplicas -}}
    {{- $autoscalingMax = .Values.elma365.global.autoscaling.maxReplicas -}}
    {{- $replicaCount = 1 }}
    {{- $replicaCountService = 1 }}
    {{- $autoscalingServiceMin = $autoscalingMin -}}
    {{- $autoscalingServiceMax = $autoscalingMax -}}
  {{- end -}}


{{- range $service, $config := .Values.elma365 -}}

  {{- if and (kindIs "map" $config) (ne $service "global" ) (ne $service "db") -}}
    {{- if and $config.autoscaling $config.autoscaling.enabled -}}
      {{- $autoscalingServiceMin = $config.autoscaling.minReplicas | default $autoscalingMin -}}
      {{- $autoscalingServiceMax = $config.autoscaling.maxReplicas | default $autoscalingMax -}}
    {{- else -}}
      {{- if not $.Values.elma365.global.autoscaling.enabled -}}
        {{- $replicaCountService = $config.replicaCount | default $replicaCount }}
        {{- $autoscalingServiceMin = $replicaCountService -}}
      {{- end -}}
    {{- end -}}
    {{- if hasKey $config "resources" -}}
      {{- with $config.resources -}}
        {{- if kindIs "map" . -}}
          {{- if hasKey . "requests" -}}
            {{- $countmicroservices = add $countmicroservices 1 -}}
            {{- with .requests -}}
              {{- if kindIs "map" . -}}
                {{- if hasKey . "memory" -}}
                  {{- $totalRequestsMemory = add $totalRequestsMemory (mul (trimSuffix "Mi" .memory) $autoscalingServiceMin) -}}
                  {{- $totalRequestsMemoryMax = add $totalRequestsMemoryMax (mul (trimSuffix "Mi" .memory) $autoscalingServiceMax) -}}
                {{- end -}}
                {{- if hasKey . "cpu" -}}
                  {{- $totalRequestsCPU = add $totalRequestsCPU (mul (trimSuffix "m" .cpu) $autoscalingServiceMin) -}}
                  {{- $totalRequestsCPUMax = add $totalRequestsCPUMax (mul (trimSuffix "m" .cpu) $autoscalingServiceMax) -}}
                {{- end -}}
              {{- end -}}
            {{- end -}}
          {{- end -}}
          {{- if hasKey . "limits" -}}
            {{- with .limits -}}
              {{- if kindIs "map" . -}}
                {{- if hasKey . "memory" -}}
                  {{- $totalLimitsMemory = add $totalLimitsMemory (mul (trimSuffix "Mi" .memory) $autoscalingServiceMin) -}}
                  {{- $totalLimitsMemoryMax = add $totalLimitsMemoryMax (mul (trimSuffix "Mi" .memory) $autoscalingServiceMax) -}}
                {{- end -}}
                {{- if hasKey . "cpu" -}}
                  {{- $totalLimitsCPU = add $totalLimitsCPU (mul (trimSuffix "m" .cpu) $autoscalingServiceMin) -}}
                  {{- $totalLimitsCPUMax = add $totalLimitsCPUMax (mul (trimSuffix "m" .cpu) $autoscalingServiceMax) -}}
                {{- end -}}
              {{- end -}}
            {{- end -}}
          {{- end -}}
        {{- end -}}
      {{- end -}}
    {{- else -}}
      {{- $replicaCountService := $config.replicaCount | default $replicaCount -}}
      {{- $totalRequestsMemory = add $totalRequestsMemory (mul $reqcpu $replicaCountService) -}}
      {{- $totalRequestsCPU = add $totalRequestsCPU (mul $reqmemory $replicaCountService) -}}
      {{- $totalLimitsMemory = add $totalLimitsMemory (mul $limcpu $replicaCountService) -}}
      {{- $totalLimitsCPU = add $totalLimitsCPU (mul $limmemory $replicaCountService) -}}
  {{ end }}
  {{- end -}}
{{- end -}}

{{- $ncount := sub $totalmicroservices $countmicroservices -}}

{{- if .Values.elma365.global.autoscaling.enabled -}}
  {{- $autoscalingMax = .Values.elma365.global.autoscaling.maxReplicas -}}
  {{- $autoscalingMin = .Values.elma365.global.autoscaling.minReplicas -}}
  {{- $totalRequestsMemoryMax = add $totalRequestsMemoryMax (mul $ncount $reqmemory $autoscalingMax) -}}
  {{- $totalRequestsCPUMax = add $totalRequestsCPUMax (mul $ncount $reqcpu $autoscalingMax) -}}
  {{- $totalLimitsMemoryMax = add $totalLimitsMemoryMax (mul $ncount $limmemory $autoscalingMax) -}}
  {{- $totalLimitsCPUMax = add $totalLimitsCPUMax (mul $ncount $limmemory $autoscalingMax) -}}
  {{- $totalRequestsMemory = add $totalRequestsMemory (mul $ncount $reqmemory $autoscalingMin) -}}
  {{- $totalRequestsCPU = add $totalRequestsCPU (mul $ncount $reqcpu $autoscalingMin) -}}
  {{- $totalLimitsMemory = add $totalLimitsMemory (mul $ncount $limmemory $autoscalingMin) -}}
  {{- $totalLimitsCPU = add $totalLimitsCPU (mul $ncount $limmemory $autoscalingMin) -}}
{{- else -}}
  {{- $totalRequestsMemory = add $totalRequestsMemory (mul $ncount $reqmemory $replicaCount) -}}
  {{- $totalRequestsCPU = add $totalRequestsCPU (mul $ncount $reqcpu $replicaCount) -}}
  {{- $totalLimitsMemory = add $totalLimitsMemory (mul $ncount $limmemory $replicaCount) -}}
  {{- $totalLimitsCPU = add $totalLimitsCPU (mul $ncount $limmemory $replicaCount) -}}
{{- end -}}


{{- printf "%d %d %d %d %d %d %d %d %d" $totalRequestsMemory $totalRequestsCPU $totalLimitsMemory $totalLimitsCPU $totalRequestsMemoryMax $totalRequestsCPUMax $totalLimitsMemoryMax $totalLimitsCPUMax (int $autoscalingMax) -}}
{{- end -}}
