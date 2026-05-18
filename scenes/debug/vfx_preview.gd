# scenes/debug/vfx_preview.gd
# VFX 프리뷰 디버그 씬 — 에디터에서 이 씬을 열고 F6로 실행. 게임 진입 없이 모든 VFX 반복 재생.
# 좌측 버튼으로 VFX 선택, 빈 곳 클릭 → 타겟 지점 이동+재생. 시전자/타겟 마커는 드래그 가능.
extends Node2D

const LIGHTNING_BEAM := preload("res://scenes/vfx/lightning_beam.gd")
const ICE_SHARDS := preload("res://scenes/vfx/ice_shards.gd")
const FIRE_BLAST := preload("res://scenes/vfx/fire_blast.gd")
const DEBUFF_HEX := preload("res://scenes/vfx/debuff_hex.gd")
const CHARM_KISS := preload("res://scenes/vfx/charm_kiss.gd")
const POISON_SPLASH := preload("res://scenes/vfx/poison_splash.gd")
const DEATH_DISSOLVE := preload("res://scenes/vfx/death_dissolve.gd")
const REVIVE_BLESSING := preload("res://scenes/vfx/revive_blessing.gd")
const HEAL_BLESSING := preload("res://scenes/vfx/heal_blessing.gd")
const BLOOD_SPRAY := preload("res://scenes/vfx/blood_spray.gd")
const HOLY_STRIKE := preload("res://scenes/vfx/holy_strike.gd")
const ARROW_SHOT := preload("res://scenes/vfx/arrow_shot.gd")
const EXPLOSION_BLAST := preload("res://scenes/vfx/explosion_blast.gd")
const BLUNT_SMASH := preload("res://scenes/vfx/blunt_smash.gd")
const STUN_STARS := preload("res://scenes/vfx/stun_stars.gd")
const BULLET_SHOT := preload("res://scenes/vfx/bullet_shot.gd")
const HOLY_SLASH := preload("res://scenes/vfx/holy_slash.gd")
const HOLY_ARROW := preload("res://scenes/vfx/holy_arrow.gd")
const HOLY_FIRE := preload("res://scenes/vfx/holy_fire.gd")
const HOLY_BLUNT := preload("res://scenes/vfx/holy_blunt.gd")
const HOLY_BUFF := preload("res://scenes/vfx/holy_buff.gd")
const WARRIOR_BUFF := preload("res://scenes/vfx/warrior_buff.gd")
const INFATUATION := preload("res://scenes/vfx/infatuation.gd")
const DEFENSE_BUFF := preload("res://scenes/vfx/defense_buff.gd")
const POISON_TICK := preload("res://scenes/vfx/poison_tick.gd")
const SUMMON_BURST := preload("res://scenes/vfx/summon_burst.gd")
const POWER_UP := preload("res://scenes/vfx/power_up.gd")
const SUMMON_CIRCLE := preload("res://scenes/vfx/summon_circle.gd")
const SPEED_BUFF := preload("res://scenes/vfx/speed_buff.gd")
const SLOW_DEBUFF := preload("res://scenes/vfx/slow_debuff.gd")
const TARGET_MARKING := preload("res://scenes/vfx/target_marking.gd")
const MIMIC := preload("res://scenes/vfx/mimic.gd")
const SACRIFICE := preload("res://scenes/vfx/sacrifice.gd")
const COUNTER_PREPARE := preload("res://scenes/vfx/counter_prepare.gd")
const STEAL_CARD := preload("res://scenes/vfx/steal_card.gd")
const PURGE_STATUS := preload("res://scenes/vfx/purge_status.gd")
const MORALE_BOOST := preload("res://scenes/vfx/morale_boost.gd")
const PREPARE := preload("res://scenes/vfx/prepare.gd")
const BOSS_PHASE := preload("res://scenes/vfx/boss_phase_changed.gd")
const SIG_HUBRIS := preload("res://scenes/vfx/sig_hubris.gd")
const SIG_RAGNAROK := preload("res://scenes/vfx/sig_ragnarok.gd")
const SIG_KARMA := preload("res://scenes/vfx/sig_karma.gd")
const SIG_YIN_YANG := preload("res://scenes/vfx/sig_yin_yang.gd")
const SIG_EGYPTIAN_CURSE := preload("res://scenes/vfx/sig_egyptian_curse.gd")
const SIG_KEKKAI := preload("res://scenes/vfx/sig_kekkai.gd")
const TAUNT_VFX := preload("res://scenes/vfx/taunt.gd")
const CARD_EXHAUST := preload("res://scenes/vfx/card_exhaust.gd")
const BOSS_DEATH := preload("res://scenes/vfx/boss_death.gd")
const _CARD_SCENE := preload("res://scenes/card/card_scene.tscn")
const _CardResourceClass := preload("res://resources/card_resource.gd")

