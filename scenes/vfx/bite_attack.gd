# scenes/vfx/bite_attack.gd
# 물기 공격 VFX — ui_sample/vfx/Bite Attack VFX.html 재현.
# battle_scene 이 bite_attack damage_type 공격 시 .new() → add_child → play(caster, target).
# 단계: WINDUP 0.16s (snarl marks 페이드) → JAWS APPEAR 0.14s (위/아래 송곳니 등장)
#       → SNAP 0.12s (동시 닫힘 + blur 트레일) → CLAMP 0.34s → RELEASE 0.5s + DRIP 1.6s → WAIT 1.3s.
# 본체 = 위/아래 송곳니 줄 + gum (잇몸 아치) + punctures (8 자국 + drip line).
# 파티클 = blood 70 작은 + 16 큰 + bone 10 회전 직사각형 + drip burst 3개/0.12s during 1.6s.
extends Node2D

var _particle_scale_override: float = -1.0

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

const COL_BONE_HOT      := Color(1.0, 0.980, 0.941)   # #fffaf0 — 송곳니 상단
const COL_BONE_MID      := Color(0.910, 0.875, 0.784) # #e8dfc8 — 송곳니 중간
const COL_BONE_COOL     := Color(0.773, 0.722, 0.604) # #c5b89a — 송곳니 하단
const COL_BONE_SHADOW   := Color(0.227, 0.200, 0.149) # #3a3326 — 송곳니 그림자
const COL_GUM_TOP       := Color(0.290, 0.024, 0.031) # #4a0608 — 잇몸 상단
const COL_GUM_BOT       := Color(0.102, 0.024, 0.031) # #1a0608 — 잇몸 하단
const COL_BLOOD         := Color(0.659, 0.063, 0.102) # #a8101a
const COL_BLOOD_BRIGHT  := Color(0.902, 0.227, 0.227) # #e63a3a
const COL_BLOOD_DEEP    := Color(0.290, 0.024, 0.031) # #4a0608

const WINDUP_TIME   := 0.16
const APPEAR_TIME   := 0.14
const SNAP_TIME     := 0.12
const CLAMP_TIME    := 0.6    # 잠시 유지 (이빨 닿은 상태로)
const FADE_TIME     := 0.3    # release 대신 그냥 alpha 0 페이드
const DRIP_TIME     := 1.6
const WAIT_TIME     := 1.0
const IMPACT_DELAY  := WINDUP_TIME + APPEAR_TIME + SNAP_TIME  # 0.42 — battle_manager 동기화
const PUNCTURE_TIME := 2.4

# 턱 / 자국 / snarl 위치 — 모두 caster, target 기준 offset (center)
const SNARL_OFFSET    := Vector2(80.0, -80.0)    # caster 우상단 (lunge 방향)
const JAWS_OFFSET     := Vector2(0.0, -10.0)     # target 중앙 (몸통 정가운데, 살짝 위)
const PUNCTURE_OFFSET := Vector2(0.0, -10.0)     # JAWS 와 동일 center — 잇자국 = 무는 위치
const JAW_OPEN_DIST   := 90.0   # SNAP 전 위/아래 row 떨어진 거리
# SNAP 종료 시 위/아래 row 거리. 송곳니가 지그재그로 비집고 들어가는 깊이 결정 —
# 30 이면 위 송곳니 (h≈48) 끝이 아래 송곳니 중간 정도까지 박힘 (사이즈 mix 자연스러움).
const JAW_CLOSED_DIST := 30.0
const JAWS_WIDTH      := 160.0
const PUNCTURE_AREA   := Vector2(76.0, 80.0)

# 위 송곳니 6개 — 좌우 대칭 (small/big/huge/huge/big/small)
const FANG_TOP := [
	# {width, height}
	[6.0, 22.8],   # small
	[10.8, 40.8],  # big
	[13.2, 48.0],  # huge
	[13.2, 48.0],  # huge
	[10.8, 40.8],  # big
	[6.0, 22.8],   # small
]
# 아래 송곳니 5개 — 위 6개 사이 5 gap 에 정확히 맞물리는 사이즈/배치 (좌우 대칭).
# 양 끝 small (위 small↔big 사이) / 중간 big (위 big↔huge 사이) / 가운데 huge (위 huge↔huge 사이).
const FANG_BOT := [
	[6.0, 22.8],   # small  — 양 끝
	[10.8, 40.8],  # big    — 중간
	[13.2, 48.0],  # huge   — 가운데
	[10.8, 40.8],  # big    — 중간
	[6.0, 22.8],   # small  — 양 끝
]

