$script = @'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
$draftPath = $env:DRAFT_PATH
if (Test-Path -LiteralPath $draftPath) {
    $content = Get-Content -LiteralPath $draftPath -Raw -Encoding UTF8
    # 找出 "## 写作执行说明" 之前的内容（正文部分）
    $marker = "## 写作执行说明"
    $idx = $content.IndexOf($marker)
    if ($idx -gt 0) {
        $body = $content.Substring(0, $idx)
    } else {
        $body = $content
    }
    $cn = [regex]::Matches($body, '[\u4e00-\u9fff]').Count
    $en = [regex]::Matches($body, '[A-Za-z]').Count
    Write-Host ("正文部分（不含写作执行说明）中文字符数: {0}" -f $cn)
    Write-Host ("正文部分英文字符数: {0}" -f $en)
    # 找出 "## 引言" 到 "## 引言" 之前的部分 + 看看从 "## 引言" 到 "---" (后面单独的) 的部分
    # 实际正文是：标题、引言、一、二、三、四、结尾、小尾巴、相关文章
    # 不含 "## 写作执行说明" 之后的内容
}
'@
$utf8 = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText("C:\Users\27649\Documents\myproject\Content\scripts\count_body.ps1", $script, $utf8)
Write-Host "Script written"