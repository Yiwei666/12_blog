#!/usr/bin/env bash

# 错误代码
# 0 - 无错误
# 1 - 找不到解压后的 rclone 二进制文件
# 2 - 不支持的操作系统或架构
# 3 - 当前已经是同一版本，无需更新
# 4 - 解压工具不可用
# 5 - 压缩包路径不存在
# 6 - ZIP 包版本低于当前已安装版本，已拒绝降级

set -e

# ============================================================
# 变量配置区
# ============================================================
# 这一部分是最常需要修改的地方。
# 一般情况下，你只需要根据实际情况修改 ZIP_PATH 即可。
#
# 推荐使用方式：
# 1. 直接修改下面的 ZIP_PATH 默认值；
# 2. 或者运行脚本时把 ZIP 文件路径作为第一个参数传入。
#
# 示例：
# sudo bash update_rclone.sh
# sudo bash update_rclone.sh /home/00_software/rclone-current-linux-amd64.zip
# ============================================================

# rclone 压缩包路径。
# 如果运行脚本时传入第一个参数，则优先使用传入的路径。
# 如果未传入参数，则使用冒号后面的默认路径。
#
# 例如：
# ZIP_PATH="${1:-/home/00_software/rclone-current-linux-amd64.zip}"
#
# 含义：
# - $1 是命令行第一个参数；
# - :- 后面是默认值；
# - 如果 $1 为空，就使用默认路径。
ZIP_PATH="${1:-/home/00_software/rclone-current-linux-amd64.zip}"

# rclone 安装目录。
# 官网 Linux 安装脚本默认安装到 /usr/bin。
# 如果你的 rclone 实际在 /usr/local/bin，可以改成：
# INSTALL_BIN_DIR="/usr/local/bin"
INSTALL_BIN_DIR="/usr/bin"

# rclone 可执行文件名称。
# 一般不需要修改。
RCLONE_BIN_NAME="rclone"

# rclone 完整安装路径。
# 一般不需要手动修改，它会由 INSTALL_BIN_DIR 和 RCLONE_BIN_NAME 自动组合。
INSTALL_BIN_PATH="${INSTALL_BIN_DIR}/${RCLONE_BIN_NAME}"

# 安装时使用的临时文件路径。
# 先复制为 rclone.new，再 mv 替换正式文件，这和官网脚本逻辑一致。
# 一般不需要修改。
INSTALL_BIN_NEW_PATH="${INSTALL_BIN_PATH}.new"

# man 手册安装目录。
# Linux 下通常使用这个目录。
# 一般不需要修改。
MAN_DIR="/usr/local/share/man/man1"

# man 手册文件名。
# 一般不需要修改。
MAN_FILE_NAME="rclone.1"

# 临时解压目录前缀。
# 脚本会用 mktemp 自动生成随机目录，例如：
# /tmp/rclone_update.ABCD123456
# 一般不需要修改。
TMP_DIR_TEMPLATE="/tmp/rclone_update.XXXXXXXXXX"

# 支持的解压工具列表。
# 脚本会按顺序查找，找到第一个可用工具后使用。
# 一般不需要修改。
unzip_tools_list=('unzip' '7z' 'busybox')

# 是否允许降级安装。
# 0 = 不允许降级，推荐；
# 1 = 允许降级。
#
# 如果你明确想从高版本回退到低版本，可以改成：
# ALLOW_DOWNGRADE=1
ALLOW_DOWNGRADE=0

# 是否更新 man 手册。
# 1 = 更新；
# 0 = 不更新。
INSTALL_MAN_PAGE=1

# 允许的操作系统。
# 当前脚本只针对 Linux。
# 一般不需要修改。
SUPPORTED_OS="Linux"

# 允许的 CPU 架构。
# 当前脚本只针对 linux-amd64。
# 如果以后要支持 arm64，需要同时换成 arm64 的 rclone 压缩包，并修改这里。
SUPPORTED_ARCH="amd64"

# ============================================================
# 基础检查区
# ============================================================

# 检查操作系统
current_os="$(uname)"

if [ "$current_os" != "$SUPPORTED_OS" ]; then
    echo "错误: 当前脚本仅适用于 $SUPPORTED_OS 系统。当前系统: $current_os"
    exit 2
fi

# 检查架构
current_arch_raw="$(uname -m)"

case "$current_arch_raw" in
    x86_64|amd64)
        current_arch="amd64"
        ;;
    *)
        echo "错误: 当前脚本仅适用于 linux-${SUPPORTED_ARCH}。当前架构: $current_arch_raw"
        exit 2
        ;;
esac

if [ "$current_arch" != "$SUPPORTED_ARCH" ]; then
    echo "错误: 当前脚本仅适用于 linux-${SUPPORTED_ARCH}。当前架构: $current_arch"
    exit 2
fi

# 检查压缩包是否存在
if [ ! -f "$ZIP_PATH" ]; then
    echo "错误: 找不到压缩包: $ZIP_PATH"
    exit 5
fi

# 检查解压工具
set +e
unzip_tool=""

for tool in "${unzip_tools_list[@]}"; do
    if command -v "$tool" > /dev/null 2>&1; then
        unzip_tool="$tool"
        break
    fi
