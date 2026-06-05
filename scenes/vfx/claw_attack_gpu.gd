# scenes/vfx/claw_attack_gpu.gd
# 할퀴기 GPU VFX — ui_sample/vfx/Claw Attack VFX.html 정확 재현.
# 단독 Node2D + 자식 _RakeLayer (가산 블렌드 — HTML screen blend) + 메인 _draw (gash 일반 블렌드) + GPU blood.
# 단계: CROUCH 0.28s → SWIPE (3 rake 0.05s 간격) → IMPACT (가운데) → AFTERMATH (gash 페이드 2.8s).
extends Node2D

const _Helpers = preload("res://scenes/vfx/gpu_particle_helpers.gd")

signal screen_effect

# 색 — HTML CSS var 매핑
const COL_BLOOD        := Color(0.722, 0.082, 0.133)  # #b81522
const COL_BLOOD_DEEP   := Color(0.227, 0.024, 0.031)  # #3a0608

const CROUCH_TIME  := 0.28
const RAKE_GAP     := 0.05
const RAKE_DUR     := 0.10    # 호 머리 진행 시간 — 짧게 (휙 지나감)
const RAKE_DECAY   := 0.20    # decay 도 짧게
const GASH_TIME    := 2.8
const IMPACT_DELAY := CROUCH_TIME + RAKE_GAP * 2.0  # 0.38 — 마지막 rake 발사 시점 (= 첫 rake 통과)

const SFX_IMPACT := "claw_attack"

var _caster := Vector2.ZERO
var _target := Vector2.ZERO
var _particle_scale_override: float = -1.0

var _rakes: Array = []
var _gash_age: float = -1.0
var _gash_data: Array = []  # [{top_pts, bot_pts, mid_pts, top_cols, body_cols, hi_cols, spatter, drips}]
var _rake_layer: Node2D

# 가산 블렌드 rake 그리기 자식 노드 (HTML screen blend 매핑)
class _RakeLayer extends Node2D:
	var _vfx: Object = null
	func _draw() -> void:
		if _vfx == null:
			return
		_vfx._paint_rakes_on(self)

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

func _ready() -> void:
	_rake_layer = _RakeLayer.new()
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_rake_layer.material = mat
	_rake_layer._vfx = self
	add_child(_rake_layer)

func play(caster: Vector2, target: Vector2) -> void:
	_caster = caster
	_target = target
	_run_sequence()

func _run_sequence() -> void:
	await get_tree().create_timer(CROUCH_TIME).timeout
	# 3 rake 빠르게 발사 (0.05s 간격, RAKE_DUR 0.10s — 휙 지나감)
	_fire_rake(-32.0)
	await get_tree().create_timer(RAKE_GAP).timeout
	_fire_rake(0.0)
	await get_tree().create_timer(RAKE_GAP).timeout
	_fire_rake(32.0)
	# 이 시점 = 첫 rake fire 후 RAKE_GAP*2 = 0.10s 경과 = 첫 rake 가 막 target 통과.
	# 상흔 즉시 spawn (사용자: "지나감과 동시에").
	emit_signal("screen_effect")
	_spawn_gashes()
	_spawn_blood(-28.0)
	# 가운데/마지막 rake 통과 시점에 추가 blood
	get_tree().create_timer(RAKE_GAP).timeout.connect(func() -> void:
		if is_instance_valid(self): _spawn_blood(0.0))
	get_tree().create_timer(RAKE_GAP * 2.0).timeout.connect(func() -> void:
		if is_instance_valid(self): _spawn_blood(30.0))
	await get_tree().create_timer(GASH_TIME + 0.5).timeout
	queue_free()

# rake — target 왼쪽 → 오른쪽, 아래로 활처럼 휘는 베지어. 좀 더 길게 (사용자 요청).
func _fire_rake(y_offset: float) -> void:
	var x0: float = _target.x - 140.0 + randf_range(-3.0, 3.0)
	var y0: float = _target.y - 60.0 + y_offset + randf_range(-2.0, 2.0)
	var x1: float = _target.x + 130.0
	var y1: float = _target.y + 60.0 + y_offset + randf_range(-2.0, 2.0)
	var cx: float = (x0 + x1) * 0.5 + 12.0
	var cy: float = (y0 + y1) * 0.5 + 22.0
	var n: int = 22
	var pts := PackedVector2Array()
	for i in n + 1:
		var u: float = float(i) / float(n)
		var iu: float = 1.0 - u
		pts.push_back(Vector2(
			iu * iu * x0 + 2.0 * iu * u * cx + u * u * x1,
			iu * iu * y0 + 2.0 * iu * u * cy + u * u * y1
		))
	_rakes.append({"pts": pts, "elapsed": 0.0, "decay": 0.0})

