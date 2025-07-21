# Loki

Loki

## Prerequisites

- Kubernetes 1.19+
- Helm 3+

## Add Helm Chart Repository

```console
helm repo add elma365 https://charts.elma365.tech
helm repo update
```

## Creating buckets and setting lifecycle rules in minio.

```console
mc alias set my_alias http://minio.local accessKey secretKey
mc mb -p my_alias/admin --region=ru-central-1
mc mb -p my_alias/chunks --region=ru-central-1
mc mb -p my_alias/rules --region=ru-central-1

## Configure values

## Install Chart

```console
helm show values elma365/loki > values-loki.yaml
helm upgrade --install -n namespace loki elma365/loki -f values-loki.yaml
```

## Uninstall Chart

```console
helm uninstall [RELEASE_NAME]
```

## Requirements

| Repository | Name | Version |
|------------|------|---------|
|  | loki |  |
|  | promtail |  |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| loki.backend | object | `{"autoscaling":{"enabled":false,"maxReplicas":6,"minReplicas":2},"replicas":1}` | Конфигурация модулей бэкенда |
| loki.chunksCache.enabled | bool | `false` |  |
| loki.deploymentMode | string | `"SimpleScalable"` | Режим развертывания позволяет указать способ развертывания Loki. |
| loki.enterprise | object | `{"enabled":false,"gelGateway":false}` | Конфигурация для запуска Enterprise Loki |
| loki.enterprise.gelGateway | bool | `false` | Использовать шлюз GEL, если false, будет использоваться шлюз nginx по умолчанию. |
| loki.gateway | object | `{"autoscaling":{"enabled":false,"maxReplicas":3,"minReplicas":1},"enabled":true,"replicas":1,"verboseLogging":true}` | Конфигурация модулей шлюза |
| loki.global | object | `{"image":{"registry":null}}` | параметры подключения к приватному registry |
| loki.imagePullSecrets | list | `[]` |  |
| loki.loki.auth_enabled | bool | `false` | Включение аутентификации |
| loki.loki.commonConfig.replication_factor | int | `1` |  |
| loki.loki.compactor | object | `{"compaction_interval":"10m","delete_request_store":"s3","retention_delete_delay":"2h","retention_delete_worker_count":150,"retention_enabled":true,"working_directory":"/var/loki/chunks"}` | Дополнительная конфигурация уплотнителя |
| loki.loki.limits_config | object | `{"per_stream_rate_limit":"512M","per_stream_rate_limit_burst":"1024M","retention_period":"744h"}` | Конфигурация лимитов |
| loki.loki.schemaConfig | object | `{"configs":[{"from":"2024-04-01","index":{"period":"24h","prefix":"index_"},"object_store":"s3","schema":"v13","store":"tsdb"}]}` | Настройка схемы |
| loki.loki.storage | object | `{"bucketNames":{"admin":"admin","chunks":"chunks","ruler":"ruler"},"s3":{"accessKeyId":"accessKeyId","endpoint":"minio.local:9000","http_config":{},"insecure":true,"region":"ru-central-1","s3":null,"s3ForcePathStyle":true,"secretAccessKey":"secretAccessKey","signatureVersion":null},"type":"s3"}` | Конфигурация хранилища. |
| loki.loki.useTestSchema | bool | `false` |  |
| loki.lokiCanary.enabled | bool | `false` |  |
| loki.read | object | `{"autoscaling":{"enabled":false,"maxReplicas":6,"minReplicas":2},"replicas":1}` | Конфигурация модулей чтения |
| loki.test | object | `{"enabled":false}` | Раздел для настройки дополнительного теста Helm |
| loki.write | object | `{"autoscaling":{"enabled":false,"maxReplicas":6,"minReplicas":2},"replicas":1}` | Конфигурация модулей записи |
| promtail | object | `{"config":{"clients":[{"url":"http://loki-gateway/loki/api/v1/push"}],"enabled":true,"serverPort":3101},"daemonset":{"autoscaling":{"enabled":false},"enabled":true},"deployment":{"autoscaling":{"enabled":false,"maxReplicas":10,"minReplicas":1},"enabled":false,"replicaCount":1},"global":{"imagePullSecrets":[],"imageRegistry":""}}` | Настройка promtail |
| promtail.config | object | `{"clients":[{"url":"http://loki-gateway/loki/api/v1/push"}],"enabled":true,"serverPort":3101}` | Конфигурация Promtail |
| promtail.daemonset.enabled | bool | `true` | Развертывает Promtail как DaemonSet |
| promtail.deployment.enabled | bool | `false` | Развертывает Promtail как Deployment |
| promtail.global | object | `{"imagePullSecrets":[],"imageRegistry":""}` | параметры подключения к приватному registry |

----------------------------------------------
