<?php
declare(strict_types=1);

/**
 * APK 文件树展示与下载
 * 保存路径示例：/home/01_html/91_apk_github.php
 * 访问地址示例：http://domain.com/91_apk_github.php
 */

mb_internal_encoding('UTF-8');

/* =========================
 * 基础配置
 * ========================= */
$domain      = 'yourdomain.com';                 // 域名
$webRoot     = '/home/01_html';              // 站点根目录
$scanBaseDir = '/home/01_html/91_apk_github';// 需要扫描的目录
$pageTitle   = 'APK 文件中心';

/* =========================
 * 安全检查
 * ========================= */
if (!is_dir($scanBaseDir)) {
    http_response_code(500);
    exit('错误：扫描目录不存在。');
}

$realWebRoot     = realpath($webRoot);
$realScanBaseDir = realpath($scanBaseDir);

if ($realWebRoot === false || $realScanBaseDir === false) {
    http_response_code(500);
    exit('错误：路径解析失败。');
}

if (strpos($realScanBaseDir, $realWebRoot) !== 0) {
    http_response_code(500);
    exit('错误：扫描目录不在站点根目录之下。');
}

/* =========================
 * 工具函数
 * ========================= */

/**
 * HTML 转义
 */
function e(string $value): string
{
    return htmlspecialchars($value, ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8');
}

/**
 * 文件大小格式化
 */
function formatBytes(int $bytes): string
{
    $units = ['B', 'KB', 'MB', 'GB', 'TB'];
    $i = 0;
    $size = (float)$bytes;

    while ($size >= 1024 && $i < count($units) - 1) {
        $size /= 1024;
        $i++;
    }

    return $i === 0 ? $bytes . ' ' . $units[$i] : number_format($size, 2) . ' ' . $units[$i];
}

/**
 * 时间格式化
 */
function formatTime(int $timestamp): string
{
    return date('Y-m-d H:i:s', $timestamp);
}

/**
 * 将绝对路径转为相对 webRoot 的 URL 路径
 */
function absolutePathToUrlPath(string $absolutePath, string $realWebRoot): string
{
    $realAbsolute = realpath($absolutePath);
    if ($realAbsolute === false || strpos($realAbsolute, $realWebRoot) !== 0) {
        return '#';
    }

    $relative = substr($realAbsolute, strlen($realWebRoot));
    $relative = str_replace(DIRECTORY_SEPARATOR, '/', $relative);

    return $relative === '' ? '/' : $relative;
}

/**
 * 构建目录树
 * 仅保留包含 APK 的目录分支
 */
function buildApkTree(string $baseDir): array
{
    $tree = [
        'name' => basename($baseDir),
        'path' => $baseDir,
        'type' => 'dir',
        'children' => [],
        'apk_count' => 0,
    ];

    $items = @scandir($baseDir);
    if ($items === false) {
        return $tree;
    }

    $dirs = [];
    $files = [];

    foreach ($items as $item) {
        if ($item === '.' || $item === '..') {
            continue;
        }

        $fullPath = $baseDir . DIRECTORY_SEPARATOR . $item;

        if (is_dir($fullPath)) {
            $dirs[] = $item;
        } elseif (is_file($fullPath) && preg_match('/\.apk$/i', $item)) {
            $files[] = $item;
        }
    }

    natcasesort($dirs);
    natcasesort($files);

    foreach ($dirs as $dirName) {
        $childPath = $baseDir . DIRECTORY_SEPARATOR . $dirName;
        $childTree = buildApkTree($childPath);

        if ($childTree['apk_count'] > 0) {
            $tree['children'][] = $childTree;
            $tree['apk_count'] += $childTree['apk_count'];
        }
    }

    foreach ($files as $fileName) {
        $filePath = $baseDir . DIRECTORY_SEPARATOR . $fileName;
        $tree['children'][] = [
            'name'      => $fileName,
            'path'      => $filePath,
            'type'      => 'file',
            'size'      => filesize($filePath) ?: 0,
            'mtime'     => filemtime($filePath) ?: time(),
            'extension' => strtolower(pathinfo($fileName, PATHINFO_EXTENSION)),
        ];
        $tree['apk_count']++;
    }

    return $tree;
}

/**
 * 统计总目录数、总文件数
 */
function collectStats(array $node, int &$dirCount, int &$fileCount): void
{
    if ($node['type'] === 'dir') {
        $dirCount++;
        foreach ($node['children'] as $child) {
            collectStats($child, $dirCount, $fileCount);
        }
    } else {
        $fileCount++;
    }
}

/**
 * 渲染目录树 HTML
 */
function renderTree(array $node, string $realWebRoot): string
{
    if ($node['type'] === 'file') {
        $downloadToken = base64_encode($node['path']);
        $urlPath = absolutePathToUrlPath($node['path'], $realWebRoot);

        $html  = '<li class="tree-item file-item">';
        $html .= '<div class="node-row">';
        $html .= '<span class="node-left">';
        $html .= '<span class="icon file-icon" aria-hidden="true">⬇</span>';
        $html .= '<a class="file-link" href="?download=' . rawurlencode($downloadToken) . '" title="点击下载 ' . e($node['name']) . '">';
        $html .= e($node['name']);
        $html .= '</a>';
        $html .= '</span>';

        $html .= '<span class="meta">';
        $html .= '<span class="badge">APK</span>';
        $html .= '<span class="size">' . e(formatBytes((int)$node['size'])) . '</span>';
        $html .= '<span class="time">' . e(formatTime((int)$node['mtime'])) . '</span>';
        $html .= '</span>';
        $html .= '</div>';

        $html .= '<div class="file-submeta">';
        $html .= '<span class="submeta-label">URL:</span> ';
        $html .= '<code>' . e($urlPath) . '</code>';
        $html .= '</div>';

        $html .= '</li>';

        return $html;
    }

    $isRoot = basename($node['path']) === basename(realpath($node['path']) ?: $node['path']);
    $openClass = ' open';

    $html  = '<li class="tree-item dir-item' . $openClass . '">';
    $html .= '<div class="node-row dir-row" onclick="toggleFolder(this)">';
    $html .= '<span class="node-left">';
    $html .= '<span class="caret" aria-hidden="true">▾</span>';
    $html .= '<span class="icon folder-icon" aria-hidden="true">📁</span>';
    $html .= '<span class="dir-name">' . e($node['name']) . '</span>';
    $html .= '</span>';
    $html .= '<span class="meta">';
    $html .= '<span class="count">' . (int)$node['apk_count'] . ' 个 APK</span>';
    $html .= '</span>';
    $html .= '</div>';

    if (!empty($node['children'])) {
        $html .= '<ul class="tree-children">';
        foreach ($node['children'] as $child) {
            $html .= renderTree($child, $realWebRoot);
        }
        $html .= '</ul>';
    }

    $html .= '</li>';

    return $html;
}

/* =========================
 * 下载处理
 * ========================= */
if (isset($_GET['download'])) {
    $downloadToken = (string)$_GET['download'];
    $decodedPath = base64_decode($downloadToken, true);

    if ($decodedPath === false || $decodedPath === '') {
        http_response_code(400);
        exit('无效的下载参数。');
    }

    $realFile = realpath($decodedPath);

    if (
        $realFile === false ||
        !is_file($realFile) ||
        strpos($realFile, $realScanBaseDir) !== 0 ||
        !preg_match('/\.apk$/i', $realFile)
    ) {
        http_response_code(404);
        exit('文件不存在或不允许下载。');
    }

    $fileName = basename($realFile);
    $fileSize = filesize($realFile);

    if ($fileSize === false) {
        http_response_code(500);
        exit('无法读取文件大小。');
    }

    while (ob_get_level() > 0) {
        ob_end_clean();
    }

    header('Content-Description: File Transfer');
    header('Content-Type: application/vnd.android.package-archive');
    header('Content-Disposition: attachment; filename="' . rawurlencode($fileName) . '"; filename*=UTF-8\'\'' . rawurlencode($fileName));
    header('Content-Transfer-Encoding: binary');
    header('Content-Length: ' . $fileSize);
    header('Cache-Control: private, no-store, no-cache, must-revalidate');
    header('Pragma: public');
    header('Expires: 0');

    $fp = fopen($realFile, 'rb');
    if ($fp === false) {
        http_response_code(500);
        exit('文件打开失败。');
    }

    while (!feof($fp)) {
        echo fread($fp, 8192);
        flush();
    }

    fclose($fp);
    exit;
}

/* =========================
 * 页面数据准备
 * ========================= */
$tree = buildApkTree($realScanBaseDir);

$dirCount = 0;
$fileCount = 0;
collectStats($tree, $dirCount, $fileCount);

$rootUrlPath = absolutePathToUrlPath($realScanBaseDir, $realWebRoot);
$currentTime = date('Y-m-d H:i:s');
?>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?= e($pageTitle) ?></title>
    <style>
        :root{
            --bg: #0b1020;
            --panel: rgba(255,255,255,0.08);
            --panel-2: rgba(255,255,255,0.05);
            --border: rgba(255,255,255,0.10);
            --text: #eef2ff;
            --muted: #a9b4d0;
            --accent: #7c9cff;
            --accent-2: #5eead4;
            --success: #22c55e;
            --shadow: 0 20px 60px rgba(0,0,0,0.35);
            --radius-xl: 24px;
            --radius-lg: 18px;
            --radius-md: 14px;
            --radius-sm: 10px;
        }

        * { box-sizing: border-box; }

        html, body {
            margin: 0;
            padding: 0;
            font-family: -apple-system, BlinkMacSystemFont, "SF Pro Display", "Segoe UI",
                         "PingFang SC", "Hiragino Sans GB", "Microsoft YaHei", sans-serif;
            color: var(--text);
            background:
                radial-gradient(circle at top left, rgba(124,156,255,0.22), transparent 30%),
                radial-gradient(circle at top right, rgba(94,234,212,0.16), transparent 28%),
                linear-gradient(180deg, #0a0f1f 0%, #0f172a 100%);
            min-height: 100vh;
        }

        a {
            color: inherit;
            text-decoration: none;
        }

        .page {
            max-width: 1240px;
            margin: 0 auto;
            padding: 40px 20px 60px;
        }

        .hero {
            position: relative;
            overflow: hidden;
            border: 1px solid var(--border);
            background: linear-gradient(135deg, rgba(255,255,255,0.09), rgba(255,255,255,0.04));
            backdrop-filter: blur(18px);
            -webkit-backdrop-filter: blur(18px);
            border-radius: 30px;
            padding: 36px 30px;
            box-shadow: var(--shadow);
        }

        .hero::after {
            content: "";
            position: absolute;
            inset: auto -40px -60px auto;
            width: 280px;
            height: 280px;
            background: radial-gradient(circle, rgba(124,156,255,0.25), transparent 65%);
            pointer-events: none;
        }

        .hero-top {
            display: flex;
            align-items: flex-start;
            justify-content: space-between;
            gap: 24px;
            flex-wrap: wrap;
        }

        .eyebrow {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            padding: 8px 12px;
            border-radius: 999px;
            background: rgba(255,255,255,0.08);
            color: var(--muted);
            font-size: 13px;
            border: 1px solid rgba(255,255,255,0.08);
            margin-bottom: 18px;
        }

        .hero h1 {
            margin: 0 0 12px;
            font-size: clamp(30px, 4vw, 52px);
            line-height: 1.08;
            letter-spacing: -0.02em;
            font-weight: 800;
        }

        .hero p {
            margin: 0;
            color: var(--muted);
            line-height: 1.8;
            font-size: 15px;
            max-width: 860px;
        }

        .hero-actions {
            display: flex;
            gap: 12px;
            flex-wrap: wrap;
            margin-top: 22px;
        }

        .btn {
            display: inline-flex;
            align-items: center;
            gap: 10px;
            padding: 12px 16px;
            border-radius: 14px;
            font-weight: 600;
            font-size: 14px;
            border: 1px solid var(--border);
            transition: all .22s ease;
        }

        .btn-primary {
            background: linear-gradient(135deg, var(--accent), #5b7fff);
            color: white;
            box-shadow: 0 12px 24px rgba(92, 124, 255, 0.28);
        }

        .btn-primary:hover {
            transform: translateY(-1px);
            box-shadow: 0 16px 30px rgba(92, 124, 255, 0.34);
        }

        .btn-secondary {
            background: rgba(255,255,255,0.06);
            color: var(--text);
        }

        .btn-secondary:hover {
            background: rgba(255,255,255,0.10);
        }

        .cards {
            display: grid;
            grid-template-columns: repeat(4, minmax(0, 1fr));
            gap: 16px;
            margin-top: 24px;
        }

        .card {
            border: 1px solid var(--border);
            background: var(--panel);
            border-radius: var(--radius-lg);
            padding: 18px;
            backdrop-filter: blur(12px);
            -webkit-backdrop-filter: blur(12px);
        }

        .card-label {
            color: var(--muted);
            font-size: 13px;
            margin-bottom: 10px;
        }

        .card-value {
            font-size: 24px;
            font-weight: 800;
            letter-spacing: -0.02em;
        }

        .card-sub {
            color: var(--muted);
            font-size: 12px;
            margin-top: 6px;
            word-break: break-all;
        }

        .main-panel {
            margin-top: 26px;
            border: 1px solid var(--border);
            background: linear-gradient(180deg, rgba(255,255,255,0.06), rgba(255,255,255,0.04));
            border-radius: 28px;
            box-shadow: var(--shadow);
            overflow: hidden;
        }

        .panel-head {
            padding: 22px 24px;
            border-bottom: 1px solid var(--border);
            background: rgba(255,255,255,0.04);
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 18px;
            flex-wrap: wrap;
        }

        .panel-head h2 {
            margin: 0;
            font-size: 20px;
            font-weight: 750;
            letter-spacing: -0.02em;
        }

        .panel-head .muted {
            color: var(--muted);
            font-size: 14px;
        }

        .tree-wrap {
            padding: 18px;
        }

        .tree {
            list-style: none;
            margin: 0;
            padding: 0;
        }

        .tree-children {
            list-style: none;
            margin: 8px 0 0 0;
            padding: 0 0 0 22px;
            border-left: 1px dashed rgba(255,255,255,0.10);
        }

        .tree-item {
            margin: 8px 0;
        }

        .node-row {
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 16px;
            padding: 14px 16px;
            border: 1px solid transparent;
            border-radius: 16px;
            background: rgba(255,255,255,0.03);
            transition: all .18s ease;
        }

        .node-row:hover {
            background: rgba(255,255,255,0.06);
            border-color: rgba(255,255,255,0.08);
        }

        .dir-row {
            cursor: pointer;
            user-select: none;
        }

        .node-left {
            display: inline-flex;
            align-items: center;
            gap: 10px;
            min-width: 0;
        }

        .caret {
            width: 16px;
            display: inline-block;
            color: var(--muted);
            transition: transform .18s ease;
        }

        .dir-item:not(.open) > .dir-row .caret {
            transform: rotate(-90deg);
        }

        .icon {
            width: 24px;
            text-align: center;
            flex: 0 0 auto;
        }

        .dir-name, .file-link {
            font-size: 15px;
            font-weight: 600;
            line-height: 1.5;
            word-break: break-all;
        }

        .file-link {
            color: #ffffff;
            transition: color .16s ease, opacity .16s ease;
        }

        .file-link:hover {
            color: var(--accent-2);
        }

        .meta {
            display: inline-flex;
            align-items: center;
            gap: 12px;
            flex-wrap: wrap;
            justify-content: flex-end;
            color: var(--muted);
            font-size: 13px;
        }

        .badge {
            padding: 5px 10px;
            border-radius: 999px;
            font-size: 12px;
            font-weight: 700;
            letter-spacing: .04em;
            color: #0b1220;
            background: linear-gradient(135deg, #8ff3d4, #5eead4);
        }

        .count {
            padding: 6px 10px;
            border-radius: 999px;
            background: rgba(124,156,255,0.12);
            border: 1px solid rgba(124,156,255,0.18);
            color: #c8d6ff;
            font-weight: 600;
        }

        .file-submeta {
            margin: 8px 0 0 40px;
            color: var(--muted);
            font-size: 12px;
            line-height: 1.7;
            word-break: break-all;
        }

        .submeta-label {
            color: #d7deef;
        }

        code {
            font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;
            background: rgba(255,255,255,0.06);
            border: 1px solid rgba(255,255,255,0.08);
            padding: 2px 7px;
            border-radius: 8px;
            color: #d7e2ff;
        }

        .empty {
            padding: 40px 24px;
            text-align: center;
            color: var(--muted);
            font-size: 15px;
        }

        .footer-note {
            text-align: center;
            color: var(--muted);
            font-size: 13px;
            margin-top: 22px;
        }

        .dir-item:not(.open) > .tree-children {
            display: none;
        }

        @media (max-width: 980px) {
            .cards {
                grid-template-columns: repeat(2, minmax(0, 1fr));
            }

            .node-row {
                align-items: flex-start;
                flex-direction: column;
            }

            .meta {
                justify-content: flex-start;
            }
        }

        @media (max-width: 640px) {
            .page {
                padding: 18px 12px 40px;
            }

            .hero {
                padding: 22px 18px;
                border-radius: 24px;
            }

            .main-panel {
                border-radius: 22px;
            }

            .panel-head {
                padding: 18px;
            }

            .tree-wrap {
                padding: 12px;
            }

            .cards {
                grid-template-columns: 1fr;
            }

            .file-submeta {
                margin-left: 10px;
            }
        }
    </style>
</head>
<body>
<div class="page">
    <section class="hero">
        <div class="hero-top">
            <div>
                <div class="eyebrow">APK Distribution · Clean Tree View · Direct Download</div>
                <h1><?= e($pageTitle) ?></h1>
                <p>
                    浏览并下载 <code><?= e($rootUrlPath) ?></code> 下的 APK 文件。
                    页面会自动按目录树结构展示所有子目录中的 APK，并通过 PHP 安全校验后触发下载。
                </p>

                <div class="hero-actions">
                    <a class="btn btn-primary" href="#tree-panel">查看文件树</a>
                    <a class="btn btn-secondary" href="https://<?= e($domain) ?>" target="_blank" rel="noopener noreferrer">
                        打开站点首页
                    </a>
                </div>
            </div>
        </div>

        <div class="cards">
            <div class="card">
                <div class="card-label">扫描根目录</div>
                <div class="card-value"><?= e(basename($realScanBaseDir)) ?></div>
                <div class="card-sub"><?= e($realScanBaseDir) ?></div>
            </div>

            <div class="card">
                <div class="card-label">目录数量</div>
                <div class="card-value"><?= (int)$dirCount ?></div>
                <div class="card-sub">仅统计保留在目录树中的有效目录分支</div>
            </div>

            <div class="card">
                <div class="card-label">APK 文件数量</div>
                <div class="card-value"><?= (int)$fileCount ?></div>
                <div class="card-sub">仅统计 .apk 文件</div>
            </div>

            <div class="card">
                <div class="card-label">页面生成时间</div>
                <div class="card-value" style="font-size:18px;"><?= e($currentTime) ?></div>
                <div class="card-sub">域名：<?= e($domain) ?></div>
            </div>
        </div>
    </section>

    <section id="tree-panel" class="main-panel">
        <div class="panel-head">
            <div>
                <h2>APK 目录树</h2>
                <div class="muted">点击文件名即可下载，点击文件夹行可展开或折叠子目录。</div>
            </div>
            <div class="muted">
                基础路径：<code><?= e($rootUrlPath) ?></code>
            </div>
        </div>

        <div class="tree-wrap">
            <?php if ($tree['apk_count'] > 0): ?>
                <ul class="tree">
                    <?= renderTree($tree, $realWebRoot) ?>
                </ul>
            <?php else: ?>
                <div class="empty">
                    当前目录及其子目录下未发现 APK 文件。
                </div>
            <?php endif; ?>
        </div>
    </section>

    <div class="footer-note">
        Designed with a clean, premium-inspired visual style. Built for direct APK discovery and download.
    </div>
</div>

<script>
    function toggleFolder(el) {
        const item = el.parentElement;
        if (!item.classList.contains('dir-item')) return;
        item.classList.toggle('open');
    }
</script>
</body>
</html>
