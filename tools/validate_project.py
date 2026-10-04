#!/usr/bin/env python3
"""Pemeriksa statis proyek TAPAK NUSA.

Menjalankan beberapa lapis pemeriksaan tanpa perlu membuka Godot:

  * GDScript  : indentasi, pasangan blok/tanda kurung, kelas proyek (class_name)
                yang tidak dikenal, referensi res:// yang hilang, dan pemakaian
                API yang tidak ada di dokumentasi kelas Godot (opsional, lihat
                --api untuk memeriksa versi 4.x terbaru dan --api-compat untuk
                versi 4.x paling lama yang didukung).
  * Scene     : format .tscn, ext_resource/sub_resource yang lengkap, pohon node,
                properti node terhadap dokumentasi kelas, nama unik pemilik (%).
  * project.godot: bagian yang wajib, autoload, input action, properti objek.
  * Data      : JSON dialog/quest/item/catatan beserta rujukan silang id-nya.

Contoh pemakaian:
    python3 tools/validate_project.py
    python3 tools/validate_project.py --api /tmp/godot_api --api-compat /tmp/godot_api_42
"""

from __future__ import annotations

import argparse
import json
import re
import sys
import xml.etree.ElementTree as ET
from pathlib import Path
from typing import Iterable

ROOT = Path(__file__).resolve().parents[1]

SKIP_DIRS = {"tools", "__pycache__", ".git", ".arena", "assets/ui/theme"}

# --- Properti Control/Node yang diatur oleh editor, bukan anggota kelas -----
LAYOUT_PROPS = re.compile(
    r"^(layout_mode|anchors_preset|anchor_[a-z]+|offset_[a-z]+|grow_[a-z]+|"
    r"size_flags_[a-z]+|theme_override_[a-z_/]+|metadata/[a-zA-Z0-9_]+|"
    r"physics_material_override|script|instance|index|owner|groups|"
    r"auto_translate_mode|process_thread_group|editor_description|"
    r"follow_viewport_settings|texture_filter|clip_children)"
)

# --- Fungsi/@GlobalScope yang selalu boleh dipanggil ------------------------
BUILTIN_CALLS = {
    "preload", "load", "print", "print_rich", "print_verbose", "push_error",
    "push_warning", "range", "str", "int", "float", "bool", "abs", "sign",
    "min", "max", "clamp", "lerp", "is_instance_valid", "is_same", "typeof",
    "weakref", "hash", "len", "sin", "cos", "tan", "asin", "acos", "atan",
    "atan2", "sqrt", "pow", "log", "exp", "floor", "ceil", "round", "fmod",
    "wrapf", "wrapi", "snapped", "snappedf", "lerpf", "move_toward", "remap",
    "smoothstep", "ease", "randf", "randi", "randf_range", "randi_range",
    "randomize", "seed", "var_to_str", "str_to_var", "type_convert",
}

# --- Kata kunci yang tidak boleh dibaca sebagai pemanggilan fungsi ----------
KEYWORDS = {
    "if", "elif", "else", "while", "for", "match", "return", "and", "or", "not",
    "in", "is", "as", "func", "var", "const", "static", "class_name", "extends",
    "await", "assert", "break", "continue", "pass", "super", "self", "enum",
    "signal", "class", "yield", "when", "void", "true", "false", "null",
}

GODOT_TYPES = {
    "int", "float", "bool", "String", "StringName", "NodePath", "void",
    "Vector2", "Vector2i", "Vector3", "Vector4", "Rect2", "Rect2i", "Color",
    "Array", "Dictionary", "Callable", "Signal", "PackedByteArray",
    "PackedInt32Array", "PackedInt64Array", "PackedFloat32Array",
    "PackedFloat64Array", "PackedStringArray", "PackedVector2Array",
    "PackedVector3Array", "PackedColorArray", "Variant", "Object", "Quaternion",
    "Transform2D", "Transform3D", "Basis", "Plane", "Projection", "AABB",
    "RID", "PackedVector2Array", "PackedFloat32Array",
}

OBJECT_METHODS = {
    "new", "connect", "disconnect", "emit", "is_connected", "call", "callv",
    "call_deferred", "call_group", "notify_group", "bind", "unbind", "free",
    "duplicate", "get", "set", "get_class", "is_class", "has_method", "has_signal",
    "set_deferred", "notify_deferred", "has_meta", "get_meta", "set_meta",
    "remove_meta", "add_user_signal", "emit_signal", "tr", "tr_n",
    "get_instance_id", "get_script", "set_script", "to_string", "queue_free",
    "get_parent", "get_node", "get_node_or_null", "add_child", "remove_child",
    "is_queued_for_deletion", "property_list_changed_notify",
}

LIFECYCLE = {
    "_ready", "_process", "_physics_process", "_draw", "_input",
    "_unhandled_input", "_unhandled_key_input", "_shortcut_input", "_enter_tree",
    "_exit_tree", "_notification", "_init", "_to_string", "_get", "_set",
    "_get_property_list", "_property_can_revert", "_property_get_revert",
    "_validate_property", "_input_event", "_gui_input", "_tick", "_post_process",
    "_integrate_forces", "_animate", "_can_drop_data", "_drop_data",
    "_get_drag_data", "_make_custom_tooltip", "_get_minimum_size",
    "_get_configuration_warnings", "_has_point", "_structured_text_parser",
    "_accessibility_screen_reader", "_static_body_process",
}

errors: list[str] = []
warnings: list[str] = []


def _merge_range(old: tuple[int, int] | None, new: tuple[int, int]) -> tuple[int, int]:
    if old is None:
        return new
    return (min(old[0], new[0]), max(old[1], new[1]))


def _line_index(text: str):
    starts = [0]
    for match in re.finditer(r"\n", text):
        starts.append(match.end())

    def find(index: int) -> int:
        low, high = 0, len(starts) - 1
        while low < high:
            mid = (low + high + 1) // 2
            if starts[mid] <= index:
                low = mid
            else:
                high = mid - 1
        return low + 1

    return find


def _return_type(node) -> str:
    raw = node.get("return")
    if raw is None:
        element = node.find("return")
        raw = element.get("type", "") if element is not None else ""
    return raw.split("[")[0].strip()


def _param_range(node) -> tuple[int, int]:
    """Rentang argumen dari sebuah <method>/<signal>: (wajib, maksimum)."""
    params = node.findall("param")
    if not params:
        return (0, 0)
    if any((param.get("name") or "") in ("...", "*args", "args...") for param in params):
        return (0, 999)
    required = 0
    for param in params:
        if param.get("default") is None:
            required += 1
        elif (param.get("name") or "").endswith("..."):
            return (required, 999)
    return (required, len(params))


def split_args(text: str, open_index: int) -> list[str] | None:
    """Pisahkan argumen pada tanda kurung yang dibuka di open_index.

    Mengembalikan daftar argumen (tanpa spasi pinggir) atau None bila tanda
    kurung tidak seimbang di dalam berkas.
    """
    out: list[str] = []
    depth = 0
    quote = ""
    start = open_index + 1
    i = start
    n = len(text)
    while i < n:
        ch = text[i]
        if quote:
            if ch == "\\":
                i += 2
                continue
            if ch == quote:
                quote = ""
        elif ch in "\"'":
            quote = ch
        elif ch == "#":
            while i < n and text[i] != "\n":
                i += 1
            continue
        elif ch in "([{":
            depth += 1
        elif ch in ")]}":
            if depth == 0:
                tail = text[start:i].strip()
                if tail:
                    out.append(tail)
                elif out:
                    out.append("")  # koma terakhir
                    out.pop()
                return out
            depth -= 1
        elif ch == "," and depth == 0:
            out.append(text[start:i].strip())
            start = i + 1
        i += 1
    return None


def count_args(text: str, open_index: int) -> int:
    args = split_args(text, open_index)
    if args is None:
        return -1
    return len([arg for arg in args if arg])


def err(message: str) -> None:
    errors.append(message)


def warn(message: str) -> None:
    warnings.append(message)


# ===========================================================================
# Dokumentasi kelas Godot (XML resmi) sebagai basis data API
# ===========================================================================


