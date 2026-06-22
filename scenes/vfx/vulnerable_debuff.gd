# scenes/vfx/vulnerable_debuff.gd
# 취약(vulnerable) 디버프 VFX — ui_sample/vfx/Vulnerability Debuff VFX.html 재현 (스탯 텍스트 제외).
# battle_scene 이 vulnerable 디버프 적용 시 .new() → add_child → play(caster, target).
# 단계: CHARGE 0.32s (시전자 손 brass/blood 구체) → SPIKE 0.18s (파쇄 쐐기 강하) →
#       IMPACT (screen_effect: 갑옷 파쇄 — 균열·파편) → EXPOSED 2.0s (약점 표식·깨진 방패·funnel·잔불) → fade.
# 글로우 벡터(쐐기·균열·표식·방패·funnel)는 CPU draw. 파편·잔불 파티클은 _gpu 서브클래스에서 GPU 로 대체.
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

# 색 — HTML --vuln 계열(blood) + brass
const COL_VULN      := Color(0.851, 0.290, 0.314)  # #d94a50
const COL_VULN_MID  := Color(0.698, 0.165, 0.188)  # #b22a30
const COL_VULN_DEEP := Color(0.420, 0.078, 0.094)  # #6b1418
const COL_WARN      := Color(0.910, 0.784, 0.471)  # #e8c878 brass
const COL_RED_HOT   := Color(1.0, 0.420, 0.471)    # #ff6b78

# 타이밍
const CHARGE_TIME  := 0.32
const SPIKE_TIME   := 0.18
const IMPACT_DELAY := CHARGE_TIME + SPIKE_TIME  # 0.50 — battle_manager 동기화 (impact = 쐐기 명중)
const EXPOSED_TIME := 2.0   # 노출 상태(균열·표식·방패·잔불) 지속
const FADE_TIME    := 0.6
const PSPEED       := 60.0  # HTML(dt*0.06) → Godot(delta*60) 환산

# 위치 offset (chest = 타겟 가슴 기준)
const CHEST_OFFSET  := Vector2(0.0, -6.0)
const SHIELD_OFFSET := Vector2(0.0, -6.0)   # 타겟 중앙 깨진 방패 (구 머리 위 → 중앙)
const SHIELD_SCALE  := 1.9                  # 깨진 방패 크기 배율 (중앙 강조)
const ORB_SCALE     := 0.3                  # 차지 구체 최대 스케일 (256px tex 기준 — 과대 방지)
const SPIKE_TOP     := -160.0               # 쐐기 시작 높이 (chest 기준)
const SPIKE_LEN     := 130.0

## 쐐기 명중 순간 — 화면 흔들림·SFX 요청 (battle_scene 이 수신)
signal screen_effect

var _caster := Vector2.ZERO
var _target := Vector2.ZERO
var _chest := Vector2.ZERO
var _charge_orb: Sprite2D
var _glow_layer: Node2D   # 가산 — 쐐기·균열·표식·방패·funnel·mote
var _smoke_layer: Node2D  # 일반 — dust

var _particles: Array = []  # CPU 파티클 (GPU 서브클래스는 비워둠)

var _spike_prog: float = -1.0   # <0 비활성, 0→1 강하
var _expose_age: float = -1.0   # <0 비활성, impact 후 경과초
var _crack_prog: float = 0.0    # 균열 draw-on 0→1
var _shield_split: float = 0.0  # 방패 분리 0→1
var _embers_timer: float = 0.0

# 라디얼 그라데이션 구체 (brass-core blood orb)
static func _make_orb_tex() -> GradientTexture2D:
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.24, 0.55, 0.82, 1.0])
	grad.colors = PackedColorArray([
		Color(1, 1, 1, 1.0), COL_WARN, COL_VULN, COL_VULN_DEEP,
		Color(COL_VULN_DEEP.r, COL_VULN_DEEP.g, COL_VULN_DEEP.b, 0.0)])
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
	_charge_orb.modulate = Color(1, 1, 1, 0.0)  # 알파만 제어 — 색은 텍스처
	_charge_orb.scale = Vector2(0.05, 0.05)
	add_child(_charge_orb)
	_glow_layer = _DrawLayer.new()
	_glow_layer.setup(self, true)
	add_child(_glow_layer)

