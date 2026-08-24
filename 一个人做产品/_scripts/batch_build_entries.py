#!/usr/bin/env python3
"""Batch-build HTML previews and illustration prompts for 一个人做产品 theme packs.

Parses revision markdown (图文组合集 format) and emits:
  - 09_终稿/{NN}_终稿.html per entry
  - prompts fragments appended to 08_插图/prompts.json (or per-entry files)

Usage:
    python 一个人做产品/_scripts/batch_build_entries.py \\
        "一个人做产品/01_网站上线基础设施/06_修订与发布/修订稿 v3.md" \\
        --entries 02-10
"""

from __future__ import annotations

import argparse
import html
import json
import re
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[2]

CARD_STYLE = """    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
    html { font-size: 16px; }
    body {
      font-family: "PingFang SC", "Microsoft YaHei", "Helvetica Neue", sans-serif;
      background: linear-gradient(180deg, #f0f2f5 0%, #e8eaed 100%);
      color: #1a1a1a; line-height: 1.6; -webkit-font-smoothing: antialiased; min-height: 100vh;
    }
    .preview-wrap { max-width: 420px; margin: 0 auto; padding: 1.5rem 1rem 3rem; }
    .header { text-align: center; margin-bottom: 1.75rem; }
    .series-tag {
      display: inline-block; font-size: 0.72rem; color: #666; background: #fff;
      border: 1px solid #e0e0e0; border-radius: 999px; padding: 0.25rem 0.75rem;
      margin-bottom: 0.85rem; letter-spacing: 0.02em;
    }
    h1 { font-size: 1.35rem; font-weight: 700; color: #111; line-height: 1.35; margin-bottom: 0.45rem; }
    .subtitle { font-size: 0.95rem; color: #2563eb; font-weight: 500; line-height: 1.4; }
    .entry-label { font-size: 0.78rem; color: #888; margin-bottom: 1rem; padding-left: 0.15rem; }
    .cards-grid { display: flex; flex-direction: column; gap: 1.25rem; }
    .card-item { display: flex; flex-direction: column; gap: 0.5rem; }
    .card-label { font-size: 0.75rem; font-weight: 600; color: #555; padding-left: 0.2rem; }
    .card-label span { color: #2563eb; margin-right: 0.35rem; }
    .card-frame {
      position: relative; width: 100%; aspect-ratio: 3 / 4; border-radius: 12px;
      overflow: hidden; box-shadow: 0 4px 20px rgba(0,0,0,0.08), 0 1px 4px rgba(0,0,0,0.04); background: #fff;
    }
    .card-frame img { position: absolute; inset: 0; width: 100%; height: 100%; object-fit: cover; display: none; }
    .card-frame.has-image img { display: block; }
    .card-frame.has-image .card-fallback { display: none; }
    .card-fallback {
      position: absolute; inset: 0; display: flex; flex-direction: column;
      padding: 1.5rem 1.25rem 1.25rem; background: #fff; overflow: hidden;
    }
    .card-fallback.cover {
      justify-content: center; align-items: flex-start;
      background: linear-gradient(165deg, #fafafa 0%, #f5f5f5 100%);
    }
    .page-num { position: absolute; bottom: 1rem; right: 1.1rem; font-size: 0.68rem; color: #bbb; }
    .cover-line1 { font-size: 1.25rem; font-weight: 700; color: #2563eb; line-height: 1.35; margin-bottom: 0.65rem; }
    .cover-line2 { font-size: 1.05rem; font-weight: 600; color: #1a1a1a; line-height: 1.4; }
    .card-body { flex: 1; display: flex; flex-direction: column; gap: 0.55rem; font-size: 0.88rem; line-height: 1.65; color: #222; }
    .card-body p { margin: 0; }
    .flow-arrow { color: #2563eb; font-weight: 500; }
    code {
      font-family: "SF Mono", "Consolas", monospace; font-size: 0.82em;
      background: #f3f4f6; padding: 0.1em 0.35em; border-radius: 3px; color: #c2410c;
    }
    .caption-section {
      margin-top: 1.75rem; padding: 1.1rem 1.15rem; background: #fff;
      border-radius: 10px; border: 1px solid #e8e8e8; box-shadow: 0 2px 8px rgba(0,0,0,0.04);
    }
    .caption-section h2 { font-size: 0.78rem; font-weight: 600; color: #888; margin-bottom: 0.65rem; }
    .caption-section p { font-size: 0.85rem; line-height: 1.75; color: #333; }
    .footer-note { margin-top: 1.5rem; text-align: center; font-size: 0.68rem; color: #aaa; }
"""

