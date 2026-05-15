# autoload/game_settings.gd
# 게임 속도 / 그래픽 옵션 — settings_overlay 의 graphics·gameplay 탭과 연동.
# 변경 즉시 적용 + ConfigFile 저장 (user://game_settings.cfg).
extends Node

# ── 단계 키·값 매핑 (UI 의 segment 인덱스 ↔ 실제 multiplier) ──
const VFX_SPEED_KEYS    := ["fastest", "fast", "normal", "slow"]
const VFX_SPEED_VALUES  := [0.5, 0.75, 1.0, 1.5]
const VFX_SPEED_DEFAULT := "normal"  # 보통

const ANIM_SPEED_KEYS    := ["slow", "normal", "fast", "fastest"]
const ANIM_SPEED_VALUES  := [0.5, 0.7, 1.0, 1.5]  # AnimationPlayer.speed_scale (오름차순)
const ANIM_SPEED_DEFAULT := "fast"  # = 1.0 = 현재 상태

const MONSTER_INTERVAL_KEYS    := ["fastest", "fast", "normal", "slow"]
const MONSTER_INTERVAL_VALUES  := [0.5, 1.0, 1.5, 2.0]
const MONSTER_INTERVAL_DEFAULT := "fast"  # 빠르게 = 현재 turn_interval 0.4 그대로

const PARTICLE_KEYS    := ["minimal", "low", "medium", "high"]
const PARTICLE_VALUES  := [0.1, 0.25, 0.5, 1.0]
const PARTICLE_DEFAULT := "high"  # 상

# 킬캠 — 처치/사망 시 슬로우 + 카메라 줌인 (사용자 옵션, 기본 on)
const KILL_CAM_DEFAULT := true

const _CONFIG_PATH := "user://game_settings.cfg"

# 현재 multiplier 값 (직접 사용)
var vfx_speed_multiplier: float = 1.0
var monster_interval_multiplier: float = 1.0
var anim_speed_multiplier: float = 1.0
var particle_quality: int = 2  # 0=하, 1=중, 2=상

# 현재 segment 키 (UI 가 읽음)
var vfx_speed_key: String = VFX_SPEED_DEFAULT
var anim_speed_key: String = ANIM_SPEED_DEFAULT
var monster_interval_key: String = MONSTER_INTERVAL_DEFAULT
var particle_key: String = PARTICLE_DEFAULT
var kill_cam_enabled: bool = KILL_CAM_DEFAULT

func _ready() -> void:
	load_settings()

# ── setter (segment 키 받음. multiplier 자동 갱신) ──
func set_vfx_speed(key: String) -> void:
	var idx := VFX_SPEED_KEYS.find(key)
	if idx < 0:
		return
	vfx_speed_key = key
	vfx_speed_multiplier = VFX_SPEED_VALUES[idx]

func set_anim_speed(key: String) -> void:
	var idx := ANIM_SPEED_KEYS.find(key)
	if idx < 0:
		return
	anim_speed_key = key
	anim_speed_multiplier = ANIM_SPEED_VALUES[idx]

func set_monster_interval(key: String) -> void:
	var idx := MONSTER_INTERVAL_KEYS.find(key)
	if idx < 0:
		return
	monster_interval_key = key
	monster_interval_multiplier = MONSTER_INTERVAL_VALUES[idx]

func set_particle_quality(key: String) -> void:
	var idx := PARTICLE_KEYS.find(key)
	if idx < 0:
		return
	particle_key = key
	particle_quality = idx

func set_kill_cam_enabled(enabled: bool) -> void:
	kill_cam_enabled = enabled

# ── 적용된 값 조회 (battle_manager 등이 사용) ──
func get_vfx_delay(base: float) -> float:
	return base * vfx_speed_multiplier

func get_monster_interval(base: float) -> float:
	return base * monster_interval_multiplier

func get_anim_scale() -> float:
	return anim_speed_multiplier

func particle_count_scale() -> float:
	return PARTICLE_VALUES[particle_quality]

# ── save / load (ConfigFile) ──
func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("graphics", "particle_quality", particle_key)
	cfg.set_value("gameplay", "vfx_speed", vfx_speed_key)
	cfg.set_value("gameplay", "anim_speed", anim_speed_key)
	cfg.set_value("gameplay", "monster_interval", monster_interval_key)
	cfg.set_value("gameplay", "kill_cam_enabled", kill_cam_enabled)
	cfg.save(_CONFIG_PATH)

func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(_CONFIG_PATH) != OK:
		# 첫 실행 — default 값 적용
		set_particle_quality(PARTICLE_DEFAULT)
		set_vfx_speed(VFX_SPEED_DEFAULT)
		set_anim_speed(ANIM_SPEED_DEFAULT)
		set_monster_interval(MONSTER_INTERVAL_DEFAULT)
		set_kill_cam_enabled(KILL_CAM_DEFAULT)
		return
	set_particle_quality(cfg.get_value("graphics", "particle_quality", PARTICLE_DEFAULT))
	set_vfx_speed(cfg.get_value("gameplay", "vfx_speed", VFX_SPEED_DEFAULT))
	set_anim_speed(cfg.get_value("gameplay", "anim_speed", ANIM_SPEED_DEFAULT))
	set_monster_interval(cfg.get_value("gameplay", "monster_interval", MONSTER_INTERVAL_DEFAULT))
	set_kill_cam_enabled(cfg.get_value("gameplay", "kill_cam_enabled", KILL_CAM_DEFAULT))
