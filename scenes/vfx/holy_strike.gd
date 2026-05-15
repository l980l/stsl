# scenes/vfx/holy_strike.gd
# 성스러운 일격 VFX — ui_sample/vfx/Holy Strike VFX.html 재현 (데미지 숫자 제외).
# battle_scene이 divine damage_type 공격 시 .new() → add_child → play(caster, target).
# 노드는 position (0,0)으로 add_child해야 한다 (좌표를 global로 받아 그대로 그림).
# 어두운 황금 안개는 가산 블렌드로 흐려지므로 기둥·글리프·안개·깃털(일반)·빛입자/칼(가산) 2레이어로 그린다.
extends Node2D

# 파티클 갯수 — GameSettings.particle_count_scale 적용 (하/중/상 = 0.25/0.5/1.0배)
var _particle_scale_override: float = -1.0  # vfx_preview 3-way 비교용 (음수=GameSettings)

func _pcount(n: int) -> int:
	if _particle_scale_override > 0.0:
		return maxi(1, int(round(n * _particle_scale_override)))
	var gs := get_node_or_null("/root/GameSettings")
	return n if gs == null else maxi(1, int(round(n * gs.particle_count_scale())))


# ambient/trail 의 확률 spawn 에 사용 — _pcount 와 동일 스케일
func _scale() -> float:
	if _particle_scale_override > 0.0:
		return _particle_scale_override
	var gs := get_node_or_null("/root/GameSettings")
	return 1.0 if gs == null else gs.particle_count_scale()
const COL_HOT     := Color(1, 1, 1)             # 흰 코어
const COL_MID     := Color(1.0, 0.949, 0.753)   # #fff2c0 — 성광
const COL_GOLD    := Color(1.0, 0.820, 0.4)     # #ffd166 — 금빛
const COL_DEEP    := Color(0.784, 0.573, 0.196) # #c89232 — 진금빛
const COL_HAZE    := Color(1.0, 0.941, 0.784)   # rgba(255,240,200) — 안개
const COL_FEATHER := Color(1.0, 0.980, 0.863)   # rgba(255,250,220) — 깃털

# 크기/타이밍 — 이 상수만 만지면 된다.
const ORB_CHARGE_START := 0.12  # 채널 구체 시작
const ORB_CHARGE_FULL  := 0.36  # 채널 완료
const CHANNEL_TIME     := 0.32  # 채널(차지) 시간(s)
const DESCENT_TIME     := 0.3   # 빛기둥·빛의 칼 강하 시간(s)
const IMPACT_DELAY     := CHANNEL_TIME + DESCENT_TIME  # battle_manager 동기화용
const PILLAR_WIDTH     := 180.0 # 빛기둥 너비(px)
const PILLAR_HEIGHT    := 420.0 # 빛기둥 높이 — 타겟 위로(px)
const GLYPH_RADIUS     := 130.0 # 바닥 글리프 기준 반경(px)
const GLYPH_SQUASH     := 0.34  # 누운 원근 — y축 압축 (rotateX 70°)
const LINGER_TIME      := 1.5   # 명중 후 잔류(s)
const PSPEED           := 60.0  # HTML(dt*0.06) → Godot(delta*60) 환산 계수

## 빛의 칼 명중 순간 — 화면 플래시·흔들림·SFX·피격 피드백 요청 (battle_scene이 수신)
signal screen_effect

var _caster := Vector2.ZERO
var _target := Vector2.ZERO
var _charge_orb: Sprite2D
var _smoke_layer: Node2D  # 일반 블렌드 — 기둥·글리프·안개·깃털
var _glow_layer: Node2D   # 가산 블렌드 — 빛 입자·빛의 칼·십자 섬광·충격파
var _particles: Array = []  # [{pos, vel, life, max_life, r, kind, grav, rot, spin}]
var _channeling := false  # 채널 중 — 시전자 손에서 빛 입자 상승
var _blade_t := -1.0      # <0 = 비활성, 0~1 = 빛의 칼 강하
var _pillar_age := -1.0   # <0 = 비활성, 경과 초 (빛기둥)
var _glyph_age := -1.0    # <0 = 비활성, 경과 초 (바닥 글리프)
var _shock_life := -1.0   # <0 = 비활성, 0~1 = 충격파 링
var _cross_age := -1.0    # <0 = 비활성, 경과 초 (십자 섬광)
var _linger_timer := 0.0  # 잔류 빛 입자 남은 시간