func _process(delta: float) -> void:
	for i in range(_rakes.size() - 1, -1, -1):
		var r: Dictionary = _rakes[i]
		r["elapsed"] = float(r["elapsed"]) + delta
		var head: float = clampf(float(r["elapsed"]) / RAKE_DUR, 0.0, 1.0)
		if head >= 1.0:
			r["decay"] = float(r["decay"]) + delta
			if float(r["decay"]) >= RAKE_DECAY:
				_rakes.remove_at(i)
	if _gash_age >= 0.0:
		_gash_age += delta
		if _gash_age > GASH_TIME:
			_gash_age = -1.0
	queue_redraw()
	if _rake_layer != null:
		_rake_layer.queue_redraw()

# 메인 노드 — gash 흉터만 (일반 블렌드)
func _draw() -> void:
	if _gash_age >= 0.0:
		_draw_gashes()

# ── rake (자식 가산 블렌드 레이어가 호출) ──
# HTML 3-layer stroke: wide warm glow 18px + medium white 7px + bright core 2px.
# 가산 블렌드라 여러 layer 가 빛으로 합성됨. 두께 그라데이션은 polyline 으로 못 함 — 다중 polyline 으로 근사.
func _paint_rakes_on(layer: Node2D) -> void:
	for r in _rakes:
		var pts: PackedVector2Array = r["pts"]
		var ela: float = float(r["elapsed"])
		var head: float = clampf(ela / RAKE_DUR, 0.0, 1.0)
		var decay_k: float = clampf(float(r["decay"]) / RAKE_DECAY, 0.0, 1.0)
		var alpha: float = 1.0 - decay_k
		if alpha <= 0.01:
			continue
		var head_idx: int = clampi(int(head * float(pts.size() - 1)), 0, pts.size() - 1)
		var tail_frac: float = maxf(0.0, head - 0.35)
		var tail_idx: int = clampi(int(tail_frac * float(pts.size() - 1)), 0, head_idx)
		if head_idx <= tail_idx:
			continue
		# 머리부터 꼬리까지 각 segment 별로 그라데이션 색 매핑 (꼬리 어둡고 머리 밝음).
		# HTML 그라데이션 (꼬리→머리): 빨강 fade → 살구 → 크림 → 흰. 가산 블렌드라 색 합산.
		var n_seg: int = head_idx - tail_idx
		# 각 segment 를 작은 polyline (2점) 으로 그려서 색 보간. n_seg ~10 정도라 부담 적음.
		for s in n_seg:
			var idx0: int = tail_idx + s
			var idx1: int = idx0 + 1
			var u: float = float(s) / float(maxi(1, n_seg - 1))  # 0=tail, 1=head
			var seg := PackedVector2Array()
			seg.push_back(pts[idx0])
			seg.push_back(pts[idx1])
			# Layer 1: 큰 글로우 18px — 빨강→살구→크림→흰 (alpha 점진)
			var c1 := _rake_color(u, alpha, 0)
			layer.draw_polyline(seg, c1, 18.0)
			# Layer 2: 중간 7px — 살구→크림→흰 (alpha 더 진함)
			var c2 := _rake_color(u, alpha, 1)
			layer.draw_polyline(seg, c2, 7.0)
			# Layer 3: 코어 2px — 흰 (alpha 가장 진함)
			var c3 := _rake_color(u, alpha, 2)
			layer.draw_polyline(seg, c3, 2.0)

