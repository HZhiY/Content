$utf8 = New-Object System.Text.UTF8Encoding($false, $true)

$srcPath = $args[0]

$content = [System.IO.File]::ReadAllText($srcPath, $utf8)
$lines = $content -split "`r?`n"

# Loop test
$foundIntro = $false
for ($i = 0; $i -lt $lines.Count; $i++) {
    $line = $lines[$i]
    if ($line.StartsWith("##") -and $line.Contains("引言")) {
        $foundIntro = $true
        Write-Host ("Found at index " + $i + ": " + $line)
        break
    }
}
