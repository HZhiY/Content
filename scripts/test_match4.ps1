$utf8 = New-Object System.Text.UTF8Encoding($false, $true)

$srcPath = $args[0]

$content = [System.IO.File]::ReadAllText($srcPath, $utf8)
$lines = $content -split "`r?`n"

Write-Host ("Lines count: " + $lines.Count)

# Find first ## line
$intro = -1
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i].StartsWith("##")) {
        $intro = $i
        break
    }
}
Write-Host ("First ## at index: " + $intro)
if ($intro -ge 0) {
    Write-Host ("  Content: [" + $lines[$intro] + "]")
}

# Try char comparison
Write-Host ""
Write-Host ("Char 0 of line " + $intro + ": " + $lines[$intro][0])
Write-Host ("Char 1 of line " + $intro + ": " + $lines[$intro][1])
Write-Host ("Substring(0,2): [" + $lines[$intro].Substring(0,2) + "]")

# Save first 5 lines
Write-Host ""
Write-Host "First 5 lines:"
for ($i = 0; $i -lt 5; $i++) {
    Write-Host ("  [" + $i + "] " + $lines[$i])
}
