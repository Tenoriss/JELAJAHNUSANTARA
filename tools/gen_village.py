#!/usr/bin/env python3
"""Generate scenes/world/Village.tscn (Desa Arunika) from a compact layout spec.

The village layout is described here in one place so it can be re-generated or
tweaked quickly. Run:

    python3 tools/gen_village.py

The output is a normal Godot scene: everything stays editable in the editor
afterwards (this script is only a convenience for regenerating the base map).
"""
from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "scenes" / "world" / "Village.tscn"

MAP = (0, 0, 3200, 2000)
SPAWN = (185, 1040)  # sejajar dengan scene: di jalur masuk, bebas dari tiang papan

# --- Area data: (x, y, w, h) ---------------------------------------------

PATHS = [
    (40, 985, 800, 74),  # jalan masuk dari barat
    (700, 800, 86, 240),  # menuju rumah Raka
    (1740, 830, 240, 74),  # alun-alun -> balai desa
    (760, 1050, 86, 350),  # alun-alun -> simpang kebun
    (420, 1330, 440, 74),  # jalan kebun
    (560, 1150, 86, 220),  # simpang -> kebun
    (1120, 1060, 86, 340),  # alun-alun -> sawah
    (1120, 1326, 940, 74),  # pematang utama sawah
    (1650, 1330, 80, 240),  # masuk ke sawah / saung
    (2160, 880, 330, 74),  # balai -> bengkel
    (2330, 700, 86, 260),  # naik ke bengkel
    (2300, 940, 86, 330),  # balai -> lapangan guyub
    (2300, 1180, 700, 74),  # jalan lapangan guyub
]

PLAZAS = [
    (1180, 780, 620, 460),  # alun-alun desa
    (2150, 1180, 800, 560),  # lapangan guyub
]

PADDIES = [
    (1200, 1420, 260, 200),
    (1490, 1420, 130, 200),
    (1760, 1420, 280, 200),
    (1200, 1650, 260, 200),
    (1490, 1650, 130, 200),
    (1760, 1650, 280, 200),
]

PONDS = [(880, 1250, 190, 120)]

GARDENS = [
    (470, 1400, 160, 110),
    (660, 1400, 160, 110),
    (470, 1560, 160, 110),
    (660, 1560, 160, 110),
]

OPEN_SOIL = [
    (800, 700, 240, 170),  # halaman rumah Raka
    (2280, 940, 320, 190),  # halaman bengkel
    (450, 1000, 210, 120),  # tanah di dekat gapura
]

FLOWERS = [
    (300, 1100, 320, 210),
    (890, 880, 220, 150),
    (1880, 1250, 220, 160),
    (2560, 1740, 320, 150),
    (1480, 1240, 320, 90),
    (2900, 980, 240, 220),
    (330, 1440, 300, 200),
]

# --- Props: (kind, x, y, size, kwargs) ------------------------------------
# size None -> pakai ukuran default jenis prop.

