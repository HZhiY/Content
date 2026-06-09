$ErrorActionPreference = "Stop"
$dir = Split-Path -Parent $MyInvocation.MyCommand.Path
$src = Join-Path $dir "benchmark_lishicui_output.md"
$dst = Join-Path $dir "benchmark_lishicui_final.md"
$lines = Get-Content -LiteralPath $src -Encoding UTF8

$header = @(
"# 对标账号数据：历史崔"
""
"> 数据来源：头条账号主页列表"
"> 抓取时间：2026-06-09"
"> 生成脚本：gen_benchmark_lishicui.py + gen_from_lishicui.ps1"
""
"---"
""
"## 账号信息"
""
"| 字段 | 值 |"
"|------|------|"
"| 账号名 | 历史崔 |"
"| 获赞 | 3.0 万 |"
"| 粉丝 | 23.6 万 |"
"| 关注 | 4 |"
"| 认证 | 头条新锐创作者 |"
"| 简介 | 历史崔，专门介绍历史人物的自媒体 |"
"| 文章数 | 228 |"
""
"---"
""
"## 字段说明"
""
"| 字段 | 说明 |"
"|------|------|"
"| 序号 | 按用户提供的原始顺序 |"
"| 标题 | 头条原文标题 |"
"| 类型 | 图文 / 视频 |"
"| 阅读/播放 | 原数据阅读量或播放量 |"
"| 阅读(数值) | 换算整数，便于排序 |"
"| 评论 | 评论数 |"
"| 日期 | 发布日期 |"
""
"> 备注：主页列表未提供点赞、收藏、展现量、涨粉等字段。"
""
"---"
""
"## 文章列表"
""
"| 序号 | 标题 | 类型 | 阅读/播放 | 阅读(数值) | 评论 | 日期 |"
"|------|------|------|-----------|------------|------|------|"
)

$table = @()
foreach ($line in $lines) {
    if ($line -notmatch '^\| \d+ \|') { continue }
    $p = ($line -split '\|') | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }
    if ($p.Count -lt 7) { continue }
    $typ = if ($p[1] -eq 'video') { '视频' } else { '图文' }
    $table += "| $($p[0]) | $($p[6]) | $typ | $($p[2]) | $($p[3]) | $($p[4]) | $($p[5]) |"
}

$stats = $lines | Where-Object { $_ -match '^- (count|reads_|comments_|videos):' }
$footer = @(
""
"---"
""
"## 统计摘要"
""
"- 总篇数：228"
"- 阅读/播放合计：382,845"
"- 阅读/播放最高：36,000"
"- 阅读/播放最低：54"
"- 阅读/播放中位数：703"
"- 评论合计：1,615"
"- 阅读 ≥1万：5 篇"
"- 阅读 ≥5万：0 篇"
"- 视频数：1 篇"
""
)

$all = $header + $table + $footer
[System.IO.File]::WriteAllLines($dst, $all, [System.Text.UTF8Encoding]::new($false))
Write-Host "Wrote $dst"
