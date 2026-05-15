# scenes/vfx/blunt_smash.gd
# 시전자→타겟 둔기 공격 VFX — ui_sample/vfx/Blunt Attack VFX.html 재현 (데미지 숫자 제외).
# battle_scene이 blunt damage_type 공격 시 .new() → add_child → play(caster, target).
# 노드는 position (0,0)으로 add_child해야 한다 (좌표를 global로 받아 그대로 그림).
# 어두운 먼지·파편·균열은 일반 블렌드, 스트라이크·스파크·충격파·별폭발은 가산 블렌드 — 2레이어로 그린다.
extends Node2D

const COL_HOT       := Color(1, 1, 1)             # 흰 코어
const COL_DUST_HOT  := Color(1.0, 0.965, 0.863)   # #fff6dc — 밝은 먼지
const COL_DUST_MID  := Color(0.831, 0.769, 0.627) # #d4c4a0 — 먼지
const COL_DUST_DEEP := Color(0.478, 0.416, 0.290) # #7a6a4a — 어두운 먼지
const COL_HIT_RING  := Color(1.0, 0.816, 0.416)   # #ffd06a — 황금 충격
const COL_CRACK     := Color(0.227, 0.165, 0.078) # #3a2a14 — 균열
const COL_CHUNK     := Color(0.431, 0.353, 0.235) # rgba(110,90,60) — 파편

# 크기/타이밍 — 이 상수만 만지면 된다.
const WINDUP_TIME := 0.35  # 휘두르기 준비 (캐릭터 애니메이션 — VFX는 대기만)
const SLAM_TIME   := 0.25  # 슬램 동작 — 시전자 머리 위 호로 휘두르기 표시
const ARC_RADIUS  := 90.0  # 휘두르기 호 반경(px) — 검 궤적 크기
const ARC_OFFSET  := -30.0 # 호 중심 — 시전자 어깨 높이로(px)
const STUN_TIME   := 2.0   # 명중 후 균열·분화구 유지(s)
const DUST_SCALE  := 0.5   # 흙먼지 분출 범위·크기 배율
const PSPEED      := 60.0  # HTML(dt*0.06) → Godot(delta*60) 환산 계수

## 슬램 명중 순간 — 화면 플래시·흔들림·SFX·피격 피드백 요청 (battle_scene이 수신)
signal screen_effect

var _caster := Vector2.ZERO
var _target := Vector2.ZERO
var _smoke_layer: Node2D  # 일반 블렌드 — 먼지·파편·균열·분화구
var _glow_layer: Node2D   # 가산 블렌드 — 스트라이크·스파크·충격파·별폭발·머리 위 별
var _particles: Array = []  # [{pos, vel, life, max_life, r, kind, grav, rot, spin}]
var _cracks: Array = []   # [PackedVector2Array] — 8개 균열선
var _strike_age := -1.0   # <0 = 비활성, 경과 초 (모션 스트라이크)
var _ring_life := -1.0    # <0 = 비활성, 0~1 = 충격파 링
var _burst_age := -1.0    # <0 = 비활성, 경과 초 (별 폭발)
var _crater_age := -1.0   # <0 = 비활성, 경과 초 (분화구)
var _crack_age := -1.0    # <0 = 비활성, 경과 초 (균열)

# ── 별 모양 윤곽 (autoload 비의존 static — 단위 테스트 가능) ──
# points 개의 꼭짓점을 가진 별 — 바깥/안쪽 꼭짓점 교대로 총 points*2 개 점.
static func star_poly(center: Vector2, outer_r: float, inner_r: float, points: int, rot: float) -> PackedVector2Array:
	var n := points * 2
	var out := PackedVector2Array()
	for i in range(n):
		var ang := TAU * float(i) / float(n) - PI * 0.5 + rot
		var r: float = outer_r if i % 2 == 0 else inner_r
		out.append(center + Vector2(cos(ang), sin(ang)) * r)
	return out

func _ready() -> void:
	set_process(false)
	# 먼지·파편·균열 레이어 — 일반 블렌드, 아래
	_smoke_layer = _DrawLayer.new()
	_smoke_layer.setup(self, false)
	add_child(_smoke_layer)
	# 스트라이크·스파크·충격파·별 레이어 — 가산 블렌드, 위
	_glow_layer = _DrawLayer.new()
	_glow_layer.setup(self, true)
	add_child(_glow_layer)

