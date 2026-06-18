import re

FILE = r'c:/Users/27649/Documents/myproject/Content/巴基斯坦如何把世界变成自己的资源/01_不是夹缝求生，而是管理不对称/06_修订与发布/修订稿 v2.md'

with open(FILE, 'r', encoding='utf-8') as f:
    text = f.read()

# More careful checks
print('=== Check key phrases ===')
checks = [
    '不是选边', '不是在选边', '不是在选边，是同时',
    '同时管理', '同时经营',
    '三组不对称依赖',
    '分轴经营',
    '综合议价包',
    '结构性需求', '再生产',
    '兑换术',
    '换生存', '难换转型', '换生存易', '换生存难',
]
for c in checks:
    cnt = len(re.findall(re.escape(c), text))
    print(f'  "{c}": {cnt}')

print()
print('=== Check 4证 出场 (variants) ===')
fork = [
    ('SIFC', 'SIFC'),
    ('CPEC Authority', 'CPEC Authority'),
    ('Rubio', 'Rubio'),
    ('Asim Munir', 'Asim Munir'),
    ('Asim Bajwa', 'Asim Bajwa'),
    ('IMF 4轮', '(2008.*2013.*2019.*2023|2008年.*2013年.*2019年.*2023年|SBA.*EFF)'),
]
for name, pat in fork:
    cnt = len(re.findall(pat, text))
    print(f'  {name}: {cnt}')

print()
print('=== Check 5证 出场 (variants) ===')
trans = [
    ('IMF 4轮', 'IMF'),
    ('60亿 vs 16.5亿', '16.5'),
    ('43.55亿', '43.55'),
    ('沙特存款展期3次', '续作|展期'),
    ('SBP 时间链', '30.9亿|30 多亿|34 亿'),
    ('FATF 灰白名单', 'FATF|灰名单'),
]
for name, pat in trans:
    cnt = len(re.findall(pat, text))
    print(f'  {name}: {cnt}')

print()
print('=== Check each for specific occurrences with context ===')
# Print lines containing specific keywords
keywords_to_find = ['不是选边', '三组不对称依赖', '分轴经营', '综合议价包', '兑换术', '结构性需求', '再生产']
lines = text.split('\n')
for kw in keywords_to_find:
    print(f'\n--- Lines containing "{kw}" ---')
    for i, line in enumerate(lines):
        if kw in line:
            print(f'  Line {i}: {line.strip()[:120]}')