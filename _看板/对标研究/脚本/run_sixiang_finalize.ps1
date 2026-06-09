$ErrorActionPreference = "Stop"
$base = "C:\Users\27649\Documents\myproject\Content"
$kanban = [string][char]0x770B + [string][char]0x677F
$dir = Join-Path $base ("_" + $kanban)
$header = Join-Path $dir "sixiang_header.md"
$footer = Join-Path $dir "sixiang_footer.md"
$bench = Join-Path $dir "benchmark_sixiang_output.md"
$outName = [string][char]0x5BF9 + [string][char]0x6807 + [string][char]0x6570 + [string][char]0x636E + "_2026-06-09_" + [string][char]0x601D + [string][char]0x60F3 + [string][char]0x53F2 + [string][char]0x4E07 + [string][char]0x6709 + [string][char]0x5F15 + [string][char]0x529B + ".md"
$final = Join-Path $dir $outName

$enc = [System.Text.UTF8Encoding]::new($false)
$benchLines = [System.IO.File]::ReadAllLines($bench, $enc)

$count = 0; $sum = 0; $maxR = 0; $minR = [int]::MaxValue; $comments = 0
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
        $tableRows += "| $($Matches[1]) | $($Matches[2]) | $($Matches[3]) | $rn | $c | $($Matches[6]) |"
    }
}

$sorted = $readsList | Sort-Object
$median = $sorted[[int]($sorted.Count / 2)]
$ge1w = ($readsList | Where-Object { $_ -ge 10000 }).Count
$ge5w = ($readsList | Where-Object { $_ -ge 50000 }).Count
$ge10w = ($readsList | Where-Object { $_ -ge 100000 }).Count

$headerText = [System.IO.File]::ReadAllText($header, $enc) -replace 'PLACEHOLDER_COUNT', "$count"
$footerText = [System.IO.File]::ReadAllText($footer, $enc)
$footerText = $footerText -replace 'PLACEHOLDER_MEDIAN', ($median.ToString('N0'))
$footerText = $footerText -replace 'PLACEHOLDER_COMMENTS', ($comments.ToString('N0'))

$content = $headerText + ($tableRows -join "`n") + "`n" + $footerText
[System.IO.File]::WriteAllText($final, $content, $enc)
Write-Host "Wrote $count rows median=$median comments=$comments"
