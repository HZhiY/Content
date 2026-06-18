#!/usr/bin/env python3
"""Count paragraph characters for a Markdown article.

Usage:
    python scripts/count_paragraph_chars.py path/to/article.md
    python scripts/count_paragraph_chars.py path/to/article.md --json
    python scripts/count_paragraph_chars.py path/to/article.md --max 220
"""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path
from typing import Any

CODE_FENCE_RE = re.compile(r"^\s*```")
HEADING_RE = re.compile(r"^\s{0,3}#{1,6}\s+")
BLOCKQUOTE_RE = re.compile(r"^\s{0,3}>")
LIST_RE = re.compile(r"^\s{0,3}([-*+]\s+|\d+[.)]\s+)")
TABLE_RE = re.compile(r"^\s*\|.*\|\s*$")
HR_RE = re.compile(r"^\s{0,3}(-{3,}|\*{3,}|_{3,})\s*$")


def visible_char_count(text: str, include_spaces: bool = False) -> int:
    text = re.sub(r"[`*_~>#\[\](){}]", "", text)
    if not include_spaces:
        text = re.sub(r"\s+", "", text)
    return len(text)


def collect_paragraphs(markdown: str) -> list[dict[str, Any]]:
    paragraphs: list[dict[str, Any]] = []
    buffer: list[str] = []
    start_line = 0
    in_code = False

    def flush(end_line: int) -> None:
        nonlocal buffer, start_line
        if not buffer:
            return
        text = "\n".join(buffer).strip()
        if text:
            paragraphs.append(
                {
                    "index": len(paragraphs) + 1,
                    "start_line": start_line,
                    "end_line": end_line,
                    "text": text,
                    "chars_no_spaces": visible_char_count(text, include_spaces=False),
                    "chars_with_spaces": visible_char_count(text, include_spaces=True),
                }
            )
        buffer = []
        start_line = 0

    for line_no, line in enumerate(markdown.splitlines(), start=1):
        stripped = line.strip()

        if CODE_FENCE_RE.match(line):
            flush(line_no - 1)
            in_code = not in_code
            continue
        if in_code:
            continue

        if not stripped:
            flush(line_no - 1)
            continue

        if HEADING_RE.match(line) or BLOCKQUOTE_RE.match(line) or LIST_RE.match(line) or TABLE_RE.match(line) or HR_RE.match(line):
            flush(line_no - 1)
            continue

        if not buffer:
            start_line = line_no
        buffer.append(stripped)

    flush(len(markdown.splitlines()))
    return paragraphs


def print_report(path: Path, paragraphs: list[dict[str, Any]], max_chars: int) -> None:
    total_chars = sum(item["chars_no_spaces"] for item in paragraphs)
    over_limit = [item for item in paragraphs if item["chars_no_spaces"] > max_chars]

    print(f"文件：{path}")
    print(f"正文段落数：{len(paragraphs)}")
    print(f"正文段落总字符数（不含空白）：{total_chars}")
    print(f"阈值：单段 {max_chars} 字")
    print(f"超阈值段落：{len(over_limit)}")
    print()

    if over_limit:
        print("## 超阈值段落")
        for item in over_limit:
            preview = item["text"].replace("\n", " ")[:80]
            print(
                f"- P{item['index']} 行 {item['start_line']}-{item['end_line']}："
                f"{item['chars_no_spaces']} 字｜{preview}"
            )
        print()

    print("## 段落明细")
    for item in paragraphs:
        mark = " !" if item["chars_no_spaces"] > max_chars else ""
        preview = item["text"].replace("\n", " ")[:60]
        print(
            f"P{item['index']:03d}{mark}｜行 {item['start_line']}-{item['end_line']}｜"
            f"{item['chars_no_spaces']} 字｜{preview}"
        )


def main() -> None:
    parser = argparse.ArgumentParser(description="Count Markdown paragraph characters")
    parser.add_argument("file", help="Markdown file to analyze")
    parser.add_argument("--max", type=int, default=220, help="Warn when a paragraph exceeds this many characters")
    parser.add_argument("--json", action="store_true", help="Output JSON instead of text report")
    args = parser.parse_args()

    path = Path(args.file).resolve()
    markdown = path.read_text(encoding="utf-8")
    paragraphs = collect_paragraphs(markdown)

    if args.json:
        print(json.dumps({"file": str(path), "max": args.max, "paragraphs": paragraphs}, ensure_ascii=False, indent=2))
    else:
        print_report(path, paragraphs, args.max)


if __name__ == "__main__":
    main()