# ── 빛기둥 사다리꼴 4점 (autoload 비의존 static — 단위 테스트 가능) ──
static func pillar_quad(target: Vector2, width: float, height: float, grow: float) -> PackedVector2Array:
	var hw := width * 0.5
	var top := target.y - height
	var bot := lerpf(top, target.y, clampf(grow, 0.0, 1.0))
	return PackedVector2Array([
		Vector2(target.x - hw, top), Vector2(target.x + hw, top),
		Vector2(target.x + hw, bot), Vector2(target.x - hw, bot),
	])

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

	# 기둥·글리프·안개·깃털 레이어 — 일반 블렌드, 아래
	_smoke_layer = _DrawLayer.new()
	_smoke_layer.setup(self, false)
	add_child(_smoke_layer)

	_charge_orb = Sprite2D.new()
	_charge_orb.texture = _make_orb_tex(COL_HOT, COL_MID, COL_GOLD)
	_charge_orb.modulate = Color(1, 1, 1, 0.0)  # 알파만 제어 — 색은 텍스처가 가짐
	_charge_orb.scale = Vector2(ORB_CHARGE_START, ORB_CHARGE_START)
	add_child(_charge_orb)

	# 빛 입자·칼·십자·충격파 레이어 — 가산 블렌드, 위
	_glow_layer = _DrawLayer.new()
	_glow_layer.setup(self, true)
	add_child(_glow_layer)

# caster_pos / target_pos 는 global 좌표 (노드가 (0,0)에 있다는 전제)
func play(caster_pos: Vector2, target_pos: Vector2) -> void:
	_caster = caster_pos
	_target = target_pos
	_charge_orb.position = caster_pos + Vector2(0.0, -40.0)
	_run()

func _run() -> void:
	# 1) 채널 — 시전자 손의 성광 구체 (0.65s)
	_channeling = true
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(_charge_orb, "modulate:a", 1.0, 0.2)
	tw.parallel().tween_property(_charge_orb, "scale", Vector2(ORB_CHARGE_FULL, ORB_CHARGE_FULL), CHANNEL_TIME)
	set_process(true)
	await get_tree().create_timer(CHANNEL_TIME).timeout
	if not is_inside_tree():
		return
	# 2) 빛기둥 + 빛의 칼 강하
	_channeling = false
	var tw2 := create_tween()
	tw2.tween_property(_charge_orb, "modulate:a", 0.0, 0.12)
	_pillar_age = 0.0
	_glyph_age = 0.0
	_blade_t = 0.0
	await get_tree().create_timer(DESCENT_TIME).timeout
	if not is_inside_tree():
		return
	# 3) 심판 — 칼이 꽂히는 순간
	_on_impact()
	# 4) 잔류·페이드는 _process에서. 정리.
	await get_tree().create_timer(LINGER_TIME + 1.5).timeout
	if is_inside_tree():
		queue_free()

func _mk(pos: Vector2, vel: Vector2, max_life: float, r: float, kind: String,
		grav: float, rot: float = 0.0, spin: float = 0.0) -> Dictionary:
	return {"pos": pos, "vel": vel, "life": 0.0, "max_life": max_life, "r": r,
		"kind": kind, "grav": grav, "rot": rot, "spin": spin}

# 채널 중 시전자 손에서 피어오르는 빛 입자
func _spawn_channel_mote() -> void:
	_particles.append(_mk(_caster + Vector2(randf_range(-11.0, 11.0), randf_range(-50.0, -34.0)),
		Vector2(randf_range(-0.3, 0.3), -0.6 - randf() * 0.8),
		1.2 + randf() * 0.8, 1.5 + randf() * 1.4, "mote", -0.005))

