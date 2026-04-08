#!/usr/bin/env bash

# 错误代码
# 0 - 无错误
# 1 - 找不到解压后的二进制文件
# 2 - 不支持的操作系统 (预留)
# 3 - 当前已经是最新版本
# 4 - 解压工具不可用
# 5 - 压缩包路径不存在

set -e  # 出现错误时退出脚本

# --- 配置区 ---
# 建议通过这种方式保持灵活性，或者将 ZIP_PATH 作为参数传入
ZIP_PATH="/home/00_software/rclone-v1.73.3-linux-amd64.zip"
UNZIP_DIR="/tmp/rclone_update"
unzip_tools_list=('unzip' '7z' 'busybox')

# 检查压缩包是否存在
if [ ! -f "$ZIP_PATH" ]; then
    echo "错误: 找不到压缩包 $ZIP_PATH"
    exit 5
fi

# 检查是否有解压工具可用
set +e
unzip_tool=""
for tool in "${unzip_tools_list[@]}"; do
    if command -v "$tool" > /dev/null; then
        unzip_tool="$tool"
        break
    fi
done
set -e

if [ -z "$unzip_tool" ]; then
    echo "未找到可用的解压工具 (${unzip_tools_list[*]}). 请安装其中一个并重试."
    exit 4
fi

# --- 逻辑处理区 ---

# 1. 创建并清理临时目录
rm -rf "$UNZIP_DIR"
mkdir -p "$UNZIP_DIR"

# 2. 解压文件
echo "正在使用 $unzip_tool 解压..."
case "$unzip_tool" in
    'unzip')   unzip -q "$ZIP_PATH" -d "$UNZIP_DIR" ;;
    '7z')      7z x "$ZIP_PATH" -o"$UNZIP_DIR" > /dev/null ;;
    'busybox') busybox unzip "$ZIP_PATH" -d "$UNZIP_DIR" ;;
esac

# 3. 【修复关键】动态定位解压后的目录
# Rclone 的官方包解压后通常是一个名为 rclone-v*-linux-amd64 的目录
# 我们通过查找该目录下是否存在 rclone 二进制文件来锁定路径
REAL_EXTRACT_DIR=$(find "$UNZIP_DIR" -maxdepth 2 -name "rclone" -type f -exec dirname {} \; | head -n 1)

if [ -z "$REAL_EXTRACT_DIR" ] || [ ! -f "$REAL_EXTRACT_DIR/rclone" ]; then
    echo "错误: 在压缩包中未找到 rclone 执行文件。"
    rm -rf "$UNZIP_DIR"
    exit 1
fi

# 4. 版本比对
installed_version=$(rclone --version 2>/dev/null | head -n 1 | awk '{print $2}')
new_version=$("$REAL_EXTRACT_DIR/rclone" --version | head -n 1 | awk '{print $2}')

if [ "$installed_version" == "$new_version" ]; then
    echo "当前 rclone 已是最新版本 ($installed_version)，无需更新。"
    rm -rf "$UNZIP_DIR"
    exit 3
fi

# 5. 安装新版本
echo "发现新版本: $new_version (当前: ${installed_version:-未安装})"
echo "正在安装到 /usr/bin/rclone..."

# 使用 .new 方式安全替换
cp "$REAL_EXTRACT_DIR/rclone" /usr/bin/rclone.new
chmod 755 /usr/bin/rclone.new
chown root:root /usr/bin/rclone.new
mv /usr/bin/rclone.new /usr/bin/rclone

# 6. 安装 man 手册 (如果有)
MAN_FILE=$(find "$REAL_EXTRACT_DIR" -name "rclone.1" -type f | head -n 1)
if [ -n "$MAN_FILE" ]; then
    echo "更新帮助手册..."
    mkdir -p /usr/local/share/man/man1
    cp "$MAN_FILE" /usr/local/share/man/man1/
    mandb -q || echo "注意: 尝试更新 mandb 失败，手册可能不会立即生效。"
fi

# 7. 清理
rm -rf "$UNZIP_DIR"
echo "更新完成！目前版本: $new_version"

exit 0
