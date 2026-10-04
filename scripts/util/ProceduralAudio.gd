class_name ProceduralAudio
extends RefCounted
## Seluruh audio TAPAK NUSA dibuat lewat kode (tanpa file audio eksternal).
##
## Nada dasar memakai tangga lima nada mirip gamelan (pembagian oktaf 5 langkah)
## supaya suasananya terasa dekat dengan musik tradisional Nusantara.
##
## Catatan teknis: setiap nada di-render dari satu tabel gelombang (wave table)
## yang di-resample, lalu diberi selubung (envelope) peluruhan. Cara ini jauh
## lebih murah daripada memanggil sin() untuk setiap sampel.

const RATE := 16000
const SFX_RATE := 22050
const TABLE_LENGTH := 2048
const TABLE_FREQ := 440.0

static var _sfx_cache: Dictionary = {}
static var _music_cache: Dictionary = {}
static var _table_cache: Dictionary = {}

# --- Tabel gelombang -----------------------------------------------------

## Tabel nada "saron": beberapa harmonisa dengan amplitudo menurun.
static func _metal_table() -> PackedFloat32Array:
	return _table("metal", PackedFloat32Array([1.0, 0.5, 0.28, 0.12, 0.05]))


static func _bell_table() -> PackedFloat32Array:
	return _table("bell", PackedFloat32Array([1.0, 0.0, 0.35, 0.0, 0.18]))


static func _soft_table() -> PackedFloat32Array:
	return _table("soft", PackedFloat32Array([1.0, 0.22, 0.06]))


static func _gong_table() -> PackedFloat32Array:
	return _table("gong", PackedFloat32Array([1.0, 0.62, 0.42, 0.3, 0.22, 0.14, 0.08]))


static func _table(key: String, harmonics: PackedFloat32Array) -> PackedFloat32Array:
	if _table_cache.has(key):
		return _table_cache[key]
	var table := PackedFloat32Array()
	table.resize(TABLE_LENGTH)
	for i in TABLE_LENGTH:
		var t := float(i) / float(RATE)
		var value := 0.0
		for h in harmonics.size():
			if harmonics[h] == 0.0:
				continue
			var freq := TABLE_FREQ * float(h + 1) * (1.0 + 0.0015 * float(h))
			value += sin(TAU * freq * t) * harmonics[h]
		table[i] = value
	_table_cache[key] = table
	return table


## Menambahkan satu nada ke buffer (resample + peluruhan eksponensial).
static func _mix_note(
	buffer: PackedFloat32Array,
	start_sample: int,
	freq: float,
	amplitude: float,
	decay_time: float,
	table: PackedFloat32Array,
	attack := 0.004
) -> void:
	if start_sample >= buffer.size():
		return
	var step := freq / TABLE_FREQ
	var decay := exp(-1.0 / (maxf(decay_time, 0.02) * float(RATE)))
	var attack_samples := int(attack * float(RATE))
	var env := 1.0
	var total := buffer.size()
	var table_length := table.size()
	var index := start_sample
	var source := 0.0
	while index < total and env > 0.002:
		var target := int(source)
		var frac := source - float(target)
		var a := table[target % table_length]
		var b := table[(target + 1) % table_length]
		var value := (a + (b - a) * frac) * amplitude
		if attack_samples > 0 and index - start_sample < attack_samples:
			value *= float(index - start_sample) / float(attack_samples)
		buffer[index] += value * env
		source += step
		env *= decay
		index += 1


static func _mix_noise(
	buffer: PackedFloat32Array,
	start_sample: int,
	amplitude: float,
	decay_time: float,
	rng: RandomNumberGenerator,
	lowpass := 0.35
) -> void:
	var decay := exp(-1.0 / (maxf(decay_time, 0.02) * float(RATE)))
	var env := 1.0
	var state := 0.0
	var index := start_sample
	while index < buffer.size() and env > 0.002:
		var white := rng.randf_range(-1.0, 1.0)
		state += (white - state) * lowpass
		buffer[index] += state * env * amplitude
		env *= decay
		index += 1


static func _make_buffer(length_sec: float, rate := RATE) -> PackedFloat32Array:
	var buffer := PackedFloat32Array()
	buffer.resize(int(length_sec * float(rate)))
	buffer.fill(0.0)
	return buffer


static func _normalize(buffer: PackedFloat32Array, peak: float) -> void:
	var max_value := 0.0
	for i in buffer.size():
		var value := absf(buffer[i])
		if value > max_value:
			max_value = value
	if max_value <= 0.0001:
		return
	var scale := peak / max_value
	for i in buffer.size():
		buffer[i] *= scale


## Menghaluskan awal/akhir buffer agar loop tidak berbunyi "klik".
static func _soften_edges(buffer: PackedFloat32Array, seconds := 0.02) -> void:
	var count := int(seconds * float(RATE))
	var total := buffer.size()
	if count * 2 >= total:
		return
	for i in count:
		var factor := float(i) / float(count)
		buffer[i] *= factor
		buffer[total - 1 - i] *= factor


