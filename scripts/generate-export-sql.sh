#!/bin/bash
# scripts/generate-export-sql.sh
# config/safe-options.yaml를 읽어서 wp_options export SQL 생성

set -e

CONFIG_FILE="${1:-config/safe-options.yaml}"
OUTPUT_DIR="${2:-scripts/sql}"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ Config file not found: $CONFIG_FILE"
    exit 1
fi

mkdir -p "$OUTPUT_DIR"

# YAML에서 include 섹션의 option_name만 추출 (exclude 전까지)
OPTIONS=$(sed -n '/^include:/,/^exclude:/p' "$CONFIG_FILE" \
    | grep "option_name:" \
    | sed 's/.*option_name: //' \
    | sed "s/'//g" \
    | tr '\n' ',')

# 마지막 쉼표 제거
OPTIONS="${OPTIONS%,}"

if [ -z "$OPTIONS" ]; then
    echo "❌ No options found in include section"
    exit 1
fi

# SQL 파일 생성
OUTPUT_FILE="$OUTPUT_DIR/export-safe-options.sql"

cat > "$OUTPUT_FILE" << 'EOF'
-- Auto-generated from config/safe-options.yaml
-- Generated: $(date)
-- Include 섹션의 옵션만 추출

SELECT option_id, option_name, option_value
FROM wp_options
WHERE option_name IN (
EOF

# option_name들을 SQL WHERE 절에 추가
echo "$OPTIONS" | tr ',' '\n' | sed "s/^/    '/;s/$/'/" | head -n -1 | tr '\n' ',' | sed 's/,$/\n/;s/,$/,/' >> "$OUTPUT_FILE"
echo "$OPTIONS" | tr ',' '\n' | tail -1 | sed "s/^/    '/" | sed "s/$/'/" >> "$OUTPUT_FILE"

cat >> "$OUTPUT_FILE" << 'EOF'
);
EOF

echo "✅ SQL generated: $OUTPUT_FILE"
echo "📋 Options count: $(echo "$OPTIONS" | tr ',' '\n' | wc -l)"
echo ""
echo "Included options:"
echo "$OPTIONS" | tr ',' '\n' | nl
