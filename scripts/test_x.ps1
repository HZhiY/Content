$utf8 = New-Object System.Text.UTF8Encoding($false, $true)
$srcPath = $args[0]
$content = [System.IO.File]::ReadAllText($srcPath, $utf8)

# Find "60 亿" and surrounding text
$idx = $content.IndexOf("60 亿")
Write-Host "60 亿 location: $idx"
if ($idx -ge 0) {
    $start = [Math]::Max(0, $idx - 30)
    $end = [Math]::Min($content.Length, $idx + 30)
    Write-Host ("  Context: " + $content.Substring($start, $end - $start))
}

# Find "16.5 亿"
$idx = $content.IndexOf("16.5 亿")
Write-Host ""
Write-Host "16.5 亿 location: $idx"
if ($idx -ge 0) {
    $start = [Math]::Max(0, $idx - 30)
    $end = [Math]::Min($content.Length, $idx + 30)
    Write-Host ("  Context: " + $content.Substring($start, $end - $start))
}

# Count 5 证 in text
$count1 = ([regex]::Matches($content, "5 证")).Count
$count2 = ([regex]::Matches($content, "5 个工具")).Count
$count3 = ([regex]::Matches($content, "5 个证据")).Count
Write-Host ""
Write-Host "5 证: $count1"
Write-Host "5 个工具: $count2"
Write-Host "5 个证据: $count3"
