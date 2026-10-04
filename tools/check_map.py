#!/usr/bin/env python3
"""Periksa peta Desa Arunika tanpa menjalankan Godot.

Membaca scenes/world/Village.tscn (dan scene-scene yang di-instance di
dalamnya), menyusun bidang rintangan, lalu menelusuri peta dari titik spawn
untuk memastikan:

  * pemain tidak bisa keluar dari peta,
  * titik spawn tidak tertimbun benda padat,
  * semua yang dibutuhkan cerita (barang, NPC, papan, stasiun) bisa dijangkau.

Pemakaian:
    python3 tools/check_map.py

Bidang rintangan disusun dari data yang sama seperti game: ukuran prop dari
Prop.DEFAULT_SIZES, profil tabrakan dari Prop.COLLISION, ukuran badan NPC dari
Npc.tscn, dan ukuran badan pemain dari Player.tscn.
"""

from __future__ import annotations

import re
import sys
from collections import deque
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
VILLAGE = ROOT / "scenes" / "world" / "Village.tscn"
PROP_SCRIPT = ROOT / "scripts" / "world" / "Prop.gd"
NPC_SCENE = ROOT / "scenes" / "npc" / "Npc.tscn"
PLAYER_SCENE = ROOT / "scenes" / "player" / "Player.tscn"

CELL = 8.0  # ukuran sel grid dalam piksel

Rect = tuple[float, float, float, float]  # x, y, w, h


# ---------------------------------------------------------------------------
# Pembacaan data dari skrip Godot
# ---------------------------------------------------------------------------


def numbers_in(text: str) -> list[float]:
    """Angka di dalam tanda kurung (mengabaikan angka pada nama tipe)."""
    match = re.search(r"\(([^)]*)\)", text)
    body = match.group(1) if match else text
    return [float(value) for value in re.findall(r"-?\d+(?:\.\d+)?", body)]


def parse_vector(text: str) -> tuple[float, float]:
    values = numbers_in(text)
    return (values[0], values[1]) if len(values) >= 2 else (0.0, 0.0)


def parse_dict(source: str, name: str) -> dict[str, tuple[float, float]]:
    start = source.index("const " + name)
    end = source.index("\n}", start)
    body = source[start:end]
    out: dict[str, tuple[float, float]] = {}
    for match in re.finditer(r'"([a-z_]+)":\s*Vector2\(([^)]*)\)', body):
        out[match.group(1)] = parse_vector(match.group(2))
    return out


def parse_list(source: str, name: str) -> list[str]:
    start = source.index("const " + name)
    end = source.index("]", start)
    return re.findall(r'"([a-z_]+)"', source[start:end])


def sub_resources(text: str) -> dict[str, tuple[str, Rect]]:
    """id -> (tipe, (x, y, w, h)) untuk RectangleShape2D/CircleShape2D."""
    out: dict[str, tuple[str, Rect]] = {}
    for match in re.finditer(r'\[sub_resource type="(\w+)" id="([^"]+)"\]\n((?:(?!\n\[).)*)', text, re.S):
        kind, rid, body = match.group(1), match.group(2), match.group(3)
        if kind == "RectangleShape2D":
            size = parse_vector(re.search(r"size = Vector2\(([^)]*)\)", body).group(1))
            out[rid] = (kind, (-size[0] / 2, -size[1] / 2, size[0], size[1]))
        elif kind == "CircleShape2D":
            radius = float(re.search(r"radius = ([\d.]+)", body).group(1))
            out[rid] = (kind, (-radius, -radius, radius * 2, radius * 2))
    return out


def node_blocks(text: str) -> list[dict]:
    out = []
    for block in re.split(r"\n(?=\[)", text):
        header = re.match(
            r'\[node name="([^"]+)"(?: type="([^"]+)")?(?: parent="([^"]+)")?(?: instance=ExtResource\("([^"]+)"\))?\]',
            block,
        )
        if not header:
            continue
        name, kind, parent, instance = header.groups()
        props: dict[str, str] = {}
        for line in block.split("\n")[1:]:
            if " = " in line and not line.startswith("["):
                key, value = line.split(" = ", 1)
                props.setdefault(key.strip(), value.strip())
        out.append({"name": name, "type": kind or "", "parent": parent or "", "instance": instance or "", "props": props})
    return out


# ---------------------------------------------------------------------------
# Susun rintangan
# ---------------------------------------------------------------------------


