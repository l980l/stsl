# scenes/vfx/debuff_hex.gd
# 시전자→타겟 디버프(Hex Mark) VFX — ui_sample/vfx/Debuff VFX.html 재현 (스탯 숫자 제외).
# battle_scene이 weak/vulnerable 디버프 적용 시 .new() → add_child → play(caster, target).
# 노드는 position (0,0)으로 add_child해야 한다 (좌표를 global로 받아 그대로 그림).
# 어두운 독무는 가산 블렌드로 안 보이므로 독무·물방울(일반)·룬·발톱(가산) 2개 레이어로 그린다.
extends Node2D

const COL_HOT     := Color(0.847, 0.706, 1.0)   # #d8b4ff — 밝은 보라
const COL_MID     := Color(0.545, 0.361, 0.965) # #8b5cf6 — 보라
const COL_DEEP    := Color(0.290, 0.165, 0.549) # #4a2a8c — 진보라
const COL_SICK    := Color(0.541, 0.686, 0.420) # #8aaf6b — 병든 녹색
const COL_MIASMA  := Color(0.471, 0.314, 0.706) # rgba(120,80,180) — 독무
const COL_DRIP    := Color(0.431, 0.627, 0.314) # rgba(110,160,80) — 독액
const COL_DRIP_HL := Color(0.784, 0.902, 0.667) # rgba(200,230,170) — 독액 하이라이트

# 크기/타이밍 — 이 상수만 만지면 된다.
const ORB_CHARGE_START := 0.12  # 차지 구체 시작
const ORB_CHARGE_FULL  := 0.40  # 차지 완료
const CHARGE_TIME      := 0.32  # 차지 시간(s)
const IMPACT_DELAY     := CHARGE_TIME  # battle_manager 동기화용 (차지 끝 = 발톱 할퀴기 시작)
const CLAW_DUR         := 0.28  # 발톱 할퀴기 1회 지속(s)
const DEBUFF_TIME      := 2.0   # 명중 후 독무·마법진 지속(s)
const PSPEED           := 60.0  # HTML(dt*0.06) → Godot(delta*60) 환산 계수

## 발톱 명중 순간 — 화면 흔들림·SFX 요청 (battle_scene이 수신)
signal screen_effect

var _caster := Vector2.ZERO
var _target := Vector2.ZERO
var _charge_orb: Sprite2D
var _smoke_layer: Node2D  # 일반 블렌드 — 독무·독액
var _hex_layer: Node2D    # 가산 블렌드 — 룬·발톱·마법진
var _particles: Array = []  # [{pos, vel, life, max_life, r, kind, grav}]
var _claws: Array = []      # [{pos, ang, t, len}]
var _sigil_age := -1.0      # <0 = 비활성, 경과 초 (마법진)
var _ambient_timer := 0.0   # 잔류 독무 남은 시간

# ── 점 묶음을 center 기준 회전+스케일 (autoload 비의존 static — 단위 테스트 가능) ──
static func rotate_points(pts: PackedVector2Array, center: Vector2, ang: float, scale: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in pts:
		out.append(center + (p * scale).rotated(ang))
	return out

# 라디얼 그라데이션 구체 텍스처 — orb.png는 배경이 불투명해 검은 박스로 보이므로 코드 생성.
static func _make_orb_tex(c_core: Color, c_mid: Color, c_edge: Color) -> GradientTexture2D:
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.42, 0.72, 1.0])
	grad.colors = PackedColorArray([c_core, c_mid, c_edge, Color(c_edge.r, c_edge.g, c_edge.b, 0.0)])
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
	var orb_tex := _make_orb_tex(COL_HOT, COL_MID, COL_DEEP)

	# 독무 레이어 — 일반 블렌드, 가장 아래
	_smoke_layer = _DrawLayer.new()
	_smoke_layer.setup(self, false)
	add_child(_smoke_layer)

	_charge_orb = Sprite2D.new()
	_charge_orb.texture = orb_tex
	_charge_orb.modulate = Color(1, 1, 1, 0.0)  # 알파만 제어 — 색은 텍스처가 가짐
	_charge_orb.scale = Vector2(ORB_CHARGE_START, ORB_CHARGE_START)
	add_child(_charge_orb)

	# 룬·발톱·마법진 레이어 — 가산 블렌드, 가장 위
	_hex_layer = _DrawLayer.new()
	_hex_layer.setup(self, true)
	add_child(_hex_layer)

