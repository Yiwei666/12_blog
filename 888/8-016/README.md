# 1. 文件结构

```sh
26_vless_generator.php                # 网页端输入5个参数，生成VLESS分享链接，可直接导入到v2rayNG等软件

```




# 2. `26_vless_generator.php`

## 1. 脚本功能

1. 功能：让用户在网页上输入 VLESS REALITY 配置参数，然后自动生成可导入客户端的 VLESS 分享链接

2. 参数含义：

```php
$address = $_POST['address'] ?? '';
// address：服务器地址
// 可以填写域名或服务器 IP。
// 在生成的链接中位于 vless://id@address:443 这一部分。
// 例如：example.com、mctea.one、1.2.3.4

$id = $_POST['id'] ?? '';
// id：用户 UUID
// 用于客户端和服务器端识别同一个 VLESS 用户。
// 必须与服务器端 Xray/V2Ray 配置中的 clients -> id 保持一致。
// 例如：xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx

$publicKey = $_POST['publicKey'] ?? '';
// publicKey：REALITY 公钥
// 由服务器端 REALITY 私钥推导/生成出来，客户端需要填写公钥。
// 在链接中对应 pbk 参数。
// 注意：客户端填写 publicKey，服务器端保存 privateKey。

$shortId = $_POST['shortId'] ?? '';
// shortId：REALITY shortId
// REALITY 握手时使用的短标识符，相当于一个辅助识别参数。
// 必须与服务器端 REALITY 配置中的 shortIds 保持一致。
// 在链接中对应 sid 参数。
// 可以为空，也可以是十六进制字符串，常见如：a1b2c3d4

$remarks = $_POST['remarks'] ?? '';
// remarks：节点备注名称
// 主要用于客户端显示这个节点的名字，不参与服务器认证。
// 在链接中位于 # 后面。
// 例如：racknerd-us-01、azure-jp-01、美国节点1
```



## 2. 编程思路

```json
"address": "value1"
"id": "value2"
"publicKey": "value3"
"shortId": "value4"
"remarks": "value5"
```

编写一个php脚本，网页访问该脚本时，提示用户输入 address、id等上述5个值，分别对应value1-5，然后将用户输入的值赋值给下面字符串，打印赋值后的字符串

```sh
vless://value2@value1:443?encryption=none&security=reality&type=tcp&sni=www.cloudflare.com&fp=chrome&pbk=value3&sid=value4&spx=%2F&flow=xtls-rprx-vision#value5
```

输出满足上述需求的php脚本，页面要美观



## 3. 环境变量

无。

