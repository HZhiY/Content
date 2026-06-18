import re
import os

# Files
FILE = r'c:/Users/27649/Documents/myproject/Content/巴基斯坦如何把世界变成自己的资源/01_不是夹缝求生，而是管理不对称/06_修订与发布/修订稿 v2.md'

with open(FILE, 'r', encoding='utf-8') as f:
    text = f.read()

# Sections (find by ## headings)
sections = [
    ('引言', r'## 引言'),
    ('一、快不行了 4 时刻', r'## 一、'),
    ('二、分工联盟', r'## 二、'),
    ('三、中国', r'## 三、'),
    ('四、海湾', r'## 四、'),
    ('五、美国', r'## 五、'),
    ('六、换生存难换转型', r'## 六、'),
    ('结尾', r'## 结尾'),
]

positions = []
for name, pat in sections:
    m = re.search(pat, text)
    if m:
        positions.append((name, m.start()))

positions.append(('END', len(text)))
positions.sort(key=lambda x: x[1])

def count_body_chars(s):
    # Remove lines that are: starting with single #, > blockquote, ---, ## headers
    out_lines = []
    for line in s.split('\n'):
        if line.startswith('# 01'):
            continue
        if line.startswith('>'):
            continue
        if line.strip() == '---':
            continue
        if line.startswith('## '):
            continue
        out_lines.append(line)
    body = '\n'.join(out_lines)
    # Count CJK chars + Chinese punctuation
    cjk = re.findall(r'[\u4e00-\u9fff]', body)
    punct = re.findall(r'[\u3000-\u303f\uff00-\uffef]', body)
    return len(cjk) + len(punct)

print('=== Section character counts (汉字 + 标点) ===')
section_chars = {}
for i in range(len(positions) - 1):
    name = positions[i][0]
    start = positions[i][1]
    end = positions[i+1][1]
    seg = text[start:end]
    chars = count_body_chars(seg)
    section_chars[name] = chars

total = sum(section_chars.values())
for name, c in section_chars.items():
    pct = c / total * 100 if total else 0
    print(f'  {name}: {c} chars ({pct:.1f}%)')
print(f'TOTAL: {total} chars')

# Count occurrences
def count_in_body(pattern):
    return len(re.findall(pattern, text))

print()
print('=== Key short sentences (关键短句) ===')
keys = [
    '不是选边', '同时管理', '三组不对称依赖',
    '分轴经营', '综合议价包', '结构性需求', '再生产',
    '兑换术', '换生存', '难换转型',
    '三组结构性约束', '综合议价包',
]
for k in keys:
    print(f'  {k}: {count_in_body(re.escape(k))}')

print()
print('=== 机制词 (mechanism words) ===')
mech = [
    '兑换术', '分轴经营', '综合议价包',
    '三组不对称依赖', '结构性需求', '再生产',
]
for k in mech:
    print(f'  {k}: {count_in_body(re.escape(k))}')

print()
print('=== 4证分工联盟出场 ===')
fork = ['SIFC', 'CPEC Authority', 'Rubio', 'Asim Munir', 'Asim Bajwa']
for k in fork:
    cnt = count_in_body(re.escape(k))
    print(f'  {k}: {cnt}')

# Count IMF 历轮安排 (SBA/EFF)
imf_arrangements = re.findall(r'(?:备用安排|SBA|扩展基金安排|EFF)', text)
print(f'  IMF历轮安排 引用次数: {len(imf_arrangements)}')

print()
print('=== 5证换生存难换转型出场 ===')
trans = ['IMF', '60亿', '16.5亿', '43.55亿', '沙特', 'SBP', 'FATF', '灰名单', '展期', '34亿', '30.9亿']
for k in trans:
    print(f'  {k}: {count_in_body(re.escape(k))}')

# Count IMF 4轮 arrangements specifically (SBA/EFF)
print()
print('=== IMF 4轮安排 提到 ===')
for k in ['2008', '2013', '2019', '2023']:
    cnt = count_in_body(re.escape(k))
    print(f'  {k}: {cnt}')

print()
print('=== 段落超 6 行检查 ===')
paragraphs = re.split(r'\n\s*\n', text)
over_6 = []
for i, p in enumerate(paragraphs):
    p_clean = p.strip()
    if not p_clean:
        continue
    if p_clean.startswith('#'):
        continue
    if p_clean.startswith('>'):
        continue
    if p_clean == '---':
        continue
    lines = p_clean.split('\n')
    nlines = len(lines)
    if nlines > 6:
        # Show first line + total lines
        first_line = lines[0][:50]
        over_6.append((i, nlines, first_line))

print(f'Total paragraphs (incl all): {len(paragraphs)}')
print(f'Over 6 lines: {len(over_6)}')
for idx, nl, prev in over_6:
    print(f'  Para#{idx}: {nl} lines | {prev}')

# File size
size = os.path.getsize(FILE)
print(f'\n=== File size ===')
print(f'Bytes: {size}')