# layer: 0=glow, 1=medium, 2=core. u: 0=tail, 1=head.
func _rake_color(u: float, alpha: float, layer_idx: int) -> Color:
	# HTML 그라데이션 stops (꼬리→머리):
	# layer 0 (18px): 0:rgba(184,21,34,0) 0.3:rgba(255,180,140,0.18) 0.85:rgba(255,246,228,0.45) 1:rgba(255,255,255,0.65)
	# layer 1 (7px):  0:rgba(255,180,140,0) 0.5:rgba(255,236,200,0.7) 1:rgba(255,255,255,0.95)
	# layer 2 (2px):  0:rgba(255,236,200,0) 0.6:rgba(255,255,255,0.95) 1:rgba(255,255,255,1.0)
	match layer_idx:
		0:
			if u < 0.3:
				var t: float = u / 0.3
				return Color(1.0, lerpf(0.082, 0.706, t), lerpf(0.133, 0.549, t), lerpf(0.0, 0.18, t) * alpha)
			elif u < 0.85:
				var t2: float = (u - 0.3) / 0.55
				return Color(1.0, lerpf(0.706, 0.965, t2), lerpf(0.549, 0.894, t2), lerpf(0.18, 0.45, t2) * alpha)
			else:
				var t3: float = (u - 0.85) / 0.15
				return Color(1.0, lerpf(0.965, 1.0, t3), lerpf(0.894, 1.0, t3), lerpf(0.45, 0.65, t3) * alpha)
		1:
			if u < 0.5:
				var t: float = u / 0.5
				return Color(1.0, lerpf(0.706, 0.925, t), lerpf(0.549, 0.784, t), lerpf(0.0, 0.7, t) * alpha)
			else:
				var t2: float = (u - 0.5) / 0.5
				return Color(1.0, lerpf(0.925, 1.0, t2), lerpf(0.784, 1.0, t2), lerpf(0.7, 0.95, t2) * alpha)
		_:
			if u < 0.6:
				var t: float = u / 0.6
				return Color(1.0, lerpf(0.925, 1.0, t), lerpf(0.784, 1.0, t), lerpf(0.0, 0.95, t) * alpha)
			else:
				var t2: float = (u - 0.6) / 0.4
				return Color(1.0, 1.0, 1.0, lerpf(0.95, 1.0, t2) * alpha)

# ── blood spray (GPU) ──
func _spawn_blood(y_off: float) -> void:
	var pos: Vector2 = _target + Vector2(-10.0 + y_off * 0.6, y_off)
	var small := _Helpers.make_emitter({
		"count": _pcount(22), "lifetime": 1.3, "color": COL_BLOOD,
		"speed_min": 180.0, "speed_max": 540.0,
		"direction": Vector2.RIGHT, "spread": 126.0,
		"gravity": 13.2,
		"size_min": 1.4, "size_max": 3.2,
		"additive": false,
		"start_alpha": 0.95, "mid_alpha": 0.55, "end_alpha": 0.0,
	})
	small.position = pos
	add_child(small)
	var fat := _Helpers.make_emitter({
		"count": _pcount(5), "lifetime": 1.7, "color": COL_BLOOD,
		"speed_min": 240.0, "speed_max": 480.0,
		"direction": Vector2.UP, "spread": 60.0,
		"gravity": 14.4,
		"size_min": 2.6, "size_max": 4.6,
		"additive": false,
		"start_alpha": 0.95, "mid_alpha": 0.55, "end_alpha": 0.0,
	})
	fat.position = pos
	add_child(fat)

# ── gash (3개 흉터) — bake 시 jitter/spatter/drip 모두 미리 계산 ──
func _spawn_gashes() -> void:
	_gash_age = 0.0
	_gash_data.clear()
	var cuts := [
		{"d0": Vector2(-32.0, -46.0), "d1": Vector2(32.0, -12.0), "w": 3.6, "seed": 7},
		{"d0": Vector2(-36.0, -20.0), "d1": Vector2(34.0, 18.0), "w": 4.2, "seed": 13},
		{"d0": Vector2(-30.0, 8.0), "d1": Vector2(30.0, 42.0), "w": 3.4, "seed": 19},
	]
	for c in cuts:
		_gash_data.append(_bake_gash(_target + c["d0"], _target + c["d1"], c["w"], c["seed"]))