static func _to_wav(buffer: PackedFloat32Array, rate: int, loop: bool) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(buffer.size() * 2)
	for i in buffer.size():
		var value := int(clampf(buffer[i], -1.0, 1.0) * 32000.0)
		data.encode_s16(i * 2, value)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.stereo = false
	stream.data = data
	if loop:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = buffer.size()
	return stream


# --- Efek suara ----------------------------------------------------------

static func sfx_names() -> PackedStringArray:
	return PackedStringArray(
		[
			"click", "hover", "confirm", "cancel", "pickup", "quest", "note",
			"place", "success", "fail", "talk", "sparkle", "step1", "step2", "gong",
		]
	)


static func get_sfx(name: String) -> AudioStreamWAV:
	if _sfx_cache.has(name):
		return _sfx_cache[name]
	var stream := _build_sfx(name)
	_sfx_cache[name] = stream
	return stream


static func _build_sfx(name: String) -> AudioStreamWAV:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(name)
	var metal := _metal_table()
	var bell := _bell_table()
	var soft := _soft_table()
	var gong := _gong_table()
	match name:
		"click":
			var b := _make_short(0.09)
			_mix_note(b, 0, 900.0, 0.5, 0.05, metal)
			_mix_note(b, 120, 1350.0, 0.22, 0.04, metal)
			return _to_wav(b, RATE, false)
		"hover":
			var b := _make_short(0.07)
			_mix_note(b, 0, 700.0, 0.22, 0.05, soft)
			return _to_wav(b, RATE, false)
		"confirm":
			var b := _make_short(0.3)
			_mix_note(b, 0, 587.0, 0.42, 0.22, metal)
			_mix_note(b, int(0.09 * RATE), 880.0, 0.42, 0.26, metal)
			return _to_wav(b, RATE, false)
		"cancel":
			var b := _make_short(0.3)
			_mix_note(b, 0, 520.0, 0.36, 0.16, soft)
			_mix_note(b, int(0.08 * RATE), 392.0, 0.36, 0.22, soft)
			return _to_wav(b, RATE, false)
		"pickup":
			var b := _make_short(0.55)
			var notes := PackedFloat32Array([587.0, 784.0, 1046.0])
			for i in notes.size():
				_mix_note(b, int(float(i) * 0.075 * RATE), notes[i], 0.4, 0.24, metal)
			return _to_wav(b, RATE, false)
		"quest":
			var b := _make_short(1.5)
			var notes := PackedFloat32Array([440.0, 587.0, 880.0, 1046.0, 1318.0])
			for i in notes.size():
				_mix_note(b, int(float(i) * 0.13 * RATE), notes[i], 0.42, 0.75, bell)
			_mix_note(b, 0, 110.0, 0.3, 1.1, gong)
			return _to_wav(b, RATE, false)
		"note":
			var b := _make_short(1.1)
			_mix_note(b, 0, 1318.0, 0.3, 0.5, bell)
			_mix_note(b, int(0.1 * RATE), 1760.0, 0.26, 0.6, bell)
			return _to_wav(b, RATE, false)
		"place":
			var b := _make_short(0.22)
			_mix_note(b, 0, 196.0, 0.5, 0.11, soft)
			_mix_noise(b, 0, 0.22, 0.05, rng, 0.5)
			return _to_wav(b, RATE, false)
		"success":
			var b := _make_short(1.8)
			var notes := PackedFloat32Array([587.0, 784.0, 880.0, 1174.0, 1568.0])
			for i in notes.size():
				_mix_note(b, int(float(i) * 0.11 * RATE), notes[i], 0.4, 0.9, metal)
			_mix_note(b, 0, 147.0, 0.35, 1.4, gong)
			return _to_wav(b, RATE, false)
		"fail":
			var b := _make_short(0.45)
			_mix_note(b, 0, 233.0, 0.42, 0.18, soft)
			_mix_note(b, int(0.12 * RATE), 175.0, 0.42, 0.26, soft)
			_mix_noise(b, 0, 0.12, 0.09, rng, 0.18)
			return _to_wav(b, RATE, false)
		"talk":
			var b := _make_short(0.045)
			_mix_note(b, 0, 1200.0, 0.12, 0.03, soft)
			return _to_wav(b, RATE, false)
		"sparkle":
			var b := _make_short(0.6)
			_mix_note(b, 0, 1568.0, 0.22, 0.28, bell)
			_mix_note(b, int(0.06 * RATE), 2093.0, 0.18, 0.34, bell)
			return _to_wav(b, RATE, false)
		"step1", "step2":
			var b := _make_short(0.16)
			var pitch := 0.9 if name == "step1" else 1.05
			_mix_noise(b, 0, 0.2, 0.05, rng, 0.12)
			_mix_note(b, 0, 120.0 * pitch, 0.16, 0.06, soft)
			return _to_wav(b, RATE, false)
		"gong":
			var b := _make_short(3.2)
			_mix_note(b, 0, 98.0, 0.55, 2.4, gong)
			_mix_note(b, 0, 147.0, 0.25, 1.8, gong)
			_mix_noise(b, 0, 0.1, 0.25, rng, 0.08)
			return _to_wav(b, RATE, false)
		_:
			var b := _make_short(0.12)
			_mix_note(b, 0, 660.0, 0.3, 0.06, soft)
			return _to_wav(b, RATE, false)


