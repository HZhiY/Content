uFEFF# -*- coding: utf-8-bom -*-
$src = "c:\Users\27649\Documents\myproject\Content\巴基斯坦如何把世界变成自己的资源\01_不是夹缝求生，而是管理不对称\06_修订与发布\修订稿 v1.md"
$content = Get-Content -Raw -Encoding UTF8 $src

$sections = @(
    @{name="引言"; h2=16; start=17; end=22},
    @{name="一 快不了了 4 个核心时刻"; h2=26; start=27; end=32},
    @{name="二 分工联盟 谁在替巴方谈判"; h2=36; start=37; end=48},
    @{name="三 中国 战略背书与基础设施"; h2=52; start=53; end=68},
    @{name="四 海湾 现金、存款与能源赊账"; h2=72; start=73; end=84},
    @{name="五 美国 援助与合法性的阀门"; h2=88; start=89; end=100},
    @{name="六 换生存易 换转型难"; h2=106; start=107; end=114},
    @{name="结尾"; h2=118; start=119; end=122}
)

$lines = $content -split "`n"
Write-Host ("总行数: " + $lines.Length)
Write-Host ""

function Count-Hanzi($text) {
    $n = 0
    foreach ($ch in $text.ToCharArray()) {
        $code = [int][char]$ch
        if ($code -ge 0x4e00 -and $code -le 0x9fff) { $n = $n + 1 }
    }
    return $n
}

function Count-Punct($text) {
    $n = 0
    foreach ($ch in $text.ToCharArray()) {
        $code = [int][char]$ch
        if ($code -ge 0x3000 -and $code -le 0x303f) { $n = $n + 1 }
        if ($code -ge 0xff00 -and $code -le 0xffef) { $n = $n + 1 }
    }
    return $n
}

function Count-Printable($text) {
    $n = 0
    foreach ($ch in $text.ToCharArray()) {
        $code = [int][char]$ch
        if ($code -ge 0x4e00 -and $code -le 0x9fff) { $n = $n + 1; continue }
        if ($code -ge 0x3000 -and $code -le 0x303f) { $n = $n + 1; continue }
        if ($code -ge 0xff00 -and $code -le 0xffef) { $n = $n + 1; continue }
    }
    return $n
}

$totalPrintable = 0
$totalHanzi = 0
$totalPunct = 0
$totalParagraphs = 0
$totalOver6 = 0
$totalOver4 = 0
$allParagraphs = @()

foreach ($s in $sections) {
    $sectionText = ""
    for ($i = $s.start - 1; $i -le $s.end - 1; $i++) {
        $line = $lines[$i]
        if ($i -eq $s.h2 - 1) { continue }
        $sectionText = $sectionText + $line + "`n"
    }
    $sectionText = $sectionText.TrimEnd("`n")
    $p = Count-Printable $sectionText
    $h = Count-Hanzi $sectionText
    $pu = Count-Punct $sectionText
    $totalPrintable = $totalPrintable + $p
    $totalHanzi = $totalHanzi + $h
    $totalPunct = $totalPunct + $pu
    $msg = "[" + $s.name + "] 汉字=" + $h + " 标点=" + $pu + " 汉字+标点=" + $p
    Write-Host $msg

    $paras = $sectionText -split "`n`n" | Where-Object { $_.Trim().Length -gt 0 }
    $totalParagraphs = $totalParagraphs + $paras.Count
    foreach ($para in $paras) {
        $lineCount = ($para -split "`n").Count
        $paraHanzi = Count-Hanzi $para
        $paraPrint = Count-Printable $para
        $firstChars = ($para -replace "`n", " ").Substring(0, [Math]::Min(40, $para.Length))
        $entry = New-Object PSObject -Property @{
            Section = $s.name
            Lines = $lineCount
            Hanzi = $paraHanzi
            Print = $paraPrint
            First = $firstChars
        }
        $allParagraphs += $entry
        if ($lineCount -gt 6) { $totalOver6 = $totalOver6 + 1 }
        if ($lineCount -gt 4) { $totalOver4 = $totalOver4 + 1 }
    }
}

Write-Host ""
Write-Host "================ 全文合计 ================"
$msg1 = "汉字=" + $totalHanzi + " 标点=" + $totalPunct + " 汉字+标点=" + $totalPrintable
Write-Host $msg1
$msg2 = "段落总数=" + $totalParagraphs + " 超4行=" + $totalOver4 + " 超6行=" + $totalOver6
Write-Host $msg2
Write-Host "=========================================="

Write-Host ""
Write-Host "================ 段落明细 ================"
$currentSec = ""
foreach ($p in $allParagraphs) {
    if ($p.Section -ne $currentSec) {
        Write-Host ""
        Write-Host ("[" + $p.Section + "]")
        $currentSec = $p.Section
    }
    $flag = ""
    if ($p.Lines -gt 6) { $flag = "  ##超6行" }
    elseif ($p.Lines -gt 4) { $flag = "  #超4行" }
    $msg = "  " + $p.Lines + "行/" + $p.Hanzi + "字" + $flag + " :: " + $p.First
    Write-Host $msg
}

Write-Host ""
Write-Host "================ 关键短句扫描 ================"
$phrases = @(
    "不是选边", "同时管理", "三组不对称依赖", "三组结构性约束", "兑换术",
    "换生存", "难换转型", "结构性需求", "不断被再生产", "分轴经营",
    "综合议价包", "分清", "前提", "三口径并列", "5 个证据", "5 个工具",
    "5 证", "五个证据", "四个证据", "4 证", "三轴",
    "扣 3 亿不是惩罚", "不是新钱", "既得利益网络", "综合议价"
)
foreach ($ph in $phrases) {
    $c = ([regex]::Matches($content, [regex]::Escape($ph))).Count
    Write-Host ("  '" + $ph + "' : " + $c)
}

Write-Host ""
Write-Host "================ 4证/5证 出场关键词 ================"
$keywords = @(
    "SIFC", "特别投资促进委员会", "CPEC Authority", "中巴经济走廊管理局",
    "Asim Bajwa", "退役中将", "Asim Munir", "Rubio", "陆军参谋长",
    "国际货币基金组织", "IMF", "SBA", "EFF",
    "部分执行", "反复延期", "执行偏差",
    "16.5 亿", "43.55 亿", "60 亿合同", "财政部口径", "DAWN",
    "展期", "续作", "30 亿", "延期支付",
    "SBP", "30.9 亿", "9 年低点", "150-160 亿", "UAE 偿还",
    "FATF", "灰名单", "34 项行动"
)
foreach ($kw in $keywords) {
    $c = ([regex]::Matches($content, [regex]::Escape($kw))).Count
    Write-Host ("  '" + $kw + "' : " + $c)
}
