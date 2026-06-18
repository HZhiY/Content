$utf8 = New-Object System.Text.UTF8Encoding($false, $true)

$srcPath = $args[0]

$content = [System.IO.File]::ReadAllText($srcPath, $utf8)
$lines = $content -split "`r?`n"

# Print all ## lines with character codes (fixed)
Write-Host "All ## lines:"
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i].StartsWith("##")) {
        $line = $lines[$i]
        $codes = ""
        for ($j = 0; $j -lt $line.Length; $j++) {
            $ch = $line[$j]
            $num = [int]$ch
            $hex = "{0:X4}" -f $num
            $codes += "U+" + $hex + " "
        }
        Write-Host ("  [" + $i + "] " + $line + "  | " + $codes)
    }
}
