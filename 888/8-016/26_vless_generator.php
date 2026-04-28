<?php
// 初始化变量
$address = $_POST['address'] ?? '';
$id = $_POST['id'] ?? '';
$publicKey = $_POST['publicKey'] ?? '';
$shortId = $_POST['shortId'] ?? '';
$remarks = $_POST['remarks'] ?? '';

$result = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    // 去除首尾空格
    $address = trim($address);
    $id = trim($id);
    $publicKey = trim($publicKey);
    $shortId = trim($shortId);
    $remarks = trim($remarks);

    // 对备注进行 URL 编码，避免中文或特殊字符导致链接异常
    $encodedRemarks = rawurlencode($remarks);

    // 生成 VLESS 链接
    $result = "vless://{$id}@{$address}:443?encryption=none&security=reality&type=tcp&sni=www.cloudflare.com&fp=chrome&pbk={$publicKey}&sid={$shortId}&spx=%2F&flow=xtls-rprx-vision#{$encodedRemarks}";
}
?>

<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <title>VLESS REALITY 链接生成器</title>
    <style>
        * {
            box-sizing: border-box;
        }

        body {
            margin: 0;
            min-height: 100vh;
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", "Microsoft YaHei", Arial, sans-serif;
            background: linear-gradient(135deg, #eef2ff, #f8fafc);
            color: #1f2937;
            display: flex;
            justify-content: center;
            align-items: center;
            padding: 30px;
        }

        .container {
            width: 100%;
            max-width: 760px;
            background: #ffffff;
            border-radius: 18px;
            box-shadow: 0 20px 45px rgba(15, 23, 42, 0.12);
            padding: 34px;
        }

        h1 {
            margin: 0 0 8px;
            text-align: center;
            font-size: 28px;
            color: #111827;
        }

        .subtitle {
            text-align: center;
            color: #6b7280;
            margin-bottom: 30px;
            font-size: 15px;
        }

        .form-group {
            margin-bottom: 18px;
        }

        label {
            display: block;
            margin-bottom: 7px;
            font-weight: 600;
            color: #374151;
        }

        input[type="text"] {
            width: 100%;
            padding: 12px 14px;
            border: 1px solid #d1d5db;
            border-radius: 10px;
            font-size: 15px;
            outline: none;
            transition: all 0.2s ease;
            background: #f9fafb;
        }

        input[type="text"]:focus {
            border-color: #6366f1;
            background: #ffffff;
            box-shadow: 0 0 0 4px rgba(99, 102, 241, 0.12);
        }

        button {
            width: 100%;
            margin-top: 8px;
            padding: 13px 16px;
            background: #4f46e5;
            color: #ffffff;
            border: none;
            border-radius: 12px;
            font-size: 16px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.2s ease;
        }

        button:hover {
            background: #4338ca;
            transform: translateY(-1px);
            box-shadow: 0 8px 18px rgba(79, 70, 229, 0.25);
        }

        .result-box {
            margin-top: 28px;
            padding: 20px;
            background: #f3f4f6;
            border-radius: 14px;
            border: 1px solid #e5e7eb;
        }

        .result-title {
            font-weight: 700;
            margin-bottom: 10px;
            color: #111827;
        }

        textarea {
            width: 100%;
            min-height: 130px;
            resize: vertical;
            padding: 14px;
            border: 1px solid #d1d5db;
            border-radius: 10px;
            font-size: 14px;
            line-height: 1.6;
            background: #ffffff;
            color: #111827;
            word-break: break-all;
        }

        .copy-btn {
            margin-top: 12px;
            background: #059669;
        }

        .copy-btn:hover {
            background: #047857;
        }

        .hint {
            margin-top: 12px;
            font-size: 13px;
            color: #6b7280;
            line-height: 1.6;
        }

        code {
            background: #eef2ff;
            color: #4338ca;
            padding: 2px 5px;
            border-radius: 5px;
        }

        @media (max-width: 600px) {
            .container {
                padding: 24px;
            }

            h1 {
                font-size: 24px;
            }
        }
    </style>
</head>
<body>

<div class="container">
    <h1>VLESS REALITY 链接生成器</h1>
    <div class="subtitle">
        输入 address、id、publicKey、shortId 和 remarks，自动生成 VLESS 分享链接
    </div>

    <form method="post">
        <div class="form-group">
            <label for="address">address，对应 value1</label>
            <input type="text" id="address" name="address"
                   placeholder="例如：example.com 或 1.2.3.4"
                   value="<?php echo htmlspecialchars($address, ENT_QUOTES, 'UTF-8'); ?>" required>
        </div>

        <div class="form-group">
            <label for="id">id，对应 value2</label>
            <input type="text" id="id" name="id"
                   placeholder="例如：UUID"
                   value="<?php echo htmlspecialchars($id, ENT_QUOTES, 'UTF-8'); ?>" required>
        </div>

        <div class="form-group">
            <label for="publicKey">publicKey，对应 value3</label>
            <input type="text" id="publicKey" name="publicKey"
                   placeholder="请输入 REALITY publicKey"
                   value="<?php echo htmlspecialchars($publicKey, ENT_QUOTES, 'UTF-8'); ?>" required>
        </div>

        <div class="form-group">
            <label for="shortId">shortId，对应 value4</label>
            <input type="text" id="shortId" name="shortId"
                   placeholder="请输入 shortId"
                   value="<?php echo htmlspecialchars($shortId, ENT_QUOTES, 'UTF-8'); ?>" required>
        </div>

        <div class="form-group">
            <label for="remarks">remarks，对应 value5</label>
            <input type="text" id="remarks" name="remarks"
                   placeholder="例如：racknerd-us-01"
                   value="<?php echo htmlspecialchars($remarks, ENT_QUOTES, 'UTF-8'); ?>" required>
        </div>

        <button type="submit">生成 VLESS 链接</button>
    </form>

    <?php if (!empty($result)): ?>
        <div class="result-box">
            <div class="result-title">生成结果：</div>

            <textarea id="resultText" readonly><?php echo htmlspecialchars($result, ENT_QUOTES, 'UTF-8'); ?></textarea>

            <button type="button" class="copy-btn" onclick="copyResult()">复制链接</button>

            <div class="hint">
                已将 <code>value1</code> 至 <code>value5</code> 分别替换为你输入的
                <code>address</code>、<code>id</code>、<code>publicKey</code>、<code>shortId</code>、<code>remarks</code>。
            </div>
        </div>
    <?php endif; ?>
</div>

<script>
function copyResult() {
    const textArea = document.getElementById('resultText');
    textArea.select();
    textArea.setSelectionRange(0, 99999);

    navigator.clipboard.writeText(textArea.value).then(function() {
        alert('链接已复制到剪贴板');
    }).catch(function() {
        document.execCommand('copy');
        alert('链接已复制');
    });
}
</script>

</body>
</html>
