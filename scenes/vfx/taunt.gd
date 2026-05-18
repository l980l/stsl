# scenes/vfx/taunt.gd
# 도발 (TAUNT) VFX — 적이 영웅에게 도발 부여 시 시전 적 위치에 재현.
# ui_sample/vfx/Taunt VFX.html 변환.
# play(caster_pos, target_pos) — caster_pos = 시전 적, target_pos 미사용 (자기 중심).
# 단계:
#   windup 0.32s — 시전자 가슴 빌드업 (시각적으론 fade-in 만 — 적 sprite 자체에 위빙 X)
#   thump 0.32s — chest flash + 3 concentric shockwave + flash + ground crack + glyph + 한글 "도발" + particles
#   hold 0.9s — 글리프 회전 + word shake
#   fade 0.7s
extends Node2D

signal screen_effect

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

# 색상 (HTML --taunt 계열)
const COL_HOT     := Color(1.0, 1.0, 1.0)
const COL_TAUNT   := Color(0.851, 0.290, 0.314)   # #d94a50 붉음
const COL_BURN    := Color(1.0, 0.423, 0.290)     # #ff6c4a 오렌지빨강
const COL_DEEP    := Color(0.419, 0.078, 0.094)   # #6b1418
const COL_BRASS   := Color(0.910, 0.784, 0.470)   # #e8c878 황금
const COL_INK     := Color(0.027, 0.024, 0.039)

# 타이밍 (HTML 의 cast() 시퀀스 단순화)
const WINDUP_TIME  := 0.32
const IMPACT_DELAY := WINDUP_TIME               # 0.32s — chest thump + shockwave + word + 흡입선
const HOLD_TIME    := 0.6
const FADE_TIME    := 0.5

# 기하 — 캐릭터 sprite (64~80px) 대비 적정 비율
const SHOCK_BASE_R := 16.0
const SHOCK_MAX_R  := 320.0       # 더 크게 (요청)
const CHEST_R      := 14.0
const WORD_OFFSET_Y := -80.0      # 타겟 머리 위
const CRACK_OFFSET_Y := 48.0      # (미사용 — anchor 호환만)

var _caster := Vector2.ZERO
var _target := Vector2.ZERO      # 도발 대상 영웅 (화살표 + stamp 표시용). ZERO 면 미표시.
var _ground_pos := Vector2.ZERO
var _has_ground: bool = false
# "Attention!" 텍스트 3개의 랜덤 속성 (rotation/scale/offset). _ready 에서 한 번 결정.
var _word_inst: Array = []

func set_ground_anchor(pos: Vector2) -> void:
	_ground_pos = pos
	_has_ground = true

func _foot_pos() -> Vector2:
	return _ground_pos if _has_ground else _caster + Vector2(0.0, CRACK_OFFSET_Y)

var _age := -1.0
var _impact_emitted := false
var _particles: Array = []

var _bg_layer: Node2D    # ground crack + heat tint (lower)
var _shock_layer: Node2D # 3 shockwave (additive)
var _glow_layer: Node2D  # chest flash + glyph + word (additive)
var _smoke_layer: Node2D # smoke/dust particles (normal blend)

func _ready() -> void:
	set_process(false)
	# Attention! 3개 — 각각 랜덤 회전 (-60~60도) · 크기 (0.7~1.0) · 위치 오프셋
	_word_inst.clear()
	for _i in range(3):
		_word_inst.append({
			"rot": deg_to_rad(randf_range(-30.0, 30.0)),
			"scale": randf_range(0.7, 1.3),
			"offset": Vector2(randf_range(-110.0, 110.0), randf_range(-50.0, 50.0)),
			# 흔들림 각각 다른 phase — 동기 안 되게
			"shake_phase_x": randf() * TAU,
			"shake_phase_y": randf() * TAU,
		})
	_bg_layer = _DrawLayer.new()
	_bg_layer.setup(self, false)  # ground crack — normal blend
	add_child(_bg_layer)
	_bg_layer.set_meta("pass", "bg")
	_shock_layer = _DrawLayer.new()
	_shock_layer.setup(self, true)  # additive shockwaves
	add_child(_shock_layer)
	_shock_layer.set_meta("pass", "shock")
	_smoke_layer = _DrawLayer.new()
	_smoke_layer.setup(self, false)  # smoke normal
	add_child(_smoke_layer)
	_smoke_layer.set_meta("pass", "smoke")
	_glow_layer = _DrawLayer.new()
	_glow_layer.setup(self, true)  # glow + glyph + word
	add_child(_glow_layer)
	_glow_layer.set_meta("pass", "glow")

