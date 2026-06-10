# v3 step4: bucket x structure boost
$ErrorActionPreference = "Stop"
$dir = Split-Path -Parent $PSCommandPath

$bucketsIn = Join-Path $dir "..\v3_output\v3_buckets.csv"
$structIn  = Join-Path $dir "_v3_structures.txt"
$keysIn    = Join-Path $dir "_v3_bucket_keys.txt"
$tmplIn    = Join-Path $dir "_v3_step4_template.txt"
$outMd     = Join-Path $dir "..\v3_output\v3_cross_table.md"

# load bucket full keys
$bucketFullKeys = @(Get-Content $keysIn -Encoding UTF8 | Where-Object { $_ })

# load structures
$structs = @()
$structFull = @{}
$structShort = @()
foreach ($ln in (Get-Content $structIn -Encoding UTF8)) {
    if ($ln -match '^([^|]+)\|(.+)$') {
        $key = $Matches[1].Trim()
        $val = $Matches[2]
        $structs += @{ key=$key; pat=$val }
        $structShort += $key
    }
}
Write-Host ("[load] {0} structures" -f $structs.Count)

# load bucket data
$rows = Import-Csv $bucketsIn
Write-Host ("[load] {0} rows" -f $rows.Count)

# bucket = T1_制度机制 / T2_历史人物 / T3_国别地缘 / T4_思想命题
$shortMap = @{
    'T1' = $bucketFullKeys[0]
    'T2' = $bucketFullKeys[1]
    'T3' = $bucketFullKeys[2]
    'T4' = $bucketFullKeys[3]
}

# filter by main bucket (or sub1/sub2)
function Get-BucketRows([string]$b) {
    $out = @()
    foreach ($r in $rows) {
        if ($r.bucket -eq $b -or $r.sub1 -eq $b -or $r.sub2 -eq $b) {
            $out += $r
        }
    }
    return $out
}

# top 10% per bucket
function Get-TopRows($bucketRows) {
    $sorted = $bucketRows | Sort-Object reads -Descending
    $n = [math]::Max(1, [int]($sorted.Count * 0.10))
    return ($sorted | Select-Object -First $n)
}

# count pattern matches (any of 'pat' alternatives)
function Get-MatchCount($rows, [string]$patStr) {
    $pats = $patStr -split '\|'
    $cnt = 0
    foreach ($r in $rows) {
        foreach ($p in $pats) {
            $p = $p.Trim()
            if ($p -ne '' -and $r.title -match [regex]::Escape($p)) {
                $cnt++; break
            }
        }
    }
    return $cnt
}

# build cross table
$table = New-Object System.Collections.ArrayList
foreach ($b in @('T1','T2','T3','T4')) {
    $full = $shortMap[$b]
    $bRows = Get-BucketRows $full
    $tRows = Get-TopRows $bRows
    $totAll = $bRows.Count
    $totTop = $tRows.Count
    $row = [ordered]@{ bucket = $b + ' ' + $full.Substring(3) }
    foreach ($s in $structs) {
        $nA = Get-MatchCount $bRows $s.pat
        $nT = Get-MatchCount $tRows $s.pat
        $rA = if ($totAll -gt 0) { $nA / $totAll } else { 0 }
        $rT = if ($totTop -gt 0) { $nT / $totTop } else { 0 }
        $boost = if ($rA -gt 0) { $rT / $rA } else { 0 }
        $row[$s.key] = '{0}x ({1}/{2})' -f ([math]::Round($boost, 2)), $nT, $nA
    }
    [void]$table.Add([PSCustomObject]$row)
}

# render table markdown
$sb = New-Object System.Text.StringBuilder
[void]$sb.Append('| 桶 |')
foreach ($s in $structs) { [void]$sb.Append((' {0} |' -f $s.key)) }
[void]$sb.AppendLine()
[void]$sb.Append('|---|')
foreach ($s in $structs) { [void]$sb.Append('---:|') }
[void]$sb.AppendLine()
foreach ($r in $table) {
    [void]$sb.Append(('| {0} |' -f $r.bucket))
    foreach ($s in $structs) {
        [void]$sb.Append((' {0} |' -f $r.($s.key)))
    }
    [void]$sb.AppendLine()
}
$crossTable = $sb.ToString()

# best per bucket
$bestBucket = New-Object System.Collections.ArrayList
foreach ($r in $table) {
    $maxKey = ''
    $maxBoost = 0
    foreach ($s in $structs) {
        $v = $r.($s.key)
        if ($v -match '([\d\.]+)x') {
            $b = [double]$Matches[1]
            if ($b -gt $maxBoost) { $maxBoost = $b; $maxKey = $s.key }
        }
    }
    [void]$bestBucket.Add(('**{0}** → 最佳 {1} ({2}x)' -f $r.bucket, $maxKey, $maxBoost))
}
$bestPerBucket = ($bestBucket -join "`n")

# best per structure
$bestStruct = New-Object System.Collections.ArrayList
foreach ($s in $structs) {
    $maxBucket = ''
    $maxBoost = 0
    foreach ($r in $table) {
        $v = $r.($s.key)
        if ($v -match '([\d\.]+)x') {
            $b = [double]$Matches[1]
            if ($b -gt $maxBoost) { $maxBoost = $b; $maxBucket = $r.bucket }
        }
    }
    [void]$bestStruct.Add(('**{0}** → 最佳桶 {1} ({2}x)' -f $s.key, $maxBucket, $maxBoost))
}
$bestPerStruct = ($bestStruct -join "`n")

# key findings
$findings = @(Get-Content (Join-Path $dir "_v3_findings.txt") -Encoding UTF8 | Where-Object { $_ -and $_.Trim() -ne '' })
$keyFindings = ($findings -join "`n")

# render template
$tmpl = [System.IO.File]::ReadAllText($tmplIn, [System.Text.Encoding]::UTF8)
$tmpl = $tmpl.Replace('{{CROSS_TABLE}}', $crossTable)
$tmpl = $tmpl.Replace('{{BEST_PER_BUCKET}}', $bestPerBucket)
$tmpl = $tmpl.Replace('{{BEST_PER_STRUCTURE}}', $bestPerStruct)
$tmpl = $tmpl.Replace('{{KEY_FINDINGS}}', $keyFindings)
[System.IO.File]::WriteAllText($outMd, $tmpl, [System.Text.UTF8Encoding]::new($false))
$msg = "[write] " + $outMd
Write-Host $msg

Write-Host ""
Write-Host "DONE step4"
