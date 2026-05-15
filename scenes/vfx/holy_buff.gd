# scenes/vfx/holy_buff.gd
# 신성 버프 VFX — ui_sample/vfx/HolyBuff VFX.html 재현 (스탯 텍스트 제외).
# Joan of Arc 의 버프 카드 발동 시 .new() → add_child → play(target, target).
# 버프는 시전자가 곧 대상이므로 play 의 첫 인자는 무시 (heal 과 동일 패턴).
# 깃털은 가산 블렌드면 묻혀버리므로 일반 블렌드, mote/룬링/빛기둥은 가산 블렌드 — 2레이어.
extends Node2D

# 파티클 갯수 — GameSettings.particle_count_scale 적용 (하/중/상 = 0.25/0.5/1.0배)
func _pcount(n: int) -> int:
	var gs := get_node_or_null("/root/GameSettings")
	return n if gs == null else maxi(1, int(round(n * gs.particle_count_scale())))

const COL_HOT     := Color(1.0, 0.965, 0.776) # #fff6c6 — 흰금 코어
const COL_MID     := Color(1.0, 0.831, 0.439) # #ffd470 — 황금
const COL_DEEP    := Color(0.8, 0.541, 0.102) # #cc8a1a — 진금
const COL_FEATHER := Color(1.0, 0.902, 0.627) # rgba(255,230,160) — 깃털

# 크기/타이밍 — 이 상수만 만지면 된다.
const ORB_CHARGE_START := 0.10  # 차지 구체 시작 스케일
const ORB_CHARGE_FULL  := 0.45  # 차지 완료 스케일
const ORB_OFFSET_Y     := -90.0 # 차지 구체 — 타겟 위로(px)
const CHARGE_TIME      := 0.3   # 차지 시간(s)
const IMPACT_DELAY     := CHARGE_TIME  # battle_manager 동기화용 (차지 끝 = 버프 발동)
const BUFF_TIME        := 1.5   # 빛기둥·룬링 지속 + mote/feather 분출(s)
const RING_SQUASH      := 0.34  # 누운 원근 — y축 압축 (HTML rotateX 70°)
const PILLAR_HEIGHT    := 240.0 # 빛기둥 높이(px)
const PILLAR_WIDTH     := 90.0  # 빛기둥 바닥 절반(px)
const RING_RADIUS      := 110.0 # 룬 링 외곽 반경(px)
const PSPEED           := 60.0  # HTML(dt*0.06) → Godot(delta*60) 환산 계수

## 화면 플래시 + 버프 SFX 트리거 (battle_scene 이 수신)
signal screen_effect

var _target := Vector2.ZERO
var _charge_orb: Sprite2D
var _smoke_layer: Node2D  # 일반 블렌드 — 깃털
var _glow_layer: Node2D   # 가산 블렌드 — mote/룬링/빛기둥
var _particles: Array = []
var _ring_age := -1.0     # <0=비활성, 경과 초
var _pillar_age := -1.0
var _buff_timer := 0.0    # mote/feather 지속 분출 남은 시간
var _ring_spin := 0.0     # 룬 링 회전 (HTML 8s/회전)

# 라디얼 그라데이션 구체 텍스처 — orb.png 는 배경이 불투명해 검은 박스로 보이므로 코드 생성.
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
	_smoke_layer = _DrawLayer.new()
	_smoke_layer.setup(self, false)
	add_child(_smoke_layer)

	_charge_orb = Sprite2D.new()
	_charge_orb.texture = _make_orb_tex(COL_HOT, COL_MID, COL_DEEP)
	_charge_orb.modulate = Color(1, 1, 1, 0.0)
	_charge_orb.scale = Vector2(ORB_CHARGE_START, ORB_CHARGE_START)
	add_child(_charge_orb)

	_glow_layer = _DrawLayer.new()
	_glow_layer.setup(self, true)
	add_child(_glow_layer)

# 첫 인자(caster) 무시 — 버프는 대상 위치에서 발동
func play(_caster_pos: Vector2, target_pos: Vector2) -> void:
	_target = target_pos
	_charge_orb.position = target_pos + Vector2(0.0, ORB_OFFSET_Y)
	_run()

func _run() -> void:
	# 1) 차지 — 대상 위 황금 구체 0.7s
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(_charge_orb, "modulate:a", 1.0, 0.18)
	tw.parallel().tween_property(_charge_orb, "scale", Vector2(ORB_CHARGE_FULL, ORB_CHARGE_FULL), CHARGE_TIME)
	set_process(true)
	await get_tree().create_timer(CHARGE_TIME).timeout
	if not is_inside_tree():
		return
	# 2) 발동 — 구체 페이드아웃 + 룬링/빛기둥 등장 + 초기 버스트 + 화면 플래시
	var tw2 := create_tween()
	tw2.tween_property(_charge_orb, "modulate:a", 0.0, 0.15)
	_ring_age = 0.0
	_pillar_age = 0.0
	_buff_timer = BUFF_TIME
	_spawn_burst()
	screen_effect.emit()
	# 3) BUFF_TIME 동안 mote/feather 솟구침 + 페이드 후 정리
	await get_tree().create_timer(BUFF_TIME + 1.5).timeout
	if is_inside_tree():
		queue_free()

