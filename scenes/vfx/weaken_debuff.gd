# scenes/vfx/weaken_debuff.gd
# 약화(weak) 디버프 VFX — ui_sample/vfx/Weaken VFX.html 재현 (스탯 텍스트 제외).
# battle_scene 이 weak 디버프 적용 시 .new() → add_child → play(caster, target).
# 단계: GRIP 0.34s (시전자 손 흡수 룬 + 주먹 쥠) → IMPACT (움켜쥐는 룬 닫힘 + siphon 실 개방 +
#       힘 흡수 burst) → SAP 2.0s (시든 검·처진 ▼·발치 웅덩이·잿빛 가라앉음) → fade.
# 글로우 벡터(룬·siphon 실·beads·시든 검·▼)는 CPU draw. 가라앉는 mote·smoke 는 _gpu 서브클래스에서 GPU.
# 노드는 position (0,0) 으로 add_child (좌표를 global 로 받아 그대로 그림).
extends Node2D

var _particle_scale_override: float = -1.0  # vfx_preview 비교용 (음수=GameSettings)

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

# 색 — 병든 sage(녹) + 잿빛
const COL_WEAK_HOT  := Color(0.914, 0.945, 0.918)  # #e9f1ea
const COL_WEAK      := Color(0.561, 0.702, 0.612)  # #8fb39c
const COL_WEAK_MID  := Color(0.361, 0.510, 0.439)  # #5c8270
const COL_WEAK_DEEP := Color(0.180, 0.290, 0.251)  # #2e4a40
const COL_ASH       := Color(0.604, 0.639, 0.604)  # #9aa39a
const COL_PALE      := Color(0.655, 0.796, 0.706)  # #a7cbb4

# 타이밍
const GRIP_TIME    := 0.34
const IMPACT_DELAY := GRIP_TIME  # battle_manager 동기화 (impact = 룬 닫힘)
const SIPHON_TIME  := 1.0   # 흡수 실·beads 지속
const SAP_TIME     := 2.0   # 약화 상태(룬·시든 검·▼·웅덩이) 지속
const FADE_TIME    := 0.6
const PSPEED       := 60.0
const ORB_SCALE    := 0.3   # 차지 룬 최대 스케일 (256px tex 기준)

# 위치 offset
const CHEST_OFFSET := Vector2(0.0, -6.0)
const WILT_OFFSET  := Vector2(0.0, -92.0)  # 머리 위 시든 검
const POOL_OFFSET  := Vector2(0.0, 88.0)   # 발치 잿빛 웅덩이
const GRIP_RADIUS  := 58.0

## 룬 닫힘 순간 — 화면 흔들림·SFX 요청 (battle_scene 이 수신)
signal screen_effect

var _caster := Vector2.ZERO
var _target := Vector2.ZERO
var _chest := Vector2.ZERO
var _hand := Vector2.ZERO
var _charge_orb: Sprite2D
var _glow_layer: Node2D   # 가산 — 룬·siphon·beads·시든 검·▼·sink mote
var _smoke_layer: Node2D  # 일반 — smoke·웅덩이

var _particles: Array = []   # CPU 파티클 (bead 는 항상 CPU, sink/smoke 는 GPU 서브클래스가 비움)
var _curves: Array = []      # siphon bezier [{p0, ctrl, p1}]
var _sap_age: float = -1.0   # <0 비활성, impact 후 경과초
var _siphon_on: bool = false
var _siphon_age: float = 0.0
var _bead_timer: float = 0.0
var _sap_emit_timer: float = 0.0

static func _make_orb_tex() -> GradientTexture2D:
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.42, 0.80, 1.0])
	grad.colors = PackedColorArray([
		COL_WEAK_HOT, COL_WEAK, COL_WEAK_DEEP,
		Color(COL_WEAK_DEEP.r, COL_WEAK_DEEP.g, COL_WEAK_DEEP.b, 0.0)])
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
	_charge_orb.texture = _make_orb_tex()
	_charge_orb.modulate = Color(1, 1, 1, 0.0)
	_charge_orb.scale = Vector2(0.05, 0.05)
	add_child(_charge_orb)
	_glow_layer = _DrawLayer.new()
	_glow_layer.setup(self, true)
	add_child(_glow_layer)

