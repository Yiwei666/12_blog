# 1. 项目功能

1. v2ray下载安装脚本


# 2. 文件结构

```sh
91_download_v2rayng_apk.sh            # 下载github中的v2rayNG到指定目录

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


