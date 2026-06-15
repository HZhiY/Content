[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
$draftPath = $env:DRAFT_PATH
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