class ClassDB:
    """Basis data kelas Godot dari doc/classes/*.xml."""

    def __init__(self, dirs: Iterable[Path]):
        self.bases: dict[str, str] = {}
        self.members: dict[str, set[str]] = {}
        self.signals: dict[str, set[str]] = {}
        self.constants: dict[str, set[str]] = {}
        self.globals: set[str] = set()
        self.global_constants: set[str] = set()
        # rentang jumlah argumen: (minimum, maksimum); 999 = variadik
        self.method_args: dict[str, dict[str, tuple[int, int]]] = {}
        self.signal_args: dict[str, dict[str, tuple[int, int]]] = {}
        self.global_args: dict[str, tuple[int, int]] = {}
        self.method_returns: dict[str, dict[str, str]] = {}
        self.method_static: dict[str, set[str]] = {}
        self.global_returns: dict[str, str] = {}
        self.loaded = False
        for directory in dirs:
            if isinstance(directory, ClassDB):
                continue
            self._load_dir(Path(directory))
        self.loaded = bool(self.bases)

    def _load_dir(self, directory: Path) -> None:
        if not directory.is_dir():
            return
        for path in sorted(directory.glob("*.xml")):
            try:
                root = ET.parse(path).getroot()
            except ET.ParseError:
                continue
            name = root.get("name", path.stem)
            if name == "@GlobalScope":
                for node in root.findall("methods/method"):
                    self.globals.add(node.get("name", ""))
                    self.global_args[node.get("name", "")] = _param_range(node)
                    self.global_returns[node.get("name", "")] = _return_type(node)
                for node in root.findall("./constants/constant"):
                    self.global_constants.add(node.get("name", ""))
                continue
            self.bases.setdefault(name, root.get("inherits", ""))
            member_names = set(self.members.get(name, set()))
            for group in ("methods/method", "members/member", "properties/property"):
                for node in root.findall(group):
                    member_names.add(node.get("name", ""))
            self.members[name] = member_names
            arg_table = self.method_args.setdefault(name, {})
            return_table = self.method_returns.setdefault(name, {})
            static_table = self.method_static.setdefault(name, set())
            for node in root.findall("methods/method"):
                method_name = node.get("name", "")
                arg_table[method_name] = _merge_range(arg_table.get(method_name), _param_range(node))
                return_table[method_name] = _return_type(node)
                if node.get("qualifiers") == "static":
                    static_table.add(method_name)
            signal_names = set(self.signals.get(name, set()))
            signal_table = self.signal_args.setdefault(name, {})
            for node in root.findall("signals/signal"):
                signal_names.add(node.get("name", ""))
                signal_table[node.get("name", "")] = _param_range(node)
            self.signals[name] = signal_names
            constant_names = set(self.constants.get(name, set()))
            for node in root.findall("./constants/constant"):
                constant_names.add(node.get("name", ""))
            self.constants[name] = constant_names

    def has_class(self, name: str) -> bool:
        return name in self.bases or name == "@GlobalScope"

    def chain(self, name: str) -> list[str]:
        out: list[str] = []
        seen: set[str] = set()
        current = name
        while current and current not in seen and current in self.bases:
            seen.add(current)
            out.append(current)
            current = self.bases.get(current, "")
        return out

    def has_member(self, klass: str, member: str) -> bool:
        """True bila anggota ada — atau bila tidak dapat dipastikan.

        Basis data hanya memuat kelas yang dipakai proyek. Bila ada kelas dalam
        rantai warisan yang belum terunduh, pemeriksaan dilewati supaya tidak
        memunculkan kesalahan palsu.
        """
        current = klass
        seen: set[str] = set()
        while current and current not in seen:
            seen.add(current)
            if not self.has_class(current):
                return True
            if self.has_member_here(current, member):
                return True
            current = self.bases.get(current, "")
        return False

    def has_member_here(self, klass: str, member: str) -> bool:
        if self.has_class(klass) and member in self.members.get(klass, set()):
            return True
        # dukungan enumerasi: Key.KEY_A, TileSet.TILE_SHAPE_SQUARE, dll.
        for constant in self.constants.get(klass, set()):
            if constant == member:
                return True
        # nilai enumerasi yang ditulis sebagai nama enum (mis. Control.PRESET_FULL_RECT)
        return False

    def has_signal(self, klass: str, signal_name: str) -> bool:
        current = klass
        seen: set[str] = set()
        while current and current not in seen:
            seen.add(current)
            if not self.has_class(current):
                return True
            if signal_name in self.signals.get(current, set()):
                return True
            current = self.bases.get(current, "")
        return False

    def known_type(self, name: str) -> bool:
        return name in GODOT_TYPES or self.has_class(name)

    def arg_range(self, klass: str, method: str) -> tuple[int, int] | None:
        current = klass
        seen: set[str] = set()
        while current and current not in seen:
            seen.add(current)
            if not self.has_class(current):
                return None
            table = self.method_args.get(current, {})
            if method in table:
                return table[method]
            current = self.bases.get(current, "")
        return None

    def method_return(self, klass: str, method: str) -> str:
        current = klass
        seen: set[str] = set()
        while current and current not in seen:
            seen.add(current)
            if not self.has_class(current):
                return ""
            returns = self.method_returns.get(current, {}).get(method, "")
            if returns:
                return returns
            current = self.bases.get(current, "")
        return ""

    def signal_range(self, klass: str, signal_name: str) -> tuple[int, int] | None:
        current = klass
        seen: set[str] = set()
        while current and current not in seen:
            seen.add(current)
            if not self.has_class(current):
                return None
            table = self.signal_args.get(current, {})
            if signal_name in table:
                return table[signal_name]
            current = self.bases.get(current, "")
        return None


# ===========================================================================
# GDScript
# ===========================================================================


