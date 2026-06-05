# 迁移脚本：把现有结构对齐到 _看板/目录约定.md
#
# 使用方法：
#   1. 在 PowerShell 中 cd 到 Content 根目录
#   2. 先跑 -DryRun 看看会做什么
#   3. 确认无误后跑正式模式
#
# 参数：
#   -DryRun    只打印计划，不实际执行（默认）
#   -Execute   实际执行
#   -Step <n>  只跑某一步（1-4）
#
# 示例：
#   .\迁移脚本.ps1 -DryRun
#   .\迁移脚本.ps1 -DryRun -Step 1
#   .\迁移脚本.ps1 -Execute -Step 1
#   .\迁移脚本.ps1 -Execute

[CmdletBinding()]
param(
    [switch]$DryRun = $true,
    [switch]$Execute,
    [ValidateRange(1,4)]
    [int]$Step = 0
)

$ErrorActionPreference = "Stop"
$root = $PSScriptRoot | Split-Path -Parent
Set-Location -LiteralPath $root

if ($Execute) { $DryRun = $false }

function Log {
    param([string]$msg, [string]$color = "Cyan")
    $prefix = if ($DryRun) { "[DRY-RUN] " } else { "[EXEC]    " }
    Write-Host "$prefix$msg" -ForegroundColor $color
}

function Do-Rename {
    param([string]$old, [string]$new)
    if (-not (Test-Path -LiteralPath $old)) {
        Log "  跳过（不存在）：$old" "Yellow"
        return
    }
    if (Test-Path -LiteralPath $new) {
        Log "  跳过（目标已存在）：$old -> $new" "Yellow"
        return
    }
    Log "  Rename: $old  ->  $new" "Green"
    if (-not $DryRun) {
        Rename-Item -LiteralPath $old -NewName $new
    }
}

function Do-Mkdir {
    param([string]$path)
    if (Test-Path -LiteralPath $path) {
        Log "  跳过（已存在）：$path" "Yellow"
        return
    }
    Log "  Mkdir:  $path" "Green"
    if (-not $DryRun) {
        New-Item -ItemType Directory -Path $path -Force | Out-Null
    }
}

function Do-Move {
    param([string]$src, [string]$dst)
    if (-not (Test-Path -LiteralPath $src)) {
        Log "  跳过（不存在）：$src" "Yellow"
        return
    }
    if (Test-Path -LiteralPath $dst) {
        Log "  跳过（目标已存在）：$dst" "Yellow"
        return
    }
    Log "  Move:   $src  ->  $dst" "Green"
    if (-not $DryRun) {
        Move-Item -LiteralPath $src -Destination $dst
    }
}

# ============================================================
# 步骤 1：低风险改名
# ============================================================
function Step1 {
    Log "===== 步骤 1：根目录 + _meta 改名 =====" "Magenta"

    Log "美国系列根目录改名（去'系列'）"
    Do-Rename "美国金融资本与产业资本系列" "美国金融资本与产业资本"

    Log "美国系列 _meta 改名"
    Do-Rename "美国金融资本与产业资本/_meta_美国金融资本与产业资本" "美国金融资本与产业资本/_meta"
}

# ============================================================
# 步骤 2：建立系列根目录骨架
# ============================================================
function Step2 {
    Log "===== 步骤 2：建立系列骨架（选题池、废弃、文章） =====" "Magenta"

    foreach ($series in @("中国历代政治得失", "日本金融系列", "美国金融资本与产业资本")) {
        Log "为 $series 建骨架"
        Do-Mkdir "$series/选题池"
        Do-Mkdir "$series/废弃"
        Do-Mkdir "$series/文章"
    }
}

# ============================================================
# 步骤 3：合并散落文章到 文章/
# ============================================================
function Step3 {
    Log "===== 步骤 3：合并散落文章到 文章/ =====" "Magenta"

    Log "中国历代政治得失：迁移 11 个文章文件夹"
    $items_cn = @(
        "01_皇权与相权如何长期拉扯",
        "01a_皇权与相权如何长期拉扯",
        "02_中央集权为什么越强治理成本也越高",
        "02a_王安石和司马光斗了一辈子，斗的其实是同一道无解题",
        "02b_中央集权为什么越强治理成本也越高",
        "03_科举真正解决的问题",
        "04_为什么制度坏在运行而不是设计",
        "06a_税收的政治结盟",
        "06b_白银化与普通人",
        "07_郡县制真正解决了什么问题",
        "09_地方权力该大还是小",
        "11_御史真正的作用，不是纠错，而是证明系统开始失灵"
    )
    # 注意：09_五代十国的根源 需要确认编号（先不迁移）
    foreach ($item in $items_cn) {
        Do-Move "中国历代政治得失/$item" "中国历代政治得失/文章/$item"
    }

    Log "美国金融资本与产业资本：迁移 4 个文章文件夹"
    $items_us = @(
        "01_铁路把华尔街养大后_华尔街发现金融比修铁路更赚钱",
        "02_1865年那场没人记得的税收如何重塑了美国银行",
        "03_汉密尔顿的债务哲学为何赢了",
        "特朗普与资本之争"
    )
    foreach ($item in $items_us) {
        Do-Move "美国金融资本与产业资本/$item" "美国金融资本与产业资本/文章/$item"
    }
    Do-Rename "美国金融资本与产业资本/文章/特朗普与资本之争" "美国金融资本与产业资本/文章/特_特朗普与资本之争"

    Log "日本金融系列：需要手工处理（结构最复杂，见迁移计划.md）" "Yellow"
    Log "  - 10_日本不是最大债主了... 是单文件不是文件夹"
    Log "  - 03/04/05/06/07 已发布但只有 articles/ 里的'大纲'"
    Log "  - 需要先确认每篇的实际状态"
}

# ============================================================
# 步骤 4：单篇文章文件夹内文件统一
# ============================================================
function Step4 {
    Log "===== 步骤 4：单篇文章文件夹内文件统一 =====" "Magenta"
    Log "  这一步需要逐文件夹手工处理，本脚本不自动跑" "Yellow"
    Log "  见 _看板/迁移计划.md 步骤 4 节" "Yellow"
}

# ============================================================
# 入口
# ============================================================
if ($Step -eq 0 -or $Step -eq 1) { Step1 }
if ($Step -eq 0 -or $Step -eq 2) { Step2 }
if ($Step -eq 0 -or $Step -eq 3) { Step3 }
if ($Step -eq 0 -or $Step -eq 4) { Step4 }

Log "" "White"
Log "完成。提醒：" "Cyan"
Log "1. 如果用了 -DryRun，没改任何文件，再跑一次 -Execute 真正执行" "Cyan"
Log "2. 跑完后建议用 git status 看变更" "Cyan"
Log "3. 遇到错误用 git reset --hard 回滚" "Cyan"