# HTML drawGash 매핑 — taper, jitter, spatter dots, drips.
func _bake_gash(p0: Vector2, p1: Vector2, base_w: float, seed_v: int) -> Dictionary:
	var delta: Vector2 = p1 - p0
	var ln: float = delta.length()
	if ln < 1.0:
		ln = 1.0
	var nrm := Vector2(-delta.y, delta.x) / ln
	var bow: float = (1.0 if seed_v % 2 == 0 else -1.0) * (4.0 + float(seed_v % 3))
	var ctrl: Vector2 = (p0 + p1) * 0.5 + nrm * bow
	var n: int = 40
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	var top := PackedVector2Array()
	var bot := PackedVector2Array()
	var mid := PackedVector2Array()
	var body_cols := PackedColorArray()
	var hi_cols := PackedColorArray()
	for i in n + 1:
		var u: float = float(i) / float(n)
		var iu: float = 1.0 - u
		var bpt: Vector2 = p0 * (iu * iu) + ctrl * (2.0 * iu * u) + p1 * (u * u)
		mid.push_back(bpt)
		var taper: float = pow(sin(u * PI), 0.7)
		var w_top: float = base_w * taper * (0.55 + rng.randf() * 0.9) + (rng.randf() - 0.5) * 1.2
		var w_bot: float = base_w * taper * (0.55 + rng.randf() * 0.9) + (rng.randf() - 0.5) * 1.2
		top.push_back(bpt + nrm * w_top)
		bot.push_back(bpt - nrm * w_bot)
		# 본체 색 그라데이션 (HTML 매핑): u<0.06 fade, 0.06~0.18 bright red, 0.18~0.4 blood, 0.4~0.7 deep, 0.7~0.95 near black, >0.95 fade
		body_cols.push_back(_gash_body_color(u))
		hi_cols.push_back(_gash_hi_color(u))
	# spatter 14개 작은 점
	var spatter: Array = []
	for _i in 14:
		var idx: int = int(rng.randf() * float(mid.size()))
		var off: float = (rng.randf() - 0.5) * base_w * 4.5
		var p_mid: Vector2 = mid[idx]
		var sp_pos: Vector2 = p_mid + nrm * off + Vector2(0.0, rng.randf() * 2.0)
		var sp_r: float = 0.6 + rng.randf() * 1.4
		var sp_col := Color(
			(168.0 + floor(rng.randf() * 40.0)) / 255.0,
			(16.0 + floor(rng.randf() * 30.0)) / 255.0,
			(26.0 + floor(rng.randf() * 20.0)) / 255.0,
			0.5 + rng.randf() * 0.4)
		spatter.append({"pos": sp_pos, "r": sp_r, "col": sp_col})
	# drip 1~2개 wavy line + bead
	var drips: Array = []
	var n_drips: int = 1 + int(rng.randf() * 2.0)
	for _d in n_drips:
		var didx: int = 8 + int(rng.randf() * float(mid.size() - 16))
		var origin: Vector2 = mid[didx]
		var drip_len: float = 10.0 + rng.randf() * 18.0
		var jitter: float = (rng.randf() - 0.5) * 2.0
		var drip_pts := PackedVector2Array()
		drip_pts.push_back(origin)
		var steps: int = 6
		for s in range(1, steps + 1):
			var t: float = float(s) / float(steps)
			drip_pts.push_back(Vector2(origin.x + jitter * t + sin(t * 5.0) * 1.2, origin.y + drip_len * t))
		drips.append({"pts": drip_pts, "bead_pos": drip_pts[drip_pts.size() - 1], "bead_r": 1.6 + rng.randf()})
	return {
		"top": top, "bot": bot, "mid": mid,
		"body_cols": body_cols, "hi_cols": hi_cols,
		"spatter": spatter, "drips": drips,
		"nrm": nrm
	}

# HTML body 그라데이션 stops 매핑
func _gash_body_color(u: float) -> Color:
	if u < 0.06:
		return Color(0.47, 0.118, 0.118, lerpf(0.0, 0.5, u / 0.06))
	elif u < 0.18:
		var t: float = (u - 0.06) / 0.12
		return Color(lerpf(0.47, 0.902, t), lerpf(0.118, 0.227, t), lerpf(0.118, 0.227, t), lerpf(0.5, 0.95, t))
	elif u < 0.4:
		var t: float = (u - 0.18) / 0.22
		return Color(lerpf(0.902, 0.659, t), lerpf(0.227, 0.063, t), lerpf(0.227, 0.102, t), 1.0)
	elif u < 0.7:
		var t: float = (u - 0.4) / 0.3
		return Color(lerpf(0.659, 0.227, t), lerpf(0.063, 0.024, t), lerpf(0.102, 0.031, t), 1.0)
	elif u < 0.95:
		var t: float = (u - 0.7) / 0.25
		return Color(lerpf(0.227, 0.039, t), lerpf(0.024, 0.008, t), lerpf(0.031, 0.016, t), lerpf(1.0, 0.85, t))
	else:
		return Color(0.039, 0.008, 0.016, lerpf(0.85, 0.0, (u - 0.95) / 0.05))

