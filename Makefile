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
KUBECONFIG=/home/panov/.kube/kind_conf


.PHONY: clean-argocd
clean-argocd:
	@echo "🧹 Чистим ArgoCD-приложения и неймспейсы перед релизом ($(VERSION))..."

	@echo "🧨 Удаляем ArgoCD приложения..."
	@argocd app delete elma365-$(VERSION) --server cd.apps.argoproj.io --grpc-web --cascade=false --yes || true
	@argocd app delete elma365-dbs --server cd.apps.argoproj.io  --grpc-web --cascade=false --yes || true

	# @echo "🔄 Обновляем root-app через hard-refresh..."
	# @argocd app get root-app  --server cd.apps.argoproj.io --grpc-web --hard-refresh
	# @argocd app sync root-app --server cd.apps.argoproj.io --grpc-web

	@echo "🔁 Скейлим deployments в namespace=elma365 до 0 (если есть)..."
	@kubectl get deploy -n elma365 -o name 2>/dev/null | xargs -r -n1 kubectl scale -n elma365 --replicas=0 || true

	@echo "🧹 Чистим ресурсы с hook-finalizer перед удалением namespace elma365..."
	@kubectl get all -n elma365 -o json 2>/dev/null \
	| jq '.items[] | select(.metadata.finalizers != null) | select([.metadata.finalizers[] | contains("argocd.argoproj.io/hook-finalizer")] | any)' \
	| jq -r '.kind + "/" + .metadata.name' \
	| xargs -r -n1 -I{} kubectl patch -n elma365 {} -p '{"metadata":{"finalizers":[]}}' --type=merge || true

	@kubectl get all -n elma365-dbs -o json 2>/dev/null \
	| jq '.items[] | select(.metadata.finalizers != null) | select([.metadata.finalizers[] | contains("argocd.argoproj.io/hook-finalizer")] | any)' \
	| jq -r '.kind + "/" + .metadata.name' \
	| xargs -r -n1 -I{} kubectl patch -n elma365-dbs {} -p '{"metadata":{"finalizers":[]}}' --type=merge || true

	
	@echo "🗑 Удаляем namespace elma365 (если существует)..."
	@kubectl get ns elma365 -o json 2>/dev/null \
		| tr -d '\n' \
		| sed 's/"finalizers": \[[^]]\+\]/"finalizers": []/' \
		| kubectl replace --raw /api/v1/namespaces/elma365/finalize -f - || true
	
		@echo "🗑 Удаляем оставшиеся ресурсы из elma365 (если есть)..."
	@kubectl delete all --all -n elma365 --ignore-not-found || true
	@kubectl delete configmap --all -n elma365 --ignore-not-found || true
	@kubectl delete secret --all -n elma365 --ignore-not-found || true
	@kubectl delete ns elma365 --ignore-not-found=true || true
	

	@echo "🗑 Удаляем namespace elma365-dbs (если существует)..."
	@kubectl delete ns elma365-dbs --ignore-not-found=true || true

	@echo "🆕 Создаём namespace'ы elma365 и elma365-dbs..."
	@kubectl create ns elma365 || true
	@kubectl create ns elma365-dbs || true

	@echo "🏷 Лейблим elma365 namespace как privileged..."
	@kubectl label ns elma365 security.deckhouse.io/pod-policy=privileged --overwrite || true

	@echo "⚙️ Патчим nodegroup master с maxPods=200..."
	@kubectl patch nodegroup master --type=merge -p '{"spec":{"kubelet":{"maxPods":200}}}' || true

	@echo "🔐 Создаём TLS secret в namespace elma365-dbs..."
	@kubectl create secret tls elma365-onpremise-tls --cert=./ssl/kind.elewise.local.crt --key=./ssl/kind.elewise.local.key -n elma365-dbs
	@echo "🔐 Создаём TLS secret в namespace elma365..."
	@kubectl create secret tls elma365-onpremise-tls --cert=./ssl/kind.elewise.local.crt --key=./ssl/kind.elewise.local.key -n elma365 
	@echo "📜 Создаём configMap с rootCA в elma365..."
	@kubectl create configmap elma365-onpremise-ca --from-file=elma365-onpremise-ca.pem=./ssl/rootCA.pem -n elma365

	@echo "🗑 Удаляем манифесты elma365 приложений..."
	@rm -f $(APPS_DIR)/elma365-$(VERSION).yaml $(APPS_DIR)/elma365-dbs.yaml || true

	@echo "🧨 Удаляем ArgoCD приложения..."
	@argocd app delete elma365-$(VERSION) --server cd.apps.argoproj.io --grpc-web --cascade=false --yes || true
	@argocd app delete elma365-dbs --server cd.apps.argoproj.io  --grpc-web --cascade=false --yes || true

	@echo "🔄 Обновляем root-app через hard-refresh..."
	@argocd app get root-app  --server cd.apps.argoproj.io --grpc-web --hard-refresh
	@argocd app sync root-app --server cd.apps.argoproj.io --grpc-web

.PHONY: release

PATH_TO_SSL_KEY := /home/panov/Загрузки/ElmaWork/ElmaGitOps/ArgoCI-CD/ssl/kind.elewise.local.key
PATH_TO_SSL_CRT := home/panov/Загрузки/ElmaWork/ElmaGitOps/ArgoCI-CD/ssl/kind.elewise.local.crt
PATH_TO_PEM := home/panov/Загрузки/ElmaWork/ElmaGitOps/ArgoCI-CD/ssl/rootCA.pemrootCA.pem
release:
	APP_NAME=elma365-$$VERSION; \
	echo "🧨 Удаляем старое приложение $$APP_NAME из ArgoCD..."; \
	argocd app delete $$APP_NAME \
		--server cd.apps.argoproj.io \
		--cascade=false \
		--yes || true

	@echo "🚀 Выполняю выпуск версии $(VERSION)"
	rm -rf $(VERSION)/elma365 $(VERSION)/elma365-dbs

	@echo "📦 Скачиваем чарт elma365..."
	helm repo update
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
# DASHED_VERSION := $(subst .,-,$(VERSION))

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


.PHONY: cleanup-git-apps
cleanup-git:
	@echo "🧹 Удаляю локальные ветки кроме main..."
	@git checkout main
	@git branch | grep -v "^\* main" | grep -v "main" | xargs -r git branch -D || true
	@git checkout main
	@git pull
	@echo "✅ Возврат в main и удаление лишних веток завершено"
.PHONY: cleanup-old-apps
cleanup-old-apps:
	@echo "🧹 Удаляю старые ArgoCD приложения elma365-*, кроме $(VERSION) и dbs..."
	@find $(APPS_DIR) -type f -name "elma365-*.yaml" \
		! -name "elma365-$(VERSION).yaml" \
		! -name "elma365-dbs.yaml" \
		-exec rm -v {} \;


.PHONY: release-full
release-full: clean-argocd release gen-apps cleanup-git cleanup-old-apps
	@git add $(APPS_DIR)
	@git commit -m "♻️ Очистка старых версий, релиз $(VERSION)" || echo "🟡 Нет изменений"
	
	@git push
	@echo "✅ Полный релиз $(VERSION) завершён: чарты, values, приложения"
