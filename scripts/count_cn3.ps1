chcp 65001 | Out-Null
$folder = [System.IO.Path]::GetFullPath($args[0])
$file = $args[1]
$path = Join-Path $folder $file
Write-Host "Path: $path"
$content = [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)
$cn = [regex]::Matches($content, '[\u4e00-\u9fff]')
$total = $content.Length
Write-Host ('Total chars: ' + $total)
Write-Host ('Chinese chars: ' + $cn.Count)
