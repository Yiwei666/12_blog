🟢 以下安装教程参考自：https://github.com/hausa-han/Cloudflare-WARP-proxy/blob/main/README.md


使用Cloudflare WARP进行代理，解锁openai等服务。
Cloudfalre官方页面有详细的安装流程和原理，不赘述。
https://developers.cloudflare.com/warp-client/setting-up/linux

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
