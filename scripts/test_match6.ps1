$utf8 = New-Object System.Text.UTF8Encoding($false, $true)

$srcPath = $args[0]

$content = [System.IO.File]::ReadAllText($srcPath, $utf8)
$lines = $content -split "`r?`n"

# Line 15 detail
$line = $lines[15]
Write-Host ("Length: " + $line.Length)
Write-Host ("Bytes (UTF-8): " + [System.Text.Encoding]::UTF8.GetByteCount($line))
Write-Host ("Char 0: [" + $line[0] + "] = " + [int]$line[0])
Write-Host ("Char 1: [" + $line[1] + "] = " + [int]$line[1])
Write-Host ("Char 2: [" + $line[2] + "] = " + [int]$line[2])
Write-Host ("Char 3: [" + $line[3] + "] = " + [int]$line[3])

# Try startsWith
Write-Host ""
Write-Host ("StartsWith '##': " + $line.StartsWith("##"))
Write-Host ("Contains '引言': " + $line.Contains("引言"))

# Test the exact match
$test = "^##\s+引言\s*$"
Write-Host ("Pattern match: " + ($line -match $test))

# Test simpler
Write-Host ("Simpler match: " + ($line -match "^##"))
