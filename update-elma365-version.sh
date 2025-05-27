#!/bin/bash

# === Ввод параметра версии ===
if [ -z "$1" ]; then
  echo "❌ Укажи версию чарта, например: ./update-elma365-version.sh 2025.4.2"
  exit 1
fi

VERSION="$1"
BASE_BRANCH="main"
PR_BRANCH="update/elma365-$VERSION"
CHART_VERSION_FILE="elma365-appsets/applications/elma365/chart-version.yaml"

# === Проверка наличия yq ===
if ! command -v yq &>/dev/null; then
  echo "❌ Установи yq: https://github.com/mikefarah/yq"
  exit 1
fi

# === Проверка наличия gh ===
if ! command -v gh &>/dev/null; then
  echo "❌ Установи GitHub CLI (gh): https://cli.github.com"
  exit 1
fi

# === Переходим в ветку main и обновляем локально ===
echo "🔄 Переключаюсь на $BASE_BRANCH и обновляю..."
git checkout "$BASE_BRANCH" && git pull origin "$BASE_BRANCH"

# === Создаём новую ветку PR ===
echo "🌿 Создаю ветку: $PR_BRANCH"
git checkout -b "$PR_BRANCH"

# === Обновляем версию чарта ===
echo "🔧 Обновляю версию чарта на $VERSION в $CHART_VERSION_FILE"
yq e -i ".data.version = \"$VERSION\"" "$CHART_VERSION_FILE"

# === Проверка изменений и коммит ===
if git diff --quiet; then
  echo "✅ Версия уже установлена ($VERSION) — изменений нет"
  exit 0
fi

git add "$CHART_VERSION_FILE"
git commit -m "🔄 bump elma365 chart version to $VERSION"
git push --set-upstream origin "$PR_BRANCH"

# === Создание Pull Request через GitHub CLI ===
echo "🚀 Открываю Pull Request в GitHub..."
gh pr create \
  --base "$BASE_BRANCH" \
  --head "$PR_BRANCH" \
  --title "Bump elma365 chart to $VERSION" \
  --body "This PR updates elma365 chart to version \`$VERSION\`."

echo "✅ Pull Request создан!"