#!/usr/bin/env python3
"""Generate article images from an illustration prompts.json file.

Configuration is read from the project-root .env file by default.

Usage:
    python scripts/generate_images_from_prompts.py "美国如何从工业国变成金融国/10_xxx/08_插图/prompts.json"
    python scripts/generate_images_from_prompts.py ".../prompts.json" --dry-run

Supported providers:
    - openai-compatible: expects /v1/images/generations style responses with data[].b64_json or data[].url
    - minimax: expects data.image_base64 from MiniMax image_generation API
"""

from __future__ import annotations

import argparse
import base64
import json
import mimetypes
import os
import sys
import time
import urllib.error
import urllib.request
from datetime import datetime
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_ENV_PATH = ROOT / ".env"


def load_env(path: Path) -> dict[str, str]:
    values: dict[str, str] = {}
    if not path.exists():
        return values
    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        key = key.strip()
        value = value.strip().strip('"').strip("'")
        values[key] = value
    return values


def config_value(env: dict[str, str], key: str, default: str = "") -> str:
    return os.environ.get(key) or env.get(key) or default


def load_prompt_items(path: Path) -> tuple[dict[str, Any], list[dict[str, Any]]]:
    with path.open("r", encoding="utf-8") as f:
        data = json.load(f)

    if isinstance(data, list):
        return {}, data

    if isinstance(data, dict):
        images = data.get("images")
        if not isinstance(images, list):
            raise ValueError("prompts.json object must contain an images array")
        return data, images

    raise ValueError("prompts.json must be either a JSON array or an object with images[]")


def normalize_size(item: dict[str, Any], default_size: str) -> str:
    if item.get("size"):
        return str(item["size"])

    ratio = str(item.get("aspect_ratio") or "").strip()
    ratio_to_size = {
        "1:1": "1024x1024",
        "3:2": "1536x1024",
        "2:3": "1024x1536",
        "16:9": "1536x864",
        "9:16": "864x1536",
        "8:5": "1536x960",
        "5:6": "1024x1229",
        "6:5": "1229x1024",
    }
    return ratio_to_size.get(ratio, default_size)


def request_openai_compatible(item: dict[str, Any], config: dict[str, str]) -> dict[str, Any]:
    api_url = config["api_url"]
    api_key = config["api_key"]
    model = item.get("model") or config["model"]
    size = normalize_size(item, config["default_size"])

    payload: dict[str, Any] = {
        "model": model,
        "prompt": item["prompt"],
        "n": int(item.get("n") or 1),
        "size": size,
        "response_format": item.get("response_format") or "b64_json",
    }

    for key in ("quality", "background", "output_format", "style"):
        if key in item and item[key] is not None:
            payload[key] = item[key]

    return post_json(api_url, api_key, payload, int(config["timeout"]))


def request_minimax(item: dict[str, Any], config: dict[str, str]) -> dict[str, Any]:
    api_url = config["api_url"]
    api_key = config["api_key"]
    model = item.get("model") or config["model"] or "image-01"

    payload: dict[str, Any] = {
        "model": model,
        "prompt": item["prompt"],
        "aspect_ratio": item.get("aspect_ratio") or "1:1",
        "response_format": item.get("response_format") or "base64",
    }

    for key in ("n", "prompt_optimizer"):
        if key in item and item[key] is not None:
            payload[key] = item[key]

    return post_json(api_url, api_key, payload, int(config["timeout"]))


def post_json(api_url: str, api_key: str, payload: dict[str, Any], timeout: int) -> dict[str, Any]:
    body = json.dumps(payload, ensure_ascii=False).encode("utf-8")
    req = urllib.request.Request(
        api_url,
        data=body,
        method="POST",
        headers={
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json",
        },
    )
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            raw = resp.read().decode("utf-8")
    except urllib.error.HTTPError as exc:
        error_body = exc.read().decode("utf-8", errors="replace")
        raise RuntimeError(f"HTTP {exc.code}: {error_body[:800]}") from exc
    return json.loads(raw)


def extract_image_payloads(response: dict[str, Any], provider: str) -> list[dict[str, str]]:
    if provider == "minimax":
        images_b64 = response.get("data", {}).get("image_base64", [])
        if isinstance(images_b64, str):
            images_b64 = [images_b64]
        return [{"b64_json": value} for value in images_b64 if value]

    data = response.get("data")
    if not isinstance(data, list):
        raise ValueError(f"Unexpected response shape: {response}")
    payloads: list[dict[str, str]] = []
    for item in data:
        if not isinstance(item, dict):
            continue
        if item.get("b64_json"):
            payloads.append({"b64_json": item["b64_json"]})
        elif item.get("url"):
            payloads.append({"url": item["url"]})
    return payloads


