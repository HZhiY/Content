#!/usr/bin/env python3
"""Insert missing 图 6 into 修订稿 v4 for entries 02-10.

v4 was written by replacing card 6 with cards 7+8, but card 6 must remain.
This script inserts the v3-style "个人开发者要记住什么" card 6 between card 5
and card 7, by parsing each entry and re-emitting the body.
"""
from pathlib import Path

ROOT = Path(r"c:\Users\27649\Documents\myproject\Content")
V4 = ROOT / "一个人做产品" / "01_网站上线基础设施" / "06_修订与发布" / "修订稿 v4.md"

# Map: entry_num -> card 6 body (lifted from v3)
CARD6 = {
    2: """服务器要付租金、要选地域、要续费。
国内做网站，服务器在国内就要考虑备案。
后面条目会拆云服务器、虚拟主机、Serverless 怎么选。""",
    3: """备案是接入门票，不是内容审核。
`mytool.com` 想进大陆服务器，要走完这一步才合法「开门」。
DNS 怎么配、接入商怎么填，见后续条目。""",
    4: """网站不装证书，浏览器会标「不安全」。
个人项目先用云厂商免费 DV 就够。
`mytool.com` 的「锁」是基本动作，不是加分项。""",
    5: """流量上来后再上 CDN，先把源站跑稳。
`mytool.com` 装 CDN 后，DNS 解析会指向 CDN 节点，不是源 IP。
国内 CDN 也要看接入合规要求。""",
    6: """这是上线基础设施里最常错位的一条链。
顺序对、概念清，剩下是填表和等审核。
后续条目拆每一步怎么落地。""",
    7: """备案是入场券，不是审核你的代码写得好不好。
`mytool.com` 想做大陆用户，先把备案当成必须项排进时间表。""",
    8: """这是上线地图的标准路径。
`mytool.com` 这条链全跑通，才算「上线」二字。
后面条目拆每一步具体怎么做。""",
    9: """先问：是不是「只展示、不交互」？
是 → 静态站。
不是 → 后面条目会拆「轻量服务器」「Serverless」怎么选。""",
    10: """起步阶段够用，比共享主机自由，比 ECS 便宜。
`mytool.com` 跑第一版先选轻量，等量起来了再升。
后续条目会拆「云服务器 ECS 怎么选」。""",
}

LABEL = {
    2: "图 6｜个人开发者要记住什么",
    3: "图 6｜个人开发者要记住什么",
    4: "图 6｜个人开发者要记住什么",
    5: "图 6｜个人开发者要记住什么",
    6: "图 6｜个人开发者要记住什么",
    7: "图 6｜个人开发者要记住什么",
    8: "图 6｜个人开发者要记住什么",
    9: "图 6｜个人开发者要记住什么",
    10: "图 6｜个人开发者要记住什么",
}


def main():
    text = V4.read_text(encoding="utf-8")
    out = text
    for num in range(2, 11):
        nn = f"{num:02d}"
        # find card 5 ending and card 7 starting for this entry
        # use a unique marker: card 7 header line
        c7_marker = f"### 图 7｜"
        # locate this entry's block first
        m_entry = next(re.finditer for re in [__import__("re")])  # placeholder
    # simpler: regex replace per-entry by walking
    import re

    for num in range(2, 11):
        nn = f"{num:02d}"
        body = CARD6[num].strip()
        # find entry block, then within it replace "### 图 7｜" with inserted card 6 + "### 图 7｜"
        # entry starts at "## 图文 NN｜" and ends at next "## 图文" or end
        pattern = re.compile(
            rf"(## 图文 {nn}[｜\|].*?)(### 图 7[｜\|])",
            re.DOTALL,
        )
        match = pattern.search(out)
        if not match:
            print(f"skip {nn}: no match")
            continue
        prefix = match.group(1)
        c7 = match.group(2)
        insert = f"### 图 6｜个人开发者要记住什么\n\n{body}\n\n"
        out = out[: match.start()] + prefix + insert + c7 + out[match.end() :]
        print(f"inserted card 6 into entry {nn}")
    V4.write_text(out, encoding="utf-8")
    print("done")


if __name__ == "__main__":
    main()