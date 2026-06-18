# 通过 cmd 的 type 命令读取文件字节，然后解码
$cmdOutput = cmd /c "type `"c:\Users\27649\Documents\myproject\Content\巴基斯坦如何把世界变成自己的资源\01_不是夹缝求生，而是管理不对称\06_修订与发布\修订稿 v1.md`""
$text = $cmdOutput -join "`n"

Write-Host ("Read text length: " + $text.Length)
Write-Host "First 200 chars:"
Write-Host $text.Substring(0, [Math]::Min(200, $text.Length))
