🟢 以下安装教程参考自：https://github.com/hausa-han/Cloudflare-WARP-proxy/blob/main/README.md


使用Cloudflare WARP进行代理，解锁openai等服务。
Cloudfalre官方页面有详细的安装流程和原理，不赘述。
https://developers.cloudflare.com/warp-client/setting-up/linux

这里写下linux机器的配置过程
注：以下过程是在v2ray/xray的服务器上操作，而不是在自己的机器上。

1.注册客户端
```
warp-cli register
```
2.设置WARP代理模式
```
warp-cli set-mode proxy
```
3.连接WARP
```
warp-cli connect
```
此时WARP会使用socks5本机代理127.0.0.1：40000
4.打开warp always-on
```
warp-cli enable-always-on
```
6.测试socks代，理检查ip是否改变
```
export ALL_PROXY=socks5://127.0.0.1:40000
curl ifconfig.me
```
7.修改v2ray/xray outbounds和分流规则，这里可以参考以下配置可自由发挥。
~ 建议在修改配置前对原有配置文件进行.bak备份。 ~
```
vim /usr/local/etc/v2ray/config.json
```
这是v2ray或者xray的配置文件，如果你的用户是root，那么它可能在/etc/v2ray/config.json

inbounds要启动sniffing
```
"sniffing": {
    "enabled": true,
    "destOverride": ["http", "tls"]
}
```
```
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
```
systemctl restart v2ray/xray
systemctl status v2ray/xray
```
xray可能需要下载geosite和geoip，
google github上就能找到，下载后放在 /usr/local/bin
