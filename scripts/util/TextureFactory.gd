class_name TextureFactory
extends RefCounted
## Pembuat tekstur prosedural (tanpa file gambar eksternal).
##
## Dipakai untuk partikel, kilau interaksi, dan potret dialog. Semua tekstur
## dibuat sekali lalu di-cache.

static var _cache: Dictionary = {}


## Titik lembut (glow) — dipakai partikel debu, kunang-kunang, dan kilau.
static func soft_dot(size: int = 24, hardness: float = 0.3, color: Color = Color(1, 1, 1, 1)) -> Texture2D:
	var key := "dot_%d_%.2f_%s" % [size, hardness, color.to_html(true)]
	if _cache.has(key):
		return _cache[key]
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center := Vector2(float(size) * 0.5, float(size) * 0.5)
	var max_dist := float(size) * 0.5
	for y in size:
		for x in size:
			var d := Vector2(float(x) + 0.5, float(y) + 0.5).distance_to(center) / max_dist
			var a := clampf(1.0 - smoothstep(hardness, 1.0, d), 0.0, 1.0)
			img.set_pixel(x, y, Color(color.r, color.g, color.b, color.a * a))
	var tex := ImageTexture.create_from_image(img)
	_cache[key] = tex
	return tex


## Cincin tipis — dipakai efek sukses puzzle.
static func ring(size: int = 32, thickness: float = 0.18, color: Color = Color(1, 1, 1, 1)) -> Texture2D:
	var key := "ring_%d_%.2f_%s" % [size, thickness, color.to_html(true)]
	if _cache.has(key):
		return _cache[key]
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center := Vector2(float(size) * 0.5, float(size) * 0.5)
	var outer := float(size) * 0.5
	var inner := outer * (1.0 - thickness)
	for y in size:
		for x in size:
			var d := Vector2(float(x) + 0.5, float(y) + 0.5).distance_to(center)
			var a := 0.0
			if d <= outer and d >= inner:
				a = 1.0
			elif d < inner:
				a = clampf((d - inner + 2.0) / 2.0, 0.0, 1.0)
			var edge := clampf((outer - d) / 1.5, 0.0, 1.0)
			img.set_pixel(x, y, Color(color.r, color.g, color.b, color.a * a * edge))
	var tex := ImageTexture.create_from_image(img)
	_cache[key] = tex
	return tex


## Daun kecil untuk partikel lingkungan.
static func leaf(width: int = 18, height: int = 11, color: Color = Palette.LEAF) -> Texture2D:
	var key := "leaf_%d_%d_%s" % [width, height, color.to_html(true)]
	if _cache.has(key):
		return _cache[key]
	var img := Image.create(width, height, false, Image.FORMAT_RGBA8)
	var cx := float(width) * 0.5
	var cy := float(height) * 0.5
	for y in height:
		for x in width:
			var nx := (float(x) + 0.5 - cx) / cx
			var ny := (float(y) + 0.5 - cy) / cy
			# bentuk tetesan daun: |ny| <= sqrt(1 - nx^2)
			var inside := absf(ny) <= sqrt(maxf(0.0, 1.0 - nx * nx))
			var edge := clampf((1.0 - absf(ny)) * 4.0, 0.0, 1.0)
			var a := 1.0 if inside else 0.0
			img.set_pixel(x, y, Color(color.r, color.g, color.b, color.a * a))
			if a > 0.0 and edge < 1.0:
				img.set_pixel(x, y, Color(color.r, color.g, color.b, color.a * edge))
	# tulang daun
	for x in width:
		var y := int(cy)
		if y >= 0 and y < height:
			img.set_pixel(x, y, color.darkened(0.25))
	var tex := ImageTexture.create_from_image(img)
	_cache[key] = tex
	return tex


## Kilau bintang empat sisi untuk feedback quest.
static func sparkle(size: int = 20, color: Color = Palette.GOLD) -> Texture2D:
	var key := "sparkle_%d_%s" % [size, color.to_html(true)]
	if _cache.has(key):
		return _cache[key]
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var c := float(size) * 0.5
	var maxv := 0.0
	for y in size:
		for x in size:
			var nx := absf((float(x) + 0.5 - c) / c)
			var ny := absf((float(y) + 0.5 - c) / c)
			if nx + ny <= 1.0:
				maxv = 1.0
			img.set_pixel(x, y, Color(0, 0, 0, 0))
	for y in size:
		for x in size:
			var nx := absf((float(x) + 0.5 - c) / c)
			var ny := absf((float(y) + 0.5 - c) / c)
			var a := clampf(1.0 - (nx + ny), 0.0, 1.0)
			a = pow(a, 0.6)
			img.set_pixel(x, y, Color(color.r, color.g, color.b, color.a * a))
	var tex := ImageTexture.create_from_image(img)
	_cache[key] = tex
	return tex


