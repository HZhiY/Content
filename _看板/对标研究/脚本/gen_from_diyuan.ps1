# ASCII-only parser for diyuan_input.txt
$ErrorActionPreference = "Stop"
$dir = Split-Path -Parent $MyInvocation.MyCommand.Path
$inputFile = Join-Path $dir "diyuan_input.txt"
$final = Join-Path $dir "benchmark_diyuan_output.md"
$finalZh = Join-Path $dir "benchmark_diyuan_output_zh.md"
$scrapeDate = "2026-06-09"

$lines = @(Get-Content -LiteralPath $inputFile -Encoding UTF8 | ForEach-Object { $_.Trim() } | Where-Object { $_ })
$statsRe = [regex]'^([\d.]+(?:\x4e07)?)[\x9605][\x8bfb](?:(\d+)[\x8bc4][\x8bba])?(.+)$'

$articles = @()
for ($i = 0; $i -lt $lines.Count - 1; $i += 2) {
    $title = $lines[$i]
    $nxt = $lines[$i + 1]
    $m = $statsRe.Match($nxt)
    if (-not $m.Success) { continue }
    $articles += [PSCustomObject]@{
        t = $title
        r = $m.Groups[1].Value
        c = if ($m.Groups[2].Success) { [int]$m.Groups[2].Value } else { 0 }
        d = $m.Groups[3].Value.Trim()
    }
}

if ($articles.Count -eq 0) { throw "No articles parsed" }

function Parse-Reads($s) {
    if ($s.EndsWith([char]0x4E07)) {
        $num = $s.Substring(0, $s.Length - 1)
        return [int]([double]$num * 10000)
    }
    return [int]$s
}

function Normalize-Date($d) {
    if ($d -match '^(\d{4})[\x5e74](\d{1,2})[\x6708](\d{1,2})[\x65e5]$') {
        return "{0}-{1:D2}-{2:D2}" -f $Matches[1], [int]$Matches[2], [int]$Matches[3]
    }
    if ($d -match '^\d{2}-\d{2}$') { return "2026-$d" }
    if ($d -match '^(\d+)[\x5c0f][\x65f6][\x524d]$') {
        $h = [int]$Matches[1]
        if ($h -ge 20) { return "2026-06-08 ($d)" }
        return "$scrapeDate ($d)"
    }
    if ($d -match '^[\x6628][\x5929](.*)$') {
        $rest = $Matches[1].Trim()
        if ($rest) { return "2026-06-08 $rest ($d)" }
        return "2026-06-08 ($d)"
    }
    if ($d -match '^[\x524d][\x5929](.*)$') {
        $rest = $Matches[1].Trim()
        if ($rest) { return "2026-06-07 $rest ($d)" }
        return "2026-06-07 ($d)"
    }
    if ($d -match '^(\d+)[\x5929][\x524d]$') {
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
[void]$sb.AppendLine("> script: gen_from_diyuan.ps1")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("---")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("## account")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("| field | value |")
[void]$sb.AppendLine("|-------|-------|")
[void]$sb.AppendLine("| name | diyuan |")
[void]$sb.AppendLine("| likes_w | 979.2 |")
[void]$sb.AppendLine("| fans_w | 169.4 |")
[void]$sb.AppendLine("| follow | 64 |")
[void]$sb.AppendLine("| articles | $($articles.Count) |")
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

[void]$sb.AppendLine("")
[void]$sb.AppendLine("---")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("## stats")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("- count: $($articles.Count)")
[void]$sb.AppendLine("- reads_sum: $sum")
[void]$sb.AppendLine("- reads_max: $maxR")
[void]$sb.AppendLine("- reads_min: $minR")
[void]$sb.AppendLine("- reads_median: $median")
[void]$sb.AppendLine("- comments_sum: $commentSum")
[void]$sb.AppendLine("- ge_10k: $ge1w")
[void]$sb.AppendLine("- ge_50k: $ge5w")
[void]$sb.AppendLine("- ge_100k: $ge10w")
[void]$sb.AppendLine("")

$content = $sb.ToString()
[System.IO.File]::WriteAllText($final, $content, [System.Text.UTF8Encoding]::new($false))
Write-Host "Parsed $($articles.Count) -> $final"
Write-Host "STATS count=$($articles.Count) sum=$sum max=$maxR ge10k=$ge1w ge50k=$ge5w ge100k=$ge10w"
