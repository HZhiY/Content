#!/usr/bin/env python3
"""Build v4 theme-pack preview HTML from 修订稿 v2 (entry 01) and 修订稿 v4 (entries 02-10).

Output: 一个人做产品/01_网站上线基础设施/09_终稿/01_终稿.html
"""
from pathlib import Path
import re

ROOT = Path(r"c:\Users\27649\Documents\myproject\Content")
PROJECT = ROOT / "一个人做产品" / "01_网站上线基础设施"
V2 = PROJECT / "06_修订与发布" / "修订稿 v2.md"
V4 = PROJECT / "06_修订与发布" / "修订稿 v4.md"
OUT = PROJECT / "09_终稿" / "01_终稿.html"
IMG_DIR = PROJECT / "08_插图" / "images"


def parse_entry(text: str, num: str, title: str, total_cards: int):
    """Parse one entry block. Returns dict with cards and caption.

    Cards are split strictly by `### 图 N｜` headers. Caption is whatever
    comes after `### caption` to end of block.
    """
    cards = {}
    # build a list of (card_index, body_start) markers
    pattern = re.compile(r"### 图\s*(\d+)\s*[｜|].*?\n")
    matches = list(pattern.finditer(text))
    for i, m in enumerate(matches):
        idx = int(m.group(1))
        if idx < 1 or idx > total_cards:
            continue
        body_start = m.end()
        body_end = matches[i + 1].start() if i + 1 < len(matches) else len(text)
        body = text[body_start:body_end]
        # strip trailing "### caption..." section if present
        cap_pos = body.find("### caption")
        if cap_pos >= 0:
            body = body[:cap_pos]
        cards[idx] = body.strip()
    cap_m = re.search(r"### caption\s*\n(.*?)\Z", text, re.DOTALL)
    caption = cap_m.group(1).strip() if cap_m else ""
    return {"num": num, "title": title, "cards": cards, "caption": caption}


