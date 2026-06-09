$ErrorActionPreference = "Stop"
$dir = Split-Path -Parent $MyInvocation.MyCommand.Path
$src = Join-Path $dir "benchmark_lishicui_output.md"
$dst = Join-Path $dir "lishicui_table.md"
$lines = Get-Content -LiteralPath $src -Encoding UTF8
$out = @(
"| idx | title | type | reads | reads_num | comments | date |",
"|-----|-------|------|-------|-----------|----------|------|"
)
foreach ($line in $lines) {
    if ($line -notmatch '^\| \d+ \|') { continue }
    $p = ($line -split '\|') | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }
    if ($p.Count -lt 7) { continue }
    $out += "| $($p[0]) | $($p[6]) | $($p[1]) | $($p[2]) | $($p[3]) | $($p[4]) | $($p[5]) |"
}
[System.IO.File]::WriteAllLines($dst, $out, [System.Text.UTF8Encoding]::new($false))
Write-Host "rows: $($out.Count - 2)"