func play(caster_pos: Vector2, target_pos: Vector2) -> void:
	_caster = caster_pos
	_target = target_pos
	_chest = target_pos + CHEST_OFFSET
	_hand = caster_pos + Vector2(0.0, -30.0)
	_charge_orb.position = _hand
	_run()

func _run() -> void:
	set_process(true)
	# 1) GRIP — 시전자 손의 흡수 룬 (sage)
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(_charge_orb, "modulate:a", 1.0, 0.2)
	tw.parallel().tween_property(_charge_orb, "scale", Vector2(ORB_SCALE, ORB_SCALE), GRIP_TIME)
	await get_tree().create_timer(GRIP_TIME).timeout
	if not is_inside_tree():
		return
	# 2) IMPACT — 룬이 타겟을 움켜쥠 + siphon 실 개방 + 힘 흡수 burst
	create_tween().tween_property(_charge_orb, "modulate:a", 0.0, 0.16)
	_sap_age = 0.0
	_siphon_on = true
	_siphon_age = 0.0
	_sap_emit_timer = SAP_TIME
	_build_siphon_curves()
	screen_effect.emit()
	_spawn_drain_burst(_chest)
	# 3) siphon 실은 SIPHON_TIME 후 사라짐
	get_tree().create_timer(SIPHON_TIME).timeout.connect(func() -> void: _siphon_on = false)
	# 4) SAP 지속 + fade 후 종료
	await get_tree().create_timer(SAP_TIME + FADE_TIME + 0.5).timeout
	if is_inside_tree():
		queue_free()

func _build_siphon_curves() -> void:
	_curves.clear()
	for i in range(4):
		var mid := (_chest + _hand) * 0.5
		mid += Vector2(randf_range(-20.0, 20.0), -40.0 - i * 18.0)
		_curves.append({"p0": _chest, "ctrl": mid, "p1": _hand})

static func _bez(c: Dictionary, t: float) -> Vector2:
	var mt: float = 1.0 - t
	return (c["p0"] as Vector2) * (mt * mt) + (c["ctrl"] as Vector2) * (2.0 * mt * t) + (c["p1"] as Vector2) * (t * t)

func _mk(pos: Vector2, vel: Vector2, max_life: float, r: float, kind: String,
		grav: float, tint: String = "sage") -> Dictionary:
	return {"pos": pos, "vel": vel, "life": 0.0, "max_life": max_life,
		"r": r, "kind": kind, "grav": grav, "tint": tint}

# ── 파티클 spawn (GPU 서브클래스가 override) ──
# 힘 흡수 burst — 아래로 빠지는 sink mote + 잿빛 smoke
func _spawn_drain_burst(pos: Vector2) -> void:
	for _i in _pcount(30):
		var ang := PI * 0.25 + randf() * PI * 0.5  # 아래쪽 부채꼴
		var sp := (1.0 + randf() * 3.0) * PSPEED
		var vx := cos(ang) * sp * (1.0 if randf() < 0.5 else -1.0) * 0.5
		var tint := "sage" if randf() < 0.5 else "ash"
		_particles.append(_mk(pos + Vector2(randf_range(-15.0, 15.0), 0.0),
			Vector2(vx, sin(ang) * sp + 0.4 * PSPEED),
			0.9 + randf() * 0.7, 1.4 + randf() * 1.8, "sink", 0.02 * PSPEED, tint))
	for _i in _pcount(12):
		_particles.append(_mk(pos + Vector2(randf_range(-20.0, 20.0), 0.0),
			Vector2(randf_range(-0.5, 0.5) * PSPEED, (0.2 + randf() * 0.4) * PSPEED),
			1.1 + randf() * 0.7, 16.0 + randf() * 16.0, "smoke", 0.0))

