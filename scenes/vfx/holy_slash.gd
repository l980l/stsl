# scenes/vfx/holy_slash.gd
# 시전자→타겟 성스러운 베기 VFX — Joan of Arc 등 성스러운 베기 카드용.
# 베기 자체는 기본 slash 임팩트 + 깃털 분출(피 대신), 시전자는 채널 오브 + 등 뒤 후광.
# .new() → add_child → play(caster, target). 노드는 position (0,0)으로 add_child.
# 깃털은 일반 블렌드, 후광·채널 빛입자·차지 오브는 가산 — 2레이어.
extends Node2D

# 파티클 갯수 — GameSettings.particle_count_scale 적용 (하/중/상 = 0.25/0.5/1.0배)
var _particle_scale_override: float = -1.0  # vfx_preview 3-way 비교용 (음수=GameSettings)

func _pcount(n: int) -> int:
	if _particle_scale_override > 0.0:
		return maxi(1, int(round(n * _particle_scale_override)))
	var gs := get_node_or_null("/root/GameSettings")
	return n if gs == null else maxi(1, int(round(n * gs.particle_count_scale())))

const COL_HOT     := Color(1, 1, 1)             # 흰 코어
const COL_MID     := Color(1.0, 0.949, 0.753)   # #fff2c0 — 성광
const COL_GOLD    := Color(1.0, 0.820, 0.4)     # #ffd166 — 황금
const COL_DEEP    := Color(0.784, 0.573, 0.196) # #c89232 — 진금빛
const COL_FEATHER := Color(1.0, 0.980, 0.863)   # rgba(255,250,220) — 깃털

# 베기 자체는 기본 slash_particle 재사용 (피 대신 깃털 분출)
const _VFX_SLASH_PARTICLE: PackedScene = preload("res://scenes/vfx/slash_particle.tscn")

# 크기/타이밍 — 이 상수만 만지면 된다.
const ORB_CHARGE_START := 0.12  # 차지 구체 시작
const ORB_CHARGE_FULL  := 0.36  # 차지 완료
const CHANNEL_TIME     := 0.19  # 채널·후광 시간(s)
const IMPACT_DELAY     := CHANNEL_TIME  # battle_manager 동기화용 (채널 끝 = 베기 명중)
const HALO_RADIUS      := 56.0  # 시전자 뒤 후광 반경(px)
const FEATHER_COUNT    := 14    # 베기 명중 시 피 대신 튀는 깃털 개수
const PSPEED           := 60.0  # HTML(dt*0.06) → Godot(delta*60) 환산 계수

## 베기 명중 순간 — 화면 플래시·흔들림·SFX·피격 피드백 요청 (battle_scene이 수신)
signal screen_effect

var _caster := Vector2.ZERO
var _target := Vector2.ZERO
var _charge_orb: Sprite2D
var _smoke_layer: Node2D  # 일반 블렌드 — 깃털
var _glow_layer: Node2D   # 가산 블렌드 — 후광·채널 빛입자
var _particles: Array = []  # [{pos, vel, life, max_life, r, kind, grav, rot, spin}]
var _channeling := false
var _halo_age := -1.0     # <0 = 비활성, 경과 초 (시전자 뒤 후광)

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
	_smoke_layer = _DrawLayer.new()
	_smoke_layer.setup(self, false)
	add_child(_smoke_layer)
	_charge_orb = Sprite2D.new()
	_charge_orb.texture = _make_orb_tex(COL_HOT, COL_MID, COL_GOLD)
	_charge_orb.modulate = Color(1, 1, 1, 0.0)
	_charge_orb.scale = Vector2(ORB_CHARGE_START, ORB_CHARGE_START)
	add_child(_charge_orb)
	_glow_layer = _DrawLayer.new()
	_glow_layer.setup(self, true)
	add_child(_glow_layer)

func play(caster_pos: Vector2, target_pos: Vector2) -> void:
	_caster = caster_pos
	_target = target_pos
	_charge_orb.position = caster_pos + Vector2(0.0, -40.0)
	_run()

