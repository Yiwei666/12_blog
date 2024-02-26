# 1. cloudflare warp介绍


使用Cloudflare WARP进行代理，解锁openai等服务。

Cloudfalre官方页面有详细的安装流程和原理，不赘述。
https://developers.cloudflare.com/warp-client/setting-up/linux


# 2. cloudflare warp配置

🟢 以下安装教程参考自：https://github.com/hausa-han/Cloudflare-WARP-proxy/blob/main/README.md

这里写下linux机器的配置过程
注：以下过程是在v2ray/xray的服务器上操作，而不是在自己的机器上。

1. 注册客户端
```bash
warp-cli register
```

2. 设置WARP代理模式
```bash
warp-cli set-mode proxy
```

3. 连接WARP
```bash
warp-cli connect
 
# warp-cli disconnect   # 断开连接
```
此时WARP会使用socks5本机代理127.0.0.1：40000

4. 打开warp always-on
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

6. 修改v2ray/xray outbounds和分流规则，这里可以参考以下配置可自由发挥。
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


8.重新启动v2ray/xray
```bash
systemctl restart v2ray/xray
systemctl status v2ray/xray
```
xray可能需要下载geosite和geoip，
google github上就能找到，下载后放在 /usr/local/bin


### 3. warp命令行

1. 常用命令

```
warp-cli  --help
warp-cli  status
```


2. 所有命令行

```
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

