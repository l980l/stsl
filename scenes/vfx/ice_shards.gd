# scenes/vfx/ice_shards.gd
# 시전자→타겟 얼음 공격 VFX — ui_sample/vfx/Ice Attack VFX.html 재현 (데미지 숫자 제외).
# battle_scene이 ice damage_type 공격 시 .new() → add_child → play(caster, target).
# 노드는 position (0,0)으로 add_child해야 한다 (좌표를 global로 받아 그대로 그림).
extends Node2D

const COL_HOT  := Color(1, 1, 1)              # 흰 코어
const COL_MID  := Color(0.749, 0.902, 1.0)    # #bfe6ff
const COL_DEEP := Color(0.353, 0.659, 0.902)  # #5aa8e6
const COL_BODY := Color(0.875, 0.949, 1.0)    # #dff2ff — 파편 바디
const COL_MIST := Color(0.863, 0.941, 1.0)    # 안개·반짝임

# 크기/타이밍 — 이 상수만 만지면 된다.
const ORB_CHARGE_START := 0.12  # 차지 구체 시작
const ORB_CHARGE_FULL  := 0.36  # 차지 완료
const FROST_FLOOR_SIZE := 1.28  # 바닥 서리 최대 가로 scale
const CHARGE_TIME      := 0.65  # 차지 시간(s)
const SHARD_COUNT      := 5     # 파편 개수
const SHARD_FLIGHT     := 0.32  # 파편 비행 시간(s)
const FREEZE_TIME      := 2.0   # 명중 후 눈보라·얼음 감옥 지속(s)
const PSPEED           := 60.0  # HTML(dt*0.06) → Godot(delta*60) 환산 계수

## 첫 파편 명중 순간 — 화면 플래시·흔들림·SFX·피격 피드백 요청 (battle_scene이 수신)
signal screen_effect

var _caster := Vector2.ZERO
var _target := Vector2.ZERO
var _charge_orb: Sprite2D
var _orbits: Node2D
var _frost_floor: Sprite2D
var _shards: Array = []     # [{t, ang, len, wid, offset, trail_t}]
var _particles: Array = []  # [{pos, vel, life, max_life, r, kind, grav, ang, spin}]
var _impacted := false
var _shock_life := -1.0     # <0 = 비활성, 0~1 = 충격파 링 진행
var _frost_life := -1.0     # <0 = 비활성, 0~1 = 바닥 서리 진행
var _shell_age := -1.0      # <0 = 비활성, 경과 초 (얼음 감옥)
var _freeze_timer := 0.0    # 눈보라 남은 시간

