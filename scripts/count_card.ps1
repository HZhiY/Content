$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath 'C:\Users\27649\Documents\myproject\Content\美国如何从工业国变成金融国\10_为什么美联储像是从摩根图书馆里长出来的\02_洞察及主题'
$f = Get-ChildItem -LiteralPath '.' -Filter '*.md' | Where-Object { $_.Name -like '*?%' }
foreach ($item in $f) {
  $bytes = [System.IO.File]::ReadAllBytes($item.FullName)
  $text = [System.Text.Encoding]::UTF8.GetString($bytes)
  $cn = [regex]::Matches($text, '[一-鿿]')
  $out = $item.Name + ' | Total: ' + $text.Length + ' | CN: ' + $cn.Count
  Write-Output $out
}
