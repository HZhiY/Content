#!/usr/bin/env python3
"""
文章流水线专家批量创建脚本
把 _工作流/03_subagents/ 下的 27 个 subagent 一对一转换为 WorkBuddy Agent 专家。

步骤：
1. 调用 init_expert.py × 27 创建目录模板
2. 替换 .codebuddy-plugin/plugin.json 中的 [TODO] 为实际元数据
3. 复制 subagent 源文件到 agents/{name}.md 并替换 frontmatter
4. 替换 README.md 占位符

然后调用 validate_expert.py 和 register_expert.py
"""
import os
import re
import sys
import io
import json
import shutil
import subprocess
from pathlib import Path

# Windows GBK 编码对 emoji 不友好；强制 UTF-8
if sys.platform == "win32":
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding="utf-8", errors="replace")

# === 路径 ===
EXPERT_DIR = Path("C:/Users/27649/.workbuddy/plugins/marketplaces/my-experts/plugins").expanduser().resolve()
SUBAGENT_DIR = Path("c:/Users/27649/Documents/myproject/content/_工作流/03_subagents")
INIT_SCRIPT = Path("C:/Users/27649/AppData/Local/Programs/WorkBuddy/resources/app.asar.unpacked/resources/builtin-skills/expert-manager/scripts/init_expert.py")
VALIDATE_SCRIPT = INIT_SCRIPT.parent / "validate_expert.py"
REGISTER_SCRIPT = INIT_SCRIPT.parent / "register_expert.py"

# session-id 用于 register 时写入 .created-by-session
SESSION_ID = "article-pipeline-20260622"

# === 27 个专家的元数据 ===
# name: kebab-case 专家目录名（去掉 subagent 的数字前缀）
# src: 对应 subagent 源文件名
# zh_display / en_display: 显示名
# zh_prof / en_prof: 职业头衔
# zh_desc: 中文描述，40-50 字
# en_desc: 英文描述
# tags: [(en, zh), (en, zh), (en, zh)] 固定 3 个
# quick_prompts: [(en, zh), (en, zh), (en, zh)] 固定 3 个

