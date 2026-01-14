#!/bin/bash
# scripts/export-safe-options.sh
# config/safe-options.yaml 기반으로 wp_options export

set -e

CONFIG_FILE="config/safe-options.yaml"
BACKUP_DIR="src/wp-data/db-exports"
mkdir -p "$BACKUP_DIR"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
OUTPUT_FILE="$BACKUP_DIR/safe-options_$TIMESTAMP.sql"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ Config file not found: $CONFIG_FILE"
    exit 1
fi

echo "📋 Reading config: $CONFIG_FILE"

# YAML에서 include 섹션의 option_name만 추출 (exclude 전까지)
OPTIONS=$(sed -n '/^include:/,/^exclude:/p' "$CONFIG_FILE" \
    | grep "option_name:" \
    | sed 's/.*option_name: //' \
    | sed "s/'//g")

if [ -z "$OPTIONS" ]; then
    echo "❌ No options found in config"
    exit 1
fi

# option_name 개수 세기
OPTION_COUNT=$(echo "$OPTIONS" | wc -l)

# SQL WHERE 절 생성
WHERE_CLAUSE="option_name IN ($(echo "$OPTIONS" | sed "s/^/'/;s/$/'/" | tr '\n' ',' | sed 's/,$//'))"

echo "📥 Exporting $OPTION_COUNT safe options..."

# Export
docker compose exec -T db mysql -u wp_playground -pplayground_secure_pass_123 wordpress_playground \
    -e "SELECT option_id, option_name, option_value FROM wp_options WHERE $WHERE_CLAUSE;" \
    > "$OUTPUT_FILE"

echo "✅ Exported to: $OUTPUT_FILE"
echo "📋 Options count: $OPTION_COUNT"
echo ""
echo "포함된 옵션:"
echo "$OPTIONS" | nl
