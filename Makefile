# === config ===
CHART_VERSION ?= 2025.4.1
DBS_MSG ?= обновление параметров БД
REPO_URL = https://github.com/LovemeTrue/ArgoCI-CD.git

# === targets ===

.PHONY: help
help:
	@echo "🛠 Make targets:"
	@echo "  make release-full VERSION=2025.4.1    # Создать релиз версии elma365, сгенерить apps для каждого чарта и выполнть git clean локальных веток.


VERSION ?= 2025.4.1
APPS_DIR := apps

.PHONY: release
release:
	@echo "🚀 Выполняю выпуск версии $(VERSION)"
	helm repo add elma365 https://charts.elma365.tech
	helm repo update

	@echo "🧹 Очищаем старые директории, если есть..."
	rm -rf $(VERSION)/elma365 $(VERSION)/elma365-dbs
	rm -rf $(VERSION)
	rm -rf elma365

	@echo "📦 Скачиваем чарт elma365..."
	helm pull elma365/elma365 --version $(VERSION) --untar
	mkdir -p $(VERSION)/elma365
	mv elma365/* $(VERSION)/elma365/
	rm -rf elma365
	

	@echo "📥 Копируем values-elma365.yaml"
	cp values/values-elma365.yaml $(VERSION)/elma365/
	rm -rf elma365-dbs
	@echo "📦 Скачиваем чарт elma365-dbs"
	helm pull elma365/elma365-dbs --untar
	mkdir -p $(VERSION)/elma365-dbs
	mv elma365-dbs/* $(VERSION)/elma365-dbs/
	rm -rf elma365-dbs

	@echo "📥 Копируем values-elma365-dbs.yaml"
	cp values/values-elma365-dbs.yaml $(VERSION)/elma365-dbs/

	@git add $(VERSION)
	@git commit -m "📦 Добавлена версия $(VERSION) с чартами и values"
	@git tag -a $(VERSION) -m "Release $(VERSION)"
	@git push origin main --tags

APPS_DIR := apps

.PHONY: gen-apps
gen-apps:
	@echo "📁 Генерирую приложения ArgoCD для версии $(VERSION)..."

	@bash -c '\
	APP_FILE="$(APPS_DIR)/elma365-$(VERSION).yaml"; \
	DBS_FILE="$(APPS_DIR)/elma365-dbs-$(VERSION).yaml"; \

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
		namespace: elma365-dbs
		automated:
		prune: true
		selfHeal: true
	EOF
		'
	@git add $(APPS_DIR)/elma365-$(VERSION).yaml $(APPS_DIR)/elma365-dbs.yaml
	@git commit -m "🔧 Добавлены приложения elma365 и elma365-dbs для версии $(VERSION)"
	@git push


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
