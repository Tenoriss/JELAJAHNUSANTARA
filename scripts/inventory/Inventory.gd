class_name Inventory
extends RefCounted
## Inventory sederhana: hanya menyimpan item quest (id -> jumlah).

signal changed()
signal item_added(item_id: String, amount: int)
signal item_removed(item_id: String, amount: int)

const CATALOG_PATH := "res://data/items/items.json"

static var _catalog: Dictionary = {}
static var _catalog_loaded := false

var items: Dictionary = {}


## Memuat katalog item dari data/items/items.json (dipanggil sekali).
static func load_catalog(force := false) -> void:
	if _catalog_loaded and not force:
		return
	_catalog_loaded = true
	_catalog = {}
	if not FileAccess.file_exists(CATALOG_PATH):
		push_warning("Katalog item tidak ditemukan: " + CATALOG_PATH)
		return
	var file := FileAccess.open(CATALOG_PATH, FileAccess.READ)
	if file == null:
		push_warning("Gagal membuka katalog item")
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) == TYPE_DICTIONARY:
		_catalog = parsed


## Data katalog sebuah item ({} bila tidak ada).
static func entry(item_id: String) -> Dictionary:
	load_catalog()
	if _catalog.has(item_id):
		return _catalog[item_id]
	return {}


static func display_name(item_id: String) -> String:
	var data := entry(item_id)
	return str(data.get("name", item_id.capitalize()))


static func description(item_id: String) -> String:
	return str(entry(item_id).get("description", ""))


static func item_color(item_id: String) -> Color:
	var data := entry(item_id)
	var html := str(data.get("color", "#f2b134"))
	return Color(html)


static func all_ids() -> Array:
	load_catalog()
	return _catalog.keys()


# --- Isi inventory ---------------------------------------------------------

func add(item_id: String, amount := 1) -> void:
	if amount <= 0:
		return
	items[item_id] = count(item_id) + amount
	item_added.emit(item_id, amount)
	changed.emit()


func remove(item_id: String, amount := 1) -> bool:
	if not has(item_id, amount):
		return false
	var left := count(item_id) - amount
	if left <= 0:
		items.erase(item_id)
	else:
		items[item_id] = left
	item_removed.emit(item_id, amount)
	changed.emit()
	return true


func count(item_id: String) -> int:
	return int(items.get(item_id, 0))


func has(item_id: String, amount := 1) -> bool:
	return count(item_id) >= amount


func has_all(ids: Array) -> bool:
	for id in ids:
		if not has(str(id)):
			return false
	return true


func missing(ids: Array) -> Array:
	var out: Array = []
	for id in ids:
		if not has(str(id)):
			out.append(str(id))
	return out


func clear() -> void:
	items.clear()
	changed.emit()


func to_dict() -> Dictionary:
	return items.duplicate()


func from_dict(data: Dictionary) -> void:
	items.clear()
	for key in data.keys():
		items[str(key)] = int(data[key])
	changed.emit()