# ── 회전 다이아몬드 4점 (autoload 비의존 static — 단위 테스트 가능) ──
# center 중심, ang 방향의 마름모: 앞·옆·뒤·옆 순서.
static func diamond(center: Vector2, ang: float, half_len: float, half_wid: float) -> PackedVector2Array:
	var fwd := Vector2(cos(ang), sin(ang))
	var side := Vector2(-fwd.y, fwd.x)
	return PackedVector2Array([
		center + fwd * half_len,
		center - side * half_wid,
		center - fwd * half_len,
		center + side * half_wid,
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
	# _draw() 레이어는 가산 블렌드 — 굵은 반투명 + 가산으로 글로우 근사
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = mat
	set_process(false)

	var orb_tex := _make_orb_tex(COL_HOT, COL_MID, COL_DEEP)

	_frost_floor = Sprite2D.new()
	_frost_floor.texture = orb_tex
	_frost_floor.modulate = Color(1, 1, 1, 0.0)  # 알파만 제어 — 색은 텍스처가 가짐
	_frost_floor.scale = Vector2(0.0, 0.18)
	add_child(_frost_floor)

	_charge_orb = Sprite2D.new()
	_charge_orb.texture = orb_tex
	_charge_orb.modulate = Color(1, 1, 1, 0.0)
	_charge_orb.scale = Vector2(ORB_CHARGE_START, ORB_CHARGE_START)
	add_child(_charge_orb)

	# 차지 중 구체 주위를 공전하는 6개 작은 크리스탈
	_orbits = Node2D.new()
	_orbits.visible = false
	add_child(_orbits)
	for i in range(6):
		var crystal := Polygon2D.new()
		crystal.polygon = PackedVector2Array([
			Vector2(0.0, -8.0), Vector2(5.0, -2.5), Vector2(3.0, 8.0),
			Vector2(-3.0, 8.0), Vector2(-5.0, -2.5),
		])
		crystal.color = COL_MID
		var ang := TAU * float(i) / 6.0
		crystal.position = Vector2(cos(ang), sin(ang)) * 32.0
		_orbits.add_child(crystal)

# caster_pos / target_pos 는 global 좌표 (노드가 (0,0)에 있다는 전제)
func play(caster_pos: Vector2, target_pos: Vector2) -> void:
	_caster = caster_pos
	_target = target_pos
	_charge_orb.position = caster_pos
	_orbits.position = caster_pos
	_frost_floor.position = target_pos + Vector2(0.0, 64.0)
	_run()

func _run() -> void:
	# 1) 차지 — 시전자 손의 구체 + 6 크리스탈 공전 (0.65s)
	_orbits.visible = true
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(_charge_orb, "modulate:a", 1.0, 0.18)
	tw.parallel().tween_property(_charge_orb, "scale", Vector2(ORB_CHARGE_FULL, ORB_CHARGE_FULL), CHARGE_TIME)
	set_process(true)
	await get_tree().create_timer(CHARGE_TIME).timeout
	if not is_inside_tree():
		return
	# 2) 발사 — 구체 사라짐 + 5개 파편 (50ms 간격으로 어긋나게)
	var tw2 := create_tween()
	tw2.tween_property(_charge_orb, "modulate:a", 0.0, 0.12)
	_orbits.visible = false
	_spawn_shards()
	# 3) 비행·명중·눈보라는 _process에서. 정리.
	await get_tree().create_timer(CHARGE_TIME + FREEZE_TIME + 1.5).timeout
	if is_inside_tree():
		queue_free()

func _spawn_shards() -> void:
	var base_ang := (_target - _caster).angle()
	for i in range(SHARD_COUNT):
		_shards.append({
			"t": -float(i) * 0.05 / SHARD_FLIGHT,  # 음수 = 발사 지연
			"ang": base_ang + randf_range(-0.06, 0.06),
			"len": randf_range(30.0, 40.0),
			"wid": randf_range(8.0, 11.0),
			"offset": Vector2(0.0, randf_range(-14.0, 6.0)),
			"trail_t": 0.0,
		})

# 비행 중 파편 꽁무니의 서리 안개 + 작은 반짝임
func _spawn_frost_mist(pos: Vector2, intensity: float) -> void:
	for _i in range(int(6.0 * intensity)):
		_particles.append({
			"pos": pos + Vector2(randf_range(-5.0, 5.0), randf_range(-5.0, 5.0)),
			"vel": Vector2(randf_range(-0.3, 0.3), -0.2 - randf() * 0.5),
			"life": 0.0, "max_life": 0.5 + randf() * 0.5,
			"r": 6.0 + randf() * 12.0, "kind": "mist", "grav": -0.005,
			"ang": 0.0, "spin": 0.0,
		})
	for _i in range(int(3.0 * intensity)):
		_particles.append({
			"pos": pos,
			"vel": Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0) - 0.3),
			"life": 0.0, "max_life": 0.6 + randf() * 0.5,
			"r": 1.2 + randf() * 1.2, "kind": "sparkle", "grav": 0.005,
			"ang": 0.0, "spin": 0.0,
		})

# 명중 순간 — 회전 파편(chunk) + 큰 서리 안개(mist) + 십자 반짝임(sparkle)
func _spawn_impact_shatter(pos: Vector2) -> void:
	for _i in range(28):
		var a := randf() * TAU
		var sp := 2.0 + randf() * 5.0
		_particles.append({
			"pos": pos,
			"vel": Vector2(cos(a) * sp, sin(a) * sp - 1.2),
			"life": 0.0, "max_life": 0.7 + randf() * 0.5,
			"r": 3.0 + randf() * 5.0, "kind": "chunk", "grav": 0.06,
			"ang": a, "spin": randf_range(-0.3, 0.3),
		})
	for _i in range(60):
		var a := randf() * TAU
		var sp := 0.8 + randf() * 3.0
		_particles.append({
			"pos": pos,
			"vel": Vector2(cos(a) * sp, sin(a) * sp * 0.7 - 0.4),
			"life": 0.0, "max_life": 0.9 + randf() * 0.7,
			"r": 16.0 + randf() * 22.0, "kind": "mist", "grav": -0.01,
			"ang": 0.0, "spin": 0.0,
		})
	for _i in range(50):
		var a := randf() * TAU
		var sp := 1.0 + randf() * 4.0
		_particles.append({
			"pos": pos,
			"vel": Vector2(cos(a) * sp, sin(a) * sp - 0.5),
			"life": 0.0, "max_life": 0.9 + randf() * 0.6,
			"r": 1.0 + randf() * 1.4, "kind": "sparkle", "grav": 0.02,
			"ang": 0.0, "spin": 0.0,
		})

