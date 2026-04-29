#!/usr/bin/env bash

set -euo pipefail

# =========================
# 配置区
# =========================
TARGET_DIR="/home/01_html/91_apk_github/01_v2rayNG"
API_URL="https://api.github.com/repos/2dust/v2rayNG/releases/latest"

# GitHub API 请求头
ACCEPT_HEADER="Accept: application/vnd.github+json"
API_VERSION_HEADER="X-GitHub-Api-Version: 2022-11-28"
UA_HEADER="User-Agent: v2rayng-apk-downloader"

# =========================
# 1. 检查目录并清空
# =========================
if [ ! -d "$TARGET_DIR" ]; then
    echo "目录不存在，正在创建: $TARGET_DIR"
    mkdir -p "$TARGET_DIR"
else
    echo "目录已存在，正在清空: $TARGET_DIR"
    find "$TARGET_DIR" -mindepth 1 -maxdepth 1 -exec rm -rf {} +
fi

# =========================
# 2. 获取最新 release 信息
# =========================
echo "正在查询 GitHub 最新 release..."
json_file="$(mktemp)"

curl -fsSL \
  -H "$ACCEPT_HEADER" \
  -H "$API_VERSION_HEADER" \
  -H "$UA_HEADER" \
  "$API_URL" \
  -o "$json_file"

# =========================
# 3. 从 assets 中提取所有 apk 下载链接
#    这里用 python3 解析 JSON，避免依赖 jq
# =========================
mapfile -t apk_urls < <(
python3 - <<'PY' "$json_file"
import json
import sys

json_path = sys.argv[1]
with open(json_path, "r", encoding="utf-8") as f:
    data = json.load(f)

assets = data.get("assets", [])
for asset in assets:
    name = asset.get("name", "")
    url = asset.get("browser_download_url", "")
    if name.lower().endswith(".apk") and url:
        print(url)
PY
)

if [ "${#apk_urls[@]}" -eq 0 ]; then
    echo "错误：最新 release 中没有找到 apk 文件。"
    rm -f "$json_file"
    exit 1
fi

echo "找到 ${#apk_urls[@]} 个 APK，开始下载到: $TARGET_DIR"

for url in "${apk_urls[@]}"; do
    file_name="$(basename "$url")"
    echo "下载中: $file_name"
    curl -fL \
      -H "$UA_HEADER" \
      -o "$TARGET_DIR/$file_name" \
      "$url"
done

rm -f "$json_file"

echo "下载完成。当前目录文件列表："
ls -lh "$TARGET_DIR"