# SAP 중 — 타겟에서 가라앉는 잿빛 활력 (매 프레임 확률 spawn)
func _spawn_sap_ambient() -> void:
	if randf() < 0.6 * _scale():
		var tint := "sage" if randf() < 0.5 else "ash"
		_particles.append(_mk(_chest + Vector2(randf_range(-35.0, 35.0), randf_range(-25.0, 25.0)),
			Vector2(randf_range(-0.18, 0.18), 0.25 + randf() * 0.4) * PSPEED,
			1.1 + randf() * 0.7, 1.4 + randf() * 1.6, "sink", 0.0, tint))
	if randf() < 0.3 * _scale():
		_particles.append(_mk(_chest + Vector2(randf_range(-30.0, 30.0), 10.0),
			Vector2(randf_range(-0.15, 0.15), 0.12 + randf() * 0.18) * PSPEED,
			1.4 + randf() * 0.8, 14.0 + randf() * 14.0, "smoke", 0.0))

func _process(delta: float) -> void:
	# siphon beads spawn (CPU — 베지어 경로)
	if _siphon_on and not _curves.is_empty():
		_bead_timer += delta
		if _bead_timer >= 0.03:
			_bead_timer = 0.0
			for _i in _pcount(2):
				_particles.append({"kind": "bead", "ci": randi() % _curves.size(), "t": 0.0,
					"speed": 0.9 + randf() * 0.9, "r": 1.6 + randf() * 1.6,
					"tint": "pale" if randf() < 0.4 else "sage"})
	_siphon_age += delta
	# 파티클 update
	var damp: float = pow(0.99, delta * 60.0)
	for i in range(_particles.size() - 1, -1, -1):
		var p: Dictionary = _particles[i]
		if p["kind"] == "bead":  # 베지어 경로 — life 없이 t 로 진행
			p["t"] = float(p["t"]) + float(p["speed"]) * delta
			if float(p["t"]) >= 1.0:
				_particles.remove_at(i)
			continue
		p["life"] = float(p["life"]) + delta
		if float(p["life"]) >= float(p["max_life"]):
			_particles.remove_at(i)
			continue
		var pos: Vector2 = p["pos"]
		var vel: Vector2 = p["vel"]
		pos += vel * delta
		vel.y += float(p["grav"]) * delta
		vel *= damp
		p["pos"] = pos
		p["vel"] = vel
	# SAP 중 잿빛 가라앉음 생성
	if _sap_emit_timer > 0.0:
		_sap_emit_timer -= delta
		_spawn_sap_ambient()
	if _sap_age >= 0.0:
		_sap_age += delta
	_smoke_layer.queue_redraw()
	_glow_layer.queue_redraw()

# SAP 요소 공통 alpha — SAP_TIME 까지 1.0, 이후 FADE_TIME 동안 0
func _sap_alpha() -> float:
	if _sap_age < SAP_TIME:
		return 1.0
	return clampf(1.0 - (_sap_age - SAP_TIME) / FADE_TIME, 0.0, 1.0)

