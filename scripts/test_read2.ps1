$path = "c:\Users\27649\Documents\myproject\Content\巴基斯坦如何把世界变成自己的资源\01_不是夹缝求生，而是管理不对称\06_修订与发布\修订稿 v1.md"
Write-Host ("Test 1: Get-Content -Raw")
try {
    $content = Get-Content -Path $path -Raw
    Write-Host ("  Length: " + $content.Length)
    Write-Host "  First 100 chars:"
    Write-Host ("  " + $content.Substring(0, [Math]::Min(100, $content.Length)))
} catch {
    Write-Host ("  Error: " + $_.Exception.Message)
}

Write-Host ""
Write-Host "Test 2: Get-Content -Encoding UTF8"
try {
    $content = Get-Content -Path $path -Encoding UTF8
    Write-Host ("  Count: " + $content.Count)
    Write-Host "  First line: $($content[0])")
} catch {
    Write-Host ("  Error: " + $_.Exception.Message)
}

Write-Host ""
Write-Host "Test 3: Get-Content -Encoding Default"
try {
    $content = Get-Content -Path $path
    Write-Host ("  Count: " + $content.Count)
    Write-Host "  First line: $($content[0])")
} catch {
    Write-Host ("  Error: " + $_.Exception.Message)
}

Write-Host ""
Write-Host "Test 4: [IO.File]::ReadAllText"
try {
    $content = [System.IO.File]::ReadAllText($path)
    Write-Host ("  Length: " + $content.Length)
} catch {
    Write-Host ("  Error: " + $_.Exception.Message)
}

Write-Host ""
Write-Host "Test 5: [IO.File]::ReadAllText with UTF8"
try {
    $content = [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)
    Write-Host ("  Length: " + $content.Length)
} catch {
    Write-Host ("  Error: " + $_.Exception.Message)
}

Write-Host ""
Write-Host "Test 6: short ASCII path"
$shortPath = "c:\Users\27649\Documents\myproject\Content\scripts\test_cmd_read.ps1"
try {
    $content = [System.IO.File]::ReadAllText($shortPath)
    Write-Host ("  Length: " + $content.Length)
} catch {
    Write-Host ("  Error: " + $_.Exception.Message)
}
