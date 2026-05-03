# autoload/audio_manager.gd
class_name AudioManagerClass
extends Node

const _SETTINGS_PATH := "user://audio_settings.json"
const _SFX_BASE := "res://assets/audio/sfx/"
const _BGM_BASE := "res://assets/audio/bgm/"
const _RATE_MS := 50
const _POOL_SIZE := 16
const _BUS_MAP: Dictionary = {"master": "Master", "sfx": "SFX", "music": "Music", "ui": "UI"}
const _BGM_FADE_IN  := 1.0   # 페이드인 시간(초)
const _BGM_FADE_OUT := 1.2   # 페이드아웃 시간(초)

var _pool: Array[AudioStreamPlayer] = []
var _ui_player: AudioStreamPlayer
var _bgm_players: Array[AudioStreamPlayer] = []
var _bgm_cur: int = 0
var _bgm_fadeout_timer: Timer

var _sfx_variants: Dictionary = {}   # key → Array[AudioStream]
var _sfx_rr: Dictionary = {}         # key → 다음 재생 인덱스 (라운드로빈)
var _last_ms: Dictionary = {}
var _warned: Dictionary = {}

var _vol: Dictionary = {"master": 1.0, "sfx": 1.0, "music": 0.8, "ui": 1.0}
var _bgm_base_key: String = ""
var _bgm_category: String = ""
var _bgm_identifier: String = ""
var _bgm_phase: int = 0

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
	_bgm_fadeout_timer = Timer.new()
	_bgm_fadeout_timer.one_shot = true
	_bgm_fadeout_timer.timeout.connect(_on_bgm_fadeout_timer)
	add_child(_bgm_fadeout_timer)

func _resolve_variants(key: String) -> Array:
	if _sfx_variants.has(key):
		return _sfx_variants[key]
	var streams: Array = []
	# key_1, key_2, ... 순서로 존재하는 것까지 로드
	for i in range(1, 10):
		var found := false
		for ext: String in [".wav", ".ogg", ".mp3"]:
			var path := _SFX_BASE + key + "_" + str(i) + ext
			if ResourceLoader.exists(path):
				streams.append(ResourceLoader.load(path) as AudioStream)
				found = true
				break
		if not found:
			break
	# fallback: 번호 없는 단일 파일
	if streams.is_empty():
		for ext: String in [".wav", ".ogg", ".mp3"]:
			var path := _SFX_BASE + key + ext
			if ResourceLoader.exists(path):
				streams.append(ResourceLoader.load(path) as AudioStream)
				break
	if streams.is_empty() and not _warned.get(key, false):
		_warned[key] = true
		push_warning("[AudioManager] SFX 없음: " + key)
	_sfx_variants[key] = streams
	return streams

func play_sfx(key: String, vol_db: float = 0.0) -> void:
	var now := Time.get_ticks_msec()
	if _last_ms.get(key, 0) + _RATE_MS > now:
		return
	_last_ms[key] = now
	var variants := _resolve_variants(key)
	if variants.is_empty():
		return
	var idx: int = _sfx_rr.get(key, 0) % variants.size()
	_sfx_rr[key] = idx + 1
	var s: AudioStream = variants[idx]
	for p: AudioStreamPlayer in _pool:
		if not p.playing:
			p.stream = s
			p.volume_db = vol_db
			p.play()
			return

func play_ui(key: String) -> void:
	var variants := _resolve_variants(key)
	if variants.is_empty():
		return
	var idx: int = _sfx_rr.get(key, 0) % variants.size()
	_sfx_rr[key] = idx + 1
	_ui_player.stream = variants[idx]
	_ui_player.play()

func play_bgm(key: String, fade: float = _BGM_FADE_IN) -> void:
	for ext: String in [".ogg", ".wav", ".mp3"]:
		var path := _BGM_BASE + key + ext
		if ResourceLoader.exists(path):
			_bgm_fadeout_timer.stop()
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
			# 트랙 종료 전 페이드아웃 타이머 설정
			var length: float = _bgm_players[nxt].stream.get_length()
			if length > _BGM_FADE_OUT + fade:
				_bgm_fadeout_timer.start(length - _BGM_FADE_OUT)
			return
	if not _warned.get("bgm_" + key, false):
		_warned["bgm_" + key] = true
		push_warning("[AudioManager] BGM 없음: " + key)

func _on_bgm_fadeout_timer() -> void:
	var p := _bgm_players[_bgm_cur]
	if not p.playing:
		return
	var tw := create_tween()
	tw.tween_property(p, "volume_db", -80.0, _BGM_FADE_OUT)
	tw.chain().tween_callback(p.stop)
	if not _bgm_category.is_empty():
		var cat := _bgm_category
		var ident := _bgm_identifier
		var ph := _bgm_phase
		tw.chain().tween_callback(func(): play_bgm_dynamic(cat, ident, ph))

func play_bgm_dynamic(category: String, identifier: String, phase: int = 0) -> void:
	# category="battle", identifier="greek" → bgm_battle_greek (variant 랜덤)
	# category="boss", identifier="hydra", phase=0 → bgm_boss_hydra
	# category="boss", identifier="hydra", phase=1 → bgm_boss_hydra_p2
	var base_key: String
	if category == "boss":
		var suffix := ""
		if phase == 1: suffix = "_p2"
		elif phase >= 2: suffix = "_p3"
		base_key = "bgm_boss_" + identifier + suffix
	elif identifier.is_empty():
		base_key = "bgm_" + category
	else:
		base_key = "bgm_" + category + "_" + identifier

	# variant 탐색 (base_key_1, _2, ... 랜덤 선택)
	var resolved_key := base_key
	var variant_num := 0
	for i in range(1, 10):
		var candidate := _BGM_BASE + base_key + "_" + str(i)
		var found := false
		for ext: String in [".ogg", ".wav", ".mp3"]:
			if ResourceLoader.exists(candidate + ext):
				found = true
				break
		if found:
			variant_num = i
		else:
			break

	if base_key == _bgm_base_key and _bgm_players[_bgm_cur].playing:
		return

	if variant_num > 0:
		resolved_key = base_key + "_" + str(randi() % variant_num + 1)

	_bgm_base_key = base_key
	_bgm_category = category
	_bgm_identifier = identifier
	_bgm_phase = phase
	play_bgm(resolved_key)

func stop_bgm(fade: float = _BGM_FADE_OUT) -> void:
	_bgm_base_key = ""
	_bgm_category = ""
	_bgm_fadeout_timer.stop()
	var p := _bgm_players[_bgm_cur]
	if not p.playing:
		return
	var tw := create_tween()
	tw.tween_property(p, "volume_db", -80.0, fade)
	tw.chain().tween_callback(p.stop)

func get_bus_volume(bus_name: String) -> float:
	return _vol.get(bus_name.to_lower(), 1.0)

func set_bus_volume(bus_name: String, linear: float) -> void:
	var actual: String = _BUS_MAP.get(bus_name.to_lower(), bus_name)
	var idx := AudioServer.get_bus_index(actual)
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
