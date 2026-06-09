# Parse gen_benchmark_data.py and generate markdown
$ErrorActionPreference = "Stop"
$dir = Split-Path -Parent $MyInvocation.MyCommand.Path
$pyFile = Join-Path $dir "gen_benchmark_data.py"
$lines = Get-Content -LiteralPath $pyFile -Encoding UTF8
$pattern = '^\s+\("(.+)", "(.+)", (\d+), "(.+)"\),?\s*$'

$articles = @()
foreach ($line in $lines) {
    if ($line -match $pattern) {
        $articles += [PSCustomObject]@{
            t = $Matches[1]
            r = $Matches[2]
            c = [int]$Matches[3]
            d = $Matches[4]
        }
    }
}

if ($articles.Count -eq 0) {
    throw "No articles parsed"
}

function Parse-Reads($s) {
    if ($s.EndsWith([char]0x4E07)) {
        $num = $s.Substring(0, $s.Length - 1)
        return [int]([double]$num * 10000)
    }
    return [int]$s
}

function Normalize-Date($d) {
    if ($d -match '^\d{2}-\d{2}$') {
        return "2026-$d"
    }
    if ($d -match '^(\d+)') {
        $days = [int]$Matches[1]
        $rest = $d.Substring($Matches[1].Length)
        if ($rest.Length -eq 2) {
            $dt = ([datetime]'2026-06-09').AddDays(-$days).ToString('yyyy-MM-dd')
            return "$dt ($d)"
        }
    }
    return $d
}

$out = Join-Path $dir "benchmark_output.md"
$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine('# benchmark: lishizhenchachu')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('| # | title | reads | reads_num | comments | date |')
[void]$sb.AppendLine('|---|-------|-------|-----------|----------|------|')

$nums = @()
$commentSum = 0
$i = 0
foreach ($a in $articles) {
    $i++
    $title = ($a.t -replace '\|','\\|')
    $rn = Parse-Reads $a.r
    $nums += $rn
    $commentSum += $a.c
    $dn = Normalize-Date $a.d
    [void]$sb.AppendLine("| $i | $title | $($a.r) | $rn | $($a.c) | $dn |")
}

$sorted = $nums | Sort-Object
$median = $sorted[[int]($sorted.Count/2)]
[void]$sb.AppendLine('')
[void]$sb.AppendLine('## stats')
[void]$sb.AppendLine("- count: $($articles.Count)")
[void]$sb.AppendLine("- reads_sum: $($nums | Measure-Object -Sum | Select-Object -ExpandProperty Sum)")
[void]$sb.AppendLine("- reads_max: $($nums | Measure-Object -Maximum | Select-Object -ExpandProperty Maximum)")
[void]$sb.AppendLine("- reads_min: $($nums | Measure-Object -Minimum | Select-Object -ExpandProperty Minimum)")
[void]$sb.AppendLine("- reads_median: $median")
[void]$sb.AppendLine("- comments_sum: $commentSum")
[void]$sb.AppendLine("- reads_ge_10k: $(($nums | Where-Object { $_ -ge 10000 }).Count)")
[void]$sb.AppendLine("- reads_ge_50k: $(($nums | Where-Object { $_ -ge 50000 }).Count)")

[System.IO.File]::WriteAllText($out, $sb.ToString(), [System.Text.UTF8Encoding]::new($false))
Write-Host "OK: $($articles.Count) -> $out"
