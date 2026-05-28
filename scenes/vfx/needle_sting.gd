# scenes/vfx/needle_sting.gd
# 전갈 침 공격 VFX — ui_sample/vfx/Needle Sting VFX.html 재현.
# battle_scene 이 needle_sting damage_type 공격 시 .new() → add_child → play(caster, target).
# 단계: COIL 0.32s (꼬리 솟구침) → HOVER 0.08s → STRIKE 0.16s (찌르기) → HOLD 0.12s → RETRACT 0.54s → WAIT 0.7s.
# 본체 꼬리 = base→tip quadratic Bezier ribbon (가변 두께) + chitin gradient + barb 침.
# 파티클 = 피 22+5 (어두운 빨강 streak) + 뼈 6 (회전 직사각형).
# puncture = 찌른 자국 (빨간 dot + halo pulse) 2.2s.
extends Node2D

var _particle_scale_override: float = -1.0  # vfx_preview 비교용

func _pcount(n: int) -> int:
	if _particle_scale_override > 0.0:
		return maxi(1, int(round(n * _particle_scale_override)))
	var gs := get_node_or_null("/root/GameSettings")
	return n if gs == null else maxi(1, int(round(n * gs.particle_count_scale())))

const COL_CHITIN_HOT   := Color(0.478, 0.353, 0.212)  # #7a5a36 — 밝은 갑각
const COL_CHITIN_MID   := Color(0.227, 0.157, 0.094)  # #3a2818 — 본체
const COL_CHITIN_EDGE  := Color(0.627, 0.478, 0.290)  # #a07a4a — 하이라이트
const COL_BONE_MID     := Color(0.902, 0.847, 0.706)  # #e6d8b4 — 뼈 조각
const COL_BARB_TIP     := Color(0.957, 0.910, 0.769)  # #f4e8c4 — 침 끝 광택
const COL_BLOOD        := Color(0.659, 0.063, 0.102)  # #a8101a — 피
const COL_BLOOD_BRIGHT := Color(0.902, 0.227, 0.227)  # #e63a3a — 찌른 자국
const COL_BLOOD_DEEP   := Color(0.16, 0.024, 0.031)   # #2a0408 — 자국 코어
const COL_HALO         := Color(1.0, 0.784, 0.706)    # 자국 둘레 halo

const COIL_TIME    := 0.32
const HOVER_TIME   := 0.08
const STRIKE_TIME  := 0.16
const HOLD_TIME    := 0.12
const RETRACT_1    := 0.22
const RETRACT_2    := 0.32
const WAIT_TIME    := 0.7
const IMPACT_DELAY := COIL_TIME + HOVER_TIME + STRIKE_TIME  # 0.56 — battle_manager 동기화
const PUNCTURE_TIME := 2.2
const HALO_TIME    := 1.2

# 꼬리 base/tip — caster sprite center 기준 offset
const BASE_OFFSET   := Vector2(20.0, -50.0)
const TIP_REST      := Vector2(14.0, -85.0)
const TIP_COIL_PEAK := Vector2(60.0, -185.0)
const TIP_RETRACT   := Vector2(10.0, -175.0)
# 타겟 strike 지점
const STRIKE_OFFSET := Vector2(0.0, -10.0)
# 꼬리 모양
const TAIL_WIDTH    := 7.0
const N_SAMPLES     := 16
# motion blur — ghost 각각 자체 lifetime 페이드 (HTML phaseHistory 흉내).
const MAX_GHOSTS    := 8
const GHOST_LIFETIME := 0.18    # 각 잔상 페이드 시간 (s)
const GHOST_PUSH_INTERVAL := 0.022  # ~45fps push

# SFX — battle_scene._spawn_attack_beam_simple 자동 호출
const SFX_IMPACT := "needle_sting_stab"

signal screen_effect

var _caster := Vector2.ZERO
var _target := Vector2.ZERO

var _base := Vector2.ZERO
var _tip := Vector2.ZERO
var _curl: float = 0.3

var _particles: Array = []
var _puncture_age: float = -1.0
var _puncture_pos := Vector2.ZERO

var _ghosts: Array = []  # STRIKE 중 motion blur — {tip, curl, age} 각 자체 lifetime
var _in_strike: bool = false
var _ghost_push_timer: float = 0.0

func play(caster: Vector2, target: Vector2) -> void:
	_caster = caster
	_target = target
	_base = caster + BASE_OFFSET
	_tip = caster + TIP_REST
	_curl = 0.3
	_run_sequence()