func play(caster_pos: Vector2, target_pos: Vector2) -> void:
	_caster = caster_pos
	_target = target_pos
	_chest = target_pos + CHEST_OFFSET
	_charge_orb.position = caster_pos + Vector2(0.0, -30.0)
	_run()

func _run() -> void:
	set_process(true)
	# 1) CHARGE — 시전자 손의 brass/blood 구체
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(_charge_orb, "modulate:a", 1.0, 0.18)
	tw.parallel().tween_property(_charge_orb, "scale", Vector2(ORB_SCALE, ORB_SCALE), CHARGE_TIME)
	await get_tree().create_timer(CHARGE_TIME).timeout
	if not is_inside_tree():
		return
	# 2) SPIKE — 구체 사라짐 + 파쇄 쐐기 강하
	create_tween().tween_property(_charge_orb, "modulate:a", 0.0, 0.12)
	_spike_prog = 0.0
	var tws := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tws.tween_property(self, "_spike_prog", 1.0, SPIKE_TIME)
	await tws.finished
	if not is_inside_tree():
		return
	# 3) IMPACT — 갑옷 파쇄 (균열·파편), 노출 상태 진입
	_spike_prog = -1.0
	_expose_age = 0.0
	_embers_timer = EXPOSED_TIME
	screen_effect.emit()
	_spawn_shatter(_chest)
	create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT) \
		.tween_property(self, "_crack_prog", 1.0, 0.28)
	create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT) \
		.tween_property(self, "_shield_split", 1.0, 1.1)
	# 4) EXPOSED 지속 + fade (draw 가 _expose_age 로 alpha 계산) 후 종료
	await get_tree().create_timer(EXPOSED_TIME + FADE_TIME + 0.5).timeout
	if is_inside_tree():
		queue_free()

func _mk(pos: Vector2, vel: Vector2, max_life: float, r: float, kind: String,
		grav: float, rot: float = 0.0, vrot: float = 0.0) -> Dictionary:
	return {"pos": pos, "vel": vel, "life": 0.0, "max_life": max_life,
		"r": r, "kind": kind, "grav": grav, "rot": rot, "vrot": vrot}

# ── 파티클 spawn (GPU 서브클래스가 override) ──
# 갑옷 파편(shard) + brass/red mote + dust
func _spawn_shatter(pos: Vector2) -> void:
	for _i in _pcount(24):
		var a := randf() * TAU
		var sp := (2.2 + randf() * 5.0) * PSPEED
		_particles.append(_mk(pos, Vector2(cos(a), sin(a)) * sp - Vector2(0.0, PSPEED),
			0.7 + randf() * 0.6, 4.0 + randf() * 6.0, "shard", 0.06 * PSPEED,
			randf() * TAU, (randf() - 0.5) * 18.0))
	for _i in _pcount(28):
		var a := randf() * TAU
		var sp := (1.6 + randf() * 4.0) * PSPEED
		var kind := "mote_brass" if randf() < 0.45 else "mote_red"
		_particles.append(_mk(pos, Vector2(cos(a), sin(a)) * sp - Vector2(0.0, 0.6 * PSPEED),
			0.5 + randf() * 0.5, 1.0 + randf() * 1.6, kind, 0.0))
	for _i in _pcount(12):
		var a := randf() * TAU
		var sp := (0.6 + randf() * 2.0) * PSPEED
		_particles.append(_mk(pos, Vector2(cos(a), sin(a) * 0.7) * sp - Vector2(0.0, 0.3 * PSPEED),
			1.0 + randf() * 0.7, 16.0 + randf() * 16.0, "dust", -0.006 * PSPEED))