# kind: "impact"=피격 버스트(타겟 위치) / "self"=자기 버프 버스트 / "beam"=시전자→타겟 빔
# 현재버전 — 게임에서 실제 사용 중
const VFX_CURRENT := [
	{"name": "slash+blood",    "kind": "impact", "path": "res://scenes/vfx/slash_particle.tscn", "with_blood": true},
	{"name": "fire",           "kind": "beam",   "path": "res://scenes/vfx/fire_blast.gd"},
	{"name": "ice",            "kind": "beam",   "path": "res://scenes/vfx/ice_shards.gd"},
	{"name": "lightning_beam", "kind": "beam",   "path": "res://scenes/vfx/lightning_beam.gd"},
	{"name": "debuff",         "kind": "beam",   "path": "res://scenes/vfx/debuff_hex.gd"},
	{"name": "charm",          "kind": "beam",   "path": "res://scenes/vfx/charm_kiss.gd"},
	{"name": "poison",         "kind": "beam",   "path": "res://scenes/vfx/poison_splash.gd"},
	{"name": "poison_tick",    "kind": "beam",   "path": "res://scenes/vfx/poison_tick.gd"},
	{"name": "death",          "kind": "beam",   "path": "res://scenes/vfx/death_dissolve.gd"},
	{"name": "revive",         "kind": "beam",   "path": "res://scenes/vfx/revive_blessing.gd"},
	{"name": "heal",           "kind": "beam",   "path": "res://scenes/vfx/heal_blessing.gd"},
	{"name": "blood",          "kind": "beam",   "path": "res://scenes/vfx/blood_spray.gd"},
	{"name": "arrow",          "kind": "beam",   "path": "res://scenes/vfx/arrow_shot.gd"},
	{"name": "explosion",      "kind": "beam",   "path": "res://scenes/vfx/explosion_blast.gd"},
	{"name": "blunt",          "kind": "beam",   "path": "res://scenes/vfx/blunt_smash.gd"},
	{"name": "stun",           "kind": "beam",   "path": "res://scenes/vfx/stun_stars.gd"},
	{"name": "bullet",         "kind": "beam",   "path": "res://scenes/vfx/bullet_shot.gd"},
	{"name": "holy_strike",    "kind": "beam",   "path": "res://scenes/vfx/holy_strike.gd"},
	{"name": "holy_slash",     "kind": "beam",   "path": "res://scenes/vfx/holy_slash.gd"},
	{"name": "holy_arrow",     "kind": "beam",   "path": "res://scenes/vfx/holy_arrow.gd"},
	{"name": "holy_fire",      "kind": "beam",   "path": "res://scenes/vfx/holy_fire.gd"},
	{"name": "holy_blunt",     "kind": "beam",   "path": "res://scenes/vfx/holy_blunt.gd"},
	{"name": "holy_buff",      "kind": "beam",   "path": "res://scenes/vfx/holy_buff.gd"},
	{"name": "warrior_buff",   "kind": "beam",   "path": "res://scenes/vfx/warrior_buff.gd"},
	{"name": "infatuation",    "kind": "beam",   "path": "res://scenes/vfx/infatuation.gd"},
	{"name": "defense_buff",   "kind": "beam",   "path": "res://scenes/vfx/defense_buff.gd"},
	{"name": "summon_burst",   "kind": "beam",   "path": "res://scenes/vfx/summon_burst.gd"},
	{"name": "power_up",       "kind": "beam",   "path": "res://scenes/vfx/power_up.gd"},
	{"name": "summon_circle",  "kind": "beam",   "path": "res://scenes/vfx/summon_circle.gd"},
	{"name": "speed_buff",     "kind": "beam",   "path": "res://scenes/vfx/speed_buff.gd"},
	{"name": "slow_debuff",    "kind": "beam",   "path": "res://scenes/vfx/slow_debuff.gd"},
	{"name": "target_marking", "kind": "beam",   "path": "res://scenes/vfx/target_marking.gd"},
	{"name": "mimic",          "kind": "beam",   "path": "res://scenes/vfx/mimic.gd"},
	{"name": "sacrifice",      "kind": "beam",   "path": "res://scenes/vfx/sacrifice.gd"},
	{"name": "counter_prepare","kind": "beam",   "path": "res://scenes/vfx/counter_prepare.gd"},
	{"name": "steal_card",     "kind": "beam",   "path": "res://scenes/vfx/steal_card.gd"},
	{"name": "purge_status",   "kind": "beam",   "path": "res://scenes/vfx/purge_status.gd"},
	{"name": "morale_boost",   "kind": "beam",   "path": "res://scenes/vfx/morale_boost.gd"},
	{"name": "prepare",        "kind": "beam",   "path": "res://scenes/vfx/prepare.gd"},
	{"name": "boss_phase",     "kind": "beam",   "path": "res://scenes/vfx/boss_phase_changed.gd"},
	{"name": "sig_hubris",         "kind": "beam", "path": "res://scenes/vfx/sig_hubris.gd"},
	{"name": "sig_ragnarok",       "kind": "beam", "path": "res://scenes/vfx/sig_ragnarok.gd"},
	{"name": "sig_karma",          "kind": "beam", "path": "res://scenes/vfx/sig_karma.gd"},
	{"name": "sig_yin_yang",       "kind": "beam", "path": "res://scenes/vfx/sig_yin_yang.gd"},
	{"name": "sig_egyptian_curse", "kind": "beam", "path": "res://scenes/vfx/sig_egyptian_curse.gd"},
	{"name": "sig_kekkai",         "kind": "beam", "path": "res://scenes/vfx/sig_kekkai.gd"},
	{"name": "taunt",              "kind": "beam", "path": "res://scenes/vfx/taunt.gd"},
	{"name": "card_exhaust",       "kind": "beam", "path": "res://scenes/vfx/card_exhaust.gd"},
	{"name": "boss_death",         "kind": "beam", "path": "res://scenes/vfx/boss_death.gd"},
]

# 구버전 — 더 이상 사용 X. 참조용으로 vfx_preview 에 표시.
const VFX_LEGACY := [
	{"name": "slash",          "kind": "impact", "path": "res://scenes/vfx/slash_particle.tscn"},
	{"name": "projectile",     "kind": "impact", "path": "res://scenes/vfx/projectile_particle.tscn"},
	{"name": "explosive",      "kind": "impact", "path": "res://scenes/vfx/explosive_particle.tscn"},
	{"name": "curse",          "kind": "impact", "path": "res://scenes/vfx/curse_particle.tscn"},
	{"name": "default",        "kind": "impact", "path": "res://scenes/vfx/default_particle.tscn"},
	{"name": "block",          "kind": "self",   "path": "res://scenes/vfx/block_particle.tscn"},
]

const VFX_LIST := VFX_CURRENT + VFX_LEGACY  # 호환성 유지 (다른 코드가 참조 시)

var _caster_pos := Vector2(420, 540)
var _target_pos := Vector2(1500, 540)
var _dragging: int = -1  # 0=시전자, 1=타겟, -1=없음
var _auto := false
var _selected: Dictionary = VFX_LIST[VFX_LIST.size() - 1]  # 기본 lightning_beam
var _info: Label
var _impact_label: Label  # 임팩트 시점 시각 마커 — VFX 의 screen_effect 콜백
var _compare_4way: bool = false  # 4-way 비교 모드 — 한 번에 x0.1/x0.25/x0.5/x1.0 동시 spawn

