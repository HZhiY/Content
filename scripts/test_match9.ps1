Write-Host ("Test 引言 length: " + "引言".Length)
Write-Host ("Test 引言 codes: U+" + "{0:X4}" -f [int]"引言"[0] + " U+" + "{0:X4}" -f [int]"引言"[1])

$line = "## 引言"
$codes = ""
for ($j = 0; $j -lt $line.Length; $j++) {
    $codes += "U+" + ("{0:X4}" -f [int]$line[$j]) + " "
}
Write-Host ("## 引言 codes: " + $codes)
