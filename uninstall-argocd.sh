#!/bin/bash

# Скрипт для полного удаления Argo CD с локальной ВМ и Kubernetes-кластера
# Требует: kubectl, helm (если установка была через helm)

set -euo pipefail

echo -e "\033[1;34m=== Начало удаления Argo CD ===\033[0m"

# 1. Удаление Argo CD из Kubernetes
echo -e "\033[1;33m[1/6] Удаление Argo CD из кластера...\033[0m"

if kubectl get namespace argocd &> /dev/null; then
    # Удаление через манифест (если устанавливался так)
    kubectl delete -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml 2> /dev/null || true
    
    # Удаление через Helm (если устанавливался так)
    if helm list -n argocd | grep -q argocd; then
        helm uninstall argocd -n argocd
    fi

    # Удаление оставшихся ресурсов
    kubectl delete all,secret,configmap,serviceaccount,role,rolebinding --all -n argocd --ignore-not-found
    kubectl get namespace "argocd" -o json \
  | tr -d "\n" | sed "s/\"finalizers\": \[[^]]\+\]/\"finalizers\": []/" \
  | kubectl replace --raw /api/v1/namespaces/argocd/finalize -f -

    kubectl delete namespace argocd --ignore-not-found
    echo -e "\033[1;32m[✓] Ресурсы Argo CD удалены из кластера\033[0m"
else
    echo -e "\033[1;35m[!] Namespace argocd не найден, пропускаю\033[0m"
fi

# 2. Удаление CRD
echo -e "\033[1;33m[2/6] Удаление Custom Resource Definitions...\033[0m"
kubectl delete crd -l app.kubernetes.io/part-of=argocd --ignore-not-found
kubectl delete crd applications.argoproj.io appprojects.argoproj.io --ignore-not-found 2> /dev/null || true
echo -e "\033[1;32m[✓] CRD удалены\033[0m"

# 3. Удаление RBAC
echo -e "\033[1;33m[3/6] Удаление RBAC-правил...\033[0m"
kubectl delete clusterrole,clusterrolebinding -l app.kubernetes.io/part-of=argocd --ignore-not-found
echo -e "\033[1;32m[✓] RBAC-правила удалены\033[0m"

# 4. Удаление Persistent Volumes
echo -e "\033[1;33m[4/6] Удаление Persistent Volumes...\033[0m"
for pv in $(kubectl get pv -o jsonpath='{.items[?(@.spec.claimRef.namespace=="argocd")].metadata.name}'); do
    kubectl delete pv "$pv" --ignore-not-found
done
echo -e "\033[1;32m[✓] Persistent Volumes удалены\033[0m"

# 5. Удаление локальных файлов Argo CD
echo -e "\033[1;33m[5/6] Удаление локальных файлов...\033[0m"
# Удаление CLI
if [ -f "/usr/local/bin/argocd" ]; then
    sudo rm -f /usr/local/bin/argocd
    echo -e "  \033[1;32m[✓] CLI удален\033[0m"
fi

# Удаление конфигов
rm -rf ~/.argocd ~/.cache/argocd ~/.kube/cache/argocd 2> /dev/null || true
echo -e "  \033[1;32m[✓] Локальные конфиги удалены\033[0m"

# 6. Финальная проверка
echo -e "\033[1;33m[6/6] Проверка результатов...\033[0m"
if ! kubectl get namespace argocd &> /dev/null && \
   ! kubectl get crd applications.argoproj.io &> /dev/null && \
   ! command -v argocd &> /dev/null; then
    echo -e "\033[1;32m=== Argo CD полностью удален ===\033[0m"
else
    echo -e "\033[1;31m[!] Обнаружены остаточные компоненты Argo CD\033[0m"
    exit 1
fi

