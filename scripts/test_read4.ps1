$src = "c:\Users\27649\Documents\myproject\Content\巴基斯坦如何把世界变成自己的资源\01_不是夹缝求生，而是管理不对称\06_修订与发布\修订稿 v1.md"
$dst = "c:\Users\27649\Documents\myproject\Content\scripts\_rev1_copy.md"

# Try direct copy
try {
    [System.IO.File]::Copy($src, $dst, $true)
    Write-Host "Copy OK"
} catch {
    Write-Host ("Copy error: " + $_.Exception.Message)
    # Try via Read+Write
    try {
        $content = [System.IO.File]::ReadAllBytes($src)
        [System.IO.File]::WriteAllBytes($dst, $content)
        Write-Host "Read+Write OK"
    } catch {
        Write-Host ("R+W error: " + $_.Exception.Message)
    }
}

# Now read short
try {
    $content = [System.IO.File]::ReadAllText($dst, [System.Text.Encoding]::UTF8)
    Write-Host ("Length: " + $content.Length)
    Write-Host ("First 100: " + $content.Substring(0, [Math]::Min(100, $content.Length)))
} catch {
    Write-Host ("Read error: " + $_.Exception.Message)
}
