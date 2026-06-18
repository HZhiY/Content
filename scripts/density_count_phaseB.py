# -*- coding: utf-8 -*-
import re

with open(r'c:\Users\27649\Documents\myproject\Content\巴基斯坦如何把世界变成自己的资源\01_不是夹缝求生，而是管理不对称\06_修订与发布\修订稿 v1.md', 'r', encoding='utf-8') as f:
    content = f.read()

# 跳过文件头 metadata + 章节标题占位
# 找到第一个 H2 标题"## 引言"作为正文起点
start_match = re.search(r'## 引言', content)
if not start_match:
    raise SystemExit('No intro marker found')

start_pos = start_match.start()

# 找到结尾（"---" 之后无正文）
end_match = re.search(r'\n---\s*$', content)
end_pos = end_match.start() if end_match else len(content)

body = content[start_pos:end_pos]
# 去分隔线/空行
body_clean = re.sub(r'^\s*---\s*$', '', body, flags=re.MULTILINE)

total = len(body_clean)
print(f'[Body 总字符（含换行/空格）]: {total}')

# 汉字+标点 = 过滤掉空白后所有字符
non_blank = re.sub(r'\s', '', body_clean)
print(f'[Body 非空白字符总数]: {len(non_blank)}')

# 仅汉字
cn_only = re.findall(r'[\u4e00-\u9fff]', body_clean)
print(f'[Body 仅汉字]: {len(cn_only)}')

# 标点 (含全角/半角)
punct = re.findall(r'[\u3000-\u303f\uff00-\uffef\u2018\u2019\u201c\u201d\u2026\u2014]', body_clean)
print(f'[Body 标点]: {len(punct)}')

# 各节字数 (汉字+标点)
section_pattern = re.compile(r'## (引言|[一二三四五六七八、]+、?[^\n]*?)\n', re.MULTILINE)
matches = list(section_pattern.finditer(content))
print('\n=== 各节字数 ===')
for i, m in enumerate(matches):
    sec_start = m.end()
    sec_end = matches[i+1].start() if i+1 < len(matches) else end_pos
    sec_body = content[sec_start:sec_end]
    sec_body_clean = re.sub(r'^\s*---\s*$', '', sec_body, flags=re.MULTILINE)
    sec_non_blank = re.sub(r'\s', '', sec_body_clean)
    cn = len(re.findall(r'[\u4e00-\u9fff]', sec_body_clean))
    pt = len(re.findall(r'[\u3000-\u303f\uff00-\uffef\u2018\u2019\u201c\u201d\u2026\u2014]', sec_body_clean))
    print(f'  {m.group(1).strip()}: 总={len(sec_non_blank)}, 汉字={cn}, 标点={pt}')

# 关键短句与机制词出现次数
print('\n=== 关键短句与机制词 ===')
items = [
    '巴基斯坦不是在选边',
    '三组不对称依赖',
    '分轴经营',
    '综合议价包',
    '兑换术',
    '结构性需求',
    '换生存',
    '难换转型',
    '结构性约束',
    '结构性产物',
    '60 亿',
    '16.5 亿',
    '43.55 亿',
    '30 亿',
    '20 亿',
    '50 亿',
    '620 亿',
    '247 亿',
    '42 亿',
    '76 亿',
    '267 亿',
    'IMF',
    '海湾',
    '结构性需求不断被再生产',
    '巴基斯坦的三份工',
    '多线兑换',
    '不同时打三份工',
    '把三份工的需求绑成一份',
    '6000',
    '6,500',
    '6580',
    '5,580',
    '720',
    '1,000',
    '4,000',
    '375 万吨',
    '5 个证据',
    '5 个工具',
    '4 个核心时刻',
    '7 个反常识时刻',
    '5 证',
    '4 证',
]
for kw in items:
    n = body.count(kw)
    print(f'  {kw}: {n}')

# 段落超 6 行数
print('\n=== 段落超 6 行 ===')
paragraphs = re.split(r'\n\s*\n', body)
over = 0
for i, p in enumerate(paragraphs):
    p = p.strip()
    if not p:
        continue
    line_count = p.count('\n') + 1
    if line_count > 6:
        over += 1
        preview = p[:50].replace('\n', ' / ')
        print(f'  P{i} (lines={line_count}): {preview}...')
print(f'超 6 行段落总数: {over}')
