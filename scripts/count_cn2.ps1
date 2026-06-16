$path = 'C:\Users\27649\Documents\myproject\Content\美国如何从工业国变成金融国\10_为什么美联储像是从摩根图书馆里长出来的\02_洞察及主题\结构命题审查卡.md'
$bytes = [System.IO.File]::ReadAllBytes($path)
$text = [System.Text.Encoding]::UTF8.GetString($bytes)
$cn = [regex]::Matches($text, '[\u4e00-\u9fff]')
$total = $text.Length
Write-Host ('Total chars: ' + $total)
Write-Host ('Chinese chars: ' + $cn.Count)