static func _make_short(length_sec: float) -> PackedFloat32Array:
	return _make_buffer(length_sec, RATE)


# --- Musik & ambience ----------------------------------------------------

static func get_music(name: String) -> AudioStreamWAV:
	if _music_cache.has(name):
		return _music_cache[name]
	var stream := _build_music(name)
	_music_cache[name] = stream
	return stream


static func _build_music(name: String) -> AudioStreamWAV:
	var metal := _metal_table()
	var bell := _bell_table()
	var gong := _gong_table()
	# tangga lima nada (mirip slendro): rasio 2^(k/5)
	var scale := PackedFloat32Array([220.0, 252.7, 290.3, 333.3, 382.9, 440.0, 505.4, 580.5])
	var buffer: PackedFloat32Array
	var rng := RandomNumberGenerator.new()
	match name:
		"village":
			buffer = _make_buffer(20.0)
			rng.seed = 20261015
			_sequence(buffer, rng, scale, 0.55, 0.62, metal, bell, gong, 7, 0.5)
		"ending":
			buffer = _make_buffer(18.0)
			rng.seed = 771215
			_sequence(buffer, rng, scale, 0.9, 0.55, metal, bell, gong, 5, 0.35)
		"menu":
			buffer = _make_buffer(14.0)
			rng.seed = 424242
			_sequence(buffer, rng, scale, 0.8, 0.45, metal, bell, gong, 4, 0.3)
		_:
			buffer = _make_buffer(12.0)
			rng.seed = 99
			_sequence(buffer, rng, scale, 0.7, 0.5, metal, bell, gong, 5, 0.4)
	_normalize(buffer, 0.62)
	_soften_edges(buffer, 0.05)
	return _to_wav(buffer, RATE, true)


## Menyusun melodi sederhana: melodi utama, bass, dan gong berkala.
static func _sequence(
	buffer: PackedFloat32Array,
	rng: RandomNumberGenerator,
	scale: PackedFloat32Array,
	beat: float,
	amplitude: float,
	metal: PackedFloat32Array,
	bell: PackedFloat32Array,
	gong: PackedFloat32Array,
	top_index: int,
	bass_amplitude: float
) -> void:
	var length := float(buffer.size()) / float(RATE)
	var index := 3
	var time := 0.0
	var step := 0
	while time < length - 0.6:
		# melodi: jalan acak pada tangga nada
		index += rng.randi_range(-2, 2)
		index = clampi(index, 0, top_index)
		if rng.randf() > 0.18:  # sesekali istirahat agar tidak ramai
			var freq: float = scale[index]
			_mix_note(buffer, int(time * RATE), freq, amplitude, 1.05, metal, 0.006)
			if rng.randf() > 0.72:
				_mix_note(buffer, int((time + beat * 0.5) * RATE), freq * 2.0, amplitude * 0.45, 0.8, bell)
		if step % 4 == 0:
			var bass_freq: float = scale[index % 3] * 0.5
			_mix_note(buffer, int(time * RATE), bass_freq, bass_amplitude, 1.6, metal, 0.01)
		if step % 16 == 0:
			_mix_note(buffer, int(time * RATE), 98.0, bass_amplitude * 0.8, 2.6, gong)
		time += beat
		step += 1


static func get_ambient(name: String) -> AudioStreamWAV:
	if _music_cache.has("amb_" + name):
		return _music_cache["amb_" + name]
	var stream := _build_ambient(name)
	_music_cache["amb_" + name] = stream
	return stream


static func _build_ambient(name: String) -> AudioStreamWAV:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(name)
	var buffer := _make_buffer(12.0)
	var night := name == "night"
	# angin / latar lembut
	var state := 0.0
	var drift := 0.0
	for i in buffer.size():
		var white := rng.randf_range(-1.0, 1.0)
		state += (white - state) * 0.015
		drift += (state - drift) * 0.0009
		buffer[i] = drift * 2.4
	# suara alam berkala
	var bell := _bell_table()
	var time := 0.6
	while time < 11.0:
		if night:
			# jangkrik: pulsa pendek berulang
			for k in 4:
				_mix_note(buffer, int((time + float(k) * 0.12) * RATE), 3200.0, 0.05, 0.05, bell)
		else:
			# burung: 2-3 nada cepat
			var base: float = rng.randf_range(1200.0, 2100.0)
			var notes := rng.randi_range(2, 3)
			for k in notes:
				_mix_note(
					buffer,
					int((time + float(k) * 0.11) * RATE),
					base * (1.0 + 0.12 * float(k)),
					0.09,
					0.09,
					bell
				)
		time += rng.randf_range(1.4, 3.4)
	_normalize(buffer, 0.34)
	_soften_edges(buffer, 0.05)
	return _to_wav(buffer, RATE, true)