PROPS = [
    # Gerbang & jalan masuk
    ("gapura", 330, 1055, None, {"solid": False}),
    # papan sambutan digeser sedikit ke belakang supaya jalur masuk tidak terhalang
    ("sign_post", 225, 1000, None, {}),
    ("tree", 150, 890, (150, 175), {"sway": True}),
    ("tree", 190, 1260, (130, 150), {"sway": True}),
    ("bamboo_clump", 120, 1160, None, {"sway": True}),
    ("grass_tuft", 460, 940, None, {}),
    ("grass_tuft", 560, 1120, None, {}),
    ("flower_bush", 430, 950, None, {}),
    ("flower_bush", 250, 1180, None, {}),
    ("rock", 520, 1240, None, {}),
    ("banner", 640, 990, None, {"variant": 0}),
    ("basket", 450, 1020, None, {}),
    # Rumah Raka
    ("house", 760, 810, (170, 145), {"variant": 0}),
    ("bench", 870, 870, None, {}),
    ("flower_bush", 700, 880, None, {}),
    ("flower_bush", 830, 890, None, {}),
    ("table", 690, 840, None, {}),
    ("tree", 990, 790, (140, 165), {"sway": True}),
    ("fence", 640, 700, (160, 40), {}),
    ("crate", 640, 830, None, {}),
    ("lamp", 930, 910, None, {"glow": 0.0}),
    # Alun-alun desa
    ("tree", 1400, 930, (250, 270), {"sway": True}),
    ("bench", 1300, 1150, None, {}),
    ("bench", 1600, 1150, None, {}),
    ("bench", 1490, 830, None, {}),
    ("lamp", 1230, 850, None, {"glow": 0.0}),
    ("lamp", 1740, 850, None, {"glow": 0.0}),
    ("lamp", 1230, 1240, None, {"glow": 0.0}),
    ("lamp", 1740, 1240, None, {"glow": 0.0}),
    ("sign_post", 1560, 900, None, {}),
    ("banner", 1350, 800, None, {"variant": 1}),
    ("banner", 1700, 1220, None, {"variant": 0}),
    ("table", 1640, 1090, None, {}),
    ("basket", 1690, 1110, None, {}),
    ("well", 1690, 1170, None, {}),
    ("crate", 1250, 960, None, {}),
    ("flower_bush", 1200, 800, None, {}),
    ("flower_bush", 1780, 1190, None, {}),
    ("cart", 1500, 1210, None, {}),
    ("grass_tuft", 1180, 1100, None, {}),
    ("grass_tuft", 1800, 950, None, {}),
    # Balai desa
    ("balai", 1950, 700, (330, 215), {}),
    ("banner", 1800, 730, None, {"variant": 1}),
    ("banner", 2130, 730, None, {"variant": 0}),
    ("lamp", 1830, 790, None, {"glow": 0.0}),
    ("lamp", 2170, 790, None, {"glow": 0.0}),
    ("table", 2050, 910, None, {}),
    ("crate", 2110, 940, None, {}),
    ("crate", 2160, 910, None, {}),
    ("sign_post", 1900, 900, None, {}),
    ("bench", 1880, 960, None, {}),
    ("flower_bush", 1790, 910, None, {}),
    # Lapangan Guyub (acara akhir)
    ("gapura", 2500, 1265, None, {"solid": False, "variant": 1}),
    ("stage", 2500, 1430, (340, 150), {}),
    ("lamp", 2230, 1270, None, {"glow": 0.0}),
    ("lamp", 2820, 1270, None, {"glow": 0.0}),
    ("lamp", 2230, 1570, None, {"glow": 0.0}),
    ("lamp", 2820, 1570, None, {"glow": 0.0}),
    ("banner", 2340, 1310, None, {"variant": 0}),
    ("banner", 2680, 1310, None, {"variant": 1}),
    ("bench", 2320, 1690, None, {}),
    ("bench", 2700, 1690, None, {}),
    ("fence", 2260, 1745, (160, 40), {}),
    ("fence", 2900, 1745, (160, 40), {}),
    ("fire_pit", 2500, 1670, None, {"glow": 0.0}),
    ("table", 2350, 1610, None, {}),
    ("basket", 2400, 1630, None, {}),
    ("tree", 2180, 1810, (150, 165), {"sway": True}),
    ("tree", 2920, 1320, (140, 155), {"sway": True}),
    ("grass_tuft", 2600, 1780, None, {}),
    ("flower_bush", 2760, 1600, None, {}),
    # Kebun Bu Rini
    ("bamboo_clump", 400, 1420, None, {"sway": True}),
    ("scarecrow", 840, 1530, None, {"sway": True}),
    ("barrel", 770, 1430, None, {}),
    ("cart", 870, 1630, None, {}),
    ("sign_post", 430, 1630, None, {}),
    ("flower_bush", 350, 1470, None, {}),
    ("flower_bush", 910, 1490, None, {}),
    ("crate", 350, 1620, None, {}),
    ("basket", 610, 1660, None, {}),
    ("fence", 620, 1730, (200, 40), {}),
    ("tree", 300, 1710, (140, 155), {"sway": True}),
    ("rice_sheaf", 910, 1410, None, {}),
    ("rice_sheaf", 330, 1530, None, {}),
    # Sawah & saung
    ("saung", 1700, 1630, (135, 135), {}),
    ("scarecrow", 1260, 1460, None, {"sway": True}),
    ("scarecrow", 1960, 1610, None, {"sway": True}),
    ("rice_sheaf", 1500, 1400, None, {}),
    ("rice_sheaf", 1860, 1400, None, {}),
    ("rice_sheaf", 1210, 1630, None, {}),
    ("rice_sheaf", 1610, 1910, None, {}),
    ("rice_sheaf", 1930, 1860, None, {}),
    ("bamboo_clump", 1090, 1430, None, {"sway": True}),
    ("bamboo_clump", 2110, 1510, None, {"sway": True}),
    ("tree", 2160, 1710, (150, 165), {"sway": True}),
    ("lamp", 1150, 1340, None, {"glow": 0.0}),
    ("grass_tuft", 1130, 1580, None, {}),
    ("grass_tuft", 2060, 1780, None, {}),
    ("flower_bush", 1140, 1380, None, {}),
    # Bengkel Pak Jaya
    ("workshop", 2430, 730, (260, 180), {}),
    ("wood_stack", 2300, 910, None, {}),
    ("wood_stack", 2360, 910, None, {}),
    ("crate", 2620, 900, None, {}),
    ("crate", 2670, 900, None, {}),
    ("tools", 2500, 940, None, {}),
    ("tools", 2570, 950, None, {}),
    ("table", 2420, 970, None, {}),
    ("barrel", 2690, 960, None, {}),
    ("sign_post", 2250, 860, None, {}),
    ("cart", 2190, 1010, None, {}),
    ("banner", 2660, 810, None, {"variant": 1}),
    ("lamp", 2300, 720, None, {"glow": 0.0}),
    # Batas desa (pepohonan & bebatuan)
    ("tree", 420, 120, (160, 180), {"sway": True}),
    ("tree", 900, 110, (150, 170), {"sway": True}),
    ("tree", 1500, 120, (170, 190), {"sway": True}),
    ("tree", 2600, 110, (160, 180), {"sway": True}),
    ("tree", 3000, 400, (150, 170), {"sway": True}),
    ("tree", 2950, 800, (140, 160), {"sway": True}),
    ("tree", 120, 1750, (150, 170), {"sway": True}),
    ("tree", 700, 1930, (150, 170), {"sway": True}),
    ("tree", 2450, 1930, (150, 170), {"sway": True}),
    ("tree", 3050, 1600, (140, 160), {"sway": True}),
    ("rock", 700, 1930, None, {}),
    ("rock", 3100, 1200, None, {}),
    ("rock", 300, 800, None, {}),
    ("flower_bush", 620, 1870, None, {}),
    ("flower_bush", 3000, 300, None, {}),
    ("grass_tuft", 480, 620, None, {}),
    ("grass_tuft", 1050, 700, None, {}),
    ("grass_tuft", 2850, 600, None, {}),
]

