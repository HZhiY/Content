$utf8 = New-Object System.Text.UTF8Encoding($false, $true)

$srcPath = $args[0]
$phrasesPath = $args[1]
$checksPath = $args[2]

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

Write-Host ("Body lines count: " + $bodyLines.Count)
Write-Host ("First line: [" + $bodyLines[0] + "]")
Write-Host ("Last line: [" + $bodyLines[-1] + "]")

if ($bodyLines.Count -gt 0 -and $bodyLines[-1].Trim() -eq "---") {
    $bodyLines = $bodyLines[0..($bodyLines.Count - 2)]
}

$order = @()
$sections = @{}
$curName = $null
$curLines = @()

# Match ## (non-greedy) followed by section name
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
    $n = ($body -replace "\s", "").Length
    $total += $n
    $lineCount = ($sections[$name] | Where-Object { $_.Trim() -ne "" }).Count
    Write-Host ("[" + $name + "] chars=" + $n + "  lines=" + $lineCount)
}
Write-Host ("TOTAL: " + $total)

Write-Host ""
Write-Host "=== para > 6 lines ==="
$paraOver6 = 0
foreach ($name in $order) {
    $para = @()
    foreach ($line in $sections[$name]) {
        if ($line.Trim() -eq "") {
            if ($para.Count -gt 6) {
                $paraOver6++
                $preview = ($para[0..1] -join " ") -replace "\s+", " "
                Write-Host ("  [" + $name + "] " + $para.Count + " lines : " + $preview.Substring(0, [Math]::Min(50, $preview.Length)))
            }
            $para = @()
        } else {
            $para += $line
        }
    }
    if ($para.Count -gt 6) {
        $paraOver6++
        $preview = ($para[0..1] -join " ") -replace "\s+", " "
        Write-Host ("  [" + $name + "] " + $para.Count + " lines : " + $preview.Substring(0, [Math]::Min(50, $preview.Length)))
    }
}
Write-Host ("Total para > 6 lines: " + $paraOver6)

$fullBody = -join $bodyLines

$fullCleaned = $fullBody -replace "\s", ""
$totalPunctChars = $fullCleaned.Length
$totalHanzi = ([regex]::Matches($fullCleaned, "[\u4e00-\u9fff]")).Count
$totalPunct = $totalPunctChars - $totalHanzi
Write-Host ""
Write-Host "=== char count breakdown ==="
Write-Host ("  Total non-blank: " + $totalPunctChars)
Write-Host ("  Hanzi: " + $totalHanzi)
Write-Host ("  Punct+other: " + $totalPunct)

# Read check list
$checkBytes = [System.IO.File]::ReadAllText($checksPath, $utf8)
$checkList = $checkBytes -split "`r?`n"
Write-Host ""
Write-Host "=== evidence markers ==="
foreach ($c in $checkList) {
    if ([string]::IsNullOrWhiteSpace($c)) { continue }
    $cnt = ([regex]::Matches($fullBody, [regex]::Escape($c))).Count
    Write-Host ("  " + $c + ": " + $cnt)
}

$phrBytes = [System.IO.File]::ReadAllText($phrasesPath, $utf8)
$phrases = $phrBytes -split "`r?`n"
Write-Host ""
Write-Host "=== phrases ==="
foreach ($pp in $phrases) {
    if ([string]::IsNullOrWhiteSpace($pp)) { continue }
    $cnt = ([regex]::Matches($fullBody, [regex]::Escape($pp))).Count
    Write-Host ("  " + $pp + ": " + $cnt)
}

# 短句长度分布
Write-Host ""
Write-Host "=== sentence length distribution ==="
$cleaned2 = $fullBody -replace "[\s>]"
$pattern = "[\u3002\uFF01\uFF1F]"
$sentences = [regex]::Split($cleaned2, $pattern)
$lenBuckets = @(0,0,0,0,0,0)
foreach ($s in $sentences) {
    $s = $s.Trim()
    if ($s.Length -eq 0) { continue }
    if ($s.Length -le 20) { $lenBuckets[0]++ }
    elseif ($s.Length -le 35) { $lenBuckets[1]++ }
    elseif ($s.Length -le 60) { $lenBuckets[2]++ }
    elseif ($s.Length -le 100) { $lenBuckets[3]++ }
    elseif ($s.Length -le 200) { $lenBuckets[4]++ }
    else { $lenBuckets[5]++ }
}
Write-Host ("  <=20 chars: " + $lenBuckets[0])
Write-Host ("  21-35 chars: " + $lenBuckets[1])
Write-Host ("  36-60 chars: " + $lenBuckets[2])
Write-Host ("  61-100 chars: " + $lenBuckets[3])
Write-Host ("  101-200 chars: " + $lenBuckets[4])
Write-Host ("  >200 chars: " + $lenBuckets[5])

# Save body for any future use
[System.IO.File]::WriteAllText("c:\Users\27649\Documents\myproject\Content\scripts\_rev1_body.txt", $fullBody, $utf8)
