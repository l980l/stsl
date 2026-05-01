# autoload/audio_manager.gd
class_name AudioManagerClass
extends Node

const _SETTINGS_PATH := "user://audio_settings.json"
const _SFX_BASE := "res://assets/audio/sfx/"
const _BGM_BASE := "res://assets/audio/bgm/"
const _RATE_MS := 50
const _POOL_SIZE := 16
const _BUS_MAP: Dictionary = {"master": "Master", "sfx": "SFX", "music": "Music", "ui": "UI"}

var _pool: Array[AudioStreamPlayer] = []
var _ui_player: AudioStreamPlayer
var _bgm_players: Array[AudioStreamPlayer] = []
var _bgm_cur: int = 0

var _sfx_cache: Dictionary = {}
var _last_ms: Dictionary = {}
var _warned: Dictionary = {}

var _vol: Dictionary = {"master": 1.0, "sfx": 1.0, "music": 0.8, "ui": 1.0}

func _ready() -> void:
	_ensure_buses()
	_build_pool()
	_load_settings()
	_apply_volumes()

func _ensure_buses() -> void:
	for bname: String in ["SFX", "Music", "UI"]:
		if AudioServer.get_bus_index(bname) < 0:
			var idx := AudioServer.get_bus_count()
			AudioServer.add_bus(idx)
			AudioServer.set_bus_name(idx, bname)
			AudioServer.set_bus_send(idx, &"Master")

func _build_pool() -> void:
	for _i in _POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = &"SFX"
		add_child(p)
		_pool.append(p)
	_ui_player = AudioStreamPlayer.new()
	_ui_player.bus = &"UI"
	add_child(_ui_player)
	for _i in 2:
		var p := AudioStreamPlayer.new()
		p.bus = &"Music"
		p.volume_db = -80.0
		add_child(p)
		_bgm_players.append(p)

func _resolve_sfx(key: String) -> AudioStream:
	if _sfx_cache.has(key):
		return _sfx_cache[key]
	for ext: String in [".wav", ".ogg", ".mp3"]:
		var path := _SFX_BASE + key + ext
		if ResourceLoader.exists(path):
			var s := ResourceLoader.load(path) as AudioStream
			_sfx_cache[key] = s
			return s
	if not _warned.get(key, false):
		_warned[key] = true
		push_warning("[AudioManager] SFX 없음: " + key)
	_sfx_cache[key] = null
	return null

func play_sfx(key: String, vol_db: float = 0.0) -> void:
	var now := Time.get_ticks_msec()
	if _last_ms.get(key, 0) + _RATE_MS > now:
		return
	_last_ms[key] = now
	var s := _resolve_sfx(key)
	if s == null:
		return
	for p: AudioStreamPlayer in _pool:
		if not p.playing:
			p.stream = s
			p.volume_db = vol_db
			p.play()
			return

func play_ui(key: String) -> void:
	var s := _resolve_sfx(key)
	if s == null:
		return
	_ui_player.stream = s
	_ui_player.play()

func play_bgm(key: String, fade: float = 1.5) -> void:
	for ext: String in [".ogg", ".wav", ".mp3"]:
		var path := _BGM_BASE + key + ext
		if ResourceLoader.exists(path):
			var nxt := 1 - _bgm_cur
			var prev := _bgm_players[_bgm_cur]
			_bgm_players[nxt].stream = ResourceLoader.load(path)
			_bgm_players[nxt].volume_db = -80.0
			_bgm_players[nxt].play()
			var tw := create_tween().set_parallel(true)
			tw.tween_property(prev, "volume_db", -80.0, fade)
			tw.tween_property(_bgm_players[nxt], "volume_db", 0.0, fade)
			tw.chain().tween_callback(prev.stop)
			_bgm_cur = nxt
			return
	if not _warned.get("bgm_" + key, false):
		_warned["bgm_" + key] = true
		push_warning("[AudioManager] BGM 없음: " + key)

func stop_bgm(fade: float = 1.0) -> void:
	var p := _bgm_players[_bgm_cur]
	if not p.playing:
		return
	var tw := create_tween()
	tw.tween_property(p, "volume_db", -80.0, fade)
	tw.chain().tween_callback(p.stop)

func set_bus_volume(bus_name: String, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx < 0:
		return
	linear = clampf(linear, 0.0, 1.0)
	AudioServer.set_bus_volume_db(idx, linear_to_db(linear) if linear > 0.001 else -80.0)
	_vol[bus_name.to_lower()] = linear
	_save_settings()

func _apply_volumes() -> void:
	for key: String in _BUS_MAP:
		var idx := AudioServer.get_bus_index(_BUS_MAP[key])
		if idx < 0:
			continue
		var linear: float = _vol.get(key, 1.0)
		AudioServer.set_bus_volume_db(idx, linear_to_db(linear) if linear > 0.001 else -80.0)

func _load_settings() -> void:
	if not FileAccess.file_exists(_SETTINGS_PATH):
		return
	var file := FileAccess.open(_SETTINGS_PATH, FileAccess.READ)
	if not file:
		return
	var data = JSON.parse_string(file.get_as_text())
	file.close()
	if data is Dictionary:
		for k: String in data:
			if _vol.has(k):
				_vol[k] = float(data[k])

func _save_settings() -> void:
	var file := FileAccess.open(_SETTINGS_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(_vol))
		file.close()