# caster_pos / target_pos 는 global 좌표 (노드가 (0,0)에 있다는 전제)
func play(caster_pos: Vector2, target_pos: Vector2) -> void:
	_caster = caster_pos
	_target = target_pos
	_charge_orb.position = caster_pos
	_run()

func _run() -> void:
	# 1) 차지 — 시전자 손의 병든 보라 구체 + 어두운 덩굴이 타겟으로 기어감
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(_charge_orb, "modulate:a", 1.0, 0.2)
	tw.parallel().tween_property(_charge_orb, "scale", Vector2(ORB_CHARGE_FULL, ORB_CHARGE_FULL), CHARGE_TIME)
	set_process(true)
	for _i in range(3):
		_spawn_tendrils()
		await get_tree().create_timer(0.15).timeout
		if not is_inside_tree():
			return
	await get_tree().create_timer(CHARGE_TIME - 0.45).timeout
	if not is_inside_tree():
		return
	# 2) 발사 — 구체 사라짐 + 발톱 3연타
	var tw2 := create_tween()
	tw2.tween_property(_charge_orb, "modulate:a", 0.0, 0.12)
	_spawn_claw(-0.4, -30.0)
	await get_tree().create_timer(0.08).timeout
	if not is_inside_tree():
		return
	_spawn_claw(0.1, 0.0)
	await get_tree().create_timer(0.08).timeout
	if not is_inside_tree():
		return
	_spawn_claw(-0.2, 30.0)
	await get_tree().create_timer(0.04).timeout
	if not is_inside_tree():
		return
	# 3) 명중 — 마법진·독무 폭발. 잔류는 _process에서. 정리.
	_on_impact()
	await get_tree().create_timer(DEBUFF_TIME + 1.5).timeout
	if is_inside_tree():
		queue_free()

# 차지 중 시전자→타겟 경로를 따라 기어가는 어두운 덩굴 (포물선 경로)
func _spawn_tendrils() -> void:
	for _i in range(10):
		var t := randf()
		var base := _caster.lerp(_target, t)
		base += Vector2(randf_range(-15.0, 15.0), randf_range(-20.0, 20.0) - sin(t * PI) * 40.0)
		_particles.append(_mk(base,
			Vector2(randf_range(-0.15, 0.15), -0.2 - randf() * 0.3),
			0.7 + randf() * 0.5, 10.0 + randf() * 16.0, "miasma", -0.003))

func _spawn_claw(ang_off: float, y_off: float) -> void:
	_claws.append({
		"pos": _target + Vector2(0.0, y_off),
		"ang": ang_off,
		"t": 0.0,
		"len": 110.0 + randf() * 40.0,
	})

# 명중 폭발 — 독무 + 룬 파편 + 독액 방울
func _spawn_impact_cloud(pos: Vector2) -> void:
	for _i in range(55):
		var a := randf() * TAU
		var sp := 0.8 + randf() * 3.0
		_particles.append(_mk(pos, Vector2(cos(a) * sp, sin(a) * sp * 0.7 - 0.5),
			1.2 + randf() * 0.9, 18.0 + randf() * 22.0, "miasma", -0.008))
	for _i in range(32):
		var a := randf() * TAU
		var sp := 1.0 + randf() * 4.0
		_particles.append(_mk(pos, Vector2(cos(a) * sp, sin(a) * sp - 0.5),
			1.0 + randf() * 0.7, 1.5 + randf() * 1.4, "rune", 0.0))
	for _i in range(18):
		var a := randf() * TAU
		var sp := 1.0 + randf() * 3.0
		_particles.append(_mk(pos, Vector2(cos(a) * sp, sin(a) * sp - 0.4),
			1.2 + randf() * 0.8, 3.0 + randf() * 4.0, "drip", 0.05))

# 잔류 — 명중 후 타겟 주위에 천천히 피어오르는 독무·룬
func _spawn_ambient() -> void:
	if randf() < 0.7:
		_particles.append(_mk(_target + Vector2(randf_range(-50.0, 50.0), randf_range(20.0, 40.0)),
			Vector2(randf_range(-0.1, 0.1), -0.3 - randf() * 0.5),
			1.6 + randf() * 0.9, 10.0 + randf() * 14.0, "miasma", -0.004))
	if randf() < 0.3:
		_particles.append(_mk(_target + Vector2(randf_range(-45.0, 45.0), randf_range(-5.0, 25.0)),
			Vector2(randf_range(-0.15, 0.15), -0.4 - randf() * 0.4),
			1.4 + randf() * 0.8, 1.2 + randf() * 1.2, "rune", 0.0))