# SFX
const SFX_IMPACT := "bite_attack"

signal screen_effect

var _caster := Vector2.ZERO
var _target := Vector2.ZERO

var _snarl_age: float = -1.0       # WINDUP 시 0.3s 페이드
var _jaws_age: float = -1.0        # JAWS APPEAR 부터 진행
var _jaws_phase: String = "hidden"  # hidden | appear | snap | clamp | release | done
var _puncture_age: float = -1.0
var _drip_timer: float = 0.0
var _drip_active_time: float = -1.0  # > 0 동안 drip emit

var _particles: Array = []  # {pos, vel, life, max_life, r, kind, grav, rot, vrot}

func play(caster: Vector2, target: Vector2) -> void:
	_caster = caster
	_target = target
	_run_sequence()

func _run_sequence() -> void:
	# 1. WINDUP — caster 위 snarl marks 페이드인
	_snarl_age = 0.0
	await get_tree().create_timer(WINDUP_TIME).timeout
	# 2. JAWS APPEAR — 턱 등장 (open 상태)
	_jaws_age = 0.0
	_jaws_phase = "appear"
	await get_tree().create_timer(APPEAR_TIME).timeout
	# 3. SNAP — 위/아래 동시 닫힘
	_jaws_age = 0.0
	_jaws_phase = "snap"
	await get_tree().create_timer(SNAP_TIME).timeout
	# IMPACT — 데미지 적용 시점
	emit_signal("screen_effect")
	_jaws_phase = "clamp"
	_jaws_age = 0.0
	_puncture_age = 0.0
	_spawn_blood_burst()
	# 4. CLAMP — 잠시 물고 있음 (drip 도 함께 시작)
	_drip_active_time = DRIP_TIME
	_drip_timer = 0.0
	await get_tree().create_timer(CLAMP_TIME).timeout
	# 5. FADE — 위치 유지한 채 그냥 alpha 0 (위/아래로 흩어지지 않음)
	_jaws_phase = "fade"
	_jaws_age = 0.0
	await get_tree().create_timer(FADE_TIME).timeout
	_jaws_phase = "done"
	# 6. DRIP 잔여 시간 + WAIT
	await get_tree().create_timer(maxf(0.0, DRIP_TIME - CLAMP_TIME - FADE_TIME) + WAIT_TIME).timeout
	queue_free()

func _process(delta: float) -> void:
	# 페이즈별 age 진행
	if _snarl_age >= 0.0:
		_snarl_age += delta
		if _snarl_age > 0.3:
			_snarl_age = -1.0
	if _jaws_age >= 0.0:
		_jaws_age += delta
	if _puncture_age >= 0.0:
		_puncture_age += delta
		if _puncture_age > PUNCTURE_TIME:
			_puncture_age = -1.0
	# drip 주기적 spawn
	if _drip_active_time > 0.0:
		_drip_active_time -= delta
		_drip_timer += delta
		if _drip_timer >= 0.12:
			_drip_timer = 0.0
			_spawn_drip()
	# 파티클 update (HTML dt*0.06 매핑 — vel/grav 모두 ×60)
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
	queue_redraw()

func _draw() -> void:
	if _snarl_age >= 0.0:
		_draw_snarl()
	# punctures 가 jaws 뒤 — jaws 가 위에 덮어서 자국이 뒤에 보이도록
	if _puncture_age >= 0.0:
		_draw_punctures()
	if _jaws_phase != "hidden" and _jaws_phase != "done":
		_draw_jaws()
	_draw_particles()

# ── SNARL — caster 우상단 3개 빛 라인, 0.3s 페이드 (40% 시점 peak) ──
func _draw_snarl() -> void:
	var t: float = _snarl_age / 0.3
	var alpha: float
	if t < 0.4:
		alpha = t / 0.4
	else:
		alpha = (1.0 - t) / 0.6
	var origin: Vector2 = _caster + SNARL_OFFSET
	# 3 라인 — y 18 / 36 / 54, 길이 60/68/54, rotation -12/-2/10도
	var configs := [
		{"y": 18.0, "len": 60.0, "rot_deg": -12.0, "x": 0.0},
		{"y": 36.0, "len": 68.0, "rot_deg": -2.0, "x": 6.0},
		{"y": 54.0, "len": 54.0, "rot_deg": 10.0, "x": 2.0},
	]
	for c in configs:
		var rot := deg_to_rad(float(c["rot_deg"]))
		var start: Vector2 = origin + Vector2(float(c["x"]), float(c["y"]))
		var dir := Vector2(cos(rot), sin(rot))
		var end: Vector2 = start + dir * float(c["len"])
		# gradient — 가운데 밝게, 끝 페이드. 단순화로 2 segment 그라데이션.
		draw_line(start + dir * float(c["len"]) * 0.2, end, Color(COL_BONE_HOT.r, COL_BONE_HOT.g, COL_BONE_HOT.b, alpha * 0.8), 3.0)
		draw_line(start, start + dir * float(c["len"]) * 0.3, Color(COL_BONE_MID.r, COL_BONE_MID.g, COL_BONE_MID.b, alpha * 0.4), 2.5)

