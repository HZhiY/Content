#!/usr/bin/env python3
"""统计 修订稿 v5.md 每条/每卡/caption 字数（汉字 + 标点）。"""
from pathlib import Path
import re
import sys

ROOT = Path(r"c:\Users\27649\Documents\myproject\Content")
V5 = ROOT / "一个人做产品" / "01_网站上线基础设施" / "06_修订与发布" / "修订稿 v5.md"


def count_cn(text: str) -> int:
    """Count Chinese chars + Chinese/Unicode punctuation. Excludes ASCII letters/digits/spaces."""
    n = 0
    for ch in text:
        # Chinese chars
        if "\u4e00" <= ch <= "\u9fff":
            n += 1
        elif "\u3400" <= ch <= "\u4dbf":  # CJK ext A
            n += 1
        # Chinese/half-width punctuation
        elif ch in "，。！？；：「」『』《》（）()【】——……·、,!?;:":
            n += 1
        # Other unicode symbols that aren't ASCII letters/digits/whitespace
        elif ord(ch) > 127 and not ch.isascii():
            n += 1
    return n


def main():
    text = V5.read_text(encoding="utf-8")

    # Strip file header
    body_start = text.find("## 图文 01")
    if body_start < 0:
        print("ERR: no entry 01 found")
        sys.exit(1)
    body = text[body_start:]

    # Match each entry
    entry_pat = re.compile(r"## 图文 (\d+)[｜|](.*?)\n(.*?)(?=## 图文 \d+|\Z)", re.DOTALL)
    card_pat = re.compile(r"### 图\s*(\d+)\s*[｜|]([^\n]*)\n(.*?)(?=### 图\s*\d+|### caption|\Z)", re.DOTALL)
    cap_pat = re.compile(r"### caption\s*\n(.*?)(?=## 图文|\Z)", re.DOTALL)

    print(f"{'条目':<6}{'标题':<28}{'卡数':<6}{'卡片正文小计':<14}{'caption':<10}{'合计':<8}{'目标区间':<10}")
    print("-" * 90)

    grand_total = 0
    total_card_chars = []  # collect per-card for stats

    for m in entry_pat.finditer(body):
        num = m.group(1)
        title = m.group(2).strip()
        block = m.group(3)

        card_sum = 0
        card_counts = []
        for cm in card_pat.finditer(block):
            idx = cm.group(1)
            body_text = cm.group(3).strip()
            n = count_cn(body_text)
            card_sum += n
            card_counts.append((idx, n))

        cap_m = cap_pat.search(block)
        cap_text = cap_m.group(1).strip() if cap_m else ""
        cap_n = count_cn(cap_text)

        entry_total = card_sum + cap_n
        grand_total += entry_total

        # Range flag
        flag = ""
        if entry_total > 800:
            flag = "超800"
        elif entry_total < 500:
            flag = "低于500"
        else:
            flag = "OK"

        print(f"{num:<6}{title[:26]:<28}{len(card_counts):<6}{card_sum:<14}{cap_n:<10}{entry_total:<8}{flag}")

        for idx, n in card_counts:
            total_card_chars.append((num, idx, n))
            mark = "超90" if n > 90 else ("低" if n < 30 else "")
            print(f"  图{idx}: {n} 字 {mark}")
        print(f"  caption: {cap_n} 字 {'超200' if cap_n > 200 else ''}")

    print("-" * 90)
    print(f"整本合计：{grand_total} 字")
    print()

    # Summary
    print("=== 单卡超 90 字 ===")
    over90 = [(e, i, n) for e, i, n in total_card_chars if n > 90]
    for e, i, n in over90:
        print(f"  条目 {e} 图 {i}: {n}")

    print()
    print("=== caption 超 200 字 ===")
    for m in entry_pat.finditer(body):
        num = m.group(1)
        block = m.group(3)
        cap_m = cap_pat.search(block)
        if cap_m:
            cap_n = count_cn(cap_m.group(1).strip())
            if cap_n > 200:
                print(f"  条目 {num}: {cap_n}")


if __name__ == "__main__":
    main()