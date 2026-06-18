# -*- coding: utf-8 -*-
import os
p = r"巴基斯坦如何把世界变成自己的资源\01_不是夹缝求生，而是管理不对称\05_审阅\内容密度审读 v3.md"
size = os.path.getsize(p)
data = open(p, "r", encoding="utf-8").read()
print(f"Bytes: {size}")
print(f"Chars: {len(data)}")
print(f"Lines: {data.count(chr(10)) + 1}")
