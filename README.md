# 🚀 Elma365 GitOps Platform with ArgoCD & Helm

Этот репозиторий реализует **GitOps-платформу** для деплоя `elma365` и `elma365-dbs` в Kubernetes через **ArgoCD + Helm**, с полной автоматизацией через Makefile.

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
.
├── Makefile                     # Главный механизм CI/CD
├── apps/                        # ArgoCD Application YAML-файлы
├── 2025.4.2/                    # Пример версии чарта
│   ├── elma365/
│   │   ├── Chart.yaml
│   │   ├── values-elma365.yaml
│   └── elma365-dbs/
│       ├── Chart.yaml
│       ├── values-elma365-dbs.yaml
├── ssl/                         # TLS-сертификаты и корневой CA
│   ├── kind.elewise.local.crt
│   ├── kind.elewise.local.key
│   └── rootCA.pem
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
🛠 Makefile Targets

🔁 make release-full VERSION=2025.4.2

Полный GitOps-релиз:
	•	Скейлит и удаляет namespace elma365, elma365-dbs
	•	Удаляет ArgoCD приложения и finalizer’ы
	•	Создаёт namespace’ы заново, применяет label’ы
	•	Создаёт TLS-секреты и ConfigMap с CA
	•	Скачивает нужную версию чарта
	•	Копирует values-файлы
	•	Генерирует ArgoCD Application YAML
	•	Обновляет root-app через hard-refresh

🧼 make clean-argocd

Чистка всего окружения:
	•	Удаляет namespace’ы (с finalizer-hook обработкой)
	•	Удаляет ArgoCD приложения
	•	Удаляет YAML-файлы в apps/
	•	Создаёт заново секреты и configmap
	•	Обновляет root-app

📦 make release VERSION=...

Скачивает Helm-чарты в нужную версию и создаёт структуру /VERSION/elma365/, /VERSION/elma365-dbs/

📄 make gen-apps VERSION=...

Генерирует YAML-файлы ArgoCD Application:
	•	apps/elma365-$(VERSION).yaml
	•	apps/elma365-dbs.yaml
С учётом syncWave, depends-on, valueFiles

✏️ make update-values

Коммитит изменения в values-elma365.yaml (если есть) → триггерит ArgoCD sync

⸻

🔐 TLS и CA

Секреты автоматически создаются:
	•	elma365-onpremise-tls — в elma365 и elma365-dbs
	•	elma365-onpremise-ca — в elma365

Файлы должны находиться в ./ssl/:
	•	kind.elewise.local.crt
	•	kind.elewise.local.key
	•	rootCA.pem

⸻

🧠 Finalizer Hook Fix

Внутри make clean-argocd автоматически очищаются все argocd.argoproj.io/hook-finalizer, чтобы корректно удалять namespace elma365.

## 🚀 Деплой новой версии

Пример для версии `2025.4.3`:

```sh
make release-full VERSION=2025.4.3
```
🤝 Авторы и поддержка

Создан и поддерживается с ❤️
Контакты: @SimplicityOfTheGospel
