$dir = $PSScriptRoot
$scriptPath = Join-Path $dir '_check02.ps1'
chcp 65001 | Out-Null
$output = & $scriptPath 2>&1
$output | Out-File -FilePath (Join-Path $dir '_check_output.txt') -Encoding UTF8
$output | ForEach-Object { Write-Host $_ }
