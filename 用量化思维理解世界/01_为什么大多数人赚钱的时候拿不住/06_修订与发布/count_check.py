import re
import sys

filepath = r'C:\Users\27649\Documents\myproject\Content\用量化思维理解世界\01_为什么大多数人赚钱的时候拿不住\06_修订与发布\修订稿 v1.md'

with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

lines = content.split('\n')

body_start = 0
for i, line in enumerate(lines):
    if line.startswith('## '):
        body_start = i
        break

body_text = '\n'.join(lines[body_start:])
sections = body_text.split('---')
section_names = ['引言', '第一节', '第二节', '第三节', '第四节', '结尾']
total = 0

for i, section in enumerate(sections):
    section = section.strip()
    if not section:
        continue
    clean = re.sub(r'#+ ', '', section)
    clean = re.sub(r'\*\*', '', clean)
    clean = re.sub(r'> ', '', clean)
    clean = re.sub(r'\n+', '', clean)
    clean = re.sub(r'---', '', clean)
    cn_chars = len(re.findall(r'[\u4e00-\u9fff]', clean))
    cn_punct = len(re.findall(r'[\u3000-\u303f\uff00-\uffef]', clean))
    ascii_punct = len(re.findall(r'[,.\!?;:()\-]', clean))
    word_count = cn_chars + cn_punct + ascii_punct
    name = section_names[i] if i < len(section_names) else f'Section {i}'
    print(f'{name}: {word_count}')
    total += word_count

print(f'Total: {total}')
