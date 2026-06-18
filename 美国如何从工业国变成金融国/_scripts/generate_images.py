#!/usr/bin/env python3
"""Deprecated series-level image generation wrapper.

Use the project-level script instead:
    python scripts/generate_images_from_prompts.py path/to/08_插图/prompts.json

Configuration is loaded from the project-root .env file.
"""

from pathlib import Path
import runpy
import sys

ROOT = Path(__file__).resolve().parents[2]
SCRIPT = ROOT / "scripts" / "generate_images_from_prompts.py"

if len(sys.argv) < 2:
    print("Usage: python scripts/generate_images_from_prompts.py path/to/08_插图/prompts.json")
    raise SystemExit(2)

sys.argv = [str(SCRIPT), *sys.argv[1:]]
runpy.run_path(str(SCRIPT), run_name="__main__")
