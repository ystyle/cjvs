#!/bin/bash

# 合并 index 目录并上传到 OBS，刷新 CDN
# 使用方法: ./upload_index.sh

set -e

INDEX_DIR="index"
BUCKET="ystyle-images"
OBJECT_KEY="images/cjvs-index.json"
LOCAL_FILE="index.json"
CDN_URL="https://dll.ystyle.top/images/cjvs-index.json"

# 合并 index
echo "=== 合并 index 目录 ==="
./merge_index.sh

echo ""
echo "=== 上传 index.json 到 OBS ==="
echo "本地文件: ${LOCAL_FILE}"
echo "目标位置: obs://${BUCKET}/${OBJECT_KEY}"

# 上传到 OBS
hcloud obs cp "${LOCAL_FILE}" "obs://${BUCKET}/${OBJECT_KEY}" -acl=public-read

if [ $? -eq 0 ]; then
    echo "✅ 上传成功"
else
    echo "❌ 上传失败"
    exit 1
fi

echo ""
echo "=== 刷新 CDN 缓存 ==="
echo "URL: ${CDN_URL}"

# 刷新 CDN
hcloud CDN CreateRefreshTasks/v2 \
    --cli-region=cn-north-1 \
    --refresh_task.urls.1="${CDN_URL}" \
    --refresh_task.type=file

if [ $? -eq 0 ]; then
    echo "✅ CDN 刷新任务已提交"
else
    echo "❌ CDN 刷新失败"
    exit 1
fi

echo ""
echo "=== 完成 ==="
echo "文件已上传到: https://dll.ystyle.top/images/cjvs-index.json"