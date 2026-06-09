# 相对路径方式 - 在工作目录运行
Set-Location (Split-Path $MyInvocation.MyCommand.Path -Parent)
$file = '.\03_草稿\草稿.md'

Write-Host ('FILE_PATH: ' + (Resolve-Path $file).Path)
Write-Host ('FILE_EXISTS: ' + (Test-Path $file))

if (-not (Test-Path $file)) {
    Write-Host 'FILE NOT FOUND'
    exit 1
}

$bytes = [System.IO.File]::ReadAllBytes((Resolve-Path $file).Path)
$content = [System.Text.Encoding]::UTF8.GetString($bytes)
$totalNoSpace = ($content -replace '\s','').Length
$totalWithSpace = $content.Length
Write-Host ('TOTAL_NO_SPACE: ' + $totalNoSpace)
Write-Host ('TOTAL_WITH_SPACE: ' + $totalWithSpace)

$paras = New-Object System.Collections.Generic.List[string]
$lines = $content -split "`n"
$current = New-Object System.Text.StringBuilder
foreach ($line in $lines) {
    $trim = $line.TrimEnd()
    if ($trim.Length -eq 0) {
        $text = $current.ToString().Trim()
        if ($text.Length -gt 0 -and $text -notmatch '^#' -and $text -notmatch '^---' -and $text -notmatch '^\*') {
            $paras.Add($text)
        }
        [void]$current.Clear()
    } else {
        [void]$current.AppendLine($line)
    }
}
$last = $current.ToString().Trim()
if ($last.Length -gt 0 -and $last -notmatch '^#' -and $last -notmatch '^---' -and $last -notmatch '^\*') {
    $paras.Add($last)
}

$maxLen = 0
$maxIdx = -1
$over100 = 0
$over80 = 0
$over60 = 0
for ($i = 0; $i -lt $paras.Count; $i++) {
    $l = $paras[$i].Length
    if ($l -gt $maxLen) { $maxLen = $l; $maxIdx = $i }
    if ($l -gt 100) { $over100++ }
    if ($l -gt 80) { $over80++ }
    if ($l -gt 60) { $over60++ }
}
Write-Host ('PARAGRAPH_COUNT: ' + $paras.Count)
Write-Host ('MAX_LEN: ' + $maxLen + ' (idx=' + $maxIdx + ')')
Write-Host ('OVER_60: ' + $over60)
Write-Host ('OVER_80: ' + $over80)
Write-Host ('OVER_100: ' + $over100)
Write-Host '---PARAGRAPHS_OVER_60---'
for ($i = 0; $i -lt $paras.Count; $i++) {
    $l = $paras[$i].Length
    if ($l -gt 60) {
        $preview = $paras[$i]
        if ($preview.Length -gt 80) { $preview = $preview.Substring(0, 80) + '...' }
        Write-Host ('[' + $i + ' LEN=' + $l + '] ' + $preview)
    }
}