func play(caster_pos: Vector2, target_pos: Vector2) -> void:
	_caster = caster_pos
	# target_pos == caster 면 영웅 화살표 X (시전자 본인 자기 대상 케이스)
	if target_pos != Vector2.ZERO and target_pos != caster_pos:
		_target = target_pos
	_age = 0.0
	set_process(true)
	var total: float = IMPACT_DELAY + 0.32 + HOLD_TIME + FADE_TIME + 0.1
	await get_tree().create_timer(total).timeout
	if is_inside_tree():
		queue_free()

func _process(delta: float) -> void:
	_age += delta
	if not _impact_emitted and _age >= IMPACT_DELAY:
		_impact_emitted = true
		_spawn_impact_particles()
		screen_effect.emit()
	_update_particles(delta)
	_bg_layer.queue_redraw()
	_shock_layer.queue_redraw()
	_smoke_layer.queue_redraw()
	_glow_layer.queue_redraw()

func _global_alpha() -> float:
	var end_phase: float = IMPACT_DELAY + 0.32 + HOLD_TIME
	if _age < end_phase:
		return clampf(_age / 0.15, 0.0, 1.0)
	var t: float = (_age - end_phase) / FADE_TIME
	return clampf(1.0 - t, 0.0, 1.0)

# ── 파티클 ── (제거됨 — 사용자 피드백: 모든 파티클 제거)
func _spawn_impact_particles() -> void:
	pass

func _update_particles(delta: float) -> void:
	for i in range(_particles.size() - 1, -1, -1):
		var p: Dictionary = _particles[i]
		p["life"] += delta
		if p["life"] >= p["max_life"]:
			_particles.remove_at(i)
			continue
		p["x"] += p["vx"] * delta
		p["y"] += p["vy"] * delta
		p["vy"] += p["grav"]
		p["vx"] *= pow(0.98, delta * 60.0)
		p["vy"] *= pow(0.98, delta * 60.0)

# ── 레이어별 draw ──
func _draw_bg_pass(_canvas: CanvasItem) -> void:
	# ground crack 제거 — 사용자 피드백.
	pass

func _draw_shock_pass(canvas: CanvasItem) -> void:
	var ga: float = _global_alpha()
	if ga <= 0.0 or not _impact_emitted:
		return
	var shock_age: float = _age - IMPACT_DELAY
	# 비주얼 크기는 파티클 갯수 옵션과 무관 — s=1.0 고정 전달
	# 3 concentric shockwave (s1: red strong / s2: burn / s3: brass) — 빠르게 (duration 1/3)
	_draw_one_shock(canvas, shock_age, 0.0, 0.32, COL_TAUNT, 3.0, ga, 1.0)
	_draw_one_shock(canvas, shock_age, 0.05, 0.38, COL_BURN, 2.2, ga * 0.85, 1.0)
	_draw_one_shock(canvas, shock_age, 0.10, 0.44, COL_BRASS, 1.6, ga * 0.7, 1.0)
	# chest flash (interior burst)
	if shock_age < 0.35:
		var k: float = shock_age / 0.35
		var alpha: float = (1.0 - k) * ga
		var r: float = CHEST_R * (0.3 + k * 2.0)
		canvas.draw_circle(_caster + Vector2(0.0, -50.0), r, Color(COL_HOT.r, COL_HOT.g, COL_HOT.b, alpha * 0.9))
		canvas.draw_circle(_caster + Vector2(0.0, -50.0), r * 0.55, Color(COL_BURN.r, COL_BURN.g, COL_BURN.b, alpha))

