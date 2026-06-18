$utf8 = New-Object System.Text.UTF8Encoding($false, $true)
$p = $args[0]
$bytes = [System.IO.File]::ReadAllBytes($p)
Write-Host ("Bytes: " + $bytes.Length)
