#!/usr/bin/env bash

# 错误代码
# 0 - 无错误
# 1 - 参数错误
# 2 - 不支持的操作系统
# 3 - 当前已经是最新版本
# 4 - 解压工具不可用

set -e  # 出现错误时退出脚本

# 安装包路径
ZIP_PATH="/home/00_software/rclone_v1.68.0/rclone-current-linux-amd64.zip"
UNZIP_DIR="/tmp/rclone_update"

# 支持的解压工具
unzip_tools_list=('unzip' '7z' 'busybox')

# 检查是否有解压工具可用
set +e
for tool in "${unzip_tools_list[@]}"; do
    if command -v "$tool" > /dev/null; then
        unzip_tool="$tool"
        break
    fi
done
set -e

# 如果没有解压工具则退出
if [ -z "$unzip_tool" ]; then
    echo "未找到可用的解压工具 (${unzip_tools_list[*]}). 请安装其中一个并重试."
    exit 4
fi

# 检查已安装的 rclone 版本
installed_version=$(rclone --version 2>/dev/null | head -n 1 | awk '{print $2}')

# 获取新版本的版本号
new_version=$(unzip -p "$ZIP_PATH" rclone-v1.68.0-linux-amd64/rclone.1 2>/dev/null | head -n 1 | awk '{print $2}')

# 比较版本号
if [ "$installed_version" == "$new_version" ]; then
    echo "当前 rclone 已是最新版本: $installed_version"
    exit 3
fi

# 创建临时目录以解压缩新版本
rm -rf "$UNZIP_DIR"
mkdir -p "$UNZIP_DIR"

# 解压文件到临时目录
case "$unzip_tool" in
    'unzip')
        unzip -q "$ZIP_PATH" -d "$UNZIP_DIR"
        ;;
    '7z')
        7z x "$ZIP_PATH" -o"$UNZIP_DIR"
        ;;
    'busybox')
        busybox unzip "$ZIP_PATH" -d "$UNZIP_DIR"
        ;;
esac

# 进入解压后的子目录
cd "$UNZIP_DIR/rclone-v1.68.0-linux-amd64"

# 安装新版本的 rclone
if [ -f "rclone" ]; then
    echo "安装新版本的 rclone..."
    cp rclone /usr/bin/rclone.new
    chmod 755 /usr/bin/rclone.new
    chown root:root /usr/bin/rclone.new
    mv /usr/bin/rclone.new /usr/bin/rclone

    # 检查是否有 man 手册，并安装
    if [ -f "rclone.1" ]; then
        mkdir -p /usr/local/share/man/man1
        cp rclone.1 /usr/local/share/man/man1/
        mandb || echo "未找到 mandb，rclone 手册未更新。"
    fi

    echo "rclone 已成功更新到版本: $new_version"
else
    echo "未找到 rclone 可执行文件。解压可能出错。"
    exit 1
fi

# 清理临时目录
rm -rf "$UNZIP_DIR"

exit 0