# --- NPC: (name, scene, x, y, props) --------------------------------------

NPCS = [
    (
        "Npc_MbahSeno", "npc", 1450, 1080,
        {
            "npc_id": "mbah_seno", "display_name": "Mbah Seno", "dialogue_id": "mbah_seno",
            "palette_id": "mbah_seno", "start_facing": (0, 1), "gather_position": (2470, 1530),
        },
    ),
    (
        "Npc_Sari", "npc", 1960, 850,
        {
            "npc_id": "sari", "display_name": "Sari", "dialogue_id": "sari",
            "palette_id": "sari", "start_facing": (0, 1), "gather_position": (2560, 1500),
        },
    ),
    (
        "Npc_PakJaya", "npc", 2520, 850,
        {
            "npc_id": "pak_jaya", "display_name": "Pak Jaya", "dialogue_id": "pak_jaya",
            "palette_id": "pak_jaya", "start_facing": (0, 1), "gather_position": (2620, 1560),
        },
    ),
    (
        "Npc_BuRini", "npc", 560, 1520,
        {
            "npc_id": "bu_rini", "display_name": "Bu Rini", "dialogue_id": "bu_rini",
            "palette_id": "bu_rini", "start_facing": (1, 0), "gather_position": (2420, 1580),
        },
    ),
    (
        "Npc_Dimas", "npc", 1620, 1130,
        {
            "npc_id": "dimas", "display_name": "Dimas", "dialogue_id": "dimas",
            "palette_id": "dimas", "start_facing": (-1, 0), "gather_position": (2540, 1620),
            "alt_quest": "q_hilang", "alt_position": (1700, 1700),
        },
    ),
    (
        "Villager_Petani", "villager", 1300, 1120,
        {
            "npc_id": "warga_petani", "display_name": "Pak Tani", "dialogue_id": "bark_petani",
            "palette_id": "warga_petani", "start_facing": (1, 0), "gather_position": (2380, 1500),
            "wander_points": [(-150, 0), (150, 0)], "wander_pause": 2.4,
        },
    ),
    (
        "Villager_Penjual", "villager", 1650, 880,
        {
            "npc_id": "warga_penjual", "display_name": "Bu Warung", "dialogue_id": "bark_penjual",
            "palette_id": "warga_penjual", "start_facing": (0, 1), "gather_position": (2700, 1500),
            "wander_points": [(0, 150), (-170, 150)], "wander_pause": 1.8,
        },
    ),
    (
        "Villager_Anak", "villager", 1400, 1010,
        {
            "npc_id": "warga_anak", "display_name": "Nia", "dialogue_id": "bark_anak",
            "palette_id": "warga_anak", "start_facing": (1, 0), "gather_position": (2460, 1680),
            "wander_points": [(130, -60), (250, 60), (120, 130)], "wander_pause": 1.2,
        },
    ),
]

