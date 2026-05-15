# scenes/vfx/defense_buff.gd
# 방어도 버프 VFX — ui_sample/vfx/Defense Buff VFX.html 재현 (스탯·카운터·파티클 제외).
# 영웅이 BLOCK 획득 시 .new() → add_child → play(target, target). 첫 인자는 무시.
# 빈번 발동 (defend 등) — 짧고 가볍게 (CHARGE 0.3 + BUFF 1.2). 파티클 없이 기하 도형만.
extends Node2D

const COL_HOT  := Color(1.0, 1.0, 1.0)
const COL_MID  := Color(0.659, 0.816, 1.0)   # #a8d0ff — 강철 파랑
const COL_DEEP := Color(0.165, 0.420, 0.690) # #2a6bb0

const ORB_OFFSET_Y    := -50.0
const ORB_CHARGE_FULL := 0.32
const CHARGE_TIME     := 0.3
const IMPACT_DELAY    := CHARGE_TIME  # battle_manager 동기화용
const BUFF_TIME       := 1.2
const RING_SQUASH     := 0.34
const RING_RADIUS     := 100.0
const PANEL_DIST      := 60.0   # dome 패널 중심에서 거리
const PANEL_SIZE      := 24.0   # 6각 패널 크기
const SNAP_DUR        := 0.30   # 패널 snap 애니메이션 시간

## 화면 플래시 + block SFX 트리거
signal screen_effect

var _target := Vector2.ZERO
var _charge_orb: Sprite2D
var _glow_layer: Node2D
var _ring_age := -1.0
var _dome_age := -1.0
var _barrier_age := -1.0
var _ring_spin := 0.0  # HTML 14s/회전

# 6각 정점 윤곽 (단위 r 기준)
static func hex_poly(center: Vector2, r: float, rot: float = 0.0) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(6):
		var ang := PI / 3.0 * float(i) - PI * 0.5 + rot
		pts.append(center + Vector2(cos(ang), sin(ang)) * r)
	return pts

static func _make_orb_tex() -> GradientTexture2D:
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.42, 0.72, 1.0])
	grad.colors = PackedColorArray([
		Color(1, 1, 1, 1.0),
		Color(0.659, 0.816, 1.0, 0.95),
		Color(0.165, 0.420, 0.690, 0.85),
		Color(0.165, 0.420, 0.690, 0.0),
	])
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 256
	tex.height = 256
	return tex

func _ready() -> void:
	set_process(false)
	_charge_orb = Sprite2D.new()
	_charge_orb.texture = _make_orb_tex()
	_charge_orb.modulate = Color(1, 1, 1, 0.0)
	_charge_orb.scale = Vector2(0.10, 0.10)
	add_child(_charge_orb)
	_glow_layer = _DrawLayer.new()
	_glow_layer.setup(self)
	add_child(_glow_layer)

# 첫 인자(caster) 무시
func play(_caster_pos: Vector2, target_pos: Vector2) -> void:
	_target = target_pos
	_charge_orb.position = target_pos + Vector2(0.0, ORB_OFFSET_Y)
	_run()

func _run() -> void:
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(_charge_orb, "modulate:a", 1.0, 0.12)
	tw.parallel().tween_property(_charge_orb, "scale", Vector2(ORB_CHARGE_FULL, ORB_CHARGE_FULL), CHARGE_TIME)
	set_process(true)
	await get_tree().create_timer(CHARGE_TIME).timeout
	if not is_inside_tree():
		return
	var tw2 := create_tween()
	tw2.tween_property(_charge_orb, "modulate:a", 0.0, 0.12)
	_ring_age = 0.0
	_dome_age = 0.0
	_barrier_age = 0.0
	screen_effect.emit()
	await get_tree().create_timer(BUFF_TIME + 1.0).timeout
	if is_inside_tree():
		queue_free()

func _process(delta: float) -> void:
	if _ring_age >= 0.0:
		_ring_age += delta
		_ring_spin += delta * (TAU / 14.0)
	if _dome_age >= 0.0:
		_dome_age += delta
	if _barrier_age >= 0.0:
		_barrier_age += delta
	_glow_layer.queue_redraw()

# ── 가산 블렌드 — dome 패널, barrier, 룬링 ──
func _draw_glow_pass(canvas: CanvasItem) -> void:
	if _barrier_age >= 0.0:
		_draw_barrier(canvas)
	if _ring_age >= 0.0:
		_draw_ring(canvas)
	if _dome_age >= 0.0:
		_draw_dome(canvas)

