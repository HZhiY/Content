# v3 step2 - all CJK literals from external files
$ErrorActionPreference = "Stop"
$dir = Split-Path -Parent $PSCommandPath

$sampleIn  = Join-Path $dir "..\v3_output\v3_samples_all.csv"
$rulesIn   = Join-Path $dir "_v3_bucket_rules.txt"
$seedsIn   = Join-Path $dir "_v3_tag_seeds.txt"
$defsIn    = Join-Path $dir "_v3_bucket_defs.txt"
$tmplIn    = Join-Path $dir "_v3_def_template.txt"
$subHdrIn  = Join-Path $dir "_v3_subheader.txt"
$outBuckets= Join-Path $dir "..\v3_output\v3_buckets.csv"
$outDefs   = Join-Path $dir "..\v3_output\v3_bucket_definition.md"

$rules = @{}
foreach ($ln in (Get-Content $rulesIn -Encoding UTF8)) {
    if ($ln -match '^\s*([^;]+);(.+)$') {
        $rules[$Matches[1].Trim()] = $Matches[2].Trim()
    }
}

$seeds = @{}
foreach ($ln in (Get-Content $seedsIn -Encoding UTF8)) {
    if ($ln -match '^\s*([^:]+):(.+)$') {
        $bucket = $Matches[1].Trim()
        foreach ($w in ($Matches[2] -split ',')) {
            $w = $w.Trim()
            if ($w) { $seeds[$w] = $bucket }
        }
    }
}

$defs = @{}
foreach ($ln in (Get-Content $defsIn -Encoding UTF8)) {
    if ($ln -match '^\s*([^|]+)\|(.+)$') {
        $defs[$Matches[1].Trim()] = $Matches[2].Trim()
    }
}

# subheader lines
$subLines = @(Get-Content $subHdrIn -Encoding UTF8 | Where-Object { $_ })
$SUB_BUCKET = $subLines[0]   # "###"
$SUB_TABLE  = $subLines[1]   # "| 账号 | 阅读 | 标题 |"
$SUB_RULE   = $subLines[2]   # "|---|---:|---|"

$rows = Import-Csv $sampleIn
$log = "[load] samples: " + $rows.Count
Write-Host $log

function Get-Buckets {
    param([string]$title, [string]$account)
    $scores = @{
        'T1_制度机制' = 0
        'T2_历史人物' = 0
        'T3_国别地缘' = 0
        'T4_思想命题' = 0
    }
    if ($rules.ContainsKey($account)) {
        $b = $rules[$account]
        $scores[$b] += 2
    }
    foreach ($w in $seeds.Keys) {
        if ($title -match [regex]::Escape($w)) {
            $b = $seeds[$w]
            $scores[$b] += 1
        }
    }
    $sorted = $scores.GetEnumerator() | Sort-Object Value -Descending
    $main = $sorted[0].Key
    $sub1 = ''
    $sub2 = ''
    if ($sorted.Count -gt 1 -and $sorted[1].Value -gt 0) { $sub1 = $sorted[1].Key }
    if ($sorted.Count -gt 2 -and $sorted[2].Value -gt 0) { $sub2 = $sorted[2].Key }
    return @{ main=$main; sub1=$sub1; sub2=$sub2 }
}

$out = New-Object System.Collections.ArrayList
foreach ($r in $rows) {
    $b = Get-Buckets $r.title $r.account
    [void]$out.Add([PSCustomObject]@{
        account = $r.account
        title   = $r.title
        reads   = [int]$r.reads
        bucket  = $b.main
        sub1    = $b.sub1
        sub2    = $b.sub2
    })
}

$sb = New-Object System.Text.StringBuilder
[void]$sb.Append([char]0xFEFF)
[void]$sb.AppendLine('account,title,reads,bucket,sub1,sub2')
foreach ($r in $out) {
    $t = $r.title -replace '"','""'
    [void]$sb.AppendLine(('"{0}","{1}",{2},"{3}","{4}","{5}"' -f $r.account, $t, $r.reads, $r.bucket, $r.sub1, $r.sub2))
}
[System.IO.File]::WriteAllText($outBuckets, $sb.ToString(), [System.Text.UTF8Encoding]::new($false))
$log = "[write] " + $outBuckets + "  (" + $out.Count + " rows)"
Write-Host $log

# ---- bucket table ----
$byBucket = $out | Group-Object bucket
$btbl = New-Object System.Collections.ArrayList
foreach ($bg in $byBucket) {
    $n = $bg.Count
    $pct = [math]::Round($n * 100.0 / $out.Count, 1)
    $sorted = $bg.Group | Sort-Object reads
    $mid = $sorted[[int]($sorted.Count/2)].reads
    $topN = [math]::Max(1, [int]($n * 0.10))
    $topAvg = [int](($bg.Group | Sort-Object reads -Descending | Select-Object -First $topN | Measure-Object reads -Average).Average)
    [void]$btbl.Add(('| {0} | {1} | {2} | {3}% | {4} | {5} |' -f $bg.Name, $defs[$bg.Name], $n, $pct, $mid, $topAvg))
}
$bucketTable = ($btbl -join "`n")

# ---- account -> bucket table ----
$atbl = New-Object System.Collections.ArrayList
$byAcct = $out | Group-Object account
foreach ($ag in $byAcct) {
    $mainB = ($ag.Group | Group-Object bucket | Sort-Object Count -Descending | Select-Object -First 1).Name
    [void]$atbl.Add(('| {0} | {1} | {2} |' -f $ag.Name, $mainB, $ag.Count))
}
$acctTable = ($atbl -join "`n")

# ---- bucket details (header lines from external file) ----
$details = New-Object System.Collections.ArrayList
foreach ($bg in $byBucket) {
    $head = $SUB_BUCKET + ' ' + $bg.Name + ':' + $defs[$bg.Name]
    [void]$details.Add($head)
    [void]$details.Add('')
    [void]$details.Add($SUB_TABLE)
    [void]$details.Add($SUB_RULE)
    $top = $bg.Group | Sort-Object reads -Descending | Select-Object -First 5
    foreach ($r in $top) {
        $t = $r.title -replace '\|','\|'
        [void]$details.Add(('| {0} | {1} | {2} |' -f $r.account, $r.reads, $t))
    }
    [void]$details.Add('')
}
$bucketDetails = ($details -join "`n")

# ---- template ----
$tmpl = [System.IO.File]::ReadAllText($tmplIn, [System.Text.Encoding]::UTF8)
$tmpl = $tmpl.Replace('{{BUCKET_TABLE}}', $bucketTable)
$tmpl = $tmpl.Replace('{{ACCT_TABLE}}', $acctTable)
$tmpl = $tmpl.Replace('{{BUCKET_DETAILS}}', $bucketDetails)
[System.IO.File]::WriteAllText($outDefs, $tmpl, [System.Text.UTF8Encoding]::new($false))
$log = "[write] " + $outDefs
Write-Host $log

Write-Host ""
Write-Host "DONE step2"
