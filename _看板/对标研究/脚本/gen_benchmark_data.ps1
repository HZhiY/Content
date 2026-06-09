# Generate benchmark markdown from JSON chunk files
$ErrorActionPreference = "Stop"
$dir = $PSScriptRoot
$chunks = Get-ChildItem -Path $dir -Filter "benchmark_chunk_*.json" | Sort-Object Name
$articles = @()
foreach ($f in $chunks) {
    $articles += Get-Content -LiteralPath $f.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
}

$relativeDates = @{
    "3天前" = "2026-06-06"
    "4天前" = "2026-06-05"
    "5天前" = "2026-06-04"
    "6天前" = "2026-06-03"
    "7天前" = "2026-06-02"
    "8天前" = "2026-06-01"
}

function Parse-Reads($s) {
    if ($s -match "万$") {
        return [int]([double]($s -replace "万$","") * 10000)
    }
    return [int]$s
}

function Normalize-Date($d) {
    if ($relativeDates.ContainsKey($d)) {
        return "$($relativeDates[$d])（$d）"
    }
    if ($d -match "^(04|05)-") {
        return "2026-$d"
    }
    return $d
}

$out = Join-Path $dir "对标数据_2026-06-09_历史侦查处.md"
$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine("# 对标账号数据：历史侦查处")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("> 数据来源：头条账号主页列表")
[void]$sb.AppendLine("> 抓取时间：2026-06-09")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("---")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("## 账号信息")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("| 字段 | 值 |")
[void]$sb.AppendLine("|------|------|")
[void]$sb.AppendLine("| 账号名 | 历史侦查处 |")
[void]$sb.AppendLine("| 获赞 | 153.4 万 |")
[void]$sb.AppendLine("| 粉丝 | 19.7 万 |")
[void]$sb.AppendLine("| 关注 | 212 |")
[void]$sb.AppendLine("| 认证 | 作家 |")
[void]$sb.AppendLine("| 公众号 | 青史凭谁说 |")
[void]$sb.AppendLine("| 文章数 | $($articles.Count) |")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("---")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("## 字段说明")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("| 字段 | 说明 |")
[void]$sb.AppendLine("|------|------|")
[void]$sb.AppendLine("| 序号 | 按用户提供的原始顺序 |")
[void]$sb.AppendLine("| 标题 | 头条原文标题 |")
[void]$sb.AppendLine("| 阅读 | 原数据阅读量 |")
[void]$sb.AppendLine("| 阅读(数值) | 换算整数，便于排序 |")
[void]$sb.AppendLine("| 评论 | 评论数 |")
[void]$sb.AppendLine("| 日期 | 发布日期 |")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("> 备注：主页列表未提供点赞、收藏、展现量、涨粉等字段。")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("---")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("## 文章列表")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("| 序号 | 标题 | 阅读 | 阅读(数值) | 评论 | 日期 |")
[void]$sb.AppendLine("|------|------|------|------------|------|------|")

$nums = @()
$commentSum = 0
$i = 0
foreach ($a in $articles) {
    $i++
    $title = ($a.t -replace '\|','\\|')
    $rn = Parse-Reads $a.r
    $nums += $rn
    $commentSum += [int]$a.c
    $dn = Normalize-Date $a.d
    [void]$sb.AppendLine("| $i | $title | $($a.r) | $rn | $($a.c) | $dn |")
}

$sorted = $nums | Sort-Object
$median = $sorted[[int]($sorted.Count/2)]
[void]$sb.AppendLine("")
[void]$sb.AppendLine("---")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("## 统计摘要")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("- 总篇数：$($articles.Count)")
[void]$sb.AppendLine("- 阅读合计：$($nums | Measure-Object -Sum | Select-Object -ExpandProperty Sum)")
[void]$sb.AppendLine("- 阅读最高：$($nums | Measure-Object -Maximum | Select-Object -ExpandProperty Maximum)")
[void]$sb.AppendLine("- 阅读最低：$($nums | Measure-Object -Minimum | Select-Object -ExpandProperty Minimum)")
[void]$sb.AppendLine("- 阅读中位数：$median")
[void]$sb.AppendLine("- 评论合计：$commentSum")
[void]$sb.AppendLine("- 阅读 ≥1万：$(($nums | Where-Object { $_ -ge 10000 }).Count) 篇")
[void]$sb.AppendLine("- 阅读 ≥5万：$(($nums | Where-Object { $_ -ge 50000 }).Count) 篇")
[void]$sb.AppendLine("")

[System.IO.File]::WriteAllText($out, $sb.ToString(), [System.Text.UTF8Encoding]::new($false))
Write-Host "Wrote $($articles.Count) articles to $out"
