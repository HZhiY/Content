# Use only ASCII chars in script to avoid ANSI parse issues
# Use short ASCII path with copy

$src = "c:\Users\27649\Documents\myproject\Content\巴基斯坦如何把世界变成自己的资源\01_不是夹缝求生，而是管理不对称\06_修订与发布\修订稿 v1.md"
$dst = "c:\Users\27649\Documents\myproject\Content\scripts\_rev1_copy.md"

# Copy via cmd
cmd /c "copy `"$src`" `"$dst`"" | Out-Null

Write-Host "Test 1: short path Get-Content"
try {
    $content = Get-Content -Path $dst
    Write-Host ("  Lines: " + $content.Count)
    Write-Host ("  First line: " + $content[0])
} catch {
    Write-Host ("  Error: " + $_.Exception.Message)
}

Write-Host ""
Write-Host "Test 2: [IO.File]::ReadAllText short path"
try {
    $content = [System.IO.File]::ReadAllText($dst, [System.Text.Encoding]::UTF8)
    Write-Host ("  Length: " + $content.Length)
    Write-Host ("  First 80: " + $content.Substring(0, [Math]::Min(80, $content.Length)))
} catch {
    Write-Host ("  Error: " + $_.Exception.Message)
}