class GDScriptFile:
    def __init__(self, path: Path):
        self.path = path
        self.text = path.read_text(encoding="utf-8", errors="replace")
        self.lines = self.text.split("\n")
        self.rel = "res://" + str(path.relative_to(ROOT))
        self.class_name = ""
        self.extends = ""
        self.exports: set[str] = set()
        self.signals: set[str] = set()
        self.res_paths: list[tuple[int, str]] = []
        self.node_gets: list[tuple[int, str]] = []
        self.unique_gets: list[tuple[int, str]] = []
        self.var_types: dict[str, str] = {}
        self.scene_object_vars: dict[str, str] = {}
        self.calls: list[tuple[str, str, int, str]] = []  # (kind, owner, line, name)
        self.this_instance = False
        self.parse_error = ""
        # arity: panggilan (owner, nama, jumlah argumen, baris) dan emit sinyal
        self.arg_calls: list[tuple[str, str, int, int]] = []
        self.func_args: dict[str, tuple[int, int]] = {}
        self.func_returns: dict[str, str] = {}
        self.signal_args: dict[str, tuple[int, int]] = {}
        self._parse()
        self._scan_arity()

    # --- pembersihan baris -------------------------------------------------
    def _code(self, line: str) -> str:
        out = line
        if "#" in out:
            # abaikan '#' di dalam string
            quote = ""
            cut = None
            for i, ch in enumerate(out):
                if quote:
                    if ch == quote:
                        quote = ""
                elif ch in "\"'":
                    quote = ch
                elif ch == "#":
                    cut = i
                    break
            if cut is not None:
                out = out[:cut]
        return out.rstrip()

    def _parse(self) -> None:
        for number, raw in enumerate(self.lines, start=1):
            line = self._code(raw)
            stripped = line.strip()
            if not stripped:
                continue
            prefix = raw[: len(raw) - len(raw.lstrip(" \t"))]
            if "\t" in prefix and " " in prefix:
                err(f"{self.rel}:{number}: indentasi campur tab dan spasi")
            if prefix and "\t" not in prefix and len(prefix) % 4 != 0:
                warn(f"{self.rel}:{number}: indentasi bukan kelipatan 4")
            self._parse_line(stripped, number)
        self._collect_signatures()
        self._check_blocks()

    def _collect_signatures(self) -> None:
        text = self.text
        for match in re.finditer(r"^(?:static\s+)?func\s+([A-Za-z_]\w*)\s*(\()", text, re.M):
            args = split_args(text, match.end() - 1)
            if args is None:
                continue
            header = text[match.end(): text.find(":", match.end()) if text.find(":", match.end()) > 0 else len(text)]
            arrow = re.search(r"->\s*([A-Za-z_]\w*)", header)
            if arrow:
                self.func_returns[match.group(1)] = arrow.group(1)
            required = 0
            variadic = False
            for arg in args:
                if not arg:
                    continue
                if arg.startswith("...") or arg.startswith("*"):
                    variadic = True
                    continue
                if "=" not in arg and ":=" not in arg:
                    required += 1
            maximum = 999 if variadic else len([arg for arg in args if arg and not arg.startswith("...")])
            self.func_args[match.group(1)] = (required, maximum)
        for match in re.finditer(r"^signal\s+([A-Za-z_]\w*)\s*(\(?)", text, re.M):
            name = match.group(1)
            if match.group(2) == "(":
                args = split_args(text, match.end() - 1)
                if args is None:
                    continue
                self.signal_args[name] = (len([arg for arg in args if arg]), len([arg for arg in args if arg]))
            else:
                self.signal_args[name] = (0, 0)

    def _parse_line(self, line: str, number: int) -> None:
        if line.startswith(("signal ", "func ", "enum ", "class_name ", "extends ", "class ")):
            for match in re.finditer(r"\bvar\s+(\w+)\s*:\s*([A-Za-z_][\w\[\]]*)", line):
                self.var_types.setdefault(match.group(1), match.group(2).split("[")[0])
            if line.startswith("signal "):
                for match in re.finditer(r"^signal\s+(\w+)", line):
                    self.signals.add(match.group(1))
            if line.startswith("extends"):
                self.extends = line.split(None, 1)[1].strip().split("(")[0].strip()
            if line.startswith("class_name "):
                self.class_name = line.split()[1].rstrip(":")
            return
        if line.startswith("class_name"):
            self.class_name = line.split()[1].rstrip(":")
        elif line.startswith("extends"):
            self.extends = line.split(None, 1)[1].strip().split("(")[0].strip()
        # kelas proyek dengan huruf kapital awal = deklarasi class_name
        for match in re.finditer(r"class_name\s+(\w+)", line):
            self.class_name = match.group(1)
        for match in re.finditer(r"@export[^\n]*?\bvar\s+(\w+)", line):
            self.exports.add(match.group(1))
        for match in re.finditer(r"^signal\s+(\w+)", line):
            self.signals.add(match.group(1))
        for match in re.finditer(r'(?:preload|load)\(\s*"(res://[^"]+)"', line):
            self.res_paths.append((number, match.group(1)))
        bare = re.sub(r'"[^"]*"', '""', line)
        for match in re.finditer(r'\$"[^"]*"|\$[A-Za-z_][\w/]*|%[A-Za-z_]\w*', bare):
            token = match.group(0)
            if token.startswith("%"):
                self.unique_gets.append((number, token[1:]))
            else:
                self.node_gets.append((number, token.lstrip("$").strip('"')))
        # tipe variabel: var x: Tipe = ...
        for match in re.finditer(r"\bvar\s+(\w+)\s*:\s*([A-Za-z_][\w\[\]]*)", line):
            self.var_types.setdefault(match.group(1), match.group(2).split("[")[0])
        # tipe parameter: func f(a: Tipe, b := ...)
        for match in re.finditer(r"\bfunc\s+\w+\s*\(([^)]*)\)", line):
            for param in match.group(1).split(","):
                parts = param.split(":")
                if len(parts) == 2:
                    name = parts[0].strip().lstrip("*")
                    type_name = parts[1].strip().split("=")[0].strip()
                    if name and re.match(r"^[A-Za-z_]\w*$", name):
                        self.var_types.setdefault(name, type_name.split("[")[0])
        for match in re.finditer(r"\bfor\s+(\w+)\s*:\s*([A-Za-z_]\w*)", line):
            self.var_types.setdefault(match.group(1), match.group(2))
        # panggilan: Pengenal.Sesuatu(...) atau Sesuatu(...)
        for match in re.finditer(r"([A-Za-z_]\w*(?:\.[A-Za-z_]\w*)*)\s*\.\s*([A-Za-z_]\w*)\s*\(", line):
            self.calls.append(("method", match.group(1), number, match.group(2)))
        for match in re.finditer(r"(?<![\w.$])([A-Za-z_]\w*)\s*\(", line):
            self.calls.append(("global", "", number, match.group(1)))
        # akses konstanta / enum: Kelas.NAMA (tanpa tanda kurung)
        for match in re.finditer(r"\b([A-Z]\w+(?:\.\w+)*)\.([A-Z][A-Z0-9_]{2,})\b(?!\s*\()", line):
            self.calls.append(("constant", match.group(1), number, match.group(2)))
        # sinyal: X.sinyal.connect(...) / X.sinyal.emit(...)
        for match in re.finditer(r"([A-Za-z_]\w*(?:\.[A-Za-z_]\w*)*)\.([a-z_]\w*)\.(connect|emit|disconnect)\(", line):
            self.calls.append(("signal", match.group(1), number, match.group(2)))

    def _scan_arity(self) -> None:
        """Kumpulkan jumlah argumen tiap pemanggilan (termasuk yang multi-baris).

        Hanya dipakai untuk pemeriksaan jumlah argumen; panggilan yang pemiliknya
        tidak bisa dipastikan akan dilewati agar tidak ada kesalahan palsu.
        """
        text = self.text
        line_of = _line_index(text)
        self._infer_var_types(text)
        for match in re.finditer(r"((?:self\.|[A-Za-z_]\w*(?:\.[A-Za-z_]\w*)*)\.)([A-Za-z_]\w*)\s*(\()", text):
            owner = match.group(1)[:-1]
            name = match.group(2)
            args = count_args(text, match.end() - 1)
            if args >= 0:
                self.arg_calls.append((owner, name, args, line_of(match.start())))
        for match in re.finditer(r"(?<![\w.$])([A-Za-z_]\w*)\s*(\()", text):
            name = match.group(1)
            if name in ("func", "if", "elif", "while", "for", "match", "return", "and", "or", "not", "in", "await", "assert", "super", "self", "range"):
                continue
            args = count_args(text, match.end() - 1)
            if args >= 0:
                self.arg_calls.append(("", name, args, line_of(match.start())))
        for match in re.finditer(r"((?:self\.|[A-Za-z_]\w*(?:\.[A-Za-z_]\w*)*)\.)?([A-Za-z_]\w*)\.emit\s*(\()", text):
            owner = (match.group(1) or "")[:-1]
            name = match.group(2)
            args = count_args(text, match.end() - 1)
            if args >= 0:
                self.arg_calls.append((("__emit__:" + owner), name, args, line_of(match.start())))

    def _infer_var_types(self, text: str) -> None:
        """Tebak tipe variabel dari `var x := Sesuatu(...)` yang dapat dipastikan.

        Hanya bentuk yang pasti (konstruktor .new(), fungsi global Godot dengan
        tipe kembalian yang terdokumentasi, dan fungsi statis proyek) yang
        dipakai, supaya tidak muncul kesalahan palsu.
        """
        db = CLASS_DB
        for match in re.finditer(r"\bvar\s+([A-Za-z_]\w*)\s*:=\s*([^\n=]+)", text):
            name = match.group(1)
            if name in self.var_types:
                continue
            expr = match.group(2).strip()
            constructor = re.match(r"([A-Za-z_]\w*)\.new\s*\(", expr)
            if constructor:
                type_name = constructor.group(1)
                if type_name != "self" and (type_name in self.func_returns or True):
                    self.var_types.setdefault(name, type_name)
                continue
            static_call = re.match(r"([A-Za-z_]\w*)\.([A-Za-z_]\w*)\s*\(", expr)
            if static_call and db is not None and db.loaded:
                owner, method = static_call.group(1), static_call.group(2)
                returns = db.method_returns.get(owner, {}).get(method, "")
                if returns and method in db.method_static.get(owner, set()) and returns not in ("void", "Variant"):
                    self.var_types.setdefault(name, returns)
                continue
            plain = re.match(r"([A-Za-z_]\w*)\s*\(", expr)
            if plain and db is not None and db.loaded:
                func_name = plain.group(1)
                if func_name in self.func_returns:
                    returns = self.func_returns[func_name]
                    if returns not in ("void", "Variant"):
                        self.var_types.setdefault(name, returns)
                elif func_name in db.global_returns:
                    returns = db.global_returns[func_name]
                    if returns not in ("void", "Variant", "Nil"):
                        self.var_types.setdefault(name, returns)
                elif self.extends:
                    returns = db.method_return(self.extends.split("(")[0].strip(), func_name)
                    if returns and returns not in ("void", "Variant", "Nil"):
                        self.var_types.setdefault(name, returns)

    def _check_blocks(self) -> None:
        depth = 0
        for number, raw in enumerate(self.lines, start=1):
            code = self._code(raw)
            if not code.strip():
                continue
            depth += code.count("(") - code.count(")")
            depth += code.count("[") - code.count("]")
            if depth < 0:
                err(f"{self.rel}:{number}: tanda kurung menutup berlebihan")
                depth = 0
        if depth != 0:
            err(f"{self.rel}: tanda kurung tidak seimbang ({depth:+d})")


def scan_scripts() -> dict[str, GDScriptFile]:
    files: dict[str, GDScriptFile] = {}
    for path in sorted(ROOT.rglob("*.gd")):
        if any(part in SKIP_DIRS for part in path.relative_to(ROOT).parts):
            continue
        script = GDScriptFile(path)
        files[script.rel] = script
    return files


# ===========================================================================
# project.godot
# ===========================================================================


def read_project() -> dict:
    path = ROOT / "project.godot"
    data = {"config_version": 5, "name": ROOT.name, "main_scene": "", "autoloads": {}, "sections": {}}
    if not path.exists():
        err("project.godot tidak ditemukan")
        return data
    section = ""
    for raw in path.read_text(encoding="utf-8").split("\n"):
        line = raw.strip()
        if line.startswith("[") and line.endswith("]"):
            section = line[1:-1]
            data["sections"].setdefault(section, {})
            continue
        if not line or line.startswith(";") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        key, value = key.strip(), value.strip()
        data["sections"].setdefault(section, {})[key] = value
        if section == "application":
            if key == "config/name":
                data["name"] = value.strip('"')
            if key == "run/main_scene":
                data["main_scene"] = value.strip('"')
        elif section == "autoload":
            data["autoloads"][key] = value.strip('"')
    return data


# ===========================================================================
# Scene (.tscn)
# ===========================================================================