# --- AreaZone: (name, x, y, w, h, title, subtitle, flag) -------------------

ZONES = [
    ("Zone_Entrance", 400, 1030, 460, 520, "Desa Arunika", "Gerbang desa", "area_entrance"),
    ("Zone_House", 780, 900, 380, 380, "Rumah Raka", "Rumah yang lama ditinggalkan", "area_house"),
    ("Zone_Square", 1490, 1010, 620, 460, "Alun-Alun Desa", "Tempat warga berkumpul", "area_square"),
    ("Zone_Hall", 1990, 800, 520, 420, "Balai Desa", "Pusat kegiatan warga", "area_hall"),
    ("Zone_Garden", 620, 1520, 520, 420, "Kebun Bu Rini", "Kebun yang dirawat berbagi", "area_garden"),
    ("Zone_Ricefield", 1620, 1660, 900, 420, "Sawah Arunika", "Sambatan saat musim tanam", "area_ricefield"),
    ("Zone_Workshop", 2450, 850, 560, 420, "Bengkel Pak Jaya", "Ilmu yang diwariskan", "area_workshop"),
    ("Zone_Field", 2550, 1420, 760, 520, "Lapangan Guyub", "Tempat acara dimulai", "area_field"),
]

# --- Papan & objek informatif ---------------------------------------------

