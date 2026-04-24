# 1. cloudflare warp介绍


使用Cloudflare WARP进行代理，解锁openai等服务。

Cloudfalre官方页面有详细的安装流程和原理，不赘述。
https://developers.cloudflare.com/warp-client/setting-up/linux


# 2. cloudflare warp 安装

## 1. 首次安装

支持的ubuntu版本:

- Jammy (22.04)
- Focal (20.04)
- Bionic (18.04)
- Xenial (16.04)


```sh
# 确认ubuntu版本号
lsb_release -cs
```


### 1. Add cloudflare gpg key

```bash
curl -fsSL https://pkg.cloudflareclient.com/pubkey.gpg | sudo gpg --yes --dearmor --output /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg
```

这条命令下载 Cloudflare Warp 的 GPG 密钥，然后使用 `gpg` 工具进行解密并将其放置在 `/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg` 文件中。


### 2. Add this repo to your apt repositories

```bash
echo "deb [signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] https://pkg.cloudflareclient.com/ $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/cloudflare-client.list
```

这条命令将 Cloudflare Warp 的软件源添加到 apt 的仓库中。它会在 `/etc/apt/sources.list.d/cloudflare-client.list` 文件中添加一行，指定 Cloudflare Warp 的仓库地址和组件。


### 3. Install

```bash
sudo apt-get update && sudo apt-get install cloudflare-warp
```

这条命令首先更新 apt 软件包列表，然后安装 Cloudflare Warp 软件包。


- 参考资料
  1. https://developers.cloudflare.com/warp-client/get-started/linux/
  2. https://pkg.cloudflareclient.com/#ubuntu



## 2. 版本更新

### 1. 更新warp

1. 查看当前版本

```sh
# 查看已经安装的版本
warp-cli --version

# 查看 cloudflare-warp 这个软件包的安装情况、候选版本，以及它来自哪个软件源
apt policy cloudflare-warp
```

如果看到类似：

```sh
(base) root@racknerd-47ac22:/home/01_html# apt policy cloudflare-warp
cloudflare-warp:
  Installed: 2023.3.398-1
  Candidate: 2023.3.398-1
  Version table:
 *** 2023.3.398-1 100
        100 /var/lib/dpkg/status
```

说明当前 APT 没有从 Cloudflare 仓库获取到新版。


2. 重新添加 Cloudflare WARP 官方 GPG key

```sh
# usr/share/keyrings 是存放第三方软件源公钥的推荐位置，在大多数标准的 Ubuntu 或 Debian 系统中，它通常是存在的
mkdir -p /usr/share/keyrings

# 1. 从 Cloudflare 的服务器上下载名为 pubkey.gpg 的公钥文件
# 2. | 把下载到的数据传给下一个程序
# 3. --dearmor 将下载到的文本格式（ASCII armored）的密钥转换成 Linux 包管理器更容易读取的 二进制格式
# 4. --output 将转换后的二进制密钥保存在第一条命令创建的目录下，命名为 cloudflare-warp-archive-keyring.gpg
curl -fsSL https://pkg.cloudflareclient.com/pubkey.gpg | sudo gpg --yes --dearmor --output /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg
```
这是 Cloudflare WARP 官方仓库页面给出的 key 添加方式。


3. 重新添加 WARP 的 apt 源

```sh
# 把 Cloudflare WARP 官方下载地址注册到的系统软件源里
echo "deb [signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] https://pkg.cloudflareclient.com/ $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/cloudflare-client.list

# 然后更新索引
sudo apt update

# 查看是否已有新版候选版本
apt policy cloudflare-warp
```

正常情况下应该看到如下类似，即`Candidate`中有新版本。

```
(base) root@racknerd-47ac22:/home/01_html# apt policy cloudflare-warp
cloudflare-warp:
  Installed: 2023.3.398-1
  Candidate: 2026.3.846.0
  Version table:
     2026.3.846.0 500
        500 https://pkg.cloudflareclient.com jammy/main amd64 Packages
 *** 2023.3.398-1 100
        100 /var/lib/dpkg/status
```


