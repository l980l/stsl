# scenes/vfx/sig_yin_yang.gd
# 도교 신화 시그너처 — 음양 (자세 교대).
# ui_sample/vfx/Yin-Yang VFX.html 재현. 매 턴 공격(STR +1) ↔ 방어(BLOCK +15) 자동 교대.
# 짧고 가벼움 (~0.9s) — 매 턴 발동이라 화면 부담 최소화.
# play(_caster_pos, target_pos) — caster 무시. target = 적 위치 (시전자 본인).
# ground: 적 발치 작은 wash (희미한 흑백 split).
# glow: 머리 위 회전 태극 glyph + side icon 잔상 (작은 빛).
extends Node2D

var _particle_scale_override: float = -1.0

func _pcount(n: int) -> int:
	if _particle_scale_override > 0.0:
		return maxi(1, int(round(n * _particle_scale_override)))
	var gs := get_node_or_null("/root/GameSettings")
	return n if gs == null else maxi(1, int(round(n * gs.particle_count_scale())))

func _scale() -> float:
	if _particle_scale_override > 0.0:
		return _particle_scale_override
	var gs := get_node_or_null("/root/GameSettings")
	return 1.0 if gs == null else gs.particle_count_scale()


const COL_HOT     := Color(1.0, 1.0, 1.0)
const COL_YANG    := Color(0.964, 0.945, 0.901)   # #f6f1e6 흰 (양)
const COL_YIN     := Color(0.039, 0.031, 0.019)   # #0a0805 검 (음)
const COL_RED     := Color(0.850, 0.290, 0.313)   # #d94a50 양 — 공격
const COL_BLUE    := Color(0.482, 0.627, 0.784)   # #7ba0c8 음 — 방어
const COL_BONE    := Color(0.847, 0.811, 0.725)   # #d8cfb9

const IMPACT_DELAY := 0.18    # 태극 등장 peak — SFX 동기화용 (음양은 SFX 없음 — battle_scene 선택)
const HOLD_TIME    := 0.85
const FADE_TIME    := 0.35
const TAIJI_R      := 42.0
const HEAD_OFFSET  := -130.0
const PSPEED       := 60.0
# snap 회전 — 매 SNAP_STEP 마다 90도. self-touch polygon 사용 안 함 (단순 반원 + 원) → 회전 안전.
const SNAP_STEP    := 0.4
const SNAP_TURN    := 0.18    # 한 snap 중 회전 차지 시간 (나머지는 정지 hold)
const SNAP_ANGLE   := PI / 2.0

signal screen_effect

var _target := Vector2.ZERO
var _ground_pos := Vector2.ZERO
var _has_ground: bool = false

func set_ground_anchor(pos: Vector2) -> void:
	_ground_pos = pos
	_has_ground = true
	# z_index 조정 X — 후광은 머리 위 캐릭터와 안 겹쳐 z 무관. add_child 순서로 ground(후광) 가 glow(태극) 뒤.

func _foot_pos() -> Vector2:
	return _ground_pos if _has_ground else _target + Vector2(0.0, 60.0)

var _age := -1.0
var _impact_emitted := false
var _ground_layer: Node2D
var _glow_layer: Node2D

func _ready() -> void:
	set_process(false)
	_ground_layer = _DrawLayer.new()
	_ground_layer.setup(self, true)
	add_child(_ground_layer)
	_ground_layer.set_meta("pass", "ground")
	# 태극은 normal blend — 가산이면 검정 영역(음)이 표현 안 됨
	_glow_layer = _DrawLayer.new()
	_glow_layer.setup(self, false)
	add_child(_glow_layer)
	_glow_layer.set_meta("pass", "glow")

func play(_caster_pos: Vector2, target_pos: Vector2) -> void:
	_target = target_pos
	_age = 0.0
	set_process(true)
	await get_tree().create_timer(IMPACT_DELAY + HOLD_TIME + FADE_TIME + 0.1).timeout
	if is_inside_tree():
		queue_free()

func _process(delta: float) -> void:
	_age += delta
	if not _impact_emitted and _age >= IMPACT_DELAY:
		_impact_emitted = true
		screen_effect.emit()
	_ground_layer.queue_redraw()
	_glow_layer.queue_redraw()

# alpha 는 등장 페이드인만 — 사라질 땐 scale 로 줄어듦 (불투명 유지)
func _global_alpha() -> float:
	return clampf(_age / 0.1, 0.0, 1.0)

# ── ground — 태극 후광 (가산 blend, radial gradient polygon). 태극 뒤로 그려짐. ──
func _draw_ground_pass(canvas: CanvasItem) -> void:
	if _age < 0.0:
		return
	var pop: float = clampf(_age / 0.18, 0.0, 1.0)
	if pop <= 0.0:
		return
	var sc: float = lerpf(0.3, 1.15, pop)
	if pop >= 1.0:
		sc = 1.0
	if _age > IMPACT_DELAY + HOLD_TIME:
		var fade_t: float = clampf((_age - IMPACT_DELAY - HOLD_TIME) / FADE_TIME, 0.0, 1.0)
		sc = lerpf(1.0, 0.0, 1.0 - pow(1.0 - fade_t, 2.0))
	if sc <= 0.001:
		return
	var alpha: float = pop * _global_alpha()
	var ctr: Vector2 = _target + Vector2(0.0, HEAD_OFFSET)
	var r: float = TAIJI_R * sc
	# radial gradient — 가산 blend 로 동심원 다중 누적 (중심 진함 → 외곽 옅음). 층 안 보이게 16겹.
	var halo_r: float = r * 1.35
	var inner_r: float = r * 0.9
	var layers := 16
	var per_alpha: float = alpha * 0.05
	var halo_color := Color(COL_HOT.r, COL_HOT.g, COL_HOT.b, per_alpha)
	for i in range(layers):
		var t: float = float(i) / float(layers - 1)
		var rad: float = lerpf(halo_r, inner_r, t)
		canvas.draw_circle(ctr, rad, halo_color)

