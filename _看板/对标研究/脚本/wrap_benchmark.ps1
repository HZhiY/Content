$dir = Split-Path -Parent $MyInvocation.MyCommand.Path
$src = Join-Path $dir 'benchmark_output.md'
$dst = Join-Path $dir 'benchmark_data_final.md'
$lines = Get-Content -LiteralPath $src -Encoding UTF8
$table = $lines[4..223]
$table[0] = '| 序号 | 标题 | 阅读 | 阅读(数值) | 评论 | 日期 |'
$table[1] = '|------|------|------|------------|------|------|'
$stats = $lines[226..233]

$header = @(
'# 对标账号数据：历史侦查处'
''
'> 数据来源：头条账号主页列表'
'> 抓取时间：2026-06-09'
'> 生成脚本：gen_benchmark_data.py + gen_from_py.ps1'
''
'---'
''
'## 账号信息'
''
'| 字段 | 值 |'
'|------|------|'
'| 账号名 | 历史侦查处 |'
'| 获赞 | 153.4 万 |'
'| 粉丝 | 19.7 万 |'
'| 关注 | 212 |'
'| 认证 | 作家 |'
'| 公众号 | 青史凭谁说 |'
'| 文章数 | 220 |'
''
'---'
''
'## 字段说明'
''
'| 字段 | 说明 |'
'|------|------|'
'| 序号 | 按用户提供的原始顺序 |'
'| 标题 | 头条原文标题 |'
'| 阅读 | 原数据阅读量（保留原文，如 2.7万） |'
'| 阅读(数值) | 换算后的整数，便于排序分析 |'
'| 评论 | 评论数 |'
'| 日期 | 发布日期 |'
''
'> 备注：主页列表未提供点赞、收藏、展现量、涨粉等字段。'
''
'---'
''
'## 文章列表'
''
)

$footer = @(
''
'---'
''
'## 统计摘要'
''
"- 总篇数：$($stats[0] -replace 'count: ','')"
"- 阅读合计：$($stats[1] -replace 'reads_sum: ','')"
"- 阅读最高：$($stats[2] -replace 'reads_max: ','')"
"- 阅读最低：$($stats[3] -replace 'reads_min: ','')"
"- 阅读中位数：$($stats[4] -replace 'reads_median: ','')"
"- 评论合计：$($stats[5] -replace 'comments_sum: ','')"
"- 阅读 >=1万：$($stats[6] -replace 'reads_ge_10k: ','') 篇"
"- 阅读 >=5万：$($stats[7] -replace 'reads_ge_50k: ','') 篇"
'')

$all = $header + $table + $footer
[System.IO.File]::WriteAllLines($dst, $all, [System.Text.UTF8Encoding]::new($false))
Write-Host "Wrote $dst"