func _ready() -> void:
	# 어두운 배경 — 가산 블렌드 글로우 확인용
	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.05, 0.08)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var panel := VBoxContainer.new()
	panel.position = Vector2(24, 8)
	add_child(panel)

	var title := Label.new()
	title.text = "VFX 버튼 선택 → 빈 곳 클릭으로 타겟 이동+재생   /   [Space] 재생"
	panel.add_child(title)

	# 현재버전 (게임에서 실제 사용 중)
	var current_lbl := Label.new()
	current_lbl.text = "── 현재버전 ──"
	current_lbl.add_theme_color_override("font_color", Color(0.7, 1.0, 0.7))
	panel.add_child(current_lbl)
	var grid_current := GridContainer.new()
	grid_current.columns = 15
	panel.add_child(grid_current)
	for entry in VFX_CURRENT:
		var b := Button.new()
		b.text = entry["name"]
		b.custom_minimum_size = Vector2(105.0, 0.0)
		b.pressed.connect(_select_and_play.bind(entry))
		grid_current.add_child(b)

	# 구버전 (더 이상 사용 X — 참조용)
	var legacy_lbl := Label.new()
	legacy_lbl.text = "── 구버전 (사용 X) ──"
	legacy_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	panel.add_child(legacy_lbl)
	var grid_legacy := GridContainer.new()
	grid_legacy.columns = 15
	panel.add_child(grid_legacy)
	for entry in VFX_LEGACY:
		var b := Button.new()
		b.text = entry["name"]
		b.custom_minimum_size = Vector2(105.0, 0.0)
		b.modulate = Color(0.75, 0.75, 0.75)
		b.pressed.connect(_select_and_play.bind(entry))
		grid_legacy.add_child(b)

	var auto_btn := CheckBox.new()
	auto_btn.text = "자동 반복 (1.8s)"
	auto_btn.toggled.connect(func(on: bool) -> void: _auto = on)
	panel.add_child(auto_btn)

	# 파티클 갯수 토글 — 다음 VFX spawn 부터 즉시 반영 (GameSettings.particle_quality)
	var pq_label := Label.new()
	pq_label.text = "파티클 갯수 (현재: %s)" % GameSettings.particle_key
	panel.add_child(pq_label)
	var pq_box := HBoxContainer.new()
	panel.add_child(pq_box)
	for k in GameSettings.PARTICLE_KEYS:
		var idx_str := str(GameSettings.PARTICLE_VALUES[GameSettings.PARTICLE_KEYS.find(k)])
		var pq_btn := Button.new()
		pq_btn.text = "x" + idx_str
		pq_btn.custom_minimum_size = Vector2(80, 0)
		pq_btn.pressed.connect(func() -> void:
			GameSettings.set_particle_quality(k)
			pq_label.text = "파티클 갯수 (현재: %s)" % GameSettings.particle_key
			_update_info())
		pq_box.add_child(pq_btn)

	# 4-way 비교 — 한 번 클릭에 4개 인스턴스 (x0.1 / x0.25 / x0.5 / x1.0) 동시 spawn
	var cmp_btn := CheckBox.new()
	cmp_btn.text = "4-way 비교 (x0.1 | x0.25 | x0.5 | x1.0 동시 spawn)"
	cmp_btn.toggled.connect(func(on: bool) -> void: _compare_4way = on)
	panel.add_child(cmp_btn)

	_info = Label.new()
	panel.add_child(_info)
	_update_info()

	# 임팩트 시점 마커 — 화면 중앙. VFX screen_effect 시점에 표시.
	_impact_label = Label.new()
	_impact_label.text = ""
	_impact_label.add_theme_font_size_override("font_size", 36)
	_impact_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	_impact_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_impact_label.add_theme_constant_override("outline_size", 6)
	_impact_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_impact_label.modulate.a = 0.0
	add_child(_impact_label)

	var t := Timer.new()
	t.wait_time = 1.8
	t.autostart = true
	t.timeout.connect(func() -> void:
		if _auto:
			_play(_selected))
	add_child(t)

	queue_redraw()

