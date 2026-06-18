$path = "c:\Users\27649\Documents\myproject\Content\巴基斯坦如何把世界变成自己的资源\01_不是夹缝求生，而是管理不对称\04_草稿\草稿 v1.md"
$content = Get-Content -Path $path -Encoding UTF8
# skip header
$body = @()
$seen = $false
foreach ($l in $content) {
    if (-not $seen -and $l.Trim() -eq "---") { $seen = $true; continue }
    if ($seen) { $body += $l }
}
# sections
$order = @()
$sections = @{}
$cur = $null
$curL = @()
foreach ($l in $body) {
    if ($l -match '^##\s+(.+)$') {
        if ($cur) { $sections[$cur] = $curL; $order += $cur }
        $cur = $Matches[1].Trim()
        $curL = @()
    } else {
        if ($cur -and $l.Trim() -ne "" -and -not $l.StartsWith("#") -and -not $l.StartsWith(">") -and $l.Trim() -ne "---") {
            $curL += $l
        }
    }
}
if ($cur) { $sections[$cur] = $curL; $order += $cur }

$total = 0
Write-Host "===== 字数(含标点、去 metadata)=====" -ForegroundColor Cyan
foreach ($name in $order) {
    $text = -join $sections[$name]
    $n = ($text -replace '\s','').Length
    $total += $n
    Write-Host ("[{0,-30}] {1,5}" -f $name, $n)
}
Write-Host "===== 全文合计: $total =====" -ForegroundColor Cyan

Write-Host ""
Write-Host "===== 段落超 6 行段 =====" -ForegroundColor Cyan
$over6 = 0
foreach ($name in $order) {
    $para = @()
    foreach ($l in $sections[$name]) {
        if ($l.Trim() -eq "") {
            if ($para.Count -gt 6) {
                $over6++
                Write-Host "  [$name] $($para.Count) lines" -ForegroundColor Yellow
            }
            $para = @()
        } else { $para += $l }
    }
    if ($para.Count -gt 6) {
        $over6++
        Write-Host "  [$name] $($para.Count) lines" -ForegroundColor Yellow
    }
}
Write-Host "合计: $over6" -ForegroundColor Cyan

$full = -join ($sections.Values | ForEach-Object {$_})
function Cnt([string]$s) { ([regex]::Matches($full, [regex]::Escape($s))).Count }

Write-Host ""
Write-Host "===== 4证分工联盟 =====" -ForegroundColor Cyan
foreach ($p in @('SIFC','CPEC Authority','Rubio','Asim Munir','Asim Bajwa','IMF','2008','2013','2019','2023','财政部','陆军参谋长')) {
    Write-Host ("  {0,-15}: {1}" -f $p, (Cnt $p))
}

Write-Host ""
Write-Host "===== 5证换生存难换转型 =====" -ForegroundColor Cyan
foreach ($p in @('16.5','43.55','60亿','30亿','30.9','9年','灰名单','34 项','移出','结构性','FATF','展期','SBP','DAWN','财政部')) {
    Write-Host ("  {0,-15}: {1}" -f $p, (Cnt $p))
}

Write-Host ""
Write-Host "===== 机制词 =====" -ForegroundColor Cyan
foreach ($p in @('兑换术','三组不对称依赖','三组结构性约束','分工联盟','换生存','换转型','结构性需求','管理不对称','不是选边','综合议价包','分轴经营','结构性产物','地缘租金','外部资源结构','军方定边界','文官做交易','信用阀门','海湾资金','海湾资本','战略背书','合法性包装','再生产','现金流','能源赊账','能源安全阀','信用背书','外债','依赖','对印安全','对阿边境','经济脆弱性','4个时刻','7个时刻','7 个时刻','再看海湾','分清谁拍板','再看')) {
    Write-Host ("  {0,-15}: {1}" -f $p, (Cnt $p))
}
