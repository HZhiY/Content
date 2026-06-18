#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""统计修订稿 v2 各节字数（汉字 + 标点，含 Markdown 结构但仅按章节分割）"""
import re

path = r"c:\Users\27649\Documents\myproject\Content\巴基斯坦如何把世界变成自己的资源\01_不是夹缝求生，而是管理不对称\06_修订与发布\修订稿 v2.md"

with open(path, "r", encoding="utf-8") as f:
    text = f.read()

# 标点 + 汉字 + 英文字母 + 数字都计
def count_chars(s):
    # 过滤空白行 / Markdown 标记
    s = s.strip()
    # 去掉 markdown 标题前缀 # 和 > 引用
    s = re.sub(r'^#+\s*', '', s, flags=re.M)
    s = re.sub(r'^>\s*', '', s, flags=re.M)
    # 去掉元数据头文件部分（8 行内）
    # 只保留汉字、英文字母、数字、标点
    # 但过滤空白
    chars = []
    for ch in s:
        if ch.strip() == "":
            continue
        chars.append(ch)
    return len(chars)

# 按节划分
sections = {}
current = "front"
sections[current] = []

for line in text.split("\n"):
    line_stripped = line.strip()
    # 跳过元数据头（--- 开头）
    if line_stripped.startswith("---"):
        continue
    # 检测标题
    if line_stripped.startswith("## ") and not line_stripped.startswith("### "):
        title = line_stripped[3:].strip()
        current = title
        sections[current] = []
    else:
        sections[current].append(line)

# 统计
print("=" * 60)
for sec, lines in sections.items():
    full_text = "\n".join(lines)
    n = count_chars(full_text)
    print(f"{sec}: {n}")

print("=" * 60)
# 总计
total = sum(count_chars("\n".join(lines)) for lines in sections.values())
print(f"全文合计（含标点，不含元数据头）: {total}")

# 计算不含 markdown 标记的纯正文
# 再去除 markdown 标记和首尾符号
clean_text = []
for line in text.split("\n"):
    if line.strip().startswith("---"):
        continue
    if line.strip().startswith("# "):
        continue
    clean = re.sub(r'^#+\s*', '', line)
    clean = re.sub(r'^>\s*', '', clean)
    if clean.strip():
        clean_text.append(clean)

pure_text = "\n".join(clean_text)
n_clean = len([ch for ch in pure_text if ch.strip()])
print(f"纯正文（含标题与正文）字符数: {n_clean}")

# 不含标题的纯正文
no_title = []
for line in text.split("\n"):
    if line.strip().startswith("---"):
        continue
    if line.strip().startswith("# "):
        continue
    if line.strip().startswith("## "):
        continue
    clean = re.sub(r'^#+\s*', '', line)
    clean = re.sub(r'^>\s*', '', clean)
    if clean.strip():
        no_title.append(clean)

pure_body = "\n".join(no_title)
n_body = len([ch for ch in pure_body if ch.strip()])
print(f"纯正文（不含标题）字符数: {n_body}")

# 段落数（空行分隔）+ 超 6 行段
paragraphs = [p for p in pure_body.split("\n") if p.strip()]
print(f"\n段落总数: {len(paragraphs)}")

# 段落行数统计（每段以单行视为一段）
over_six = 0
total_lines_body = 0
for p in paragraphs:
    lines_in_p = p.split("\n")
    n_lines = len([l for l in lines_in_p if l.strip()])
    total_lines_body += n_lines
    if n_lines > 6:
        over_six += 1

print(f"段落行数总和: {total_lines_body}")
print(f"超 6 行的段数: {over_six}")

# 计算 4 证 / 5 证 关键短语出现次数
phrases_4 = ["SIFC", "CPEC Authority", "Rubio", "IMF"]  # 分工联盟 4 证
phrases_5 = ["60 亿合同", "16.5 亿", "沙特", "SBP", "FATF"]  # 换生存难换转型 5 证

print("\n=== 4 证分工联盟出现情况 ===")
for p in ["SIFC", "CPEC Authority", "Rubio", "Asim Munir", "陆军参谋长", "财政部", "央行"]:
    count = pure_body.count(p)
    print(f"  '{p}': {count} 次")

print("\n=== 5 证换生存难换转型出现情况 ===")
for p in ["IMF", "16.5 亿", "沙特存款", "30 亿存款", "SBP", "FATF", "灰名单", "结构性改革", "部分执行", "反复延期", "60 亿"]:
    count = pure_body.count(p)
    print(f"  '{p}': {count} 次")

# 关键短句总数（以句号分句，长度超短句算关键短句）
import re
sentences = re.split(r'[。！？]', pure_body)
sentences = [s for s in sentences if s.strip()]
print(f"\n总句数: {len(sentences)}")

# 加粗文本统计
bolds = re.findall(r'\*\*([^*]+)\*\*', pure_body)
print(f"\n加粗短语数: {len(bolds)}")
for b in bolds:
    print(f"  - {b}")