func _update_info() -> void:
	var s := "선택: %s (%s)\n" % [_selected["name"], _selected["kind"]]
	match _selected["name"]:
		"lightning_beam":
			s += "차지 오브 scale: %.2f → %.2f → %.2f\n" % [
				LIGHTNING_BEAM.ORB_CHARGE_START, LIGHTNING_BEAM.ORB_CHARGE_FULL, LIGHTNING_BEAM.ORB_FIRE]
			s += "임팩트 scale: %.2f → %.2f → %.2f" % [
				LIGHTNING_BEAM.IMPACT_START, LIGHTNING_BEAM.IMPACT_MID, LIGHTNING_BEAM.IMPACT_END]
		"ice":
			s += "차지 오브 scale: %.2f → %.2f / 바닥 서리: %.2f\n" % [
				ICE_SHARDS.ORB_CHARGE_START, ICE_SHARDS.ORB_CHARGE_FULL, ICE_SHARDS.FROST_FLOOR_SIZE]
			s += "파편 %d발 · 비행 %.2fs · 차지 %.2fs" % [
				ICE_SHARDS.SHARD_COUNT, ICE_SHARDS.SHARD_FLIGHT, ICE_SHARDS.CHARGE_TIME]
		"fire":
			s += "차지 오브 scale: %.2f → %.2f / 포물선 높이: %.0f\n" % [
				FIRE_BLAST.ORB_CHARGE_START, FIRE_BLAST.ORB_CHARGE_FULL, FIRE_BLAST.ARC_HEIGHT]
			s += "차지 %.2fs · 비행 %.2fs · 잔불 %.1fs" % [
				FIRE_BLAST.CHARGE_TIME, FIRE_BLAST.PROJ_FLIGHT, FIRE_BLAST.BURN_TIME]
		"debuff":
			s += "차지 오브 scale: %.2f → %.2f / 발톱 지속: %.2fs\n" % [
				DEBUFF_HEX.ORB_CHARGE_START, DEBUFF_HEX.ORB_CHARGE_FULL, DEBUFF_HEX.CLAW_DUR]
			s += "차지 %.2fs · 디버프 지속 %.1fs" % [
				DEBUFF_HEX.CHARGE_TIME, DEBUFF_HEX.DEBUFF_TIME]
		"charm":
			s += "하트 구체 %.0fpx / 포물선 높이 %.0f · 흔들림 %.0f\n" % [
				CHARM_KISS.ORB_SIZE, CHARM_KISS.ARC_HEIGHT, CHARM_KISS.WOBBLE_AMP]
			s += "차지 %.2fs · 비행 %.2fs · 매혹 잔류 %.1fs" % [
				CHARM_KISS.CHARGE_TIME, CHARM_KISS.PROJ_FLIGHT, CHARM_KISS.CHARM_TIME]
		"poison":
			s += "차지 오브 scale: %.2f → %.2f / 포물선 높이: %.0f\n" % [
				POISON_SPLASH.ORB_CHARGE_START, POISON_SPLASH.ORB_CHARGE_FULL, POISON_SPLASH.ARC_HEIGHT]
			s += "차지 %.2fs · 비행 %.2fs · 잔류 독 %.1fs" % [
				POISON_SPLASH.CHARGE_TIME, POISON_SPLASH.FLASK_FLIGHT, POISON_SPLASH.POISON_TIME]
		"death":
			s += "핏물 웅덩이 반경 %.0f · 확장 %.1fs\n" % [
				DEATH_DISSOLVE.POOL_RADIUS, DEATH_DISSOLVE.POOL_GROW]
			s += "재·영혼 분출 %.1fs (시전자 마커 무시 — 타겟 위치만 사용)" % DEATH_DISSOLVE.DISSOLVE_TIME
		"revive":
			s += "빛기둥 %.0f×%.0f · 강하 %.1fs / 고리 반경 %.0f\n" % [
				REVIVE_BLESSING.PILLAR_WIDTH, REVIVE_BLESSING.PILLAR_HEIGHT,
				REVIVE_BLESSING.PILLAR_TIME, REVIVE_BLESSING.RING_RADIUS]
			s += "잔류 %.1fs (시전자 마커 무시 — 타겟 위치만 사용)" % REVIVE_BLESSING.REVIVE_TIME
		"heal":
			s += "차지 오브 scale: %.2f → %.2f\n" % [
				HEAL_BLESSING.ORB_CHARGE_START, HEAL_BLESSING.ORB_CHARGE_FULL]
			s += "차지 %.1fs · 분출 %.1fs (시전자 마커 무시 — 타겟 위치만 사용)" % [
				HEAL_BLESSING.CHARGE_TIME, HEAL_BLESSING.HEAL_TIME]
		"blood":
			s += "핏방울 %d + 큰 핏방울 %d (slash 명중 시 기존 베기 파티클에 추가 발동)\n" % [
				BLOOD_SPRAY.BLOOD_COUNT, BLOOD_SPRAY.BLOOD_BIG_COUNT]
			s += "시전자 마커 무시 — 타겟 위치만 사용"
		"holy":
			s += "빛기둥 %.0f×%.0f / 글리프 반경 %.0f\n" % [
				HOLY_STRIKE.PILLAR_WIDTH, HOLY_STRIKE.PILLAR_HEIGHT, HOLY_STRIKE.GLYPH_RADIUS]
			s += "채널 %.2fs · 강하 %.2fs · 잔류 %.1fs" % [
				HOLY_STRIKE.CHANNEL_TIME, HOLY_STRIKE.DESCENT_TIME, HOLY_STRIKE.LINGER_TIME]
		"arrow":
			s += "화살 길이 %.0f\n" % ARROW_SHOT.ARROW_LEN
			s += "조준 %.2fs · 비행 %.2fs · 박힌 화살 %.1fs" % [
				ARROW_SHOT.DRAW_TIME, ARROW_SHOT.FLIGHT_TIME, ARROW_SHOT.STUCK_TIME]
		"explosive":
			s += "포물선 높이 %.0f · 폭발 크기 배율 %.2f\n" % [
				EXPLOSION_BLAST.ARC_HEIGHT, EXPLOSION_BLAST.BLAST_SCALE]
			s += "투척 %.2fs · 잔류연기 %.1fs" % [
				EXPLOSION_BLAST.BOMB_FLIGHT, EXPLOSION_BLAST.SMOKE_TIME]
		"blunt":
			s += "준비 %.2fs · 슬램 %.2fs · 흙먼지 배율 %.2f\n" % [
				BLUNT_SMASH.WINDUP_TIME, BLUNT_SMASH.SLAM_TIME, BLUNT_SMASH.DUST_SCALE]
			s += "휘두르기 호 반경 %.0f (시전자 머리 위)" % BLUNT_SMASH.ARC_RADIUS
		"stun":
			s += "머리 위 별 3개 회전 — 추후 스턴 상태이상에 사용 예정\n"
			s += "회전 주기 %.1fs · 표시 %.1fs (시전자 마커 무시)" % [
				TAU / STUN_STARS.ROT_SPEED, STUN_STARS.STUN_TIME]
		"bullet":
			s += "조준 %.2fs · 비행 %.2fs · 탄흔 %.1fs" % [
				BULLET_SHOT.DRAW_TIME, BULLET_SHOT.FLIGHT_TIME, BULLET_SHOT.HOLE_TIME]
		"holy_slash":
			s += "후광 반경 %.0f · 깃털 %d개 (피 대신 분출)\n" % [
				HOLY_SLASH.HALO_RADIUS, HOLY_SLASH.FEATHER_COUNT]
			s += "채널 %.2fs · 베기는 기본 slash + 깃털" % HOLY_SLASH.CHANNEL_TIME
		"holy_arrow":
			s += "후광 반경 %.0f · 화살 머리는 가로 십자가\n" % HOLY_ARROW.HALO_RADIUS
			s += "조준 %.2fs · 비행 %.2fs · 박힘 %.1fs (명중: 스파크 + 작은 안개 + 박힌 십자가)" % [
				HOLY_ARROW.DRAW_TIME, HOLY_ARROW.FLIGHT_TIME, HOLY_ARROW.STUCK_TIME]
		"holy_fire":
			s += "황금 화염 변종 (fire 색만 바꿈)\n"
			s += "차지 %.2fs · 비행 %.2fs · 잔불 %.1fs" % [
				HOLY_FIRE.CHARGE_TIME, HOLY_FIRE.PROJ_FLIGHT, HOLY_FIRE.BURN_TIME]
		"holy_blunt":
			s += "황금 둔기 변종 (blunt 색만 바꿈) · 흙먼지 배율 %.2f\n" % HOLY_BLUNT.DUST_SCALE
			s += "준비 %.2fs · 슬램 %.2fs · 휘두르기 호 반경 %.0f" % [
				HOLY_BLUNT.WINDUP_TIME, HOLY_BLUNT.SLAM_TIME, HOLY_BLUNT.ARC_RADIUS]
		"holy_buff":
			s += "빛기둥 %.0fx%.0f · 룬링 반경 %.0f\n" % [
				HOLY_BUFF.PILLAR_WIDTH, HOLY_BUFF.PILLAR_HEIGHT, HOLY_BUFF.RING_RADIUS]
			s += "차지 %.2fs · 버프 지속 %.1fs (시전자 마커 무시 — 타겟 위치만 사용)" % [
				HOLY_BUFF.CHARGE_TIME, HOLY_BUFF.BUFF_TIME]
		"warrior_buff":
			s += "분노 오라 %.0fx%.0f · 가시링 반경 %.0f · 충격파 %.2fs\n" % [
				WARRIOR_BUFF.AURA_WIDTH, WARRIOR_BUFF.AURA_HEIGHT,
				WARRIOR_BUFF.RING_RADIUS, WARRIOR_BUFF.SHOCK_TIME]
			s += "차지 %.2fs · 버프 지속 %.1fs (시전자 마커 무시 — 타겟 위치만 사용)" % [
				WARRIOR_BUFF.CHARGE_TIME, WARRIOR_BUFF.BUFF_TIME]
		"infatuation":
			s += "fan 하트 %d개 + 큰 키스 — 비행 %.2fs\n" % [
				INFATUATION.FAN_COUNT, INFATUATION.FLIGHT_TIME]
			s += "차지 %.2fs · 반함 지속 %.1fs (만다라/체인/오라)" % [
				INFATUATION.CHARGE_TIME, INFATUATION.BUFF_TIME]
		"defense_buff":
			s += "6각 패널 dome 반경 %.0f · 룬링 반경 %.0f\n" % [
				DEFENSE_BUFF.PANEL_DIST, DEFENSE_BUFF.RING_RADIUS]
			s += "차지 %.2fs · 버프 지속 %.1fs (시전자 마커 무시)" % [
				DEFENSE_BUFF.CHARGE_TIME, DEFENSE_BUFF.BUFF_TIME]
		"poison_tick":
			s += "독 DoT tick — 잔류 가스만 (poison_splash 의 ambient 추출)\n"
			s += "지속 %.1fs · sfx=impact_poison · 시전자 마커 무시" % POISON_TICK.TICK_TIME
		"summon_burst":
			s += "병사 소환 — callRing 반경 %.0f · pillar %.0fx%.0f\n" % [
				SUMMON_BURST.RING_MAX_R, SUMMON_BURST.PILLAR_W, SUMMON_BURST.PILLAR_H]
			s += "차지 %.2fs · pillar 지속 %.2fs (타겟 좌우 3슬롯 자동 spawn)" % [
				SUMMON_BURST.CHARGE_TIME, SUMMON_BURST.PILLAR_GROW + SUMMON_BURST.PILLAR_HOLD + SUMMON_BURST.PILLAR_FADE]
		"power_up":
			s += "힘 모으기 — aura %.0fx%.0f · streak %.0fx%.0f (8개)\n" % [
				POWER_UP.AURA_W, POWER_UP.AURA_H, POWER_UP.STREAK_W, POWER_UP.STREAK_H]
			s += "차지 %.2fs · hold %.2fs · fade %.2fs (시전자 마커 무시 — 타겟 위치 중심)" % [
				POWER_UP.CHARGE_TIME, POWER_UP.HOLD_TIME, POWER_UP.FADE_TIME]
		"summon_circle":
			s += "소환 — 외곽 마법진 반경 %.0f · pillar %.0fx%.0f\n" % [
				SUMMON_CIRCLE.CIRCLE_R, SUMMON_CIRCLE.PILLAR_W, SUMMON_CIRCLE.PILLAR_H]
			s += "채널 %.2fs · peak %.2fs · hold %.2fs · fade %.2fs (시전자 마커 무시 — 타겟 위치 발치)" % [
				SUMMON_CIRCLE.CHANNEL_TIME, SUMMON_CIRCLE.PEAK_DELAY, SUMMON_CIRCLE.HOLD_TIME, SUMMON_CIRCLE.FADE_TIME]
		"speed_buff":
			s += "속도 버프 — chevron ring 반경 %.0f · orb offset %.0f\n" % [
				SPEED_BUFF.RING_RADIUS, SPEED_BUFF.ORB_OFFSET_Y]
			s += "차지 %.2fs · buff %.2fs · fade %.2fs (시전자 마커 무시 — 타겟 위치)" % [
				SPEED_BUFF.CHARGE_TIME, SPEED_BUFF.BUFF_TIME, SPEED_BUFF.FADE_TIME]
		"slow_debuff":
			s += "속도 감소 — goop %.0fx%.0f · 역chevron ring 반경 %.0f\n" % [
				SLOW_DEBUFF.GOOP_W, SLOW_DEBUFF.GOOP_H, SLOW_DEBUFF.RING_RADIUS]
			s += "차지 %.2fs · debuff %.2fs · fade %.2fs (시전자 마커 무시 — 타겟 위치 발치)" % [
				SLOW_DEBUFF.CHARGE_TIME, SLOW_DEBUFF.DEBUFF_TIME, SLOW_DEBUFF.FADE_TIME]
		"target_marking":
			s += "타겟 마킹 — reticle 반경 %.0f · bracket %.0fx%.0f\n" % [
				TARGET_MARKING.RETICLE_R, TARGET_MARKING.BRACKET_W, TARGET_MARKING.BRACKET_H]
			s += "차지 %.2fs · travel %.2fs · hold %.2fs · fade %.2fs (시전자→타겟 tracer + lock)" % [
				TARGET_MARKING.CHARGE_TIME, TARGET_MARKING.TRAVEL_TIME, TARGET_MARKING.HOLD_TIME, TARGET_MARKING.FADE_TIME]
		"mimic":
			s += "메아리 반사 — source pulse 반경 %.0f · ripple %.2fs\n" % [
				MIMIC.SOURCE_R, MIMIC.RIPPLE_TIME]
			s += "채널 %.2fs · arc ramp %.2fs · peak %.2fs · hold %.2fs · fade %.2fs (시전자↔타겟 mirror arc)" % [
				MIMIC.CHANNEL_TIME, MIMIC.ARC_RAMP, MIMIC.PEAK_DELAY, MIMIC.HOLD_TIME, MIMIC.FADE_TIME]
		"sacrifice":
			s += "자해 강화 — spiral 반경 %.0f · column %.0fx%.0f · sigil 반경 %.0f\n" % [
				SACRIFICE.SPIRAL_R, SACRIFICE.COLUMN_W, SACRIFICE.COLUMN_H, SACRIFICE.SIGIL_R]
			s += "차지 %.2fs · slash %.2fs · hold %.2fs · fade %.2fs (시전자 마커 무시 — 타겟 위치)" % [
				SACRIFICE.CHARGE_TIME, SACRIFICE.IMPACT_DELAY, SACRIFICE.HOLD_TIME, SACRIFICE.FADE_TIME]
		"counter_prepare":
			s += "반사 준비 — shield %.0fx%.0f · ring 반경 %.0f · sigil 반경 %.0f\n" % [
				COUNTER_PREPARE.SHIELD_W, COUNTER_PREPARE.SHIELD_H, COUNTER_PREPARE.RING_RADIUS, COUNTER_PREPARE.SIGIL_R]
			s += "차지 %.2fs · assemble %.2fs · hold %.2fs · fade %.2fs (시전자 마커 무시 — 타겟 위치)" % [
				COUNTER_PREPARE.CHARGE_TIME, COUNTER_PREPARE.IMPACT_DELAY, COUNTER_PREPARE.HOLD_TIME, COUNTER_PREPARE.FADE_TIME]
		"steal_card":
			s += "카드 빼앗기 — card %.0fx%.0f · mark 반경 %.0f · hook 반경 %.0f\n" % [
				STEAL_CARD.CARD_W, STEAL_CARD.CARD_H, STEAL_CARD.MARK_R, STEAL_CARD.HOOK_R]
			s += "mark %.2fs · flight %.2fs · catch %.2fs · hold %.2fs · fade %.2fs (caster=적, target=영웅)" % [
				STEAL_CARD.CHARGE_TIME, STEAL_CARD.FLIGHT_TIME, STEAL_CARD.IMPACT_DELAY, STEAL_CARD.HOLD_TIME, STEAL_CARD.FADE_TIME]
		"purge_status":
			s += "디버프 정화 — core 반경 %.0f · ring %.0f · pillar %.0fx%.0f · halo %.0fx%.0f\n" % [
				PURGE_STATUS.CORE_R, PURGE_STATUS.RING_RADIUS, PURGE_STATUS.PILLAR_W, PURGE_STATUS.PILLAR_H, PURGE_STATUS.HALO_W, PURGE_STATUS.HALO_H]
			s += "차지 %.2fs · wave %.2fs · hold %.2fs · fade %.2fs (시전자 마커 무시 — 타겟 위치)" % [
				PURGE_STATUS.CHARGE_TIME, PURGE_STATUS.IMPACT_DELAY, PURGE_STATUS.HOLD_TIME, PURGE_STATUS.FADE_TIME]
		"morale_boost":
			s += "사기 진작 — ring %.0f · sunburst ray %d × %.0f · flag %.0fx%.0f · sigil %.0f\n" % [
				MORALE_BOOST.RING_RADIUS, MORALE_BOOST.SUNBURST_RAYS, MORALE_BOOST.SUNBURST_R, MORALE_BOOST.FLAG_W, MORALE_BOOST.FLAG_H, MORALE_BOOST.SIGIL_R]
			s += "차지 %.2fs · trumpet %.2fs · hold %.2fs · fade %.2fs (시전자 마커 무시 — 타겟 위치)" % [
				MORALE_BOOST.CHARGE_TIME, MORALE_BOOST.IMPACT_DELAY, MORALE_BOOST.HOLD_TIME, MORALE_BOOST.FADE_TIME]
		"prepare":
			s += "준비 (효과 없는 빈 턴) — orb 반경 %.0f · ring %.0f · glyph %.0f · wash %.0f\n" % [
				PREPARE.ORB_R, PREPARE.RING_RADIUS, PREPARE.GLYPH_R, PREPARE.WASH_R]
			s += "차지 %.2fs · brew %.2fs · fade %.2fs (절제된 차분 VFX, screen_effect emit X)" % [
				PREPARE.CHARGE_TIME, PREPARE.BREW_TIME, PREPARE.FADE_TIME]
		"boss_phase":
			s += "보스 페이즈 전환 — ring %.0f · aura %.0f · core %.0f\n" % [
				BOSS_PHASE.RING_RADIUS, BOSS_PHASE.AURA_R, BOSS_PHASE.CORE_R]
			s += "build %.2fs · erupt %.2fs · hold %.2fs · fade %.2fs (큰 폭발 + 4겹 shockwave + 화면 flash·shake)" % [
				BOSS_PHASE.BUILD_TIME, BOSS_PHASE.IMPACT_DELAY, BOSS_PHASE.HOLD_TIME, BOSS_PHASE.FADE_TIME]
		"sig_hubris":
			s += "그리스 휴브리스 — halo 반경 %.0f · rage ring %.0f · head offset %.0f\n" % [
				SIG_HUBRIS.HALO_R, SIG_HUBRIS.RAGE_R, SIG_HUBRIS.HEAD_OFFSET]
			s += "strike %.2fs · rage %.2fs · hold %.2fs · fade %.2fs (적 25+ 피해 → 황금 halo + zigzag 번개)" % [
				SIG_HUBRIS.IMPACT_DELAY, SIG_HUBRIS.RAGE_DELAY, SIG_HUBRIS.HOLD_TIME, SIG_HUBRIS.FADE_TIME]
		"sig_ragnarok":
			s += "북유럽 라그나로크 — ember spawn 반경 %.0f (화면 broadcast)\n" % SIG_RAGNAROK.SPAWN_W
			s += "impact %.2fs · hold %.2fs · fade %.2fs (HP 30% 미만 → 바닥 ember 상승만)" % [
				SIG_RAGNAROK.IMPACT_DELAY, SIG_RAGNAROK.HOLD_TIME, SIG_RAGNAROK.FADE_TIME]
		"sig_karma":
			s += "불교 인과응보 — lotus 반경 %.0f · ring %.0f · halo %.0f\n" % [
				SIG_KARMA.LOTUS_R, SIG_KARMA.RING_R, SIG_KARMA.HALO_R]
			s += "bloom %.2fs · rings %.2fs · beams %.2fs · hold %.2fs · fade %.2fs (시체→영웅 다중 빔)" % [
				SIG_KARMA.BLOOM_DELAY, SIG_KARMA.RINGS_DELAY, SIG_KARMA.BEAMS_DELAY, SIG_KARMA.HOLD_TIME, SIG_KARMA.FADE_TIME]
		"sig_yin_yang":
			s += "도교 음양 — 태극 반경 %.0f · head offset %.0f\n" % [
				SIG_YIN_YANG.TAIJI_R, SIG_YIN_YANG.HEAD_OFFSET]
			s += "spin %.2fs · hold %.2fs · fade %.2fs (매 턴 발동 — 회전 태극 glyph, SFX 없음)" % [
				SIG_YIN_YANG.IMPACT_DELAY, SIG_YIN_YANG.HOLD_TIME, SIG_YIN_YANG.FADE_TIME]
		"sig_egyptian_curse":
			s += "이집트 저주 — horus %.0fx%.0f · head offset %.0f\n" % [
				SIG_EGYPTIAN_CURSE.HORUS_W, SIG_EGYPTIAN_CURSE.HORUS_H, SIG_EGYPTIAN_CURSE.HEAD_OFFSET]
			s += "stamp %.2fs · hold %.2fs · fade %.2fs (모든 공격 적중 — 호루스 눈 + 상형문자)" % [
				SIG_EGYPTIAN_CURSE.STAMP_DELAY, SIG_EGYPTIAN_CURSE.HOLD_TIME, SIG_EGYPTIAN_CURSE.FADE_TIME]
		"sig_kekkai":
			s += "일본 결계 — hex 반경 %.0f · ofuda %.0fx%.0f × 4 (NWSE)\n" % [
				SIG_KEKKAI.HEX_R, SIG_KEKKAI.OFUDA_W, SIG_KEKKAI.OFUDA_H]
			s += "ofuda %.2fs · barrier %.2fs · kanji %.2fs · hold %.2fs · fade %.2fs (매 5턴 — 4 부적 + 6각 결계)" % [
				SIG_KEKKAI.OFUDA_DELAY, SIG_KEKKAI.BARRIER_DELAY, SIG_KEKKAI.KANJI_DELAY, SIG_KEKKAI.HOLD_TIME, SIG_KEKKAI.FADE_TIME]
		"taunt":
			s += "도발 — shockwave 3중 · glyph 반경 %.0f · word offset Y %.0f\n" % [
				TAUNT_VFX.GLYPH_R, TAUNT_VFX.WORD_OFFSET_Y]
			s += "windup %.2fs · impact %.2fs · hold %.2fs · fade %.2fs (적 DEBUFF taunt → 영웅 SINGLE 카드 lock, 발치 anchor 적용)" % [
				TAUNT_VFX.WINDUP_TIME, TAUNT_VFX.IMPACT_DELAY, TAUNT_VFX.HOLD_TIME, TAUNT_VFX.FADE_TIME]
		"card_exhaust":
			s += "카드 소진 — 카드 %.0fx%.0f · sweep %.2fs (위→아래 ember line + 잿불 + 회색 재)\n" % [
				CARD_EXHAUST.CARD_W, CARD_EXHAUST.CARD_H, CARD_EXHAUST.SWEEP_TIME]
			s += "impact %.2fs · hold %.2fs · fade %.2fs (preview 에선 더미 카드 표시 → fade out)" % [
				CARD_EXHAUST.IMPACT_DELAY, CARD_EXHAUST.HOLD_TIME, CARD_EXHAUST.FADE_TIME]
		"boss_death":
			s += "보스 사망 — boss %.0fx%.0f · shock %.2fs · pillar %.2fs\n" % [
				BOSS_DEATH.BOSS_W, BOSS_DEATH.BOSS_H, BOSS_DEATH.SHOCK_TIME, BOSS_DEATH.PILLAR_TIME]
			s += "crack 0s → inhale %.2fs → impact %.2fs → crown %.2fs → slate %.2fs · hold %.2fs · fade %.2fs" % [
				BOSS_DEATH.INHALE_DELAY, BOSS_DEATH.IMPACT_DELAY, BOSS_DEATH.CROWN_DELAY,
				BOSS_DEATH.SLATE_DELAY, BOSS_DEATH.HOLD_TIME, BOSS_DEATH.FADE_TIME]
		_:
			s += "시전자 마커는 beam 전용 — impact/self는 타겟 위치에서 재생"
	# IMPACT_DELAY 한 줄 자동 추가 — VFX 스크립트에 노출돼 있으면 표시 (battle_manager 가 동기화에 사용)
	if _selected.get("kind", "") == "beam":
		var script: GDScript = load(_selected["path"]) as GDScript
		if script and "IMPACT_DELAY" in script:
			s += "\n⏱ 임팩트 시점: %.2fs (이때 데미지/SFX 적용)" % script.IMPACT_DELAY
		# 파티클 갯수 적용 여부 — 스크립트에 _pcount 메서드 정의돼 있는지
		if script:
			var has_pcount: bool = false
			for m in script.get_script_method_list():
				if m["name"] == "_pcount":
					has_pcount = true
					break
			if has_pcount:
				s += "\n🎚 파티클 갯수 적용 ✓ — 현재 %s (x%s)" % [GameSettings.particle_key, str(GameSettings.particle_count_scale())]
			else:
				s += "\n🎚 파티클 갯수 미적용 (단일 spawn / 폴리곤 점)"
	_info.text = s

