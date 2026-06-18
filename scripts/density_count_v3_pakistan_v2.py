# -*- coding: utf-8 -*-
import json, re, os

root = r"巴基斯坦如何把世界变成自己的资源/01_不是夹缝求生，而是管理不对称/04_草稿/草稿 v1.md"
out_root = r"巴基斯坦如何把世界变成自己的资源/01_不是夹缝求生，而是管理不对称/05_审阅"
with open(root, "r", encoding="utf-8") as f:
    raw = f.read()

m = re.split(r"\n---\n", raw, maxsplit=1)
body = m[1] if len(m) > 1 else raw
body_no_header = body
lines = body.split("\n")

section_starts = []
for i, ln in enumerate(lines):
    if ln.startswith("## "):
        section_starts.append((i, ln[3:].strip()))
section_starts.append((len(lines), "END"))

def cn_count(text):
    n = 0
    for ch in text:
        if ch.isspace():
            continue
        if '0' <= ch <= '9' or 'A' <= ch <= 'Z' or 'a' <= ch <= 'z':
            continue
        if ch in ".,;:!?-_=+()[]{}<>\\/|@#$%^&*~`'\"":
            continue
        n += 1
    return n

sections = {}
for idx in range(len(section_starts) - 1):
    start, name = section_starts[idx]
    end = section_starts[idx+1][0]
    text = "\n".join(lines[start:end])
    sections[name] = {"len_char": cn_count(text), "paras": len([p for p in re.split(r"\n\s*\n", text) if p.strip()])}

# 找包含 "5证" / "5 证" / "3 个工具" / "5 个证据" 的句子
print("=== 关键短句上下文 ===")
for kp in ["5证", "5 证", "5证拼完", "5 证拼完", "5个证据", "5 个证据", "3 个工具", "3个工具", "5证拼完换生存", "5 证拼完换生存", "5个证据合起来", "5 个证据合起来", "执行偏差同样贯穿", "执行偏差", "换不到", "换不到国内改革", "换不到改革", "难换", "换转型"]:
    for m in re.finditer(re.escape(kp), body):
        s = max(0, m.start()-30)
        e = min(len(body), m.end()+30)
        snippet = body[s:e].replace("\n", " ")
        print(f"  [{kp}] @{m.start()}: ...{snippet}...")

# 段落行数与"超 6 行"统计
print("\n=== 段落行数 ===")
paras_all = [p for p in re.split(r"\n\s*\n", body) if p.strip()]
for i, p in enumerate(paras_all):
    p_lines = [l for l in p.split("\n") if l.strip()]
    if len(p_lines) >= 4:
        print(f"  P{i+1} ({len(p_lines)}行): {p_lines[0][:50]}")

# 关键短语场景出现 - 重要"机制主钉"判定
print("\n=== 4证并引 - 分工联盟 ===")
for kp, desc in [
    ("SIFC", "E01-P1-12 SIFC 设立"),
    ("CPEC Authority", "E01-P2-01 CPEC Authority"),
    ("Asim Munir", "E01-P0-22 Rubio / Munir 通话"),
    ("国际货币基金组织", "IMF 历轮安排"),
    ("IMF", "IMF 历轮安排"),
    ("四轮安排", "E01-P0-05 IMF 四轮"),
    ("E01-P0-05", "E01-P0-05"),
]:
    cnt = body.count(kp)
    print(f"  {desc} ({kp}): {cnt} 次")

print("\n=== 5证并引 - 换生存难换转型 ===")
for kp, desc in [
    ("四轮安排", "E01-P0-05 IMF 四轮安排 + 部分执行"),
    ("部分执行", "E01-P0-05 部分执行"),
    ("16.5", "E01-P1-01 IMF 净口径 16.5 亿"),
    ("43.55", "E01-P1-01 43.55 亿需还旧账"),
    ("60 亿合同", "E01-P1-01 60 亿合同"),
    ("续作", "E01-P0-13 沙特存款续作"),
    ("30亿存款", "E01-P0-13 沙特 30 亿存款"),
    ("展期", "E01-P0-13 展期"),
    ("30.9", "E01-P0-20 SBP 储备"),
    ("9 年低点", "E01-P0-20 9 年低点"),
    ("150-160", "E01-P0-20 2026-04 区间"),
    ("FATF", "E01-P1-11 FATF 灰白名单"),
    ("灰名单", "E01-P1-11 灰名单"),
    ("34 项", "E01-P1-11 34 项行动计划"),
]:
    cnt = body.count(kp)
    print(f"  {desc} ({kp}): {cnt} 次")

# 引言字数
print("\n=== 引言 / 第一节 内部字数 ===")
intro_match = re.search(r"## 引言\n(.*?)(?=\n## )", body, re.S)
intro = intro_match.group(1) if intro_match else ""
print(f"  引言长度: {cn_count(intro)} 字")

s1_match = re.search(r"## 一、(.*?)(?=\n## )", body, re.S)
s1 = s1_match.group(1) if s1_match else ""
print(f"  第一节长度: {cn_count(s1)} 字")

end_match = re.search(r"## 结尾\n(.*?)$", body, re.S)
end = end_match.group(1) if end_match else ""
print(f"  结尾长度: {cn_count(end)} 字")

# 每节中所有"分清...是看清...的前提"句式
print("\n=== 句式重复扫描 ===")
for kp in ["分清谁拍板", "分清这两类", "分清", "是看清", "前提"]:
    cnt = body.count(kp)
    print(f"  {kp}: {cnt} 次")
