#!/usr/bin/env python3
"""批量 validate + register 27 个专家"""
import os
import sys
import io
import subprocess
from pathlib import Path

# Windows GBK 编码对 emoji 不友好；强制 UTF-8
if sys.platform == "win32":
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding="utf-8", errors="replace")
    os.environ["PYTHONIOENCODING"] = "utf-8"

EXPERT_DIR = Path("C:/Users/27649/.workbuddy/plugins/marketplaces/my-experts/plugins").expanduser().resolve()
SCRIPT_DIR = Path("C:/Users/27649/AppData/Local/Programs/WorkBuddy/resources/app.asar.unpacked/resources/builtin-skills/expert-manager/scripts")
SESSION_ID = "article-pipeline-20260622"

EXPERTS = [
    "project-setup", "source-research", "evidence-ledger", "fact-check",
    "ecosystem-scan", "insight-select", "communication-criteria", "communication-analyze",
    "structure-criteria", "structure-analyze", "direction-decide",
    "style-guide", "reader-criteria", "outline-plan", "outline-review",
    "draft-write", "free-review", "reader-review", "density-edit", "editor-review",
    "release-check", "format-final-check", "draft-revise",
    "title-ecosystem", "title-write", "illustration-plan", "html-build",
]

def run(args, **kwargs):
    env = os.environ.copy()
    env["PYTHONIOENCODING"] = "utf-8"
    return subprocess.run(args, capture_output=True, text=True, env=env,
                          encoding="utf-8", errors="replace", **kwargs)

def main():
    results = {"validate_ok": [], "validate_fail": [], "register_ok": [], "register_fail": []}

    # Step 1: 批量 validate
    print("=" * 50)
    print("🔍 Step 1: 批量 validate")
    print("=" * 50)
    for i, name in enumerate(EXPERTS, 1):
        target = EXPERT_DIR / name
        result = run([sys.executable, str(SCRIPT_DIR / "validate_expert.py"), str(target)])
        # 统计 error/warn 数量
        out = result.stdout + result.stderr
        err_count = out.count("❌") + out.count("error")
        warn_count = out.count("⚠️")
        if result.returncode == 0:
            print(f"   [{i:2d}/27] ✅ {name}  (warn: {warn_count})")
            results["validate_ok"].append(name)
        else:
            print(f"   [{i:2d}/27] ❌ {name}")
            # 提取关键错误
            for line in out.split("\n"):
                if "❌" in line and "error" in line.lower():
                    print(f"         {line.strip()[:200]}")
            results["validate_fail"].append((name, out[-500:]))

    print()
    print("=" * 50)
    print("📝 Step 2: 批量 register")
    print("=" * 50)
    for i, name in enumerate(EXPERTS, 1):
        target = EXPERT_DIR / name
        result = run([sys.executable, str(SCRIPT_DIR / "register_expert.py"),
                      str(target), "--session-id", SESSION_ID])
        out = result.stdout + result.stderr
        if result.returncode == 0:
            print(f"   [{i:2d}/27] ✅ {name}")
            results["register_ok"].append(name)
        else:
            print(f"   [{i:2d}/27] ❌ {name}")
            for line in out.split("\n"):
                if "❌" in line or "Error" in line:
                    print(f"         {line.strip()[:200]}")
            results["register_fail"].append((name, out[-500:]))

    print()
    print("=" * 50)
    print(f"📊 结果汇总：")
    print(f"   validate: {len(results['validate_ok'])} 通过, {len(results['validate_fail'])} 失败")
    print(f"   register: {len(results['register_ok'])} 成功, {len(results['register_fail'])} 失败")
    if results["register_fail"]:
        print("\n失败详情：")
        for name, out in results["register_fail"][:3]:
            print(f"\n--- {name} ---")
            print(out)

if __name__ == "__main__":
    main()