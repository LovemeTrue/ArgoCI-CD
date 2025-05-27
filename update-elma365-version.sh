#!/bin/bash

# Проверка аргументов
if [ -z "$1" ]; then
  echo "❌ Укажи версию чарта, например: ./update-elma365-version.sh 2025.4.2"
  exit 1
fi

VERSION="$1"
BRANCH="pr"
FILE="elma365-appsets/applications/elma365/chart-version.yaml"

# Обновляем версию в YAML-файле
echo "🔧 Обновляю версию чарта на $VERSION..."
yq e -i ".data.version = \"$VERSION\"" "$FILE"

# Коммит и push
echo "📦 Коммитим и пушим в ветку '$BRANCH'..."
git add "$FILE"
git commit -m "🔄 bump elma365 chart version to $VERSION"
git push origin "$BRANCH"

echo "✅ Готово! Версия чарта elma365 теперь $VERSION (в ветке $BRANCH)"