# ── 그리기 패스 ──
func _draw_smoke_pass(canvas: CanvasItem) -> void:
	# 잿빛 smoke (가라앉음)
	for p in _particles:
		if p["kind"] != "smoke":
			continue
		var k: float = float(p["life"]) / float(p["max_life"])
		var a: float = (1.0 - k) * 0.3
		var r: float = float(p["r"]) * (1.0 + k * 1.4)
		canvas.draw_circle(p["pos"], r, Color(0.31, 0.42, 0.37, a))
	# 발치 잿빛 웅덩이
	if _sap_age >= 0.0:
		var sa: float = _sap_alpha()
		var spread: float = clampf(_sap_age / 0.8, 0.0, 1.0)
		if sa > 0.0 and spread > 0.0:
			var pool := _target + POOL_OFFSET
			canvas.draw_set_transform(pool, 0.0, Vector2(spread, 0.32))
			canvas.draw_circle(Vector2.ZERO, 96.0, Color(COL_WEAK_MID.r, COL_WEAK_MID.g, COL_WEAK_MID.b, 0.5 * sa))
			canvas.draw_circle(Vector2.ZERO, 64.0, Color(COL_WEAK_DEEP.r, COL_WEAK_DEEP.g, COL_WEAK_DEEP.b, 0.4 * sa))
			canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_glow_pass(canvas: CanvasItem) -> void:
	# siphon 실 + beads
	if _siphon_on or _siphon_age < SIPHON_TIME + 0.4:
		_draw_siphon(canvas)
	_draw_beads(canvas)
	# SAP 요소
	if _sap_age >= 0.0:
		var sa: float = _sap_alpha()
		if sa > 0.0:
			var ap: float = clampf(_sap_age / 0.4, 0.0, 1.0)
			_draw_grip_rune(canvas, sa, ap)
			_draw_wilt(canvas, sa, ap)
			_draw_droop(canvas, sa, ap)
	# sink mote
	_draw_sink_motes(canvas)

func _draw_siphon(canvas: CanvasItem) -> void:
	var fade: float = 1.0
	if not _siphon_on:
		fade = clampf(1.0 - (_siphon_age - SIPHON_TIME) / 0.4, 0.0, 1.0)
	if fade <= 0.0:
		return
	for c in _curves:
		var pts := PackedVector2Array()
		for i in range(13):
			pts.push_back(_bez(c, float(i) / 12.0))
		canvas.draw_polyline(pts, Color(0.47, 0.63, 0.54, 0.22 * fade), 2.0)

func _draw_beads(canvas: CanvasItem) -> void:
	for p in _particles:
		if p["kind"] != "bead":
			continue
		var ci: int = int(p["ci"])
		if ci < 0 or ci >= _curves.size():
			continue
		var t: float = float(p["t"])
		var pt: Vector2 = _bez(_curves[ci], t)
		var a: float = sin(t * PI)
		var col := COL_PALE if p["tint"] == "pale" else COL_WEAK
		var r: float = float(p["r"])
		canvas.draw_circle(pt, r * 1.8, Color(col.r, col.g, col.b, 0.4 * a))
		canvas.draw_circle(pt, r, Color(col.r, col.g, col.b, a))

func _draw_sink_motes(canvas: CanvasItem) -> void:
	for p in _particles:
		if p["kind"] != "sink":
			continue
		var a: float = 1.0 - float(p["life"]) / float(p["max_life"])
		var col := COL_ASH if p["tint"] == "ash" else COL_WEAK
		canvas.draw_circle(p["pos"], float(p["r"]), Color(col.r, col.g, col.b, a))

# 움켜쥐는 룬 — 동심원(점선 근사) + 6 갈고리(안쪽으로) + 내원. 천천히 역회전.
func _draw_grip_rune(canvas: CanvasItem, sa: float, ap: float) -> void:
	var c := _chest
	var sc: float = lerpf(1.6, 1.0, ap)
	var rot: float = -_sap_age * 0.35
	var rr: float = GRIP_RADIUS * sc
	canvas.draw_arc(c, rr, 0.0, TAU, 52, Color(COL_WEAK.r, COL_WEAK.g, COL_WEAK.b, 0.32 * sa), 1.0)
	canvas.draw_arc(c, rr * 0.54, 0.0, TAU, 40, Color(COL_WEAK_MID.r, COL_WEAK_MID.g, COL_WEAK_MID.b, 0.5 * sa), 1.0)
	var col := Color(COL_PALE.r, COL_PALE.g, COL_PALE.b, 0.9 * sa)
	for i in range(6):
		var ang: float = rot + deg_to_rad(60.0 * i)
		var dir := Vector2(cos(ang), sin(ang))
		var perp := Vector2(-dir.y, dir.x)
		var outer := c + dir * rr
		var inner := c + dir * (rr * 0.5)
		var ctrl := c + dir * (rr * 0.78) + perp * (rr * 0.26)  # 접선 방향 갈고리
		var hook := PackedVector2Array()
		for s in range(7):
			var tt: float = float(s) / 6.0
			var mt: float = 1.0 - tt
			hook.push_back(outer * (mt * mt) + ctrl * (2.0 * mt * tt) + inner * (tt * tt))
		canvas.draw_polyline(hook, col, 2.0)

