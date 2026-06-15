Set-Location -LiteralPath "C:\Users\27649\Documents\myproject\Content"
$targetDir = Get-ChildItem -LiteralPath "." -Directory -Filter "08_*" | Where-Object { $_.Name -match "杜邦" } | Select-Object -First 1
Write-Host "Found dir: $($targetDir.FullName)"
$draft = Join-Path $targetDir.FullName "04_草稿\草稿.md"
$content = Get-Content -LiteralPath $draft -Raw -Encoding UTF8
Write-Host "Content length: $($content.Length)"
$matches = [regex]::Matches($content, '[\u4e00-\u9fff]')
Write-Host "中文字符总数: $($matches.Count)"
$ascii = [regex]::Matches($content, '[A-Za-z]')
Write-Host "英文字符数: $($ascii.Count)"
$lines = $content -split "`n"
Write-Host "总行数: $($lines.Length)"