IMG_PROMPT_STYLE = (
    "Vertical 3:4 note card, off-white or cream background, minimalist product-doc aesthetic, "
    "NOT a marketing poster. Black body text, blue accent, orange for examples. "
    "Clean sans-serif typography, mobile-friendly. No photos, no stickers, no training-course aesthetics."
)


def parse_entries(md_text: str) -> list[dict[str, Any]]:
    entries: list[dict[str, Any]] = []
    blocks = re.split(r"\n## 图文 (\d+)｜", md_text)
    for i in range(1, len(blocks), 2):
        num = int(blocks[i])
        body = blocks[i + 1]
        title_line = body.split("\n", 1)[0].strip()
        cards: list[dict[str, str]] = []
        caption = ""
        for m in re.finditer(
            r"### (图 \d+｜[^\n]+)\n\n([\s\S]*?)(?=\n### |\n---|\Z)", body
        ):
            label = m.group(1)
            text = m.group(2).strip()
            cards.append({"label": label, "text": text})
        cap_m = re.search(r"### caption\n\n([\s\S]*?)(?=\n---|\n## |\Z)", body)
        if cap_m:
            caption = cap_m.group(1).strip()
        entries.append(
            {"num": num, "title": title_line, "cards": cards, "caption": caption}
        )
    return entries


def inline_code(text: str) -> str:
    parts = re.split(r"`([^`]+)`", text)
    out: list[str] = []
    for i, part in enumerate(parts):
        if i % 2 == 1:
            out.append(f"<code>{html.escape(part)}</code>")
        else:
            out.append(html.escape(part))
    return "".join(out)


def card_body_html(text: str, is_cover: bool) -> str:
    lines = [ln.strip() for ln in text.split("\n") if ln.strip()]
    if is_cover and len(lines) >= 2:
        return (
            f'<p class="cover-line1">{inline_code(lines[0])}</p>'
            f'<p class="cover-line2">{inline_code(lines[1])}</p>'
        )
    if is_cover and len(lines) == 1:
        return f'<p class="cover-line1">{inline_code(lines[0])}</p>'
    paras = []
    for ln in lines:
        if ln.startswith("→") or "→" in ln:
            paras.append(f'<p><span class="flow-arrow">→</span> {inline_code(ln.lstrip("→ ").strip())}</p>')
        else:
            paras.append(f"<p>{inline_code(ln)}</p>")
    return "\n                ".join(paras)


def build_html(entry: dict[str, Any], note_title: str, theme: str) -> str:
    n = entry["num"]
    nn = f"{n:02d}"
    total = len(entry["cards"])
    cards_html: list[str] = []
    for i, card in enumerate(entry["cards"], 1):
        ci = f"{i:02d}"
        img = f"../08_插图/images/card_{nn}_{ci}.png"
        is_cover = i == 1
        fallback_cls = "card-fallback cover" if is_cover else "card-fallback"
        body = card_body_html(card["text"], is_cover)
        cards_html.append(f"""
        <article class="card-item">
          <p class="card-label"><span>{ci}</span>{html.escape(card['label'])}</p>
          <div class="card-frame" data-card="{ci}">
            <img src="{img}" alt="{html.escape(card['label'])}">
            <div class="{fallback_cls}">
              <div class="card-body">{body}</div>
              <span class="page-num">{ci} / {total:02d}</span>
            </div>
          </div>
        </article>""")

    cap = inline_code(entry["caption"]) if entry["caption"] else ""
    return f"""<!DOCTYPE html>
<html lang="zh-CN">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>{html.escape(note_title)}</title>
  <style>
{CARD_STYLE}
  </style>
</head>
<body>
  <div class="preview-wrap">
    <header class="header">
      <div class="series-tag">一个人做产品 · 图文 {nn}</div>
      <h1>{html.escape(note_title)}</h1>
      <p class="subtitle">{html.escape(entry['title'])}</p>
    </header>
    <section class="entry-group">
      <p class="entry-label">主题包：{html.escape(theme)} · {total} 张卡片</p>
      <div class="cards-grid">
{"".join(cards_html)}
      </div>
    </section>
    <section class="caption-section">
      <h2>Caption</h2>
      <p>{cap}</p>
    </section>
    <p class="footer-note">小红书图文预览 · 卡片 3:4 · 08_插图/images/card_{nn}_01–{total:02d}.png</p>
  </div>
  <script>
    document.querySelectorAll('.card-frame img').forEach(function (img) {{
      img.addEventListener('load', function () {{
        if (img.naturalWidth > 0) img.parentElement.classList.add('has-image');
      }});
      img.addEventListener('error', function () {{ img.style.display = 'none'; }});
      if (img.complete && img.naturalWidth > 0) img.parentElement.classList.add('has-image');
    }});
  </script>
</body>
</html>
"""