4. 更新 Cloudflare WARP

```sh
# 更新
apt install --only-upgrade cloudflare-warp

# 查看服务状态
systemctl status warp-svc

# 查看版本
warp-cli --version

# 查看连接状态
warp-cli status
```


### 2. 重新注册 WARP 并配置

新版 WARP 在 MASQUE + Local Proxy 模式下读取到旧注册信息/旧密钥格式，导致公钥长度不匹配。因此，需要重新注册 WARP 并配置。

```sh
# 断开当前 WARP 连接（确保后续操作在干净状态下进行）
warp-cli disconnect

# 删除本机已有的 WARP 注册信息（清除旧密钥/配置）
warp-cli registration delete

# 重新注册 WARP 客户端（生成新的密钥和设备身份）
warp-cli registration new

# 设置为本地代理模式（WarpProxy，默认监听 127.0.0.1:40000）
warp-cli mode proxy

# 重启 WARP 服务，使配置生效
systemctl restart warp-svc

# 等待服务完全启动（避免后续命令执行过快）
sleep 5

# 连接到 WARP 网络
warp-cli connect

# 等待连接建立（确保状态稳定）
sleep 5

# 查看当前 WARP 连接状态（应为 Connected）
warp-cli status

# 检查本机 40000 端口是否被 WARP 监听（判断代理是否启动成功）
ss -ltnp | grep 40000

# 通过 SOCKS5 代理测试 WARP 是否生效（应返回 warp=on）
curl -x socks5h://127.0.0.1:40000 https://www.cloudflare.com/cdn-cgi/trace
```


- `warp-cli settings`查看新版本（`warp-cli 2026.3.846.0`版本）的设置如下：

```
(base) root@racknerd-47ac22:/home/01_html# warp-cli settings
Merged configuration:
(not set)	Compliance Environment: Normal
(derived)	Always On: true
(override)	Switch Locked: false
(user set)	Mode: WarpProxy on port 40000
(network policy)	WARP tunnel protocol: MASQUE
(not set)	MASQUE Protocol Settings: 
  HTTP Version: MASQUE (HTTP/3 with HTTP/2 fallback)
(network policy)	Post-quantum support for MASQUE: Enabled (downgrades allowed)
(default)	Disabled for Wifi: false
(default)	Disabled for Ethernet: false
(not set)	Resolve via: cloudflare-dns.com @ [162.159.36.1, 162.159.46.1, 2606:4700:4700::1111, 2606:4700:4700::1001]
(not set)	qlog log until: FutureSystemTime(None)
(default)	Onboarding: true
(api defaults)	Exclude mode, with hosts/ips:
  10.0.0.0/8
  100.64.0.0/10
  169.254.0.0/16
  172.16.0.0/12
  192.0.0.0/24
  192.168.0.0/16
  224.0.0.0/24
  240.0.0.0/4
  239.255.255.250/32
  255.255.255.255/32
  fe80::/10
  fd00::/8
  ff01::/16
  ff02::/16
  ff03::/16
  ff04::/16
  ff05::/16
  fc00::/7
  17.249.0.0/16
  17.252.0.0/16
  17.57.144.0/22
  17.188.128.0/18
  17.188.20.0/23
  2620:149:a44::/48
  2403:300:a42::/48
  2403:300:a51::/48
  2a01:b740:a42::/48

(default)	Fallback domains:
  corp
  domain
  home
  home.arpa
  host
  internal
  intranet
  invalid
  lan
  local
  localdomain
  localhost
  private
  test
(not set)	Daemon Teams Auth: false
(default)	Disable Auto Fallback: false
(not set)	Allow Updates: true
(not set)	Registration Scope: System
(not set)	Register Tunnel Interface IP: false
(not set)	Firewall Scope: All interfaces
```

### 3. 注意事项

1. Cloudflare 官方文档说明，Local Proxy 模式下，WARP/Cloudflare One Client 会监听 `127.0.0.1` / `localhost` 上的配置端口，默认端口是 `40000`。应用程序或系统代理必须显式配置为使用该本机代理，相关流量才会通过 WARP。