func _run() -> void:
	# 1) 채널 — 시전자 손의 성광 구체 + 등 뒤 후광
	_channeling = true
	_halo_age = 0.0
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(_charge_orb, "modulate:a", 1.0, 0.18)
	tw.parallel().tween_property(_charge_orb, "scale", Vector2(ORB_CHARGE_FULL, ORB_CHARGE_FULL), CHANNEL_TIME)
	set_process(true)
	await get_tree().create_timer(CHANNEL_TIME).timeout
	if not is_inside_tree():
		return
	# 2) 베기 — 채널 종료 + 즉시 임팩트 (기본 slash + 깃털 분출)
	_channeling = false
	var tw2 := create_tween()
	tw2.tween_property(_charge_orb, "modulate:a", 0.0, 0.12)
	_on_impact()
	# 3) 잔류·페이드는 _process 에서. 정리.
	await get_tree().create_timer(2.0).timeout
	if is_inside_tree():
		queue_free()

func _on_impact() -> void:
	_spawn_basic_slash_and_feathers()
	screen_effect.emit()

# 기본 slash 임팩트 파티클(랜덤 회전) + 피 대신 깃털 분출(베기 방향 부채꼴)
func _spawn_basic_slash_and_feathers() -> void:
	var slash_rot: float = randf_range(0.0, TAU)
	var fx: Node2D = _VFX_SLASH_PARTICLE.instantiate()
	if "autostart" in fx:
		fx.autostart = false
	if "repeat" in fx:
		fx.repeat = false
	add_child(fx)
	fx.global_position = _target
	fx.rotation = slash_rot
	fx.burst()
	for _i in range(_pcount(FEATHER_COUNT)):
		var a := slash_rot + randf_range(-0.7, 0.7)
		var sp := 1.5 + randf() * 4.0
		_particles.append({
			"pos": _target,
			"vel": Vector2(cos(a) * sp, sin(a) * sp - 0.6),
			"life": 0.0, "max_life": 1.4 + randf() * 0.8,
			"r": 8.0 + randf() * 8.0, "kind": "feather", "grav": 0.012,
			"rot": randf_range(-0.6, 0.6), "spin": randf_range(-0.18, 0.18),
		})

# 채널 중 시전자 손에서 피어오르는 빛 입자 (시전자 위에서만 — 명중 후 주위 별가루 아님)
func _spawn_channel_mote() -> void:
	_particles.append({
		"pos": _caster + Vector2(randf_range(-11.0, 11.0), randf_range(-50.0, -34.0)),
		"vel": Vector2(randf_range(-0.3, 0.3), -0.4 - randf() * 0.6),
		"life": 0.0, "max_life": 0.9 + randf() * 0.6,
		"r": 1.4 + randf() * 1.4, "kind": "mote", "grav": -0.005,
		"rot": 0.0, "spin": 0.0,
	})

func _process(delta: float) -> void:
	if _channeling and randf() < 0.7:
		_spawn_channel_mote()
	if _halo_age >= 0.0:
		_halo_age += delta

	# 파티클 물리
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

# ── 그리기 패스 ──
func _draw_smoke_pass(canvas: CanvasItem) -> void:
	for p in _particles:
		if p["kind"] != "feather":
			continue
		_draw_feather(canvas, p)

func _draw_glow_pass(canvas: CanvasItem) -> void:
	# 시전자 뒤 후광 (채널 동안 + 짧은 잔상)
	if _halo_age >= 0.0:
		_draw_halo(canvas)
	# 채널 빛 입자 (시전자 손 위쪽으로만 — 명중 후 주위로 흩날리지 않음)
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

func _draw_halo(canvas: CanvasItem) -> void:
	var ap: float = clampf(_halo_age / 0.35, 0.0, 1.0)
	var fade := 1.0
	if _halo_age > CHANNEL_TIME:
		fade = clampf(1.0 - (_halo_age - CHANNEL_TIME) / 0.3, 0.0, 1.0)
	var a: float = ap * fade * 0.7
	if a <= 0.0:
		return
	var hc := _caster + Vector2(-30.0, -30.0)
	canvas.draw_arc(hc, HALO_RADIUS, 0.0, TAU, 40, Color(COL_MID, 0.85 * a), 2.0, true)
	canvas.draw_arc(hc, HALO_RADIUS * 0.78, 0.0, TAU, 32, Color(COL_GOLD, 0.55 * a), 1.0, true)

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