BOARDS = [
    ("Board_Welcome", 230, 1030, "papan_selamat_datang", "guyub_desa", "Baca papan"),
    ("Board_Square", 1560, 900, "papan_alun_alun", "gotong_royong", "Baca pengumuman"),
    ("Board_Ricefield", 1255, 1330, "papan_sawah", "sambatan_sawah", "Baca papan"),
    ("Board_Workshop", 2250, 860, "papan_bengkel", "warisan_ilmu", "Baca papan"),
    ("Board_Well", 1690, 1200, "sumur", "sumur_bersama", "Periksa sumur"),
    ("Board_Garden", 430, 1630, "kebun_bu_rini", "bahan_alam", "Periksa kebun"),
    ("Board_Hall", 1900, 900, "balai_desa", "halaman_warga", "Baca papan"),
    ("Board_Gate", 620, 1080, "papan_ajakan", "", "Baca papan"),
    ("Board_Stage", 2350, 1480, "panggung", "", "Lihat panggung"),
]

# --- Titik interaksi lain --------------------------------------------------

PICKUPS = [
    ("Pickup_Bambu", 1075, 1370, "bambu", "q_persiapan", "o_bambu", "took_bambu"),
]

STATIONS = [
    ("Station_Persiapan", 2540, 1560, "prep", "Susun perlengkapan"),
]

# Blocker tambahan (tiang gapura) — supaya pemain tetap bisa lewat di bawahnya.
BLOCKERS = [
    ("Gapura_West_A", 270, 1055), ("Gapura_West_B", 390, 1055),
    ("Gapura_Field_A", 2440, 1265), ("Gapura_Field_B", 2560, 1265),
]

EXT = [
    ("Script", "res://scripts/world/Village.gd", "1_village"),
    ("Script", "res://scripts/world/VillageGround.gd", "2_ground"),
    ("PackedScene", "res://scenes/props/Prop.tscn", "3_prop"),
    ("PackedScene", "res://scenes/player/Player.tscn", "4_player"),
    ("PackedScene", "res://scenes/npc/Npc.tscn", "5_npc"),
    ("PackedScene", "res://scenes/npc/Villager.tscn", "6_villager"),
    ("PackedScene", "res://scenes/props/ItemPickup.tscn", "7_pickup"),
    ("PackedScene", "res://scenes/props/InfoBoard.tscn", "8_board"),
    ("PackedScene", "res://scenes/world/AreaZone.tscn", "9_zone"),
    ("PackedScene", "res://scenes/world/SupplyStation.tscn", "10_station"),
]


def vec(values) -> str:
    return f"Vector2({values[0]}, {values[1]})"


def rect2(values) -> str:
    return f"Rect2({values[0]}, {values[1]}, {values[2]}, {values[3]})"


def rect_array(rects) -> str:
    return "Array[Rect2]([" + ", ".join(rect2(r) for r in rects) + "])"


def packed_vec_array(points) -> str:
    flat = []
    for x, y in points:
        flat.append(str(x))
        flat.append(str(y))
    return "PackedVector2Array(" + ", ".join(flat) + ")"


