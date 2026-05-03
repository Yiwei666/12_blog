# 1. 项目功能

1. v2ray下载安装脚本
2. 通过github api定期下载v2rayNG的最新版apk，并提供网页下载


# 2. 文件结构

```sh
91_download_v2rayng_apk.sh            # 定期下载最新版github中的v2rayNG到指定目录
91_apk_github.php                     # 页面显示v2rayNG，并提供网页下载
```


# 3. 环境配置

## 1. `91_download_v2rayng_apk.sh`

### 1. 功能

自动从 GitHub 获取 v2rayNG 项目的最新 Release，并下载其中所有 .apk 安装包到指定目录。


### 2. 编程思路

编写bash脚本实现如下功能：
1. 检查`/home/01_html/91_apk_github/01_v2rayNG`这个目录是否存在，然后清空这个目录下的所有文件。
2. 调用github的api，查询 `https://github.com/2dust/v2rayNG/releases` 这个路径下最新发布版本的apk（似乎均位于Assets下）。
3. 将最新版本的所有apk下载到服务器上的 `/home/01_html/91_apk_github/01_v2rayNG`目录下。


### 3. 环境变量

1. cron定时任务

```sh
# 每周五的4点7分定时下载，cc1-2服务器
7 4 * * 5 /usr/bin/bash /home/01_html/91_download_v2rayng_apk.sh >> /home/01_html/91_download_v2rayng_apk.log 2>&1
```



## 2. `91_apk_github.php`

### 1. 功能

自动扫描指定目录下的 `.apk` 文件，按目录树形式展示文件名、大小、更新时间和路径，并支持点击文件名进行安全下载。代码还包含路径校验、文件类型限制、下载参数验证和前端折叠目录树等功能，适合用于服务器上集中展示和分发 APK 安装包。

### 2. 编程思路

编写php代码实现如下需求：
1. `/home/01_html/91_apk_github` 路径下可能包含多个子文件夹，每个子文件夹中可能包含有apk为后缀的文件。
2. 在网页上按照目录树的结构显示上述目录下的apk文件。
3. 由于域名`domain.com`（采用变量赋值管理）对应的根目录是 `root /home/01_html`，因此需要用户在网页上点击目录树上相关文件名时，能实现自动下载该文件。
4. 上述网页设计的尽量美观、优雅，可参考github、苹果、特斯拉等相关网页的设计。

输出满足上述需求的完整代码。


### 3. 环境变量

注意修改服务器对应的域名、网站的根目录以及存放apk文件的目录

```sh
$domain      = 'yourdomain.com';                 // 域名
$webRoot     = '/home/01_html';                  // 站点根目录
$scanBaseDir = '/home/01_html/91_apk_github';    // 需要扫描的目录
```