2. Local Proxy 模式支持应用通过 HTTP/HTTPS 代理或 SOCKS5 代理连接 WARP 本机代理端口。对于命令行测试，建议使用 `socks5h://127.0.0.1:40000`，这样 DNS 解析也会通过 SOCKS5 代理完成。

3. MASQUE 是 WARP 客户端与 Cloudflare 服务器之间的底层隧道协议，不是 V2Ray/Xray 需要配置的协议。V2Ray/Xray 只需要把指定域名的出站流量转发到 `127.0.0.1:40000` 的 SOCKS5 代理即可。

4. 在本次升级中，如果出现 `InvalidPublicKeyLength(32)` 或 40000 端口不监听的问题，可尝试删除旧注册并重新注册 WARP，然后重新设置 `mode proxy`。

- 流量传递路径

```
V2Ray routing 命中 openai.com / chatgpt.com / github.com
        ↓
V2Ray outboundTag: socks_out
        ↓
V2Ray 使用 SOCKS5 连接 127.0.0.1:40000
        ↓
warp-svc 本地代理接收流量
        ↓
WARP 使用 MASQUE 协议连接 Cloudflare
        ↓
Cloudflare WARP 出口访问目标网站
```



# 3. cloudflare warp配置

🟢 以下安装教程参考自：https://github.com/hausa-han/Cloudflare-WARP-proxy/blob/main/README.md

这里写下linux机器的配置过程
注：以下过程是在v2ray/xray的服务器上操作，而不是在自己的机器上。

1. 注册客户端
```bash
# 旧版本注册命令
# warp-cli register

warp-cli registration new

# 查看注册状态
warp-cli registration show

```

2. 设置WARP代理模式
```bash
warp-cli set-mode proxy     # 旧版本命令

# Warning: The "set-mode" command will be deprecated in a future release. Please use "mode" instead
warp-cli mode proxy         # 新版本命令
```

3. 连接WARP
```bash
warp-cli connect
 
# warp-cli disconnect   # 断开连接
```
此时WARP会使用socks5本机代理 `127.0.0.1：40000`

4. 打开 `warp always-on`

注意：`warp-cli enable-always-on`命令在新版本 (warp-cli 2024.2.62) 的warp中已经弃用，默认 `Always On: true` 是打开的

```bash
warp-cli enable-always-on
 
# warp-cli status     # 查看warp状态
# warp-cli help       # 查看warp-cli命令帮助
# warp-cli settings   # 查看warp-cli命令设置
```

5. 测试socks代理，检查ip是否改变

```bash
# 命令是用于在当前的终端或 shell 会话中设置代理服务器，以便所有的网络请求都可以通过指定的 SOCKS5 代理服务器进行转发。
# 该终端中发起的所有网络连接都会通过该代理服务器进行路由
# 下面命令设置的环境变量只会在当前会话中生效，当您关闭当前终端或退出当前会话时，该环境变量也会失效。
export ALL_PROXY=socks5://127.0.0.1:40000   
 
# echo $ALL_PROXY     # 打印出设置的环境变量值
 
curl ifconfig.me      # 从终端或命令行获取当前设备的公共 IP 地址, curl 命令默认会使用端口80来发出HTTP请求，因为80是HTTP的标准端口。
 
# curl ifconfig.me --proxy socks5://127.0.0.1:40000   # 用于通过指定的 SOCKS5 代理服务器向 ifconfig.me 发送 HTTP 请求，并从该网站获取当前设备的公共 IP 地址。
 
# curl chat.openai.com     # 测试不使用代理的情况下能否访问
 
# curl chat.openai.com --socks5 127.0.0.1:40000 -v    # 通过 SOCKS5 代理服务器与 chat.openai.com 进行通信，并在终端输出详细的调试信息，包括请求头、响应头和数据内容等。
```

6. 查看cloudflare warp的设置

运行`warp-cli settings`，查看cloudflare warp的设置，确保上述命令行设置都已经生效