done

set -e

if [ -z "$unzip_tool" ]; then
    echo "错误: 未找到可用的解压工具 (${unzip_tools_list[*]})。请安装其中一个后重试。"
    exit 4
fi

# ============================================================
# 临时目录处理区
# ============================================================

unzip_dir="$(mktemp -d "$TMP_DIR_TEMPLATE")"

cleanup() {
    rm -rf "$unzip_dir"
}

trap cleanup EXIT

# ============================================================
# 解压区
# ============================================================

echo "正在使用 $unzip_tool 解压: $ZIP_PATH"

case "$unzip_tool" in
    'unzip')
        unzip -q "$ZIP_PATH" -d "$unzip_dir"
        ;;
    '7z')
        7z x "$ZIP_PATH" -o"$unzip_dir" > /dev/null
        ;;
    'busybox')
        busybox unzip "$ZIP_PATH" -d "$unzip_dir"
        ;;
esac

# ============================================================
# 定位 rclone 二进制文件
# ============================================================

real_extract_dir=$(find "$unzip_dir" -maxdepth 2 -name "$RCLONE_BIN_NAME" -type f -exec dirname {} \; | head -n 1)

if [ -z "$real_extract_dir" ] || [ ! -f "$real_extract_dir/$RCLONE_BIN_NAME" ]; then
    echo "错误: 在压缩包中未找到 $RCLONE_BIN_NAME 执行文件。"
    exit 1
fi

new_rclone="${real_extract_dir}/${RCLONE_BIN_NAME}"

# ============================================================
# 版本识别区
# ============================================================

if command -v "$RCLONE_BIN_NAME" > /dev/null 2>&1; then
    installed_version=$("$RCLONE_BIN_NAME" --version 2>/dev/null | head -n 1 | awk '{print $2}')
else
    installed_version=""
fi

new_version=$("$new_rclone" --version | head -n 1 | awk '{print $2}')

if [ -z "$new_version" ]; then
    echo "错误: 无法识别 ZIP 包内 $RCLONE_BIN_NAME 的版本。"
    exit 1
fi

installed_version_num="${installed_version#v}"
new_version_num="${new_version#v}"

# ============================================================
# 版本比对区
# ============================================================

if [ -n "$installed_version" ] && [ "$installed_version" = "$new_version" ]; then
    echo "当前 $RCLONE_BIN_NAME 已经是同一版本 ($installed_version)，无需更新。"
    exit 3
fi

# 如果不允许降级，则检查 ZIP 包版本是否低于当前已安装版本
if [ "$ALLOW_DOWNGRADE" -ne 1 ] && [ -n "$installed_version" ] && command -v sort > /dev/null 2>&1; then
    lower_version=$(printf "%s\n%s\n" "$installed_version_num" "$new_version_num" | sort -V | head -n 1)

    if [ "$lower_version" = "$new_version_num" ] && [ "$installed_version_num" != "$new_version_num" ]; then
        echo "警告: ZIP 包内版本 ($new_version) 低于当前已安装版本 ($installed_version)。"
        echo "为避免误降级，已取消安装。"
        echo "如确实需要降级，请将脚本开头的 ALLOW_DOWNGRADE=0 改为 ALLOW_DOWNGRADE=1。"
        exit 6
    fi
fi

# ============================================================
# 安装区
# ============================================================

if [ -z "$installed_version" ]; then
    echo "当前系统未检测到 $RCLONE_BIN_NAME。"
else
    echo "当前已安装版本: $installed_version"
fi

echo "待安装版本: $new_version"
echo "正在安装到 $INSTALL_BIN_PATH ..."

mkdir -p "$INSTALL_BIN_DIR"

cp "$new_rclone" "$INSTALL_BIN_NEW_PATH"
chmod 755 "$INSTALL_BIN_NEW_PATH"
chown root:root "$INSTALL_BIN_NEW_PATH"
mv "$INSTALL_BIN_NEW_PATH" "$INSTALL_BIN_PATH"

# ============================================================
# 安装 man 手册
# ============================================================

if [ "$INSTALL_MAN_PAGE" -eq 1 ]; then
    man_file=$(find "$real_extract_dir" -name "$MAN_FILE_NAME" -type f | head -n 1)

    if [ -n "$man_file" ]; then
        echo "正在更新帮助手册..."
        mkdir -p "$MAN_DIR"
        cp "$man_file" "$MAN_DIR/"

        if command -v mandb > /dev/null 2>&1; then
            mandb -q || echo "注意: mandb 更新失败，手册可能不会立即生效。"
        else
            echo "注意: 未找到 mandb，已复制手册文件，但 man 数据库未更新。"
        fi
    else
        echo "注意: 压缩包中未找到 $MAN_FILE_NAME，跳过帮助手册安装。"
    fi
else
    echo "已根据配置跳过 man 手册安装。"
fi

# ============================================================
# 安装后确认
# ============================================================

final_version=$("$INSTALL_BIN_PATH" --version 2>/dev/null | head -n 1)

echo
echo "更新完成！"
echo "当前安装路径: $INSTALL_BIN_PATH"
echo "当前版本: $final_version"
echo
echo '现在可以运行 "rclone config" 进行配置。'

exit 0
