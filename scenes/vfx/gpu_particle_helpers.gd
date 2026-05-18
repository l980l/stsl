# scenes/vfx/gpu_particle_helpers.gd
# GPU 하이브리드 VFX 공통 헬퍼.
# 원본 CPU VFX (_particles Array + draw_circle per frame) 의 표준 파티클 (속도/감속/gravity/색 페이드) 부분만
# GPUParticles2D 로 대체. 폴리곤 effect (빛기둥/룬링/오라/충격파) 는 호출자가 CPU 그대로 유지.
class_name GpuParticleHelpers
extends Object

# ── 텍스처 캐시 (한 번 생성 후 재사용) ──
static var _circle_tex: Texture2D
static var _square_tex: Texture2D
static var _sparkle_tex: Texture2D
static var _feather_tex: Texture2D

# 100% 솔리드 원 + 가장자리 1px 안티앨리어싱.
# CPU draw_circle(pos, r, col) 과 거의 동일 — 가장자리 페이드 없음.
# 64×64, 솔리드 반경 31 → size_min/max 는 픽셀 반경 (helper / 32 매핑).
static func circle_tex() -> Texture2D:
	if _circle_tex == null:
		var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
		img.fill(Color.TRANSPARENT)
		for y in 64:
			for x in 64:
				var dx: float = float(x) - 31.5
				var dy: float = float(y) - 31.5
				var d: float = sqrt(dx * dx + dy * dy)
				if d <= 31.0:
					img.set_pixel(x, y, Color.WHITE)
				elif d <= 32.0:
					img.set_pixel(x, y, Color(1, 1, 1, 1.0 - (d - 31.0)))
		_circle_tex = ImageTexture.create_from_image(img)
	return _circle_tex

# 균일 사각형 64×64 (chunk/debris 회전용 — size 매핑 일관)
static func square_tex() -> Texture2D:
	if _square_tex == null:
		var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
		img.fill(Color.WHITE)
		_square_tex = ImageTexture.create_from_image(img)
	return _square_tex

# glow_circle_tex 폐기 — 원본 CPU 어디서도 그라데이션 텍스처 안 씀.
# 원본의 글로우 효과는 "큰 alpha 낮은 원 + 작은 alpha 높은 원" 두 번 draw_circle.
# 필요 시 호출자가 두 emitter (큰/작은) 동시 spawn 으로 표현.

# 별가루 (sparkle) — 코어 원 + 가로/세로 막대 십자 (반짝이). 원본 holy_buff mote 와 동일 모양.
# draw_circle(pos, pr) + draw_rect 가로/세로 (5pr × 0.6) 십자.
static func sparkle_tex() -> Texture2D:
	if _sparkle_tex == null:
		var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
		img.fill(Color.TRANSPARENT)
		# 코어 원 — 반경 12, 부드러운 페이드
		for y in 64:
			for x in 64:
				var dx: float = float(x) - 32.0
				var dy: float = float(y) - 32.0
				var d: float = sqrt(dx * dx + dy * dy)
				if d <= 12.0:
					var a: float = 1.0 - (d / 12.0) * 0.5  # 가장자리 0.5 페이드
					img.set_pixel(x, y, Color(1, 1, 1, a))
		# 가로 막대 — y=30~33 (두께 4), x 8~56 (길이 48), 알파 가장자리 페이드
		for x in range(4, 60):
			var t: float = 1.0 - abs(float(x) - 32.0) / 28.0
			t = clampf(t, 0.0, 1.0)
			for dy in range(-2, 3):
				var py: int = 32 + dy
				if py >= 0 and py < 64:
					var existing: Color = img.get_pixel(x, py)
					var new_a: float = maxf(existing.a, t * (1.0 - abs(float(dy)) / 2.5))
					img.set_pixel(x, py, Color(1, 1, 1, new_a))
		# 세로 막대 — x=30~33 (두께 4), y 8~56 (길이 48)
		for y in range(4, 60):
			var t: float = 1.0 - abs(float(y) - 32.0) / 28.0
			t = clampf(t, 0.0, 1.0)
			for dx in range(-2, 3):
				var px: int = 32 + dx
				if px >= 0 and px < 64:
					var existing: Color = img.get_pixel(px, y)
					var new_a: float = maxf(existing.a, t * (1.0 - abs(float(dx)) / 2.5))
					img.set_pixel(px, y, Color(1, 1, 1, new_a))
		_sparkle_tex = ImageTexture.create_from_image(img)
	return _sparkle_tex

