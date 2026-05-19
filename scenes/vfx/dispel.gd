# scenes/vfx/dispel.gd
# DISPEL VFX — ui_sample/vfx/DispelBuffs VFX.html 재현 (단순화).
# caster (적) → target (영웅) 으로 빨간 hook tendril 3가닥 발사.
# 각 hook 끝의 황금 buff orb 가 도달 시 부서지며 brass shard + crimson backsplash.
# screen_effect = windup 끝 (impact 시점) 한 번 발동.
extends Node2D

const COL_STRIP_HOT  := Color(1.0, 0.36, 0.39)    # #ff5c64 — hot crimson
const COL_STRIP_DEEP := Color(0.42, 0.078, 0.094) # #6b1418 — deep crimson
const COL_BUFF       := Color(0.91, 0.78, 0.47)   # #e8c878 — brass
const COL_BUFF_HOT   := Color(1.0, 0.95, 0.75)    # #fff3c0 — light brass

const NUM_HOOKS    := 3
const WINDUP_TIME  := 0.22       # impact 까지 대기
const STAGGER      := 0.12       # hook 별 시작 간격
const HOOK_TRAVEL  := 0.22       # tendril 늘어나는 시간
const SHATTER_TIME := 0.45       # 부서짐 지속
const FADE_TIME    := 0.4
const IMPACT_DELAY := WINDUP_TIME  # battle_manager 동기화 표준 상수 (= WINDUP_TIME)

signal screen_effect

var _caster_pos := Vector2.ZERO
var _target_pos := Vector2.ZERO
var _foot_pos := Vector2.ZERO  # 안 쓰지만 다른 VFX 와 인터페이스 통일
var _age := -1.0
var _impact_emitted := false
var _hooks: Array = []     # {start_t: float, target: Vector2, ctrl: Vector2, shattered: bool}
var _shatters: Array = []  # {start_t: float, pos: Vector2}
var _particles: Array = [] # {pos, vel, life, max_life, size, kind}

func set_ground_anchor(pos: Vector2) -> void:
	_foot_pos = pos

func _ready() -> void:
	set_process(false)

func play(caster_pos: Vector2, target_pos: Vector2) -> void:
	_caster_pos = caster_pos
	_target_pos = target_pos
	# buff orb 위치 — target 주위 orbit (위/우상/좌상 3 위치)
	var orbit_r: float = 60.0
	for i in range(NUM_HOOKS):
		var angle: float = -PI / 2.0 + (float(i) - 1.0) * 0.75  # -90, -47, -4 도 근방
		var b_pos: Vector2 = _target_pos + Vector2(cos(angle) * orbit_r, sin(angle) * orbit_r * 0.85)
		var start_t: float = WINDUP_TIME + float(i) * STAGGER
		# ctrl 점 — 곡선 위쪽으로 휘게
		var hand: Vector2 = _caster_hand()
		var ctrl: Vector2 = (hand + b_pos) * 0.5 + Vector2(0.0, -50.0 - randf() * 25.0)
		_hooks.append({
			"start_t": start_t, "target": b_pos, "ctrl": ctrl, "shattered": false,
		})
	_age = 0.0
	set_process(true)
	var total: float = WINDUP_TIME + float(NUM_HOOKS) * STAGGER + HOOK_TRAVEL + SHATTER_TIME + FADE_TIME + 0.1
	await get_tree().create_timer(total).timeout
	if is_inside_tree():
		queue_free()

func _process(delta: float) -> void:
	_age += delta
	if not _impact_emitted and _age >= WINDUP_TIME:
		_impact_emitted = true
		screen_effect.emit()
	# hook 도달 시 shatter 트리거
	for h in _hooks:
		if not h["shattered"] and _age >= h["start_t"] + HOOK_TRAVEL:
			h["shattered"] = true
			_shatters.append({"start_t": _age, "pos": h["target"]})
			_spawn_shatter_particles(h["target"])
	# 파티클 업데이트
	var alive: Array = []
	for p in _particles:
		p["life"] += delta
		if p["life"] >= p["max_life"]:
			continue
		p["pos"] += p["vel"] * delta
		p["vel"] *= 0.985
		alive.append(p)
	_particles = alive
	queue_redraw()

func _global_alpha() -> float:
	var total_visual: float = WINDUP_TIME + float(NUM_HOOKS) * STAGGER + HOOK_TRAVEL + SHATTER_TIME
	if _age < total_visual:
		return clampf(_age / 0.08, 0.0, 1.0)
	var t: float = (_age - total_visual) / FADE_TIME
	return clampf(1.0 - t, 0.0, 1.0)

func _caster_hand() -> Vector2:
	# 시전자 손 — 타겟 방향으로 30px 옆 + 20px 위
	var dir: float = sign(_target_pos.x - _caster_pos.x)
	if dir == 0.0:
		dir = 1.0
	return _caster_pos + Vector2(dir * 30.0, -20.0)