def build_prompt(entry: dict[str, Any], card_idx: int, card: dict[str, str]) -> dict[str, Any]:
    n = entry["num"]
    nn = f"{n:02d}"
    ci = f"{card_idx:02d}"
    total = len(entry["cards"])
    text_escaped = card["text"].replace("\n", " newline ")
    return {
        "id": f"card_{nn}_{ci}",
        "filename": f"card_{nn}_{ci}.png",
        "position": f"图文{nn} / {card['label']}",
        "function": card["label"],
        "description_cn": card["text"][:120],
        "prompt": (
            f"{IMG_PROMPT_STYLE} Chinese text exactly: {text_escaped}. "
            f"Page number 「{ci} / {total:02d}」 bottom-right."
        ),
        "aspect_ratio": "3:4",
    }


def parse_range(s: str) -> set[int]:
    result: set[int] = set()
    for part in s.split(","):
        part = part.strip()
        if "-" in part:
            a, b = part.split("-", 1)
            result.update(range(int(a), int(b) + 1))
        else:
            result.add(int(part))
    return result


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("revision_md", type=Path)
    ap.add_argument("--entries", default="02-10", help="e.g. 02-10 or 2,3,5")
    ap.add_argument("--theme", default="网站上线基础设施")
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    md_path = args.revision_md if args.revision_md.is_absolute() else ROOT / args.revision_md
    pack_dir = md_path.parent.parent
    out_dir = pack_dir / "09_终稿"
    img_dir = pack_dir / "08_插图"
    prompts_path = img_dir / "prompts.json"

    entries = parse_entries(md_path.read_text(encoding="utf-8"))
    wanted = parse_range(args.entries)

    existing: dict[str, Any] = {}
    if prompts_path.exists():
        existing = json.loads(prompts_path.read_text(encoding="utf-8"))
    all_images: list[dict[str, Any]] = list(existing.get("images", []))
    existing_ids = {img["id"] for img in all_images}

    titles: dict[int, str] = {
        2: "买了服务器，为什么还看不到网站？",
        3: "备案到底是什么？先搞清它不是买域名",
        4: "HTTPS 小锁，靠的不是域名本身",
        5: "CDN 解决的是「离用户太远」",
        6: "域名、服务器、备案，三件事别混",
        7: "不是后缀决定备案，是服务器在哪",
        8: "一个网页上线，至少经过这六步",
        9: "个人项目，静态站往往更现实",
        10: "轻量服务器，适合先跑起来",
    }

    for entry in entries:
        if entry["num"] not in wanted:
            continue
        nn = f"{entry['num']:02d}"
        note_title = titles.get(entry["num"], entry["title"])
        html_content = build_html(entry, note_title, args.theme)
        html_path = out_dir / f"{nn}_终稿.html"
        if args.dry_run:
            print(f"[dry-run] would write {html_path}")
        else:
            out_dir.mkdir(parents=True, exist_ok=True)
            html_path.write_text(html_content, encoding="utf-8")
            print(f"Wrote {html_path}")

        for i, card in enumerate(entry["cards"], 1):
            prompt = build_prompt(entry, i, card)
            if prompt["id"] not in existing_ids:
                all_images.append(prompt)
                existing_ids.add(prompt["id"])

    if not args.dry_run and wanted:
        payload = {**existing, "images": all_images}
        prompts_path.write_text(
            json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
        print(f"Updated {prompts_path} ({len(all_images)} images total)")


if __name__ == "__main__":
    main()