# ── JAWS — 위/아래 송곳니 줄 ──
# appear: open 상태 (위로 -90, 아래로 +90 떨어짐)
# snap: 0.14s 안에 위로 +90, 아래로 -90 이동 (만나는 위치 = JAWS_OFFSET 중앙)
# clamp: 닫힌 상태에서 작은 떨림
# release: 위로 -60, 아래로 +60 + 페이드 (0.5s)
func _draw_jaws() -> void:
	var center: Vector2 = _target + JAWS_OFFSET
	var top_offset_y: float = -JAW_OPEN_DIST
	var bot_offset_y: float = JAW_OPEN_DIST
	var alpha: float = 1.0
	match _jaws_phase:
		"appear":
			pass  # open 상태 유지
		"snap":
			var t: float = clampf(_jaws_age / SNAP_TIME, 0.0, 1.0)
			# cubic-bezier (.6,.0,.9,1) — 빠르게 가속. 종료 위치 = ±JAW_CLOSED_DIST (송곳니 끝 만남).
			var k: float = 1.0 - pow(1.0 - t, 3.0)
			top_offset_y = lerpf(-JAW_OPEN_DIST, -JAW_CLOSED_DIST, k)
			bot_offset_y = lerpf(JAW_OPEN_DIST, JAW_CLOSED_DIST, k)
		"clamp":
			# 닫힌 위치 (±JAW_CLOSED_DIST) 기준 작은 떨림 — 60% 시점까지 ±3px
			var t2: float = clampf(_jaws_age / CLAMP_TIME, 0.0, 1.0)
			var bump: float = 0.0
			if t2 < 0.6:
				var sub: float = t2 / 0.6
				bump = sin(sub * PI) * 3.0
			top_offset_y = -JAW_CLOSED_DIST + bump
			bot_offset_y = JAW_CLOSED_DIST - bump
		"fade":
			# 위치 유지 + alpha 0 페이드 (release 처럼 위/아래 사라지지 않음)
			var t3: float = clampf(_jaws_age / FADE_TIME, 0.0, 1.0)
			top_offset_y = -JAW_CLOSED_DIST
			bot_offset_y = JAW_CLOSED_DIST
			alpha = 1.0 - t3
	# snap 트레일 블러 (snap 페이즈 동안만, 진행 70%까지 빛남)
	if _jaws_phase == "snap":
		var t4: float = _jaws_age / SNAP_TIME
		var blur_alpha: float = 0.0
		if t4 < 0.4:
			blur_alpha = t4 / 0.4 * 0.9
		else:
			blur_alpha = (1.0 - t4) / 0.6 * 0.9
		_draw_jaw_blur(center, blur_alpha)
	# 위 송곳니
	_draw_jaw_row(center + Vector2(0.0, top_offset_y), FANG_TOP, true, alpha)
	# 아래 송곳니
	_draw_jaw_row(center + Vector2(0.0, bot_offset_y), FANG_BOT, false, alpha)

