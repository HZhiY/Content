#!/usr/bin/env python3
"""Deprecated local wrapper for GPT-image-2 generation.

Use the project-level script instead. Configuration is loaded from .env:
    python scripts/generate_images_from_prompts.py "美国如何从工业国变成金融国/10_为什么美联储像是从摩根图书馆里长出来的/08_插图/prompts.json"
"""

from pathlib import Path
import runpy
import sys

ROOT = Path(__file__).resolve().parents[3]
PROMPTS = Path(__file__).resolve().parent / "prompts.json"
SCRIPT = ROOT / "scripts" / "generate_images_from_prompts.py"

sys.argv = [str(SCRIPT), str(PROMPTS), *sys.argv[1:]]
runpy.run_path(str(SCRIPT), run_name="__main__")