# 명중 폭발 — 빛 입자 + 깃털 + 황금 안개 + 바닥에서 솟는 안개
func _spawn_impact() -> void:
	for _i in range(_pcount(40)):
		var a := randf() * TAU
		var sp := 2.0 + randf() * 6.0
		_particles.append(_mk(_target, Vector2(cos(a) * sp, sin(a) * sp - 1.5),
			1.4 + randf() * 0.9, 1.6 + randf() * 1.6, "mote", 0.018))
	for _i in range(_pcount(35)):
		var a := randf() * TAU
		var sp := 1.4 + randf() * 4.0
		_particles.append(_mk(_target, Vector2(cos(a) * sp, sin(a) * sp * 0.8 - 1.2),
			1.8 + randf() * 1.1, 11.0 + randf() * 12.0, "feather", 0.01,
			randf_range(-0.6, 0.6), randf_range(-0.18, 0.18)))
	for _i in range(_pcount(26)):
		var a := randf() * TAU
		var sp := 0.6 + randf() * 1.8
		_particles.append(_mk(_target, Vector2(cos(a) * sp, sin(a) * sp * 0.6 - 0.5),
			1.6 + randf() * 0.9, 28.0 + randf() * 22.0, "haze", -0.008))
	# 바닥에서 솟는 안개
	for _i in range(_pcount(24)):
		var a := -PI / 2.0 + randf_range(-0.7, 0.7)
		var sp := 1.0 + randf() * 2.0
		_particles.append(_mk(_target + Vector2(0.0, 70.0),
			Vector2(cos(a) * sp * 0.5, sin(a) * sp - 0.6),
			1.1 + randf() * 0.7, 14.0 + randf() * 14.0, "haze", -0.01))

# 잔류 — 명중 후 타겟 주위에 천천히 떠오르는 빛 입자
func _spawn_linger() -> void:
	if randf() < 0.35:
		_particles.append(_mk(_target + Vector2(randf_range(-35.0, 35.0), randf_range(-25.0, 35.0)),
			Vector2(randf_range(-0.2, 0.2), -0.4 - randf() * 0.4),
			1.4 + randf() * 0.9, 1.3 + randf() * 1.4, "mote", 0.0))

func _process(delta: float) -> void:
	# 채널 중 시전자 손에서 빛 입자 상승
	if _channeling and randf() < 0.45:
		_spawn_channel_mote()

	# 빛의 칼 강하
	if _blade_t >= 0.0 and _blade_t < 1.0:
		_blade_t += delta / DESCENT_TIME

	# 기둥·글리프·충격파·십자 진행
	if _pillar_age >= 0.0:
		_pillar_age += delta
	if _glyph_age >= 0.0:
		_glyph_age += delta
	if _shock_life >= 0.0:
		_shock_life += delta / 0.8
	if _cross_age >= 0.0:
		_cross_age += delta

	# 잔류 빛 입자
	if _linger_timer > 0.0:
		_linger_timer -= delta
		_spawn_linger()

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
		if p["kind"] == "feather":
			p["rot"] += p["spin"] * delta * PSPEED
		alive.append(p)
	_particles = alive

	_smoke_layer.queue_redraw()
	_glow_layer.queue_redraw()

func _on_impact() -> void:
	_spawn_impact()
	_shock_life = 0.0
	_cross_age = 0.0
	_linger_timer = LINGER_TIME
	screen_effect.emit()

# ── 그리기 패스 — _DrawLayer 가 블렌드 모드별로 호출 ──
func _draw_smoke_pass(canvas: CanvasItem) -> void:
	# 빛기둥 — 위에서 아래로 자라는 세로 그라데이션 띠
	if _pillar_age >= 0.0:
		var grow: float = 1.0 - pow(1.0 - clampf(_pillar_age / DESCENT_TIME, 0.0, 1.0), 2.0)
		var pa := 0.5
		if _pillar_age > LINGER_TIME:
			pa *= clampf(1.0 - (_pillar_age - LINGER_TIME) / 1.4, 0.0, 1.0)
		if pa > 0.0:
			var quad := pillar_quad(_target, PILLAR_WIDTH, PILLAR_HEIGHT, grow)
			var cols := PackedColorArray([
				Color(COL_MID, pa), Color(COL_MID, pa),
				Color(COL_GOLD, 0.0), Color(COL_GOLD, 0.0)])
			canvas.draw_polygon(quad, cols)

	# 바닥 글리프 (누운 원근)
	if _glyph_age >= 0.0:
		_draw_glyph(canvas)

	# 황금 안개
	for p in _particles:
		if p["kind"] != "haze":
			continue
		var k: float = p["life"] / p["max_life"]
		var a: float = (1.0 - k) * 0.4
		var r: float = p["r"] * (1.0 + k * 1.4)
		canvas.draw_circle(p["pos"], r, Color(COL_HAZE, a))

	# 깃털
	for p in _particles:
		if p["kind"] != "feather":
			continue
		_draw_feather(canvas, p)

