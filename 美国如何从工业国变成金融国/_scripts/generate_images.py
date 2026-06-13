#!/usr/bin/env python3
"""
Generate images from a prompts.json file.

Usage from the series root:
    python .\_scripts\generate_images.py ".\06_为什么通用汽车用金融打败了福特\08_插图\prompts.json"

This script is intentionally simple for testing:
- Fill API_URL and API_TOKEN manually below.
- It reads prompts.json.
- It saves images into an images/ folder next to prompts.json.
- It supports API responses containing either b64_json or url.
"""

from __future__ import annotations

import argparse
import base64
import json
import mimetypes
import sys
import time
import urllib.request
from datetime import datetime
from pathlib import Path
from typing import Any

# Fill these manually for testing.
API_URL = "https://tokenking.cc.cd/v1/images/generations"
API_TOKEN = "sk-WC1pfxuXLpn30s8OG8zQKmkm0HfTILGMYVrpMCtr7Hb0Z2eW"

DEFAULT_MODEL = "gpt-image-2"
DEFAULT_SIZE = "1024x1024"


def load_prompts(path: Path) -> list[dict[str, Any]]:
    with path.open("r", encoding="utf-8") as f:
        data = json.load(f)
    if not isinstance(data, list):
        raise ValueError("prompts.json must be a JSON array")
    return data


def request_image(item: dict[str, Any]) -> dict[str, Any]:
    if not API_TOKEN:
        raise RuntimeError("API_TOKEN is empty. Please fill API_TOKEN at the top of the script.")

    payload = {
        "model": item.get("model") or DEFAULT_MODEL,
        "prompt": item["prompt"],
        "size": item.get("size") or DEFAULT_SIZE,
    }

    # Pass through optional common image parameters if present.
    for key in ("quality", "background", "output_format", "n"):
        if key in item and item[key] is not None:
            payload[key] = item[key]

    body = json.dumps(payload, ensure_ascii=False).encode("utf-8")
    req = urllib.request.Request(
        API_URL,
        data=body,
        method="POST",
        headers={
            "Authorization": f"Bearer {API_TOKEN}",
            "Content-Type": "application/json",
        },
    )

    with urllib.request.urlopen(req, timeout=180) as resp:
        raw = resp.read().decode("utf-8")
    return json.loads(raw)


def first_image_payload(response: dict[str, Any]) -> dict[str, Any]:
    data = response.get("data")
    if not isinstance(data, list) or not data:
        raise ValueError(f"Unexpected response: {response}")
    first = data[0]
    if not isinstance(first, dict):
        raise ValueError(f"Unexpected image payload: {first}")
    return first


def save_from_b64(b64_value: str, output_path: Path) -> None:
    output_path.write_bytes(base64.b64decode(b64_value))


def save_from_url(url: str, output_path: Path) -> None:
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(req, timeout=180) as resp:
        content = resp.read()
        content_type = resp.headers.get("Content-Type")

    if output_path.suffix.lower() not in {".png", ".jpg", ".jpeg", ".webp"}:
        ext = mimetypes.guess_extension(content_type or "") or ".png"
        output_path = output_path.with_suffix(ext)

    output_path.write_bytes(content)


def append_log(log_path: Path, item: dict[str, Any], filename: str, status: str, message: str = "") -> None:
    now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    with log_path.open("a", encoding="utf-8") as f:
        f.write(f"## {now}｜{item.get('id', filename)}｜{status}\n\n")
        f.write(f"- file: `{filename}`\n")
        f.write(f"- model: `{item.get('model') or DEFAULT_MODEL}`\n")
        f.write(f"- size: `{item.get('size') or DEFAULT_SIZE}`\n")
        if item.get("placement"):
            f.write(f"- placement: {item['placement']}\n")
        if item.get("reading_role"):
            f.write(f"- reading_role: {item['reading_role']}\n")
        if message:
            f.write(f"- message: {message}\n")
        f.write("\n### prompt\n\n")
        f.write(item.get("prompt", ""))
        f.write("\n\n---\n\n")


def generate_all(prompts_path: Path, dry_run: bool = False) -> None:
    prompts_path = prompts_path.resolve()
    base_dir = prompts_path.parent
    images_dir = base_dir / "images"
    images_dir.mkdir(exist_ok=True)
    log_path = base_dir / "生成记录.md"

    items = load_prompts(prompts_path)

    for idx, item in enumerate(items, start=1):
        filename = item.get("filename") or f"image_{idx:02d}.png"
        output_path = images_dir / filename
        print(f"[{idx}/{len(items)}] {item.get('id', filename)} -> {output_path}")

        if dry_run:
            append_log(log_path, item, filename, "dry-run", "No API call made.")
            continue

        try:
            response = request_image(item)
            payload = first_image_payload(response)
            if payload.get("b64_json"):
                save_from_b64(payload["b64_json"], output_path)
            elif payload.get("url"):
                save_from_url(payload["url"], output_path)
            else:
                raise ValueError(f"No b64_json or url in response payload: {payload}")
            append_log(log_path, item, filename, "success")
            print(f"Saved: {output_path}")
        except Exception as exc:
            append_log(log_path, item, filename, "failed", str(exc))
            print(f"Failed: {exc}", file=sys.stderr)
            raise

        # Small delay to avoid sending requests too aggressively.
        time.sleep(1)


def main() -> None:
    parser = argparse.ArgumentParser(description="Generate images from prompts.json")
    parser.add_argument("prompts", help="Path to prompts.json")
    parser.add_argument("--dry-run", action="store_true", help="Validate config and write log without API calls")
    args = parser.parse_args()

    generate_all(Path(args.prompts), dry_run=args.dry_run)


if __name__ == "__main__":
    main()