func _mk(pos: Vector2, vel: Vector2, max_life: float, r: float, kind: String,
		grav: float = 0.0, rot: float = 0.0, spin: float = 0.0) -> Dictionary:
	return {"pos": pos, "vel": vel, "life": 0.0, "max_life": max_life, "r": r,
		"kind": kind, "grav": grav, "rot": rot, "spin": spin}

# 발동 순간 — mote 25 + feather 10 폭발
func _spawn_burst() -> void:
	var ctr := _target + Vector2(0.0, -30.0)
	for _i in range(_pcount(25)):
		var a := randf() * TAU
		var sp := 2.0 + randf() * 5.0
		_particles.append(_mk(ctr, Vector2(cos(a) * sp, sin(a) * sp - 1.5),
			1.2 + randf() * 0.7, 1.5 + randf() * 1.6, "mote", 0.025))
	for _i in range(_pcount(10)):
		var a := randf() * TAU
		var sp := 1.0 + randf() * 3.0
		_particles.append(_mk(ctr, Vector2(cos(a) * sp, sin(a) * sp - 0.8),
			1.4 + randf() * 0.9, 10.0 + randf() * 10.0, "feather", 0.01,
			randf_range(-0.6, 0.6), randf_range(-0.05, 0.05)))

# BUFF_TIME 동안 매 프레임 — 기둥 형태로 위로 솟구침
func _spawn_rising() -> void:
	var ctr := _target + Vector2(0.0, -30.0)
	for _i in range(_pcount(2)):
		_particles.append(_mk(ctr + Vector2(randf_range(-60.0, 60.0), 10.0),
			Vector2(randf_range(-0.3, 0.3), -1.0 - randf() * 1.2),
			1.4 + randf() * 0.9, 1.4 + randf() * 1.6, "mote"))
	if randf() < 0.2:
		_particles.append(_mk(ctr + Vector2(randf_range(-50.0, 50.0), 0.0),
			Vector2(randf_range(-0.4, 0.4), -0.6 - randf() * 0.7),
			1.6 + randf() * 0.9, 8.0 + randf() * 8.0, "feather", 0.0,
			randf_range(-0.4, 0.4), randf_range(-0.04, 0.04)))

func _process(delta: float) -> void:
	if _ring_age >= 0.0:
		_ring_age += delta
		_ring_spin += delta * (TAU / 8.0)  # 8s/회전 (HTML ringSpin)
	if _pillar_age >= 0.0:
		_pillar_age += delta

	if _buff_timer > 0.0:
		_buff_timer -= delta
		_spawn_rising()

	var damp: float = pow(0.992, delta * 60.0)
	var alive: Array = []
	for p in _particles:
		p["life"] += delta
		if p["life"] >= p["max_life"]:
			continue
		p["pos"] += p["vel"] * delta * PSPEED
		p["vel"].y += p["grav"] * delta * PSPEED
		p["vel"] *= damp
		if p["kind"] == "feather":
			p["rot"] += p["spin"] * delta * PSPEED
		alive.append(p)
	_particles = alive

	_smoke_layer.queue_redraw()
	_glow_layer.queue_redraw()

# ── 일반 블렌드 — 깃털 (가산이면 묻혀버림) ──
func _draw_smoke_pass(canvas: CanvasItem) -> void:
	for p in _particles:
		if p["kind"] != "feather":
			continue
		var k: float = p["life"] / p["max_life"]
		var a: float = (1.0 - k) * 0.9
		var lr: float = p["r"]
		# 깃털 본체 — 길쭉한 타원 (12점 폴리곤, 회전)
		var poly := PackedVector2Array()
		for i in range(12):
			var ang := TAU * float(i) / 12.0
			poly.append(p["pos"] + (Vector2(cos(ang) * 0.45, sin(ang)) * lr).rotated(p["rot"]))
		canvas.draw_colored_polygon(poly, Color(COL_FEATHER, a))
		# 음영 — 위쪽 작은 타원
		var inner := PackedVector2Array()
		for i in range(12):
			var ang := TAU * float(i) / 12.0
			var v := Vector2(cos(ang) * 0.18, sin(ang) * 0.5) * lr
			v.y -= lr * 0.3
			inner.append(p["pos"] + v.rotated(p["rot"]))
		canvas.draw_colored_polygon(inner, Color(COL_HOT, 0.7 * a))

