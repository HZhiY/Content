import re
import sys
import io

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

with open(r'c:/Users/27649/Documents/myproject/Content/巴基斯坦如何把世界变成自己的资源/01_不是夹缝求生，而是管理不对称/06_修订与发布/修订稿 v2.md', 'r', encoding='utf-8') as f:
    text = f.read()

# 按节切分
sections = []
current_section = None
current_lines = []
skip_header = True

for line in text.split('\n'):
    if line.startswith('## ') and not line.startswith('### '):
        if current_section is not None:
            sections.append((current_section, '\n'.join(current_lines)))
        current_section = line[3:].strip()
        current_lines = []
        skip_header = False
    elif not skip_header:
        current_lines.append(line)

if current_section is not None:
    sections.append((current_section, '\n'.join(current_lines)))

def count_cn_punct(s):
    cn_chars = re.findall(r'[\u4e00-\u9fff\u3000-\u303f\uff00-\uffef]', s)
    return len(cn_chars)

total = 0
print("=== 各节字数统计（汉字+标点）===")
for name, content in sections:
    n = count_cn_punct(content)
    total += n
    pct = n / total * 100 if total > 0 else 0
    print(f'  {name}: {n} 字')
print(f'TOTAL: {total} 字')
print()

# 关键短语统计
print("=== 关键短语统计 ===")
key_phrases = [
    ('兑换术', '主机制词'),
    ('三组不对称依赖', '主机制词'),
    ('三组结构性约束', '主机制词'),
    ('分轴经营', '主机制词'),
    ('综合议价包', '主机制词'),
    ('结构性需求', '主机制词'),
    ('结构性产物', '主机制词'),
    ('60亿', '数据'),
    ('16.5亿', '数据'),
    ('43.55亿', '数据'),
    ('30亿', '数据'),
    ('247亿', '数据'),
    ('620亿', '数据'),
    ('342亿', '数据'),
    ('76亿', '数据'),
    ('50亿', '数据'),
    ('Asim Munir', '反直觉细节'),
    ('Asim Bajwa', '反直觉细节'),
    ('Marco Rubio', '反直觉细节'),
    ('Rubio', '反直觉细节'),
    ('SIFC', '术语'),
    ('CPEC Authority', '术语'),
    ('FATF', '术语'),
    ('IMF', '术语'),
    ('CSF', '术语'),
    ('DGMO', '术语'),
    ('SBP', '术语'),
    ('换生存', '机制判断'),
    ('难换转型', '机制判断'),
    ('既得利益网络', '机制判断'),
    ('5倍', '口径'),
    ('9年低点', '口径'),
]
for p, label in key_phrases:
    cnt = text.count(p)
    if cnt > 0:
        print(f'  {label} "{p}": {cnt} 次')
print()

# 关键短句统计（机制判断句/收束句）
print("=== 关键短句（机制判断+收束句）统计 ===")
key_short_sentences = [
    '巴基斯坦不是在选边',
    '不是选边',
    '巴基斯坦不是同时打三份工',
    '把三份工的需求绑成一份',
    '不是同时打三份工',
    '综合议价包',
    '分轴经营',
    '结构性需求不断被再生产',
    '结构性需求被再生产',
    '结构性需求不断被再生产出来',
    '换生存',
    '难换转型',
    '能换生存',
    '难换国内改革',
    '换生存易、换转型难',
    '5个证据',
    '五证拼完',
    '5个证据拼完',
    '巴基斯坦的兑换术',
    '汇率储备',
    '分工联盟',
    '军方定边界',
    '文官做交易',
    '信用阀门',
    '分清谁拍板',
    '看清分工的前提',
    '看清三组不对称依赖的前提',
    '巴基斯坦同时经营',
    '巴基斯坦能换到现金',
    '5个工具',
    '结构性需求再生产',
]
total_short = 0
for s in key_short_sentences:
    cnt = text.count(s)
    if cnt > 0:
        total_short += cnt
        print(f'  "{s}": {cnt} 次')
print(f'\n  关键短句总计: {total_short} 次')
print()

# 段落统计
print("=== 段落统计（正文区域）===")
para_count = 0
long_para_count = 0
very_long_para_count = 0
in_body = False
current_para = []
para_data = []
for line in text.split('\n'):
    if line.startswith('## ') and not line.startswith('### '):
        in_body = True
    elif in_body and line.startswith('# '):
        in_body = False
    if in_body:
        if line.strip() == '':
            if current_para:
                para_count += 1
                ptext = ' | '.join(current_para[:1])
                para_data.append((len(current_para), ptext))
                if len(current_para) > 6:
                    long_para_count += 1
                if len(current_para) > 8:
                    very_long_para_count += 1
                current_para = []
        else:
            current_para.append(line)
if current_para:
    para_count += 1
    ptext = ' | '.join(current_para[:1])
    para_data.append((len(current_para), ptext))
    if len(current_para) > 6:
        long_para_count += 1
    if len(current_para) > 8:
        very_long_para_count += 1

print(f'总段落数: {para_count}')
print(f'超 6 行段数: {long_para_count}')
print(f'超 8 行段数: {very_long_para_count}')
print('\n  详细段落长度（行数:首句摘要）:')
for n, t in para_data:
    marker = '**' if n > 6 else ''
    print(f'    {marker}{n}{marker} 行: {t[:60]}')