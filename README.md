# 🚀 Elma365 GitOps Platform with ArgoCD & Helm

Этот репозиторий реализует **GitOps-платформу** для деплоя `elma365` и `elma365-dbs` в Kubernetes через **ArgoCD + Helm**, с полной автоматизацией через Makefile и GitHub Actions.

---

## 🧰 Возможности

- 📦 Установка Helm-чартов `elma365` и `elma365-dbs`
- 🔁 Управление версиями — только одна актуальная версия чарта в кластере
- 🔄 Автоматическая синхронизация с ArgoCD
- 🧹 Удаление старых приложений и локальных Git-веток
- 🛠 CI/CD через GitHub Actions
- ☁️ АргоCD App of Apps + `sync-wave` + `depends-on`

---

## ⚙️ Требования к окружению

На машине, откуда ты администрируешь деплой, установи:

| Пакет       | Назначение                            |
|-------------|----------------------------------------|
| `kubectl`   | Работа с Kubernetes                    |
| `helm`      | Работа с Helm-чартами                  |
| `make`      | Выполнение целей Makefile              |
| `yq`        | Редактирование YAML (CLI)              |
| `git`       | Работа с Git                           |
| `gh`        | GitHub CLI — создание Pull Request     |
| `argocd`    | CLI для ArgoCD (опционально)           |

---

## 📂 Структура репозитория
```
├── apps/ # ArgoCD Application YAML'ы
├── values/ # values-файлы для Helm
├── 2025.4.3/
│ ├── elma365/ # чарт + values
│ └── elma365-dbs/ # чарт + values
├── Makefile # Автоматизация
├── .github/workflows/ # CI (ArgoCD sync, helm validate)
```
---

## 🔧 Возможности Makefile

| Команда                              | Что делает                                                   |
|--------------------------------------|--------------------------------------------------------------|
| `make release VERSION=2025.4.3`      | Скачивает чарты elma365/elma365-dbs и копирует values        |
| `make gen-apps VERSION=2025.4.3`     | Генерирует YAML-файлы ArgoCD Application                    |
| `make release-full VERSION=...`      | Полный цикл: release → cleanup → gen-apps → git push         |
| `make cleanup-old-apps`              | Удаляет старые `apps/elma365-*.yaml`, кроме текущей версии   |
| `make cleanup-local-branches`        | Удаляет все локальные Git-ветки кроме `main`                 |
| `make delete-old-applications`       | Удаляет старые ArgoCD Application из кластера                |

---

## 🚀 Деплой новой версии

Пример для версии `2025.4.3`:

```bash
make release-full VERSION=2025.4.3
