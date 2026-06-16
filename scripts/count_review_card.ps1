Set-Location 'C:\Users\27649\Documents\myproject\Content\美国如何从工业国变成金融国\10_为什么美联储像是从摩根图书馆里长出来的\02_洞察及主题'
$file = '.\传播学审查卡.md'
$content = Get-Content $file -Raw -Encoding UTF8
$cnCount = 0
foreach ($ch in $content.ToCharArray()) {
    $code = [int]$ch
    if ($code -ge 0x4E00 -and $code -le 0x9FFF) { $cnCount++ }
}
Write-Output "Chinese chars: $cnCount"
Write-Output "Total chars: $($content.Length)"
