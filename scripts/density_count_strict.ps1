$utf8 = New-Object System.Text.UTF8Encoding($false, $true)

$srcPath = $args[0]

$content = [System.IO.File]::ReadAllText($srcPath, $utf8)
$lines = $content -split "`r?`n"

# Use Unicode escape for "引言"
$introMarker = [char]0x5F15 + [char]0x8A00
$introMarkerLine = "## " + $introMarker

# Find first intro
$foundIntro = $false
$bodyLines = @()
foreach ($line in $lines) {
    if (-not $foundIntro) {
        if ($line.Trim() -eq $introMarkerLine) {
            $foundIntro = $true
            $bodyLines += $line
        }
        continue
    }
    $bodyLines += $line
}

if ($bodyLines.Count -gt 0 -and $bodyLines[-1].Trim() -eq "---") {
    $bodyLines = $bodyLines[0..($bodyLines.Count - 2)]
}

# 严格 CJK 计数
function Global:StrictCnCount($text) {
    $n = 0
    foreach ($ch in $text.ToCharArray()) {
        $cp = [int]$ch
        if ($cp -ge 0x4E00 -and $cp -le 0x9FFF) { $n++; continue }
        if ($cp -ge 0x3400 -and $cp -le 0x4DBF) { $n++; continue }
        if ($cp -ge 0x20000 -and $cp -le 0x2A6DF) { $n++; continue }
        if ($cp -ge 0xFF00 -and $cp -le 0xFFEF) { $n++; continue }
        if ($cp -ge 0x3000 -and $cp -le 0x303F) { $n++; continue }
    }
    return $n
}

$order = @()
$sections = @{}
$curName = $null
$curLines = @()

foreach ($line in $bodyLines) {
    if ($line -match "^##\s+(.+)$") {
        if ($null -ne $curName) {
            $sections[$curName] = $curLines
            $order += $curName
        }
        $curName = $matches[1].Trim()
        $curLines = @()
    } else {
        if ($null -ne $curName -and $line.Trim() -ne "---") {
            $curLines += $line
        }
    }
}
if ($null -ne $curName) {
    $sections[$curName] = $curLines
    $order += $curName
}

$total = 0
foreach ($name in $order) {
    $body = -join $sections[$name]
    $n = StrictCnCount $body
    $total += $n
    $lineCount = ($sections[$name] | Where-Object { $_.Trim() -ne "" }).Count
    Write-Host ("[" + $name + "] strict_cn=" + $n + "  lines=" + $lineCount)
}
Write-Host ("TOTAL strict_cn: " + $total)