# 6각 패널 dome — 6개 패널이 사방에서 안쪽으로 snap (각각 다른 delay)
func _draw_dome(canvas: CanvasItem) -> void:
	var fade := 1.0
	if _dome_age > BUFF_TIME:
		fade = clampf(1.0 - (_dome_age - BUFF_TIME) / 0.4, 0.0, 1.0)
	if fade <= 0.0:
		return
	# HTML 의 6 패널 위치/회전 (좌상/위/우상/좌하/아래/우하)
	var positions := [
		Vector2(-1.0, -0.7), Vector2(0.0, -1.05), Vector2(1.0, -0.7),
		Vector2(-0.85, 0.5), Vector2(0.0, 0.85), Vector2(0.85, 0.5),
	]
	var rotations := [-0.21, 0.0, 0.21, -0.14, 0.0, 0.14]
	var delays := [0.0, 0.04, 0.08, 0.12, 0.16, 0.2]
	for i in range(6):
		var local_age: float = _dome_age - delays[i]
		if local_age < 0.0:
			continue
		var t: float = clampf(local_age / SNAP_DUR, 0.0, 1.0)
		var eased: float = 1.0 - pow(1.0 - t, 3.0)
		var start_offset: Vector2 = positions[i] * 80.0
		var end_offset: Vector2 = positions[i] * PANEL_DIST
		var pos: Vector2 = _target + Vector2(0.0, -50.0) + start_offset.lerp(end_offset, eased)
		var sc: float = lerpf(0.4, 1.0, eased)
		var alpha: float = clampf(t * 2.0, 0.0, 1.0) * fade
		var poly := hex_poly(pos, PANEL_SIZE * sc, rotations[i])
		canvas.draw_colored_polygon(poly, Color(COL_MID, 0.55 * alpha))
		var poly2 := poly.duplicate()
		poly2.append(poly2[0])
		canvas.draw_polyline(poly2, Color(COL_HOT, 0.9 * alpha), 1.5, true)

# 외곽 barrier 타원 — 점선 + 펄스 (1.8s 주기)
func _draw_barrier(canvas: CanvasItem) -> void:
	var grow: float = clampf(_barrier_age / 0.4, 0.0, 1.0)
	var fade := 1.0
	if _barrier_age > BUFF_TIME:
		fade = clampf(1.0 - (_barrier_age - BUFF_TIME) / 0.4, 0.0, 1.0)
	if fade <= 0.0:
		return
	var pulse: float = 0.55 + sin(_barrier_age * (TAU / 1.8)) * 0.20
	var alpha: float = grow * fade * pulse
	var rc := _target + Vector2(0.0, -30.0)
	var rx: float = 90.0 * grow
	var ry: float = 130.0 * grow
	for i in range(16):
		var a0: float = TAU * float(i) / 16.0
		var a1: float = a0 + TAU / 32.0
		var pts := PackedVector2Array()
		for k in range(4):
			var t: float = float(k) / 3.0
			var ang: float = lerpf(a0, a1, t)
			pts.append(rc + Vector2(cos(ang) * rx, sin(ang) * ry))
		canvas.draw_polyline(pts, Color(COL_MID, 0.85 * alpha), 1.5)

# 지면 룬링 — 누운 원근 두 동심원 + 8개 6각 tab (회전)
func _draw_ring(canvas: CanvasItem) -> void:
	var grow: float = clampf(_ring_age / 0.35, 0.0, 1.0)
	var fade := 1.0
	if _ring_age > BUFF_TIME:
		fade = clampf(1.0 - (_ring_age - BUFF_TIME) / 0.4, 0.0, 1.0)
	if fade <= 0.0:
		return
	var sc: float = lerpf(0.3, 1.0, grow)
	var a: float = grow * fade * 0.9
	var rc := _target + Vector2(0.0, 30.0)
	for radius in [RING_RADIUS, RING_RADIUS * 0.87]:
		var rad: float = float(radius) * sc
		var pts := PackedVector2Array()
		for i in range(48):
			var ang: float = TAU * float(i) / 48.0
			pts.append(rc + Vector2(cos(ang) * rad, sin(ang) * rad * RING_SQUASH))
		pts.append(pts[0])
		canvas.draw_polyline(pts, Color(COL_MID, a), 1.5)
	var tab_r: float = RING_RADIUS * sc
	for i in range(8):
		var ang: float = TAU * float(i) / 8.0 + _ring_spin
		var center := rc + Vector2(cos(ang) * tab_r, sin(ang) * tab_r * RING_SQUASH)
		var poly := hex_poly(center, 6.0 * sc, 0.0)
		canvas.draw_colored_polygon(poly, Color(COL_HOT, a * 0.7))

# 가산 블렌드 단일 레이어 — 파티클 없으니 smoke 레이어 불필요
class _DrawLayer:
	extends Node2D
	var _fx: Node2D

	func setup(owner_fx: Node2D) -> void:
		_fx = owner_fx
		var m := CanvasItemMaterial.new()
		m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		material = m

	func _draw() -> void:
		_fx._draw_glow_pass(self)
