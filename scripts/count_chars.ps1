$path = 'C:\Users\27649\Documents\myproject\Content\美国如何从工业国变成金融国\08_为什么杜邦要救通用汽车？\04_草稿\草稿.md'
$content = Get-Content -Path $path -Raw -Encoding UTF8
$matches = [regex]::Matches($content, '[\u4e00-\u9fff]')
Write-Host "中文字符总数: $($matches.Count)"
$ascii = [regex]::Matches($content, '[A-Za-z]')
Write-Host "英文字符数: $($ascii.Count)"
$lines = $content -split "`n"
Write-Host "总行数: $($lines.Length)"