# === config ===
CHART_VERSION ?= 2025.4.1
DBS_MSG ?= обновление параметров БД
REPO_URL = https://github.com/LovemeTrue/ArgoCI-CD.git

# === targets ===

.PHONY: help
help:
	@echo "🛠 Make targets:"
	@echo "  make bump VERSION=2025.4.2      # Обновить версию elma365 и создать PR"
	@echo "  make dbs-update DBS_MSG='...'  # Обновить values-elma365-dbs.yaml и PR"

.PHONY: bump
bump:
	@echo "🔄 Обновляем версию elma365 до $(CHART_VERSION)"
	git checkout main
	git pull origin main
	@if git show-ref --quiet refs/heads/update/elma365-$(CHART_VERSION); then \
		echo "⚠️ Ветка update/elma365-$(CHART_VERSION) уже существует. Удаляю..."; \
		git branch -D update/elma365-$(CHART_VERSION); \
	fi
	@git checkout -b update/elma365-$(CHART_VERSION)
	@yq e -i '.data.version = "$(CHART_VERSION)"' apps/elma365/chart-version.yaml
	@if git diff --quiet; then echo "✅ Версия уже актуальна."; exit 0; fi
	git add apps/elma365/chart-version.yaml
	git commit -m "🔄 bump elma365 chart to $(CHART_VERSION)"
	git push -u origin update/elma365-$(CHART_VERSION)
	gh pr create \
		--base main \
		--head update/elma365-$(CHART_VERSION) \
		--title "elma365: bump to $(CHART_VERSION)" \
		--body "This PR updates elma365 chart to version \`$(CHART_VERSION)\`."
		--web
	git checkout main
	git add -A
	git commit -m "AutoMakeCommit"
.PHONY: dbs-update
dbs-update:
	@echo "🔧 Обновляем elma365-dbs (values)"
	git checkout main
	git pull origin main
	@PR_BRANCH=update/elma365-dbs-`date +%Y%m%d-%H%M%S` && \
	git checkout -b $$PR_BRANCH && \
	if git diff --quiet apps/elma365-dbs/values-elma365-dbs.yaml; then echo "⚠️ Нет изменений — отмена."; exit 0; fi && \
	git add apps/elma365-dbs/values-elma365-dbs.yaml && \
	git commit -m "🔧 elma365-dbs: $(DBS_MSG)" && \
	git push -u origin $$PR_BRANCH && \
	gh pr create \
		--base main \
		--head $$PR_BRANCH \
		--title "elma365-dbs: $(DBS_MSG)" \
		--body "Changes in \`values-elma365-dbs.yaml\`: $(DBS_MSG)"
		--web
	git checkout main
	git add -A
	git commit -m "AutoMakeCommit"

.PHONY: sync-status

VERSION ?= 2025.4.3
APPS_DIR := apps

.PHONY: release
release:
	@echo "🚀 Выполняю выпуск версии $(VERSION)"
	helm repo add elma365 https://charts.elma365.tech
	helm repo update

	@echo "🧹 Очищаем старые директории, если есть..."
	rm -rf $(VERSION)/elma365 $(VERSION)/elma365-dbs
	
	@echo "📦 Скачиваем чарт elma365..."
	helm pull elma365/elma365 --version $(VERSION) --untar
	mkdir -p $(VERSION)/elma365
	mv elma365/* $(VERSION)/elma365/
	rm -rf elma365

	@echo "📥 Копируем values-elma365.yaml"
	cp values/values-elma365.yaml $(VERSION)/elma365/

	@echo "📦 Скачиваем чарт elma365-dbs (latest)"
	helm pull elma365/elma365-dbs --version latest --untar
	mkdir -p $(VERSION)/elma365-dbs
	mv elma365-dbs/* $(VERSION)/elma365-dbs/
	rm -rf elma365-dbs

	@echo "📥 Копируем values-elma365-dbs.yaml"
	cp values/values-elma365-dbs.yaml $(VERSION)/elma365-dbs/

	@git add $(VERSION)
	@git commit -m "📦 Добавлена версия $(VERSION) с чартами и values"
	@git tag -a $(VERSION) -m "Release $(VERSION)"
	@git push origin main --tags

.PHONY: gen-apps
gen-apps:
	@echo "📁 Генерирую приложения ArgoCD для версии $(VERSION)..."
	@mkdir -p $(APPS_DIR)

	@APP_FILE=$(APPS_DIR)/elma365-$(VERSION).yaml && \
	DBS_FILE=$(APPS_DIR)/elma365-dbs-$(VERSION).yaml && \

	echo "📄 Создаю $$APP_FILE" && \
	cat > $$APP_FILE <<EOF
	
	apiVersion: argoproj.io/v1alpha1
	kind: Application
	metadata:
	name: elma365-$(subst .,-,$(VERSION))
	namespace: argocd
	annotations:
		argocd.argoproj.io/sync-wave: "1"
	spec:
	project: default
	source:
		repoURL: https://github.com/LovemeTrue/ArgoCI-CD.git
		targetRevision: main
		path: $(VERSION)/elma365
		helm:
		valueFiles:
			- values-elma365.yaml
	destination:
		server: https://kubernetes.default.svc
		namespace: elma365
	syncPolicy:
		automated:
		prune: true
		selfHeal: true
	EOF

	echo "📄 Создаю $$DBS_FILE" && \
	cat > $$DBS_FILE <<EOF

	apiVersion: argoproj.io/v1alpha1
	kind: Application
	metadata:
	name: elma365-dbs-$(subst .,-,$(VERSION))
	namespace: argocd
	annotations:
		argocd.argoproj.io/sync-wave: "0"
	spec:
	project: default
	source:
		repoURL: https://github.com/LovemeTrue/ArgoCI-CD.git
		targetRevision: main
		path: $(VERSION)/elma365-dbs
		helm:
		valueFiles:
			- values-elma365-dbs.yaml
	destination:
		server: https://kubernetes.default.svc
		namespace: elma365
		automated:
		prune: true
		selfHeal: true
	EOF

	@git add $(APPS_DIR)/elma365-$(VERSION).yaml $(APPS_DIR)/elma365-dbs-$(VERSION).yaml
	@git commit -m "🔧 Добавлены приложения elma365 и elma365-dbs для версии $(VERSION)"
	@git push

.PHONY: release-full
release-full: release gen-apps
	@echo "✅ Полный релиз $(VERSION) завершён: чарты, values, приложения"