# caster_pos / target_pos 는 global 좌표 (노드가 (0,0)에 있다는 전제)
func play(caster_pos: Vector2, target_pos: Vector2) -> void:
	_caster = caster_pos + Vector2(0.0, -30.0)  # 손 높이로 살짝 올림
	_target = target_pos
	_run()

func _run() -> void:
	# 1) 휘두르기 준비 (캐릭터 애니메이션 — VFX는 대기만)
	set_process(true)
	await get_tree().create_timer(WINDUP_TIME).timeout
	if not is_inside_tree():
		return
	# 2) 슬램 동작 — 모션 스트라이크
	_strike_age = 0.0
	await get_tree().create_timer(SLAM_TIME).timeout
	if not is_inside_tree():
		return
	# 3) 명중
	_on_impact()
	# 4) 스턴 연출 유지 후 정리
	await get_tree().create_timer(STUN_TIME + 1.0).timeout
	if is_inside_tree():
		queue_free()

func _mk(pos: Vector2, vel: Vector2, max_life: float, r: float, kind: String,
		grav: float, rot: float = 0.0, spin: float = 0.0) -> Dictionary:
	return {"pos": pos, "vel": vel, "life": 0.0, "max_life": max_life, "r": r,
		"kind": kind, "grav": grav, "rot": rot, "spin": spin}

# 명중 — 바닥 먼지 + 디버리스 + 스파크 + 위로 솟는 먼지 기둥
# 흙먼지(dust) 만 DUST_SCALE 적용 — 파편/스파크는 영향 없음.
func _spawn_impact_dust() -> void:
	var gy := _target + Vector2(0.0, 80.0)
	for _i in range(80):
		var a := randf() * TAU
		var sp := 2.0 + randf() * 5.0
		_particles.append(_mk(gy, Vector2(cos(a) * sp, sin(a) * sp * 0.25 - 0.6 - randf() * 1.2) * DUST_SCALE,
			1.4 + randf() * 0.9, (20.0 + randf() * 22.0) * DUST_SCALE, "dust", -0.005))
	for _i in range(24):
		var a := randf() * TAU
		var sp := 3.0 + randf() * 7.0
		_particles.append(_mk(gy, Vector2(cos(a) * sp, sin(a) * sp * 0.5 - 3.0 - randf() * 2.0),
			1.0 + randf() * 0.7, 3.0 + randf() * 4.0, "chunk", 0.3,
			randf() * TAU, randf_range(-0.4, 0.4)))
	for _i in range(30):
		var a := randf() * TAU
		var sp := 2.0 + randf() * 6.0
		_particles.append(_mk(gy + Vector2(0.0, -10.0), Vector2(cos(a) * sp, sin(a) * sp - 2.0),
			0.5 + randf() * 0.5, 1.0 + randf() * 1.4, "spark", 0.15))
	for _i in range(24):
		_particles.append(_mk(gy + Vector2(randf_range(-20.0, 20.0) * DUST_SCALE, 0.0),
			Vector2(randf_range(-0.25, 0.25), -3.0 - randf() * 3.0) * DUST_SCALE,
			1.2 + randf() * 0.7, (16.0 + randf() * 16.0) * DUST_SCALE, "dust", -0.005))

# 명중 — 8개 방사형 균열 생성
func _spawn_cracks() -> void:
	var gy := _target + Vector2(0.0, 80.0)
	for i in range(8):
		var ang := PI + float(i) / 8.0 * PI + randf_range(-0.1, 0.1)
		var ln: float = 60.0 + randf() * 80.0
		var x2 := gy.x + cos(ang) * ln
		var y2 := gy.y + sin(ang) * ln * 0.3
		var segs := PackedVector2Array([gy])
		for k in range(1, 7):
			var t := float(k) / 6.0
			segs.append(Vector2(
				gy.x + (x2 - gy.x) * t + randf_range(-4.0, 4.0),
				gy.y + (y2 - gy.y) * t + randf_range(-2.0, 2.0)))
		_cracks.append(segs)