EXPERTS = [
    # === 0. 项目初始化 ===
    {
        "name": "project-setup",
        "src": "00-project-setup.md",
        "zh_display": "项目架构员",
        "en_display": "Project Setup Architect",
        "zh_prof": "内容项目架构员",
        "en_prof": "Content Project Architect",
        "zh_desc": "为单篇文章创建独立项目包，含目录结构、README、总计划，是文章流水线的起点与基础设施搭建者。",
        "en_desc": "Creates isolated article project packages: folder plan, README, master plan and directory scaffold—the launchpad of the article pipeline.",
        "tags": [("Project Setup", "项目初始化"), ("Directory Scaffold", "目录结构"), ("Infrastructure", "基础设施")],
        "quick_prompts": [
            ("Initialize a new article project package for: <topic>", "为下面选题创建独立项目包：<标题>"),
            ("Show me the standard folder plan for an article in this series", "展示当前系列文章的标准目录结构"),
            ("Create README.md and 总计划.md for the new article", "为新文章生成 README.md 和 总计划.md"),
        ],
    },
    # === 1. 资料研究链 ===
    {
        "name": "source-research",
        "src": "01-source-research.md",
        "zh_display": "资料研究员",
        "en_display": "Source Researcher",
        "zh_prof": "原始资料研究员",
        "en_prof": "Primary Source Researcher",
        "zh_desc": "为当前文章做第一轮资料研究，搜集来源、标注口径差异、标\"待补资料\"，不写正文不生洞察。",
        "en_desc": "Performs isolated research for one article—gathers sources, notes conflicting accounts, marks unknowns. Never writes the article body.",
        "tags": [("Source Gathering", "资料搜集"), ("Citation Tracing", "来源追溯"), ("Discrepancy Notes", "口径标注")],
        "quick_prompts": [
            ("Research the topic '<topic>' for an article in the series '<series>'", "为系列「<系列>」研究选题「<标题>」的资料"),
            ("Mark unknowns as 待补资料 and never invent facts", "资料不足处标\"待补资料\"，不得编造事实"),
            ("List conflicting accounts among sources for the key claim", "对关键主张列出不同来源的口径差异"),
        ],
    },
    {
        "name": "evidence-ledger",
        "src": "01-evidence-ledger.md",
        "zh_display": "证据台账员",
        "en_display": "Evidence Ledger Keeper",
        "zh_prof": "内容证据台账员",
        "en_prof": "Content Evidence Ledger Keeper",
        "zh_desc": "把资料拆为 P0/P1/P2 事实钉子，建立可追溯的证据台账，供后续洞察、大纲和写作直接引用。",
        "en_desc": "Splits the research package into P0/P1/P2 factual nails with traceable sources—fuels insight selection, outline and drafting.",
        "tags": [("Evidence Ledger", "证据台账"), ("P0 P1 P2", "事实优先级"), ("Traceability", "可追溯")],
        "quick_prompts": [
            ("Build the evidence ledger from 01_资料/资料.md for this article", "基于资料.md 建立本篇文章的证据台账"),
            ("Tag every fact as P0 / P1 / P2 with source and risk level", "为每条事实打 P0/P1/P2 标签，标注来源与风险"),
            ("Surface conflicts and weak sources for follow-up", "标出口径冲突和弱来源以便补证"),
        ],
    },
    {
        "name": "fact-check",
        "src": "01-fact-check.md",
        "zh_display": "事实核查员",
        "en_display": "Fact Checker",
        "zh_prof": "内容事实核查员",
        "en_prof": "Content Fact Checker",
        "zh_desc": "对资料包做 P0/P1/P2 二次独立核对，决定是否能进入下一阶段，输出严格事实核查清单。",
        "en_desc": "Independently re-verifies the research package—decides whether P0 facts are cleared for outline and drafting.",
        "tags": [("Fact Verification", "事实核查"), ("P0 Clearance", "P0 放行"), ("Risk Grading", "风险分级")],
        "quick_prompts": [
            ("Fact-check 资料.md against the evidence ledger for this article", "对本篇文章的资料和证据台账做事实核查"),
            ("Mark each P0 fact as 通过 / 按口径通过 / 待补资料 / 不采用", "把 P0 事实标为通过/按口径通过/待补资料/不采用"),
            ("Block progression if any P0 is not cleared", "若 P0 仍有未清项，禁止进入下一步"),
        ],
    },
    # === 2. 洞察链 ===
    {
        "name": "ecosystem-scan",
        "src": "02-ecosystem-scan.md",
        "zh_display": "外部分析员",
        "en_display": "Ecosystem Analyst",
        "zh_prof": "外部内容分析员",
        "en_prof": "External Content Analyst",
        "zh_desc": "分析同题外部内容生态：常见写法、标题套路、写烂角度、可借鉴机制，给后续洞察差异化约束。",
        "en_desc": "Scans how others write the same topic—common angles, title patterns, overused frames and reusable mechanisms.",
        "tags": [("External Content", "外部内容"), ("Differentiation", "差异化"), ("Title Patterns", "标题套路")],
        "quick_prompts": [
            ("Scan the ecosystem for articles on '<topic>' and summarize common angles", "扫描同题「<选题>」的外部内容，总结常见角度"),
            ("List overused angles to avoid and mechanisms worth borrowing", "列出应避开的写烂角度和可借鉴的传播机制"),
            ("Generate differentiation constraints for the insight editor", "给洞察编辑生成差异化约束"),
        ],
    },
    {
        "name": "insight-select",
        "src": "02-insight-select.md",
        "zh_display": "洞察编辑",
        "en_display": "Insight Selector",
        "zh_prof": "内容洞察编辑",
        "en_prof": "Content Insight Editor",
        "zh_desc": "基于资料、证据台账、外部分析生成候选洞察和主题方向，供传播学和结构命题后续筛选。",
        "en_desc": "Drafts candidate insights and themes from research package, evidence ledger and ecosystem scan—feeds downstream filters.",
        "tags": [("Candidate Insights", "候选洞察"), ("Theme Drafting", "主题初选"), ("Editorial Filter", "选题会")],
        "quick_prompts": [
            ("Generate candidate insights for the article on '<topic>'", "为「<标题>」生成候选洞察和主题方向"),
            ("Every insight must trace to a cleared or qualified fact", "每个洞察必须能回到已核或有条件放行事实"),
            ("Note 传播优势 / 结构风险 / 事实风险 for each candidate", "为每个候选标注传播优势、结构风险和事实风险"),
        ],
    },
    {
        "name": "communication-criteria",
        "src": "02-communication-criteria.md",
        "zh_display": "传播学审查员",
        "en_display": "Communication Criterian",
        "zh_prof": "传播学审查卡生成员",
        "en_prof": "Communication Review Card Author",
        "zh_desc": "用系列传播配置生成传播学审查卡，定义合格/不合格标准，不做倾向性选择。",
        "en_desc": "Generates the communication review card from series config—defines what counts as pass / fail, without picking winners.",
        "tags": [("Review Card", "审查卡"), ("Communication Criteria", "传播标准"), ("Pass-Fail Line", "合格线")],
        "quick_prompts": [
            ("Generate the communication review card for this article", "为本篇文章生成传播学审查卡"),
            ("Set pass/fail criteria—no picking or scoring yet", "只定义合格/不合格标准，不做选择或打分"),
            ("Cover reader fit, headline risk and external saturation", "覆盖读者匹配、标题承诺风险和外部同质化"),
        ],
    },
    {
        "name": "communication-analyze",
        "src": "02-communication-analyze.md",
        "zh_display": "传播学分析师",
        "en_display": "Communication Analyst",
        "zh_prof": "传播学分析员",
        "en_prof": "Communication Analyst",
        "zh_desc": "用传播学审查卡逐条评估候选洞察，给出评分、目标客户匹配、传播风险和标题承诺风险。",
        "en_desc": "Scores each candidate insight against the communication review card—covers reader fit, virality and headline risk.",
        "tags": [("Insight Scoring", "洞察评分"), ("Reader Fit", "读者匹配"), ("Virality Risk", "传播风险")],
        "quick_prompts": [
            ("Score every candidate insight using the review card", "用传播学审查卡为每个候选洞察打分"),
            ("For each insight: who cares, why, can they retell it?", "对每个洞察评估：谁会关心、为什么、能否转述"),
            ("Flag headline-commitment risk for each insight", "标出每个洞察的标题承诺兑现风险"),
        ],
    },
    {
        "name": "structure-criteria",
        "src": "02-structure-criteria.md",
        "zh_display": "结构审查员",
        "en_display": "Structure Criterian",
        "zh_prof": "结构命题审查卡生成员",
        "en_prof": "Structure Proposition Review Card Author",
        "zh_desc": "用系列结构命题配置生成结构命题审查卡，定义 Claim/Grounds/Warrant 等合格线。",
        "en_desc": "Generates the structure proposition review card—defines Claim / Grounds / Warrant standards and pass-fail lines.",
        "tags": [("Structure Criteria", "结构标准"), ("Claim-Grounds-Warrant", "论证三段"), ("Pass-Fail Line", "合格线")],
        "quick_prompts": [
            ("Generate the structure proposition review card for this article", "为本篇文章生成结构命题审查卡"),
            ("Define Claim / Grounds / Warrant pass-fail standards", "定义 Claim/Grounds/Warrant 合格线"),
            ("No pre-selection; only set the criteria", "不做预选倾向，只定标准"),
        ],
    },
    {
        "name": "structure-analyze",
        "src": "02-structure-analyze.md",
        "zh_display": "结构分析师",
        "en_display": "Structure Analyst",
        "zh_prof": "结构命题分析员",
        "en_prof": "Structure Proposition Analyst",
        "zh_desc": "用结构命题审查卡评估候选洞察，给出全文命题、段落命题、结尾升维的评分与取舍。",
        "en_desc": "Evaluates candidates against the structure review card—ranks main proposition, section propositions and closing elevation.",
        "tags": [("Proposition Ranking", "命题排序"), ("Mechanism Chain", "机制链"), ("Trade-off", "取舍")],
        "quick_prompts": [
            ("Evaluate each candidate insight for full-article structure fit", "评估每个候选洞察作为全文结构命题的适配度"),
            ("Score Claim / Grounds / Warrant for each candidate", "为每个候选打分 Claim/Grounds/Warrant"),
            ("Pick main / section / closing propositions or mark as 放弃", "选出主命题/段落命题/结尾升维，或标记放弃"),
        ],
    },
    {
        "name": "direction-decide",
        "src": "02-direction-decide.md",
        "zh_display": "方向把控员",
        "en_display": "Direction Orchestrator",
        "zh_prof": "方向把控编辑",
        "en_prof": "Direction Orchestration Editor",
        "zh_desc": "整合传播+结构+事实+目标客户，给方向主承诺和洞察组合方案，判断是否进入大纲阶段。",
        "en_desc": "Integrates communication + structure + factual + reader fit—issues direction promise and insight combo, gates next stage.",
        "tags": [("Direction Promise", "主承诺"), ("Insight Combo", "洞察组合"), ("Gate Decision", "放行判断")],
        "quick_prompts": [
            ("Issue the direction control for article '<topic>'", "为文章「<标题>」出具方向把控"),
            ("Combine communication / structure / factual / reader into one promise", "把传播/结构/事实/读者整合为方向主承诺"),
            ("Allow / block entry into style card and outline", "判断是否允许进入文风卡和大纲"),
        ],
    },
    # === 3. 文风与大纲 ===
    {
        "name": "style-guide",
        "src": "03-style-guide.md",
        "zh_display": "文风编辑",
        "en_display": "Style Guide Editor",
        "zh_prof": "内容文风编辑",
        "en_prof": "Per-article Style Editor",
        "zh_desc": "基于方向把控和系列文风生成本文专属文风卡，含句子长度、段落节奏、入口策略、禁用表达。",
        "en_desc": "Issues the article-specific style card—sentence length, paragraph rhythm, entry strategy, mobile reading and blacklist.",
        "tags": [("Style Card", "文风卡"), ("Mobile Reading", "手机阅读"), ("Blacklist Phrases", "禁用表达")],
        "quick_prompts": [
            ("Generate the style card for article '<topic>'", "为「<标题>」生成本文专属文风卡"),
            ("Set sentence length, paragraph rhythm, entry approach", "定句子长度、段落节奏、入口方式"),
            ("List series blacklist and direction-specific constraints", "列系列禁用清单和方向相关约束"),
        ],
    },
    {
        "name": "reader-criteria",
        "src": "03-reader-criteria.md",
        "zh_display": "读者标准员",
        "en_display": "Reader Criterian",
        "zh_prof": "读者审稿卡生成员",
        "en_prof": "Reader Review Criteria Author",
        "zh_desc": "基于方向、文风、读者画像、平台阅读方式生成读者审稿卡，定义读者侧合格线。",
        "en_desc": "Generates the reader-side review criteria card—defines pass / fail standards from the reader's seat.",
        "tags": [("Reader Review", "读者审稿"), ("Pass-Fail", "合格线"), ("Experience Criteria", "体验标准")],
        "quick_prompts": [
            ("Generate the reader review criteria card for this article", "为本篇文章生成读者审稿卡"),
            ("Define reader-side pass / fail standards", "定义读者侧合格线"),
            ("No scoring yet; only set criteria", "不做评价，只定标准"),
        ],
    },
    {
        "name": "outline-plan",
        "src": "03-outline-plan.md",
        "zh_display": "大纲编辑",
        "en_display": "Outline Planner",
        "zh_prof": "内容大纲编辑",
        "en_prof": "Content Outline Editor",
        "zh_desc": "基于方向、文风、结构格式生成或修订大纲，设计标题—引言—正文—结尾承接链与字数分配。",
        "en_desc": "Drafts or revises the article outline—title-to-end chain, section breakdown, word budget and structural anchors.",
        "tags": [("Outline", "大纲"), ("Structure Chain", "承接链"), ("Word Budget", "字数分配")],
        "quick_prompts": [
            ("Draft the outline for article '<topic>'", "为「<标题>」起草大纲"),
            ("Build the title-intro-body-end chain and word budget", "设计标题—引言—正文—结尾承接链与字数分配"),
            ("Revise outline based on outline review feedback", "基于大纲审阅反馈修订大纲（v2/v3…）"),
        ],
    },
    {
        "name": "outline-review",
        "src": "03-outline-review.md",
        "zh_display": "大纲审阅主编",
        "en_display": "Outline Reviewer",
        "zh_prof": "大纲审阅主编",
        "en_prof": "Outline Review Chief",
        "zh_desc": "审阅大纲与方向、文风、事实边界、系列格式的契合度，决定能否进入草稿。",
        "en_desc": "Reviews the outline against direction, style, factual and structural fit—decides whether drafting can start.",
        "tags": [("Outline Review", "大纲审阅"), ("Gate Decision", "放行判断"), ("Structural Fit", "结构契合")],
        "quick_prompts": [
            ("Review the outline for article '<topic>'", "审阅「<标题>」的大纲"),
            ("Check direction, style, structure and factual alignment", "查方向、文风、结构、事实契合度"),
            ("Issue verdict: pass / minor-fix / major-fix / block", "给出结论：通过/小修/大修/退回上游"),
        ],
    },
    # === 4. 草稿 ===
    {
        "name": "draft-write",
        "src": "04-draft-write.md",
        "zh_display": "文章作者",
        "en_display": "Article Author",
        "zh_prof": "内容文章作者",
        "en_prof": "Content Article Author",
        "zh_desc": "严格按已通过大纲、文风卡和事实边界生成首版草稿，事实先行判断后置，不新增主洞察。",
        "en_desc": "Drafts the first version—follows the cleared outline, style card and factual boundaries. Facts first, judgments last.",
        "tags": [("Drafting", "草稿写作"), ("Outline Execution", "大纲执行"), ("Style Application", "文风落地")],
        "quick_prompts": [
            ("Write the first draft for article '<topic>' following the cleared outline", "按已通过大纲为「<标题>」写首版草稿"),
            ("Use only cleared facts; do not invent or amplify", "只用已放行事实，不得新增或放大"),
            ("Add a 写作执行说明 table at the end of the draft file", "草稿末尾附写作执行说明表"),
        ],
    },
    # === 5. 审稿链 ===
    {
        "name": "free-review",
        "src": "05-free-review.md",
        "zh_display": "自由审稿人",
        "en_display": "Free Reviewer",
        "zh_prof": "自由审稿编辑",
        "en_prof": "Free-form Blind Reviewer",
        "zh_desc": "零上下文盲审大纲/草稿/修订稿，纯普通读者视角写自由感受，无模板无必改项。",
        "en_desc": "Zero-context blind review of outline / draft / revision—writes free-form reactions as an ordinary reader, no template.",
        "tags": [("Blind Review", "盲审"), ("Free-form", "自由文本"), ("Reader Reaction", "读者感受")],
        "quick_prompts": [
            ("Blind-review this outline as an ordinary reader", "以普通读者身份盲审这份大纲"),
            ("Write free-form reactions, no templates, no must-fix", "写自由感受，不套模板，不下必改项"),
            ("Skip facts judgment—only gut reactions, curiosity, confusion", "不裁决事实，只表达直觉、好奇和困惑"),
        ],
    },
    {
        "name": "reader-review",
        "src": "05-reader-review.md",
        "zh_display": "读者审读员",
        "en_display": "Reader Reviewer",
        "zh_prof": "内容读者审读员",
        "en_prof": "Content Reader Reviewer",
        "zh_desc": "用读者审稿卡审读草稿/修订稿，给出读者侧必改项、建议项、可保留项和需主编判断的问题。",
        "en_desc": "Reviews draft / revision using the reader criteria card—emits reader-side must-fix, suggestions and keepables.",
        "tags": [("Reader Experience", "读者体验"), ("Must-fix", "必改项"), ("Payoff", "获得感")],
        "quick_prompts": [
            ("Reader-review the draft for article '<topic>'", "对「<标题>」的草稿做读者审读"),
            ("Emit must-fix / suggestion / keepable / needs-editor-decision", "分必改项/建议项/可保留项/需主编判断"),
            ("Do not judge facts; only reader experience", "不裁决事实，只看读者体验"),
        ],
    },
    {
        "name": "density-edit",
        "src": "05-density-edit.md",
        "zh_display": "密度编辑",
        "en_display": "Density Editor",
        "zh_prof": "内容密度审读员",
        "en_prof": "Content Density Auditor",
        "zh_desc": "审计可删/必留/常识词/详略/加粗建议，给出字数与加粗是否合理，密度诊断不重写正文。",
        "en_desc": "Audits deletable padding, required anchors, over-explained terms, word count and bold usage—does not rewrite.",
        "tags": [("Density Audit", "密度审计"), ("Cut / Keep", "可删必留"), ("Word Count", "字数")],
        "quick_prompts": [
            ("Audit content density of this draft", "对这份草稿做内容密度审计"),
            ("List cut / keep / common-term / bold suggestions", "列出可删/必留/常识词/加粗建议"),
            ("Do not rewrite; emit diagnosis only", "不重写正文，只给诊断"),
        ],
    },
    {
        "name": "editor-review",
        "src": "05-editor-review.md",
        "zh_display": "主编",
        "en_display": "Chief Editor",
        "zh_prof": "内容主编",
        "en_prof": "Content Chief Editor",
        "zh_desc": "综合三读+事实+方向+文风+大纲+成稿卫生，输出主编必改项、本版必处理建议项和审稿结论。",
        "en_desc": "Synthesizes three reads + facts + direction + style + outline + hygiene—emits must-fix, must-process and verdict.",
        "tags": [("Chief Editor", "主编"), ("Must-fix", "必改项"), ("Freeze Decision", "冻结决策")],
        "quick_prompts": [
            ("Chief-editor review the draft / revision for article '<topic>'", "对「<标题>」的草稿/修订做主编审稿"),
            ("Synthesize free-read + reader-review + density-edit", "综合自由审读、读者审读、内容密度审读"),
            ("Scan hygiene H1 items and emit verdict: revise / freeze / block", "扫描成稿卫生 H1 项并出结论：修订/冻结/退回"),
        ],
    },
    # === 6. 发布/修订 ===
    {
        "name": "release-check",
        "src": "06-release-check.md",
        "zh_display": "发布检查员",
        "en_display": "Release Checker",
        "zh_prof": "内容闭环发布检查员",
        "en_prof": "Content-closure Release Checker",
        "zh_desc": "主编内容冻结后做内容闭环质量门：审稿闭环、事实安全、方向承诺、标题阶段边界。",
        "en_desc": "After editor freeze—checks closure of must-fix / suggestions, factual safety, direction promise and title-stage gate.",
        "tags": [("Content Closure", "内容闭环"), ("Release Gate", "发布门"), ("Title Boundary", "标题边界")],
        "quick_prompts": [
            ("Run the release check on the final revision", "对最终修订稿做发布检查"),
            ("Verify must-fix and must-process are closed", "核实必改项和本版必处理建议项已闭环"),
            ("Set title-stage boundary: allowed claims and forbidden claims", "设定标题阶段可承诺和不可承诺边界"),
        ],
    },
    {
        "name": "format-final-check",
        "src": "06-format-final-check.md",
        "zh_display": "终审员",
        "en_display": "Format Final Checker",
        "zh_prof": "成稿终审员（格式）",
        "en_prof": "Manuscript Format Final Reviewer",
        "zh_desc": "HTML 前做格式与成稿卫生终审：施工标记、元数据污染、字数、加粗、HTML 就绪检查。",
        "en_desc": "Pre-HTML format & hygiene check—editorial markers, metadata pollution, word count, bold usage, HTML readiness.",
        "tags": [("Format Check", "格式检查"), ("Hygiene", "成稿卫生"), ("HTML Ready", "HTML 就绪")],
        "quick_prompts": [
            ("Run format final check before HTML build", "HTML 前做格式终审"),
            ("Check editorial markers, metadata, word count, bold usage", "查施工标记、元数据、字数、加粗"),
            ("Issue verdict: pass to HTML / block and fix", "出结论：通过进 HTML / 退回修复"),
        ],
    },
    {
        "name": "draft-revise",
        "src": "06-draft-revise.md",
        "zh_display": "修订作者",
        "en_display": "Revision Author",
        "zh_prof": "内容修订作者",
        "en_prof": "Content Revision Author",
        "zh_desc": "按主编修改建议+读者必改+本版必处理建议项修订稿件，输出修订稿+修订执行说明。",
        "en_desc": "Executes editor's instructions—must-fix, reader must-fix, must-process suggestions—and writes 修订稿 + 修订执行说明.",
        "tags": [("Revision", "修订"), ("Editor Follow-through", "执行主编"), ("Process Note", "执行说明")],
        "quick_prompts": [
            ("Revise the article following editor-review v<N>", "按主编修改建议 v<N> 修订文章"),
            ("Process all must-fix and must-process suggestions", "处理全部必改项和本版必处理建议项"),
            ("Output 修订稿 vN.md (body) and 修订执行说明 vN.md (process)", "输出修订稿 vN.md（正文）和修订执行说明 vN.md（流程）"),
        ],
    },
    # === 7. 标题 ===
    {
        "name": "title-ecosystem",
        "src": "07-title-ecosystem.md",
        "zh_display": "标题生态员",
        "en_display": "Title Ecosystem Analyst",
        "zh_prof": "标题生态分析员",
        "en_prof": "Title Ecosystem Analyst",
        "zh_desc": "在标题方案前分析同题已有标题模式、饱和区、可差异化角度，给标题阶段约束清单。",
        "en_desc": "Pre-title-plan analysis of existing title patterns, saturation zones and differentiation angles for this topic.",
        "tags": [("Title Patterns", "标题模式"), ("Saturation", "饱和区"), ("Differentiation", "差异化")],
        "quick_prompts": [
            ("Analyze the title ecosystem for '<topic>' before title plan", "在标题方案前分析「<选题>」的标题生态"),
            ("List saturation patterns to avoid and differentiation angles", "列饱和模式与可差异化角度"),
            ("Set hard constraints for the title writer", "给标题策略员下硬约束"),
        ],
    },
    {
        "name": "title-write",
        "src": "07-title-write.md",
        "zh_display": "标题策略员",
        "en_display": "Title Strategist",
        "zh_prof": "标题文案策略员",
        "en_prof": "Title Strategy Editor",
        "zh_desc": "基于发布检查、修订稿、方向、文风、事实边界、标题方法论生成可兑现的标题方案。",
        "en_desc": "Issues the title plan grounded in release check, revision, direction, style, factual boundaries and title methodology.",
        "tags": [("Title Plan", "标题方案"), ("Promise Fit", "兑现依据"), ("Methodology", "方法论")],
        "quick_prompts": [
            ("Draft the title plan for article '<topic>'", "为「<标题>」生成标题方案"),
            ("Each candidate must trace to a body proof", "每个标题候选必须有正文兑现依据"),
            ("Pick the final title with rationale", "选定发布标题并给出理由"),
        ],
    },
    # === 8. 插图 ===
    {
        "name": "illustration-plan",
        "src": "08-illustration-plan.md",
        "zh_display": "插图策划",
        "en_display": "Illustration Planner",
        "zh_prof": "插图方案策划编辑",
        "en_prof": "Illustration Plan Editor",
        "zh_desc": "基于修订稿、标题方案、发布边界生成插图方案和 prompts.json，控制画面作用与手机阅读。",
        "en_desc": "Generates illustration plan + prompts.json—per-image function, mobile readability and factual fit to title.",
        "tags": [("Illustration Plan", "插图方案"), ("Prompts JSON", "提示词"), ("Mobile Reading", "手机阅读")],
        "quick_prompts": [
            ("Plan illustrations for the final revision of '<topic>'", "为「<标题>」的最终修订稿规划插图"),
            ("Output 插图方案.md (human) and prompts.json (machine)", "输出插图方案.md（人类）和 prompts.json（机器）"),
            ("Each image: filename, position, function, description", "每张图含文件名、插入位置、画面作用、画面描述"),
        ],
    },
    # === 9. HTML ===
    {
        "name": "html-build",
        "src": "09-html-build.md",
        "zh_display": "排版工程师",
        "en_display": "HTML Builder",
        "zh_prof": "HTML 排版工程师",
        "en_prof": "HTML Typesetting Engineer",
        "zh_desc": "主编冻结+发布检查+成稿终审通过后，把修订稿转成唯一终稿 HTML，含标题、引言、正文、插图。",
        "en_desc": "After editor freeze + release check + format pass—builds the single final HTML from revision + title + illustration paths.",
        "tags": [("HTML Build", "HTML 构建"), ("Typesetting", "排版"), ("Single Deliverable", "单文件交付")],
        "quick_prompts": [
            ("Build the final HTML for article '<topic>'", "为「<标题>」生成唯一终稿 HTML"),
            ("Title must match the chosen title in 标题方案.md", "标题必须与标题方案中选定项一致"),
            ("Insert illustrations via relative paths under 08_插图/images/", "插图按相对路径从 08_插图/images/ 插入"),
        ],
    },
]