func _select_and_play(entry: Dictionary) -> void:
	_selected = entry
	_update_info()
	_play(entry)

func _play(entry: Dictionary) -> void:
	match entry["kind"]:
		"beam":
			var script: GDScript = load(entry["path"]) as GDScript
			if _compare_4way:
				# 4개 인스턴스 동시 spawn — 각 다른 _particle_scale_override + 화면 가로 4분할
				var x_offsets := [-540.0, -180.0, 180.0, 540.0]
				var scales    := [0.1, 0.25, 0.5, 1.0]
				for i in 4:
					var fx_n: Node2D = script.new()
					add_child(fx_n)
					fx_n.position = Vector2.ZERO
					if "_particle_scale_override" in fx_n:
						fx_n.set("_particle_scale_override", scales[i])
					var t_pos: Vector2 = _target_pos + Vector2(x_offsets[i], 0.0)
					var c_pos: Vector2 = _caster_pos + Vector2(x_offsets[i], 0.0)
					# 시전자 마커 무시, 타겟 위치를 중심·발치로
					if entry["name"] in ["power_up", "summon_circle", "speed_buff", "slow_debuff", "sacrifice", "counter_prepare", "purge_status", "morale_boost", "prepare", "boss_phase", "sig_hubris", "sig_ragnarok", "sig_yin_yang", "sig_egyptian_curse", "sig_kekkai", "taunt", "boss_death"]:
						c_pos = t_pos
						if fx_n.has_method("set_ground_anchor"):
							fx_n.set_ground_anchor(t_pos)
					# target_marking / mimic / steal_card 은 caster→target 둘 다 사용 — 타겟 발치만 anchor
					elif entry["name"] in ["target_marking", "mimic", "steal_card"] and fx_n.has_method("set_ground_anchor"):
						fx_n.set_ground_anchor(t_pos)
					if i == 2:
						# x0.5 인스턴스만 임팩트 마커 (4개가 거의 동시 발동 — 라벨은 1개)
						fx_n.screen_effect.connect(_preview_flash)
						fx_n.screen_effect.connect(_show_impact_marker.bind("%s — 4way" % entry["name"]))
					fx_n.play(c_pos, t_pos)
					_spawn_compare_label(t_pos, "x" + str(scales[i]))
			else:
				var fx: Node2D = script.new()
				add_child(fx)
				fx.position = Vector2.ZERO
				fx.screen_effect.connect(_preview_flash)
				fx.screen_effect.connect(_show_impact_marker.bind(entry["name"]))
				# summon_burst — 타겟을 중심으로 좌우 3 슬롯 자동 spawn (실제 게임에선 토큰 그리드 좌표)
				if entry["name"] == "summon_burst" and fx.has_method("set_spawn_positions"):
					fx.set_spawn_positions([
						_target_pos + Vector2(-130.0, 0.0),
						_target_pos,
						_target_pos + Vector2(130.0, 0.0),
					])
				# card_exhaust — 실제 게임 CardScene + CardResource 표시 (타겟 위치) + VFX 위에. 카드는 fade out.
				if entry["name"] == "card_exhaust":
					var dummy := _make_dummy_card(_target_pos)
					add_child(dummy)
					var card_size: Vector2 = dummy.size
					if card_size == Vector2.ZERO:
						card_size = Vector2(180.0, 250.0)
					dummy.position = _target_pos - card_size * 0.5
					if fx.has_method("set_card_size"):
						fx.set_card_size(card_size)
					fx.play(_target_pos, _target_pos)
					# IMPACT_DELAY 후 카드 alpha tween (sweep 따라 fade)
					var tw := create_tween()
					tw.tween_interval(CARD_EXHAUST.IMPACT_DELAY)
					tw.tween_property(dummy, "modulate:a", 0.0, CARD_EXHAUST.SWEEP_TIME)
					tw.tween_callback(dummy.queue_free)
					return
				# 시전자 마커 무시, 타겟 위치를 중심·발치로
				if entry["name"] in ["power_up", "summon_circle", "speed_buff", "slow_debuff", "sacrifice", "counter_prepare", "purge_status", "morale_boost", "prepare", "boss_phase", "sig_hubris", "sig_ragnarok", "sig_yin_yang", "sig_egyptian_curse", "sig_kekkai", "taunt", "boss_death"]:
					if fx.has_method("set_ground_anchor"):
						fx.set_ground_anchor(_target_pos)
					fx.play(_target_pos, _target_pos)
				else:
					# target_marking / mimic / steal_card 은 caster→target 둘 다 사용 — 타겟 발치만 anchor
					if entry["name"] in ["target_marking", "mimic", "steal_card"] and fx.has_method("set_ground_anchor"):
						fx.set_ground_anchor(_target_pos)
					fx.play(_caster_pos, _target_pos)
		"impact":
			var packed := load(entry["path"]) as PackedScene
			if _compare_4way:
				# PackedScene (GPUParticles2D) 의 amount 를 인스턴스별로 스케일
				var x_offsets := [-540.0, -180.0, 180.0, 540.0]
				var scales    := [0.1, 0.25, 0.5, 1.0]
				for i in 4:
					var fx_n: Node2D = packed.instantiate()
					if "autostart" in fx_n:
						fx_n.autostart = false
					if "repeat" in fx_n:
						fx_n.repeat = false
					add_child(fx_n)
					var t_pos: Vector2 = _target_pos + Vector2(x_offsets[i], 0.0)
					fx_n.global_position = t_pos
					_scale_packed_amounts(fx_n, scales[i])
					var slash_rot_n := randf_range(0.0, TAU)
					if entry.get("with_blood", false):
						fx_n.rotation = slash_rot_n
						var blood_n: Node2D = BLOOD_SPRAY.new()
						add_child(blood_n)
						blood_n.position = Vector2.ZERO
						blood_n.play(t_pos, t_pos, slash_rot_n)
					elif entry["name"] == "slash":
						fx_n.rotation = slash_rot_n
					fx_n.burst()
					_spawn_compare_label(t_pos, "x" + str(scales[i]))
			else:
				var fx: Node2D = packed.instantiate()
				if "autostart" in fx:
					fx.autostart = false
				if "repeat" in fx:
					fx.repeat = false
				add_child(fx)
				fx.global_position = _target_pos
				var slash_rot := randf_range(0.0, TAU)
				if entry.get("with_blood", false):
					fx.rotation = slash_rot
					# battle_scene과 동일하게 slash는 피 분출을 베기 방향으로 추가 발동
					var blood: Node2D = BLOOD_SPRAY.new()
					add_child(blood)
					blood.position = Vector2.ZERO
					blood.play(_target_pos, _target_pos, slash_rot)
				elif entry["name"] == "slash":
					fx.rotation = slash_rot
				fx.burst()
		"self":
			var fx: Node2D = (load(entry["path"]) as PackedScene).instantiate()
			if "autostart" in fx:
				fx.autostart = false
			if "repeat" in fx:
				fx.repeat = false
			add_child(fx)
			fx.global_position = _target_pos
			fx.burst()
			var shield := fx.get_node_or_null("ShieldIcon")
			if shield:
				shield.play_shield()

