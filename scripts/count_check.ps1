Add-Type -AssemblyName System.Text.RegularExpressions
$path = 'c:\Users\27649\Documents\myproject\Content\美国如何从工业国变成金融国\10_为什么美联储像是从摩根图书馆里长出来的\02_洞察及主题\传播学审查卡.md'
$content = [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)
$cn = [regex]::Matches($content, '[\u4e00-\u9fff]')
Write-Output ('Chinese chars: ' + $cn.Count)
$cnp = [regex]::Matches($content, '[\u4e00-\u9fff\u3000-\u303f\uff00-\uffef]')
Write-Output ('Chinese + punct: ' + $cnp.Count)