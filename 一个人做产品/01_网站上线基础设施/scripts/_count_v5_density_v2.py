"""Count characters (汉字+标点) per card per section, per article."""
import re

with open(r'c:\Users\27649\Documents\myproject\Content\一个人做产品\01_网站上线基础设施\06_修订与发布\修订稿 v5.md', 'r', encoding='utf-8') as f:
    text = f.read()

# Force utf-8 output
import sys
sys.stdout.reconfigure(encoding='utf-8')

# Find all sections: split on "## 图文 NN｜" boundaries
# Then within each section, split on "### 图 N｜" boundaries and "### caption"

# Strategy: parse article by article
articles = re.split(r'(?=^## 图文 \d+｜)', text, flags=re.MULTILINE)
print(f'Total articles: {len(articles)}')

# For each article, count sub-cards
def count_chars(s):
    """Count 汉字 + 标点 = total characters in s, excluding whitespace.
    We include all Chinese characters and ASCII punctuation, but exclude English letters/numbers and whitespace.
    """
    # Remove all whitespace
    s2 = re.sub(r'\s+', '', s)
    return len(s2)

def detailed_count(s):
    """Count 汉字 + 中文标点 + ASCII 标点.
    We define: any character that is not English letter, digit, whitespace, and not the markdown markup `*` `_`.
    Actually simpler: remove whitespace + markdown markup markers; count what's left.
    """
    # Remove markdown bold markers ** and *
    s2 = re.sub(r'\*+', '', s)
    # Remove whitespace
    s2 = re.sub(r'\s+', '', s2)
    # Count all chars now
    return len(s2)

# For each article
results = []
for art in articles:
    if not art.strip():
        continue
    # Extract article title (e.g. "图文 01｜域名到底是什么？")
    m = re.match(r'## 图文 (\d+)｜([^\n]+)', art)
    if not m:
        continue
    art_num = int(m.group(1))
    art_title = m.group(2).strip()

    # Find all cards: "### 图 N｜xxx"
    card_pattern = re.compile(r'### (图 \d+|caption)\｜([^\n]+)\n(.*?)(?=^### |\Z)', re.MULTILINE | re.DOTALL)
    cards = []
    for cm in card_pattern.finditer(art):
        cname = cm.group(1)
        ctitle = cm.group(2).strip()
        cbody = cm.group(3).strip()
        cnt = detailed_count(cbody)
        cards.append((cname, ctitle, cnt, cbody[:60]))

    art_total = sum(c[2] for c in cards)
    results.append((art_num, art_title, cards, art_total))

# Print
for art_num, art_title, cards, art_total in results:
    print(f'\n=== 条目 {art_num:02d}: {art_title} (合计 {art_total} 字) ===')
    for cname, ctitle, cnt, body60 in cards:
        flag = ''
    if cnt > 90:
        flag = ' OVER90'
    elif cnt < 30:
        flag = ' UNDER30'
    if flag:
        print(f'ALERT {art_num:02d} {cname} = {cnt} {flag}')
# print full csv-style table - 写到文件
with open(r'c:\Users\27649\Documents\myproject\Content\一个人做产品\01_网站上线基础设施\scripts\_count_v5_cardtable.txt', 'w', encoding='utf-8') as fout:
    fout.write('条目,卡片,字数,标记\n')
    for art_num, art_title, cards, art_total in results:
        for cname, ctitle, cnt, _ in cards:
            mark = ''
            if cnt > 90: mark = 'OVER90'
            elif cnt < 30: mark = 'UNDER30'
            fout.write(f'{art_num:02d},{cname},{cnt},{mark}\n')
        fout.write(f'{art_num:02d},整条合计,{art_total},\n')
    fout.write(f'整本,合计,{total},\n')
    print(f'  {cname:8s} {ctitle[:30]:30s} = {cnt:3d}{flag}  | {body60}')

# 整本 total
total = sum(r[3] for r in results)
print(f'\n\n整本 10 条合计 = {total} 字 (caption 含内)')
