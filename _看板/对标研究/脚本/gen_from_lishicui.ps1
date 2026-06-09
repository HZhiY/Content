$ErrorActionPreference = "Stop"
$dir = Split-Path -Parent $MyInvocation.MyCommand.Path
$pyFile = Join-Path $dir "gen_benchmark_lishicui.py"
$lines = Get-Content -LiteralPath $pyFile -Encoding UTF8
$pattern = '^\s+\("(.+)", "(.+)", (\d+), "(.+)", "(.+)"\),?\s*$'

$articles = @()
foreach ($line in $lines) {
    if ($line -match $pattern) {
        $articles += [PSCustomObject]@{
            t = $Matches[1]
            r = $Matches[2]
            c = [int]$Matches[3]
            d = $Matches[4]
            typ = $Matches[5]
        }
    }
}
if ($articles.Count -eq 0) { throw "No articles parsed" }

function Parse-Reads($s) {
    if ($s.EndsWith([char]0x4E07)) {
        return [int]([double]$s.Substring(0, $s.Length - 1) * 10000)
    }
    return [int]$s
}

function Normalize-Date($d) {
    if ($d -match '^\d{2}-\d{2}$') { return "2026-$d" }
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

$out = Join-Path $dir 'benchmark_lishicui_output.md'
$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine('# benchmark_lishicui')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('| # | type | reads | reads_num | comments | date | title |')
[void]$sb.AppendLine('|---|------|-------|-----------|----------|------|-------|')

$nums = @(); $cs = 0; $i = 0
foreach ($a in $articles) {
    $i++
    $rn = Parse-Reads $a.r
    $nums += $rn; $cs += $a.c
    $dn = Normalize-Date $a.d
    $title = ($a.t -replace '\|','\\|')
    [void]$sb.AppendLine("| $i | $($a.typ) | $($a.r) | $rn | $($a.c) | $dn | $title |")
}

$sorted = $nums | Sort-Object
[void]$sb.AppendLine('')
[void]$sb.AppendLine('## stats')
[void]$sb.AppendLine("- count: $($articles.Count)")
[void]$sb.AppendLine("- reads_sum: $(($nums | Measure-Object -Sum).Sum)")
[void]$sb.AppendLine("- reads_max: $(($nums | Measure-Object -Maximum).Maximum)")
[void]$sb.AppendLine("- reads_min: $(($nums | Measure-Object -Minimum).Minimum)")
[void]$sb.AppendLine("- reads_median: $($sorted[[int]($sorted.Count/2)])")
[void]$sb.AppendLine("- comments_sum: $cs")
[void]$sb.AppendLine("- reads_ge_10k: $(($nums | Where-Object { $_ -ge 10000 }).Count)")
[void]$sb.AppendLine("- reads_ge_50k: $(($nums | Where-Object { $_ -ge 50000 }).Count)")
[void]$sb.AppendLine("- videos: $(($articles | Where-Object { $_.typ -eq 'video' }).Count)")

[System.IO.File]::WriteAllText($out, $sb.ToString(), [System.Text.UTF8Encoding]::new($false))
Write-Host "OK: $($articles.Count) -> $out"
