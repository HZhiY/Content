[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
$dp = $env:DRAFT_PATH
$tp = Test-Path -LiteralPath $dp
Write-Host "Test: $tp"
if ($tp) {
    $c = Get-Content -LiteralPath $dp -Raw -Encoding UTF8
    $m = "## Writing Execution Notes"
    $idx = $c.IndexOf($m)
    if ($idx -lt 0) {
        $m = $env:MARKER
        $idx = $c.IndexOf($m)
    }
    if ($idx -gt 0) {
        $body = $c.Substring(0, $idx)
    } else {
        $body = $c
    }
    $cn = [regex]::Matches($body, '[\u4e00-\u9fff]').Count
    $en = [regex]::Matches($body, '[A-Za-z]').Count
    Write-Host ("Body Chinese chars: {0}" -f $cn)
    Write-Host ("Body English chars: {0}" -f $en)
}