def build() -> str:
    lines: list[str] = []
    sub_resources = [
        ("RectangleShape2D_wide", "size = Vector2(3240, 60)"),
        ("RectangleShape2D_tall", "size = Vector2(60, 2060)"),
        ("RectangleShape2D_post", "size = Vector2(34, 30)"),
    ]
    load_steps = len(EXT) + len(sub_resources) + 1
    lines.append(f"[gd_scene load_steps={load_steps} format=3]")
    lines.append("")
    for kind, path, rid in EXT:
        lines.append(f'[ext_resource type="{kind}" path="{path}" id="{rid}"]')
    lines.append("")
    for rid, body in sub_resources:
        lines.append(f'[sub_resource type="RectangleShape2D" id="{rid}"]')
        lines.append(body)
        lines.append("")

    # Root
    lines.append('[node name="Village" type="Node2D"]')
    lines.append('script = ExtResource("1_village")')
    lines.append(f"map_bounds = {rect2(MAP)}")
    lines.append(f"spawn_point = {vec(SPAWN)}")
    lines.append("")

    # Ground
    lines.append('[node name="Ground" type="Node2D" parent="."]')
    lines.append('script = ExtResource("2_ground")')
    lines.append(f"map_bounds = {rect2(MAP)}")
    lines.append(f"paths = {rect_array(PATHS)}")
    lines.append(f"plazas = {rect_array(PLAZAS)}")
    lines.append(f"paddies = {rect_array(PADDIES)}")
    lines.append(f"ponds = {rect_array(PONDS)}")
    lines.append(f"gardens = {rect_array(GARDENS)}")
    lines.append(f"open_soil = {rect_array(OPEN_SOIL)}")
    lines.append(f"flower_patches = {rect_array(FLOWERS)}")
    lines.append("")

    # Entities (y-sorted world contents)
    lines.append('[node name="Entities" type="Node2D" parent="."]')
    lines.append("y_sort_enabled = true")
    lines.append("")

    lines.append('[node name="Player" parent="Entities" instance=ExtResource("4_player")]')
    lines.append(f"position = {vec(SPAWN)}")
    lines.append("")

    counters: dict[str, int] = {}
    for kind, x, y, size, kwargs in PROPS:
        counters[kind] = counters.get(kind, 0) + 1
        name = f"Prop_{kind}_{counters[kind]:02d}"
        lines.append(f'[node name="{name}" parent="Entities" instance=ExtResource("3_prop")]')
        lines.append(f"position = {vec((x, y))}")
        lines.append(f'kind = "{kind}"')
        if size is not None:
            lines.append(f"size = {vec(size)}")
        if "variant" in kwargs:
            lines.append(f"variant = {kwargs['variant']}")
        if kwargs.get("sway"):
            lines.append("sway = true")
        if "solid" in kwargs:
            lines.append(f"solid = {'true' if kwargs['solid'] else 'false'}")
        if "glow" in kwargs:
            lines.append(f"glow = {kwargs['glow']}")
        lines.append("")

    for name, scene, x, y, props in NPCS:
        scene_id = "5_npc" if scene == "npc" else "6_villager"
        lines.append(f'[node name="{name}" parent="Entities" instance=ExtResource("{scene_id}")]')
        lines.append(f"position = {vec((x, y))}")
        for key, value in props.items():
            if key in ("start_facing", "gather_position", "alt_position"):
                lines.append(f"{key} = {vec(value)}")
            elif key == "wander_points":
                lines.append(f"{key} = {packed_vec_array(value)}")
            elif isinstance(value, str):
                lines.append(f'{key} = "{value}"')
            else:
                lines.append(f"{key} = {value}")
        lines.append("")

    for name, x, y, item, quest, objective, flag in PICKUPS:
        lines.append(f'[node name="{name}" parent="Entities" instance=ExtResource("7_pickup")]')
        lines.append(f"position = {vec((x, y))}")
        lines.append(f'item_id = "{item}"')
        lines.append(f'quest_id = "{quest}"')
        lines.append(f'objective_id = "{objective}"')
        lines.append(f'flag_id = "{flag}"')
        lines.append("")

    for name, x, y, dialogue, note, prompt in BOARDS:
        lines.append(f'[node name="{name}" parent="Entities" instance=ExtResource("8_board")]')
        lines.append(f"position = {vec((x, y))}")
        lines.append(f'dialogue_id = "{dialogue}"')
        if note:
            lines.append(f'note_id = "{note}"')
        lines.append(f'prompt_text = "{prompt}"')
        lines.append("")

    for name, x, y, puzzle, prompt in STATIONS:
        lines.append(f'[node name="{name}" parent="Entities" instance=ExtResource("10_station")]')
        lines.append(f"position = {vec((x, y))}")
        lines.append('required_items = PackedStringArray("bambu", "tali", "papan_kayu", "kain_pola")')
        lines.append(f'puzzle_id = "{puzzle}"')
        lines.append(f'prompt_text = "{prompt}"')
        lines.append("")

    # Zones
    lines.append('[node name="Zones" type="Node2D" parent="."]')
    lines.append("")
    for name, x, y, w, h, title, subtitle, flag in ZONES:
        lines.append(f'[node name="{name}" parent="Zones" instance=ExtResource("9_zone")]')
        lines.append(f"position = {vec((x, y))}")
        lines.append(f'area_title = "{title}"')
        lines.append(f'area_subtitle = "{subtitle}"')
        lines.append(f'flag_id = "{flag}"')
        lines.append(f"zone_size = {vec((w, h))}")
        lines.append("")

    # Walls & blockers
    lines.append('[node name="Walls" type="StaticBody2D" parent="."]')
    lines.append("collision_layer = 1")
    lines.append("collision_mask = 0")
    lines.append("")
    for name, pos, shape in [
        ("Wall_Top", (1600, 20), "RectangleShape2D_wide"),
        ("Wall_Bottom", (1600, 1980), "RectangleShape2D_wide"),
        ("Wall_Left", (20, 1000), "RectangleShape2D_tall"),
        ("Wall_Right", (3180, 1000), "RectangleShape2D_tall"),
    ]:
        lines.append(f'[node name="{name}" type="CollisionShape2D" parent="Walls"]')
        lines.append(f"position = {vec(pos)}")
        lines.append(f'shape = SubResource("{shape}")')
        lines.append("")
    for name, x, y in BLOCKERS:
        lines.append(f'[node name="{name}" type="CollisionShape2D" parent="Walls"]')
        lines.append(f"position = {vec((x, y))}")
        lines.append('shape = SubResource("RectangleShape2D_post")')
        lines.append("")

    return "\n".join(lines) + "\n"


