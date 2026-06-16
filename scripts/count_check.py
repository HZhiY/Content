import re
with open(r'c:\Users\27649\Documents\myproject\Content\美国如何从工业国变成金融国\10_为什么美联储像是从摩根图书馆里长出来的\02_洞察及主题\传播学审查卡.md', 'r', encoding='utf-8') as f:
    content = f.read()
cn_chars = re.findall(r'[\u4e00-\u9fff]', content)
print(f"Total Chinese chars: {len(cn_chars)}")
print(f"Total chars: {len(content)}")
# rough Chinese + punctuation count
cn_punct = re.findall(r'[\u4e00-\u9fff\u3000-\u303f\uff00-\uffef]', content)
print(f"Chinese + punctuation: {len(cn_punct)}")