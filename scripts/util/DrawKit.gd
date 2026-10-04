class_name DrawKit
extends RefCounted
## Helper menggambar untuk seluruh art prosedural game.
##
## Semua visual TAPAK NUSA dibuat dari bentuk dasar (kotak membulat, elips,
## garis, poligon) supaya project tetap berjalan tanpa aset eksternal.
## StyleBoxFlat dan titik poligon di-cache agar _draw() tetap murah.

static var _box_cache: Dictionary = {}
static var _poly_cache: Dictionary = {}


static func font() -> Font:
	return ThemeDB.fallback_font


# --- Kotak & panel -------------------------------------------------------

static func box_style(
	color: Color, radius: int = 6, border_color: Color = Color(0, 0, 0, 0), border_width: int = 0
) -> StyleBoxFlat:
	var key := "%s|%d|%s|%d" % [color.to_html(true), radius, border_color.to_html(true), border_width]
	if _box_cache.has(key):
		return _box_cache[key]
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(radius)
	if border_width > 0:
		sb.set_border_width_all(border_width)
		sb.border_color = border_color
	_box_cache[key] = sb
	return sb


static func draw_box(ci: CanvasItem, rect: Rect2, color: Color, radius: int = 6) -> void:
	ci.draw_style_box(box_style(color, radius), rect)


static func draw_box_border(
	ci: CanvasItem,
	rect: Rect2,
	fill: Color,
	border: Color,
	border_width: int = 2,
	radius: int = 8
) -> void:
	ci.draw_style_box(box_style(fill, radius, border, border_width), rect)


# --- Elips ---------------------------------------------------------------

static func ellipse_points(radii: Vector2, segments: int = 24) -> PackedVector2Array:
	var key := "%.1f_%.1f_%d" % [radii.x, radii.y, segments]
	if _poly_cache.has(key):
		return _poly_cache[key]
	var pts := PackedVector2Array()
	for i in segments:
		var a := TAU * float(i) / float(segments)
		pts.append(Vector2(cos(a) * radii.x, sin(a) * radii.y))
	_poly_cache[key] = pts
	return pts


static func draw_ellipse(ci: CanvasItem, center: Vector2, radii: Vector2, color: Color, segments: int = 24) -> void:
	if radii.x <= 0.0 or radii.y <= 0.0:
		return
	var pts := ellipse_points(radii, segments)
	var world := PackedVector2Array()
	world.resize(pts.size())
	for i in pts.size():
		world[i] = center + pts[i]
	ci.draw_colored_polygon(world, color)


static func draw_ellipse_ring(
	ci: CanvasItem, center: Vector2, radii: Vector2, color: Color, width: float = 2.0, segments: int = 24
) -> void:
	if radii.x <= 0.0 or radii.y <= 0.0:
		return
	var pts := ellipse_points(radii, segments)
	var world := PackedVector2Array()
	for p in pts:
		world.append(center + p)
	world.append(world[0])
	ci.draw_polyline(world, color, width, true)


static func draw_shadow(ci: CanvasItem, center: Vector2, radii: Vector2, alpha: float = 0.2) -> void:
	draw_ellipse(ci, center, radii, Palette.with_alpha(Color(0.05, 0.04, 0.03, 1.0), alpha))


# --- Bentuk lain ---------------------------------------------------------

## Batang/tonggak vertikal dengan ujung membulat (bambu, tiang, pohon).
static func draw_pillar(
	ci: CanvasItem, base: Vector2, width: float, height: float, color: Color, top_color: Color = Color(0, 0, 0, 0)
) -> void:
	var rect := Rect2(base.x - width * 0.5, base.y - height, width, height)
	draw_box(ci, rect, color, int(min(width, height) * 0.5))
	var top := top_color if top_color.a > 0.0 else color.lightened(0.12)
	draw_ellipse(ci, Vector2(base.x, base.y - height), Vector2(width * 0.5, width * 0.35), top)


static func draw_poly(ci: CanvasItem, points: PackedVector2Array, color: Color) -> void:
	if points.size() >= 3:
		ci.draw_colored_polygon(points, color)


static func draw_line_soft(ci: CanvasItem, from: Vector2, to: Vector2, color: Color, width: float = 2.0) -> void:
	ci.draw_line(from, to, color, width, true)


## Garis dengan sudut membulat (jalur, pipa, tali).
static func draw_band(ci: CanvasItem, from: Vector2, to: Vector2, width: float, color: Color) -> void:
	var a := from if from.x <= to.x else to
	var b := to if from.x <= to.x else from
	draw_box(ci, Rect2(a.x, a.y - width * 0.5, max(b.x - a.x, 0.5), width), color, int(width * 0.5))


# --- Teks ----------------------------------------------------------------

static func text_size(text: String, size: int = 18) -> Vector2:
	return font().get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size)


static func draw_text(
	ci: CanvasItem,
	pos: Vector2,
	text: String,
	size: int = 18,
	color: Color = Palette.CREAM,
	width: float = -1.0,
	outline: bool = false,
	outline_color: Color = Palette.INK
) -> void:
	if outline:
		ci.draw_string_outline(font(), pos, text, HORIZONTAL_ALIGNMENT_LEFT, width, size, 4, outline_color)
	ci.draw_string(font(), pos, text, HORIZONTAL_ALIGNMENT_LEFT, width, size, color)


## Menggambar teks terpusat pada sebuah titik (horizontal + vertikal).
static func draw_text_centered(
	ci: CanvasItem,
	center: Vector2,
	text: String,
	size: int = 18,
	color: Color = Palette.CREAM,
	outline: bool = false,
	outline_color: Color = Palette.INK
) -> void:
	var f := font()
	var dimensions := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size)
	var baseline := center.y + (f.get_ascent(size) - f.get_descent(size)) * 0.5
	var pos := Vector2(center.x - dimensions.x * 0.5, baseline)
	draw_text(ci, pos, text, size, color, -1.0, outline, outline_color)


## Teks multi-baris sederhana dengan pembungkusan manual.
static func draw_text_wrapped(
	ci: CanvasItem,
	top_left: Vector2,
	text: String,
	max_width: float,
	size: int = 18,
	color: Color = Palette.CREAM,
	line_height: float = 0.0
) -> void:
	var lh := line_height if line_height > 0.0 else float(size) * 1.35
	var y := top_left.y + float(size)
	for line in wrap_lines(text, max_width, size):
		draw_text(ci, Vector2(top_left.x, y), line, size, color)
		y += lh


static func wrap_lines(text: String, max_width: float, size: int = 18) -> PackedStringArray:
	var out := PackedStringArray()
	for paragraph in text.split("\n"):
		var current := ""
		for word in paragraph.split(" "):
			var candidate := word if current.is_empty() else current + " " + word
			if text_size(candidate, size).x > max_width and not current.is_empty():
				out.append(current)
				current = word
			else:
				current = candidate
		out.append(current)
	return out
