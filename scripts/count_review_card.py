import re
with open(r'C:\Users\27649\Documents\myproject\Content\美国如何从工业国变成金融国\10_为什么美联储像是从摩根图书馆里长出来的\02_洞察及主题\传播学审查卡.md', 'r', encoding='utf-8') as f:
    text = f.read()
chinese = len(re.findall(r'[\u4e00-\u9fff]', text))
print(f'Chinese chars: {chinese}')
print(f'Total chars: {len(text)}')