# --- Ekspor JSON untuk versi web (React) -----------------------------------
#
# Spesifikasi peta di berkas ini adalah satu-satunya sumber kebenaran: selain
# menulis scene Godot, skrip ini juga menulis data/world/village.json yang
# dibaca versi web. Dengan begitu peta tidak pernah ditulis dua kali.

JSON_OUT = ROOT / "data" / "world" / "village.json"
PROP_SCRIPT = ROOT / "scripts" / "world" / "Prop.gd"


def _prop_rules():
    """Baca ukuran & profil tabrakan langsung dari scripts/world/Prop.gd.

    Dengan begitu versi Godot dan versi web memakai angka yang sama; tidak ada
    tabel ukuran yang ditulis dua kali.
    """
    import re

    source = PROP_SCRIPT.read_text(encoding="utf-8")

    def table(name: str) -> dict:
        body = source[source.index("const " + name):]
        body = body[: body.index("\n}")]
        out = {}
        for key, values in re.findall(r'"([a-z_]+)":\s*Vector2\(([^)]*)\)', body):
            x, y = [float(v) for v in values.split(",")[:2]]
            out[key] = (x, y)
        return out

    def string_list(name: str) -> list:
        body = source[source.index("const " + name):]
        body = body[: body.index("]")]
        return re.findall(r'"([a-z_]+)"', body)

    return table("DEFAULT_SIZES"), table("COLLISION"), string_list("SOFT_KINDS")


def _point(values):
    return {"x": values[0], "y": values[1]}


def _rect(values):
    return {"x": values[0], "y": values[1], "w": values[2], "h": values[3]}


