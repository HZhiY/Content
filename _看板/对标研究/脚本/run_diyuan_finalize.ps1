$ErrorActionPreference = "Stop"
$base = "C:\Users\27649\Documents\myproject\Content"
$kanban = [string][char]0x770B + [string][char]0x677F
$dir = Join-Path $base ("_" + $kanban)
$header = Join-Path $dir "diyuan_header.md"
$footer = Join-Path $dir "diyuan_footer.md"
$bench = Join-Path $dir "benchmark_diyuan_output.md"
$outName = [string][char]0x5BF9 + [string][char]0x6807 + [string][char]0x6570 + [string][char]0x636E + "_2026-06-09_" + [string][char]0x5730 + [string][char]0x7F18 + [string][char]0x5386 + [string][char]0x53F2 + [string][char]0x6863 + [string][char]0x6848 + [string][char]0x9986 + ".md"
$final = Join-Path $dir $outName

$enc = [System.Text.UTF8Encoding]::new($false)
$headerText = [System.IO.File]::ReadAllText($header, $enc)
$footerText = [System.IO.File]::ReadAllText($footer, $enc)
$benchLines = [System.IO.File]::ReadAllLines($bench, $enc)

$tableRows = @()
for ($i = 0; $i -lt $benchLines.Length; $i++) {
    $line = $benchLines[$i]
    if ($line -match '^\| \d+ \|') {
        $tableRows += ($line -replace '^\| no \|', '| 序号 |' -replace '^\| (\d+) \|', '| $1 |')
    }
}

$content = $headerText + ($tableRows -join "`n") + "`n" + $footerText
[System.IO.File]::WriteAllText($final, $content, $enc)
Write-Host "Wrote $($tableRows.Count) rows -> $final"