func _draw_glow_pass(canvas: CanvasItem) -> void:
	# 빛 입자 (밝은 점 + 십자 반짝임)
	for p in _particles:
		if p["kind"] != "mote":
			continue
		var k: float = p["life"] / p["max_life"]
		var a: float = 1.0 - k
		var pr: float = p["r"]
		var pos: Vector2 = p["pos"]
		var col := Color(1.0, 0.961 - 0.078 * k, 0.745 + 0.078 * k, a)
		canvas.draw_circle(pos, pr, col)
		canvas.draw_rect(Rect2(pos.x - pr * 2.5, pos.y - 0.3, pr * 5.0, 0.6), col)
		canvas.draw_rect(Rect2(pos.x - 0.3, pos.y - pr * 2.5, 0.6, pr * 5.0), col)

	# 강하하는 빛의 칼
	if _blade_t >= 0.0 and _blade_t < 1.0:
		_draw_blade(canvas)

	# 충격파 링
	if _shock_life >= 0.0 and _shock_life <= 1.0:
		var rad: float = 30.0 + _shock_life * 360.0
		var sa: float = (1.0 - _shock_life) * 0.85
		canvas.draw_arc(_target, rad, 0.0, TAU, 48, Color(COL_MID, sa), 1.0 + 4.0 * (1.0 - _shock_life), true)

	# 십자 섬광
	if _cross_age >= 0.0:
		_draw_cross_flash(canvas)

func _draw_blade(canvas: CanvasItem) -> void:
	var t := _blade_t
	var tip_y := lerpf(_target.y - PILLAR_HEIGHT, _target.y + 30.0, minf(1.0, t * 1.15))
	var blade_len := 220.0 + 80.0 * t
	var fade := maxf(0.0, 1.0 - maxf(0.0, (t - 0.6) / 0.4))
	var x := _target.x
	var top := Vector2(x, tip_y - blade_len)
	var tip := Vector2(x, tip_y)
	# 외곽 글로우 → 중간 → 흰 코어 → 황금 tip
	canvas.draw_line(top, tip, Color(COL_MID, 0.5 * fade), 38.0)
	canvas.draw_line(top, tip, Color(COL_MID, 0.85 * fade), 16.0)
	canvas.draw_line(top, tip, Color(COL_HOT, fade), 5.0)
	canvas.draw_line(Vector2(x, tip_y - blade_len * 0.6), tip, Color(COL_GOLD, 0.8 * fade), 2.0)

func _draw_cross_flash(canvas: CanvasItem) -> void:
	# crossIn: 0% scale .6 알파 0 → 20% scale 1.1 알파 1 → 100% scale 1.4 알파 0
	var t := _cross_age / 0.55
	if t >= 1.0:
		return
	var sc: float
	var a := 1.0
	if t < 0.2:
		# 등장 — 불투명하게 확대
		sc = lerpf(0.6, 1.1, t / 0.2)
	elif t < 0.75:
		# 유지 — 불투명, 살짝만 확대
		sc = lerpf(1.1, 1.2, (t - 0.2) / 0.55)
	else:
		# 소멸 — 빠르게 작아지며 사라짐
		var u := (t - 0.75) / 0.25
		sc = lerpf(1.2, 0.25, u)
		a = 1.0 - u
	var c := _target + Vector2(0.0, -40.0)
	var vh := 110.0 * sc   # 세로 막대 길이(반)
	var vw := 12.0 * sc    # 세로 막대 두께(반)
	var hw := 70.0 * sc    # 가로 막대 길이(반)
	var hh := 9.0 * sc     # 가로 막대 두께(반)
	var cross_y := c.y - vh + 78.0 * sc  # 가로 막대 위치 (HTML: 세로 상단에서 약간 아래)
	canvas.draw_rect(Rect2(c.x - vw, c.y - vh, vw * 2.0, vh * 2.0), Color(COL_MID, a))
	canvas.draw_rect(Rect2(c.x - hw, cross_y - hh, hw * 2.0, hh * 2.0), Color(COL_MID, a))
	# 흰 하이라이트
	canvas.draw_rect(Rect2(c.x - vw * 0.4, c.y - vh + 4.0, vw * 0.8, vh * 2.0 - 8.0), Color(COL_HOT, 0.8 * a))

