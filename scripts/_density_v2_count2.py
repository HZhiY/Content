# -*- coding: utf-8 -*-
import re
import sys
import io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

def count_cn_punct(s):
    # Chinese chars + Chinese punctuation
    pattern = re.compile(r'[\u4e00-\u9fff]|[，。！？；：、""''「」（）()【】《》〈〉『』…—–·]')
    return len(pattern.findall(s))

with open(r'c:/Users/27649/Documents/myproject/Content/巴基斯坦如何把世界变成自己的资源/01_不是夹缝求生，而是管理不对称/06_修订与发布/修订稿 v2.md','r',encoding='utf-8') as f:
    text = f.read()

lines = text.split('\n')
sections = {}
order = []
current = None
buf = []
for line in lines:
    m = re.match(r'^## (.+)$', line)
    if m:
        if current:
            sections[current] = '\n'.join(buf)
        current = m.group(1).strip()
        buf = []
        order.append(current)
    else:
        if current is not None:
            buf.append(line)
if current:
    sections[current] = '\n'.join(buf)

total = 0
for k in order:
    v = sections[k]
    cnt = count_cn_punct(v)
    total += cnt
    print(f"[{k}] = {cnt}")
print(f"TOTAL = {total}")

# also count total plain (all)
print(f"PLAIN TOTAL = {count_cn_punct(text)}")

bold_pattern = re.compile(r'\*\*([^*]+)\*\*')
bolds = bold_pattern.findall(text)
print(f"\nBOLD COUNT = {len(bolds)}")
for b in bolds:
    print(f"  - {b}")

# paragraphs
paras = re.split(r'\n\s*\n', text)
long_paras = 0
for p in paras:
    nonempty = [l for l in p.strip().split('\n') if l.strip()]
    if len(nonempty) > 6:
        long_paras += 1
print(f"\nLONG PARAS (>6 lines) = {long_paras}")

# keywords
keywords = ['兑换术', '分轴经营', '综合议价包', '三组不对称依赖', '结构性需求', '多线兑换', '三组结构性约束', '分工联盟', '反常识', '信用阀门', '可调节', '结构性产物', '既得利益网络', '复合驱动', '地缘租金', '快不行了', '快不了了']
print("\nKEYWORDS:")
for kw in keywords:
    c = text.count(kw)
    if c > 0:
        print(f"  {kw}: {c}")