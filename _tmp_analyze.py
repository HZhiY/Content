import json, sys, glob, os

for label, fpath in [
    ("04", r"C:\Users\27649\AppData\Local\Temp\p04.json"),
    ("12_v2", r"C:\Users\27649\AppData\Local\Temp\p12.json"),
]:
    if not os.path.exists(fpath):
        print(f"{label}: file not found")
        continue
    raw = open(fpath, 'rb').read()
    try:
        text = raw.decode('utf-8-sig')
    except Exception:
        try:
            text = raw.decode('utf-16-le')
        except Exception:
            text = raw.decode('utf-8', errors='replace')
    try:
        d = json.loads(text)
    except Exception as e:
        print(f"{label}: JSON error {e}")
        continue
    ps = d.get("paragraphs", [])
    overs = [p for p in ps if p["chars_no_spaces"] > 220]
    total = sum(p["chars_no_spaces"] for p in ps)
    print(f"\n=== {label} ===")
    print(f"Total: {len(ps)} paras, {total} chars, over220: {len(overs)}")
    for p in overs:
        txt = p["text"].replace("\n", " ")[:60]
        print(f"  P{p['index']:03d} {p['chars_no_spaces']:4d} | {txt}")
