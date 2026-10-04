#!/usr/bin/env python3
"""Audit alur permainan TAPAK NUSA (statis).

Validator (tools/validate_project.py) memeriksa sintaks, API, dan referensi.
Skrip ini memeriksa *alur*: apakah setiap objective quest bisa diselesaikan,
apakah setiap quest punya pemicu, apakah setiap flag yang dibaca punya penulis,
dan apakah akhir cerita bisa dicapai.

Pemakaian:
    python3 tools/audit_flow.py

Keluaran: daftar temuan (TIDAK BISA = kemungkinan soft-lock, PERIKSA = perlu
dilihat manusia). Tanpa temuan berarti alur konsisten menurut data.
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DATA = ROOT / "data"
SCENES = ROOT / "scenes"

EFFECT_KEYS = {
    "sfx",
    "message",
    "banner",
    "banner_subtitle",
    "set_flags",
    "clear_flags",
    "give_items",
    "remove_items",
    "note",
    "start_quest",
    "start_quests",
    "advance_objectives",
    "complete_objectives",
    "complete_quest",
    "complete_quests",
    "start_puzzle",
    "start_dialogue",
    "goto_screen",
    "finish_game",
}

findings: list[tuple[str, str]] = []
info: list[str] = []


def fail(message: str) -> None:
    findings.append(("TIDAK BISA", message))


def check(message: str) -> None:
    findings.append(("PERIKSA", message))


def load_json(path: Path):
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception as exc:  # pragma: no cover - hanya untuk laporan
        fail(f"{path.relative_to(ROOT)}: JSON tidak bisa dibaca ({exc})")
        return {}


# ---------------------------------------------------------------------------
# Muat data
# ---------------------------------------------------------------------------

quests = load_json(DATA / "quests" / "quests.json")
items = load_json(DATA / "items" / "items.json")
notes = load_json(DATA / "notes" / "cultural_notes.json")

dialogue_nodes: dict[str, dict] = {}   # "dialog_id/node_id" -> node
dialogue_ids: set[str] = set()
for path in sorted((DATA / "dialogue").glob("*.json")):
    payload = load_json(path)
    for dialogue_id, value in payload.items():
        dialogue_ids.add(dialogue_id)
        for node in value.get("nodes", []):
            key = f"{dialogue_id}/{node.get('id', '?')}"
            dialogue_nodes[key] = node

scene_texts = {p: p.read_text(encoding="utf-8", errors="replace") for p in sorted(SCENES.rglob("*.tscn"))}
script_texts = {p: p.read_text(encoding="utf-8", errors="replace") for p in sorted((ROOT / "scripts").rglob("*.gd"))}
autoload_texts = {p: p.read_text(encoding="utf-8", errors="replace") for p in sorted((ROOT / "autoload").rglob("*.gd"))}
all_code = {**script_texts, **autoload_texts}
code_blob = "\n".join(all_code.values())


# ---------------------------------------------------------------------------
# Kumpulkan pemicu
# ---------------------------------------------------------------------------

started_quests: dict[str, list[str]] = {}
completed_objectives: dict[tuple[str, str], list[str]] = {}
adv_give_items: dict[str, list[str]] = {}
flag_writers: dict[str, list[str]] = {}
flag_readers: dict[str, list[str]] = {}
dialogue_used: set[str] = set()
notes_referenced: set[str] = set()
items_given: dict[str, list[str]] = {}
goto_screens: dict[str, list[str]] = {}


def note_effect(where: str, effects: dict) -> None:
    if not isinstance(effects, dict):
        check(f"{where}: 'effects' bukan objek")
        return
    for key in effects:
        if key not in EFFECT_KEYS:
            check(f"{where}: kunci efek tidak dikenal: '{key}'")
    if "sfx" in effects:
        pass
    for quest_id in [effects.get("start_quest")] if "start_quest" in effects else []:
        started_quests.setdefault(str(quest_id), []).append(where)
    for quest_id in effects.get("start_quests", []) or []:
        started_quests.setdefault(str(quest_id), []).append(where)
    for entry in effects.get("complete_objectives", []) or []:
        completed_objectives.setdefault((str(entry.get("quest")), str(entry.get("objective"))), []).append(where)
    for entry in effects.get("advance_objectives", []) or []:
        completed_objectives.setdefault((str(entry.get("quest")), str(entry.get("objective"))), []).append(where)
    if "complete_quest" in effects:
        completed_objectives.setdefault(("*" + str(effects["complete_quest"]), "*"), []).append(where)
    for quest_id in effects.get("complete_quests", []) or []:
        completed_objectives.setdefault(("*" + str(quest_id), "*"), []).append(where)
    for item_id in effects.get("give_items", []) or []:
        items_given.setdefault(str(item_id), []).append(where)
    if "note" in effects:
        notes_referenced.add(str(effects["note"]))
    for flag in (effects.get("set_flags") or {}).keys():
        flag_writers.setdefault(str(flag), []).append(where)
    for flag in effects.get("clear_flags", []) or []:
        flag_writers.setdefault(str(flag), []).append(where + " (clear)")
    if "start_dialogue" in effects:
        dialogue_used.add(str(effects["start_dialogue"]))
    if "goto_screen" in effects:
        goto_screens.setdefault(str(effects["goto_screen"]), []).append(where)


def note_conditions(where: str, conditions: dict) -> None:
    if not isinstance(conditions, dict):
        check(f"{where}: 'conditions' bukan objek")
        return
    for flag, value in (conditions.get("flags") or {}).items():
        flag_readers.setdefault(str(flag), []).append(f"{where} (harus {value})")
    for flag in conditions.get("not_flags", []) or []:
        flag_readers.setdefault(str(flag), []).append(f"{where} (harus tidak)")
    for quest_id in ["q_pulang"]:  # placeholder agar loop di bawah tetap jelas
        break
    for key in ("quest_active", "quest_not_started", "quest_completed", "quest_not_completed"):
        value = conditions.get(key)
        if value:
            flag_readers.setdefault(f"@{key}:{value}", []).append(where)
    for item_id in conditions.get("items", []) or []:
        flag_readers.setdefault(f"@item:{item_id}", []).append(where)
    for item_id in conditions.get("missing_items", []) or []:
        flag_readers.setdefault(f"@missing:{item_id}", []).append(where)
    for note_id in conditions.get("notes", []) or []:
        flag_readers.setdefault(f"@note:{note_id}", []).append(where)
    if conditions.get("game_finished"):
        flag_readers.setdefault("@game_finished", []).append(where)


# Dialog
for key, node in dialogue_nodes.items():
    note_conditions(key, node.get("conditions", {}) or {})
    note_effect(key, node.get("effects", {}) or {})

# Quest (on_start / on_complete)
for quest_id, quest in quests.items():
    note_effect(f"quest:{quest_id}.on_start", quest.get("on_start", {}) or {})
    note_effect(f"quest:{quest_id}.on_complete", quest.get("on_complete", {}) or {})

# Scene: interaksi dunia
scene_dialogues: set[str] = set()
scene_notes: set[str] = set()
for path, text in scene_texts.items():
    rel = "res://" + str(path.relative_to(ROOT))
    blocks = re.split(r"\n(?=\[)", text)
    name = ""
    node_type = ""
    for block in blocks:
        header = re.match(r"\[node name=\"([^\"]+)\"(?:[^\]]*?type=\"([^\"]+)\")?", block)
        if header:
            name = header.group(1)
            node_type = header.group(2) or ""
        if not name or not block.startswith("[node"):
            continue
        for dialogue_id in re.findall(r'^dialogue_id = \"([^\"]+)\"', block, re.M):
            scene_dialogues.add(dialogue_id)
            dialogue_used.add(dialogue_id)
            if dialogue_id not in dialogue_ids:
                fail(f"{rel}:{name}: dialogue_id '{dialogue_id}' tidak ada di data/dialogue")
        for dialogue_id in re.findall(r'^ready_dialogue = \"([^\"]+)\"', block, re.M):
            scene_dialogues.add(dialogue_id)
            dialogue_used.add(dialogue_id)
        for note_id in re.findall(r'^note_id = \"([^\"]+)\"', block, re.M):
            scene_notes.add(note_id)
            if note_id not in notes:
                fail(f"{rel}:{name}: note_id '{note_id}' tidak ada di cultural_notes.json")
        quest_id = re.search(r'^quest_id = \"([^\"]+)\"', block, re.M)
        objective_id = re.search(r'^objective_id = \"([^\"]+)\"', block, re.M)
        item_id = re.search(r'^item_id = \"([^\"]+)\"', block, re.M)
        if quest_id and objective_id:
            completed_objectives.setdefault((quest_id.group(1), objective_id.group(1)), []).append(
                f"{rel}:{name} (interaksi)"
            )
        if item_id:
            items_given.setdefault(item_id.group(1), []).append(f"{rel}:{name} (ambil)")
        flag_id = re.search(r'^flag_id = \"([^\"]+)\"', block, re.M)
        if flag_id:
            flag_writers.setdefault(flag_id.group(1), []).append(f"{rel}:{name}")
        if node_type == "AreaZone" or 'script = ExtResource("9_zone")' in block:
            pass

def _flag_calls(text: str, func: str) -> list[tuple[str, bool]]:
    """Ambil nama flag dari pemanggilan func("nama") atau func("nama" + var)."""
    out: list[tuple[str, bool]] = []
    for match in re.finditer(func + r'\(\s*"([^"]+)"\s*(\+|%|,|\))', text):
        out.append((match.group(1), match.group(2) in "+%"))
    return out


# Skrip: flag yang ditulis/dibaca lewat kode
for path, text in all_code.items():
    rel = str(path.relative_to(ROOT))
    for flag, dynamic in _flag_calls(text, "set_flag"):
        flag_writers.setdefault(flag + ("*" if dynamic else ""), []).append(f"{rel} (kode)")
    for flag, dynamic in _flag_calls(text, "has_flag"):
        flag_readers.setdefault(flag + ("*" if dynamic else ""), []).append(f"{rel} (kode)")
    for flag, dynamic in _flag_calls(text, "get_flag"):
        flag_readers.setdefault(flag + ("*" if dynamic else ""), []).append(f"{rel} (kode)")

# Puzzle selesai -> flag + dialog sukses
puzzle_success = {
    "pattern": "pak_jaya_sukses",
    "prep": "guyub_siap",
}
for puzzle_id, dialogue_id in puzzle_success.items():
    flag_writers.setdefault(f"puzzle_{puzzle_id}_done", []).append("GameManager.finish_puzzle (kode)")
    dialogue_used.add(dialogue_id)

# Quest otomatis dari objective (script) - tandai objective yang dipakai skrip
for quest_id, quest in quests.items():
    for objective in quest.get("objectives", []):
        key = (quest_id, objective["id"])
        if key not in completed_objectives and (f"*{quest_id}", "*") not in completed_objectives:
            check(
                f"objective tanpa pemicu eksplisit: {quest_id}/{objective['id']} "
                f"('{objective.get('text', '')}')"
            )

# Quest harus punya pemicu mulai (q_pulang dimulai dari Opening)
for quest_id in quests:
    if quest_id not in started_quests:
        starters = [f"quest:{q}.on_complete" for q in quests if quests[q].get("on_complete", {}).get("start_quest") == quest_id]
        if quest_id == "q_pulang":
            continue
        fail(f"quest '{quest_id}' tidak pernah dimulai oleh efek mana pun")


# ---------------------------------------------------------------------------
# Rujukan id berupa string di dalam skrip
# ---------------------------------------------------------------------------

audio_source = (ROOT / "scripts" / "util" / "ProceduralAudio.gd").read_text()
sfx_names = set(re.findall(r'"([a-z0-9_]+)"', audio_source[audio_source.index("static func sfx_names"):audio_source.index("static func get_sfx")]))
music_names = set(re.findall(r'^\t\t"([a-z0-9_]+)":', audio_source[audio_source.index("static func _build_music"):audio_source.index("static func _sequence")], re.M))
ambient_names = set(re.findall(r'^\t\t"([a-z0-9_]+)":', audio_source[audio_source.index("static func _build_ambient"):], re.M))

screens = {"main_menu", "opening", "village", "ending", "credits"}
puzzles = {"pattern", "prep"}

LITERAL_CHECKS: list[tuple[str, str, set[str], str]] = [
    ("play_sfx", "efek suara", sfx_names, "ProceduralAudio.sfx_names()"),
    ("play_music", "musik", music_names, "ProceduralAudio musik"),
    ("play_ambient", "ambience", ambient_names, "ProceduralAudio ambience"),
    ("start_quest", "quest", set(quests), "data/quests/quests.json"),
    ("complete_quest", "quest", set(quests), "data/quests/quests.json"),
    ("get_quest", "quest", set(quests), "data/quests/quests.json"),
    ("is_active", "quest", set(quests), "data/quests/quests.json"),
    ("is_completed", "quest", set(quests), "data/quests/quests.json"),
    ("has_started", "quest", set(quests), "data/quests/quests.json"),
    ("add_item", "item", set(items), "data/items/items.json"),
    ("has_item", "item", set(items), "data/items/items.json"),
    ("remove_item", "item", set(items), "data/items/items.json"),
    ("find_note", "catatan", set(notes), "data/notes/cultural_notes.json"),
    ("note_title", "catatan", set(notes), "data/notes/cultural_notes.json"),
    ("note_text", "catatan", set(notes), "data/notes/cultural_notes.json"),
    ("goto_screen", "layar", screens, "GameManager.SCREENS"),
    ("change_screen", "layar", screens, "GameManager.SCREENS"),
    ("start_puzzle", "puzzle", puzzles, "GameManager.PUZZLE_SCENES"),
    ("DialogueManager.start", "dialog", dialogue_ids, "data/dialogue/"),
]

for path, text in all_code.items():
    rel = str(path.relative_to(ROOT))
    for number, line in enumerate(text.split("\n"), start=1):
        if line.strip().startswith("#"):
            continue
        for func, label, valid, source in LITERAL_CHECKS:
            for match in re.finditer(re.escape(func) + r'\(\s*"([^"]+)"', line):
                value = match.group(1)
                if value and value not in valid:
                    fail(f"{rel}:{number}: {label} '{value}' tidak ada di {source}")
                if value and func == "DialogueManager.start":
                    dialogue_used.add(value)

# nama dialog yang disebut sebagai string di mana pun (mis. nilai default @export)
for path, text in all_code.items():
    for dialogue_id in re.findall(r'"([a-z0-9_]+)"', text):
        if dialogue_id in dialogue_ids:
            dialogue_used.add(dialogue_id)

# efek di data juga memakai nama sfx
for key, node in dialogue_nodes.items():
    effects = node.get("effects") or {}
    for sfx in ([effects["sfx"]] if "sfx" in effects else []):
        if str(sfx) not in sfx_names:
            fail(f"dialog {key}: sfx '{sfx}' tidak ada di ProceduralAudio.sfx_names()")


# ---------------------------------------------------------------------------
# Laporan alur cerita
# ---------------------------------------------------------------------------

for quest_id, quest in sorted(quests.items(), key=lambda kv: kv[1].get("order", 0)):
    for objective in quest.get("objectives", []):
        trig = completed_objectives.get((quest_id, objective["id"])) or completed_objectives.get((f"*{quest_id}", "*"))
        status = "ok" if trig else "TIDAK ADA"
        info.append(
            f"  {quest_id}/{objective['id']}: {status}"
            + (f" <- {trig[0].split(' ')[0]}" if trig else "")
        )

# Item & kebutuhan
required_items: dict[str, list[str]] = {}
for quest_id, quest in quests.items():
    for objective in quest.get("objectives", []):
        if objective.get("item"):
            required_items.setdefault(objective["item"], []).append(f"quest:{quest_id}/{objective['id']}")
for path, text in scene_texts.items():
    for match in re.finditer(r'^required_items = PackedStringArray\(([^)]*)\)', text, re.M):
        for item_id in re.findall(r'"([^"]+)"', match.group(1)):
            required_items.setdefault(item_id, []).append(str(path.relative_to(ROOT)))
for item_id, who in sorted(required_items.items()):
    if item_id not in items_given:
        fail(f"item '{item_id}' dibutuhkan ({who[0]}) tapi tidak pernah diberikan")
    elif item_id not in items:
        check(f"item '{item_id}' tidak ada di items.json")

for item_id in items_given:
    if item_id not in items:
        fail(f"item '{item_id}' diberikan tapi tidak ada di data/items/items.json")

def _written(flag: str) -> bool:
    if flag in flag_writers:
        return True
    if flag.endswith("*"):
        prefix = flag[:-1]
        return any(other.startswith(prefix) for other in flag_writers)
    return any(other.startswith(flag[:-1]) for other in flag_writers if other.endswith("*"))


def _read(flag: str) -> bool:
    if flag in flag_readers:
        return True
    if flag.endswith("*"):
        prefix = flag[:-1]
        return any(other.startswith(prefix) for other in flag_readers)
    return any(other.startswith(flag[:-1]) for other in flag_readers if other.endswith("*"))


# Flag yang dibaca tapi tidak pernah ditulis
for flag, readers in sorted(flag_readers.items()):
    if flag.startswith("@"):
        continue
    if not _written(flag):
        fail(f"flag '{flag}' dibaca ({readers[0]}) tapi tidak pernah di-set")

# Flag yang ditulis tapi tidak pernah dibaca (hanya info)
for flag in sorted(flag_writers):
    if flag.startswith("puzzle_"):
        continue
    if not _read(flag):
        info.append(f"  flag '{flag}' ditulis tapi tidak ada kondisi yang membacanya")

# Dialog yang tidak dipakai
for dialogue_id in sorted(dialogue_ids):
    if dialogue_id not in dialogue_used:
        check(f"dialog '{dialogue_id}' tidak pernah dipanggil dari skrip atau scene")

# Catatan budaya
for note_id in sorted(notes):
    if note_id not in scene_notes and f"@{note_id}" not in " ".join(flag_readers) and note_id not in notes_referenced:
        info.append(f"  catatan '{note_id}' tidak dipakai di scene")

# Layar
for screen_id in sorted(set(list(goto_screens) + ["main_menu", "opening", "village", "ending", "credits"])):
    if screen_id not in {"main_menu", "opening", "village", "ending", "credits"}:
        fail(f"goto_screen '{screen_id}' bukan layar yang dikenal")

# Akhir cerita harus terjangkau
if not any("finish_game" in (node.get("effects") or {}) for node in dialogue_nodes.values()):
    fail("tidak ada dialog yang memanggil finish_game")
if "event_ready" not in flag_writers:
    fail("flag 'event_ready' tidak pernah di-set, akhir cerita tidak bisa dicapai")


def main() -> int:
    print("=== Ringkasan alur ===")
    for line in info:
        print(line)
    print()
    print(f"=== Temuan: {len(findings)} ===")
    for kind, message in findings:
        print(f"[{kind}] {message}")
    hard = [f for f in findings if f[0] == "TIDAK BISA"]
    print()
    print(f"{len(hard)} masalah keras, {len(findings) - len(hard)} catatan.")
    return 1 if hard else 0


if __name__ == "__main__":
    sys.exit(main())
