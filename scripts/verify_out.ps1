$utf8 = New-Object System.Text.UTF8Encoding($false, $true)
$p = $args[0]
$content = [System.IO.File]::ReadAllText($p, $utf8)
Write-Host ("Output file pure body length: " + $content.Length)
Write-Host ("First 80 chars: " + $content.Substring(0, [Math]::Min(80, $content.Length)))