# 송곳니 한 줄 + gum (잇몸 아치)
func _draw_jaw_row(center: Vector2, fangs: Array, is_top: bool, alpha: float) -> void:
	var total_width: float = 0.0
	for f in fangs:
		total_width += float(f[0]) + 2.0
	# 위/아래 모두 자체 좌우 대칭 (center.x 중심 정렬). 위 6개 / 아래 5개 — 아래 송곳니 위치가
	# 자연스럽게 위 송곳니 사이 gap 의 가운데로 떨어져 지그재그 맞물림 (별도 offset 불필요).
	var x: float = center.x - total_width * 0.5
	var gum_y: float = center.y if is_top else center.y
	# 잇몸 아치 — 송곳니 줄 위/아래 base 라인
	var gum_h: float = 11.0
	var gum_rect: Rect2
	if is_top:
		gum_rect = Rect2(center.x - JAWS_WIDTH * 0.4, gum_y - gum_h * 0.5, JAWS_WIDTH * 0.8, gum_h)
	else:
		gum_rect = Rect2(center.x - JAWS_WIDTH * 0.4, gum_y - gum_h * 0.5, JAWS_WIDTH * 0.8, gum_h)
	draw_rect(gum_rect, Color(COL_GUM_TOP.r, COL_GUM_TOP.g, COL_GUM_TOP.b, alpha))
	# 송곳니 — 삼각형 (clip-path polygon(50% 100%, 0 0, 100% 0))
	for f in fangs:
		var fw: float = float(f[0])
		var fh: float = float(f[1])
		var apex_y: float
		var base_y: float
		if is_top:
			# 위 송곳니: gum 아래로 뾰족 (apex 가 base 아래)
			base_y = gum_y + gum_h * 0.5 - 2.0
			apex_y = base_y + fh
		else:
			# 아래 송곳니: gum 위로 뾰족 (apex 가 base 위)
			base_y = gum_y - gum_h * 0.5 + 2.0
			apex_y = base_y - fh
		var poly := PackedVector2Array()
		poly.push_back(Vector2(x, base_y))                       # 좌상
		poly.push_back(Vector2(x + fw, base_y))                  # 우상
		poly.push_back(Vector2(x + fw * 0.5, apex_y))            # 뾰족 끝
		# gradient 매핑 — 단색 (mid) + 하이라이트 (좌 edge) + 그림자 (우 edge)
		draw_polygon(poly, [Color(COL_BONE_MID.r, COL_BONE_MID.g, COL_BONE_MID.b, alpha)])
		# 좌 edge 하이라이트
		draw_line(Vector2(x, base_y), Vector2(x + fw * 0.5, apex_y), Color(COL_BONE_HOT.r, COL_BONE_HOT.g, COL_BONE_HOT.b, alpha * 0.85), 1.2)
		# 우 edge 그림자
		draw_line(Vector2(x + fw, base_y), Vector2(x + fw * 0.5, apex_y), Color(COL_BONE_SHADOW.r, COL_BONE_SHADOW.g, COL_BONE_SHADOW.b, alpha * 0.7), 1.0)
		x += fw + 2.0

# SNAP 트레일 블러 — 위/아래 호 모양 빛 (단순화: 두 ellipse)
func _draw_jaw_blur(center: Vector2, alpha: float) -> void:
	if alpha <= 0.01:
		return
	var col := Color(COL_BONE_MID.r, COL_BONE_MID.g, COL_BONE_MID.b, alpha * 0.45)
	# 위 호 (위쪽이 진하고 아래로 페이드 — 정확한 그라데이션 어려워 ellipse 두 개 근사)
	draw_set_transform(center + Vector2(0.0, -30.0), 0.0, Vector2(1.0, 0.5))
	draw_circle(Vector2.ZERO, 60.0, col)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_set_transform(center + Vector2(0.0, 30.0), 0.0, Vector2(1.0, 0.5))
	draw_circle(Vector2.ZERO, 60.0, col)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

# ── PUNCTURES — 8개 핏자국 (위 4 + 아래 4) + drip line ──
func _draw_punctures() -> void:
	var t: float = _puncture_age / PUNCTURE_TIME
	var alpha: float
	if t < 0.1:
		alpha = t / 0.1
	elif t < 0.8:
		alpha = 1.0
	else:
		alpha = (1.0 - t) / 0.2
	# PUNCTURE_OFFSET = center offset. 영역을 center 기준 ±AREA/2 로 펼침.
	var center: Vector2 = _target + PUNCTURE_OFFSET
	var top_y: float = center.y - PUNCTURE_AREA.y * 0.5 + 8.0
	var bot_y: float = center.y + PUNCTURE_AREA.y * 0.5 - 8.0
	var spacing: float = PUNCTURE_AREA.x / 4.0
	for i in 4:
		var px: float = center.x - PUNCTURE_AREA.x * 0.5 + spacing * 0.5 + float(i) * spacing
		# 위 자국 + drip line 아래로
		_draw_one_puncture(Vector2(px, top_y), alpha, true)
		# 아래 자국 + drip line 위로
		_draw_one_puncture(Vector2(px, bot_y), alpha, false)

