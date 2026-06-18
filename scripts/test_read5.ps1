# Use only ASCII in PowerShell source. Chinese chars in file content, OK.
# Read source file using .NET with explicit UTF-8 decode
$utf8 = New-Object System.Text.UTF8Encoding($false, $true)

# Try .NET IO directly
$src = [System.IO.Path]::GetFullPath($args[0])
$dst = [System.IO.Path]::GetFullPath($args[1])
$phrasesPath = [System.IO.Path]::GetFullPath($args[2])
$checksPath = [System.IO.Path]::GetFullPath($args[3])

Write-Host ("src: " + $src)
Write-Host ("dst: " + $dst)
Write-Host ("phrases: " + $phrasesPath)

# Read source
$content = [System.IO.File]::ReadAllText($src, $utf8)
Write-Host ("Read content length: " + $content.Length)

# Copy via .NET IO
$bytes = [System.IO.File]::ReadAllBytes($src)
[System.IO.File]::WriteAllBytes($dst, $bytes)
Write-Host "Copy OK"
