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