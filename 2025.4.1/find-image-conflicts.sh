#!/bin/bash

# Указать директорию чарта (по умолчанию ./elma365)
CHART_DIR=${1:-"./elma365"}

echo "🔍 Поиск потенциальных конфликтов image: в чарте: $CHART_DIR"
echo

echo "----------------------------------------"
echo "📄 Все шаблоны с 'containers:' секцией"
echo "----------------------------------------"

grep -rn --include='*.yaml' 'containers:' "$CHART_DIR/templates" | tee /tmp/containers.txt

echo
echo "----------------------------------------"
echo "📄 Все строки, содержащие 'image:'"
echo "----------------------------------------"

grep -rn --include='*.yaml' --include='*.tpl' 'image:' "$CHART_DIR/templates" | tee /tmp/image_lines.txt

echo
echo "⚠️ Файлы с повторяющимися image:"
echo "----------------------------------------"

cut -d: -f1 /tmp/image_lines.txt | sort | uniq -c | awk '$1 > 1 { print "❗ " $2 " - " $1 " вставок image:" }'

echo
echo "----------------------------------------"
echo "🧠 Контекст: ближайшие image: после containers:"
echo "----------------------------------------"

while read -r container_line; do
  FILE=$(echo "$container_line" | cut -d: -f1)
  LINE=$(echo "$container_line" | cut -d: -f2)

  echo
  echo "📁 Файл: $FILE (строка $LINE)"
  echo "----------------------------------------"

  awk -v start=$LINE '
    NR >= start && NR <= start + 20 {
      print NR ": " $0
    }
  ' "$FILE" | grep -E 'containers:|name:|image:|imagePullPolicy' || echo "  🚫 Нет image: после containers:"
done < /tmp/containers.txt