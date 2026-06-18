# -*- coding: utf-8 -*-
import re
import sys
from pathlib import Path

p = Path(r"c:\Users\27649\Documents\myproject\Content\巴基斯坦如何把世界变成自己的资源\01_不是夹缝求生，而是管理不对称\04_草稿\草稿 v1.md")
text = p.read_text(encoding="utf-8")

lines = text.splitlines()

# 找出每节标题行 (## 一、 ## 二、 等) 和正文行
sections = {}
current = None
buf = []

# 跳过文件头 metadata (开头 --- 之上的内容)
header_end = 0
for i, line in enumerate(lines):
    if line.strip() == "---":
        header_end = i
        break

# 跳过文件头 + 第一个 --- 后的内容
body_started = False
section_start_re = re.compile(r"^##\s+(.+)$")
blank_re = re.compile(r"^\s*$")
meta_re = re.compile(r"^>")
h_re = re.compile(r"^#")
hr_re = re.compile(r"^---$")

cur_name = None
cur_lines = []

def cnt(s):
    # 含标点的全文字数 = 汉字 + 标点 + 英文字母 + 数字
    # 模板要求"汉字 + 标点",这里采用更广的口径,统计所有非空白字符
    return len([c for c in s if not c.isspace()])

def is_body(l):
    if not l.strip():
        return False
    if l.startswith("#"):
        return False
    if l.startswith(">"):
        return False
    if l.strip() == "---":
        return False
    return True

# 简单处理: 跳过文件头(第一个 --- 之上)
start_idx = 0
seen_first_hr = False
for i, l in enumerate(lines):
    if l.strip() == "---" and not seen_first_hr:
        seen_first_hr = True
        start_idx = i + 1
        break

# 继续走
i = start_idx
order = []
while i < len(lines):
    l = lines[i]
    m = section_start_re.match(l)
    if m:
        # 保存上一节
        if cur_name is not None:
            sections[cur_name] = cur_lines
            order.append(cur_name)
        cur_name = m.group(1).strip()
        cur_lines = []
    else:
        if cur_name is not None and is_body(l):
            cur_lines.append(l)
    i += 1

# 收尾
if cur_name is not None:
    sections[cur_name] = cur_lines
    order.append(cur_name)

# 输出每节字符数(包含标点) = 汉字 + 标点 + 字母 + 数字
total_all = 0
print(f"{'节名':<40} {'字符数(含标点)':>12} {'行数':>6}")
print("-" * 70)
for name in order:
    body = "".join(sections[name])
    n = cnt(body)
    total_all += n
    print(f"{name:<40} {n:>12} {len(sections[name]):>6}")

print("-" * 70)
print(f"{'合计':<40} {total_all:>12}")

# 全文字符(全文字数含标点)
full_body = "".join([c for name in order for c in "".join(sections[name])])
print()
print(f"全文总字符数(含标点、去 metadata): {cnt(full_body)}")

# 全文字符(不去 metadata)
print(f"全文总字符数(含标点、含 metadata): {cnt(text)}")

# 关键短句计数 - 大致
key_phrases = [
    "兑换术", "三组不对称依赖", "三组结构性约束", "分工联盟", "换生存", "换转型",
    "结构性需求", "管理不对称", "不是选边", "综合议价包", "分轴经营", "结构性产物",
    "地缘租金", "外部资源结构", "军方定边界", "文官做交易", "IMF 当信用阀门",
    "海湾资金", "海湾资本", "战略背书", "合法性包装", "现金流感官", "安全国家本能",
    "再生产", "现金流", "能源赊账", "能源安全阀", "阀门", "信用背书"
]
print()
print("机制词 / 母题词汇出现次数:")
for kw in key_phrases:
    c = full_body.count(kw)
    print(f"  {kw}: {c}")

# 段落超 6 行数
print()
print("段落超 6 行数:")
para_count = 0
for name in order:
    para = []
    for line in sections[name]:
        if blank_re.match(line):
            if para:
                if len(para) > 6:
                    para_count += 1
                    print(f"  [{name}] 段 {len(para)} 行")
                para = []
        else:
            para.append(line)
    if para and len(para) > 6:
        para_count += 1
        print(f"  [{name}] 段 {len(para)} 行")
print(f"合计超 6 行段数: {para_count}")

# 4 证 / 5 证 出场情况
print()
print("=== 4 证分工联盟出场检查 ===")
checks_4 = [
    ("SIFC", "SIFC"),
    ("CPEC Authority", "CPEC Authority"),
    ("Rubio 通话", "Rubio"),
    ("Asim Munir", "Asim Munir"),
    ("Asim Bajwa", "Asim Bajwa"),
    ("IMF 历轮安排", "IMF"),
    ("2008", "2008"),
    ("2013", "2013"),
    ("2019", "2019"),
    ("2023", "2023"),
]
for label, kw in checks_4:
    c = full_body.count(kw)
    print(f"  {label}({kw}): {c}")

print()
print("=== 5 证换生存难换转型出场检查 ===")
checks_5 = [
    ("IMF 四轮安排", "IMF"),
    ("60 亿合同 vs 16.5 亿净流入", "16.5"),
    ("财政部口径", "财政部"),
    ("沙特存款展期", "30 亿"),
    ("SBP 储备", "30.9"),
    ("SBP 9 年低点", "9 年"),
    ("FATF 灰名单", "灰名单"),
    ("FATF 34 项行动计划", "34 项"),
    ("FATF 移出", "移出"),
    ("结构性条件", "结构性"),
]
for label, kw in checks_5:
    c = full_body.count(kw)
    print(f"  {label}({kw}): {c}")