func _draw_feather(canvas: CanvasItem, p: Dictionary) -> void:
	var a: float = 1.0 - p["life"] / p["max_life"]
	var r: float = p["r"]
	var rot: float = p["rot"]
	var pos: Vector2 = p["pos"]
	var body := PackedVector2Array()
	for i in range(10):
		var ang := TAU * float(i) / 10.0
		body.append(pos + Vector2(cos(ang) * r * 0.4, sin(ang) * r).rotated(rot))
	canvas.draw_colored_polygon(body, Color(COL_FEATHER, 0.95 * a))
	var mid_center: Vector2 = pos + Vector2(0.0, -r * 0.3).rotated(rot)
	var mid := PackedVector2Array()
	for i in range(8):
		var ang := TAU * float(i) / 8.0
		mid.append(mid_center + Vector2(cos(ang) * r * 0.15, sin(ang) * r * 0.5).rotated(rot))
	canvas.draw_colored_polygon(mid, Color(COL_GOLD, 0.7 * a))
	canvas.draw_line(pos + Vector2(0.0, -r).rotated(rot), pos + Vector2(0.0, r).rotated(rot),
		Color(COL_DEEP, 0.5 * a), 0.7)

func _draw_glyph(canvas: CanvasItem) -> void:
	var appear: float = clampf(_glyph_age / 0.6, 0.0, 1.0)
	var sc: float = lerpf(0.3, 1.0, appear)
	var spin: float = _glyph_age * 0.5
	var fade := 1.0
	if _glyph_age > LINGER_TIME:
		fade = clampf(1.0 - (_glyph_age - LINGER_TIME) / 1.4, 0.0, 1.0)
	var a: float = appear * fade * 0.92
	if a <= 0.0:
		return
	var gc := _target + Vector2(0.0, 40.0)
	# 동심원 3개 (누운 타원)
	var radii := [135.0, 118.0, 92.0]
	var ring_cols := [Color(COL_MID, 0.9 * a), Color(COL_HOT, 0.6 * a), Color(COL_GOLD, 0.5 * a)]
	for ri in range(3):
		var rad: float = float(radii[ri]) * sc
		var rc_col: Color = ring_cols[ri]
		var pts := PackedVector2Array()
		for i in range(48):
			var ang := TAU * float(i) / 48.0 + spin
			pts.append(gc + Vector2(cos(ang) * rad, sin(ang) * rad * GLYPH_SQUASH))
		canvas.draw_polyline(pts + PackedVector2Array([pts[0]]), rc_col, 1.4, true)
	# 16각 별 (바깥/안쪽 꼭짓점 교대)
	var star := PackedVector2Array()
	for i in range(16):
		var ang := TAU * float(i) / 16.0 + spin
		var sr: float = (118.0 if i % 2 == 0 else 70.0) * sc
		star.append(gc + Vector2(cos(ang) * sr, sin(ang) * sr * GLYPH_SQUASH))
	canvas.draw_polyline(star + PackedVector2Array([star[0]]), Color(COL_MID, 0.85 * a), 1.4, true)
	# 회전 사각형 (45° + spin)
	var sq := PackedVector2Array()
	for i in range(4):
		var ang := deg_to_rad(45.0) + spin + TAU * float(i) / 4.0
		var qr := 105.0 * sc
		sq.append(gc + Vector2(cos(ang) * qr, sin(ang) * qr * GLYPH_SQUASH))
	canvas.draw_polyline(sq + PackedVector2Array([sq[0]]), Color(COL_GOLD, 0.75 * a), 1.2, true)

# ── 블렌드 모드가 다른 두 그리기 레이어 ──
# 어두운 황금 안개는 가산이면 흐려지므로 일반 블렌드, 빛 입자·칼은 글로우용 가산 블렌드.
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