func _process(delta: float) -> void:
	# 진행 시간들
	if _strike_age >= 0.0:
		_strike_age += delta
	if _ring_life >= 0.0:
		_ring_life += delta / 0.55
	if _burst_age >= 0.0:
		_burst_age += delta
	if _crater_age >= 0.0:
		_crater_age += delta
	if _crack_age >= 0.0:
		_crack_age += delta

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
		if p["kind"] == "chunk":
			p["rot"] += p["spin"] * delta * PSPEED
		alive.append(p)
	_particles = alive

	_smoke_layer.queue_redraw()
	_glow_layer.queue_redraw()

func _on_impact() -> void:
	_spawn_impact_dust()
	_spawn_cracks()
	_ring_life = 0.0
	_burst_age = 0.0
	_crater_age = 0.0
	_crack_age = 0.0
	screen_effect.emit()

# ── 그리기 패스 — _DrawLayer 가 블렌드 모드별로 호출 ──
func _draw_smoke_pass(canvas: CanvasItem) -> void:
	# 분화구 (타겟 발 아래)
	if _crater_age >= 0.0:
		var grow: float = clampf(_crater_age / 0.35, 0.0, 1.0)
		var fade := 1.0
		if _crater_age > STUN_TIME:
			fade = clampf(1.0 - (_crater_age - STUN_TIME) / 0.6, 0.0, 1.0)
		if fade > 0.0:
			var cc := _target + Vector2(0.0, 80.0)
			var crater := PackedVector2Array()
			for i in range(28):
				var ang := TAU * float(i) / 28.0
				crater.append(cc + Vector2(cos(ang) * 100.0 * grow, sin(ang) * 14.0 * grow))
			canvas.draw_colored_polygon(crater, Color(0.0, 0.0, 0.0, 0.6 * fade))

	# 바닥 균열 8개 (시간에 따라 자라남)
	if _crack_age >= 0.0:
		var grow_c: float = minf(1.0, _crack_age / 1.5 * 4.0)
		var fade_c: float = maxf(0.0, 1.0 - maxf(0.0, (_crack_age / 1.5 - 0.6) / 0.4))
		if fade_c > 0.0:
			for ln in _cracks:
				var n_segs := (ln as PackedVector2Array).size()
				var cut := int(float(n_segs) * grow_c)
				if cut < 1:
					continue
				var pts := PackedVector2Array()
				for i in range(min(cut + 1, n_segs)):
					pts.append(ln[i])
				if pts.size() >= 2:
					canvas.draw_polyline(pts, Color(COL_CRACK, 0.9 * fade_c), 2.5, true)

	# 먼지
	for p in _particles:
		if p["kind"] != "dust":
			continue
		var k: float = p["life"] / p["max_life"]
		var a: float = (1.0 - k) * 0.45
		var r: float = p["r"] * (1.0 + k * 1.3)
		canvas.draw_circle(p["pos"], r, Color(COL_DUST_MID, a))

	# 파편 (회전 사각형)
	for p in _particles:
		if p["kind"] != "chunk":
			continue
		var a: float = (1.0 - p["life"] / p["max_life"]) * 0.9
		var r: float = p["r"]
		var fwd := Vector2(cos(p["rot"]), sin(p["rot"]))
		var side := Vector2(-fwd.y, fwd.x)
		canvas.draw_colored_polygon(PackedVector2Array([
			p["pos"] + fwd * -r + side * (-r * 0.7), p["pos"] + fwd * r + side * (-r * 0.7),
			p["pos"] + fwd * r + side * (r * 0.7), p["pos"] + fwd * -r + side * (r * 0.7),
		]), Color(COL_CHUNK, a))