def main():
    v2_text = V2.read_text(encoding="utf-8")
    v4_text = V4.read_text(encoding="utf-8")

    entries = []
    # entry 01 from v2
    m = re.search(r"## 图文 01[｜|].*?\n(.*?)(?=\Z)", v2_text, re.DOTALL)
    if m:
        entries.append(parse_entry(m.group(1), "01", "域名到底是什么？", 6))

    # entries 02-10 from v4
    for num in range(2, 11):
        nn = f"{num:02d}"
        m = re.search(rf"## 图文 {nn}[｜|].*?\n(.*?)(?=## 图文|\Z)", v4_text, re.DOTALL)
        if not m:
            continue
        m_title = re.search(r"## 图文 \d+[｜|]([^#\n]+)", v4_text)
        title = m_title.group(1).strip() if m_title else f"图文{nn}"
        entries.append(parse_entry(m.group(1), nn, title, 8))

    # build html
    entries_html = []
    for e in entries:
        total = len(e["cards"])
        cards_html = []
        for i in range(1, total + 1):
            text = e["cards"].get(i, "")
            if not text:
                continue
            img = IMG_DIR / f"card_{e['num']}_{i:02d}.png"
            page_num = f"{e['num']}-{i:02d} / {total:02d}"
            fallback_html = format_card_fallback(text, page_num)
            img_tag = f'<img src="../08_插图/images/card_{e["num"]}_{i:02d}.png" alt="图{i}" onerror="this.parentElement.classList.remove(\'has-image\')">'
            cards_html.append(
                f'<div class="card-item">'
                f'<div class="card-label"><span>图{i}</span></div>'
                f'<div class="card-frame has-image">'
                f'{img_tag}'
                f'<div class="card-fallback">{fallback_html}</div>'
                f'</div>'
                f'</div>'
            )
        cap_html = ""
        if e["caption"]:
            cap_html = (
                f'<div class="caption-section">'
                f'<h2>Caption</h2>'
                f'<p>{escape_html(e["caption"])}</p>'
                f'</div>'
            )
        entries_html.append(
            f'<div class="entry-group">'
            f'<div class="entry-header">'
            f'<span class="entry-num">条目 {e["num"]}</span>'
            f'<span class="entry-title">{escape_html(e["title"])}</span>'
            f'</div>'
            f'<div class="entry-sub">{total} 卡 · caption 一段</div>'
            f'<div class="cards-grid">{"".join(cards_html)}</div>'
            f'{cap_html}'
            f'</div>'
        )

    head = """<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>网站上线基础设施 · 主题包预览 v4 · 一个人做产品</title>
<style>
*, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
html { font-size: 16px; }
body {
  font-family: "PingFang SC", "Microsoft YaHei", "Helvetica Neue", sans-serif;
  background: #fafafa;
  color: #1a1a1a;
  line-height: 1.6;
  -webkit-font-smoothing: antialiased;
  min-height: 100vh;
}
.preview-wrap { max-width: 460px; margin: 0 auto; padding: 1.5rem 1rem 3rem; }
.header { text-align: center; margin-bottom: 2rem; padding-bottom: 1.5rem; border-bottom: 1px solid #ececec; }
.series-tag {
  display: inline-block;
  font-size: 0.7rem;
  color: #666;
  background: #fff;
  border: 1px solid #e0e0e0;
  border-radius: 999px;
  padding: 0.22rem 0.7rem;
  margin-bottom: 0.85rem;
}
.pack-title { font-size: 1.45rem; font-weight: 700; color: #111; line-height: 1.35; margin-bottom: 0.5rem; }
.pack-intro { font-size: 0.82rem; color: #555; line-height: 1.7; padding: 0 0.5rem; }
.pack-intro .accent { color: #2563eb; font-weight: 500; }
.pack-meta { margin-top: 0.85rem; font-size: 0.7rem; color: #999; }
.entry-group { margin-bottom: 2.25rem; }
.entry-header { display: flex; align-items: baseline; gap: 0.5rem; margin-bottom: 0.35rem; }
.entry-num { font-size: 0.95rem; font-weight: 700; color: #2563eb; flex-shrink: 0; }
.entry-title { font-size: 0.95rem; font-weight: 600; color: #1a1a1a; line-height: 1.4; }
.entry-sub { font-size: 0.74rem; color: #888; margin-bottom: 1rem; padding-left: 0.1rem; }
.cards-grid { display: flex; flex-direction: column; gap: 1.1rem; }
.card-item { display: flex; flex-direction: column; gap: 0.45rem; }
.card-label { font-size: 0.72rem; font-weight: 600; color: #555; padding-left: 0.2rem; }
.card-label span { color: #2563eb; margin-right: 0.3rem; }
.card-frame {
  position: relative;
  width: 100%;
  aspect-ratio: 3 / 4;
  border-radius: 12px;
  overflow: hidden;
  box-shadow: 0 4px 20px rgba(0,0,0,0.08), 0 1px 4px rgba(0,0,0,0.04);
  background: #fff;
}
.card-frame img { position: absolute; inset: 0; width: 100%; height: 100%; object-fit: cover; display: block; }
.card-frame.has-image .card-fallback { display: none; }
.card-fallback {
  position: absolute;
  inset: 0;
  padding: 1rem 0.9rem;
  background: linear-gradient(180deg, #fafafa 0%, #f5f3ee 100%);
  display: flex;
  flex-direction: column;
  justify-content: center;
  font-size: 0.86rem;
  color: #1a1a1a;
  line-height: 1.7;
}
.card-fallback .badge {
  position: absolute;
  top: 0.6rem;
  left: 0.6rem;
  font-size: 0.62rem;
  color: #2563eb;
  background: rgba(37,99,235,0.08);
  padding: 0.18rem 0.55rem;
  border-radius: 999px;
  font-weight: 600;
}
.card-fallback .page-num {
  position: absolute;
  bottom: 0.55rem;
  right: 0.7rem;
  font-size: 0.62rem;
  color: #999;
  font-family: monospace;
}
.card-fallback p { margin: 0; }
.card-fallback .line { display: block; }
.card-fallback .gap { margin-top: 0.55rem; display: block; }
.card-fallback .accent { color: #2563eb; font-weight: 600; }
.card-fallback .example { font-family: monospace; background: rgba(0,0,0,0.04); padding: 0 0.25em; border-radius: 3px; }
.card-fallback strong { color: #1a1a1a; font-weight: 700; }
.card-caption { font-size: 0.7rem; color: #999; padding-left: 0.2rem; line-height: 1.55; }
.caption-section {
  margin-top: 1.5rem;
  padding: 0.95rem 1rem;
  background: #fff;
  border-radius: 10px;
  border: 1px solid #e8e8e8;
  box-shadow: 0 2px 8px rgba(0,0,0,0.04);
}
.caption-section h2 {
  font-size: 0.74rem;
  font-weight: 600;
  color: #888;
  margin-bottom: 0.55rem;
  text-transform: uppercase;
  letter-spacing: 0.05em;
}
.caption-section p { font-size: 0.78rem; line-height: 1.7; color: #333; margin: 0; }
.footer-note {
  margin-top: 2rem;
  padding-top: 1.25rem;
  border-top: 1px solid #ececec;
  font-size: 0.7rem;
  color: #aaa;
  text-align: center;
  line-height: 1.6;
}
.footer-note strong { color: #555; }
code {
  font-family: "SF Mono", "Consolas", "Menlo", monospace;
  font-size: 0.82em;
  background: #f3f4f6;
  padding: 0.08em 0.32em;
  border-radius: 3px;
  color: #c2410c;
}
</style>
</head>
<body>
<div class="preview-wrap">
  <div class="header">
    <span class="series-tag">一个人做产品 · 主题包</span>
    <h1 class="pack-title">网站上线基础设施</h1>
    <p class="pack-intro">一个中国个人开发者想把网站上线，需要理解的 <span class="accent">10 个基础概念</span>。<br>10 条图文，6 卡 + 8 卡组合，全部用 <code>mytool.com</code> 实例贯穿。</p>
    <p class="pack-meta">v4 · 全部 9 条统一升级到 8 卡 · 加深"机制 + 坑"</p>
  </div>
"""

    body = "".join(entries_html)

    footer = """
  <div class="footer-note">
    <strong>主题包预览页</strong> · 小红书发布单元 = 单条图文<br>
    本页仅作内容预览；实际发布请按条目拆分成单条图文<br>
    v4 · 2026-06-22
  </div>
</div>
</body>
</html>
"""
    OUT.write_text(head + body + footer, encoding="utf-8")
    print(f"Wrote {OUT}")
    print(f"Entries: {len(entries)}")
    for e in entries:
        print(f"  条目 {e['num']}: {e['title']} · {len(e['cards'])} 卡")


def escape_html(s: str) -> str:
    return (
        s.replace("&", "&amp;")
        .replace("<", "&lt;")
        .replace(">", "&gt;")
        .replace('"', "&quot;")
    )


def format_card_fallback(text: str, page_num: str) -> str:
    """Format card text into pretty fallback HTML preserving structure."""
    lines = text.strip().split("\n")
    paras = []
    cur = []
    for line in lines:
        if line.strip() == "":
            if cur:
                paras.append(" ".join(cur))
                cur = []
        else:
            cur.append(line.strip())
    if cur:
        paras.append(" ".join(cur))

    html_paras = []
    for p in paras:
        # escape and reformat
        p_html = escape_html(p)
        # bold **text**
        p_html = re.sub(r"\*\*(.+?)\*\*", r"<strong>\1</strong>", p_html)
        # code `xxx`
        p_html = re.sub(r"`([^`]+)`", r'<span class="example">\1</span>', p_html)
        html_paras.append(f'<p class="line">{p_html}</p>')

    return (
        f'<span class="badge">图文卡片</span>'
        f'<div class="gap">&nbsp;</div>'
        + "".join(html_paras)
        + f'<span class="page-num">{page_num}</span>'
    )


if __name__ == "__main__":
    main()