func _draw_one_puncture(pos: Vector2, alpha: float, drip_down: bool) -> void:
	# 핏자국 점 (radial: bright → blood → deep)
	draw_circle(pos, 4.0, Color(COL_BLOOD_BRIGHT.r, COL_BLOOD_BRIGHT.g, COL_BLOOD_BRIGHT.b, alpha))
	draw_circle(pos, 2.5, Color(COL_BLOOD.r, COL_BLOOD.g, COL_BLOOD.b, alpha))
	draw_circle(pos, 1.0, Color(0.0, 0.0, 0.0, alpha))
	# drip line — 18px 길이, 페이드 그라데이션 단순화 (두 segment)
	var drip_len: float = 14.0
	var end: Vector2 = pos + Vector2(0.0, drip_len if drip_down else -drip_len)
	draw_line(pos, end, Color(COL_BLOOD.r, COL_BLOOD.g, COL_BLOOD.b, alpha * 0.7), 1.5)
	draw_line(end, pos + Vector2(0.0, (drip_len + 4.0) if drip_down else -(drip_len + 4.0)), Color(COL_BLOOD_DEEP.r, COL_BLOOD_DEEP.g, COL_BLOOD_DEEP.b, alpha * 0.3), 1.0)

# ── 파티클 spawn ──
func _spawn_blood_burst() -> void:
	var pos: Vector2 = _target + JAWS_OFFSET
	# wide spray 70 작은
	for _i in _pcount(70):
		var ang := -PI * 0.5 + (randf() - 0.5) * PI * 1.8
		var sp := (3.0 + randf() * 9.0) * 60.0
		_particles.append({
			"pos": pos,
			"vel": Vector2(cos(ang), sin(ang)) * sp,
			"life": 0.0, "max_life": 0.7 + randf() * 0.9,
			"r": 1.4 + randf() * 2.4, "kind": "blood", "grav": 0.18 * 60.0,
		})
	# fat 16 큰
	for _i in _pcount(16):
		var ang := -PI * 0.5 + (randf() - 0.5) * PI * 1.2
		var sp := (4.0 + randf() * 5.0) * 60.0
		_particles.append({
			"pos": pos,
			"vel": Vector2(cos(ang), sin(ang)) * sp,
			"life": 0.0, "max_life": 1.0 + randf() * 1.0,
			"r": 3.0 + randf() * 3.4, "kind": "blood", "grav": 0.24 * 60.0,
		})
	# bone 10
	for _i in _pcount(10):
		var ang := -PI * 0.5 + (randf() - 0.5) * PI * 1.4
		var sp := (4.0 + randf() * 5.0) * 60.0
		_particles.append({
			"pos": pos,
			"vel": Vector2(cos(ang), sin(ang)) * sp,
			"life": 0.0, "max_life": 0.7 + randf() * 0.5,
			"r": 1.4 + randf() * 1.6, "kind": "bone", "grav": 0.18 * 60.0,
			"rot": randf() * PI, "vrot": (randf() - 0.5) * 24.0,
		})

func _spawn_drip() -> void:
	var pos: Vector2 = _target + JAWS_OFFSET
	for _i in _pcount(3):
		var ox := (randf() - 0.5) * 40.0
		var oy := -10.0 + randf() * 30.0
		_particles.append({
			"pos": pos + Vector2(ox, oy),
			"vel": Vector2((randf() - 0.5) * 24.0, (0.4 + randf() * 0.6) * 60.0),
			"life": 0.0, "max_life": 1.1 + randf() * 0.5,
			"r": 2.0 + randf() * 1.5, "kind": "drip", "grav": 0.12 * 60.0,
		})

func _draw_particles() -> void:
	for p in _particles:
		var k: float = float(p["life"]) / float(p["max_life"])
		var alpha: float = 1.0 - k
		var pos: Vector2 = p["pos"]
		var r: float = float(p["r"])
		match p["kind"]:
			"blood", "drip":
				var col := Color(COL_BLOOD.r * (1.0 - k * 0.4), COL_BLOOD.g, COL_BLOOD.b, 0.95 * alpha)
				var vel: Vector2 = p["vel"]
				if vel.length() > 130.0:
					var ang := vel.angle()
					draw_set_transform(pos, ang, Vector2(1.7, 0.7))
					draw_circle(Vector2.ZERO, r, col)
					draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
				else:
					draw_circle(pos, r, col)
			"bone":
				var col2 := Color(COL_BONE_MID.r, COL_BONE_MID.g, COL_BONE_MID.b, alpha)
				var rot: float = float(p.get("rot", 0.0))
				draw_set_transform(pos, rot, Vector2.ONE)
				draw_rect(Rect2(-r * 2.0, -r * 0.4, r * 4.0, r * 0.8), col2)
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