# 눈보라 — 명중 후 타겟 주위에 천천히 흩날리는 눈
func _spawn_snow() -> void:
	_particles.append({
		"pos": _target + Vector2(randf_range(-120.0, 120.0), randf_range(-90.0, -30.0)),
		"vel": Vector2(randf_range(-0.3, 0.3), 0.3 + randf() * 0.5),
		"life": 0.0, "max_life": 1.4 + randf() * 1.0,
		"r": 1.2 + randf() * 1.2, "kind": "snow", "grav": 0.0,
		"ang": 0.0, "spin": 0.0,
	})

func _shard_pos(s: Dictionary) -> Vector2:
	var t: float = clampf(s["t"], 0.0, 1.0)
	var e: float = 1.0 - pow(1.0 - t, 2.0)  # ease-out
	return _caster.lerp(_target + s["offset"], e)

func _process(delta: float) -> void:
	# 차지 중 크리스탈 공전
	if _orbits.visible:
		_orbits.rotation += delta * 5.0

	# 파편 비행 + 꽁무니 안개
	for s in _shards:
		s["t"] += delta / SHARD_FLIGHT
		if s["t"] >= 0.0:
			s["trail_t"] -= delta
			if s["trail_t"] <= 0.0:
				_spawn_frost_mist(_shard_pos(s), 0.6)
				s["trail_t"] = 0.03

	# 명중 판정 — 가장 앞선 파편이 1.0 도달 시 (한 번만)
	if not _impacted:
		for s in _shards:
			if s["t"] >= 1.0:
				_on_impact()
				break

	# 명중 지점 통과한 파편 제거
	var alive_shards: Array = []
	for s in _shards:
		if s["t"] < 1.05:
			alive_shards.append(s)
	_shards = alive_shards

	# 파티클 물리 (HTML frame() 포팅) — 수명 만료 시 제거
	var damp: float = pow(0.992, delta * 60.0)
	var alive_p: Array = []
	for p in _particles:
		p["life"] += delta
		if p["life"] >= p["max_life"]:
			continue
		p["pos"] += p["vel"] * delta * PSPEED
		p["vel"].y += p["grav"] * delta * PSPEED
		p["vel"] *= damp
		if p["kind"] == "chunk":
			p["ang"] += p["spin"] * delta * PSPEED
		alive_p.append(p)
	_particles = alive_p

	# 눈보라 — 명중 후 FREEZE_TIME 동안 지속 생성
	if _freeze_timer > 0.0:
		_freeze_timer -= delta
		if randf() < 0.7:
			_spawn_snow()

	# 충격파 링 / 바닥 서리 / 얼음 감옥 진행
	if _shock_life >= 0.0:
		_shock_life += delta / 0.6
	if _frost_life >= 0.0:
		_frost_life = minf(_frost_life + delta / 1.0, 1.0)
		_frost_floor.scale.x = FROST_FLOOR_SIZE * _frost_life
		_frost_floor.modulate.a = 0.55 * (1.0 - _frost_life * 0.3)
	if _shell_age >= 0.0:
		_shell_age += delta

	queue_redraw()

func _on_impact() -> void:
	_impacted = true
	_spawn_impact_shatter(_target)
	_shock_life = 0.0
	_frost_life = 0.0
	_shell_age = 0.0
	_freeze_timer = FREEZE_TIME
	screen_effect.emit()