# 4-way 비교 모드 — PackedScene (GPUParticles2D/CPUParticles2D) 의 amount 를 scale 곱셈
# 재귀적으로 자식 모두 — slash_particle 같은 BurstParticleGroup 의 4개 노드 일괄 적용
func _scale_packed_amounts(node: Node, scale: float) -> void:
	if node is GPUParticles2D:
		(node as GPUParticles2D).amount = maxi(1, int(round((node as GPUParticles2D).amount * scale)))
	elif node is CPUParticles2D:
		(node as CPUParticles2D).amount = maxi(1, int(round((node as CPUParticles2D).amount * scale)))
	for child in node.get_children():
		_scale_packed_amounts(child, scale)

# 4-way 비교 모드 — 각 타겟 위 라벨 (x0.1/x0.25/x0.5/x1.0). VFX 지속 시간만큼 페이드아웃.
func _spawn_compare_label(target_pos: Vector2, text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 28)
	lbl.add_theme_color_override("font_color", Color(0.85, 1.0, 0.85))
	lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	lbl.add_theme_constant_override("outline_size", 4)
	lbl.position = target_pos + Vector2(-40.0, -180.0)
	lbl.size = Vector2(80, 40)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(lbl)
	var tw := create_tween()
	tw.tween_interval(2.5)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.5)
	tw.tween_callback(lbl.queue_free)

