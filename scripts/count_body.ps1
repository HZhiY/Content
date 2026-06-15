[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
$draftPath = $env:DRAFT_PATH
if (Test-Path -LiteralPath $draftPath) {
    $content = Get-Content -LiteralPath $draftPath -Raw -Encoding UTF8
    # 鎵惧嚭 "## 鍐欎綔鎵ц璇存槑" 涔嬪墠鐨勫唴瀹癸紙姝ｆ枃閮ㄥ垎锛?    $marker = "## 鍐欎綔鎵ц璇存槑"
    $idx = $content.IndexOf($marker)
    if ($idx -gt 0) {
        $body = $content.Substring(0, $idx)
    } else {
        $body = $content
    }
    $cn = [regex]::Matches($body, '[\u4e00-\u9fff]').Count
    $en = [regex]::Matches($body, '[A-Za-z]').Count
    Write-Host ("姝ｆ枃閮ㄥ垎锛堜笉鍚啓浣滄墽琛岃鏄庯級涓枃瀛楃鏁? {0}" -f $cn)
    Write-Host ("姝ｆ枃閮ㄥ垎鑻辨枃瀛楃鏁? {0}" -f $en)
    # 鎵惧嚭 "## 寮曡█" 鍒?"## 寮曡█" 涔嬪墠鐨勯儴鍒?+ 鐪嬬湅浠?"## 寮曡█" 鍒?"---" (鍚庨潰鍗曠嫭鐨? 鐨勯儴鍒?    # 瀹為檯姝ｆ枃鏄細鏍囬銆佸紩瑷€銆佷竴銆佷簩銆佷笁銆佸洓銆佺粨灏俱€佸皬灏惧反銆佺浉鍏虫枃绔?    # 涓嶅惈 "## 鍐欎綔鎵ц璇存槑" 涔嬪悗鐨勫唴瀹?}