import re

with open(r'c:\Users\27649\Documents\myproject\content\巴基斯坦如何把世界变成自己的资源\01_不是夹缝求生，而是管理不对称\06_修订与发布\修订稿 v5.md', 'r', encoding='utf-8') as f:
    text = f.read()

# 从 ## 引言 开始
lines = text.split('\n')
start_idx = None
for i, line in enumerate(lines):
    if line.startswith('## 引言'):
        start_idx = i
        break

content = '\n'.join(lines[start_idx:])

# 段落：以空行分隔
raw = re.split(r'\n\s*\n', content)

paragraphs = []
for p in raw:
    s = p.strip()
    if not s:
        continue
    if s == '---':
        continue
    if s.startswith('## ') and '\n' not in s:
        continue
    paragraphs.append(s)

para_chars = [len(re.sub(r'\s', '', p)) for p in paragraphs]
total = sum(para_chars)
over = [(i+1, c) for i, c in enumerate(para_chars) if c > 220]

result = []
result.append(f'段落数：{len(paragraphs)}')
result.append(f'总字符数：{total}')
result.append(f'超阈段数：{len(over)}')
for i, c in enumerate(para_chars):
    m = ' X' if c > 220 else ''
    result.append(f'  P{i+1}: {c}{m}')

with open(r'c:\Users\27649\Documents\myproject\content\_tmp_count_v5_out.txt', 'w', encoding='utf-8') as f:
    f.write('\n'.join(result))