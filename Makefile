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

APPS_DIR := apps
.PHONY: gen-apps
gen-apps:
	@echo "📁 Генерирую приложения ArgoCD для версии $(VERSION)..."
	@mkdir -p $(APPS_DIR)
	@bash -c '\
	@APP_FILE="$(APPS_DIR)/elma365-$(VERSION).yaml"; \
	DBS_FILE="$(APPS_DIR)/elma365-dbs.yaml"; \
	echo "📄 Перезаписываю $$APP_FILE"; \
		cat > $$APP_FILE <<EOF
	apiVersion: argoproj.io/v1alpha1
	kind: Application
	metadata:
	name: elma365-$(subst .,-,$(VERSION))
	namespace: argocd
	annotations:
		argocd.argoproj.io/sync-wave: "1"
		argocd.argoproj.io/depends-on: '[elma365-dbs]'
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

		echo "📄 Перезаписываю $$DBS_FILE"; \
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
	syncPolicy:
		automated:
		prune: true
		selfHeal: true
	EOF
		'
	@git add $(APPS_DIR)/elma365-$(VERSION).yaml $(APPS_DIR)/elma365-dbs.yaml
	@git commit -m "🔁 Перегенерация ArgoCD приложений для версии $(VERSION)" || echo "🟡 Нет изменений для коммита"
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