func _draw_one_shock(canvas: CanvasItem, shock_age: float, delay: float, duration: float, col: Color, width: float, ga: float, s: float) -> void:
	var t: float = shock_age - delay
	if t < 0.0 or t > duration:
		return
	var k: float = t / duration
	var r: float = SHOCK_BASE_R + (SHOCK_MAX_R - SHOCK_BASE_R) * k
	r *= s
	var alpha: float = 0.0
	if k < 0.15:
		alpha = (k / 0.15) * ga
	else:
		alpha = (1.0 - (k - 0.15) / 0.85) * ga
	var w: float = max(1.0, width * (1.0 - k * 0.7)) * s
	# 원 path
	var seg := 64
	var pts := PackedVector2Array()
	for i in range(seg + 1):
		var a: float = TAU * float(i) / float(seg)
		pts.append(_caster + Vector2(cos(a), sin(a)) * r + Vector2(0.0, -50.0))
	canvas.draw_polyline(pts, Color(col.r, col.g, col.b, alpha), w, true)

func _draw_smoke_pass(canvas: CanvasItem) -> void:
	var ga: float = _global_alpha()
	if ga <= 0.0:
		return
	# smoke + dust (lower layer, normal blend)
	for p in _particles:
		var kind: String = p["kind"]
		if kind != "smoke" and kind != "dust":
			continue
		var k: float = float(p["life"]) / float(p["max_life"])
		var a: float = (1.0 - k) * 0.4 * ga
		var r: float = float(p["size"]) * (1.0 + k * 1.5)
		var col: Color
		if kind == "smoke":
			col = Color(1.0, 0.55, 0.35, a * 0.7)
		else:
			col = Color(0.70, 0.55, 0.35, a)
		canvas.draw_circle(Vector2(p["x"], p["y"]), r, col)

func _draw_glow_pass(canvas: CanvasItem) -> void:
	var ga: float = _global_alpha()
	if ga <= 0.0:
		return
	# sparks + embers (additive)
	for p in _particles:
		var kind: String = p["kind"]
		if kind != "spark" and kind != "ember":
			continue
		var k: float = float(p["life"]) / float(p["max_life"])
		var a: float = (1.0 - k) * ga
		var col: Color
		if kind == "spark":
			col = Color(1.0, (180.0 - 80.0 * k) / 255.0, (110.0 - 60.0 * k) / 255.0, a)
			canvas.draw_circle(Vector2(p["x"], p["y"]), float(p["size"]), col)
		else:
			col = Color(1.0, (140.0 - 60.0 * k) / 255.0, (80.0 - 40.0 * k) / 255.0, a * 0.9)
			canvas.draw_circle(Vector2(p["x"], p["y"]), float(p["size"]), col)
	# "Attention!" 3개 — 시전자 머리 위, 랜덤 회전·크기·오프셋
	if _impact_emitted:
		_draw_word(canvas, ga)
	# 타겟 → 시전자 점선 흡입 (방향 반전)
	if _target != Vector2.ZERO:
		_draw_suction_line(canvas, ga)

