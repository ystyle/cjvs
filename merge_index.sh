#!/bin/bash

# 合并 index 目录下所有版本 JSON 文件到 index.json

set -e

INDEX_DIR="index"
OUTPUT_FILE="index.json"

echo "=== 合并 index 目录 ==="

# 检查目录是否存在
if [ ! -d "$INDEX_DIR" ]; then
    echo "❌ 目录 $INDEX_DIR 不存在"
    exit 1
fi

# 临时文件
TEMP_FILE=$(mktemp)

# 开始合并
echo "[" > "$TEMP_FILE"

# 按版本号排序文件
files=$(ls -1 "$INDEX_DIR"/*.json | sort -V -t/ -k3)

first=true
for file in $files; do
    if [ -f "$file" ]; then
        if [ "$first" = true ]; then
            first=false
        else
            echo "," >> "$TEMP_FILE"
        fi
        # 读取文件内容，去掉首尾的方括号
        content=$(cat "$file" | sed 's/^\[//' | sed 's/\]$//')
        echo "$content" >> "$TEMP_FILE"
    fi
done

echo "]" >> "$TEMP_FILE"

# 格式化输出
jq '.' "$TEMP_FILE" > "$OUTPUT_FILE"
rm "$TEMP_FILE"

echo "✅ 已合并到 $OUTPUT_FILE"
echo "文件数量: $(ls -1 $INDEX_DIR/*.json 2>/dev/null | wc -l)"