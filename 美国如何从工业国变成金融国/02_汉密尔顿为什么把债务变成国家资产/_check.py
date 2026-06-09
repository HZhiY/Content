#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import os
import sys
import re

# 通过脚本所在目录 + 相对路径
script_dir = os.path.dirname(os.path.abspath(__file__))
file_path = os.path.join(script_dir, '03_草稿', '草稿.md')

print(f'FILE_PATH: {file_path}')
print(f'FILE_EXISTS: {os.path.exists(file_path)}')

if not os.path.exists(file_path):
    sys.exit(1)

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

total_no_space = len(re.sub(r'\s', '', content))
total_with_space = len(content)
print(f'TOTAL_NO_SPACE: {total_no_space}')
print(f'TOTAL_WITH_SPACE: {total_with_space}')

# 段落切分：按空行（含 \n\n / \r\n\r\n）
paras = []
for block in re.split(r'\r?\n\r?\n+', content):
    text = block.strip()
    if not text:
        continue
    if text.startswith('#') or text.startswith('---') or text.startswith('*'):
        continue
    paras.append(text)

max_len = 0
max_idx = -1
over_100 = 0
over_80 = 0
over_60 = 0
for i, p in enumerate(paras):
    l = len(p)
    if l > max_len:
        max_len = l
        max_idx = i
    if l > 100:
        over_100 += 1
    if l > 80:
        over_80 += 1
    if l > 60:
        over_60 += 1

print(f'PARAGRAPH_COUNT: {len(paras)}')
print(f'MAX_LEN: {max_len} (idx={max_idx})')
print(f'OVER_60: {over_60}')
print(f'OVER_80: {over_80}')
print(f'OVER_100: {over_100}')
print('---PARAGRAPHS_OVER_60---')
for i, p in enumerate(paras):
    l = len(p)
    if l > 60:
        preview = p if len(p) <= 80 else p[:80] + '...'
        print(f'[{i} LEN={l}] {preview}')