```
Merged configuration:
Always On: true
Switch Locked: false
Mode: WarpProxy on port 40000
Cloudflare for Families: Off
Disabled for Wifi: false
Disabled for Ethernet: false
Onboarding: true
Exclude mode, with hosts/ips:
  10.0.0.0/8
  100.64.0.0/10
  169.254.0.0/16
  172.16.0.0/12
  192.0.0.0/24
  192.168.0.0/16
  224.0.0.0/24
  240.0.0.0/4
  239.255.255.250/32
  255.255.255.255/32
  fe80::/10
  fd00::/8
  ff01::/16
  ff02::/16
  ff03::/16
  ff04::/16
  ff05::/16
  fc00::/7

Fallback domains:
  intranet
  internal
  private
  localdomain
  domain
  lan
  home
  host
  corp
  local
  localhost
  home.arpa
  invalid
  test
Daemon Teams Auth: false
Disable Auto Fallback: false
Allow Updates: true
```


7. 修改v2ray/xray outbounds和分流规则，这里可以参考以下配置可自由发挥。
~ 建议在修改配置前对原有配置文件进行.bak备份。 ~
```bash
vim /usr/local/etc/v2ray/config.json
```
这是v2ray或者xray的配置文件，如果你的用户是root，那么它可能在/etc/v2ray/config.json

inbounds要启动sniffing
```json
"sniffing": {
    "enabled": true,
    "destOverride": ["http", "tls"]
}
```
```json
 "outbounds": [
        {
            "tag": "default",
            "protocol": "freedom"
        },
        {
            "tag":"socks_out",
            "protocol": "socks",
            "settings": {
                "servers": [
                     {
                        "address": "127.0.0.1",
                        "port": 40000
                    }
                ]
            }
        }
    ],
    "routing": {
        "rules": [
            {
                "type": "field",
                "outboundTag": "socks_out",
                "domain": [
                    "example.com",
                    "example.com"
                    ]
            },
            {
                "type": "field",
                "outboundTag": "default",
                "network": "udp,tcp"
            }
        ]
    }
```
请将`example.com`替换为你想要解锁访问的网站，例如访问chatGPT需要的：`openai.com`和`hcaptcha.com`。


8. 重新启动v2ray/xray
```bash
systemctl restart v2ray/xray
systemctl status v2ray/xray
```
xray可能需要下载geosite和geoip，
google github上就能找到，下载后放在 /usr/local/bin



# 4. warp命令行

### 1. 常用命令

```bash
warp-cli  --help
warp-cli  status
warp-cli settings

warp-cli registration show    # 查看注册状态

warp-cli --version            # 查看已经安装的版本

apt policy cloudflare-warp    # 查看 cloudflare-warp 这个软件包的安装情况、候选版本，以及它来自哪个软件源

# 查看 Cloudflare WARP 服务的最近 100 行系统日志
journalctl -u warp-svc -n 100 --no-pager
```


### 2. `warp-cli 2023.3.398`版本所有命令行