# === 执行 ===

def init_experts():
    """Step 1: 初始化 27 个专家目录"""
    EXPERT_DIR.mkdir(parents=True, exist_ok=True)
    print(f"\n🚀 初始化 27 个专家到 {EXPERT_DIR}\n")
    for i, e in enumerate(EXPERTS, 1):
        target = EXPERT_DIR / e["name"]
        if target.exists():
            print(f"   [{i:2d}/27] ⏭️  {e['name']}: 已存在，跳过")
            continue
        cmd = [
            sys.executable,
            str(INIT_SCRIPT),
            e["name"],
            "--type", "agent",
            "--path", str(EXPERT_DIR),
        ]
        result = subprocess.run(cmd, capture_output=True, text=True)
        ok = result.returncode == 0
        marker = "✅" if ok else "❌"
        print(f"   [{i:2d}/27] {marker} {e['name']}")
        if not ok and result.stderr:
            print(f"         {result.stderr.strip()[:200]}")
    print()

def fill_plugin_json():
    """Step 2: 填充 27 个 plugin.json"""
    print("📝 填充 plugin.json (替换 [TODO])\n")
    for i, e in enumerate(EXPERTS, 1):
        target = EXPERT_DIR / e["name"]
        pj_path = target / ".codebuddy-plugin" / "plugin.json"
        if not pj_path.exists():
            print(f"   [{i:2d}/27] ❌ {e['name']}: plugin.json 不存在")
            continue
        data = json.loads(pj_path.read_text(encoding="utf-8"))
        data["description"] = e["en_desc"]
        data["author"] = {"name": "周仪", "email": "zhouyi@example.com"}
        data["displayName"] = {"en": e["en_display"], "zh": e["zh_display"]}
        data["profession"] = {"en": e["en_prof"], "zh": e["zh_prof"]}
        data["displayDescription"] = {"en": e["en_desc"], "zh": e["zh_desc"]}
        data["categoryId"] = "06-ContentCreative"
        data["defaultInitPrompt"] = {
            "zh": e["quick_prompts"][0][1],
            "en": e["quick_prompts"][0][0],
        }
        data["tags"] = [{"en": t_en, "zh": t_zh} for t_en, t_zh in e["tags"]]
        data["quickPrompts"] = [{"en": p_en, "zh": p_zh} for p_en, p_zh in e["quick_prompts"]]
        pj_path.write_text(json.dumps(data, indent=2, ensure_ascii=False), encoding="utf-8")
        print(f"   [{i:2d}/27] ✅ {e['name']}")