class Scene:
    def __init__(self, path: Path):
        self.path = path
        self.rel = "res://" + str(path.relative_to(ROOT))
        self.text = path.read_text(encoding="utf-8", errors="replace")
        self.header = ""
        self.ext_resources: dict[str, dict] = {}
        self.sub_resources: dict[str, str] = {}
        self.nodes: list[dict] = []
        self.parse_error = ""
        self._parse()

    def _parse(self) -> None:
        blocks = re.split(r"\n(?=\[)", self.text)
        for block in blocks:
            lines = [line for line in block.split("\n")]
            if not lines:
                continue
            header = lines[0].strip()
            if header.startswith("[gd_scene"):
                self.header = header
            elif header.startswith("[ext_resource"):
                match = re.search(r'id="([^"]+)"', header)
                type_match = re.search(r'type="([^"]+)"', header)
                path_match = re.search(r'path="([^"]+)"', header)
                if match:
                    self.ext_resources[match.group(1)] = {
                        "type": type_match.group(1) if type_match else "",
                        "path": path_match.group(1) if path_match else "",
                    }
            elif header.startswith("[sub_resource"):
                match = re.search(r'id="([^"]+)"', header)
                type_match = re.search(r'type="([^"]+)"', header)
                if match:
                    self.sub_resources[match.group(1)] = type_match.group(1) if type_match else "Resource"
            elif header.startswith("[node"):
                node: dict = {"props": {}}
                for key in ("name", "type", "parent", "instance", "index"):
                    found = re.search(key + r'="([^"]*)"', header)
                    node[key] = found.group(1) if found else None
                for line in lines[1:]:
                    if "=" not in line:
                        continue
                    key, value = line.split("=", 1)
                    node["props"][key.strip()] = value.strip()
                self.nodes.append(node)
        # pohon node: hitung path lengkap untuk memeriksa nama unik
        by_path: dict[str, dict] = {}
        for node in self.nodes:
            parent = node["parent"]
            parent_path = "" if parent in (None, "") else parent
            full = node["name"] if not parent_path else parent_path + "/" + node["name"]
            key = full if parent_path else node["name"]
            node["path"] = full
            by_path[key] = node
        self.by_path = by_path


def parse_value(db: ClassDB, value: str) -> str:
    """Mengembalikan label tipe untuk sebuah nilai .tscn (aproksimasi)."""
    value = value.strip()
    if value.startswith("ExtResource("):
        return "ExtResource"
    if value.startswith("SubResource("):
        return "SubResource"
    if value.startswith("Object("):
        return "Object"
    if value.startswith("Vector2("):
        return "Vector2"
    if value.startswith("Vector2i("):
        return "Vector2i"
    if value.startswith("Rect2("):
        return "Rect2"
    if value.startswith("Color("):
        return "Color"
    if value.startswith("NodePath("):
        return "NodePath"
    if value.startswith("PackedStringArray("):
        return "PackedStringArray"
    if value.startswith("PackedVector2Array("):
        return "PackedVector2Array"
    if re.match(r"^\[", value) or value.startswith("Array["):
        return "Array"
    if value.startswith("{"):
        return "Dictionary"
    if value in ("true", "false"):
        return "bool"
    if value.startswith('"'):
        return "String"
    if re.match(r"^-?\d+$", value):
        return "int"
    if re.match(r"^-?\d*\.\d+$", value):
        return "float"
    return ""


def check_scene_script(db: ClassDB, scene: Scene, script: GDScriptFile | None, class_db: dict) -> None:
    if script is None:
        return
    root = next((node for node in scene.nodes if node["parent"] in (None, "")), None)
    if root is None:
        return
    root_type = root["type"] or ""
    if not root_type and root["instance"]:
        return
    base = script.extends.split("[")[0].strip()
    resolved = class_db.get(base, base)
    if not root_type or not db.has_class(root_type):
        return
    if resolved and db.has_class(resolved) and not db.is_a(root_type, resolved):
        err(
            f"{scene.rel}: akar node '{root_type}' bukan turunan dari '{resolved}' "
            f"(skrip {script.rel} extends {base})"
        )


def _project_range(klass: str, name: str, scripts: dict, class_index: dict) -> tuple[int, int] | None:
    """Rentang argumen fungsi/sinyal milik kelas skrip proyek (termasuk warisan)."""
    seen: set[str] = set()
    current = klass
    while current and current not in seen:
        seen.add(current)
        rel = class_index.get(current)
        if rel is None:
            return None
        script = scripts.get(rel)
        if script is None:
            return None
        if name in script.func_args:
            return script.func_args[name]
        if name in script.signal_args:
            return script.signal_args[name]
        current = script.extends.split("(")[0].strip()
    return None


def _autoload_range(rel: str, name: str, scripts: dict, class_index: dict) -> tuple[int, int] | None:
    script = scripts.get(rel)
    if script is None:
        return None
    if name in script.func_args:
        return script.func_args[name]
    if name in script.signal_args:
        return script.signal_args[name]
    if script.class_name:
        return _project_range(script.class_name, name, scripts, class_index)
    return None


def check_arity(script: GDScriptFile, scripts: dict, project: dict, class_index: dict) -> None:
    """Periksa jumlah argumen pemanggilan fungsi dan emit sinyal.

    Hanya diperiksa bila fungsi/sinyal bisa dipastikan asalnya (kelas Godot,
    kelas skrip proyek, atau autoload). Selain itu dilewati.
    """
    db = CLASS_DB
    if db is None:
        return
    if not db.loaded:
        return
    autoload_index = {name: path.replace("*", "") for name, path in project["autoloads"].items()}
    var_types = dict(script.var_types)
    var_types.setdefault("self", script.class_name)
    skip_names = {"call", "call_deferred", "callv", "emit_signal", "connect", "disconnect", "get", "set", "has", "append", "size", "keys", "values", "duplicate", "erase", "bind", "is_connected", "has_method", "has_signal", "is_instance_valid", "free", "queue_free"}

    def resolve(owner: str) -> tuple[str, str]:
        """-> (jenis, nama) dengan jenis: project | autoload | engine | """""
        head = owner.split(".")[0]
        if head in autoload_index:
            return ("autoload", autoload_index[head])
        if head in class_index:
            return ("project", head)
        if head in var_types and var_types[head]:
            type_name = var_types[head]
            if type_name in class_index:
                return ("project", type_name)
            return ("engine", type_name)
        if head and head[0].isupper() and db.has_class(head):
            return ("engine", head)
        return ("", "")

    reported: set[tuple] = set()
    for raw_owner, name, count, number in script.arg_calls:
        is_emit = False
        owner = raw_owner
        if owner.startswith("__emit__:"):
            is_emit = True
            owner = owner[len("__emit__:"):]
        if name in skip_names and not is_emit:
            continue
        kind, target = resolve(owner)
        if not kind:
            continue
        where = f"{script.rel}:{number}"
        if is_emit:
            if kind == "autoload":
                rng = _autoload_range(target, name, scripts, class_index)
            elif kind == "project":
                rng = _project_range(target, name, scripts, class_index)
            else:
                rng = db.signal_range(target, name)
            if rng is None:
                continue
            low, high = rng
            if low <= count <= high:
                continue
            key = (where, name, count)
            if key in reported:
                continue
            reported.add(key)
            err(f"{where}: '{owner + '.' if owner else ''}{name}.emit()' memakai {count} argumen, seharusnya {low}" + (f"-{high}" if high != low else ""))
            continue
        if kind == "autoload":
            rng = _autoload_range(target, name, scripts, class_index)
        elif kind == "project":
            rng = _project_range(target, name, scripts, class_index)
        else:
            rng = db.arg_range(target, name)
        if rng is None:
            continue
        low, high = rng
        if low <= count <= high:
            continue
        key = (where, name, count)
        if key in reported:
            continue
        reported.add(key)
        label = f"{owner}.{name}()" if owner else f"{name}()"
        err(f"{where}: '{label}' dipanggil dengan {count} argumen, seharusnya {low}" + (f"-{high}" if high != low else ""))


CONNECT_RE = re.compile(r"((?:self\.)?[A-Za-z_]\w*(?:\.[A-Za-z_]\w*)*)\.([A-Za-z_]\w*)\s*\.\s*connect\s*(\()")


def _count_bound(text: str) -> int:
    """Jumlah argumen pada .bind(...) di dalam teks callable."""
    total = 0
    for match in re.finditer(r"\.bind\s*(\()", text):
        count = count_args(text, match.end() - 1)
        if count >= 0:
            total += count
    for match in re.finditer(r"\.unbind\s*(\()", text):
        count = count_args(text, match.end() - 1)
        if count > 0:
            total -= count
    return total


