$script = @'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
$draftPath = "C:\Users\27649\Documents\myproject\Content\美国如何从工业国变成金融国\08_为什么杜邦要救通用汽车？\04_草稿\草稿.md"
Write-Host "Path: $draftPath"
Write-Host "Test-Path: $(Test-Path -LiteralPath $draftPath)"
if (Test-Path -LiteralPath $draftPath) {
    $content = Get-Content -LiteralPath $draftPath -Raw -Encoding UTF8
    Write-Host "Content length: $($content.Length)"
    $cn = [regex]::Matches($content, '[\u4e00-\u9fff]').Count
    $en = [regex]::Matches($content, '[A-Za-z]').Count
    $lines = ($content -split "`n").Count
    Write-Host ("中文字符数: {0}" -f $cn)
    Write-Host ("英文字符数: {0}" -f $en)
    Write-Host ("总行数: {0}" -f $lines)
}
'@
$utf8 = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText("C:\Users\27649\Documents\myproject\Content\scripts\count_chars4.ps1", $script, $utf8)
Write-Host "Script written"