def export_json() -> dict:
    sizes, profiles, soft_kinds = _prop_rules()
    props = []
    for index, (kind, x, y, size, kwargs) in enumerate(PROPS):
        dims = size if size else sizes.get(kind, (64, 64))
        solid = bool(kwargs.get("solid", True)) and kind not in soft_kinds
        profile = profiles.get(kind, (0.86, 0.26))
        width = max(dims[0] * profile[0], 8.0)
        height = max(dims[1] * profile[1], 8.0)
        collision = (
            {"x": x - width / 2, "y": y - height, "w": width, "h": height} if solid else None
        )
        props.append(
            {
                "id": f"{kind}_{index + 1}",
                "kind": kind,
                "x": x,
                "y": y,
                "size": _point(size) if size else None,
                "w": dims[0],
                "h": dims[1],
                "collision": collision,
                "variant": int(kwargs.get("variant", 0)),
                "sway": bool(kwargs.get("sway", False)),
                "solid": solid,
                "glow": float(kwargs.get("glow", 0.0)),
            }
        )

    npcs = []
    for name, scene, x, y, kw in NPCS:
        entry = {"id": name, "kind": scene, "x": x, "y": y}
        entry["npc_id"] = kw["npc_id"]
        entry["display_name"] = kw["display_name"]
        entry["dialogue_id"] = kw["dialogue_id"]
        entry["palette_id"] = kw["palette_id"]
        entry["start_facing"] = _point(kw.get("start_facing", (0, 1)))
        entry["gather_position"] = _point(kw["gather_position"]) if kw.get("gather_position") else None
        entry["alt_quest"] = kw.get("alt_quest", "")
        entry["alt_position"] = _point(kw["alt_position"]) if kw.get("alt_position") else None
        entry["wander_points"] = [_point(point) for point in kw.get("wander_points", [])]
        entry["wander_pause"] = float(kw.get("wander_pause", 1.8))
        npcs.append(entry)

    zones = []
    for name, x, y, w, h, title, subtitle, flag in ZONES:
        zones.append(
            {
                "id": name,
                "rect": {"x": x - w / 2, "y": y - h / 2, "w": w, "h": h},
                "title": title,
                "subtitle": subtitle,
                "flag": flag,
            }
        )

    boards = []
    for name, x, y, dialogue_id, note_id, prompt in BOARDS:
        boards.append(
            {
                "id": name,
                "x": x,
                "y": y,
                "dialogue_id": dialogue_id,
                "note_id": note_id,
                "prompt": prompt,
            }
        )

    pickups = []
    for name, x, y, item_id, quest_id, objective_id, flag_id in PICKUPS:
        pickups.append(
            {
                "id": name,
                "x": x,
                "y": y,
                "item_id": item_id,
                "quest_id": quest_id,
                "objective_id": objective_id,
                "flag_id": flag_id,
            }
        )

    stations = []
    for name, x, y, puzzle_id, prompt in STATIONS:
        stations.append({"id": name, "x": x, "y": y, "puzzle_id": puzzle_id, "prompt": prompt})

    blockers = [
        {"id": name, "x": x, "y": y, "w": 34, "h": 30} for name, x, y in BLOCKERS
    ]

    return {
        "map": _rect(MAP),
        "spawn": _point(SPAWN),
        "paths": [_rect(r) for r in PATHS],
        "plazas": [_rect(r) for r in PLAZAS],
        "paddies": [_rect(r) for r in PADDIES],
        "ponds": [_rect(r) for r in PONDS],
        "gardens": [_rect(r) for r in GARDENS],
        "open_soil": [_rect(r) for r in OPEN_SOIL],
        "flowers": [_rect(r) for r in FLOWERS],
        "props": props,
        "npcs": npcs,
        "zones": zones,
        "boards": boards,
        "pickups": pickups,
        "stations": stations,
        "blockers": blockers,
    }


def write_json() -> None:
    import json

    JSON_OUT.parent.mkdir(parents=True, exist_ok=True)
    payload = export_json()
    JSON_OUT.write_text(json.dumps(payload, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
    print(
        f"wrote {JSON_OUT.relative_to(ROOT)} — {len(payload['props'])} props, "
        f"{len(payload['npcs'])} npc, {len(payload['zones'])} zona"
    )


def main() -> None:
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(build(), encoding="utf-8")
    print(f"wrote {OUT.relative_to(ROOT)} — {len(PROPS)} props, {len(NPCS)} npc, {len(ZONES)} zones")
    write_json()


if __name__ == "__main__":
    main()