def check_connects(script: GDScriptFile, scripts: dict, project: dict, class_index: dict) -> None:
    """Jumlah argumen sinyal harus cocok dengan fungsi yang disambung.

    Godot menolak `connect` bila jumlah argumen tidak cocok, jadi kesalahan ini
    lebih baik ditemukan sebelum game dijalankan.
    """
    db = CLASS_DB
    if db is None or not db.loaded:
        return
    autoload_index = {name: path.replace("*", "") for name, path in project["autoloads"].items()}
    var_types = dict(script.var_types)
    if script.class_name:
        var_types.setdefault("self", script.class_name)
    text = script.text
    line_of = _line_index(text)

    def signal_arity(owner: str, name: str) -> tuple[int, int] | None:
        head = owner.split(".")[0]
        if head == "self" and script.class_name:
            return _project_range(script.class_name, name, scripts, class_index) or None
        if head in autoload_index:
            return _autoload_range(autoload_index[head], name, scripts, class_index)
        if head in class_index:
            return _project_range(head, name, scripts, class_index)
        if head in var_types and var_types[head]:
            type_name = var_types[head]
            if type_name in class_index:
                return _project_range(type_name, name, scripts, class_index)
            return db.signal_range(type_name, name)
        if head and head[0].isupper() and db.has_class(head):
            return db.signal_range(head, name)
        return None

    def callable_arity(expression: str) -> tuple[int, int] | None:
        base = expression.split(".bind")[0].split(".unbind")[0].strip()
        if base.startswith("self."):
            base = base[len("self."):]
        if not re.match(r"^[A-Za-z_]\w*$", base):
            return None
        if script.class_name:
            found = _project_range(script.class_name, base, scripts, class_index)
            if found is not None:
                return found
        if script.extends:
            found = db.arg_range(script.extends.split("(")[0].strip(), base)
            if found is not None:
                return found
        return None

    for match in CONNECT_RE.finditer(text):
        owner = match.group(1)
        name = match.group(2)
        args = split_args(text, match.end() - 1)
        if not args or not args[0]:
            continue
        target = args[0]
        if target.startswith("Callable(") or target.startswith("func "):
            continue
        arity = signal_arity(owner, name)
        if arity is None:
            continue
        (low, high) = arity
        if high == 999:
            continue
        called = callable_arity(target)
        if called is None:
            continue
        bound = _count_bound(target)
        total = high + bound
        cmin, cmax = called
        if cmin <= total <= cmax:
            continue
        err(
            f"{script.rel}:{line_of(match.start())}: sinyal '{owner}.{name}' ({low}-{high} argumen) "
            f"disambung ke '{target.split('.bind')[0].strip()}' yang menerima {cmin}" + (f"-{cmax}" if cmax != cmin else "") + " argumen"
        )


def check_local_declarations(script: GDScriptFile) -> None:
    """Cari deklarasi ganda yang benar-benar salah.

    GDScript memberi setiap blok (isi if/else/match/for) scopnya sendiri, jadi
    `var x` di dua cabang berbeda itu sah. Yang salah adalah dua `var x` pada
    blok yang sama, atau dua fungsi dengan nama sama.
    """
    funcs: dict[str, int] = {}
    current = ""
    scopes: list[tuple[int, int]] = []  # (indentasi, id scope)
    next_scope = 0
    declared: dict[tuple[str, int], tuple[int, str]] = {}
    for number, raw in enumerate(script.lines, start=1):
        code = script._code(raw).strip()
        if not code:
            continue
        signature = re.match(r"^(?:static\s+)?func\s+([A-Za-z_]\w*)\s*\(", code)
        if signature:
            name = signature.group(1)
            if name in funcs:
                err(f"{script.rel}:{number}: fungsi '{name}()' dideklarasikan dua kali (baris {funcs[name]})")
            funcs[name] = number
            current = name
            scopes = []
            next_scope = 0
            continue
        if not current:
            continue
        indent = len(raw) - len(raw.lstrip(" \t"))
        while scopes and scopes[-1][0] > indent:
            scopes.pop()
        if not scopes or scopes[-1][0] < indent:
            next_scope += 1
            scopes.append((indent, next_scope))
        scope = "%s#%d" % (current, scopes[-1][1])
        declaration = re.match(r"^var\s+([A-Za-z_]\w*)", code)
        if declaration:
            local = declaration.group(1)
            if (scope, local) in declared:
                err(
                    f"{script.rel}:{number}: variabel '{local}' dideklarasikan dua kali pada blok yang sama "
                    f"(baris {declared[(scope, local)][0]})"
                )
            else:
                declared[(scope, local)] = (number, current)


def _script_native_base(scripts: dict, class_db: dict, script, seen: set | None = None) -> str:
    """Tipe Godot paling dasar yang diwarisi sebuah skrip proyek."""
    base = script.extends.split("(")[0].strip()
    guard = seen if seen is not None else set()
    while base in class_db and base not in guard:
        guard.add(base)
        target = scripts.get(class_db[base])
        if target is None:
            return ""
        base = target.extends.split("(")[0].strip()
    return base


def check_scenes(db: ClassDB, scenes: dict[str, Scene], scripts: dict[str, GDScriptFile]) -> None:
    class_db = {s.class_name: s.rel for s in scripts.values() if s.class_name}
    for scene in scenes.values():
        if scene.header and "format=3" not in scene.header:
            err(f"{scene.rel}: header gd_scene tidak memakai format=3")
        if not scene.header:
            err(f"{scene.rel}: header [gd_scene ...] tidak ditemukan")
        for rid, res in scene.ext_resources.items():
            res_path = res.get("path", "")
            if not res_path.startswith("res://"):
                err(f"{scene.rel}: ext_resource {rid} tanpa path res://")
                continue
            target = ROOT / res_path.replace("res://", "", 1)
            if not target.exists():
                err(f"{scene.rel}: ext_resource {rid} menunjuk berkas yang tidak ada: {res_path}")
        for node in scene.nodes:
            name = node["name"] or ""
            if not name:
                err(f"{scene.rel}: node tanpa nama")
            if not re.match(r"^[A-Za-z_][A-Za-z0-9_]*$", name):
                err(f"{scene.rel}: nama node tidak valid: {name}")
            node_type = node["type"] or ""
            if node_type and not db.has_class(node_type) and node_type not in class_db:
                err(f"{scene.rel}: tipe node tidak dikenal: {node_type} ({name})")
            script_path = ""
            raw_script = node["props"].get("script", "")
            match = re.match(r'ExtResource\("([^"]+)"\)', raw_script)
            if match:
                res = scene.ext_resources.get(match.group(1), {})
                if res.get("type") != "Script":
                    err(f"{scene.rel}: {name}.script bukan ExtResource bertipe Script")
                script_path = res.get("path", "")
            if not node_type and node["instance"]:
                inner = scene.ext_resources.get(node["instance"].split('"')[1], {}).get("path", "")
                inner_scene = scenes.get(inner)
                if inner_scene is not None and inner_scene.nodes:
                    node_type = inner_scene.nodes[0]["type"] or ""
            if node_type and node_type in class_db:
                node_type = class_db.get(node_type, node_type)
            if script_path and script_path in scripts and node_type and db.has_class(node_type):
                base = _script_native_base(scripts, class_db, scripts[script_path])
                if base and db.has_class(base) and base not in db.chain(node_type):
                    err(
                        f"{scene.rel}: {name} bertipe {node_type} tetapi skrip {script_path} "
                        f"mewarisi {base}"
                    )
            exports: set[str] = set()
            if script_path and script_path in scripts:
                exports = scripts[script_path].exports
                if node["parent"] in (None, ""):
                    check_scene_script(db, scene, scripts[script_path], class_db)
            elif script_path and script_path.endswith(".gd"):
                err(f"{scene.rel}: skrip {script_path} tidak ditemukan di proyek")
            for key, value in node["props"].items():
                if LAYOUT_PROPS.match(key):
                    continue
                value_type = parse_value(db, value)
                if value_type == "ExtResource":
                    if value.replace("ExtResource(", "").strip('")') not in scene.ext_resources:
                        err(f"{scene.rel}: {name}.{key} memakai ExtResource yang tidak ada")
                    continue
                if value_type == "SubResource":
                    if value.replace("SubResource(", "").strip('")') not in scene.sub_resources:
                        err(f"{scene.rel}: {name}.{key} memakai SubResource yang tidak ada")
                    continue
                if value_type == "Object":
                    check_object_value(db, f"{scene.rel}: {name}.{key}", value)
                    continue
                if key in exports:
                    continue
                if node_type and db.has_class(node_type):
                    if not db.has_member(node_type, key):
                        err(f"{scene.rel}: {name} ({node_type}) tidak punya properti '{key}'")
        # nama unik pemilik untuk %Name
        check_unique_names(scene)


def check_unique_names(scene: Scene) -> None:
    for node in scene.nodes:
        flag = node["props"].get("unique_name_in_owner", "")
        if flag == "true" and node["parent"] not in (None, ""):
            pass  # ok


def check_object_value(db: ClassDB, where: str, value: str) -> None:
    match = re.match(r"Object\((\w+)", value)
    if not match:
        return
    klass = match.group(1)
    if not db.has_class(klass):
        err(f"{where}: Object({klass}) bukan kelas Godot yang dikenal")
        return
    for prop, raw in re.findall(r'"([a-z_0-9]+)":([^,)]+)', value):
        if not db.has_member(klass, prop):
            err(f"{where}: Object({klass}) tidak punya properti '{prop}'")