## Persegi warna datar 2x2 (untuk modulasi partikel).
static func flat(color: Color, size: int = 4) -> Texture2D:
	var key := "flat_%s_%d" % [color.to_html(true), size]
	if _cache.has(key):
		return _cache[key]
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(color)
	var tex := ImageTexture.create_from_image(img)
	_cache[key] = tex
	return tex


## Potret prosedural untuk kotak dialog: wajah sederhana sesuai palet karakter.
static func portrait(character_id: String, size: int = 128) -> Texture2D:
	var key := "portrait_%s_%d" % [character_id, size]
	if _cache.has(key):
		return _cache[key]
	var palette := Palette.character(character_id)
	var skin: Color = palette["skin"]
	var hair: Color = palette["hair"]
	var shirt: Color = palette["shirt"]
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var s := float(size)
	# latar lembut
	for y in size:
		for x in size:
			var t := float(y) / s
			img.set_pixel(x, y, Palette.INK_SOFT.lerp(Palette.INK, t))
	# badan (dada)
	var body_top := s * 0.62
	for y in range(int(body_top), size):
		for x in size:
			img.set_pixel(x, y, shirt.darkened(0.15))
	# leher
	for y in range(int(s * 0.55), int(body_top) + 2):
		for x in range(int(s * 0.40), int(s * 0.60)):
			img.set_pixel(x, y, skin.darkened(0.18))
	# kepala
	var head_c := Vector2(s * 0.5, s * 0.42)
	var head_r := Vector2(s * 0.235, s * 0.27)
	_fill_ellipse(img, head_c, head_r, skin)
	# rambut
	if palette["hat"] == "straw":
		_fill_ellipse(img, Vector2(s * 0.5, s * 0.26), Vector2(s * 0.34, s * 0.12), Palette.PATH_SAND)
		_fill_ellipse(img, Vector2(s * 0.5, s * 0.22), Vector2(s * 0.19, s * 0.10), Palette.PATH_SAND_DARK)
	else:
		_fill_ellipse(img, Vector2(s * 0.5, s * 0.27), Vector2(s * 0.26, s * 0.16), hair)
		if palette["hat"] == "cap":
			_fill_ellipse(img, Vector2(s * 0.5, s * 0.24), Vector2(s * 0.27, s * 0.13), palette["accent"])
		if palette["bun"]:
			_fill_ellipse(img, Vector2(s * 0.5, s * 0.17), Vector2(s * 0.10, s * 0.09), hair)
	# mata
	var eye_y := int(s * 0.42)
	for side in [-1.0, 1.0]:
		_fill_ellipse(img, Vector2(s * 0.5 + side * s * 0.085, eye_y), Vector2(s * 0.026, s * 0.034), Palette.CREAM)
		_fill_ellipse(img, Vector2(s * 0.5 + side * s * 0.085, eye_y), Vector2(s * 0.014, s * 0.024), Palette.HAIR_DARK)
	# mulut
	_fill_ellipse(img, Vector2(s * 0.5, s * 0.53), Vector2(s * 0.045, s * 0.018), skin.darkened(0.35))
	var tex := ImageTexture.create_from_image(img)
	_cache[key] = tex
	return tex


static func _fill_ellipse(img: Image, center: Vector2, radii: Vector2, color: Color) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var min_x := int(maxf(0.0, center.x - radii.x))
	var max_x := int(minf(float(w) - 1.0, center.x + radii.x))
	var min_y := int(maxf(0.0, center.y - radii.y))
	var max_y := int(minf(float(h) - 1.0, center.y + radii.y))
	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			var dx := (float(x) + 0.5 - center.x) / radii.x
			var dy := (float(y) + 0.5 - center.y) / radii.y
			var d := dx * dx + dy * dy
			if d <= 1.0:
				var current := img.get_pixel(x, y)
				var a := color.a * clampf((1.0 - d) * 6.0, 0.0, 1.0)
				img.set_pixel(x, y, current.lerp(color, a))