# ── 가산 블렌드 — 빛기둥, 룬 링, mote ──
func _draw_glow_pass(canvas: CanvasItem) -> void:
	if _pillar_age >= 0.0:
		_draw_pillar(canvas)
	if _ring_age >= 0.0:
		_draw_ring(canvas)
	for p in _particles:
		if p["kind"] != "mote":
			continue
		var k: float = p["life"] / p["max_life"]
		var a: float = 1.0 - k
		# HTML 색 보간: rgba(255, 235-20k, 170+30k, a)
		var col := Color(1.0, (235.0 - 20.0 * k) / 255.0, (170.0 + 30.0 * k) / 255.0, a)
		var pr: float = p["r"]
		canvas.draw_circle(p["pos"], pr, col)
		canvas.draw_rect(Rect2(p["pos"].x - pr * 2.5, p["pos"].y - 0.3, pr * 5.0, 0.6), col)
		canvas.draw_rect(Rect2(p["pos"].x - 0.3, p["pos"].y - pr * 2.5, 0.6, pr * 5.0), col)

# 빛기둥 — target 위로 PILLAR_HEIGHT, 1.4s 주기 펄스 (HTML pillarPulse)
func _draw_pillar(canvas: CanvasItem) -> void:
	var grow: float = clampf(_pillar_age / 0.55, 0.0, 1.0)
	var fade := 1.0
	if _pillar_age > BUFF_TIME:
		fade = clampf(1.0 - (_pillar_age - BUFF_TIME) / 0.4, 0.0, 1.0)
	if fade <= 0.0:
		return
	var pulse: float = 0.85 + sin(_pillar_age * (TAU / 1.4)) * 0.10
	var alpha: float = grow * fade * pulse
	var bottom_y := _target.y
	var top_y := _target.y - PILLAR_HEIGHT * grow
	var w_bottom := PILLAR_WIDTH * grow
	var w_top := PILLAR_WIDTH * 0.3 * grow
	canvas.draw_colored_polygon(PackedVector2Array([
		Vector2(_target.x - w_bottom, bottom_y),
		Vector2(_target.x + w_bottom, bottom_y),
		Vector2(_target.x + w_top, top_y),
		Vector2(_target.x - w_top, top_y),
	]), Color(COL_MID, 0.45 * alpha))
	# 안쪽 코어
	canvas.draw_colored_polygon(PackedVector2Array([
		Vector2(_target.x - w_bottom * 0.5, bottom_y),
		Vector2(_target.x + w_bottom * 0.5, bottom_y),
		Vector2(_target.x + w_top * 0.5, top_y),
		Vector2(_target.x - w_top * 0.5, top_y),
	]), Color(COL_HOT, 0.5 * alpha))

# 룬 링 — 지면 회전 (HTML rotateX 70° + 8s 회전)
# 동심원 2개 + 점선원 + 상하 두 삼각형 (룬 표식)
func _draw_ring(canvas: CanvasItem) -> void:
	var grow: float = clampf(_ring_age / 0.5, 0.0, 1.0)
	var fade := 1.0
	if _ring_age > BUFF_TIME:
		fade = clampf(1.0 - (_ring_age - BUFF_TIME) / 0.5, 0.0, 1.0)
	if fade <= 0.0:
		return
	var sc: float = lerpf(0.4, 1.0, grow)
	var a: float = grow * fade * 0.9
	var rc := _target + Vector2(0.0, 30.0)
	# 외곽 두 동심원 (HTML r=115 + r=100)
	for radius in [RING_RADIUS, RING_RADIUS * 0.87]:
		var rad := float(radius) * sc
		var pts := PackedVector2Array()
		for i in range(48):
			var ang := TAU * float(i) / 48.0
			pts.append(rc + Vector2(cos(ang) * rad, sin(ang) * rad * RING_SQUASH))
		pts.append(pts[0])
		canvas.draw_polyline(pts, Color(COL_MID, a), 1.5)
	# 안쪽 점선원 (HTML stroke-dasharray) — 부분 호 12개로 근사
	var dotted_r := RING_RADIUS * 0.71 * sc
	for i in range(12):
		var a0 := TAU * float(i) / 12.0 + _ring_spin
		var a1 := a0 + TAU / 24.0
		var pts := PackedVector2Array()
		for k in range(5):
			var t := float(k) / 4.0
			var ang := lerpf(a0, a1, t)
			pts.append(rc + Vector2(cos(ang) * dotted_r, sin(ang) * dotted_r * RING_SQUASH))
		canvas.draw_polyline(pts, Color(COL_MID, a * 0.55), 1.0)
	# 상하 두 삼각형 (HTML polygon points 위·아래) — 회전
	var tri_r := RING_RADIUS * 0.91 * sc
	for sd in [1.0, -1.0]:
		var sign_dir: float = sd
		var tri := PackedVector2Array()
		for i in range(3):
			var ang: float = _ring_spin + sign_dir * (PI * 0.5) + TAU * float(i) / 3.0
			tri.append(rc + Vector2(cos(ang) * tri_r, sin(ang) * tri_r * RING_SQUASH))
		tri.append(tri[0])
		canvas.draw_polyline(tri, Color(COL_MID, a * 0.8), 1.5)

# ── 블렌드 모드가 다른 두 그리기 레이어 ──
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
			_fx._draw_glow_pass(self)
		else:
			_fx._draw_smoke_pass(self)