# ===========================================================================
# Data (JSON)
# ===========================================================================


def check_data() -> dict:
    data: dict = {"dialogue": {}, "quests": {}, "items": {}, "notes": {}}
    quests_path = ROOT / "data" / "quests" / "quests.json"
    if quests_path.exists():
        try:
            data["quests"] = json.loads(quests_path.read_text(encoding="utf-8"))
        except json.JSONDecodeError as exc:
            err(f"data/quests/quests.json: JSON tidak valid ({exc})")
    items_path = ROOT / "data" / "items" / "items.json"
    if items_path.exists():
        try:
            data["items"] = json.loads(items_path.read_text(encoding="utf-8"))
        except json.JSONDecodeError as exc:
            err(f"data/items/items.json: JSON tidak valid ({exc})")
    notes_path = ROOT / "data" / "notes" / "cultural_notes.json"
    if notes_path.exists():
        try:
            data["notes"] = json.loads(notes_path.read_text(encoding="utf-8"))
        except json.JSONDecodeError as exc:
            err(f"data/notes/cultural_notes.json: JSON tidak valid ({exc})")
    notes_path = ROOT / "data" / "notes" / "cultural_notes.json"
    if notes_path.exists():
        try:
            data["notes"] = json.loads(notes_path.read_text(encoding="utf-8"))
        except json.JSONDecodeError as exc:
            err(f"data/notes/cultural_notes.json: JSON tidak valid ({exc})")
    dialogue_dir = ROOT / "data" / "dialogue"
    for path in sorted(dialogue_dir.glob("*.json")):
        rel = "res://" + str(path.relative_to(ROOT))
        try:
            parsed = json.loads(path.read_text(encoding="utf-8"))
        except json.JSONDecodeError as exc:
            err(f"{rel}: JSON tidak valid ({exc})")
            continue
        for dialogue_id, entry in parsed.items():
            if dialogue_id in data["dialogue"]:
                err(f"{rel}: id dialog ganda: {dialogue_id}")
            data["dialogue"][dialogue_id] = entry
            nodes = entry.get("nodes", [])
            if not nodes:
                err(f"{rel}: dialog '{dialogue_id}' tidak punya node")
            for node in nodes:
                where = f"{rel}: dialog '{dialogue_id}'/{node.get('id')}"
                if not node.get("id"):
                    warn(f"{where}: node tanpa id")
                lines = node.get("lines", [])
                if not lines:
                    err(f"{where}: node tanpa baris")
                for line in lines:
                    if not str(line.get("text", "")).strip():
                        err(f"{where}: baris tanpa teks")
                    if "speaker" not in line and not line.get("narration"):
                        err(f"{where}: baris tanpa speaker/narration")
                check_effects(f"{rel}: {dialogue_id}/{node.get('id')}", node.get("effects", {}), data)
    for quest_id, quest in data["quests"].items():
        for objective in quest.get("objectives", []):
            item_id = objective.get("item", "")
            if item_id and item_id not in data["items"]:
                err(f"quest '{quest_id}'/{objective.get('id')}: item '{item_id}' tidak ada di items.json")
    return data


def check_effects(where: str, effects: dict, data: dict) -> None:
    if not effects:
        return
    for item_id in effects.get("give_items", []) + effects.get("remove_items", []):
        if item_id not in data.get("items", {}):
            warn(f"{where}: efek memakai item '{item_id}' yang tidak dikenal")
    for quest_id in (
        ([effects["start_quest"]] if "start_quest" in effects else [])
        + list(effects.get("start_quests", []))
        + list(effects.get("complete_quests", []))
        + ([effects["complete_quest"]] if "complete_quest" in effects else [])
    ):
        if quest_id and quest_id not in data.get("quests", {}):
            warn(f"{where}: efek memakai quest '{quest_id}' yang tidak dikenal")
    for note_id in ([effects["note"]] if "note" in effects else []):
        if note_id and note_id not in data.get("notes", {}):
            warn(f"{where}: efek memakai catatan '{note_id}' yang tidak dikenal")
    for entry in effects.get("complete_objectives", []):
        quest = data.get("quests", {}).get(entry.get("quest", ""), {})
        ids = [objective.get("id") for objective in quest.get("objectives", [])]
        if quest and entry.get("objective") not in ids:
            warn(f"{where}: objective '{entry.get('objective')}' tidak ada di quest '{entry.get('quest')}'")


# ===========================================================================
# Pemeriksaan API GDScript
# ===========================================================================


def build_class_index(scripts: dict[str, GDScriptFile], project: dict) -> dict[str, str]:
    """nama kelas -> res://… untuk class_name dan autoload."""
    index: dict[str, str] = {}
    for rel, script in scripts.items():
        if script.class_name:
            if script.class_name in index:
                err(f"class_name ganda: {script.class_name} dipakai {index[script.class_name]} dan {rel}")
            index[script.class_name] = rel
    for name, path in project["autoloads"].items():
        clean = path.replace("*", "")
        if clean.startswith("res://"):
            index.setdefault(name, clean)
    return index


def check_script_basics(script: GDScriptFile, scripts: dict, project: dict, class_index: dict) -> None:
    # berkas res:// yang di-preload
    for number, res_path in script.res_paths:
        if not res_path.startswith("res://"):
            continue
        target = ROOT / res_path.replace("res://", "", 1)
        if not target.exists():
            err(f"{script.rel}:{number}: preload res:// yang tidak ada: {res_path}")
    if script.extends:
        base = script.extends.split("[")[0].strip()
        if base and not base.startswith(("res://", '"')):
            if base not in class_index and not _api_has(base):
                err(f"{script.rel}: extends '{base}' tidak dikenal")
    if not script.extends:
        warn(f"{script.rel}: tidak ada 'extends' eksplisit")


def _api_has(name: str) -> bool:
    return CLASS_DB is not None and CLASS_DB.has_class(name)


def check_script_api(script: GDScriptFile, scripts: dict, project: dict, class_index: dict) -> None:
    db = CLASS_DB
    if db is None:
        return
    autoload_index = {name: path.replace("*", "") for name, path in project["autoloads"].items()}
    own_rel = script.rel
    var_types = dict(script.var_types)
    for name, path in autoload_index.items():
        target = scripts.get(path)
        var_types.setdefault(name, target.class_name if target and target.class_name else "")
    seen: set[tuple] = set()
    for kind, owner, number, name in script.calls:
        key = (kind, owner, name, number)
        if key in seen:
            continue
        seen.add(key)
        where = f"{script.rel}:{number}"
        if kind == "global":
            if name in KEYWORDS or name in BUILTIN_CALLS or name in GODOT_TYPES:
                continue
            # varian tipe: maxf(), clampi(), roundf() …
            if name[-1] in "fi" and name[:-1] in BUILTIN_CALLS | db.globals:
                continue
            # metode tanpa "self." di dalam kelas turunan CanvasItem/Node, dsb.
            if _script_has_method(script, name, scripts, class_index):
                continue
            if _inherited_member(db, script, name, scripts, class_index):
                continue
            # panggilan fungsi yang didefinisikan di berkas ini
            if re.search(r"^\s*(static\s+)?func\s+" + re.escape(name) + r"\b", script.text, re.M):
                continue
            if name in var_types:
                continue
            if re.search(r"\bfunc\s+" + re.escape(name) + r"\s*\(", script.text):
                continue
            if db.globals and name in db.globals:
                continue
            if name in LIFECYCLE:
                continue
            if name in ("abs", "is_nan", "is_inf"):
                continue
            err(f"{where}: fungsi '{name}()' tidak dikenal")
            continue
        if kind == "constant":
            root = owner.split(".")[0]
            if root in autoload_index:
                target = scripts.get(autoload_index[root])
                if target is not None and name in {c for c in target.exports}:
                    continue
                # konstanta skrip autoload
                if target is not None and re.search(r"^\s*const\s+" + re.escape(name) + r"\b", target.text, re.M):
                    continue
                if name.isupper() and target is not None:
                    # konstanta pada autoload
                    if f"const {name}" in target.text or f"{name} :=" in target.text:
                        continue
                continue
            if owner in class_index:
                target = scripts.get(class_index[owner])
                if target is not None:
                    if re.search(r"^\s*const\s+" + re.escape(name) + r"\b", target.text, re.M):
                        continue
                    if name in target.exports or re.search(r"^\s*enum\s+" + re.escape(name), target.text, re.M):
                        continue
                    continue
            if "." in owner:
                continue
            if not db.has_class(owner):
                continue
            if not db.has_member_here(owner, name):
                err(f"{where}: {owner}.{name} tidak ada di dokumentasi kelas {owner}")
            continue
        if kind == "signal":
            root = owner.split(".")[0]
            type_name = var_types.get(root, "")
            if not type_name:
                continue
            if type_name in class_index:
                target = scripts.get(class_index[type_name])
                if target is not None and name in target.signals:
                    continue
                continue
            if db.has_class(type_name) and not db.has_signal(type_name, name):
                err(f"{where}: {type_name} tidak punya sinyal '{name}'")
            continue
        # kind == "method"
        parts = owner.split(".")
        root = parts[0]
        type_name = var_types.get(root, "")
        if root in class_index and len(parts) == 1:
            target = scripts.get(class_index[root])
            if target is not None and name not in OBJECT_METHODS:
                if not _script_has_method(target, name, scripts, class_index):
                    warn(f"{where}: '{root}.{name}()' tidak ditemukan di {target.rel}")
            continue
        if root in class_index and len(parts) > 1:
            # Palette.GRASS_DARK.darkened(), GameManager.audio.play_sfx(), …
            script_of = scripts.get(class_index[root])
            resolved = _resolve_member_chain(db, script_of, parts[1:], scripts, class_index, where)
            if resolved == "":
                continue
            if resolved is None:
                continue
            if name in OBJECT_METHODS:
                continue
            if db.has_class(resolved) and not db.has_member(resolved, name):
                err(f"{where}: '{name}()' tidak ada pada {resolved}")
            elif resolved in class_index:
                target = scripts.get(class_index[resolved])
                if target is not None and not _script_has_method(target, name, scripts, class_index):
                    base = target.extends.split("[")[0].strip()
                    if not (db.has_class(base) and db.has_member(base, name)):
                        warn(f"{where}: '{resolved}.{name}()' tidak ditemukan di {target.rel}")
            continue
        if type_name and type_name in class_index:
            target = scripts.get(class_index[type_name])
            if target is None or name in OBJECT_METHODS:
                continue
            if len(parts) > 1:
                # mis. icon.position.lerp() — telusuri sisa rantai dari tipe variabel
                resolved = _resolve_member_chain(db, target, parts[1:], scripts, class_index, where)
                if not resolved:
                    continue
                if db.has_class(resolved) and db.has_member(resolved, name):
                    continue
                if db.has_class(resolved):
                    err(f"{where}: '{name}()' tidak ada pada {resolved}")
                continue
            if not _script_has_method(target, name, scripts, class_index):
                base = target.extends.split("[")[0].strip()
                if not (db.has_class(base) and db.has_member(base, name)):
                    if name not in LIFECYCLE:
                        warn(f"{where}: '{type_name}.{name}()' tidak ditemukan di {target.rel}")
            continue
        if type_name in ("", "Variant", "NodePath", "StringName"):
            continue
        if db.has_class(type_name):
            if name in OBJECT_METHODS:
                continue
            if not db.has_member(type_name, name):
                err(f"{where}: '{name}()' tidak ada pada {type_name}")