def copy_and_rewrite_agent_md():
    """Step 3: 复制 subagent 源文件 + 重写 frontmatter 到 agents/{name}.md"""
    print("\n📄 复制 subagent 源文件 + 重写 frontmatter → agents/{name}.md\n")
    for i, e in enumerate(EXPERTS, 1):
        src = SUBAGENT_DIR / e["src"]
        dest = EXPERT_DIR / e["name"] / "agents" / f"{e['name']}.md"
        if not src.exists():
            print(f"   [{i:2d}/27] ❌ {e['name']}: 源 {src} 不存在")
            continue
        content = src.read_text(encoding="utf-8")
        # 替换 frontmatter
        m = re.match(r'^---\n(.*?)\n---\n?(.*)$', content, re.DOTALL)
        if not m:
            print(f"   [{i:2d}/27] ❌ {e['name']}: 无法解析 frontmatter")
            continue
        old_fm = m.group(1)
        body = m.group(2)
        # 提取 name 和 description
        name_m = re.search(r'^name:\s*(.+)$', old_fm, re.MULTILINE)
        desc_m = re.search(r'^description:\s*(.+)$', old_fm, re.MULTILINE)
        orig_name = name_m.group(1).strip() if name_m else e["name"]
        orig_desc = desc_m.group(1).strip() if desc_m else ""
        # 描述可能含特殊字符（如 "），用 JSON 字符串方式更安全
        # 保留原 description，去掉外层引号（如有）
        orig_desc_clean = orig_desc.strip('"').strip("'")

        new_fm = (
            f"---\n"
            f"name: {e['name']}\n"
            f"description: \"{orig_desc_clean}\"\n"
            f"displayName:\n"
            f"  en: \"{e['en_display']}\"\n"
            f"  zh: \"{e['zh_display']}\"\n"
            f"profession:\n"
            f"  en: \"{e['en_prof']}\"\n"
            f"  zh: \"{e['zh_prof']}\"\n"
            f"maxTurns: 50\n"
            f"---\n\n"
        )
        # 在正文最前面加一段「角色定位」简述
        role_intro = (
            f"# {e['zh_display']} - {e['zh_prof']}\n\n"
            f"> **角色定位**：{e['zh_desc']}\n\n"
            f"> **专家目录**：`~/.workbuddy/plugins/marketplaces/my-experts/plugins/{e['name']}/`\n\n"
            f"> **源 subagent**：`_工作流/03_subagents/{e['src']}`\n\n"
            f"---\n\n"
            f"## 角色简述\n\n"
            f"{e['zh_desc']}\n\n"
            f"本专家基于 `_工作流/03_subagents/{e['src']}` 转化而来；该 subagent 是文章从 0 到 HTML 流水线"
            f"中第 {('项目初始化' if e['name']=='project-setup' else '其他')} 环节的标准化定义。"
            f"详细 SOP、输入输出约束和禁止事项以正文为准。\n\n"
            f"---\n\n"
        )
        dest.write_text(new_fm + role_intro + body, encoding="utf-8")
        print(f"   [{i:2d}/27] ✅ {e['name']}")

