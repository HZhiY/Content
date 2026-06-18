import re

with open(r'c:/Users/27649/Documents/myproject/Content/巴基斯坦如何把世界变成自己的资源/01_不是夹缝求生，而是管理不对称/06_修订与发布/修订稿 v2.md', 'r', encoding='utf-8') as f:
    text = f.read()

# 按节切分（markdown ## 标题为分界）
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

# 计算每节字数（汉字 + 标点，不含英文字母数字）
def count_cn_punct(s):
    cn_chars = re.findall(r'[\u4e00-\u9fff\u3000-\u303f\uff00-\uffef]', s)
    return len(cn_chars)

total = 0
print("=== 各节字数统计 ===")
for name, content in sections:
    n = count_cn_punct(content)
    total += n
    pct = 0
    print(f'{name}: {n} 字')
print(f'\nTOTAL: {total} 字')

# 统计关键短语
print("\n=== 关键短语统计 ===")
key_phrases = ['兑换术', '三组不对称依赖', '三组结构性约束', '分轴经营', '综合议价包',
               '结构性需求', '60亿', '16.5亿', '43.55亿', '30亿', '9年低点', '5倍',
               '342亿', '247亿', '620亿', '76亿', '50亿', 'SIFC', 'CPEC', 'FATF',
               'IMF', 'SBP', 'CSF', 'DGMO', 'Asim Munir', 'Asim Bajwa',
               '换生存', '难换转型', '既得利益网络', '结构性产物', '结构性需求被再生产']
for p in key_phrases:
    cnt = text.count(p)
    if cnt > 0:
        print(f'  "{p}": {cnt} 次')

# 超 6 行段数
print("\n=== 段落统计 ===")
para_count = 0
long_para_count = 0
in_body = False
current_para = []
for line in text.split('\n'):
    if line.startswith('## ') and not line.startswith('### '):
        in_body = True
    elif in_body and line.startswith('# '):
        in_body = False
    if in_body:
        if line.strip() == '':
            if current_para:
                para_count += 1
                if len(current_para) > 6:
                    long_para_count += 1
                    print(f'  超 6 行段({len(current_para)} 行): {" | ".join(current_para[:2])}...')
                current_para = []
        else:
            current_para.append(line)
if current_para:
    para_count += 1
    if len(current_para) > 6:
        long_para_count += 1
        print(f'  超 6 行段({len(current_para)} 行): {" | ".join(current_para[:2])}...')

print(f'\n总段落数: {para_count}')
print(f'超 6 行段数: {long_para_count}')