func _show_impact_marker(vfx_name: String) -> void:
	_impact_label.text = "💥 IMPACT — %s\n(데미지/SFX 적용 시점)" % vfx_name
	_impact_label.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(_impact_label, "modulate:a", 1.0, 0.05)
	tw.tween_interval(0.7)
	tw.tween_property(_impact_label, "modulate:a", 0.0, 0.3)

func _preview_flash() -> void:
	var r := ColorRect.new()
	r.color = Color(0.86, 0.92, 1.0)
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.modulate.a = 0.0
	add_child(r)
	var tw := create_tween()
	tw.tween_property(r, "modulate:a", 0.6, 0.03)
	tw.tween_property(r, "modulate:a", 0.0, 0.3)
	tw.tween_callback(r.queue_free)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		_play(_selected)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var m := get_global_mouse_position()
			if m.distance_to(_caster_pos) < 30.0:
				_dragging = 0
			elif m.distance_to(_target_pos) < 30.0:
				_dragging = 1
			else:
				_target_pos = m
				queue_redraw()
				_play(_selected)
		else:
			_dragging = -1
	elif event is InputEventMouseMotion and _dragging >= 0:
		if _dragging == 0:
			_caster_pos = get_global_mouse_position()
		else:
			_target_pos = get_global_mouse_position()
		queue_redraw()

