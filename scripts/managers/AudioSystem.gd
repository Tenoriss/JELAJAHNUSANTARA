class_name AudioSystem
extends Node
## Pengelola audio game: musik, ambience, dan efek suara.
##
## Semua stream dibuat secara prosedural (lihat ProceduralAudio). Efek suara
## pendek dibuat langsung saat start; musik & ambience disiapkan di thread
## terpisah supaya game tetap terbuka cepat. Thread itu hanya menyiapkan data
## audio (tanpa menyentuh node), lalu melapor ke main thread lewat
## call_deferred sehingga pemutaran tetap aman.

const SFX_POOL_SIZE := 6

var music_volume := 0.7
var sfx_volume := 0.85
var ambient_volume := 0.5

var _music_player: AudioStreamPlayer
var _ambient_player: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_index := 0

var _pending_music := ""
var _pending_ambient := ""
var _current_music := ""
var _current_ambient := ""
var _music_fade_tween: Tween
var _build_thread: Thread = null
var _heavy_ready := false


func _ready() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.name = "MusicPlayer"
	_music_player.volume_db = _db(music_volume)
	add_child(_music_player)

	_ambient_player = AudioStreamPlayer.new()
	_ambient_player.name = "AmbientPlayer"
	_ambient_player.volume_db = _db(ambient_volume, -6.0)
	add_child(_ambient_player)

	for i in SFX_POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.name = "SfxPlayer%d" % i
		player.volume_db = _db(sfx_volume)
		add_child(player)
		_sfx_players.append(player)

	# Efek suara: pendek dan murah, aman dibuat langsung.
	for sfx_name in ProceduralAudio.sfx_names():
		ProceduralAudio.get_sfx(sfx_name)

	# Musik & ambience: dibuat di thread terpisah supaya menu langsung tampil.
	_build_thread = Thread.new()
	_build_thread.start(_build_heavy_streams, Thread.PRIORITY_LOW)


func _exit_tree() -> void:
	if _build_thread != null and _build_thread.is_started():
		_build_thread.wait_to_finish()
	_build_thread = null


## Dijalankan di thread terpisah: hanya menyiapkan data audio (cache statis),
## tidak menyentuh node apa pun milik scene tree.
func _build_heavy_streams() -> void:
	ProceduralAudio.get_music("village")
	ProceduralAudio.get_music("menu")
	ProceduralAudio.get_music("ending")
	ProceduralAudio.get_ambient("day")
	ProceduralAudio.get_ambient("night")
	call_deferred("_on_heavy_ready")


func _on_heavy_ready() -> void:
	if _heavy_ready:
		return
	_heavy_ready = true
	if not _pending_music.is_empty():
		_start_music(_pending_music)
		_pending_music = ""
	if not _pending_ambient.is_empty():
		_start_ambient(_pending_ambient)
		_pending_ambient = ""


# --- Musik -----------------------------------------------------------------

func play_music(track: String, fade := 1.2) -> void:
	if _current_music == track:
		return
	if not _heavy_ready:
		_pending_music = track
		return
	_start_music(track, fade)


func stop_music(fade := 0.8) -> void:
	_current_music = ""
	_pending_music = ""
	if _music_fade_tween != null and _music_fade_tween.is_valid():
		_music_fade_tween.kill()
	_music_fade_tween = create_tween()
	_music_fade_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_music_fade_tween.tween_property(_music_player, "volume_db", -60.0, fade)
	_music_fade_tween.tween_callback(_music_player.stop)


func _start_music(track: String, fade := 1.2) -> void:
	_current_music = track
	_music_player.stream = ProceduralAudio.get_music(track)
	_music_player.volume_db = -60.0
	if not _music_player.playing:
		_music_player.play()
	if _music_fade_tween != null and _music_fade_tween.is_valid():
		_music_fade_tween.kill()
	_music_fade_tween = create_tween()
	_music_fade_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_music_fade_tween.tween_property(_music_player, "volume_db", _db(music_volume), fade)


func current_music() -> String:
	return _current_music


# --- Ambience --------------------------------------------------------------

func play_ambient(track: String, fade := 1.5) -> void:
	if _current_ambient == track:
		return
	if not _heavy_ready:
		_pending_ambient = track
		return
	_start_ambient(track, fade)


func _start_ambient(track: String, fade := 1.5) -> void:
	_current_ambient = track
	_ambient_player.stream = ProceduralAudio.get_ambient(track)
	_ambient_player.volume_db = -60.0
	if not _ambient_player.playing:
		_ambient_player.play()
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(_ambient_player, "volume_db", _db(ambient_volume, -6.0), fade)


func stop_ambient(fade := 1.0) -> void:
	_current_ambient = ""
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(_ambient_player, "volume_db", -60.0, fade)
	tween.tween_callback(_ambient_player.stop)


# --- Efek suara ------------------------------------------------------------

func play_sfx(sfx_name: String, volume_offset_db := 0.0, pitch := 1.0) -> void:
	if _sfx_players.is_empty():
		return
	var player := _sfx_players[_sfx_index]
	_sfx_index = (_sfx_index + 1) % _sfx_players.size()
	player.stream = ProceduralAudio.get_sfx(sfx_name)
	player.volume_db = _db(sfx_volume) + volume_offset_db
	player.pitch_scale = pitch
	player.play()


func play_ui_click() -> void:
	play_sfx("click", -4.0)


# --- Volume ----------------------------------------------------------------

func set_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 1.0)
	if _current_music != "" and _music_player.playing:
		_music_player.volume_db = _db(music_volume)


func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)
	for player in _sfx_players:
		player.volume_db = _db(sfx_volume)


func set_ambient_volume(value: float) -> void:
	ambient_volume = clampf(value, 0.0, 1.0)
	if _current_ambient != "" and _ambient_player.playing:
		_ambient_player.volume_db = _db(ambient_volume, -6.0)


func _db(linear: float, offset := 0.0) -> float:
	if linear <= 0.001:
		return -80.0
	return linear_to_db(linear) + offset