func _run_sequence() -> void:
	# 1. COIL — 꼬리가 정점으로 솟구침
	var coil_target: Vector2 = _caster + TIP_COIL_PEAK
	var tw1 := create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw1.tween_property(self, "_tip", coil_target, COIL_TIME)
	tw1.tween_property(self, "_curl", 0.95, COIL_TIME)
	await tw1.finished
	# 2. HOVER
	await get_tree().create_timer(HOVER_TIME).timeout
	# 3. STRIKE — 침을 타겟에 내리침 (motion blur 기록)
	_in_strike = true
	_ghosts.clear()
	var strike_pos: Vector2 = _target + STRIKE_OFFSET
	var tw2 := create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw2.tween_property(self, "_tip", strike_pos, STRIKE_TIME)
	tw2.tween_property(self, "_curl", -0.15, STRIKE_TIME)
	await tw2.finished
	_in_strike = false
	# IMPACT — 데미지/SFX 적용 시점
	emit_signal("screen_effect")
	_puncture_pos = strike_pos
	_puncture_age = 0.0
	_spawn_blood(strike_pos)
	# 4. HOLD — 침 박힌 채 살짝 떨림
	var tw3 := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw3.tween_property(self, "_curl", -0.05, HOLD_TIME)
	await tw3.finished
	# 5. RETRACT — 중간 위 → idle
	var ret_mid: Vector2 = _caster + TIP_RETRACT
	var tw4 := create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw4.tween_property(self, "_tip", ret_mid, RETRACT_1)
	tw4.tween_property(self, "_curl", 0.7, RETRACT_1)
	await tw4.finished
	var ret_end: Vector2 = _caster + TIP_REST
	var tw5 := create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tw5.tween_property(self, "_tip", ret_end, RETRACT_2)
	tw5.tween_property(self, "_curl", 0.3, RETRACT_2)
	await tw5.finished
	# 6. 잔여물 (puncture/blood) 페이드 대기 후 종료
	await get_tree().create_timer(WAIT_TIME).timeout
	queue_free()

func _process(delta: float) -> void:
	# STRIKE 중에만 새 ghost push (일정 간격)
	if _in_strike:
		_ghost_push_timer += delta
		if _ghost_push_timer >= GHOST_PUSH_INTERVAL:
			_ghost_push_timer = 0.0
			_ghosts.append({"tip": _tip, "curl": _curl, "age": 0.0})
			if _ghosts.size() > MAX_GHOSTS:
				_ghosts.pop_front()
	# ghost age 누적 + lifetime 초과 시 제거 (각자 자연 페이드)
	for i in range(_ghosts.size() - 1, -1, -1):
		var g: Dictionary = _ghosts[i]
		g["age"] = float(g["age"]) + delta
		if float(g["age"]) >= GHOST_LIFETIME:
			_ghosts.remove_at(i)
	# 파티클 update (HTML dt*0.06 ≈ Godot delta — 매핑: vx_html*60=vel_godot, grav_html*60=grav_godot)
	for i in range(_particles.size() - 1, -1, -1):
		var p: Dictionary = _particles[i]
		p["life"] = float(p["life"]) + delta
		if float(p["life"]) >= float(p["max_life"]):
			_particles.remove_at(i)
			continue
		var pos: Vector2 = p["pos"]
		var vel: Vector2 = p["vel"]
		pos += vel * delta
		vel.y += float(p.get("grav", 0.0)) * delta
		vel *= pow(0.992, delta * 60.0)
		p["pos"] = pos
		p["vel"] = vel
		if p.has("vrot"):
			p["rot"] = float(p.get("rot", 0.0)) + float(p["vrot"]) * delta
	if _puncture_age >= 0.0:
		_puncture_age += delta
	queue_redraw()

func _draw() -> void:
	# 각 ghost 자체 age 로 alpha 결정 (오래된 잔상부터 자연 사라짐)
	for g in _ghosts:
		var age: float = float(g["age"])
		var life_k: float = age / GHOST_LIFETIME
		var op: float = (1.0 - life_k) * 0.4
		if op > 0.01:
			_draw_tail(g["tip"], g["curl"], op, 0.95)
	_draw_tail(_tip, _curl, 1.0, 1.0)
	_draw_particles()
	if _puncture_age >= 0.0:
		_draw_puncture()