func _draw_word(canvas: CanvasItem, ga: float) -> void:
	# "Attention!" 3개 — 시전자 머리 위, 각 인스턴스마다 랜덤 회전·크기·오프셋
	var word_age: float = _age - IMPACT_DELAY
	if word_age < 0.0:
		return
	var pop_t: float = clampf(word_age / 0.25, 0.0, 1.0)
	var alpha: float = ga * pop_t
	var word_end: float = HOLD_TIME
	if word_age > word_end:
		alpha *= clampf(1.0 - (word_age - word_end) / 0.4, 0.0, 1.0)
	if alpha <= 0.01:
		return
	var theme_font: Font = null
	var sacred = get_node_or_null("/root/SacredTheme")
	if sacred and sacred.theme != null:
		theme_font = sacred.theme.default_font
	if theme_font == null:
		theme_font = ThemeDB.fallback_font
	var text := "Attention!"
	# 텍스트·흔들림은 파티클 갯수 옵션과 무관 — _scale() 곱셈 X (그래픽 옵션이 글씨 크기 줄이면 버그)
	var base_fsize: int = 30
	var origin := _caster + Vector2(0.0, WORD_OFFSET_Y)
	for inst in _word_inst:
		var fsize: int = int(base_fsize * float(inst["scale"]))
		var size_v: Vector2 = theme_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize)
		var rot: float = float(inst["rot"])
		# 흔들림 (각 인스턴스 다른 phase) — 진폭 2~3px 고정
		var shake_x: float = sin(word_age * 90.0 + float(inst["shake_phase_x"])) * 2.5
		var shake_y: float = cos(word_age * 110.0 + float(inst["shake_phase_y"])) * 2.0
		var center: Vector2 = origin + inst["offset"] + Vector2(shake_x, shake_y)
		# 회전 적용 — canvas 변환 사용
		canvas.draw_set_transform(center, rot, Vector2.ONE)
		var draw_pos := Vector2(-size_v.x * 0.5, 0.0)
		# 그림자 (붉음)
		canvas.draw_string(theme_font, draw_pos + Vector2(0.0, 3.0), text,
			HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, Color(COL_DEEP.r, COL_DEEP.g, COL_DEEP.b, alpha * 0.9))
		# 본체 (흰)
		canvas.draw_string(theme_font, draw_pos, text,
			HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, Color(COL_HOT.r, COL_HOT.g, COL_HOT.b, alpha))
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

# ── 타겟 → 시전자 점선 (성장) ──
# 점선이 타겟 위에서 시작해 시전자 방향으로 점차 길어지며 이어지는 느낌.
# 0~grow_dur: 점선 끝점이 0 → dist 로 자라남 (시전자에 닿음)
# grow_dur~hold_dur: 100% 유지 (정적 dash, 약간 흐름)
# hold_dur~end: fade out
func _draw_suction_line(canvas: CanvasItem, ga: float) -> void:
	var line_age: float = _age - IMPACT_DELAY
	if line_age < 0.0:
		return
	var grow_dur := 0.35
	var hold_dur := 0.5
	var fade_dur := 0.3
	var alpha: float = ga
	if line_age > grow_dur + hold_dur:
		alpha *= clampf(1.0 - (line_age - grow_dur - hold_dur) / fade_dur, 0.0, 1.0)
	if alpha <= 0.01:
		return
	var p_target := _target + Vector2(0.0, -30.0)
	var p_caster := _caster + Vector2(0.0, -50.0)
	var dir := (p_caster - p_target).normalized()  # target → caster 방향
	var dist: float = p_target.distance_to(p_caster)
	if dist < 1.0:
		return
	# 성장 진행도: 0 → 1
	var grow_t: float = clampf(line_age / grow_dur, 0.0, 1.0)
	# ease out — 빠르게 자라다가 천천히
	grow_t = 1.0 - pow(1.0 - grow_t, 2.0)
	var effective_dist: float = dist * grow_t
	# 정적 점선 (흐름 X) — 타겟에서 dash 시작
	var dash_len: float = 8.0
	var gap_len: float = 8.0
	var step: float = dash_len + gap_len
	var col := Color(COL_BURN.r, COL_BURN.g, COL_BURN.b, alpha * 0.85)
	var t: float = 0.0
	while t < effective_dist:
		var a_pos: Vector2 = p_target + dir * t
		var b_pos: Vector2 = p_target + dir * min(t + dash_len, effective_dist)
		canvas.draw_line(a_pos, b_pos, col, 1.8, true)
		t += step

# ── 블렌드 분리 레이어 ──
class _DrawLayer:
	extends Node2D
	var _fx: Node2D

	func setup(owner_fx: Node2D, additive: bool) -> void:
		_fx = owner_fx
		if additive:
			var m := CanvasItemMaterial.new()
			m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
			material = m

	func _draw() -> void:
		match get_meta("pass", "glow"):
			"bg":    _fx._draw_bg_pass(self)
			"shock": _fx._draw_shock_pass(self)
			"smoke": _fx._draw_smoke_pass(self)
			_:       _fx._draw_glow_pass(self)