def main() -> int:
    village = VILLAGE.read_text()
    prop_source = PROP_SCRIPT.read_text()
    defaults = parse_dict(prop_source, "DEFAULT_SIZES")
    profiles = parse_dict(prop_source, "COLLISION")
    soft_kinds = parse_list(prop_source, "SOFT_KINDS")

    subs = sub_resources(village)
    nodes = node_blocks(village)
    ext = {m.group(1): m.group(2) for m in re.finditer(r'\[ext_resource type="\w+" path="([^"]+)" id="([^"]+)"\]', village)}
    npc_id = next((rid for path, rid in ext.items() if path.endswith("Npc.tscn")), "")

    bounds = (0.0, 0.0, 3200.0, 2000.0)
    for node in nodes:
        if node["name"] == "Village" and "map_bounds" in node["props"]:
            values = numbers_in(node["props"]["map_bounds"])
            if len(values) >= 4:
                bounds = (values[0], values[1], values[2], values[3])
    spawn = (220.0, 1020.0)
    for node in nodes:
        if node["name"] == "Village" and "spawn_point" in node["props"]:
            spawn = parse_vector(node["props"]["spawn_point"])

    obstacles: list[tuple[str, Rect]] = []

    def add(label: str, x: float, y: float, w: float, h: float) -> None:
        if w <= 0 or h <= 0:
            return
        obstacles.append((label, (x - w / 2, y - h / 2, w, h)))

    # NPC: badan statis dari Npc.tscn
    npc_body: Rect | None = None
    npc_text = NPC_SCENE.read_text()
    npc_subs = sub_resources(npc_text)
    for node in node_blocks(npc_text):
        if node["name"] == "Shape" and node["parent"] == "Body":
            rid = node["props"].get("shape", "").split('"')[1] if "shape" in node["props"] else ""
            shape = npc_subs.get(rid)
            pos = parse_vector(node["props"].get("position", "Vector2(0, 0)"))
            if shape:
                npc_body = (shape[1][0] + pos[0], shape[1][1] + pos[1], shape[1][2], shape[1][3])

    for node in nodes:
        props = node["props"]
        position = parse_vector(props.get("position", "Vector2(0, 0)"))
        if node["instance"] and npc_id and node["instance"] == npc_id and npc_body:
            label = f"npc:{props.get('npc_id', node['name']).strip(chr(34))}"
            add(label, position[0] + npc_body[0] + npc_body[2] / 2, position[1] + npc_body[1] + npc_body[3] / 2, npc_body[2], npc_body[3])
            continue
        if node["name"] == "Walls" or node["parent"] == "Walls":
            if "shape" in props:
                rid = props["shape"].split('"')[1]
                shape = subs.get(rid)
                if shape:
                    add("dinding", position[0] + shape[1][0] + shape[1][2] / 2, position[1] + shape[1][1] + shape[1][3] / 2, shape[1][2], shape[1][3])
            continue
        if node["instance"] and props.get("kind"):
            kind = props["kind"].strip('"')
            solid = props.get("solid", "true") != "false" and kind not in soft_kinds
            if not solid:
                continue
            size = parse_vector(props["size"]) if "size" in props else defaults.get(kind, (64.0, 64.0))
            profile = profiles.get(kind, (0.86, 0.26))
            width = max(size[0] * profile[0], 8.0)
            height = max(size[1] * profile[1], 8.0)
            add(f"prop:{kind}", position[0], position[1] - height / 2, width, height)

    # -----------------------------------------------------------------------
    # Telusuri peta
    # -----------------------------------------------------------------------
    player_half = Vector2 = (10.0, 8.0)  # pemain 20x14, origin di kaki
    inflate_x, inflate_y = player_half

    width = int(bounds[2] / CELL)
    height = int(bounds[3] / CELL)
    blocked = bytearray(width * height)
    for _, rect in obstacles:
        x0 = rect[0] - inflate_x
        y0 = rect[1] - inflate_y
        x1 = rect[0] + rect[2] + inflate_x
        y1 = rect[1] + rect[3] + inflate_y
        cx0 = max(0, int((x0 - bounds[0]) / CELL))
        cx1 = min(width - 1, int((x1 - bounds[0]) / CELL))
        cy0 = max(0, int((y0 - bounds[1]) / CELL))
        cy1 = min(height - 1, int((y1 - bounds[1]) / CELL))
        for cy in range(cy0, cy1 + 1):
            row = cy * width
            for cx in range(cx0, cx1 + 1):
                blocked[row + cx] = 1

    def cell_of(point: tuple[float, float]) -> tuple[int, int]:
        return (int((point[0] - bounds[0]) / CELL), int((point[1] - bounds[1]) / CELL))

    start = cell_of(spawn)
    if blocked[start[1] * width + start[0]]:
        print(f"  ! TITIK SPAWN {spawn} tertimbun benda padat — pemain bisa tersangkut")
    reachable = bytearray(width * height)
    queue = deque([start])
    reachable[start[1] * width + start[0]] = 1
    while queue:
        cx, cy = queue.popleft()
        for nx, ny in ((cx + 1, cy), (cx - 1, cy), (cx, cy + 1), (cx, cy - 1)):
            if 0 <= nx < width and 0 <= ny < height:
                index = ny * width + nx
                if not reachable[index] and not blocked[index]:
                    reachable[index] = 1
                    queue.append((nx, ny))

    reached = sum(reachable)
    print(f"  peta {int(bounds[2])}x{int(bounds[3])} px, sel {CELL:.0f} px, area terjangkau {reached * CELL * CELL / 1e6:.2f} juta px²")

    # keluar peta?
    edge_hit = []
    for cx in range(width):
        if reachable[cx]:
            edge_hit.append("atas")
            break
        if reachable[(height - 1) * width + cx]:
            edge_hit.append("bawah")
            break
    for cy in range(height):
        if reachable[cy * width]:
            edge_hit.append("kiri")
            break
        if reachable[cy * width + (width - 1)]:
            edge_hit.append("kanan")
            break
    if edge_hit:
        print(f"  ! PERINGATAN: area terjangkau menyentuh tepi peta ({', '.join(sorted(set(edge_hit)))})")

    def reachable_near(point: tuple[float, float], radius: float) -> bool:
        cx0, cy0 = cell_of((point[0] - radius, point[1] - radius))
        cx1, cy1 = cell_of((point[0] + radius, point[1] + radius))
        for cy in range(max(0, cy0), min(height - 1, cy1) + 1):
            for cx in range(max(0, cx0), min(width - 1, cx1) + 1):
                if reachable[cy * width + cx]:
                    return True
        return False

    targets: list[tuple[str, tuple[float, float], float]] = []
    radii = {"ItemPickup": 34.0, "InfoBoard": 40.0, "SupplyStation": 40.0}
    pickup_id = next((rid for path, rid in ext.items() if path.endswith("ItemPickup.tscn")), "")
    board_id = next((rid for path, rid in ext.items() if path.endswith("InfoBoard.tscn")), "")
    station_id = next((rid for path, rid in ext.items() if path.endswith("SupplyStation.tscn")), "")
    for node in nodes:
        props = node["props"]
        position = parse_vector(props.get("position", "Vector2(0, 0)"))
        if node["instance"] == pickup_id:
            targets.append((f"barang:{props.get('item_id', '?').strip(chr(34))}", position, radii["ItemPickup"]))
        elif node["instance"] == board_id:
            targets.append((f"papan:{props.get('dialogue_id', '?').strip(chr(34))}", position, radii["InfoBoard"]))
        elif node["instance"] == station_id:
            targets.append(("stasiun persiapan", position, radii["SupplyStation"]))
        elif node["instance"] and npc_id and node["instance"] == npc_id:
            label = props.get("npc_id", "?").strip(chr(34))
            targets.append((f"npc:{label}", position, 36.0))
            for key, extra in (("gather_position", "titik kumpul"), ("alt_position", "posisi cadangan")):
                if key in props and props[key] != "Vector2(0, 0)":
                    targets.append((f"{extra}:{label}", parse_vector(props[key]), 36.0))

    unreachable = []
    for label, position, radius in targets:
        # pemain bisa berdiri sampai radius area + radius badan pemain
        if not reachable_near(position, radius + 10.0):
            unreachable.append(label)
    if unreachable:
        for label in unreachable:
            print(f"  ! TIDAK TERJANGKAU: {label}")
    else:
        print(f"  semua {len(targets)} titik penting terjangkau")

    if not reachable_near(spawn, 4.0):
        print("  ! spawn tidak berada di area terjangkau")

    return 1 if (unreachable or edge_hit) else 0


if __name__ == "__main__":
    sys.exit(main())