# 본체 — base→tip quadratic Bezier ribbon + bulb + barb
func _draw_tail(tip: Vector2, curl: float, opacity: float, width_scale: float) -> void:
	var delta: Vector2 = tip - _base
	var ln: float = delta.length()
	if ln < 1.0:
		return
	var nrm := Vector2(-delta.y, delta.x) / ln  # 수직 (overhead 방향)
	var off: float = curl * ln * 0.55
	var ctrl: Vector2 = (_base + tip) * 0.5 + nrm * off
	var pts: Array = []  # [{pos, n, ang, u}]
	for i in N_SAMPLES + 1:
		var u: float = float(i) / float(N_SAMPLES)
		var iu: float = 1.0 - u
		var pos: Vector2 = _base * (iu * iu) + ctrl * (2.0 * iu * u) + tip * (u * u)
		var tdx: Vector2 = (ctrl - _base) * (2.0 * iu) + (tip - ctrl) * (2.0 * u)
		var tl: float = tdx.length()
		if tl < 0.001: tl = 0.001
		var n2 := Vector2(-tdx.y, tdx.x) / tl
		pts.append({"pos": pos, "n": n2, "ang": tdx.angle(), "u": u})
	# 본체 ribbon — 마지막 3 segment 는 barb 영역
	var body_end: int = N_SAMPLES - 3
	var ribbon := PackedVector2Array()
	for i in body_end + 1:
		var p: Dictionary = pts[i]
		var w: float = (1.0 - float(p["u"]) * 0.55) * TAIL_WIDTH * width_scale
		ribbon.push_back(p["pos"] + p["n"] * w)
	for i in range(body_end, -1, -1):
		var p2: Dictionary = pts[i]
		var w2: float = (1.0 - float(p2["u"]) * 0.55) * TAIL_WIDTH * width_scale
		ribbon.push_back(p2["pos"] - p2["n"] * w2)
	draw_polygon(ribbon, [Color(COL_CHITIN_MID.r, COL_CHITIN_MID.g, COL_CHITIN_MID.b, opacity)])
	# top-edge highlight
	var hl := PackedVector2Array()
	for i in body_end + 1:
		var p3: Dictionary = pts[i]
		var w3: float = (1.0 - float(p3["u"]) * 0.55) * TAIL_WIDTH * width_scale - 1.5
		hl.push_back(p3["pos"] + p3["n"] * w3)
	if hl.size() >= 2:
		draw_polyline(hl, Color(COL_CHITIN_EDGE.r, COL_CHITIN_EDGE.g, COL_CHITIN_EDGE.b, 0.55 * opacity), 1.2)
	# 마디 라인 (3마다)
	for i in range(2, body_end + 1, 3):
		var p4: Dictionary = pts[i]
		var w4: float = (1.0 - float(p4["u"]) * 0.55) * TAIL_WIDTH * width_scale * 0.9
		draw_line(p4["pos"] + p4["n"] * w4, p4["pos"] - p4["n"] * w4, Color(0.04, 0.024, 0.008, 0.7 * opacity), 1.4)
	# barb bulb (꼬리 끝 부풀음)
	var bulb_pos: Vector2 = pts[body_end]["pos"]
	draw_circle(bulb_pos, 8.0 * width_scale, Color(COL_CHITIN_HOT.r, COL_CHITIN_HOT.g, COL_CHITIN_HOT.b, opacity))
	draw_circle(bulb_pos, 6.0 * width_scale, Color(COL_CHITIN_MID.r, COL_CHITIN_MID.g, COL_CHITIN_MID.b, opacity))
	# barb (날카로운 침) — 삼각형
	var tip_pt: Dictionary = pts[N_SAMPLES]
	var pre_pt: Dictionary = pts[N_SAMPLES - 1]
	var ang: float = float(tip_pt["ang"])
	var dir := Vector2(cos(ang), sin(ang))
	var apex: Vector2 = tip_pt["pos"] + dir * 22.0 * width_scale * 0.7
	var wb: float = 5.0 * width_scale
	var pre_n: Vector2 = pre_pt["n"]
	var pre_pos: Vector2 = pre_pt["pos"]
	var barb := PackedVector2Array()
	barb.push_back(pre_pos + pre_n * wb * 0.6)
	barb.push_back(apex)
	barb.push_back(pre_pos - pre_n * wb * 0.6)
	draw_polygon(barb, [Color(COL_CHITIN_HOT.r, COL_CHITIN_HOT.g, COL_CHITIN_HOT.b, opacity)])
	draw_line(pre_pos + pre_n * wb * 0.2, apex, Color(COL_BARB_TIP.r, COL_BARB_TIP.g, COL_BARB_TIP.b, 0.7 * opacity), 1.0)