def fill_readme():
    """Step 4: 替换每个专家的 README.md 内容"""
    print("\n📖 替换 README.md\n")
    for i, e in enumerate(EXPERTS, 1):
        readme = EXPERT_DIR / e["name"] / "README.md"
        if not readme.exists():
            print(f"   [{i:2d}/27] ⏭️  {e['name']}: README 不存在")
            continue
        content = (
            f"# {e['zh_display']} - {e['zh_prof']}\n\n"
            f"{e['zh_desc']}\n\n"
            f"## 适用场景\n\n"
            f"{e['quick_prompts'][0][1]}\n\n"
            f"## 类型\n\n"
            f"Agent 型（单个 AI 专家）— 由 `_工作流/03_subagents/{e['src']}` 转化而来。\n\n"
            f"## 核心能力\n\n"
            + "".join(f"- **{t_zh}** ({t_en})\n" for t_en, t_zh in e["tags"])
            + "\n## 使用示例\n\n"
            + "".join(f"- {p_zh}\n" for p_en, p_zh in e["quick_prompts"])
            + "\n## 头像\n\n"
            f"头像自动生成在 `avatars/expert.png`。如需替换，要求：\n"
            f"- 格式：PNG（推荐）或 JPG\n"
            f"- 尺寸：512×512 px\n"
            f"- 大小：单张不超过 500KB\n\n"
            f"## 关联\n\n"
            f"- **源 subagent**：`_工作流/03_subagents/{e['src']}`\n"
            f"- **专家 ID**：`{e['name']}`\n"
            f"- **流水线位置**：{('项目初始化（0）' if e['name']=='project-setup' else '见工作流手册 02_单篇文章从0到HTML成稿执行手册.md')}\n\n"
            f"## 安装\n\n"
            f"专家目录固定在 `~/.workbuddy/plugins/marketplaces/my-experts/plugins/`。"
            f"运行 `python3 scripts/register_expert.py <expert-dir>` 注册后即可在 WorkBuddy 专家中心看到。\n"
        )
        readme.write_text(content, encoding="utf-8")
        print(f"   [{i:2d}/27] ✅ {e['name']}")

if __name__ == "__main__":
    init_experts()
    fill_plugin_json()
    copy_and_rewrite_agent_md()
    fill_readme()
    print("\n" + "="*50)
    print(f"✅ 27 个专家目录与文件全部就绪")
    print(f"   下一步：python3 scripts/validate_expert.py <expert-dir> × 27")
    print(f"           python3 scripts/register_expert.py <expert-dir> --session-id {SESSION_ID} × 27")