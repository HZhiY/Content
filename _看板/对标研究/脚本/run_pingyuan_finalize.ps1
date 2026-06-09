$ErrorActionPreference = "Stop"
$base = "C:\Users\27649\Documents\myproject\Content"
$kanban = [string][char]0x770B + [string][char]0x677F
$dir = Join-Path $base ("_" + $kanban)
$header = Join-Path $dir "pingyuan_header.md"
$footer = Join-Path $dir "pingyuan_footer.md"
$bench = Join-Path $dir "benchmark_pingyuan_output.md"
$outName = [string][char]0x5BF9 + [string][char]0x6807 + [string][char]0x6570 + [string][char]0x636E + "_2026-06-09_" + [string][char]0x5E73 + [string][char]0x539F + [string][char]0x9690 + [string][char]0x8005 + ".md"
$final = Join-Path $dir $outName

$enc = [System.Text.UTF8Encoding]::new($false)
$benchLines = [System.IO.File]::ReadAllLines($bench, $enc)

$count = 0; $comments = 0
$readsList = @()
$tableRows = @()

for ($i = 0; $i -lt $benchLines.Length; $i++) {
    $line = $benchLines[$i]
    if ($line -match '^\| (\d+) \| ') {
        $parts = $line -split '\|'
        if ($parts.Count -ge 8) {
            $no = $parts[1].Trim()
            $title = ($parts[2..($parts.Count - 6)] -join '|').Trim()
            $reads = $parts[$parts.Count - 5].Trim()
            $rn = [int]$parts[$parts.Count - 4].Trim()
            $c = [int]$parts[$parts.Count - 3].Trim()
            $date = $parts[$parts.Count - 2].Trim()
            $count++
            $readsList += $rn
            $comments += $c
            $tableRows += "| $no | $title | $reads | $rn | $c | $date |"
        }
    }
}

$sorted = $readsList | Sort-Object
$median = $sorted[[int]($sorted.Count / 2)]
$sum = ($readsList | Measure-Object -Sum).Sum
$maxR = ($readsList | Measure-Object -Maximum).Maximum
$minR = ($readsList | Measure-Object -Minimum).Minimum
$ge1w = ($readsList | Where-Object { $_ -ge 10000 }).Count
$ge5w = ($readsList | Where-Object { $_ -ge 50000 }).Count
$ge10w = ($readsList | Where-Object { $_ -ge 100000 }).Count

$headerText = [System.IO.File]::ReadAllText($header, $enc) -replace 'PLACEHOLDER_COUNT', "$count"
$footerText = [System.IO.File]::ReadAllText($footer, $enc)
$footerText = $footerText -replace 'PLACEHOLDER_COUNT', "$count"
$footerText = $footerText -replace 'PLACEHOLDER_SUM', ($sum.ToString('N0'))
$footerText = $footerText -replace 'PLACEHOLDER_MAX', ($maxR.ToString('N0'))
$footerText = $footerText -replace 'PLACEHOLDER_MIN', ($minR.ToString('N0'))
$footerText = $footerText -replace 'PLACEHOLDER_MEDIAN', ($median.ToString('N0'))
$footerText = $footerText -replace 'PLACEHOLDER_COMMENTS', ($comments.ToString('N0'))
$footerText = $footerText -replace 'PLACEHOLDER_GE1W', "$ge1w"
$footerText = $footerText -replace 'PLACEHOLDER_GE5W', "$ge5w"
$footerText = $footerText -replace 'PLACEHOLDER_GE10W', "$ge10w"

$content = $headerText + ($tableRows -join "`n") + "`n" + $footerText
[System.IO.File]::WriteAllText($final, $content, $enc)
Write-Host "Wrote $count rows sum=$sum median=$median ge10k=$ge10w"