func _draw() -> void:
	draw_circle(_caster_pos, 14.0, Color(1.0, 0.8, 0.3, 0.9))
	draw_circle(_target_pos, 14.0, Color(1.0, 0.4, 0.4, 0.9))
	var font := ThemeDB.fallback_font
	draw_string(font, _caster_pos + Vector2(-22.0, -22.0), "시전자", HORIZONTAL_ALIGNMENT_LEFT, -1, 16)
	draw_string(font, _target_pos + Vector2(-16.0, -22.0), "타겟", HORIZONTAL_ALIGNMENT_LEFT, -1, 16)

# card_exhaust preview 용 — 실제 게임 CardScene + CardResource 인스턴스 (게임 프레임 그대로)
func _make_dummy_card(center: Vector2) -> Control:
	var card_res = _CardResourceClass.new()
	card_res.card_name = "card.napoleon.strike"   # 번역 키 — 폴백으로 키 표시
	card_res.cost = 2
	card_res.card_type = _CardResourceClass.CardType.ATTACK
	card_res.rarity = _CardResourceClass.Rarity.RARE
	card_res.is_exhaust = true
	card_res.description = "EXHAUST 데모"
	card_res.owner_id = "napoleon"
	var card: Control = _CARD_SCENE.instantiate()
	card.setup(card_res, CardScene.Mode.HAND)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# 위치는 호출자에서 size 확인 후 재조정
	card.position = center
	return card
