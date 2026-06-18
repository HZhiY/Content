# -*- coding: utf-8 -*-
import re
import json
import os

SRC = r"c:\Users\27649\Documents\myproject\Content\巴基斯坦如何把世界变成自己的资源\01_不是夹缝求生，而是管理不对称\06_修订与发布\修订稿 v1.md"

# 定义各节范围（行号，1-indexed，包含范围）
SECTIONS = [
    ("引言", 16, 22),       # 行 16 H2 标题（不计） + 18-22 正文
    ("一 快不了了 4 个核心时刻", 26, 32),
    ("二 分工联盟 谁在替巴方谈判", 36, 48),
    ("三 中国 战略背书与基础设施", 52, 68),
    ("四 海湾 现金、存款与能源赊账", 72, 84),
    ("五 美国 援助与合法性的阀门", 88, 100),
    ("六 换生存易 换转型难", 106, 114),
    ("结尾", 118, 122),
]

def is_h2_header(line):
    return line.lstrip().startswith("## ")

def is_chinese_or_punct(ch):
    # 汉字范围
    if '\u4e00' <= ch <= '\u9fff':
        return True
    # 中文标点
    if ch in "，。、；：？！""''「」『』《》（）—…·【】":
        return True
    # 英文标点
    if ch in ",.;:?!'\"()<>[]{}-—–_/\\@#$%^&*+=~`":
        return True
    # 全角空格 / 中文空格
    if ch in " 　":
        return True
    return False

def count_chars(text):
    """统计汉字 + 标点字符数（含中英标点）"""
    n = 0
    for ch in text:
        if is_chinese_or_punct(ch):
            n += 1
    return n

def count_hanzi_only(text):
    """统计纯汉字数"""
    n = 0
    for ch in text:
        if '\u4e00' <= ch <= '\u9fff':
            n += 1
    return n

def count_punct_only(text):
    """统计标点数"""
    n = 0
    for ch in text:
        if is_chinese_or_punct(ch) and not ('\u4e00' <= ch <= '\u9fff'):
            n += 1
    return n

def split_paragraphs(text):
    """按空行拆段"""
    paras = []
    for block in text.strip().split("\n\n"):
        block = block.strip()
        if block:
            paras.append(block)
    return paras

def is_long_paragraph(p, max_lines=6):
    """段落是否超过 max_lines 行（按 \n 算行）"""
    return len(p.split("\n")) > max_lines

# 读文件
with open(SRC, "r", encoding="utf-8") as f:
    lines = f.readlines()

total_hanzi = 0
total_punct = 0
total_chars = 0
section_stats = []
para_over6 = 0
para_list = []  # 收集所有段落用于后续分析

for name, start, end in SECTIONS:
    section_text_lines = []
    for i in range(start - 1, end):  # 1-indexed 转 0-indexed
        line = lines[i].rstrip("\n")
        # 跳过 H2 标题行
        if is_h2_header(line):
            continue
        section_text_lines.append(line)
    section_text = "\n\n".join([x for x in section_text_lines if x.strip()])
    chars = count_chars(section_text)
    hanzi = count_hanzi_only(section_text)
    punct = count_punct_only(section_text)
    total_chars += chars
    total_hanzi += hanzi
    total_punct += punct
    section_stats.append({
        "name": name,
        "chars": chars,
        "hanzi": hanzi,
        "punct": punct,
    })
    # 段落分析
    paras = split_paragraphs(section_text)
    for p in paras:
        line_count = len(p.split("\n"))
        para_list.append({
            "section": name,
            "para": p,
            "lines": line_count,
            "chars": count_chars(p),
            "hanzi": count_hanzi_only(p),
        })
        if line_count > 6:
            para_over6 += 1

print("=" * 60)
print("各节字数统计（含标点 = 汉字 + 中英标点）")
print("=" * 60)
for s in section_stats:
    print(f"  {s['name']:30s}  汉字={s['hanzi']:4d}  标点={s['punct']:3d}  合计={s['chars']:4d}")

print()
print(f"全文合计：汉字={total_hanzi}  标点={total_punct}  合计={total_chars}")
print(f"段落总数：{len(para_list)}")
print(f"超 6 行段落数：{para_over6}")

# 段落长度明细
print()
print("=" * 60)
print("段落长度明细（按节、超过 4 行高亮）")
print("=" * 60)
current_section = None
for p in para_list:
    if p["section"] != current_section:
        print(f"\n【{p['section']}】")
        current_section = p["section"]
    flag = " ⚠超 4 行" if p["lines"] > 4 else ""
    flag6 = " ⚠⚠超 6 行" if p["lines"] > 6 else ""
    print(f"  {p['lines']:2d}行 / {p['hanzi']:3d}字 {flag}{flag6}")
    if p["lines"] > 4 or p["lines"] > 6:
        print(f"    段首：{p['para'][:50]}…")

# 关键短句 / 母题句扫描
print()
print("=" * 60)
print("关键短句 / 母题句扫描")
print("=" * 60)
KEY_PHRASES = [
    "不是选边",
    "同时管理",
    "三组不对称依赖",
    "兑换术",
    "换生存",
    "难换转型",
    "结构性需求",
    "不断被再生产",
    "分轴经营",
    "综合议价包",
    "分清",
    "前提",
    "三口径并列",
    "5 个证据",
    "5 个工具",
    "5 证",
    "四个证据",
    "4 证",
    "三轴",
    "扣 3 亿不是惩罚",
    "不是新钱",
    "既得利益网络",
    "结构性约束",
]
all_text = "".join(lines)
for kp in KEY_PHRASES:
    cnt = all_text.count(kp)
    print(f"  '{kp}': {cnt}")

# 4证 / 5证 出场情况
print()
print("=" * 60)
print("4证 / 5证 出场情况")
print("=" * 60)
print("分工联盟 4 证：")
for kw in ["SIFC", "特别投资促进委员会", "CPEC Authority", "中巴经济走廊管理局", "Asim Bajwa", "退役中将", "Asim Munir", "Rubio", "陆军参谋长", "国际货币基金组织", "IMF", "SBA", "EFF", "安排"]:
    cnt = all_text.count(kw)
    print(f"  '{kw}': {cnt}")

print()
print("换生存难换转型 5 证：")
for kw in ["部分执行", "反复延期", "16.5 亿", "43.55 亿", "60 亿合同", "财政部口径", "DAWN", "展期", "续作", "30 亿", "SBP", "30.9 亿", "9 年低点", "150-160 亿", "FATF", "灰名单", "34 项行动"]:
    cnt = all_text.count(kw)
    print(f"  '{kw}': {cnt}")