# 시든 검 — 머리 위. 휘어 처진 칼날 + 처진 십자 가드 + 활력 방울 2.
func _draw_wilt(canvas: CanvasItem, sa: float, ap: float) -> void:
	var c := _target + WILT_OFFSET + Vector2(0.0, sin(_sap_age * 2.0) * 4.0 + (1.0 - ap) * -18.0)
	var s := 0.9 * lerpf(0.7, 1.0, ap)
	var blade := Color(COL_WEAK.r, COL_WEAK.g, COL_WEAK.b, 0.95 * sa)
	var hi := Color(COL_PALE.r, COL_PALE.g, COL_PALE.b, 0.8 * sa)
	# 휘어 처진 칼날 (위→아래로 sag) — 베지어 근사
	var p0 := c + Vector2(0, -34) * s
	var p1 := c + Vector2(6, 8) * s
	var p2 := c + Vector2(-16, 40) * s
	var blade_pts := PackedVector2Array()
	for i in range(11):
		var tt: float = float(i) / 10.0
		var mt: float = 1.0 - tt
		blade_pts.push_back(p0 * (mt * mt) + p1 * (2.0 * mt * tt) + p2 * (tt * tt))
	canvas.draw_polyline(blade_pts, blade, 4.0)
	canvas.draw_polyline(blade_pts, hi, 1.4)
	# 처진 십자 가드 (아래로 휜 호)
	var g0 := c + Vector2(-20, -16) * s
	var gm := c + Vector2(0, -8) * s
	var g1 := c + Vector2(20, -16) * s
	var guard := PackedVector2Array()
	for i in range(9):
		var tt: float = float(i) / 8.0
		var mt: float = 1.0 - tt
		guard.push_back(g0 * (mt * mt) + gm * (2.0 * mt * tt) + g1 * (tt * tt))
	canvas.draw_polyline(guard, Color(COL_WEAK.r, COL_WEAK.g, COL_WEAK.b, 0.85 * sa), 3.0)
	# 떨어지는 활력 방울
	canvas.draw_circle(c + Vector2(-16, 44) * s, 2.4, Color(COL_WEAK.r, COL_WEAK.g, COL_WEAK.b, 0.9 * sa))
	canvas.draw_circle(c + Vector2(-12, 52) * s, 1.6, Color(COL_WEAK_MID.r, COL_WEAK_MID.g, COL_WEAK_MID.b, 0.8 * sa))

# 처진 ▼ 3개 — 약화(공격력 ↓) 모티프
func _draw_droop(canvas: CanvasItem, sa: float, ap: float) -> void:
	var base := _chest + Vector2(0.0, 30.0 + (1.0 - ap) * -8.0)
	var hang: float = sin(_sap_age * 2.2) * 3.0
	var specs := [
		{"off": Vector2(-16, 2), "sz": 7.0, "col": COL_WEAK},
		{"off": Vector2(0, 0), "sz": 9.0, "col": COL_WEAK_HOT},
		{"off": Vector2(16, 6), "sz": 6.0, "col": COL_WEAK_MID},
	]
	for sp in specs:
		var cc: Vector2 = base + (sp["off"] as Vector2) + Vector2(0.0, hang)
		var z: float = sp["sz"]
		var col: Color = sp["col"]
		var tri := PackedVector2Array([cc + Vector2(-z, -z), cc + Vector2(z, -z), cc + Vector2(0, z)])
		canvas.draw_colored_polygon(tri, Color(col.r, col.g, col.b, 0.9 * sa))

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
