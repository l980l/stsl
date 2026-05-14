# scenes/debug/vfx_preview.gd
# VFX 프리뷰 디버그 씬 — 에디터에서 이 씬을 열고 F6로 실행. 게임 진입 없이 모든 VFX 반복 재생.
# 좌측 버튼으로 VFX 선택, 빈 곳 클릭 → 타겟 지점 이동+재생. 시전자/타겟 마커는 드래그 가능.
extends Node2D

const LIGHTNING_BEAM := preload("res://scenes/vfx/lightning_beam.gd")
const ICE_SHARDS := preload("res://scenes/vfx/ice_shards.gd")
const FIRE_BLAST := preload("res://scenes/vfx/fire_blast.gd")
const DEBUFF_HEX := preload("res://scenes/vfx/debuff_hex.gd")

# kind: "impact"=피격 버스트(타겟 위치) / "self"=자기 버프 버스트 / "beam"=시전자→타겟 빔
const VFX_LIST := [
	{"name": "slash",          "kind": "impact", "path": "res://scenes/vfx/slash_particle.tscn"},
	{"name": "blunt",          "kind": "impact", "path": "res://scenes/vfx/blunt_particle.tscn"},
	{"name": "projectile",     "kind": "impact", "path": "res://scenes/vfx/projectile_particle.tscn"},
	{"name": "explosive",      "kind": "impact", "path": "res://scenes/vfx/explosive_particle.tscn"},
	{"name": "poison",         "kind": "impact", "path": "res://scenes/vfx/poison_particle.tscn"},
	{"name": "divine",         "kind": "impact", "path": "res://scenes/vfx/divine_particle.tscn"},
	{"name": "curse",          "kind": "impact", "path": "res://scenes/vfx/curse_particle.tscn"},
	{"name": "default",        "kind": "impact", "path": "res://scenes/vfx/default_particle.tscn"},
	{"name": "heal",           "kind": "self",   "path": "res://scenes/vfx/heal_particle.tscn"},
	{"name": "block",          "kind": "self",   "path": "res://scenes/vfx/block_particle.tscn"},
	{"name": "fire",           "kind": "beam",   "path": "res://scenes/vfx/fire_blast.gd"},
	{"name": "ice",            "kind": "beam",   "path": "res://scenes/vfx/ice_shards.gd"},
	{"name": "lightning_beam", "kind": "beam",   "path": "res://scenes/vfx/lightning_beam.gd"},
	{"name": "debuff",         "kind": "beam",   "path": "res://scenes/vfx/debuff_hex.gd"},
]

var _caster_pos := Vector2(420, 540)
var _target_pos := Vector2(1500, 540)
var _dragging: int = -1  # 0=시전자, 1=타겟, -1=없음
var _auto := false
var _selected: Dictionary = VFX_LIST[VFX_LIST.size() - 1]  # 기본 lightning_beam
var _info: Label

func _ready() -> void:
	# 어두운 배경 — 가산 블렌드 글로우 확인용
	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.05, 0.08)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var panel := VBoxContainer.new()
	panel.position = Vector2(24, 24)
	add_child(panel)

	var title := Label.new()
	title.text = "VFX 버튼 선택 → 빈 곳 클릭으로 타겟 이동+재생   /   [Space] 재생"
	panel.add_child(title)

	var grid := GridContainer.new()
	grid.columns = 5
	panel.add_child(grid)
	for entry in VFX_LIST:
		var b := Button.new()
		b.text = entry["name"]
		b.custom_minimum_size = Vector2(150.0, 0.0)
		b.pressed.connect(_select_and_play.bind(entry))
		grid.add_child(b)

	var auto_btn := CheckBox.new()
	auto_btn.text = "자동 반복 (1.8s)"
	auto_btn.toggled.connect(func(on: bool) -> void: _auto = on)
	panel.add_child(auto_btn)

	_info = Label.new()
	panel.add_child(_info)
	_update_info()

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
		_:
			s += "시전자 마커는 beam 전용 — impact/self는 타겟 위치에서 재생"
	_info.text = s

func _select_and_play(entry: Dictionary) -> void:
	_selected = entry
	_update_info()
	_play(entry)

func _play(entry: Dictionary) -> void:
	match entry["kind"]:
		"beam":
			var fx: Node2D = (load(entry["path"]) as GDScript).new()
			add_child(fx)
			fx.position = Vector2.ZERO
			fx.screen_effect.connect(_preview_flash)
			fx.play(_caster_pos, _target_pos)
		"impact":
			var fx: Node2D = (load(entry["path"]) as PackedScene).instantiate()
			if "autostart" in fx:
				fx.autostart = false
			if "repeat" in fx:
				fx.repeat = false
			add_child(fx)
			fx.global_position = _target_pos
			if entry["name"] == "slash":
				fx.rotation = randf_range(0.0, TAU)
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
