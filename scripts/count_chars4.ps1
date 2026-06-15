[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
$draftPath = "C:\Users\27649\Documents\myproject\Content\缇庡浗濡備綍浠庡伐涓氬浗鍙樻垚閲戣瀺鍥絓08_涓轰粈涔堟潨閭﹁鏁戦€氱敤姹借溅锛焅04_鑽夌\鑽夌.md"
Write-Host "Path: $draftPath"
Write-Host "Test-Path: $(Test-Path -LiteralPath $draftPath)"
if (Test-Path -LiteralPath $draftPath) {
    $content = Get-Content -LiteralPath $draftPath -Raw -Encoding UTF8
    Write-Host "Content length: $($content.Length)"
    $cn = [regex]::Matches($content, '[\u4e00-\u9fff]').Count
    $en = [regex]::Matches($content, '[A-Za-z]').Count
    $lines = ($content -split "`n").Count
    Write-Host ("涓枃瀛楃鏁? {0}" -f $cn)
    Write-Host ("鑻辨枃瀛楃鏁? {0}" -f $en)
    Write-Host ("鎬昏鏁? {0}" -f $lines)
}