func _mk(pos: Vector2, vel: Vector2, max_life: float, r: float, kind: String, grav: float) -> Dictionary:
	return {"pos": pos, "vel": vel, "life": 0.0, "max_life": max_life, "r": r, "kind": kind, "grav": grav}

func _process(delta: float) -> void:
	# 발톱 진행
	for c in _claws:
		c["t"] += delta / CLAW_DUR
	var alive_claws: Array = []
	for c in _claws:
		if c["t"] < 1.0:
			alive_claws.append(c)
	_claws = alive_claws

	# 파티클 물리 (HTML frame() 포팅) — 수명 만료 시 제거
	var damp: float = pow(0.992, delta * 60.0)
	var alive: Array = []
	for p in _particles:
		p["life"] += delta
		if p["life"] >= p["max_life"]:
			continue
		p["pos"] += p["vel"] * delta * PSPEED
		p["vel"].y += p["grav"] * delta * PSPEED
		p["vel"] *= damp
		alive.append(p)
	_particles = alive

	# 잔류 독무 — 명중 후 DEBUFF_TIME 동안 지속 생성
	if _ambient_timer > 0.0:
		_ambient_timer -= delta
		_spawn_ambient()

	# 마법진 진행
	if _sigil_age >= 0.0:
		_sigil_age += delta

	_smoke_layer.queue_redraw()
	_hex_layer.queue_redraw()

func _on_impact() -> void:
	_spawn_impact_cloud(_target)
	_sigil_age = 0.0
	_ambient_timer = DEBUFF_TIME
	screen_effect.emit()

# ── 그리기 패스 — _DrawLayer 가 블렌드 모드별로 호출 ──
func _draw_smoke_pass(canvas: CanvasItem) -> void:
	# 독무
	for p in _particles:
		if p["kind"] != "miasma":
			continue
		var k: float = p["life"] / p["max_life"]
		var a: float = (1.0 - k) * 0.4
		var r: float = p["r"] * (1.0 + k * 1.4)
		canvas.draw_circle(p["pos"], r, Color(COL_MIASMA, a))
	# 독액 방울 (몸 + 하이라이트)
	for p in _particles:
		if p["kind"] != "drip":
			continue
		var a: float = 1.0 - p["life"] / p["max_life"]
		canvas.draw_circle(p["pos"], p["r"] * 0.9, Color(COL_DRIP, 0.9 * a))
		canvas.draw_circle(p["pos"] + Vector2(-p["r"] * 0.25, -p["r"] * 0.4),
			p["r"] * 0.35, Color(COL_DRIP_HL, 0.6 * a))

func _draw_hex_pass(canvas: CanvasItem) -> void:
	# 룬 파편 (밝은 점 + 십자)
	for p in _particles:
		if p["kind"] != "rune":
			continue
		var a: float = 1.0 - p["life"] / p["max_life"]
		var pr: float = p["r"]
		var pos: Vector2 = p["pos"]
		canvas.draw_circle(pos, pr, Color(COL_HOT, a))
		canvas.draw_rect(Rect2(pos.x - pr * 2.5, pos.y - 0.3, pr * 5.0, 0.6), Color(COL_HOT, a))
		canvas.draw_rect(Rect2(pos.x - 0.3, pos.y - pr * 2.5, 0.6, pr * 5.0), Color(COL_HOT, a))
	# 발톱 할퀴기 (3줄 평행 스크래치 + 밝은 선두)
	for c in _claws:
		_draw_claw(canvas, c)
	# 마법진
	if _sigil_age >= 0.0:
		_draw_sigil(canvas)

