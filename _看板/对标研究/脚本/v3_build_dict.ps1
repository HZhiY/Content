# v3 step3: build keyword dictionary
# 4 buckets x 4 word types, all sourced from step1+2 stats

$ErrorActionPreference = "Stop"
$dir = Split-Path -Parent $PSCommandPath

$tmplIn   = Join-Path $dir "_v3_dict_template.txt"
$anchorIn = Join-Path $dir "_v3_anchor_seeds.txt"
$readerIn = Join-Path $dir "_v3_reader_seeds.txt"
$topicIn  = Join-Path $dir "_v3_topic_seeds.txt"
$poiIn    = Join-Path $dir "_v3_poisons.txt"
$bucketsIn= Join-Path $dir "..\v3_output\v3_buckets.csv"
$poiCk    = Join-Path $dir "..\v3_output\v3_poison_check.csv"
$ngramIn  = Join-Path $dir "..\v3_output\v3_ngram_boost.csv"
$outMd    = Join-Path $dir "..\v3_output\v3_keyword_dict.md"
$outJson  = Join-Path $dir "..\v3_output\v3_keywords.json"

# ---- load per-bucket word sets ----
function Load-BucketDict($path) {
    $d = @{}
    foreach ($ln in (Get-Content $path -Encoding UTF8)) {
        if ($ln -match '^\s*([^:]+):(.+)$') {
            $b = $Matches[1].Trim()
            $words = @()
            foreach ($w in ($Matches[2] -split ',')) {
                $w = $w.Trim()
                if ($w) { $words += $w }
            }
            $d[$b] = $words
        }
    }
    return $d
}

$anchors = Load-BucketDict $anchorIn
$readers = Load-BucketDict $readerIn
$topics  = Load-BucketDict $topicIn
Write-Host ("[load] anchors: {0}, readers: {1}, topics: {2}" -f $anchors.Count, $readers.Count, $topics.Count)

# ---- validate each word against actual data ----
$buckets = Import-Csv $bucketsIn
$ngram = Import-Csv $ngramIn
$poiChk = Import-Csv $poiCk

# Build word -> {bucket, count_all, count_top, boost}
function Get-Stat([string]$word) {
    $nA = ($buckets | Where-Object { $_.title -match [regex]::Escape($word) }).Count
    $nT = ($buckets | Where-Object { $_.title -match [regex]::Escape($word) -and [int]$_.reads -ge 1000 } | Select-Object -First 100).Count  # rough head
    $row = $ngram | Where-Object { $_.ngram -eq $word -and [int]$_.n -eq $word.Length } | Select-Object -First 1
    if ($row) {
        return [PSCustomObject]@{
            word = $word
            count_all = [int]$row.count_all
            count_top = [int]$row.count_top
            boost = [double]$row.boost
        }
    }
    return [PSCustomObject]@{
        word = $word
        count_all = $nA
        count_top = 0
        boost = 0.0
    }
}

function Render-List($words) {
    $lines = @()
    foreach ($w in $words) {
        $s = Get-Stat $w
        $note = ''
        if ($s.boost -ge 1.2) { $note = '(头部+' + [math]::Round(($s.boost-1)*100,0) + '%)' }
        elseif ($s.boost -ge 0.95 -and $s.boost -lt 1.2) { $note = '(中性)' }
        elseif ($s.boost -gt 0 -and $s.boost -lt 0.95) { $note = '(慎用)' }
        else { $note = '(数据未验证)' }
        $lines += ('- ' + $w + ' ' + $note + ' — 全样本 ' + $s.count_all + ' / 头部 ' + $s.count_top)
    }
    return ($lines -join "`n")
}

# ---- global ban list ----
$globalBan = @()
foreach ($r in $poiChk) {
    if ($r.verdict -eq 'ban') {
        $globalBan += ('- ' + $r.word + ' — 全样本 ' + $r.n_all + ' / 头部 ' + $r.n_top + ' / boost ' + $r.boost)
    }
}
$globalBanMd = ($globalBan -join "`n")

# ---- per-bucket ban list (in this bucket, boost < 0.8) ----
function Get-BucketBan([string]$bucket) {
    $rows = @()
    foreach ($r in $buckets) {
        if ($r.bucket -eq $bucket -or $r.sub1 -eq $bucket -or $r.sub2 -eq $bucket) {
            $rows += $r
        }
    }
    # scan poison words
    $out = @()
    foreach ($r in $poiChk) {
        if ($r.verdict -ne 'ban') { continue }
        $w = $r.word
        $nB = ($rows | Where-Object { $_.title -match [regex]::Escape($w) }).Count
        if ($nB -gt 0) {
            $out += ('- ' + $w + ' — 在本桶出现 ' + $nB + ' 次，头部 0 次 / boost ' + $r.boost)
        }
    }
    if ($out.Count -eq 0) { return '_(本桶未发现毒词)_' }
    return ($out -join "`n")
}

# ---- render template ----
$tmpl = [System.IO.File]::ReadAllText($tmplIn, [System.Text.Encoding]::UTF8)

# load bucket keys from external file (PS 5.1 literal-key bug)
$keysFile = Join-Path $dir "_v3_bucket_keys.txt"
$bucketFullKeys = @(Get-Content $keysFile -Encoding UTF8 | Where-Object { $_ })
$shortToFull = @{}
foreach ($full in $bucketFullKeys) {
    $short = $full.Substring(0, 2)  # T1 / T2 / T3 / T4
    $shortToFull[$short] = $full
}
foreach ($b in @('T1','T2','T3','T4')) {
    $full = $shortToFull[$b]
    $tmpl = $tmpl.Replace('ZZANCHOR_' + $b + 'ZZ', (Render-List $anchors[$full]))
    $tmpl = $tmpl.Replace('ZZREADER_' + $b + 'ZZ', (Render-List $readers[$full]))
    $tmpl = $tmpl.Replace('ZZTOPIC_' + $b + 'ZZ',  (Render-List $topics[$full]))
    $tmpl = $tmpl.Replace('ZZBAN_' + $b + 'ZZ',    (Get-BucketBan $full))
}

$tmpl = $tmpl.Replace('ZZGLOBAL_BANZZ', $globalBanMd)

[System.IO.File]::WriteAllText($outMd, $tmpl, [System.Text.UTF8Encoding]::new($false))
$msg = "[write] " + $outMd
Write-Host $msg

# ---- write JSON ----
$json = New-Object System.Collections.ArrayList
foreach ($b in $buckets4) {
    [void]$json.Add(('"{0}": {{"anchor":[{1}],"reader":[{2}],"topic":[{3}]}}' -f $b,
        ('"' + ($anchors[$b] -join '","') + '"'),
        ('"' + ($readers[$b] -join '","') + '"'),
        ('"' + ($topics[$b] -join '","') + '"')
    ))
}
$jsonBody = '{' + (($json -join ',') -replace '^,','') + '}'
[System.IO.File]::WriteAllText($outJson, $jsonBody, [System.Text.UTF8Encoding]::new($false))
$msg = "[write] " + $outJson
Write-Host $msg

Write-Host ""
Write-Host "DONE step3"
