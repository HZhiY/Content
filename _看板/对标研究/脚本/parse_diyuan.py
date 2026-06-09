# -*- coding: utf-8 -*-
"""Parse diyuan paste (title line + stats line) and generate markdown."""

import re
from pathlib import Path

BASE = Path(__file__).parent
INPUT = BASE / "diyuan_input.txt"
OUTPUT = BASE / "benchmark_diyuan_output.md"
FINAL = BASE / "对标数据_2026-06-09_地缘历史档案馆.md"

SCRAPE_DATE = "2026-06-09"


def parse_reads(s: str) -> int:
    s = s.strip()
    if s.endswith("万"):
        return int(float(s[:-1]) * 10000)
    return int(s.replace(",", ""))


def normalize_date(d: str) -> str:
    d = d.strip()
    if re.match(r"^\d{4}年\d{1,2}月\d{1,2}日$", d):
        m = re.match(r"^(\d{4})年(\d{1,2})月(\d{1,2})日$", d)
        return f"{m.group(1)}-{int(m.group(2)):02d}-{int(m.group(3)):02d}"
    if re.match(r"^\d{2}-\d{2}$", d):
        return f"2026-{d}"
    if d in ("1小时前", "2小时前", "3小时前"):
        return f"{SCRAPE_DATE} ({d})"
    if d == "20小时前":
        return f"2026-06-08 ({d})"
    if d == "21小时前":
        return f"2026-06-08 ({d})"
    if d == "22小时前":
        return f"2026-06-08 ({d})"
    if d == "23小时前":
        return f"2026-06-08 ({d})"
    if d.startswith("昨天"):
        return f"2026-06-08 {d.replace('昨天', '').strip()} ({d})".replace("  ", " ")
    if d.startswith("前天"):
        return f"2026-06-07 {d.replace('前天', '').strip()} ({d})".replace("  ", " ")
    m = re.match(r"^(\d+)天前$", d)
    if m:
        from datetime import datetime, timedelta
        days = int(m.group(1))
        dt = datetime.strptime(SCRAPE_DATE, "%Y-%m-%d") - timedelta(days=days)
        return f"{dt.strftime('%Y-%m-%d')} ({d})"
    return d


def parse_input(text: str):
    lines = [ln.strip() for ln in text.splitlines()]
    articles = []
    i = 0
    stats_re = re.compile(
        r"^([\d.]+万?)阅读(?:(\d+)评论)?(.+)$"
    )
    skip_prefixes = (
        "更多", "搜索", "消息", "发布", "地缘历史", "979", "169", "认证",
        "简介", "更多信息", "关注", "全部", "近期", "©", "扫黄", "网络",
        "侵权", "MCN", "未成年", "算法", "京ICP", "营业执照", "药品",
        "跟帖", "京公网", "网信", "公司", "首页", "反馈", "下载", "扫码", "顶部",
    )
    while i < len(lines):
        line = lines[i]
        if not line or any(line.startswith(p) for p in skip_prefixes):
            i += 1
            continue
        if i + 1 >= len(lines):
            break
        nxt = lines[i + 1]
        m = stats_re.match(nxt)
        if m and not stats_re.match(line):
            reads = m.group(1)
            comments = int(m.group(2) or 0)
            date = m.group(3).strip()
            articles.append((line, reads, comments, date))
            i += 2
            continue
        i += 1
    return articles


def main():
    if not INPUT.exists():
        raise SystemExit(f"Missing {INPUT}")
    text = INPUT.read_text(encoding="utf-8")
    articles = parse_input(text)
    if not articles:
        raise SystemExit("No articles parsed")

    nums = [parse_reads(r) for _, r, _, _ in articles]
    comment_sum = sum(c for _, _, c, _ in articles)

    lines = [
        "# 对标账号数据：地缘历史档案馆",
        "",
        "> 数据来源：头条账号主页列表",
        f"> 抓取时间：{SCRAPE_DATE}",
        "> 生成脚本：parse_diyuan.py",
        "",
        "---",
        "",
        "## 账号信息",
        "",
        "| 字段 | 值 |",
        "|------|------|",
        "| 账号名 | 地缘历史档案馆 |",
        "| 获赞 | 979.2 万 |",
        "| 粉丝 | 169.4 万 |",
        "| 关注 | 64 |",
        "| 认证 | 头条新锐创作者 |",
        "| 简介 | 历史系硕士在读，分享那些你不知道的历史 |",
        f"| 文章数 | {len(articles)} |",
        "",
        "---",
        "",
        "## 字段说明",
        "",
        "| 字段 | 说明 |",
        "|------|------|",
        "| 序号 | 按用户提供的原始顺序 |",
        "| 标题 | 头条原文标题 |",
        "| 阅读 | 原数据阅读量 |",
        "| 阅读(数值) | 换算整数 |",
        "| 评论 | 评论数 |",
        "| 日期 | 发布日期 |",
        "",
        "> 备注：主页列表未提供点赞、收藏、展现量、涨粉等字段。",
        "",
        "---",
        "",
        "## 文章列表",
        "",
        "| 序号 | 标题 | 阅读 | 阅读(数值) | 评论 | 日期 |",
        "|------|------|------|------------|------|------|",
    ]

    for i, (title, reads, comments, date) in enumerate(articles, 1):
        title_esc = title.replace("|", "\\|")
        rn = parse_reads(reads)
        dn = normalize_date(date)
        lines.append(f"| {i} | {title_esc} | {reads} | {rn} | {comments} | {dn} |")

    sorted_nums = sorted(nums)
    median = sorted_nums[len(sorted_nums) // 2]
    lines.extend([
        "",
        "---",
        "",
        "## 统计摘要",
        "",
        f"- 总篇数：{len(articles)}",
        f"- 阅读合计：{sum(nums):,}",
        f"- 阅读最高：{max(nums):,}",
        f"- 阅读最低：{min(nums):,}",
        f"- 阅读中位数：{median:,}",
        f"- 评论合计：{comment_sum:,}",
        f"- 阅读 ≥1万：{sum(1 for n in nums if n >= 10000)} 篇",
        f"- 阅读 ≥5万：{sum(1 for n in nums if n >= 50000)} 篇",
        f"- 阅读 ≥10万：{sum(1 for n in nums if n >= 100000)} 篇",
        "",
    ])

    content = "\n".join(lines)
    OUTPUT.write_text(content, encoding="utf-8")
    FINAL.write_text(content, encoding="utf-8")
    print(f"Parsed {len(articles)} articles -> {FINAL}")


if __name__ == "__main__":
    main()
