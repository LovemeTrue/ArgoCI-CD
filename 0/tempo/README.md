# Tempo

Tempo

## Prerequisites

- Kubernetes 1.16+
- Helm 3+

## Add Helm Chart Repository

```console
helm repo add elma365 https://charts.elma365.tech
helm repo update
```

## Creating a bucket in minio.

```console
mc alias set my_alias http://minio.local accessKey secretKey
mc mb -p my_alias/tempo --region=ru-central-1
```

## Configure values

## Install Chart

```console
helm show values elma365/tempo > values-tempo.yaml
helm upgrade --install -n namespace tempo elma365/tempo -f values-tempo.yaml
```

## Uninstall Chart

```console
helm uninstall [RELEASE_NAME]
```

## Configuration

The following table lists the configurable parameters of the Tempo chart and their default values.

| Parameter                | Description             | Default        |
| ------------------------ | ----------------------- | -------------- |
| `tempo.tempo.tempo.retention` |  | `"24h"` |
| `tempo.tempo.tempo.storage.trace.backend` |  | `"s3"` |
| `tempo.tempo.tempo.storage.trace.s3.bucket` | store traces in this bucket | `"tempo"` |
| `tempo.tempo.tempo.storage.trace.s3.endpoint` | api endpoint | `"minio.local:9000"` |
| `tempo.tempo.tempo.storage.trace.s3.access_key` | optional. access key when using static credentials. | `"access_key"` |
| `tempo.tempo.tempo.storage.trace.s3.secret_key` | optional. secret key when using static credentials. | `"secret_key"` |
| `tempo.tempo.tempo.storage.trace.s3.insecure` | optional. enable if endpoint is http | `true` |
| `tempo.jaeger-all-in-one.environmentVariables.MEMORY_MAX_TRACES` |  | `100000` |
| `tempo.jaeger-all-in-one.environmentVariables.SPAN_STORAGE_TYPE` |  | `"badger"` |
| `tempo.jaeger-all-in-one.environmentVariables.BADGER_EPHEMERAL` |  | `false` |
| `tempo.jaeger-all-in-one.environmentVariables.BADGER_DIRECTORY_VALUE` |  | `"/badger/data"` |
| `tempo.jaeger-all-in-one.environmentVariables.BADGER_DIRECTORY_KEY` |  | `"/badger/key"` |
| `tempo.jaeger-all-in-one.environmentVariables.REPORTER_TYPE` |  | `"grpc"` |
| `tempo.jaeger-all-in-one.environmentVariables.REPORTER_GRPC_HOST_PORT` |  | `"tempo:14250"` |
| `tempo.jaeger-all-in-one.environmentVariables.REPORTER_GRPC_RETRY_MAX` |  | `100` |
| `tempo.jaeger-all-in-one.tolerations` |  | `[{"key": "dedicated", "operator": "Equal", "value": "staging", "effect": "NoSchedule"}]` |
| `tempo.jaeger.nodeSelector` |  | `{}` |
| `tempo.jaeger.affinity` |  | `{}` |