# 노출 중 상처에서 피어오르는 잔불 (ember) — 매 프레임 확률 spawn
func _spawn_ambient_embers() -> void:
	if randf() < 0.5 * _scale():
		var kind := "mote_red" if randf() < 0.7 else "mote_brass"
		_particles.append(_mk(_chest + Vector2(randf_range(-34.0, 34.0), randf_range(-34.0, 34.0)),
			Vector2(randf_range(-0.25, 0.25), -0.4 - randf() * 0.5) * PSPEED,
			1.2 + randf() * 0.8, 1.0 + randf() * 1.3, kind, 0.0))

func _process(delta: float) -> void:
	var damp: float = pow(0.992, delta * 60.0)
	for i in range(_particles.size() - 1, -1, -1):
		var p: Dictionary = _particles[i]
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
		if float(p["vrot"]) != 0.0:
			p["rot"] = float(p["rot"]) + float(p["vrot"]) * delta
	if _embers_timer > 0.0:
		_embers_timer -= delta
		_spawn_ambient_embers()
	if _expose_age >= 0.0:
		_expose_age += delta
	_smoke_layer.queue_redraw()
	_glow_layer.queue_redraw()

# 노출 요소 공통 alpha — EXPOSED_TIME 까지 1.0, 이후 FADE_TIME 동안 0 으로
func _expose_alpha() -> float:
	if _expose_age < EXPOSED_TIME:
		return 1.0
	return clampf(1.0 - (_expose_age - EXPOSED_TIME) / FADE_TIME, 0.0, 1.0)

# ── 그리기 패스 ──
func _draw_smoke_pass(canvas: CanvasItem) -> void:
	for p in _particles:
		if p["kind"] != "dust":
			continue
		var k: float = float(p["life"]) / float(p["max_life"])
		var a: float = (1.0 - k) * 0.3
		var r: float = float(p["r"]) * (1.0 + k * 1.2)
		canvas.draw_circle(p["pos"], r, Color(0.46, 0.18, 0.18, a))

func _draw_glow_pass(canvas: CanvasItem) -> void:
	if _spike_prog >= 0.0:
		_draw_spike(canvas)
	if _expose_age >= 0.0:
		var ea: float = _expose_alpha()
		if ea > 0.0:
			_draw_cracks(canvas, ea)
			_draw_funnel(canvas, ea)
			_draw_shield(canvas, ea)
	_draw_particles(canvas)

func _draw_spike(canvas: CanvasItem) -> void:
	var prog: float = clampf(_spike_prog, 0.0, 1.0)
	var apex := Vector2(_chest.x, lerpf(_chest.y + SPIKE_TOP, _chest.y - 4.0, prog))
	var top := apex - Vector2(0.0, SPIKE_LEN)
	var a: float = clampf(prog * 3.0, 0.0, 1.0)
	canvas.draw_colored_polygon(PackedVector2Array([apex, top + Vector2(-16.0, 0.0), top + Vector2(16.0, 0.0)]),
		Color(COL_WARN.r, COL_WARN.g, COL_WARN.b, 0.85 * a))
	canvas.draw_colored_polygon(PackedVector2Array([apex, top + Vector2(-6.0, SPIKE_LEN * 0.18), top + Vector2(6.0, SPIKE_LEN * 0.18)]),
		Color(1, 1, 1, 0.9 * a))

func _draw_cracks(canvas: CanvasItem, ea: float) -> void:
	var prog: float = _crack_prog
	var dirs := [Vector2(-0.6, -1.0), Vector2(0.7, -1.1), Vector2(-1.1, 0.1),
		Vector2(1.0, 0.3), Vector2(-0.4, 1.2), Vector2(0.5, 1.3)]
	var lens := [42.0, 46.0, 40.0, 44.0, 50.0, 48.0]
	var col := Color(COL_RED_HOT.r, COL_RED_HOT.g, COL_RED_HOT.b, 0.9 * ea)
	for i in range(dirs.size()):
		var d: Vector2 = (dirs[i] as Vector2).normalized()
		canvas.draw_line(_chest, _chest + d * (lens[i] * prog), col, 2.0)

