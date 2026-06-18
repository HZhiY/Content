$utf8 = New-Object System.Text.UTF8Encoding($false, $true)

$srcPath = $args[0]

$content = [System.IO.File]::ReadAllText($srcPath, $utf8)
$lines = $content -split "`r?`n"

# Print all ## lines
Write-Host "All ## lines:"
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i].StartsWith("##")) {
        Write-Host ("  [" + $i + "] " + $lines[$i])
    }
}