def save_payload(payload: dict[str, str], output_path: Path, timeout: int) -> Path:
    if payload.get("b64_json"):
        output_path.write_bytes(base64.b64decode(payload["b64_json"]))
        return output_path

    if payload.get("url"):
        req = urllib.request.Request(payload["url"], headers={"User-Agent": "Mozilla/5.0"})
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            content = resp.read()
            content_type = resp.headers.get("Content-Type")
        if output_path.suffix.lower() not in {".png", ".jpg", ".jpeg", ".webp"}:
            ext = mimetypes.guess_extension(content_type or "") or ".png"
            output_path = output_path.with_suffix(ext)
        output_path.write_bytes(content)
        return output_path

    raise ValueError(f"No image payload found: {payload}")


def append_log(log_path: Path, item: dict[str, Any], filename: str, status: str, message: str = "") -> None:
    now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    with log_path.open("a", encoding="utf-8") as f:
        f.write(f"## {now}｜{item.get('id', filename)}｜{status}\n\n")
        f.write(f"- file: `{filename}`\n")
        if item.get("position"):
            f.write(f"- position: {item['position']}\n")
        if item.get("function"):
            f.write(f"- function: {item['function']}\n")
        if item.get("size"):
            f.write(f"- size: `{item['size']}`\n")
        if item.get("aspect_ratio"):
            f.write(f"- aspect_ratio: `{item['aspect_ratio']}`\n")
        if message:
            f.write(f"- message: {message}\n")
        f.write("\n### prompt\n\n")
        f.write(str(item.get("prompt", "")))
        f.write("\n\n---\n\n")


def generate(prompts_path: Path, env_path: Path, dry_run: bool = False, limit: int | None = None) -> None:
    env = load_env(env_path)
    provider = config_value(env, "IMAGE_API_PROVIDER", "openai-compatible").strip().lower()
    config = {
        "api_url": config_value(env, "IMAGE_API_URL"),
        "api_key": config_value(env, "IMAGE_API_KEY"),
        "model": config_value(env, "IMAGE_API_MODEL", "gpt-image-2"),
        "default_size": config_value(env, "IMAGE_DEFAULT_SIZE", "1024x1024"),
        "timeout": config_value(env, "IMAGE_REQUEST_TIMEOUT", "180"),
    }

    if provider not in {"openai-compatible", "minimax"}:
        raise ValueError("IMAGE_API_PROVIDER must be openai-compatible or minimax")
    if not config["api_url"]:
        raise RuntimeError("IMAGE_API_URL is missing. Set it in .env.")
    if not config["api_key"] and not dry_run:
        raise RuntimeError("IMAGE_API_KEY is missing. Set it in .env.")

    prompts_path = prompts_path.resolve()
    meta, items = load_prompt_items(prompts_path)
    if limit is not None:
        items = items[:limit]

    base_dir = prompts_path.parent
    images_dir = base_dir / "images"
    images_dir.mkdir(exist_ok=True)
    log_path = base_dir / "生成记录.md"

    print(f"prompts: {prompts_path}")
    print(f"provider: {provider}")
    print(f"model: {config['model']}")
    print(f"images: {len(items)}")
    if meta.get("article_id"):
        print(f"article_id: {meta['article_id']}")

    for idx, item in enumerate(items, start=1):
        filename = item.get("filename") or f"image_{idx:02d}.png"
        output_path = images_dir / filename
        print(f"[{idx}/{len(items)}] {item.get('id', filename)} -> {output_path}")

        if dry_run:
            append_log(log_path, item, filename, "dry-run", "No API call made.")
            continue

        if provider == "minimax":
            response = request_minimax(item, config)
        else:
            response = request_openai_compatible(item, config)

        payloads = extract_image_payloads(response, provider)
        if not payloads:
            raise ValueError(f"No generated image found in response: {response}")

        saved_path = save_payload(payloads[0], output_path, int(config["timeout"]))
        append_log(log_path, item, saved_path.name, "success")
        print(f"Saved: {saved_path}")
        time.sleep(1)


def main() -> None:
    parser = argparse.ArgumentParser(description="Generate article images from prompts.json")
    parser.add_argument("prompts", help="Path to prompts.json")
    parser.add_argument("--env", default=str(DEFAULT_ENV_PATH), help="Path to .env file")
    parser.add_argument("--dry-run", action="store_true", help="Validate inputs and write log without API calls")
    parser.add_argument("--limit", type=int, help="Generate only the first N images")
    args = parser.parse_args()

    generate(Path(args.prompts), Path(args.env), dry_run=args.dry_run, limit=args.limit)


if __name__ == "__main__":
    main()