func _spawn_shatter_particles(pos: Vector2) -> void:
	# brass shard 16개
	for _i in range(16):
		var ang: float = randf() * TAU
		var sp: float = 90.0 + randf() * 180.0
		_particles.append({
			"pos": pos, "vel": Vector2(cos(ang), sin(ang)) * sp,
			"life": 0.0, "max_life": 0.55 + randf() * 0.35,
			"size": 1.4 + randf() * 1.8, "kind": "brass",
		})
	# crimson backsplash 8개
	for _i in range(8):
		var ang2: float = randf() * TAU
		var sp2: float = 60.0 + randf() * 120.0
		_particles.append({
			"pos": pos, "vel": Vector2(cos(ang2), sin(ang2)) * sp2,
			"life": 0.0, "max_life": 0.7 + randf() * 0.4,
			"size": 1.6 + randf() * 1.6, "kind": "crimson",
		})

func _draw() -> void:
	var ga: float = _global_alpha()
	if ga <= 0.0:
		return
	# 1) 살아있는 buff orb (아직 shatter 안 된 것)
	for h in _hooks:
		if h["shattered"]:
			continue
		_draw_buff_orb(h["target"], ga)
	# 2) hook tendril (그려지는 중인 것)
	for h in _hooks:
		if _age < h["start_t"]:
			continue
		var t: float = clampf((_age - h["start_t"]) / HOOK_TRAVEL, 0.0, 1.0)
		_draw_hook(h, t, ga)
	# 3) shatter ring
	for s in _shatters:
		var st: float = _age - s["start_t"]
		if st > SHATTER_TIME:
			continue
		_draw_shatter_ring(s["pos"], st / SHATTER_TIME, ga)
	# 4) particles
	_draw_particles(ga)

func _draw_buff_orb(pos: Vector2, ga: float) -> void:
	# 외곽 글로우 (brass)
	draw_circle(pos, 22.0, Color(COL_BUFF.r, COL_BUFF.g, COL_BUFF.b, ga * 0.22))
	draw_circle(pos, 14.0, Color(COL_BUFF.r, COL_BUFF.g, COL_BUFF.b, ga * 0.55))
	# 코어 (밝은 brass)
	draw_circle(pos, 8.0, Color(COL_BUFF_HOT.r, COL_BUFF_HOT.g, COL_BUFF_HOT.b, ga * 0.95))
	# 가는 외곽 ring
	draw_arc(pos, 12.0, 0.0, TAU, 24, Color(COL_BUFF_HOT.r, COL_BUFF_HOT.g, COL_BUFF_HOT.b, ga * 0.7), 1.2)

func _draw_hook(h: Dictionary, t: float, ga: float) -> void:
	var hand: Vector2 = _caster_hand()
	var ctrl: Vector2 = h["ctrl"]
	var tip: Vector2 = h["target"]
	# Bezier 곡선 — 12 세그먼트, t 진행도까지만
	var segs: int = 12
	var end_seg: int = int(round(float(segs) * t))
	if end_seg < 1:
		return
	var pts := PackedVector2Array()
	for i in range(end_seg + 1):
		var u: float = float(i) / float(segs)
		pts.append(hand.bezier_interpolate(ctrl, ctrl, tip, u))
	# 외곽 (deep crimson, 두꺼움)
	for i in range(pts.size() - 1):
		draw_line(pts[i], pts[i + 1],
			Color(COL_STRIP_DEEP.r, COL_STRIP_DEEP.g, COL_STRIP_DEEP.b, ga * 0.85), 5.0, true)
	# 내곽 (hot crimson, 가는 코어)
	for i in range(pts.size() - 1):
		draw_line(pts[i], pts[i + 1],
			Color(COL_STRIP_HOT.r, COL_STRIP_HOT.g, COL_STRIP_HOT.b, ga), 2.2, true)
	# claw — tip 에 도달했을 때
	if t >= 1.0:
		var c: Color = Color(1.0, 1.0, 1.0, ga)
		draw_line(tip + Vector2(-12.0, -9.0), tip, c, 2.0, true)
		draw_line(tip + Vector2(-12.0, 9.0), tip, c, 2.0, true)
		draw_line(tip, tip + Vector2(9.0, -6.0), c, 1.6, true)
		draw_line(tip, tip + Vector2(9.0, 6.0), c, 1.6, true)

func _draw_shatter_ring(pos: Vector2, t: float, ga: float) -> void:
	var alpha: float = (1.0 - t) * ga
	var r: float = 14.0 + 36.0 * t
	# 외곽 (hot crimson)
	draw_arc(pos, r, 0.0, TAU, 36,
		Color(COL_STRIP_HOT.r, COL_STRIP_HOT.g, COL_STRIP_HOT.b, alpha * 0.7), 2.5)
	# 내부 flash (짧게 — 초반만)
	if t < 0.25:
		var fa: float = (0.25 - t) / 0.25 * ga * 0.7
		draw_circle(pos, 16.0, Color(COL_BUFF_HOT.r, COL_BUFF_HOT.g, COL_BUFF_HOT.b, fa))

func _draw_particles(ga: float) -> void:
	for p in _particles:
		var k: float = p["life"] / p["max_life"]
		var a: float = (1.0 - k) * ga
		var pr: float = p["size"]
		if p["kind"] == "brass":
			# 작은 brass shard — 점 + streak
			draw_circle(p["pos"], pr,
				Color(1.0, 0.9 - 0.16 * k, 0.59 - 0.31 * k, a))
		elif p["kind"] == "crimson":
			draw_circle(p["pos"], pr,
				Color(1.0, 0.43 - 0.16 * k, 0.39 - 0.24 * k, a))
