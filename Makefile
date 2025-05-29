# === config ===
DBS_MSG ?= обновление параметров БД
REPO_URL = https://github.com/LovemeTrue/ArgoCI-CD.git

# === targets ===

.PHONY: help
help:
	@echo "🛠 Make targets:"
	@echo "  make release-full VERSION=2025.4.1    # Создать релиз версии elma365, сгенерить apps для каждого чарта и выполнть git clean локальных веток.


VERSION ?= 0
APPS_DIR := apps

.PHONY: release
release:
	@echo "🚀 Выполняю выпуск версии $(VERSION)"
	rm -rf $(VERSION)/elma365 $(VERSION)/elma365-dbs

	@echo "📦 Скачиваем чарт elma365..."
	helm pull elma365/elma365 --version $(VERSION) --untar
	mkdir -p $(VERSION)/elma365
	mv elma365/* $(VERSION)/elma365/
	rm -rf elma365

	@echo "📥 Копируем values-elma365.yaml"
	cp values/values-elma365.yaml $(VERSION)/elma365/

	@echo "📦 Скачиваем чарт elma365-dbs..."
	helm pull elma365/elma365-dbs --untar
	mkdir -p $(VERSION)/elma365-dbs
	mv elma365-dbs/* $(VERSION)/elma365-dbs/
	rm -rf elma365-dbs

	@echo "📥 Копируем values-elma365-dbs.yaml"
	cp values/values-elma365-dbs.yaml $(VERSION)/elma365-dbs/

	@git add $(VERSION)
	@git commit -m "📦 Добавлена версия $(VERSION) с чартами и values" || echo "🟡 Нет новых файлов для коммита"

	@if git tag | grep -q "^$(VERSION)$$"; then \
		echo "🔁 Git tag $(VERSION) уже существует, пропускаю тегирование."; \
	else \
		git tag -a $(VERSION) -m "Release $(VERSION)"; \
		git push origin --tags; \
	fi

	@git push

AAPPS_DIR := apps

.PHONY: gen-apps
gen-apps:
	@echo "📁 Генерирую приложения ArgoCD для версии $(VERSION)..."
	@mkdir -p $(APPS_DIR)
	
	@# Генерация elma365-$(VERSION).yaml
	@echo "📄 Перезаписываю $(APPS_DIR)/elma365-$(VERSION).yaml"
	@echo "apiVersion: argoproj.io/v1alpha1" > $(APPS_DIR)/elma365-$(VERSION).yaml
	@echo "kind: Application" >> $(APPS_DIR)/elma365-$(VERSION).yaml
	@echo "metadata:" >> $(APPS_DIR)/elma365-$(VERSION).yaml
	@echo "  name: elma365-$(VERSION)" >> $(APPS_DIR)/elma365-$(VERSION).yaml
	@echo "  namespace: argocd" >> $(APPS_DIR)/elma365-$(VERSION).yaml
	@echo "  annotations:" >> $(APPS_DIR)/elma365-$(VERSION).yaml
	@echo "    argocd.argoproj.io/sync-wave: \"1\"" >> $(APPS_DIR)/elma365-$(VERSION).yaml
	@echo "    argocd.argoproj.io/depends-on: \"[elma365-dbs]\"" >> $(APPS_DIR)/elma365-$(VERSION).yaml
	@echo "spec:" >> $(APPS_DIR)/elma365-$(VERSION).yaml
	@echo "  project: default" >> $(APPS_DIR)/elma365-$(VERSION).yaml
	@echo "  source:" >> $(APPS_DIR)/elma365-$(VERSION).yaml
	@echo "    repoURL: https://github.com/LovemeTrue/ArgoCI-CD.git" >> $(APPS_DIR)/elma365-$(VERSION).yaml
	@echo "    targetRevision: main" >> $(APPS_DIR)/elma365-$(VERSION).yaml
	@echo "    path: $(VERSION)/elma365" >> $(APPS_DIR)/elma365-$(VERSION).yaml
	@echo "    helm:" >> $(APPS_DIR)/elma365-$(VERSION).yaml
	@echo "      valueFiles:" >> $(APPS_DIR)/elma365-$(VERSION).yaml
	@echo "        - values-elma365.yaml" >> $(APPS_DIR)/elma365-$(VERSION).yaml
	@echo "  destination:" >> $(APPS_DIR)/elma365-$(VERSION).yaml
	@echo "    server: https://kubernetes.default.svc" >> $(APPS_DIR)/elma365-$(VERSION).yaml
	@echo "    namespace: elma365" >> $(APPS_DIR)/elma365-$(VERSION).yaml
	@echo "  syncPolicy:" >> $(APPS_DIR)/elma365-$(VERSION).yaml
	@echo "    automated:" >> $(APPS_DIR)/elma365-$(VERSION).yaml
	@echo "      prune: true" >> $(APPS_DIR)/elma365-$(VERSION).yaml
	@echo "      selfHeal: true" >> $(APPS_DIR)/elma365-$(VERSION).yaml

	@# Генерация elma365-dbs.yaml
	@echo "📄 Перезаписываю $(APPS_DIR)/elma365-dbs.yaml"
	@echo "apiVersion: argoproj.io/v1alpha1" > $(APPS_DIR)/elma365-dbs.yaml
	@echo "kind: Application" >> $(APPS_DIR)/elma365-dbs.yaml
	@echo "metadata:" >> $(APPS_DIR)/elma365-dbs.yaml
	@echo "  name: elma365-dbs" >> $(APPS_DIR)/elma365-dbs.yaml
	@echo "  namespace: argocd" >> $(APPS_DIR)/elma365-dbs.yaml
	@echo "  annotations:" >> $(APPS_DIR)/elma365-dbs.yaml
	@echo "    argocd.argoproj.io/sync-wave: \"0\"" >> $(APPS_DIR)/elma365-dbs.yaml
	@echo "spec:" >> $(APPS_DIR)/elma365-dbs.yaml
	@echo "  project: default" >> $(APPS_DIR)/elma365-dbs.yaml
	@echo "  source:" >> $(APPS_DIR)/elma365-dbs.yaml
	@echo "    repoURL: https://github.com/LovemeTrue/ArgoCI-CD.git" >> $(APPS_DIR)/elma365-dbs.yaml
	@echo "    targetRevision: main" >> $(APPS_DIR)/elma365-dbs.yaml
	@echo "    path: $(VERSION)/elma365-dbs" >> $(APPS_DIR)/elma365-dbs.yaml
	@echo "    helm:" >> $(APPS_DIR)/elma365-dbs.yaml
	@echo "      valueFiles:" >> $(APPS_DIR)/elma365-dbs.yaml
	@echo "        - values-elma365-dbs.yaml" >> $(APPS_DIR)/elma365-dbs.yaml
	@echo "  destination:" >> $(APPS_DIR)/elma365-dbs.yaml
	@echo "    server: https://kubernetes.default.svc" >> $(APPS_DIR)/elma365-dbs.yaml
	@echo "    namespace: elma365-dbs" >> $(APPS_DIR)/elma365-dbs.yaml
	@echo "  syncPolicy:" >> $(APPS_DIR)/elma365-dbs.yaml
	@echo "    automated:" >> $(APPS_DIR)/elma365-dbs.yaml
	@echo "      prune: true" >> $(APPS_DIR)/elma365-dbs.yaml
	@echo "      selfHeal: true" >> $(APPS_DIR)/elma365-dbs.yaml

	@# Git операции
	@if [ -n "$$(git status --porcelain $(APPS_DIR))" ]; then \
		git add $(APPS_DIR)/elma365-$(VERSION).yaml $(APPS_DIR)/elma365-dbs.yaml; \
		git commit -m "🔁 Перегенерация ArgoCD приложений для версии $(VERSION)"; \
		git push; \
	else \
		echo "🟡 Нет изменений для коммита"; \
	fi


.PHONY: cleanup-git
cleanup-git:
	@echo "🧹 Удаляю локальные ветки кроме main..."
	@git branch | grep -v "^\* main" | grep -v "main" | xargs -r git branch -D
	@git checkout main
	@git pull
	@echo "✅ Возврат в main и удаление лишних веток завершено"
.PHONY: release-full
release-full: release gen-apps cleanup-git
	@echo "✅ Полный релиз $(VERSION) завершён: чарты, values, приложения"
