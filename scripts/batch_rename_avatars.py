#!/usr/bin/env python3
"""把每个专家 avatars/ 目录下 hash 命名的 png 重命名为 expert.png"""
import os
import sys
import io
from pathlib import Path

if sys.platform == "win32":
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
    os.environ["PYTHONIOENCODING"] = "utf-8"

EXPERT_DIR = Path("C:/Users/27649/.workbuddy/plugins/marketplaces/my-experts/plugins").expanduser().resolve()

EXPERTS = sorted([p.name for p in EXPERT_DIR.iterdir() if p.is_dir()])
print(f"📦 处理 {len(EXPERTS)} 个专家目录\n")

ok = 0
for name in EXPERTS:
    avatar_dir = EXPERT_DIR / name / "avatars"
    if not avatar_dir.exists():
        print(f"   ❌ {name}: avatars/ 不存在")
        continue
    # 找 hash 命名的 png
    candidates = sorted([p for p in avatar_dir.iterdir() if p.suffix.lower() == ".png" and p.name != "expert.png"])
    if not candidates:
        # 已经有 expert.png
        expert = avatar_dir / "expert.png"
        if expert.exists():
            print(f"   ✅ {name}: expert.png 已就绪")
            ok += 1
        else:
            print(f"   ⚠️  {name}: 没有 png")
        continue
    # 只保留第一个，重命名
    src = candidates[0]
    dest = avatar_dir / "expert.png"
    if dest.exists():
        dest.unlink()
    src.rename(dest)
    # 删除其他 png
    for p in candidates[1:]:
        p.unlink()
    print(f"   ✅ {name}: {src.name[:40]}... → expert.png")
    ok += 1

print(f"\n📊 重命名完成: {ok}/{len(EXPERTS)}")

# 列出文件大小统计
print("\n头像文件信息：")
for name in EXPERTS:
    expert = EXPERT_DIR / name / "avatars" / "expert.png"
    if expert.exists():
        size_kb = expert.stat().st_size // 1024
        print(f"   {name:30s} {size_kb:6d} KB")