func _draw_funnel(canvas: CanvasItem, ea: float) -> void:
	var rot: float = _expose_age * 0.4
	var rad := 62.0
	canvas.draw_arc(_chest, rad, 0.0, TAU, 48, Color(COL_VULN.r, COL_VULN.g, COL_VULN.b, 0.3 * ea), 1.0)
	var pulse: float = 0.7 + 0.3 * sin(_expose_age * 5.0)
	var col := Color(COL_RED_HOT.r, COL_RED_HOT.g, COL_RED_HOT.b, 0.85 * ea * pulse)
	for i in range(4):
		var ang: float = rot + deg_to_rad(90.0 * i)
		var dir := Vector2(cos(ang), sin(ang))
		var perp := Vector2(-dir.y, dir.x)
		var tipp := _chest + dir * (rad - 16.0)  # 안쪽 꼭지 (피해가 안으로)
		canvas.draw_polyline(PackedVector2Array([
			_chest + dir * rad + perp * 14.0, tipp, _chest + dir * rad - perp * 14.0]), col, 2.4)

func _draw_shield(canvas: CanvasItem, ea: float) -> void:
	var s: float = SHIELD_SCALE
	var c := _target + SHIELD_OFFSET + Vector2(0.0, sin(_expose_age * 2.4) * 3.0)
	var split: float = _shield_split * 5.0
	var fill := Color(COL_VULN_MID.r, COL_VULN_MID.g, COL_VULN_MID.b, 0.26 * ea)
	var line := Color(COL_RED_HOT.r, COL_RED_HOT.g, COL_RED_HOT.b, 0.95 * ea)
	var lhalf := PackedVector2Array([Vector2(0, -22), Vector2(-17, -16), Vector2(-17, 1), Vector2(-1, 19), Vector2(0, 19)])
	var rhalf := PackedVector2Array([Vector2(0, -22), Vector2(17, -16), Vector2(17, 1), Vector2(1, 19), Vector2(0, 19)])
	var lp := PackedVector2Array()
	for v in lhalf:
		lp.push_back(c + v * s + Vector2(-split, split * 0.4))
	var rp := PackedVector2Array()
	for v in rhalf:
		rp.push_back(c + v * s + Vector2(split, split * 0.4))
	canvas.draw_colored_polygon(lp, fill)
	canvas.draw_colored_polygon(rp, fill)
	canvas.draw_polyline(lp, line, 2.6)
	canvas.draw_polyline(rp, line, 2.6)
	# 가운데 지그재그 균열 (흰선)
	var frac := PackedVector2Array([Vector2(0, -22), Vector2(-4, -8), Vector2(4, 2), Vector2(-4, 12), Vector2(0, 19)])
	var fp := PackedVector2Array()
	for v in frac:
		fp.push_back(c + v * s)
	canvas.draw_polyline(fp, Color(1, 1, 1, 0.9 * ea), 1.8)

func _draw_particles(canvas: CanvasItem) -> void:
	for p in _particles:
		var k: float = float(p["life"]) / float(p["max_life"])
		var a: float = 1.0 - k
		var pos: Vector2 = p["pos"]
		var r: float = float(p["r"])
		match p["kind"]:
			"shard":
				canvas.draw_set_transform(pos, float(p["rot"]), Vector2.ONE)
				var tri := PackedVector2Array([Vector2(0, -r), Vector2(r * 0.5, r * 0.5), Vector2(-r * 0.6, r * 0.4)])
				canvas.draw_colored_polygon(tri, Color(COL_WARN.r, COL_WARN.g, COL_WARN.b, 0.85 * a))
				canvas.draw_polyline(tri + PackedVector2Array([tri[0]]), Color(COL_RED_HOT.r, COL_RED_HOT.g, COL_RED_HOT.b, 0.9 * a), 1.0)
				canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			"mote_brass":
				canvas.draw_circle(pos, r, Color(COL_WARN.r, COL_WARN.g, COL_WARN.b, a))
			"mote_red":
				canvas.draw_circle(pos, r, Color(COL_RED_HOT.r, COL_RED_HOT.g, COL_RED_HOT.b, a))

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