# 깃털 — 길쭉한 타원 (가로:세로 = 14:30) + 가운데 음영 살짝. 원본 holy_buff feather 와 동일 형태.
# 회전은 GPUParticles2D 의 angle/angular_velocity 로 처리.
static func feather_tex() -> Texture2D:
	if _feather_tex == null:
		var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
		img.fill(Color.TRANSPARENT)
		# 외곽 타원 (가로 14, 세로 30)
		for y in 64:
			for x in 64:
				var dx: float = (float(x) - 32.0) / 14.0
				var dy: float = (float(y) - 32.0) / 30.0
				var d: float = dx * dx + dy * dy
				if d <= 1.0:
					var a: float = clampf(1.0 - d * d, 0.0, 1.0)  # 부드러운 가장자리
					img.set_pixel(x, y, Color(1, 1, 1, a * 0.9))
		# 내부 음영 — 작은 타원 (가로 5, 세로 16), y 약간 위
		for y in 64:
			for x in 64:
				var dx: float = (float(x) - 32.0) / 5.0
				var dy: float = (float(y) - 22.0) / 16.0
				var d: float = dx * dx + dy * dy
				if d <= 1.0:
					var existing: Color = img.get_pixel(x, y)
					if existing.a > 0.0:
						var new_a: float = minf(1.0, existing.a + (1.0 - d) * 0.3)
						img.set_pixel(x, y, Color(1, 1, 1, new_a))
		_feather_tex = ImageTexture.create_from_image(img)
	return _feather_tex

# 단색 alpha 페이드 ramp (life 0 → 1: alpha 1 → 0). mid_alpha 로 중간 알파 조절.
static func make_fade_ramp(color: Color, mid_alpha: float = 0.7) -> GradientTexture1D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	g.colors = PackedColorArray([
		Color(color.r, color.g, color.b, 1.0),
		Color(color.r, color.g, color.b, mid_alpha),
		Color(color.r, color.g, color.b, 0.0),
	])
	var t := GradientTexture1D.new()
	t.gradient = g
	t.width = 64
	return t

# 다색 ramp — life 0 → mid → 1 에 따라 색·알파 모두 변화 (원본 CPU 의 시간별 색 매핑용).
# 예: ember `rgba(255, 200, 90)` → `rgba(255, 80, 10, 0)`.
static func make_color_ramp(start_color: Color, mid_color: Color, end_color: Color,
		start_alpha: float = 1.0, mid_alpha: float = 0.85, end_alpha: float = 0.0) -> GradientTexture1D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	g.colors = PackedColorArray([
		Color(start_color.r, start_color.g, start_color.b, start_alpha),
		Color(mid_color.r, mid_color.g, mid_color.b, mid_alpha),
		Color(end_color.r, end_color.g, end_color.b, end_alpha),
	])
	var t := GradientTexture1D.new()
	t.gradient = g
	t.width = 64
	return t

