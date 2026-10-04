#!/usr/bin/env python3
"""Mengunduh dokumentasi kelas Godot yang benar-benar dipakai proyek.

Godot tidak tersedia di lingkungan ini, jadi pemeriksa statis memakai berkas
XML dari doc/classes di repositori Godot. Skrip ini memindai proyek, mencari
nama kelas engine yang dipakai, lalu mengunduh XML-nya (beserta seluruh kelas
induknya) lewat GitHub contents API.

Contoh:
    python3 tools/fetch_api_docs.py --dir /tmp/godot_api        --tag 4.7.2-stable
    python3 tools/fetch_api_docs.py --dir /tmp/godot_api_42     --tag 4.2-stable
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SKIP_DIRS = {"tools", "__pycache__", ".git", ".arena"}

SEED = [
    "@GlobalScope", "Object", "RefCounted", "Resource", "Node", "Node2D", "Node3D",
    "CanvasItem", "Control", "Window", "Viewport", "SceneTree", "Engine",
]

TSCN_TYPE = re.compile(r'title=|\btype="([A-Z][A-Za-z0-9_]*)"')
GD_TYPE = re.compile(
    r"(?:extends|as|is)\s+([A-Z][A-Za-z0-9_]*)|"
    r":\s*([A-Z][A-Za-z0-9_]*)"
    r"|([A-Z][A-Za-z0-9_]*)\s*\.\s*(?:new|[A-Z][A-Z0-9_]{2,})\b"
)


def project_classes() -> set[str]:
    names: set[str] = set()
    for path in ROOT.rglob("*.gd"):
        if any(part in SKIP_DIRS for part in path.relative_to(ROOT).parts):
            continue
        text = path.read_text(encoding="utf-8", errors="replace")
        for match in GD_TYPE.finditer(text):
            for group in match.groups():
                if group:
                    names.add(group)
        # tipe pada Array[T]
        for match in re.finditer(r"Array\[([A-Z][A-Za-z0-9_]*)\]", text):
            names.add(match.group(1))
    for path in ROOT.rglob("*.tscn"):
        if any(part in SKIP_DIRS for part in path.relative_to(ROOT).parts):
            continue
        text = path.read_text(encoding="utf-8", errors="replace")
        for match in re.finditer(r'type="([A-Z][A-Za-z0-9_]*)"', text):
            names.add(match.group(1))
    for path in ROOT.rglob("*.tres"):
        text = path.read_text(encoding="utf-8", errors="replace")
        for match in re.finditer(r'type="([A-Z][A-Za-z0-9_]*)"', text):
            names.add(match.group(1))
    names |= set(SEED)
    return names


def local_class_names() -> set[str]:
    names: set[str] = set()
    for path in ROOT.rglob("*.gd"):
        text = path.read_text(encoding="utf-8", errors="replace")
        for match in re.finditer(r"^class_name\s+(\w+)", text, re.M):
            names.add(match.group(1))
    return names


def fetch(class_name: str, tag: str, out_dir: Path) -> str:
    url = (
        "https://api.github.com/repos/godotengine/godot/contents/"
        f"doc/classes/{class_name}.xml?ref={tag}"
    )
    result = subprocess.run(
        ["curl", "-s", "-H", "Accept: application/vnd.github.raw", url],
        capture_output=True,
    )
    text = result.stdout.decode("utf-8", errors="replace")
    if not text.lstrip().startswith("<?xml"):
        return ""
    (out_dir / f"{class_name}.xml").write_text(text, encoding="utf-8")
    return text


def inherits_of(xml_text: str) -> str:
    match = re.search(r'<class\s+name="[^"]+"[^>]*inherits="([^"]+)"', xml_text)
    return match.group(1) if match else ""


def main() -> int:
    parser = argparse.ArgumentParser(description="Unduh doc/classes sesuai kebutuhan proyek")
    parser.add_argument("--dir", default="/tmp/godot_api")
    parser.add_argument("--tag", default="4.2-stable")
    parser.add_argument("--limit", type=int, default=400)
    args = parser.parse_args()

    out_dir = Path(args.dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    local = local_class_names()
    pending = sorted(name for name in project_classes() if name not in local)
    done: set[str] = set()
    fetched = 0
    missing: list[str] = []

    while pending and fetched < args.limit:
        name = pending.pop(0)
        if name in done:
            continue
        done.add(name)
        target = out_dir / f"{name}.xml"
        if target.exists() and target.stat().st_size > 64:
            text = target.read_text(encoding="utf-8", errors="replace")
        else:
            text = fetch(name, args.tag, out_dir)
            fetched += 1
            if not text:
                missing.append(name)
                continue
        parent = inherits_of(text)
        if parent and parent not in done and parent not in local:
            pending.append(parent)

    print(f"tag {args.tag}: {fetched} berkas diunduh, {len(missing)} gagal")
    if missing:
        print("gagal: " + ", ".join(sorted(set(missing))[:20]))
    print(f"total XML di {out_dir}: {len(list(out_dir.glob('*.xml')))}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
