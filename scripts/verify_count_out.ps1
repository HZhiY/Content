$utf8 = New-Object System.Text.UTF8Encoding($false, $true)
$outputFile = $args[0]
$content = [System.IO.File]::ReadAllText($outputFile, $utf8)
$lines = $content -split "`r?`n"

# Count CJK
$totalCn = 0
$totalHanzi = 0
foreach ($ch in $content.ToCharArray()) {
    $cp = [int]$ch
    if ($cp -ge 0x4E00 -and $cp -le 0x9FFF) { $totalHanzi++; $totalCn++ }
    elseif ($cp -ge 0x3400 -and $cp -le 0x4DBF) { $totalHanzi++; $totalCn++ }
    elseif ($cp -ge 0x20000 -and $cp -le 0x2A6DF) { $totalHanzi++; $totalCn++ }
    elseif ($cp -ge 0xFF00 -and $cp -le 0xFFEF) { $totalCn++ }
    elseif ($cp -ge 0x3000 -and $cp -le 0x303F) { $totalCn++ }
}
Write-Host ("Total CJK (hanzi+cn punct): " + $totalCn)
Write-Host ("Hanzi: " + $totalHanzi)

# Count lines
Write-Host ("Total lines: " + $lines.Count)
