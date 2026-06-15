$script = @'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
$rp = $env:REVIEW_PATH
$tp = Test-Path -LiteralPath $rp
Write-Host "Test: $tp"
if ($tp) {
    $c = Get-Content -LiteralPath $rp -Raw -Encoding UTF8
    $cn = [regex]::Matches($c, '[\u4e00-\u9fff]').Count
    $en = [regex]::Matches($c, '[A-Za-z]').Count
    $total = $c.Length
    Write-Host ("Total chars: {0}" -f $total)
    Write-Host ("Chinese chars: {0}" -f $cn)
    Write-Host ("English chars: {0}" -f $en)
}
'@
$utf8 = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText("C:\Users\27649\Documents\myproject\Content\scripts\verify_review.ps1", $script, $utf8)
Write-Host "OK"