def _resolve_member_chain(db, script, segments, scripts, class_index, where) -> str | None:
    """Menelusuri A.B.C pada satu kelas proyek.

    Mengembalikan nama tipe akhir (kelas engine atau kelas proyek), "" bila
    tidak dapat dipastikan, atau None bila anggota tidak ditemukan.
    """
    current = script
    for index, segment in enumerate(segments):
        if current is None:
            return ""
        kind, type_name = _script_member_type(current, segment)
        if kind == "":
            base = current.extends.split("[")[0].strip()
            resolved_base = class_index.get(base, base)
            if db.has_member(resolved_base, segment):
                return ""
            if not db.has_class(resolved_base):
                return ""
            err(f"{where}: '{segment}' tidak ada di {current.rel}")
            return None
        last = index == len(segments) - 1
        if kind == "enum":
            return ""
        if kind in ("func", "signal"):
            return "" if last else ""
        if not type_name:
            return ""
        resolved = type_name
        if resolved in class_index:
            if last:
                return resolved
            current = scripts.get(class_index[resolved])
            continue
        if db.has_class(resolved):
            return resolved if last else ""
        return ""
    return ""


def _script_member_type(script, name: str) -> tuple[str, str]:
    """Jenis anggota skrip: const/var/func/signal/enum dan tipe nilainya."""
    for match in re.finditer(
        r"^\s*const\s+" + re.escape(name) + r"\s*(?::\s*([A-Za-z_]\w*))?\s*:?=\s*([A-Za-z_]\w*)\(",
        script.text,
        re.M,
    ):
        return ("const", match.group(1) or match.group(2))
    for match in re.finditer(
        r"^\s*const\s+" + re.escape(name) + r"\s*:\s*([A-Za-z_]\w*)", script.text, re.M
    ):
        return ("const", match.group(1))
    if re.search(r"^\s*const\s+" + re.escape(name) + r"\b", script.text, re.M):
        return ("const", "")
    for match in re.finditer(
        r"^\s*(?:@\w+\s+)*var\s+" + re.escape(name) + r"\s*:\s*([A-Za-z_]\w*)", script.text, re.M
    ):
        return ("var", match.group(1))
    for match in re.finditer(r"^\s*(?:@\w+\s+)*var\s+" + re.escape(name) + r"\s*:=", script.text, re.M):
        return ("var", "")
    if re.search(r"^\s*(?:static\s+)?func\s+" + re.escape(name) + r"\s*\(", script.text, re.M):
        return ("func", "")
    if re.search(r"^\s*signal\s+" + re.escape(name) + r"\b", script.text, re.M):
        return ("signal", "")
    if re.search(r"^\s*enum\s+" + re.escape(name) + r"\b", script.text, re.M):
        return ("enum", "")
    return ("", "")


def _script_has_method(script: GDScriptFile, name: str, scripts: dict, class_index: dict, depth: int = 0) -> bool:
    if depth > 6:
        return True
    if re.search(r"^\s*(static\s+)?func\s+" + re.escape(name) + r"\s*\(", script.text, re.M):
        return True
    if re.search(r"^\s*var\s+" + re.escape(name) + r"\b", script.text, re.M):
        return True
    if re.search(r"\bconst\s+" + re.escape(name) + r"\b", script.text):
        return True
    base = script.extends.split("[")[0].strip()
    if base in class_index:
        target = scripts.get(class_index[base])
        if target is not None:
            return _script_has_method(target, name, scripts, class_index, depth + 1)
    return False


def _inherited_member(db: ClassDB, script: GDScriptFile, name: str, scripts: dict, class_index: dict, depth: int = 0) -> bool:
    """Mencari anggota kelas pada rantai extends, termasuk kelas engine."""
    if depth > 8:
        return True
    base = script.extends.split("[")[0].strip()
    if not base:
        return False
    if base in class_index:
        target = scripts.get(class_index[base])
        if target is not None:
            if name in target.signals or name in target.var_types:
                return True
            if re.search(r"\b(?:func|var|const|signal)\s+" + re.escape(name) + r"\b", target.text):
                return True
            return _inherited_member(db, target, name, scripts, class_index, depth + 1)
        return False
    if db.has_class(base):
        return db.has_member(base, name)
    return False


def check_scene_paths(scripts: dict[str, GDScriptFile], scenes: dict[str, Scene], project: dict) -> None:
    """$Node dan %Unik yang dipakai skrip harus ada di scene miliknya."""
    scene_for_script: dict[str, Scene] = {}
    for scene in scenes.values():
        for rid, res in scene.ext_resources.items():
            if res.get("type") == "Script":
                scene_for_script.setdefault(res.get("path", ""), scene)
    for rel, script in scripts.items():
        scene = scene_for_script.get(rel)
        if scene is None:
            if script.node_gets:
                continue
            continue
        names = {
            node["name"]
            for node in scene.nodes
            if node["parent"] not in (None, "")
        }
        unique = {
            node["name"]
            for node in scene.nodes
            if node["props"].get("unique_name_in_owner") == "true"
        }
        instance_roots = {node["name"] for node in scene.nodes if node["instance"]}
        # skrip yang di-instance di dalam scene ini memakai nama dari scene asal
        for node in scene.nodes:
            if not node["instance"]:
                continue
            res = scene.ext_resources.get(node["instance"].strip('")').replace("ExtResource(", ""), {})
            inner = scenes.get(res.get("path", ""))
            if inner is not None:
                names |= {n["name"] for n in inner.nodes if n["parent"] not in (None, "")}
                unique |= {n["name"] for n in inner.nodes if n["props"].get("unique_name_in_owner") == "true"}
        for number, path in script.node_gets:
            first = path.split("/")[0].split(".")[0]
            if first not in names and first not in instance_roots:
                warn(f"{script.rel}:{number}: '{path}' tidak ditemukan di {scene.rel}")
        for number, name in script.unique_gets:
            if name not in unique:
                err(f"{script.rel}:{number}: '%{name}' tidak ada di {scene.rel}")


# ===========================================================================
# Rujukan silang data <-> skrip/scene
# ===========================================================================


