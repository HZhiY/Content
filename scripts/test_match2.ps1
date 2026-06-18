$utf8 = New-Object System.Text.UTF8Encoding($false, $true)

$srcPath = $args[0]

$content = [System.IO.File]::ReadAllText($srcPath, $utf8)
$lines = $content -split "`r?`n"

# 找第一个 '## 引言' 作为起点
$bodyLines = @()
$foundIntro = $false
foreach ($line in $lines) {
    if (-not $foundIntro) {
        if ($line -match "^##\s+引言\s*$") {
            $foundIntro = $true
            $bodyLines += $line
        }
        continue
    }
    $bodyLines += $line
}

Write-Host ("Body lines count: " + $bodyLines.Count)
Write-Host ("First 3 body lines:")
for ($i = 0; $i -lt 3 -and $i -lt $bodyLines.Count; $i++) {
    Write-Host ("  [" + $i + "] " + $bodyLines[$i])
}

# 末尾 ---
Write-Host ("Last 3 body lines:")
for ($i = [Math]::Max(0, $bodyLines.Count - 3); $i -lt $bodyLines.Count; $i++) {
    Write-Host ("  [" + $i + "] " + $bodyLines[$i])
}