# 통일 factory. opts dictionary 로 모든 속성 지정.
# 필수: count, lifetime, color
# 자주 사용: speed_min/max, gravity, size_min/max, spread, direction, additive
# 회전: angle_min/max (deg), angular_velocity_min/max (deg/s)
# emission_shape: "point" (default) / "sphere" (radius) / "box" (extents)
# damping: float (감속, 양수)
# scale_curve: Curve (시간에 따른 크기 변화. nil 이면 일정)
# explosiveness: 0.0 (지속 spawn) ~ 1.0 (전부 동시 burst, default)
# one_shot: bool (default true)
static func make_emitter(opts: Dictionary) -> GPUParticles2D:
	var ps := GPUParticles2D.new()
	ps.amount = maxi(1, int(opts.get("count", 10)))
	ps.lifetime = float(opts.get("lifetime", 1.0))
	ps.one_shot = bool(opts.get("one_shot", true))
	ps.explosiveness = float(opts.get("explosiveness", 1.0))
	ps.emitting = true
	ps.texture = opts.get("texture", circle_tex())
	ps.local_coords = false  # 부모(_target 따라가지 않음 — 발화 시점 좌표 고정)

	var mat := ParticleProcessMaterial.new()
	# emission shape
	var shape: String = opts.get("emission_shape", "point")
	match shape:
		"sphere":
			mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
			mat.emission_sphere_radius = float(opts.get("emission_radius", 1.0))
		"box":
			mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
			var ext: Vector2 = opts.get("emission_box", Vector2(20.0, 20.0))
			mat.emission_box_extents = Vector3(ext.x, ext.y, 1.0)
		_:
			mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_POINT
	# 방향·속도
	var dir2: Vector2 = opts.get("direction", Vector2.UP)
	mat.direction = Vector3(dir2.x, dir2.y, 0.0)
	mat.spread = float(opts.get("spread", 180.0))
	mat.initial_velocity_min = float(opts.get("speed_min", 30.0))
	mat.initial_velocity_max = float(opts.get("speed_max", 90.0))
	# gravity (y 양수 = 아래)
	mat.gravity = Vector3(0.0, float(opts.get("gravity", 0.0)), 0.0)
	# damping (선형 감속)
	if opts.has("damping"):
		mat.damping_min = float(opts["damping"])
		mat.damping_max = float(opts["damping"])
	# 크기 — 픽셀 반경으로 받고 GPU scale 로 변환. 기본 size_base 32 (circle_tex 64×64 솔리드 반경).
	# 다른 텍스처 사용 시 size_base 옵션으로 base 변경 가능 (예: sparkle 코어 반경 6 → size_base 6).
	var size_base: float = float(opts.get("size_base", 32.0))
	mat.scale_min = float(opts.get("size_min", 1.0)) / size_base
	mat.scale_max = float(opts.get("size_max", 2.0)) / size_base
	if opts.has("scale_curve"):
		var sc := CurveTexture.new()
		sc.curve = opts["scale_curve"]
		mat.scale_curve = sc
	# 색 + 페이드
	var col: Color = opts.get("color", Color.WHITE)
	mat.color = col
	# color_ramp 직접 주입 가능 — 원본 CPU 의 시간별 색 변화 재현용 (start/mid/end 색 다름)
	if opts.has("color_ramp"):
		mat.color_ramp = opts["color_ramp"]
	else:
		mat.color_ramp = make_fade_ramp(col, float(opts.get("mid_alpha", 0.7)))
	# 회전 (chunk)
	if opts.has("angle_min") and opts.has("angle_max"):
		mat.angle_min = float(opts["angle_min"])
		mat.angle_max = float(opts["angle_max"])
	if opts.has("angular_velocity_min") and opts.has("angular_velocity_max"):
		mat.angular_velocity_min = float(opts["angular_velocity_min"])
		mat.angular_velocity_max = float(opts["angular_velocity_max"])
	ps.process_material = mat

	# 가산 블렌드 (default true — ember/flame/mote)
	if bool(opts.get("additive", true)):
		var cm := CanvasItemMaterial.new()
		cm.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		ps.material = cm
	return ps

# ── 자주 쓰는 wrapper (시각적 일관성 보장) ──

# 흰금 mote (holy_buff, holy_strike, holy_arrow 등)
static func make_mote_emitter(color: Color, count: int, lifetime: float,
		speed_min: float, speed_max: float, additive: bool = true,
		size_min: float = 0.7, size_max: float = 1.4) -> GPUParticles2D:
	return make_emitter({
		"count": count, "lifetime": lifetime, "color": color,
		"speed_min": speed_min, "speed_max": speed_max,
		"size_min": size_min, "size_max": size_max,
		"additive": additive, "damping": 8.0,
	})

# 주황 ember (warrior_buff, sig_ragnarok, boss_death)
static func make_ember_emitter(color: Color, count: int, lifetime: float,
		speed_min: float, speed_max: float, gravity: float = 60.0,
		size_min: float = 0.6, size_max: float = 1.2) -> GPUParticles2D:
	return make_emitter({
		"count": count, "lifetime": lifetime, "color": color,
		"speed_min": speed_min, "speed_max": speed_max, "gravity": gravity,
		"size_min": size_min, "size_max": size_max, "damping": 6.0,
	})

# 회색 dust (warrior_buff, blunt)
static func make_dust_emitter(color: Color, count: int, lifetime: float,
		speed_min: float, speed_max: float,
		size_min: float = 1.0, size_max: float = 2.4) -> GPUParticles2D:
	return make_emitter({
		"count": count, "lifetime": lifetime, "color": color,
		"speed_min": speed_min, "speed_max": speed_max,
		"size_min": size_min, "size_max": size_max,
		"additive": false, "damping": 4.0, "mid_alpha": 0.4,
	})

# 갈색 chunk (회전 파편 — warrior_buff, boss_death)
# size_min/max 는 원본 draw_colored_polygon 의 한 변 픽셀 (size_base 64).
static func make_chunk_emitter(color: Color, count: int, lifetime: float,
		speed_min: float, speed_max: float, gravity: float = 220.0,
		size_min: float = 0.5, size_max: float = 1.2) -> GPUParticles2D:
	return make_emitter({
		"count": count, "lifetime": lifetime, "color": color,
		"speed_min": speed_min, "speed_max": speed_max, "gravity": gravity,
		"size_min": size_min, "size_max": size_max,
		"size_base": 64.0,  # square_tex 한 변 64px = size 픽셀 값 그대로
		"additive": false, "texture": square_tex(),
		"angle_min": -180.0, "angle_max": 180.0,
		"angular_velocity_min": -360.0, "angular_velocity_max": 360.0,
		"damping": 2.0,
	})
