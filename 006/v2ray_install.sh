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


# 6. judgment_parameters函数:
## Demo function for processing parameters
judgment_parameters() {
  while [[ "$#" -gt '0' ]]; do
    case "$1" in
      '--remove')
        if [[ "$#" -gt '1' ]]; then
          echo 'error: Please enter the correct parameters.'
          exit 1
        fi
        REMOVE='1'
        ;;
      '--version')
        VERSION="${2:?error: Please specify the correct version.}"
        break
        ;;
      '-c' | '--check')
        CHECK='1'
        break
        ;;
      '-f' | '--force')
        FORCE='1'
        break
        ;;
      '-h' | '--help')
        HELP='1'
        break
        ;;
      '-l' | '--local')
        LOCAL_INSTALL='1'
        LOCAL_FILE="${2:?error: Please specify the correct local file.}"
        break
        ;;
      '-p' | '--proxy')
        if [[ -z "${2:?error: Please specify the proxy server address.}" ]]; then
          exit 1
        fi
        PROXY="$2"
        shift
        ;;
      *)
        echo "$0: unknown option -- -"
        exit 1
        ;;
    esac
    shift
  done
}

# 这个函数使用while循环处理传递给脚本的所有参数。通过case语句检查每个参数的类型，然后根据不同的参数类型执行相应的操作。
# 例如，--remove会设置REMOVE标志，--version会设置VERSION变量为指定的版本，-c会设置CHECK标志，以此类推。shift语句用于移除已经处理的参数。

# 7. install_software函数:

install_software() {
  package_name="$1"
  file_to_detect="$2"
  type -P "$file_to_detect" > /dev/null 2>&1 && return
  if ${PACKAGE_MANAGEMENT_INSTALL} "$package_name"; then
    echo "info: $package_name is installed."
  else
    echo "error: Installation of $package_name failed, please check your network."
    exit 1
  fi
}

# 这个函数用于安装指定的软件包。它接收两个参数：软件包名称（package_name）和用于检测是否已安装的文件路径（file_to_detect）。
# 首先，它使用type -P检测指定文件是否存在，如果存在则说明软件已安装，直接返回。如果文件不存在，就使用${PACKAGE_MANAGEMENT_INSTALL}执行包管理器安装软件包，如果安装失败则退出脚本。


# 8. get_current_version函数:

get_current_version() {
  if /usr/local/bin/v2ray -version > /dev/null 2>&1; then
    VERSION="$(/usr/local/bin/v2ray -version | awk 'NR==1 {print $2}')"
  else
    VERSION="$(/usr/local/bin/v2ray version | awk 'NR==1 {print $2}')"
  fi
  CURRENT_VERSION="v${VERSION#v}"
}

# 这个函数用于获取当前安装的v2ray版本。它首先尝试使用/usr/local/bin/v2ray -version获取版本号，如果失败则尝试使用/usr/local/bin/v2ray version。然后，通过awk命令提取版本号，将其存储在CURRENT_VERSION变量中。


# 9. get_version函数:

get_version() {
  # 0: Install or update V2Ray.
  # 1: Installed or no new version of V2Ray.
  # 2: Install the specified version of V2Ray.
  if [[ -n "$VERSION" ]]; then
    RELEASE_VERSION="v${VERSION#v}"
    return 2
  fi
  # Determine the version number for V2Ray installed from a local file
  if [[ -f '/usr/local/bin/v2ray' ]]; then
    get_current_version
    if [[ "$LOCAL_INSTALL" -eq '1' ]]; then
      RELEASE_VERSION="$CURRENT_VERSION"
      return
    fi
  fi
  # Get V2Ray release version number
  TMP_FILE="$(mktemp)"
  if ! curl -x "${PROXY}" -sS -i -H "Accept: application/vnd.github.v3+json" -o "$TMP_FILE" 'https://api.github.com/repos/v2fly/v2ray-core/releases/latest'; then
    "rm" "$TMP_FILE"
    echo 'error: Failed to get release list, please check your network.'
    exit 1
  fi
  HTTP_STATUS_CODE=$(awk 'NR==1 {print $2}' "$TMP_FILE")
  if [[ $HTTP_STATUS_CODE -lt 200 ]] || [[ $HTTP_STATUS_CODE -gt 299 ]]; then
    "rm" "$TMP_FILE"
    echo "error: Failed to get release list, GitHub API response code: $HTTP_STATUS_CODE"
    exit 1
  fi
  RELEASE_LATEST="$(sed 'y/,/\n/' "$TMP_FILE" | grep 'tag_name' | awk -F '"' '{print $4}')"
  "rm" "$TMP_FILE"
  RELEASE_VERSION="v${RELEASE_LATEST#v}"
  # Compare V2Ray version numbers
  if [[ "$RELEASE_VERSION" != "$CURRENT_VERSION" ]]; then
    RELEASE_VERSIONSION_NUMBER="${RELEASE_VERSION#v}"
    RELEASE_MAJOR_VERSION_NUMBER="${RELEASE_VERSIONSION_NUMBER%%.*}"
    RELEASE_MINOR_VERSION_NUMBER="$(echo "$RELEASE_VERSIONSION_NUMBER" | awk -F '.' '{print $2}')"
    RELEASE_MINIMUM_VERSION_NUMBER="${RELEASE_VERSIONSION_NUMBER##*.}"
    # shellcheck disable=SC2001
    CURRENT_VERSION_NUMBER="$(echo "${CURRENT_VERSION#v}" | sed 's/-.*//')"
    CURRENT_MAJOR_VERSION_NUMBER="${CURRENT_VERSION_NUMBER%%.*}"
    CURRENT_MINOR_VERSION_NUMBER="$(echo "$CURRENT_VERSION_NUMBER" | awk -F '.' '{print $2}')"
    CURRENT_MINIMUM_VERSION_NUMBER="${CURRENT_VERSION_NUMBER##*.}"
    if [[ "$RELEASE_MAJOR_VERSION_NUMBER" -gt "$CURRENT_MAJOR_VERSION_NUMBER" ]]; then
      return 0
    elif [[ "$RELEASE_MAJOR_VERSION_NUMBER" -eq "$CURRENT_MAJOR_VERSION_NUMBER" ]]; then
      if [[ "$RELEASE_MINOR_VERSION_NUMBER" -gt "$CURRENT_MINOR_VERSION_NUMBER" ]]; then
        return 0
      elif [[ "$RELEASE_MINOR_VERSION_NUMBER" -eq "$CURRENT_MINOR_VERSION_NUMBER" ]]; then
        if [[ "$RELEASE_MINIMUM_VERSION_NUMBER" -gt "$CURRENT_MINIMUM_VERSION_NUMBER" ]]; then
          return 0
        else
          return 1
        fi
      else
        return 1
      fi
    else
      return 1
    fi
  elif [[ "$RELEASE_VERSION" == "$CURRENT_VERSION" ]]; then
    return 1
  fi
}

# 这个函数用于确定是否需要安装新的V2Ray版本。首先，如果用户通过--version指定了版本，那么RELEASE_VERSION会被设置为指定的版本，并且函数返回值为2。接着，如果本地已安装V2Ray，通过get_current_version获取当前版本。
# 如果是本地安装，则RELEASE_VERSION被设置为当前版本。然后，通过GitHub API获取V2Ray最新的版本号，并进行版本比较。如果需要安装新版本，返回值为0。
