# ── glow — 머리 위 회전 태극 glyph ──
func _draw_glow_pass(canvas: CanvasItem) -> void:
	var ga: float = _global_alpha()
	if ga <= 0.0:
		return
	_draw_taiji(canvas, ga)

# 머리 위 태극 — S자 polygon + snap 회전 (슥 슥 슥 180도)
func _draw_taiji(canvas: CanvasItem, ga: float) -> void:
	var pop: float = clampf(_age / 0.18, 0.0, 1.0)
	if pop <= 0.0:
		return
	var fade: float = 1.0
	if _age > IMPACT_DELAY + HOLD_TIME:
		fade = clampf(1.0 - (_age - IMPACT_DELAY - HOLD_TIME) / FADE_TIME, 0.0, 1.0)
	if fade <= 0.0:
		return
	# scale: 등장 0.3 → 1.15 → 1.0 → (fade 시) 1.0 → 0.0 (불투명 유지 — alpha fade 대신)
	var sc: float = lerpf(0.3, 1.15, pop)
	if pop >= 1.0:
		sc = 1.0
	if _age > IMPACT_DELAY + HOLD_TIME:
		var fade_t: float = clampf((_age - IMPACT_DELAY - HOLD_TIME) / FADE_TIME, 0.0, 1.0)
		sc = lerpf(1.0, 0.0, 1.0 - pow(1.0 - fade_t, 2.0))
	if sc <= 0.001:
		return
	var alpha: float = pop * ga
	# snap 90도 회전 — SNAP_TURN 동안만 회전 + 나머지 정지 hold
	var snap_idx: int = int(floor(_age / SNAP_STEP))
	var local_t: float = _age - float(snap_idx) * SNAP_STEP
	var rotate_phase: float = clampf(local_t / SNAP_TURN, 0.0, 1.0)
	var snap_t_ease: float = 1.0 - pow(1.0 - rotate_phase, 2.0)
	var rot: float = (float(snap_idx) + snap_t_ease) * SNAP_ANGLE
	var ctr: Vector2 = _target + Vector2(0.0, HEAD_OFFSET)
	var r: float = TAIJI_R * sc
	var small_r: float = r * 0.5
	var c_yang := Color(COL_YANG.r, COL_YANG.g, COL_YANG.b, alpha)
	var c_yin := Color(COL_YIN.r, COL_YIN.g, COL_YIN.b, alpha)
	# 1. 외곽 흰 원 (양 베이스 — 원이라 회전 무관)
	canvas.draw_circle(ctr, r, c_yang)
	# 2. 검 반원 polygon (회전된 D 자 — self-touch 없음, triangulation 안정)
	var half_pts := PackedVector2Array()
	var seg := 32
	for i in range(seg + 1):
		var a: float = -PI / 2.0 + PI * float(i) / float(seg)
		half_pts.append(_rotate_pt(ctr, cos(a) * r, sin(a) * r, rot))
	canvas.draw_colored_polygon(half_pts, c_yin)
	# 3. 작은 흰 원 (검 반원의 위쪽 끝 — S자 형성, 회전 위치)
	canvas.draw_circle(_rotate_pt(ctr, 0.0, -small_r, rot), small_r, c_yang)
	# 4. 작은 검 원 (흰 반원의 아래쪽 끝 — S자 완성, 회전 위치)
	canvas.draw_circle(_rotate_pt(ctr, 0.0, small_r, rot), small_r, c_yin)
	# 5. 외곽 ring 마감 (회전 무관)
	canvas.draw_arc(ctr, r, 0.0, TAU, 40, Color(COL_BONE, alpha * 0.85), 1.4, true)
	# 6. 두 작은 반대색 점
	var dot_r: float = r * 0.13
	canvas.draw_circle(_rotate_pt(ctr, 0.0, -small_r, rot), dot_r, c_yin)
	canvas.draw_circle(_rotate_pt(ctr, 0.0, small_r, rot), dot_r, c_yang)

func _rotate_pt(ctr: Vector2, x: float, y: float, rot: float) -> Vector2:
	return ctr + Vector2(x * cos(rot) - y * sin(rot), x * sin(rot) + y * cos(rot))

# ── 블렌드 분리 레이어 ──
class _DrawLayer:
	extends Node2D
	var _fx: Node2D

	func setup(owner_fx: Node2D, additive: bool) -> void:
		_fx = owner_fx
		if additive:
			var m := CanvasItemMaterial.new()
			m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
			material = m

	func _draw() -> void:
		if get_meta("pass", "glow") == "ground":
			_fx._draw_ground_pass(self)
		else:
			_fx._draw_glow_pass(self)
