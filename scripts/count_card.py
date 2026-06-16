import re
text = open(r'c:\Users\27649\Documents\myproject\Content\美国如何从工业国变成金融国\10_为什么美联储像是从摩根图书馆里长出来的\02_洞察及主题\结构命题审查卡.md', encoding='utf-8').read()
print('Total chars:', len(text))
print('Chinese chars:', len(re.findall(r'[\u4e00-\u9fff]', text)))
print('Lines:', text.count('\n') + 1)
