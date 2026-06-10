# v3 step1
# 所有中文路径字面量从外部 _v3_filelist.txt 加载
# 词表从 _v3_stopwords.txt / _v3_poisons.txt 加载

$ErrorActionPreference = "Stop"
$dir = Split-Path -Parent $PSCommandPath

$flistPath  = Join-Path $dir "_v3_filelist.txt"
$stopPath   = Join-Path $dir "_v3_stopwords.txt"
$poiPath    = Join-Path $dir "_v3_poisons.txt"

$stopWords = Get-Content -LiteralPath $stopPath -Encoding UTF8 | Where-Object { $_ -and $_.Trim() -ne '' }
$poisons   = Get-Content -LiteralPath $poiPath  -Encoding UTF8 | Where-Object { $_ -and $_.Trim() -ne '' }

$stopSet = @{}
foreach ($s in $stopWords) { $stopSet[$s.Trim()] = $true }

$fileLines = [System.IO.File]::ReadAllLines($flistPath, [System.Text.Encoding]::UTF8)
$allRows = @()
foreach ($rel in $fileLines) {
    $rel = $rel.Trim()
    if (-not $rel) { continue }
    $abs = [System.IO.Path]::GetFullPath((Join-Path $dir ("..\..\..\" + $rel)))
    $base = [System.IO.Path]::GetFileNameWithoutExtension($abs)
    $parts = $base -split "_"
    $account = $parts[-1]
    $msg = "[parse] " + $account + "  <- " + $rel
    Write-Host $msg

    $lines = [System.IO.File]::ReadAllLines($abs, [System.Text.Encoding]::UTF8)
    foreach ($ln in $lines) {
        if ($ln -match '^\|\s*\d+\s*\|\s*(.+?)\s*\|\s*(.+?)\s*\|\s*(\d+)\s*\|') {
            $title = $Matches[1] -replace '\\\|','|'
            $readsNum = [int]$Matches[3]
            $allRows += [PSCustomObject]@{ account=$account; title=$title; reads=$readsNum }
        }
    }
}
$msg = "[parse] total rows: " + $allRows.Count
Write-Host $msg

function Get-NGrams([string]$text, [int]$n) {
    $t = ''
    foreach ($c in $text.ToCharArray()) {
        $cp = [int]$c
        if ($cp -ge 19968 -and $cp -le 40869) { $t += $c }
    }
    if ($t.Length -lt $n) { return @() }
    $out = New-Object System.Collections.ArrayList
    for ($i=0; $i -le $t.Length - $n; $i++) {
        [void]$out.Add($t.Substring($i, $n))
    }
    return $out
}

$byAcct = $allRows | Group-Object account
$topRows = @()
foreach ($g in $byAcct) {
    $sorted = $g.Group | Sort-Object reads -Descending
    $topN = [math]::Max(1, [int]($sorted.Count * 0.10))
    $topRows += $sorted | Select-Object -First $topN
}
$msg = "[top] top10% rows: " + $topRows.Count
Write-Host $msg

function Count-Grams($rows, [int]$minLen, [int]$maxLen) {
    $bag = @{}
    foreach ($r in $rows) {
        for ($n=$minLen; $n -le $maxLen; $n++) {
            foreach ($g in (Get-NGrams $r.title $n)) {
                if ($bag.ContainsKey($g)) { $bag[$g]++ } else { $bag[$g] = 1 }
            }
        }
    }
    return $bag
}

Write-Host "[count] all n-grams..."
$allBag = Count-Grams $allRows 1 3
Write-Host "[count] top n-grams..."
$topBag = Count-Grams $topRows 1 3

function Pass-Filter([string]$g, [int]$n) {
    if ($g.Length -ne $n) { return $false }
    foreach ($c in $g.ToCharArray()) {
        $cp = [int]$c
        if ($cp -lt 19968 -or $cp -gt 40869) { return $false }
    }
    if ($stopSet.ContainsKey($g)) { return $false }
    return $true
}

# 写 CSV：每列加 BOM 让 Excel 可识别
function Export-CsvBom($rows, [string]$outPath) {
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.Append([char]0xFEFF)
    if ($rows.Count -gt 0) {
        $props = $rows[0].PSObject.Properties.Name
        [void]$sb.AppendLine(($props -join ','))
        foreach ($r in $rows) {
            $vals = @()
            foreach ($p in $props) { $vals += ('"' + ($r.$p -replace '"','""') + '"') }
            [void]$sb.AppendLine(($vals -join ','))
        }
    }
    [System.IO.File]::WriteAllText($outPath, $sb.ToString(), [System.Text.UTF8Encoding]::new($false))
}

function Export-Grams($bag, [int]$minOccur, [string]$outPath) {
    $rows = New-Object System.Collections.ArrayList
    foreach ($k in $bag.Keys) {
        foreach ($n in 1..3) {
            if (Pass-Filter $k $n) {
                $v = $bag[$k]
                if ($v -ge $minOccur) {
                    [void]$rows.Add([PSCustomObject]@{ ngram=$k; n=$n; count=$v })
                }
            }
        }
    }
    $rows = $rows | Sort-Object count -Descending
    Export-CsvBom $rows $outPath
    $msg = "[write] " + $outPath + "  (" + $rows.Count + " rows)"
    Write-Host $msg
}

# 输出到脚本目录的 data 子目录
$outRoot = Join-Path $dir "..\data"
$acctDir = Join-Path $outRoot "v3_account_words"
if (-not (Test-Path $acctDir)) { New-Item -ItemType Directory -Path $acctDir | Out-Null }

Export-Grams $allBag 2 (Join-Path $outRoot "v3_wordfreq_all.csv")
Export-Grams $topBag 2 (Join-Path $outRoot "v3_wordfreq_top.csv")

foreach ($g in $byAcct) {
    $safe = $g.Name -replace '[\/:*?"<>|]', '_'
    $outP = Join-Path $acctDir ("v3_words_" + $safe + ".csv")
    $bag2 = Count-Grams $g.Group 1 3
    $rows = New-Object System.Collections.ArrayList
    foreach ($k in $bag2.Keys) {
        foreach ($n in 1..3) {
            if (Pass-Filter $k $n) {
                $v = $bag2[$k]
                if ($v -ge 2) {
                    [void]$rows.Add([PSCustomObject]@{ ngram=$k; n=$n; count=$v })
                }
            }
        }
    }
    $rows = $rows | Sort-Object count -Descending
    Export-CsvBom $rows $outP
    $msg = "[write] " + $outP + "  (" + $rows.Count + " rows)"
    Write-Host $msg
}

$totalAll = $allRows.Count
$totalTop = $topRows.Count
$banOut = Join-Path $outRoot "v3_poison_check.csv"
$banRows = New-Object System.Collections.ArrayList
foreach ($w in $poisons) {
    $w = $w.Trim()
    if ($w -eq '') { continue }
    $nAll = ($allRows | Where-Object { $_.title -match [regex]::Escape($w) }).Count
    $nTop = ($topRows | Where-Object { $_.title -match [regex]::Escape($w) }).Count
    $rateAll = if ($totalAll -gt 0) { $nAll / $totalAll } else { 0 }
    $rateTop = if ($totalTop -gt 0) { $nTop / $totalTop } else { 0 }
    $boost = if ($rateAll -gt 0) { $rateTop / $rateAll } else { 0 }
    $verdict = if ($boost -lt 0.8) { 'ban' } elseif ($boost -lt 0.95) { 'careful' } elseif ($boost -lt 1.1) { 'neutral' } else { 'ok' }
    [void]$banRows.Add([PSCustomObject]@{
        word=$w; n_all=$nAll; n_top=$nTop;
        rate_all=[math]::Round($rateAll,4);
        rate_top=[math]::Round($rateTop,4);
        boost=[math]::Round($boost,3);
        verdict=$verdict
    })
}
$banRows = $banRows | Sort-Object boost
Export-CsvBom $banRows $banOut
$msg = "[write] " + $banOut + "  (" + $banRows.Count + " rows)"
Write-Host $msg

$ngramOut = Join-Path $outRoot "v3_ngram_boost.csv"
$combRows = New-Object System.Collections.ArrayList
foreach ($n in 1..3) {
    foreach ($g in $allBag.Keys) {
        if (-not (Pass-Filter $g $n)) { continue }
        $a = $allBag[$g]
        if ($a -lt 3) { continue }
        if (-not $topBag.ContainsKey($g)) { continue }
        $t = $topBag[$g]
        $rateA = $a / $totalAll
        $rateT = $t / $totalTop
        $boost = if ($rateA -gt 0) { $rateT / $rateA } else { 0 }
        [void]$combRows.Add([PSCustomObject]@{
            ngram=$g; n=$n; count_all=$a; count_top=$t;
            rate_all=[math]::Round($rateA,4);
            rate_top=[math]::Round($rateT,4);
            boost=[math]::Round($boost,3)
        })
    }
}
$combRows = $combRows | Sort-Object count_all -Descending
Export-CsvBom $combRows $ngramOut
$msg = "[write] " + $ngramOut + "  (" + $combRows.Count + " rows)"
Write-Host $msg

$sampleOut = Join-Path $outRoot "v3_samples_all.csv"
$sampleRows = $allRows | Sort-Object account, reads -Descending | Select-Object account, title, reads
Export-CsvBom $sampleRows $sampleOut
$msg = "[write] " + $sampleOut + "  (" + $sampleRows.Count + " rows)"
Write-Host $msg

Write-Host ""
Write-Host "DONE step1"
