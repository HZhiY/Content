$ErrorActionPreference = "Stop"
$base = "C:\Users\27649\Documents\myproject\Content"
$kanban = [string][char]0x770B + [string][char]0x677F
$dir = Join-Path $base ("_" + $kanban)
$header = Join-Path $dir "shiji_header.md"
$bench = Join-Path $dir "benchmark_shiji_output.md"
$outName = [string][char]0x5BF9 + [string][char]0x6807 + [string][char]0x6570 + [string][char]0x636E + "_2026-06-09_" + [string][char]0x53F2 + [string][char]0x7EAA + [string][char]0x767E + [string][char]0x5E74 + ".md"
$final = Join-Path $dir $outName

$enc = [System.Text.UTF8Encoding]::new($false)
$benchLines = [System.IO.File]::ReadAllLines($bench, $enc)

$count = 0; $sum = 0; $maxR = 0; $minR = [int]::MaxValue; $comments = 0; $ge1w = 0; $ge5w = 0; $ge10w = 0
$readsList = @()
$tableRows = @()

for ($i = 0; $i -lt $benchLines.Length; $i++) {
    $line = $benchLines[$i]
    if ($line -match '^\| (\d+) \| (.+) \| ([^|]+) \| (\d+) \| (\d+) \| (.+) \|$') {
        $count++
        $rn = [int]$Matches[4]
        $c = [int]$Matches[5]
        $readsList += $rn
        $sum += $rn
        $comments += $c
        if ($rn -gt $maxR) { $maxR = $rn }
        if ($rn -lt $minR) { $minR = $rn }
        if ($rn -ge 10000) { $ge1w++ }
        if ($rn -ge 50000) { $ge5w++ }
        if ($rn -ge 100000) { $ge10w++ }
        $tableRows += "| $($Matches[1]) | $($Matches[2]) | $($Matches[3]) | $rn | $c | $($Matches[6]) |"
    }
}

$sorted = $readsList | Sort-Object
$median = $sorted[[int]($sorted.Count / 2)]

$headerText = [System.IO.File]::ReadAllText($header, $enc) -replace 'PLACEHOLDER_COUNT', "$count"
$footer = [System.IO.File]::ReadAllText((Join-Path $dir "shiji_footer.md"), $enc)

$content = $headerText + ($tableRows -join "`n") + "`n" + $footer
[System.IO.File]::WriteAllText($final, $content, $enc)
Write-Host "Wrote $count rows -> $final"
