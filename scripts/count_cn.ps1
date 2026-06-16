$text = Get-Content 'c:\Users\27649\Documents\myproject\Content\美国如何从工业国变成金融国\10_为什么美联储像是从摩根图书馆里长出来的\02_洞察及主题\结构命题审查卡.md'
$all = ($text | Out-String)
$matches = [regex]::Matches($all, '[\u4e00-\u9fff]')
Write-Host ('Chinese chars: ' + $matches.Count)
Write-Host ('Total chars: ' + $all.Length)