func _draw_claw(canvas: CanvasItem, claw: Dictionary) -> void:
	var t: float = claw["t"]
	var k: float = minf(1.0, t * 1.8)        # 할퀴는 길이 진행
	var fade: float = 1.0 - maxf(0.0, (t - 0.4) / 0.6)
	if fade <= 0.0:
		return
	var ang: float = claw["ang"]
	var ln: float = claw["len"]
	var fwd := Vector2(cos(ang), sin(ang))
	var side := Vector2(-fwd.y, fwd.x)
	var origin: Vector2 = claw["pos"]
	for si in range(-1, 2):
		var base := origin + side * (float(si) * 14.0)
		var p0 := base + fwd * (-ln * 0.5)
		var p1 := base + fwd * (-ln * 0.5 + ln * k)
		canvas.draw_line(p0, p1, Color(COL_HOT, 0.9 * fade), 3.0)
		# 밝은 선두 엣지
		var pe := base + fwd * (-ln * 0.5 + ln * k - 12.0)
		canvas.draw_line(pe, p1, Color(1, 1, 1, 0.9 * fade), 1.5)

func _draw_sigil(canvas: CanvasItem) -> void:
	var age: float = _sigil_age
	var drop: float = clampf(age / 0.55, 0.0, 1.0)
	var de: float = 1.0 - pow(1.0 - drop, 3.0)  # ease-out
	var yoff: float = lerpf(-180.0, 0.0, de)
	# scale 0.4 → 1.15 → 1.0
	var sc: float
	var rot_deg: float
	if drop < 0.7:
		sc = lerpf(0.4, 1.15, drop / 0.7)
		rot_deg = lerpf(-60.0, 20.0, drop / 0.7)
	else:
		sc = lerpf(1.15, 1.0, (drop - 0.7) / 0.3)
		rot_deg = lerpf(20.0, 0.0, (drop - 0.7) / 0.3)
	if age > 0.55:
		rot_deg += (age - 0.55) * 55.0  # 천천히 회전
	var rot := deg_to_rad(rot_deg)
	var fade := 1.0
	if age > DEBUFF_TIME:
		fade = clampf(1.0 - (age - DEBUFF_TIME) / 0.5, 0.0, 1.0)
	var a: float = clampf(drop * 1.6, 0.0, 1.0) * fade * 0.85
	if a <= 0.0:
		return
	var c := _target + Vector2(0.0, -30.0 + yoff)
	# 동심원 2개
	canvas.draw_arc(c, 54.0 * sc, 0.0, TAU, 40, Color(COL_HOT, 0.75 * a), 1.5, true)
	canvas.draw_arc(c, 42.0 * sc, 0.0, TAU, 40, Color(COL_MID, 0.7 * a), 1.0, true)
	# 삼각형 2개 (교차하는 헥사그램)
	var tri1 := rotate_points(PackedVector2Array([
		Vector2(0, -48), Vector2(42, 24), Vector2(-42, 24)]), c, rot, sc)
	var tri2 := rotate_points(PackedVector2Array([
		Vector2(0, 48), Vector2(-42, -24), Vector2(42, -24)]), c, rot, sc)
	canvas.draw_polyline(tri1 + PackedVector2Array([tri1[0]]), Color(COL_HOT, 0.8 * a), 1.5, true)
	canvas.draw_polyline(tri2 + PackedVector2Array([tri2[0]]), Color(COL_SICK, 0.55 * a), 1.0, true)
	# 중심점
	canvas.draw_circle(c, 6.0 * sc, Color(COL_HOT, a))
	# 별 4개 (작은 마름모)
	for i in range(4):
		var sa := deg_to_rad(90.0 * float(i)) + rot
		var spos := c + Vector2(cos(sa), sin(sa)) * 48.0 * sc
		var star := PackedVector2Array([
			spos + Vector2(0, -4), spos + Vector2(3, 0),
			spos + Vector2(0, 4), spos + Vector2(-3, 0)])
		canvas.draw_colored_polygon(star, Color(COL_HOT, 0.85 * a))

# ── 블렌드 모드가 다른 두 그리기 레이어 ──
# 어두운 독무는 가산이면 안 보이므로 일반 블렌드, 룬·발톱은 글로우용 가산 블렌드.
class _DrawLayer:
	extends Node2D
	var _fx: Node2D
	var _additive := false

	func setup(owner_fx: Node2D, additive: bool) -> void:
		_fx = owner_fx
		_additive = additive
		if additive:
			var m := CanvasItemMaterial.new()
			m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
			material = m

	func _draw() -> void:
		if _additive:
			_fx._draw_hex_pass(self)
		else:
			_fx._draw_smoke_pass(self)