```bash
Usage: warp-cli [OPTIONS] <COMMAND>

Commands:
  register                     Register with the WARP API, replacing any existing registration (Must be run before first connection!)
  teams-enroll                 Enroll with Cloudflare for Teams
  delete                       Delete current registration
  rotate-keys                  Generate a new key-pair, keeping the current registration
  status                       Ask the daemon to send the current status
  warp-stats                   Retrieve the stats for the current WARP connection
  warp-dns-stats               Retrieve the DNS stats for the current WARP connection
  settings                     Retrieve the current application settings
  connect                      Connect to WARP whenever possible [aliases: enable-always-on]
  disconnect                   Disconnect from WARP [aliases: disable-always-on]
  disable-wifi                 Automatically disable WARP on Wi-Fi networks (disabled for Zero Trust customers)
  enable-wifi                  Allow WARP on Wi-Fi networks (disabled for Zero Trust customers)
  disable-ethernet             Automatically disable WARP on ethernet networks (disabled for Zero Trust customers)
  enable-ethernet              Allow WARP on ethernet networks (disabled for Zero Trust customers)
  add-trusted-ssid             Add a trusted Wi-Fi network for which WARP will be automatically disconnected
  remove-trusted-ssid          Remove a trusted Wi-Fi network
  exclude-private-ips          Exclude private IP ranges from tunnel
  enable-dns-log               Enable DNS logging (Use with the -l option)
  disable-dns-log              Disable DNS logging
  account                      Display the account associated with the current registration
  devices                      Display the list of devices associated with the current registration
  network                      Display the current network information
  get-virtual-networks         List the available virtual networks
  set-virtual-network          Set the currently connected virtual network via the id from get-virtual-networks
  set-mode                     Set the mode
  set-families-mode            Set the families mode
  set-license                  Attach the current registration to a different account using a license key
  set-gateway                  Force the app to use the specified Gateway ID for DNS queries
  clear-gateway                Clear the Gateway ID
  set-custom-endpoint          Force the client to connect to the specified IP:PORT endpoint (Zero Trust customers must run this command as a privileged user)
  clear-custom-endpoint        Remove the custom endpoint setting
  add-excluded-route           Add an excluded IP
  remove-excluded-route        Remove an excluded IP
  get-excluded-routes          Get the list of excluded routes
  get-included-routes          Get the list of included routes
  get-excluded-hosts           Get the list of excluded hosts
  get-included-hosts           Get the list of included hosts
  add-excluded-host            Add an excluded host
  remove-excluded-host         Remove an excluded host
  add-fallback-domain          Add a domain that should be resolved with the fallback resolver instead of WARP's
  remove-fallback-domain       Stop a domain from being resolved with the fallback resolver
  get-fallback-domains         Get the list of domains that go to the fallback resolver
  restore-fallback-domains     Restore the list of fallback resolver domains to its default value
  get-device-posture           Get the current device posture
  override                     Temporarily override MDM policies that require the client to stay enabled
  set-proxy-port               Set the listening port for WARP proxy (127.0.0.1:{port})
  is-mode-switch-allowed       Outputs true if Teams users should be able to change connection mode, or false if not
  reset-settings               Restore settings to default
  get-organization             Get the name of the Teams organization currently in settings
  access-reauth                Force refresh authentication with Cloudflare Access
  get-support-url              Get the support url for the current Teams organization
  get-pause-end                Retrieve the pause end time
  get-override-end             Retrieve the admin override end time
  disable-connectivity-checks  Disable the runtime connectivity checks
  enable-connectivity-checks   Enable the runtime connectivity checks
  dump-excluded-routes         Get split tunnel routing dump. For include-only mode, this shows routes NOT included
  get-alternate-network        Get the name of the currently detected alternate network, if any
  get-dex-data                 Get the most recently uploaded DEX data. Returns the most recent test for each dex metric
  help                         Print this message or the help of the given subcommand(s)

Options:
  -l, --listen      Listen for status changes and DNS logs (if enabled)
      --accept-tos  Accept the Terms of Service agreement
  -v, --verbose...  Enable verbose output. Multiple "v"s adds more verbosity
  -h, --help        Print help
  -V, --version     Print version
```

### 2. `warp-cli 2024.2.62`版本命令行

```bash
Usage: warp-cli [OPTIONS] <COMMAND>

Commands:
  connect               Maintain a connection whenever possible
  debug                 Debugging commands
  disconnect            Disconnect the client
  dns                   Configure DNS settings
  mdm                   MDM configs
  mode                  Set the client's general operating mode
  override              Allow temporary overrides of administrative settings
  proxy                 Configure proxy mode settings
  registration          Registration settings
  settings              Show or alter general application settings
  status                Return the current connection status
  trusted               Configure trusted networks where the client will be automatically disabled (Consumer only)
  tunnel                Configure tunnel settings
  vnet                  Get or specify connected virtual network
  generate-completions  Generate completions for a given shell and print to stdout
  help                  Print this message or the help of the given subcommand(s)

Options:
  -l, --listen      Listen for status changes and DNS logs (if enabled)
      --accept-tos  Accept the Terms of Service agreement
  -v, --verbose...  Enable verbose output. Multiple "v"s adds more verbosity
  -h, --help        Print help
  -V, --version     Print version
```