func _spawn_blood(impact_pos: Vector2) -> void:
	# 작은 피 22개 — 사방으로 튐, 중력
	for _i in _pcount(22):
		var ang := -PI * 0.5 + (randf() - 0.5) * PI * 1.4
		var sp := (2.0 + randf() * 5.0) * 60.0  # HTML px/frame → Godot px/s
		_particles.append({
			"pos": impact_pos,
			"vel": Vector2(cos(ang), sin(ang)) * sp,
			"life": 0.0, "max_life": 0.6 + randf() * 0.7,
			"r": 1.4 + randf() * 1.8, "kind": "blood", "grav": 0.22 * 60.0,
		})
	# 큰 피 5개 — 위로 분출
	for _i in _pcount(5):
		var ang := -PI * 0.5 + (randf() - 0.5) * 1.0
		var sp := (3.0 + randf() * 4.0) * 60.0
		_particles.append({
			"pos": impact_pos,
			"vel": Vector2(cos(ang), sin(ang)) * sp,
			"life": 0.0, "max_life": 1.0 + randf() * 0.7,
			"r": 2.6 + randf() * 2.0, "kind": "blood", "grav": 0.24 * 60.0,
		})
	# 뼈 조각 6개 — 회전
	for _i in _pcount(6):
		var ang := randf() * TAU
		var sp_base := 1.5 + randf() * 3.0
		_particles.append({
			"pos": impact_pos,
			"vel": Vector2(cos(ang) * sp_base, sin(ang) * sp_base - 1.0) * 60.0,
			"life": 0.0, "max_life": 0.5 + randf() * 0.4,
			"r": 1.0 + randf() * 1.2, "kind": "bone", "grav": 0.18 * 60.0,
			"rot": randf() * PI, "vrot": (randf() - 0.5) * 24.0,
		})

func _draw_particles() -> void:
	for p in _particles:
		var k: float = float(p["life"]) / float(p["max_life"])
		var alpha: float = 1.0 - k
		var pos: Vector2 = p["pos"]
		var r: float = float(p["r"])
		match p["kind"]:
			"blood":
				var col := Color(COL_BLOOD.r * (1.0 - k * 0.4), COL_BLOOD.g, COL_BLOOD.b, 0.95 * alpha)
				var vel: Vector2 = p["vel"]
				if vel.length() > 120.0:
					var ang := vel.angle()
					draw_set_transform(pos, ang, Vector2(1.6, 0.7))
					draw_circle(Vector2.ZERO, r, col)
					draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
				else:
					draw_circle(pos, r, col)
			"bone":
				var col2 := Color(COL_BONE_MID.r, COL_BONE_MID.g, COL_BONE_MID.b, alpha)
				var rot: float = float(p.get("rot", 0.0))
				draw_set_transform(pos, rot, Vector2.ONE)
				draw_rect(Rect2(-r * 1.6, -r * 0.4, r * 3.2, r * 0.8), col2)
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_puncture() -> void:
	var t: float = _puncture_age / PUNCTURE_TIME
	if t > 1.0:
		_puncture_age = -1.0
		return
	# puncFade: 5% 페이드인 → 80% hold → 20% 페이드아웃
	var alpha: float
	if t < 0.05:
		alpha = t / 0.05
	elif t < 0.8:
		alpha = 1.0
	else:
		alpha = (1.0 - t) / 0.2
	# 핏빛 점 (코어 + 외곽)
	draw_circle(_puncture_pos, 4.0, Color(COL_BLOOD_BRIGHT.r, COL_BLOOD_BRIGHT.g, COL_BLOOD_BRIGHT.b, alpha))
	draw_circle(_puncture_pos, 2.0, Color(COL_BLOOD_DEEP.r, COL_BLOOD_DEEP.g, COL_BLOOD_DEEP.b, alpha))
	# halo pulse — 1.2s 안에 ring 확장
	var halo_t: float = _puncture_age / HALO_TIME
	if halo_t < 1.0:
		var halo_radius: float = lerpf(2.0, 32.0, halo_t)
		var halo_alpha: float = lerpf(0.9, 0.0, halo_t) * alpha
		draw_arc(_puncture_pos, halo_radius, 0.0, TAU, 24, Color(COL_HALO.r, COL_HALO.g, COL_HALO.b, halo_alpha), 1.5)
