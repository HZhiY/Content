$utf8 = New-Object System.Text.UTF8Encoding($false, $true)

$srcPath = $args[0]

# Read source via .NET
$content = [System.IO.File]::ReadAllText($srcPath, $utf8)
$lines = $content -split "`r?`n"

Write-Host ("Total lines: " + $lines.Count)
Write-Host ("Content length: " + $content.Length)

# Look for ## markers
foreach ($line in $lines) {
    if ($line -match "^##\s+") {
        Write-Host ("MATCH: [" + $line + "]")
    }
}

# Test specific
$test = "## 引言"
Write-Host ""
Write-Host ("Test 引言 match: " + ($test -match "^##\s+(.+)$"))
if ($test -match "^##\s+(.+)$") {
    Write-Host ("  Captured: " + $matches[1])
}
