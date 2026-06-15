[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
$rp = $env:REVIEW_PATH
$c = Get-Content -LiteralPath $rp -Raw -Encoding UTF8
$matches = [regex]::Matches($c, '[A-Za-z]+')
foreach ($m in $matches) {
    $start = [Math]::Max(0, $m.Index - 10)
    $len = [Math]::Min(40, $c.Length - $start)
    $ctx = $c.Substring($start, $len)
    Write-Host ("[{0}] @{1}: ...{2}..." -f $m.Value, $m.Index, $ctx)
}