# HTML highlight 그라데이션 (위 edge 살색 페이드)
func _gash_hi_color(u: float) -> Color:
	if u < 0.2:
		return Color(1.0, 0.78, 0.71, lerpf(0.0, 0.5, u / 0.2))
	elif u < 0.5:
		var t: float = (u - 0.2) / 0.3
		return Color(1.0, lerpf(0.78, 0.86, t), lerpf(0.71, 0.78, t), lerpf(0.5, 0.7, t))
	elif u < 0.85:
		var t: float = (u - 0.5) / 0.35
		return Color(1.0, lerpf(0.86, 0.71, t), lerpf(0.78, 0.62, t), lerpf(0.7, 0.3, t))
	else:
		return Color(1.0, lerpf(0.71, 0.55, (u - 0.85) / 0.15), lerpf(0.62, 0.47, (u - 0.85) / 0.15), lerpf(0.3, 0.0, (u - 0.85) / 0.15))

func _draw_gashes() -> void:
	# 페이드인 제거 — 즉시 alpha 1.0. fade-out 만 유지 (82% 시점부터).
	var t: float = _gash_age / GASH_TIME
	var alpha_envelope: float
	if t < 0.82:
		alpha_envelope = 1.0
	else:
		alpha_envelope = (1.0 - t) / 0.18
	for g in _gash_data:
		var top: PackedVector2Array = g["top"]
		var bot: PackedVector2Array = g["bot"]
		var mid: PackedVector2Array = g["mid"]
		var body_cols: PackedColorArray = g["body_cols"]
		var _hi_cols: PackedColorArray = g["hi_cols"]
		var spatter: Array = g["spatter"]
		var drips: Array = g["drips"]
		# 1. 본체 — vertex color 폴리곤 (양 끝 fade, 가운데 진한 빨강)
		# Godot draw_polygon 의 colors 는 vertex 별. top + bot 역순으로 두 배 vertex.
		var poly := PackedVector2Array()
		var poly_cols := PackedColorArray()
		for i in top.size():
			poly.push_back(top[i])
			var c: Color = body_cols[i]
			poly_cols.push_back(Color(c.r, c.g, c.b, c.a * alpha_envelope))
		for i in range(bot.size() - 1, -1, -1):
			poly.push_back(bot[i])
			var c2: Color = body_cols[i]
			poly_cols.push_back(Color(c2.r, c2.g, c2.b, c2.a * alpha_envelope))
		draw_polygon(poly, poly_cols)
		# 2. 어두운 중심 line (단색)
		if mid.size() >= 2:
			draw_polyline(mid, Color(0.031, 0.008, 0.016, 0.9 * alpha_envelope), 1.5)
		# 3. 위 edge 하이라이트 (vertex color polyline 안 됨 → 단색 평균 사용)
		if top.size() >= 2:
			draw_polyline(top, Color(1.0, 0.86, 0.78, 0.55 * alpha_envelope), 1.0)
		# 4. spatter 14개 점
		for sp in spatter:
			var sc: Color = sp["col"]
			draw_circle(sp["pos"], sp["r"], Color(sc.r, sc.g, sc.b, sc.a * alpha_envelope))
		# 5. drip 1~2 개 (wavy line + bead)
		for d in drips:
			var dp: PackedVector2Array = d["pts"]
			if dp.size() >= 2:
				draw_polyline(dp, Color(COL_BLOOD.r, COL_BLOOD.g, COL_BLOOD.b, 0.85 * alpha_envelope), 1.4)
			draw_circle(d["bead_pos"], float(d["bead_r"]), Color(0.722, 0.082, 0.133, 0.95 * alpha_envelope))
