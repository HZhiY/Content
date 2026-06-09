$ErrorActionPreference = "Stop"
$base = "C:\Users\27649\Documents\myproject\Content"
$kanban = [string][char]0x770B + [string][char]0x677F
$inputFile = Join-Path $base ("_" + $kanban + "\diyuan_input.txt")
$outputFile = Join-Path $base ("_" + $kanban + "\benchmark_diyuan_output.md")
$scrapeDate = "2026-06-09"

$readMarker = [string][char]0x9605 + [string][char]0x8BFB
$commentMarker = [string][char]0x8BC4 + [string][char]0x8BBA
$wan = [char]0x4E07

function Parse-StatsLine($nxt) {
    $idx = $nxt.IndexOf($readMarker)
    if ($idx -lt 1) { return $null }
    $reads = $nxt.Substring(0, $idx)
    $rest = $nxt.Substring($idx + $readMarker.Length)
    $comments = 0
    $date = $rest
    $cm = [regex]::Match($rest, '^(\d+)' + [regex]::Escape($commentMarker) + '(.+)$')
    if ($cm.Success) {
        $comments = [int]$cm.Groups[1].Value
        $date = $cm.Groups[2].Value.Trim()
    }
    return [PSCustomObject]@{ r = $reads; c = $comments; d = $date }
}

$lines = @([System.IO.File]::ReadAllLines($inputFile, [System.Text.Encoding]::UTF8) | ForEach-Object { $_.Trim() } | Where-Object { $_ })
$articles = @()
for ($i = 0; $i -lt $lines.Count - 1; $i += 2) {
    $parsed = Parse-StatsLine $lines[$i + 1]
    if (-not $parsed) { continue }
    $articles += [PSCustomObject]@{
        t = $lines[$i]
        r = $parsed.r
        c = $parsed.c
        d = $parsed.d
    }
}

if ($articles.Count -eq 0) { throw "No articles parsed from $($lines.Count) lines" }

function Parse-Reads($s) {
    if ($s.EndsWith($wan)) {
        $num = $s.Substring(0, $s.Length - 1)
        return [int]([double]$num * 10000)
    }
    return [int]$s
}

function Normalize-Date($d) {
    $pat = '^(\d{4})' + [regex]::Escape([string][char]0x5E74) + '(\d{1,2})' + [regex]::Escape([string][char]0x6708) + '(\d{1,2})' + [regex]::Escape([string][char]0x65E5) + '$'
    if ($d -match $pat) {
        return "{0}-{1:D2}-{2:D2}" -f $Matches[1], [int]$Matches[2], [int]$Matches[3]
    }
    if ($d -match '^\d{2}-\d{2}$') { return "2026-$d" }
    $hourSuffix = [string][char]0x5C0F + [string][char]0x65F6 + [string][char]0x524D
    if ($d -match "^(\d+)$hourSuffix$") {
        $h = [int]$Matches[1]
        if ($h -ge 20) { return "2026-06-08 ($d)" }
        return "$scrapeDate ($d)"
    }
    $yesterday = [string][char]0x6628 + [string][char]0x5929
    if ($d.StartsWith($yesterday)) {
        $rest = $d.Substring($yesterday.Length).Trim()
        if ($rest) { return "2026-06-08 $rest ($d)" }
        return "2026-06-08 ($d)"
    }
    $dayBefore = [string][char]0x524D + [string][char]0x5929
    if ($d.StartsWith($dayBefore)) {
        $rest = $d.Substring($dayBefore.Length).Trim()
        if ($rest) { return "2026-06-07 $rest ($d)" }
        return "2026-06-07 ($d)"
    }
    $daysAgoSuffix = [string][char]0x5929 + [string][char]0x524D
    if ($d -match "^(\d+)$daysAgoSuffix$") {
        $days = [int]$Matches[1]
        $dt = ([datetime]$scrapeDate).AddDays(-$days).ToString('yyyy-MM-dd')
        return "$dt ($d)"
    }
    return $d
}

$nums = @($articles | ForEach-Object { Parse-Reads $_.r })
$commentSum = ($articles | Measure-Object -Property c -Sum).Sum
$sorted = $nums | Sort-Object
$median = $sorted[[int]($sorted.Count / 2)]
$sum = ($nums | Measure-Object -Sum).Sum
$maxR = ($nums | Measure-Object -Maximum).Maximum
$minR = ($nums | Measure-Object -Minimum).Minimum
$ge1w = ($nums | Where-Object { $_ -ge 10000 }).Count
$ge5w = ($nums | Where-Object { $_ -ge 50000 }).Count
$ge10w = ($nums | Where-Object { $_ -ge 100000 }).Count

$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine("# benchmark: diyuan")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("> scrape: $scrapeDate")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("---")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("## account")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("| field | value |")
[void]$sb.AppendLine("|-------|-------|")
[void]$sb.AppendLine("| articles | $($articles.Count) |")
[void]$sb.AppendLine("| reads_sum | $sum |")
[void]$sb.AppendLine("| reads_max | $maxR |")
[void]$sb.AppendLine("| reads_median | $median |")
[void]$sb.AppendLine("| comments_sum | $commentSum |")
[void]$sb.AppendLine("| ge_10k | $ge1w |")
[void]$sb.AppendLine("| ge_50k | $ge5w |")
[void]$sb.AppendLine("| ge_100k | $ge10w |")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("---")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("## articles")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("| no | title | reads | reads_n | comments | date |")
[void]$sb.AppendLine("|----|-------|-------|---------|----------|------|")

$idx = 1
foreach ($a in $articles) {
    $rn = Parse-Reads $a.r
    $dn = Normalize-Date $a.d
    [void]$sb.AppendLine("| $idx | $($a.t) | $($a.r) | $rn | $($a.c) | $dn |")
    $idx++
}

$content = $sb.ToString()
[System.IO.File]::WriteAllText($outputFile, $content, [System.Text.UTF8Encoding]::new($false))
Write-Host "OK count=$($articles.Count) sum=$sum max=$maxR ge10k=$ge1w ge50k=$ge5w ge100k=$ge10w"
