# -*- coding: utf-8 -*-
import re
from pathlib import Path

p = Path(__file__).resolve().parent.parent / "06_修订与发布" / "修订稿 v1.md"
text = p.read_text(encoding="utf-8")
lines = text.splitlines()

start = None
for i, line in enumerate(lines):
    if line.strip() == "## 引言":
        start = i
        break

body_lines = lines[start:]

section_order = [
    "引言",
    "一、普通税基不够用时，国家升级为\"自己经营\"",
    "二、换了一种走法，批发权还在国家手里",
    "三、朝廷把盐引变成自己发的特许——入口越来越深",
    "四、一场激烈辩论只撤了一小部分——结构已经在运转",
    "五、制度运行是连续的，退出比进入更难",
    "六、治理与财政一旦被绑在一起，退出就比进入更难",
]

sections = {k: [] for k in section_order}
current = "引言"

for line in body_lines:
    if line.startswith("## "):
        title = line[3:].strip()
        if title in sections:
            current = title
        continue
    if line.strip() == "---":
        continue
    sections[current].append(line)


def count_chars(s: str) -> int:
    s = re.sub(r"\*\*([^*]+)\*\*", r"\1", s)
    s = re.sub(r"^>.*$", "", s, flags=re.MULTILINE)
    return sum(1 for ch in s if ch not in " \t\n\r")


total = 0
print("SECTION COUNTS:")
for name in section_order:
    content = "\n".join(sections[name])
    n = count_chars(content)
    total += n
    print(f"{name}: {n}")
print(f"TOTAL: {total}")
