# Monitoring

Под установкой средств мониторинга подразумевается развёртывание в kubernetes кластере Prometheus (для хранения временных рядов) и Grafana (для визуализации).

## Установка

Установка состоит из 3 этапов:

1. Скачивание helm-чарта и конфигурационного файла.
2. Заполнение конфигурационного файла.
3. Установка с помощью helm в Kubernetes-кластер

#### 1. Скачивание helm-чарта и конфигурационного файла

```shell
helm repo add elma365 https://charts.elma365.tech
helm repo update
helm show values elma365/monitoring > values-monitoring.yaml
```

#### 2. Заполнение конфигурационного файла values-monitoring.yaml

#### 3. Установка с помощью helm

```shell
helm upgrade --install elma365-monitoring elma365/monitoring -f values-monitoring.yaml -n monitoring --create-namespace
```

## Удаление

```shell
$ helm uninstall -n monitoring elma365-monitoring
```
## Requirements

Kubernetes: `>=1.19.0-0`

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| kube-prometheus-stack.grafana.adminPassword | string | `"admin"` | учетные данные администратора |
| kube-prometheus-stack.grafana.adminUser | string | `"admin"` | учетные данные администратора |
| kube-prometheus-stack.grafana.assertNoLeakedSecrets | bool | `false` |  |
| kube-prometheus-stack.grafana.ingress.annotations | object | `{}` |  |
| kube-prometheus-stack.grafana.ingress.enabled | bool | `true` |  |
| kube-prometheus-stack.grafana.ingress.hosts[0] | string | `"grafana.mycompany.com"` | адрес по которому будет доступна grafana |
| kube-prometheus-stack.grafana.ingress.ingressClassName | string | `"nginx"` |  |
| kube-prometheus-stack.grafana.plugins[0] | string | `"camptocamp-prometheus-alertmanager-datasource"` | список используемых плагинов |
| kube-prometheus-stack.grafana.plugins[1] | string | `"flant-statusmap-panel"` | список используемых плагинов |
| kube-prometheus-stack.grafana.plugins[2] | string | `"vonage-status-panel"` | список используемых плагинов |
| kube-prometheus-stack.grafana.sidecar.datasources | object | `{"defaultDatasourceEnabled":true,"enabled":true,"isDefaultDatasource":true,"uid":"prometheus","url":"http://mimir-nginx:80/prometheus"}` | включить mimir в качестве источника данных |
| kube-prometheus-stack.grafana.sidecar.dashboards.annotations | string | `nil` |  |
| kube-prometheus-stack.grafana.sidecar.dashboards.enabled | bool | `true` |  |
| kube-prometheus-stack.grafana.sidecar.dashboards.folderAnnotation | string | `"grafana-dashboard-folder"` |  |
| kube-prometheus-stack.grafana.sidecar.dashboards.label | string | `"grafana_dashboard"` |  |
| kube-prometheus-stack.grafana.sidecar.dashboards.labelValue | string | `""` |  |
| kube-prometheus-stack.grafana.sidecar.dashboards.provider.allowUiUpdates | bool | `true` |  |
| kube-prometheus-stack.grafana.sidecar.dashboards.provider.foldersFromFilesStructure | bool | `true` |  |
| kube-prometheus-stack.prometheus.prometheusSpec.replicas | int | `1` |  |
| kube-prometheus-stack.prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues | bool | `false` |  |
| kube-prometheus-stack.prometheus.prometheusSpec.remoteWrite | list | `[{"url":"http://mimir-nginx:80/api/v1/push"}]` | включить mimir в качестве долгосрочного хранилища |

----------------------------------------------