def check_cross_references(scripts: dict, scenes: dict, data: dict) -> None:
    dialogue_ids = set(data["dialogue"].keys())
    for rel, script in scripts.items():
        used = set(re.findall(r'"(?:dialogue_id|dialogue)\s*[:=]\s*"([a-z0-9_]+)"', script.text))
        used |= set(re.findall(r'DialogueManager\.start\("([a-z0-9_]+)"\)', script.text))
        for dialogue_id in used:
            if dialogue_id not in dialogue_ids and dialogue_id not in ("dynamic",):
                warn(f"{rel}: dialog '{dialogue_id}' tidak ada di data/dialogue")
    for rel, script in scripts.items():
        for quest_id in set(re.findall(r'"(q_[a-z_]+)"', script.text)):
            if quest_id not in data["quests"]:
                warn(f"{rel}: quest '{quest_id}' tidak ada di quests.json")
        for flag in re.findall(r'(?:set_flag|has_flag|get_flag|clear_flag)\(\s*"([a-z_0-9]+)"', script.text):
            pass
    characters = palette_characters()
    kinds = prop_kinds()
    references = [
        ("dialogue_id", dialogue_ids, "data/dialogue"),
        ("note_id", set(data["notes"].keys()), "data/notes/cultural_notes.json"),
        ("item_id", set(data["items"].keys()), "data/items/items.json"),
        ("quest_id", set(data["quests"].keys()), "data/quests/quests.json"),
        ("objective_id", None, "quests.json"),
        ("palette_id", characters, "Palette.gd"),
        ("kind", kinds, "Prop.gd (DEFAULT_SIZES)"),
    ]
    for scene in scenes.values():
        for node in scene.nodes:
            for key, allowed, label in references:
                if allowed is None:
                    continue
                value = str(node["props"].get(key, "")).strip('"')
                if value and value not in allowed:
                    err(f"{scene.rel}: {node['name']}.{key} = '{value}' tidak ada di {label}")


def palette_characters() -> set:
    """Id karakter yang tersedia di Palette.CHARACTERS."""
    path = ROOT / "scripts" / "util" / "Palette.gd"
    if not path.exists():
        return set()
    text = path.read_text(encoding="utf-8", errors="replace")
    start = text.find("const CHARACTERS")
    if start < 0:
        return set()
    block = text[start:]
    end = block.find("\n}")
    return set(re.findall(r'^\s*"([a-z_0-9]+)"\s*:', block[: end if end > 0 else len(block)], re.M))


def prop_kinds() -> set:
    """Jenis prop yang digambar Prop.gd."""
    path = ROOT / "scripts" / "world" / "Prop.gd"
    if not path.exists():
        return set()
    text = path.read_text(encoding="utf-8", errors="replace")
    start = text.find("const DEFAULT_SIZES")
    if start < 0:
        return set()
    block = text[start:]
    end = block.find("\n}")
    return set(re.findall(r'^\s*"([a-z_0-9]+)"\s*:', block[: end if end > 0 else len(block)], re.M))


# ===========================================================================
# Berkas wajib
# ===========================================================================

REQUIRED_DIRS = [
    "autoload",
    "data/dialogue", "data/quests", "data/items", "data/notes",
    "scenes/main", "scenes/player", "scenes/npc", "scenes/world", "scenes/ui",
    "scenes/puzzle", "scenes/ending",
    # DialogueManager dan SaveManager tinggal di autoload/ (lihat REQUIRED_AUTOLOADS),
    # jadi tidak ada folder scripts/dialogue maupun scripts/save.
    "scripts/player", "scripts/npc", "scripts/world", "scripts/ui", "scripts/puzzle",
    "scripts/quest", "scripts/inventory", "scripts/ending", "scripts/main",
    "scripts/managers", "scripts/util",
    "assets/characters", "assets/environment", "assets/ui", "assets/audio", "assets/fonts",
]

REQUIRED_FILES = [
    "project.godot",
    "README.md",
    "scenes/main/Main.tscn",
    "scenes/main/Opening.tscn",
    "scenes/world/Village.tscn",
    "scenes/player/Player.tscn",
    "scenes/ui/MainMenu.tscn",
    "scenes/ui/Hud.tscn",
    "scenes/ui/DialogueBox.tscn",
    "scenes/ui/PauseMenu.tscn",
    "scenes/ending/Ending.tscn",
    "scenes/ending/Credits.tscn",
    "scenes/puzzle/PatternPuzzle.tscn",
    "scenes/puzzle/PrepPuzzle.tscn",
    "assets/ui/theme/TapakNusa.tres",
]

REQUIRED_AUTOLOADS = ["GameManager", "QuestManager", "DialogueManager", "SaveManager"]

REQUIRED_ACTIONS = ["move_up", "move_down", "move_left", "move_right", "interact", "journal", "pause"]


def check_required(project: dict) -> None:
    for rel in REQUIRED_DIRS:
        if not (ROOT / rel).is_dir():
            err(f"folder wajib tidak ada: {rel}")
    for rel in REQUIRED_FILES:
        if not (ROOT / rel).exists():
            err(f"berkas wajib tidak ada: {rel}")
    for name in REQUIRED_AUTOLOADS:
        if name not in project["autoloads"]:
            err(f"autoload wajib tidak terdaftar: {name}")
    actions = project["sections"].get("input", {})
    for action in REQUIRED_ACTIONS:
        if not any(key.startswith(action) for key in actions.keys()):
            err(f"input action tidak ada di project.godot: {action}")
    main_scene = project["main_scene"]
    if main_scene and not (ROOT / main_scene.replace("res://", "", 1)).exists():
        err(f"main scene tidak ada: {main_scene}")
    if project["sections"].get("rendering", {}).get("renderer/rendering_method") not in (None, '"gl_compatibility"'):
        warn("renderer bukan gl_compatibility")


# ===========================================================================
# Pemuat kelas dasar untuk pemeriksaan turunan
# ===========================================================================


def _collect(callback, *args) -> list[str]:
    """Menjalankan pemeriksaan sambil menampung pesannya ke daftar terpisah."""
    global errors
    saved = errors
    errors = []
    try:
        callback(*args)
        return errors
    finally:
        errors = saved


def _install_class_relation(db: ClassDB) -> None:
    def is_a(klass: str, base: str) -> bool:
        return base in db.chain(klass)

    db.is_a = is_a  # type: ignore[attr-defined]


# ===========================================================================
# main
# ===========================================================================


def main() -> int:
    global CLASS_DB
    parser = argparse.ArgumentParser(description="Pemeriksa statis proyek TAPAK NUSA")
    parser.add_argument("--api", default="/tmp/godot_api", help="folder doc/classes Godot 4.x")
    parser.add_argument("--compat", default="/tmp/godot_api_42", help="folder doc/classes Godot 4.x tertua")
    parser.add_argument("--quiet", action="store_true", help="hanya tampilkan kesalahan")
    args = parser.parse_args()

    db = ClassDB([Path(args.api)])
    compat_db = ClassDB([Path(args.compat)]) if args.compat else ClassDB([])
    CLASS_DB = db  # type: ignore[assignment]
    _install_class_relation(db)
    if not db.loaded:
        warn(f"dokumentasi API tidak ditemukan di {args.api}; pemeriksaan API dilewati")

    project = read_project()
    scripts = scan_scripts()
    scenes = {
        "res://" + str(path.relative_to(ROOT)): Scene(path)
        for path in sorted(ROOT.rglob("*.tscn"))
        if not any(part in SKIP_DIRS for part in path.relative_to(ROOT).parts)
    }
    class_index = build_class_index(scripts, project)

    # 1. skrip
    for rel, script in scripts.items():
        check_script_basics(script, scripts, project, class_index)
        errors.extend(_collect(check_local_declarations, script))
        errors.extend(_collect(check_connects, script, scripts, project, class_index))
        main_messages = _collect(check_script_api, script, scripts, project, class_index)
        errors.extend(main_messages)
        errors.extend(_collect(check_arity, script, scripts, project, class_index))
        # pemeriksaan API terhadap versi 4.x tertua yang didukung
        if compat_db.loaded and db.loaded:
            saved = CLASS_DB
            CLASS_DB = compat_db  # type: ignore[assignment]
            _install_class_relation(compat_db)
            compat_messages = _collect(check_script_api, script, scripts, project, class_index)
            CLASS_DB = saved  # type: ignore[assignment]
            _install_class_relation(db)
            known = {message.split(": ", 1)[-1] for message in main_messages}
            for message in compat_messages:
                if message.split(": ", 1)[-1] not in known:
                    warnings.append("kompatibilitas 4.x tertua — " + message)

    # 2. scene
    check_scenes(db, scenes, scripts)

    # 3. data
    data = check_data()

    # 4. project
    check_required(project)

    # 5. rujukan silang
    check_scene_paths(scripts, scenes, project)
    check_cross_references(scripts, scenes, data)

    if not args.quiet:
        for message in warnings:
            print(f"  ~ {message}")
        print(f"--- {len(scripts)} skrip, {len(scenes)} scene, diperiksa")
    for message in errors:
        print(f"  ! {message}")
    print(f"{len(errors)} error, {len(warnings)} peringatan")
    return 1 if errors else 0


CLASS_DB: ClassDB | None = None

if __name__ == "__main__":
    sys.exit(main())
