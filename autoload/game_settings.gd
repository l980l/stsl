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

const TURN_INTERVAL_KEYS    := ["fastest", "fast", "normal", "slow"]
const TURN_INTERVAL_VALUES  := [0.5, 1.0, 1.5, 2.0]
const TURN_INTERVAL_DEFAULT := "fast"  # 빠르게 = base turn_interval 0.4 그대로

const PARTICLE_KEYS    := ["minimal", "low", "medium", "high"]
const PARTICLE_VALUES  := [0.1, 0.25, 0.5, 1.0]
const PARTICLE_DEFAULT := "high"  # 상

# 킬캠 — 처치/사망 시 슬로우 + 카메라 줌인 (사용자 옵션, 기본 on)
const KILL_CAM_DEFAULT := true

# 영웅 차례 카메라 줌인 (개체 차례 시스템) — 기본 on
const HERO_ZOOM_DEFAULT := true

# 카메라 줌 속도 (영웅 줌인/줌아웃) — 값이 클수록 빠름. 트윈 시간 = base 0.3s / value
const CAM_ZOOM_SPEED_KEYS    := ["slow", "normal", "fast"]
const CAM_ZOOM_SPEED_VALUES  := [0.6, 1.0, 1.7]  # slow=0.5s / normal=0.3s / fast=0.18s
const CAM_ZOOM_SPEED_DEFAULT := "normal"

# 배경 시스템 v1 — parallax 다중 레이어 + 신화별 팔레트 (M7.5)
const BACKGROUND_DEFAULT := true

const _CONFIG_PATH := "user://game_settings.cfg"

# 현재 multiplier 값 (직접 사용)
var vfx_speed_multiplier: float = 1.0
var turn_interval_multiplier: float = 1.0  # 차례 전환 인터벌 (영웅↔영웅, 영웅↔적, 적↔적 등 모든 전환)
var anim_speed_multiplier: float = 1.0
var particle_quality: int = 2  # 0=하, 1=중, 2=상

# 현재 segment 키 (UI 가 읽음)
var vfx_speed_key: String = VFX_SPEED_DEFAULT
var anim_speed_key: String = ANIM_SPEED_DEFAULT
var turn_interval_key: String = TURN_INTERVAL_DEFAULT
var particle_key: String = PARTICLE_DEFAULT
var kill_cam_enabled: bool = KILL_CAM_DEFAULT
var background_enabled: bool = BACKGROUND_DEFAULT
var hero_zoom_enabled: bool = HERO_ZOOM_DEFAULT
var cam_zoom_speed_key: String = CAM_ZOOM_SPEED_DEFAULT
var cam_zoom_speed_multiplier: float = 1.0

# 설정 변경 시그널 — 변경 즉시 반영 필요한 곳에서 구독
@warning_ignore("unused_signal")
signal hero_zoom_enabled_changed(enabled: bool)

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

func set_turn_interval(key: String) -> void:
	var idx := TURN_INTERVAL_KEYS.find(key)
	if idx < 0:
		return
	turn_interval_key = key
	turn_interval_multiplier = TURN_INTERVAL_VALUES[idx]

func set_particle_quality(key: String) -> void:
	var idx := PARTICLE_KEYS.find(key)
	if idx < 0:
		return
	particle_key = key
	particle_quality = idx

func set_kill_cam_enabled(enabled: bool) -> void:
	kill_cam_enabled = enabled

func set_background_enabled(enabled: bool) -> void:
	background_enabled = enabled

func set_hero_zoom_enabled(enabled: bool) -> void:
	hero_zoom_enabled = enabled
	hero_zoom_enabled_changed.emit(enabled)

func set_cam_zoom_speed(key: String) -> void:
	var idx := CAM_ZOOM_SPEED_KEYS.find(key)
	if idx < 0:
		return
	cam_zoom_speed_key = key
	cam_zoom_speed_multiplier = CAM_ZOOM_SPEED_VALUES[idx]

# ── 적용된 값 조회 (battle_manager 등이 사용) ──
func get_vfx_delay(base: float) -> float:
	return base * vfx_speed_multiplier

func get_turn_interval(base: float) -> float:
	return base * turn_interval_multiplier

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
	cfg.set_value("gameplay", "turn_interval", turn_interval_key)
	cfg.set_value("gameplay", "kill_cam_enabled", kill_cam_enabled)
	cfg.set_value("gameplay", "hero_zoom_enabled", hero_zoom_enabled)
	cfg.set_value("gameplay", "cam_zoom_speed", cam_zoom_speed_key)
	cfg.set_value("graphics", "background_enabled", background_enabled)
	cfg.save(_CONFIG_PATH)

func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(_CONFIG_PATH) != OK:
		# 첫 실행 — default 값 적용
		set_particle_quality(PARTICLE_DEFAULT)
		set_vfx_speed(VFX_SPEED_DEFAULT)
		set_anim_speed(ANIM_SPEED_DEFAULT)
		set_turn_interval(TURN_INTERVAL_DEFAULT)
		set_kill_cam_enabled(KILL_CAM_DEFAULT)
		set_background_enabled(BACKGROUND_DEFAULT)
		set_hero_zoom_enabled(HERO_ZOOM_DEFAULT)
		set_cam_zoom_speed(CAM_ZOOM_SPEED_DEFAULT)
		return
	set_particle_quality(cfg.get_value("graphics", "particle_quality", PARTICLE_DEFAULT))
	set_vfx_speed(cfg.get_value("gameplay", "vfx_speed", VFX_SPEED_DEFAULT))
	set_anim_speed(cfg.get_value("gameplay", "anim_speed", ANIM_SPEED_DEFAULT))
	# 옛 키 "monster_interval" 하위 호환 — 없으면 default
	var ti_key: String = cfg.get_value("gameplay", "turn_interval", cfg.get_value("gameplay", "monster_interval", TURN_INTERVAL_DEFAULT))
	set_turn_interval(ti_key)
	set_kill_cam_enabled(cfg.get_value("gameplay", "kill_cam_enabled", KILL_CAM_DEFAULT))
	set_background_enabled(cfg.get_value("graphics", "background_enabled", BACKGROUND_DEFAULT))
	set_hero_zoom_enabled(cfg.get_value("gameplay", "hero_zoom_enabled", HERO_ZOOM_DEFAULT))
	set_cam_zoom_speed(cfg.get_value("gameplay", "cam_zoom_speed", CAM_ZOOM_SPEED_DEFAULT))