func _draw() -> void:
	# 1) 서리 안개 (큰 반투명 원)
	for p in _particles:
		if p["kind"] != "mist":
			continue
		var k: float = p["life"] / p["max_life"]
		var a: float = (1.0 - k) * 0.32
		var r: float = p["r"] * (1.0 + k * 1.2)
		draw_circle(p["pos"], r, Color(COL_MIST, a))

	# 2) 눈 (작은 점)
	for p in _particles:
		if p["kind"] != "snow":
			continue
		var a: float = (1.0 - p["life"] / p["max_life"]) * 0.6
		draw_circle(p["pos"], p["r"], Color(COL_MIST, a))

	# 3) 반짝임 (밝은 점 + 십자)
	for p in _particles:
		if p["kind"] != "sparkle":
			continue
		var a: float = 1.0 - p["life"] / p["max_life"]
		var pr: float = p["r"]
		var pos: Vector2 = p["pos"]
		draw_circle(pos, pr, Color(COL_HOT, a))
		draw_rect(Rect2(pos.x - pr * 2.5, pos.y - 0.3, pr * 5.0, 0.6), Color(COL_HOT, a))
		draw_rect(Rect2(pos.x - 0.3, pos.y - pr * 2.5, 0.6, pr * 5.0), Color(COL_HOT, a))

	# 4) 부서진 얼음 조각 (회전 다이아몬드)
	for p in _particles:
		if p["kind"] != "chunk":
			continue
		var a: float = 1.0 - p["life"] / p["max_life"]
		var d := diamond(p["pos"], p["ang"], p["r"], p["r"] * 0.6)
		draw_colored_polygon(d, Color(COL_BODY, 0.9 * a))
		draw_polyline(d + PackedVector2Array([d[0]]), Color(COL_HOT, 0.9 * a), 0.8, true)

	# 5) 충격파 링
	if _shock_life >= 0.0 and _shock_life <= 1.0:
		var rad: float = 14.0 + _shock_life * 320.0
		var sa: float = (1.0 - _shock_life) * 0.8
		draw_arc(_target, rad, 0.0, TAU, 48, Color(COL_MID, sa), 1.0 + 3.0 * (1.0 - _shock_life), true)

	# 6) 파편 발사체 — 외곽 글로우 + 다이아몬드 바디 + 내부 하이라이트
	for s in _shards:
		if s["t"] < 0.0:
			continue
		var sp := _shard_pos(s)
		var ang: float = s["ang"]
		var hl: float = s["len"] * 0.5
		var hw: float = s["wid"] * 0.5
		draw_circle(sp, s["len"] * 0.7, Color(COL_DEEP, 0.16))
		var body := diamond(sp, ang, hl, hw)
		draw_colored_polygon(body, COL_BODY)
		draw_polyline(body + PackedVector2Array([body[0]]), COL_HOT, 1.2, true)
		draw_colored_polygon(diamond(sp, ang, hl * 0.5, hw * 0.45), Color(COL_HOT, 0.9))

	# 7) 얼음 감옥 — 타겟을 감싸는 바닥 고드름 + 몸 윤곽
	if _shell_age >= 0.0:
		_draw_ice_shell()

# 명중 후 타겟 주위에 솟는 얼음 결정 (HTML .ice-shell SVG 근사)
func _draw_ice_shell() -> void:
	var appear: float = clampf(_shell_age / 0.35, 0.0, 1.0)
	var fade := 1.0
	if _shell_age > FREEZE_TIME:
		fade = clampf(1.0 - (_shell_age - FREEZE_TIME) / 0.4, 0.0, 1.0)
	var a: float = appear * fade
	if a <= 0.0:
		return
	var sc: float = lerpf(0.7, 1.0, appear)
	# 바닥 고드름 5개 — [중심 x오프셋, 높이]
	var base_y: float = _target.y + 58.0
	var spikes := [
		Vector2(-54.0, 64.0), Vector2(-27.0, 96.0), Vector2(0.0, 120.0),
		Vector2(29.0, 90.0), Vector2(52.0, 70.0),
	]
	for sp in spikes:
		var bx: float = _target.x + sp.x * sc
		var h: float = sp.y * sc
		var w: float = 13.0 * sc
		var tri := PackedVector2Array([
			Vector2(bx - w, base_y), Vector2(bx, base_y - h), Vector2(bx + w, base_y),
		])
		draw_colored_polygon(tri, Color(COL_MID, 0.5 * a))
		draw_polyline(tri + PackedVector2Array([tri[0]]), Color(COL_HOT, 0.6 * a), 1.0, true)
	# 몸 윤곽 — 타겟을 감싸는 각진 결정 외곽선
	var c := _target
	var outline := PackedVector2Array([
		c + Vector2(-44.0, -88.0) * sc, c + Vector2(8.0, -104.0) * sc,
		c + Vector2(50.0, -82.0) * sc, c + Vector2(58.0, -20.0) * sc,
		c + Vector2(44.0, 44.0) * sc, c + Vector2(-6.0, 58.0) * sc,
		c + Vector2(-52.0, 30.0) * sc, c + Vector2(-58.0, -36.0) * sc,
	])
	draw_colored_polygon(outline, Color(COL_MID, 0.14 * a))
	draw_polyline(outline + PackedVector2Array([outline[0]]), Color(COL_HOT, 0.5 * a), 1.2, true)