func _draw_glow_pass(canvas: CanvasItem) -> void:
	# 모션 스트라이크 (시전자 → 타겟 방향, 짧고 빠르게)
	if _strike_age >= 0.0 and _strike_age < SLAM_TIME:
		_draw_strike(canvas)

	# 스파크
	for p in _particles:
		if p["kind"] != "spark":
			continue
		var k: float = p["life"] / p["max_life"]
		var a: float = 1.0 - k
		var col := Color(1.0, 0.824 - 0.235 * k, 0.471 - 0.314 * k, a)
		var pr: float = p["r"]
		canvas.draw_circle(p["pos"], pr, col)
		canvas.draw_rect(Rect2(p["pos"].x - pr * 3.0, p["pos"].y - 0.3, pr * 6.0, 0.6), col)

	# 충격파 링 (외곽 황금 + 안쪽 흰)
	if _ring_life >= 0.0 and _ring_life <= 1.0:
		var sc: float = lerpf(0.2, 2.2, _ring_life)
		var oa: float
		if _ring_life < 0.25:
			oa = _ring_life / 0.25
		else:
			oa = 1.0 - (_ring_life - 0.25) / 0.75
		var rc := _target + Vector2(0.0, 30.0)
		canvas.draw_arc(rc, 60.0 * sc, 0.0, TAU, 48, Color(COL_HIT_RING, 0.95 * oa), 6.0, true)
		canvas.draw_arc(rc, 40.0 * sc, 0.0, TAU, 36, Color(COL_HOT, 0.8 * oa), 2.0, true)

	# 별 폭발 (16각 별 + 안쪽 작은 별 + 흰 코어)
	if _burst_age >= 0.0 and _burst_age < 0.55:
		_draw_burst(canvas)

# 시전자 어깨 위 검 궤적 호 — 머리 뒤(왼쪽 수평)에서 앞쪽 약간 아래(타겟 방향)로 내려치는 모션.
# 약 210° 호. caster→target 방향에 따라 좌우 미러.
func _draw_strike(canvas: CanvasItem) -> void:
	var t := _strike_age / SLAM_TIME
	var prog: float
	var oa: float
	# 호는 2배 빨리 그림 (t<0.35에 완성), 그 후 잠시 유지, t>0.7에 페이드아웃
	if t < 0.35:
		prog = t / 0.35
		oa = clampf(t / 0.1, 0.0, 1.0)
	elif t < 0.7:
		prog = 1.0
		oa = 1.0
	else:
		prog = 1.0
		oa = clampf(1.0 - (t - 0.7) / 0.3, 0.0, 1.0)
	var center := _caster + Vector2(0.0, ARC_OFFSET)
	var dir_x: float = 1.0 if _target.x >= _caster.x else -1.0
	var start_ang := deg_to_rad(-180.0)  # 머리 뒤 (왼쪽 수평)
	var end_ang := deg_to_rad(30.0)      # 앞쪽 약간 아래로 내려친 끝
	var current_end := lerpf(start_ang, end_ang, prog)
	var n := 22
	var pts := PackedVector2Array()
	for i in range(n + 1):
		var a := lerpf(start_ang, current_end, float(i) / float(n))
		pts.append(center + Vector2(cos(a) * dir_x, sin(a)) * ARC_RADIUS)
	canvas.draw_polyline(pts, Color(COL_HIT_RING, 0.85 * oa), 10.0)
	canvas.draw_polyline(pts, Color(COL_HOT, 0.9 * oa), 4.0)

func _draw_burst(canvas: CanvasItem) -> void:
	var t := _burst_age / 0.55
	var sc: float
	var oa: float
	var rot_deg: float
	if t < 0.2:
		sc = lerpf(0.2, 1.05, t / 0.2)
		oa = t / 0.2
		rot_deg = lerpf(-20.0, 0.0, t / 0.2)
	else:
		sc = lerpf(1.05, 1.3, (t - 0.2) / 0.8)
		oa = 1.0 - (t - 0.2) / 0.8
		rot_deg = lerpf(0.0, 10.0, (t - 0.2) / 0.8)
	var rot := deg_to_rad(rot_deg)
	var bc := _target + Vector2(0.0, -10.0)
	# 외곽 16각 별 (8 outer + 8 inner)
	canvas.draw_colored_polygon(
		star_poly(bc, 88.0 * sc, 36.0 * sc, 8, rot),
		Color(COL_DUST_HOT, 0.85 * oa))
	# 안쪽 작은 별 (약간 어긋난 회전)
	canvas.draw_colored_polygon(
		star_poly(bc, 64.0 * sc, 22.0 * sc, 8, rot + deg_to_rad(22.5)),
		Color(COL_HOT, 0.9 * oa))
	# 중심 흰 원
	canvas.draw_circle(bc, 14.0 * sc, Color(COL_HOT, oa))

# ── 블렌드 모드가 다른 두 그리기 레이어 ──
# 어두운 먼지·균열은 가산이면 안 보이므로 일반 블렌드, 스파크·충격파는 글로우용 가산 블렌드.
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
