# 1. 默认路径：

DAT_PATH=${DAT_PATH:-/usr/local/share/v2ray}
JSON_PATH=${JSON_PATH:-/usr/local/etc/v2ray}

# 这里设置了默认的安装路径，如果用户在运行脚本之前没有设置DAT_PATH和JSON_PATH环境变量，将使用这些默认路径。


# 2. curl函数：

curl() {
  $(type -P curl) -L -q --retry 5 --retry-delay 10 --retry-max-time 60 "$@"
}

# 这个函数使用curl命令进行下载，并包含一些选项，例如重试下载，以确保可靠性。


# 3. systemd_cat_config函数：

systemd_cat_config() {
  if systemd-analyze --help | grep -qw 'cat-config'; then
    systemd-analyze --no-pager cat-config "$@"
    echo
  else
    # 如果systemd版本太低，使用传统方式打印配置
    echo "${aoi}~~~~~~~~~~~~~~~~"
    cat "$@" "$1".d/*
    echo "${aoi}~~~~~~~~~~~~~~~~"
    echo "${red}warning: ${green}The systemd version on the current operating system is too low."
    echo "${red}warning: ${green}Please consider to upgrade the systemd or the operating system.${reset}"
    echo
  fi
}

# 这个函数检查系统上是否支持systemd-analyze cat-config命令，如果支持，则使用该命令打印systemd配置，否则使用传统方式打印配置。


# 4. check_if_running_as_root函数：

check_if_running_as_root() {
  if [[ "$UID" -ne '0' ]]; then
    echo "WARNING: The user currently executing this script is not root. You may encounter the insufficient privilege error."
    read -r -p "Are you sure you want to continue? [y/n] " cont_without_been_root
    if [[ x"${cont_without_been_root:0:1}" = x'y' ]]; then
      echo "Continuing the installation with current user..."
    else
      echo "Not running with root, exiting..."
      exit 1
    fi
  fi
}

# 这个函数检查脚本是否以root权限运行，如果不是，则提示用户是否要继续。

# 5. identify_the_operating_system_and_architecture函数：

identify_the_operating_system_and_architecture() {
  if [[ "$(uname)" == 'Linux' ]]; then
    # ...
    # 省略了架构和包管理器的检测和设置部分
    # ...
  else
    echo "error: This operating system is not supported."
    exit 1
  fi
}

# 这个函数识别操作系统和架构，并根据检测到的信息设置相关的变量，如包管理器命令。





















