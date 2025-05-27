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
	@yq e -i '.data.version = "$(CHART_VERSION)"' elma365-appsets/apps/elma365/chart-version.yaml
	@if git diff --quiet; then echo "✅ Версия уже актуальна."; exit 0; fi
	git add elma365-appsets/apps/elma365/chart-version.yaml
	git commit -m "🔄 bump elma365 chart to $(CHART_VERSION)"
	git push -u origin update/elma365-$(CHART_VERSION)
	gh pr create \
		--base main \
		--head update/elma365-$(CHART_VERSION) \
		--title "elma365: bump to $(CHART_VERSION)" \
		--body "This PR updates elma365 chart to version \`$(CHART_VERSION)\`."

.PHONY: dbs-update
dbs-update:
	@echo "🔧 Обновляем elma365-dbs (values)"
	git checkout main
	git pull origin main
	@PR_BRANCH=update/elma365-dbs-`date +%Y%m%d-%H%M%S` && \
	git checkout -b $$PR_BRANCH && \
	if git diff --quiet elma365-appsets/apps/elma365-dbs/values-elma365-dbs.yaml; then echo "⚠️ Нет изменений — отмена."; exit 0; fi && \
	git add elma365-appsets/apps/elma365-dbs/values-elma365-dbs.yaml && \
	git commit -m "🔧 elma365-dbs: $(DBS_MSG)" && \
	git push -u origin $$PR_BRANCH && \
	gh pr create \
		--base main \
		--head $$PR_BRANCH \
		--title "elma365-dbs: $(DBS_MSG)" \
		--body "Changes in \`values-elma365-dbs.yaml\`: $(DBS_MSG)"