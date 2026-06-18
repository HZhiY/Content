$path = "c:\Users\27649\Documents\myproject\Content\巴基斯坦如何把世界变成自己的资源\01_不是夹缝求生，而是管理不对称\04_草稿\草稿 v1.md"
$content = Get-Content -Path $path -Encoding UTF8

# skip header metadata
$bodyLines = @()
$foundFirstHR = $false
foreach ($line in $content) {
    if (-not $foundFirstHR -and $line.Trim() -eq "---") {
        $foundFirstHR = $true
        continue
    }
    if ($foundFirstHR) {
        $bodyLines += $line
    }
}

# parse sections
$order = @()
$sections = @{}
$curName = $null
$curLines = @()

foreach ($line in $bodyLines) {
    if ($line -match "^##\s+(.+)$") {
        if ($null -ne $curName) {
            $sections[$curName] = $curLines
            $order += $curName
        }
        $curName = $Matches[1].Trim()
        $curLines = @()
    } else {
        if ($curName -and $line.Trim() -ne "" -and -not $line.StartsWith("#") -and -not $line.StartsWith(">") -and $line.Trim() -ne "---") {
            $curLines += $line
        }
    }
}
if ($null -ne $curName) {
    $sections[$curName] = $curLines
    $order += $curName
}

# count
$total = 0
$totalRows = @()
foreach ($name in $order) {
    $body = -join $sections[$name]
    $n = ($body -replace "\s", "").Length
    $total += $n
    $rows = $sections[$name] | Where-Object { $_.Trim() -ne "" }
    $totalRows += [PSCustomObject]@{ name=$name; chars=$n; lines=$rows.Count }
}

$totalRows | Format-Table -AutoSize
Write-Host "TOTAL (no metadata, no whitespace): $total" -ForegroundColor Cyan

# paragraphs over 6 lines
Write-Host ""
Write-Host "Paragraphs over 6 lines:" -ForegroundColor Cyan
$paraOver6 = 0
foreach ($name in $order) {
    $para = @()
    foreach ($line in $sections[$name]) {
        if ($line.Trim() -eq "") {
            if ($para.Count -gt 6) {
                $paraOver6++
                Write-Host "  [$name] para $($para.Count) lines" -ForegroundColor Yellow
            }
            $para = @()
        } else {
            $para += $line
        }
    }
    if ($para.Count -gt 6) {
        $paraOver6++
        Write-Host "  [$name] para $($para.Count) lines" -ForegroundColor Yellow
    }
}
Write-Host "Total para over 6 lines: $paraOver6" -ForegroundColor Cyan

$fullBody = -join ($sections.Values | ForEach-Object { $_ })

Write-Host ""
Write-Host "=== 4 zheng fen gong lian meng (allocation coalition) ===" -ForegroundColor Cyan
$checks4 = @(
    @("SIFC", "SIFC"),
    @("CPEC Authority", "CPEC Authority"),
    @("Rubio", "Rubio"),
    @("Asim Munir", "Asim Munir"),
    @("Asim Bajwa", "Asim Bajwa"),
    @("IMF times", "IMF"),
    @("2008", "2008"),
    @("2013", "2013"),
    @("2019", "2019"),
    @("2023", "2023"),
    @("财政部口径", "财政部"),
    @("陆军参谋长", "陆军参谋长")
)
foreach ($c in $checks4) {
    $cnt = ([regex]::Matches($fullBody, [regex]::Escape($c[1]))).Count
    Write-Host "  $($c[0]) ($($c[1])): $cnt" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=== 5 zheng huan sheng cun nan ===" -ForegroundColor Cyan
$checks5 = @(
    @("16.5", "16.5"),
    @("43.55", "43.55"),
    @("60 yi hetong", "60亿"),
    @("30 yi", "30亿"),
    @("30.9", "30.9"),
    @("9 nian", "9年"),
    @("huimingdan", "灰名单"),
    @("34 xiang", "34 项"),
    @("yichu", "移出"),
    @("jiexingshi", "结构性"),
    @("FATF", "FATF"),
    @("zhanqi", "展期"),
    @("SBP", "SBP"),
    @("dawn/dawn", "DAWN"),
    @("caizhengbu", "财政部")
)
foreach ($c in $checks5) {
    $cnt = ([regex]::Matches($fullBody, [regex]::Escape($c[1]))).Count
    Write-Host "  $($c[0]) ($($c[1])): $cnt" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=== keywords ===" -ForegroundColor Cyan
$phrases = @(
    "兑换术", "三组不对称依赖", "三组结构性约束", "分工联盟",
    "换生存", "换转型", "结构性需求", "管理不对称", "不是选边",
    "综合议价包", "分轴经营", "结构性产物", "地缘租金", "外部资源结构",
    "军方定边界", "文官做交易", "信用阀门", "海湾资金", "海湾资本",
    "战略背书", "合法性包装", "再生产",
    "现金流", "能源赊账", "能源安全阀", "阀门", "信用背书",
    "外债", "依赖", "对印安全", "对阿边境", "经济脆弱性"
)
foreach ($pp in $phrases) {
    $cnt = ([regex]::Matches($fullBody, [regex]::Escape($pp))).Count
    Write-Host "  ${pp}: $cnt" -ForegroundColor Yellow
}
