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
static var _heart_tex: Texture2D
static var _bubble_tex: Texture2D
static var _drip_tex: Texture2D
static var _petal_tex: Texture2D
static var _halo_tex: Texture2D
static var _mote_halo_tex: Texture2D
static var _soul_tex: Texture2D

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

# mote 헤일로 — 코어 원 + 큰 헤일로 원 합성 (원본 _draw_glow_pass mote 와 동일).
# 원본: draw_circle(pos, pr, col) + draw_circle(pos, pr*1.8, col*0.5).
# 코어 반경 16 (alpha 1.0) + 헤일로 반경 28.8 (alpha 0.5). size_base=16 매핑 → size 1.4 → 코어 1.4px.
static func mote_halo_tex() -> Texture2D:
	if _mote_halo_tex == null:
		var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
		img.fill(Color.TRANSPARENT)
		for y in 64:
			for x in 64:
				var dx: float = float(x) - 31.5
				var dy: float = float(y) - 31.5
				var d: float = sqrt(dx * dx + dy * dy)
				if d <= 16.0:
					img.set_pixel(x, y, Color.WHITE)  # 코어 alpha 1.0
				elif d <= 17.0:
					img.set_pixel(x, y, Color(1, 1, 1, 0.5 + 0.5 * (17.0 - d)))  # 코어 AA
				elif d <= 28.8:
					img.set_pixel(x, y, Color(1, 1, 1, 0.5))  # 헤일로 alpha 0.5
				elif d <= 29.8:
					img.set_pixel(x, y, Color(1, 1, 1, 0.5 * (29.8 - d)))  # 헤일로 AA
		_mote_halo_tex = ImageTexture.create_from_image(img)
	return _mote_halo_tex

# 영혼 3원 합성 — 외곽 r*4 COL_SOUL alpha 0.2 + 중간 r*2 COL_SOUL_HOT alpha 0.32 + 코어 r*0.8 WHITE alpha 1.0.
# death_dissolve soul 매칭. size_base=7 (원본 r 매핑). 텍스처 외곽 반경 28 → scale × r/7 → 화면 r*4.
static func soul_tex() -> Texture2D:
	if _soul_tex == null:
		var col_outer := Color(0.549, 0.561, 0.596)   # COL_SOUL
		var col_mid := Color(0.784, 0.792, 0.820)     # COL_SOUL_HOT
		var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
		img.fill(Color.TRANSPARENT)
		for y in 64:
			for x in 64:
				var dx: float = float(x) - 31.5
				var dy: float = float(y) - 31.5
				var d: float = sqrt(dx * dx + dy * dy)
				if d <= 5.6:
					img.set_pixel(x, y, Color(1, 1, 1, 1.0))  # 코어 WHITE alpha 1.0
				elif d <= 14.0:
					img.set_pixel(x, y, Color(col_mid.r, col_mid.g, col_mid.b, 0.32))  # 중간 COL_SOUL_HOT
				elif d <= 28.0:
					img.set_pixel(x, y, Color(col_outer.r, col_outer.g, col_outer.b, 0.2))  # 외곽 COL_SOUL
				elif d <= 29.0:
					img.set_pixel(x, y, Color(col_outer.r, col_outer.g, col_outer.b, 0.2 * (29.0 - d)))  # AA
		_soul_tex = ImageTexture.create_from_image(img)
	return _soul_tex

# 직사각형 48×64 (1:1.33 비율, chunk/debris 회전 시각화용 — 정사각형이면 회전 안 보임)
static func square_tex() -> Texture2D:
	if _square_tex == null:
		var img := Image.create(48, 64, false, Image.FORMAT_RGBA8)
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
		# 코어 원 반경 4 (size_base=4) — solid + AA. size_min/max=픽셀반경 → scale = size/4.
		# size 1.5 → scale 0.375 → 코어 직경 8*0.375=3, 막대 양쪽 20*0.375=7.5 (원본 pr*2.5 매칭).
		for y in 64:
			for x in 64:
				var dx: float = float(x) - 31.5
				var dy: float = float(y) - 31.5
				var d: float = sqrt(dx * dx + dy * dy)
				if d <= 4.0:
					img.set_pixel(x, y, Color.WHITE)
				elif d <= 5.0:
					img.set_pixel(x, y, Color(1, 1, 1, 1.0 - (d - 4.0)))
		# 가로 막대 — y 30~33 (두께 4), x 12~52 (길이 40 = 양쪽 20)
		for x in range(12, 52):
			var t_len: float = clampf(1.0 - abs(float(x) - 32.0) / 20.0, 0.0, 1.0)
			for dy in range(-2, 2):
				var py: int = 32 + dy
				var t_thick: float = 1.0 - abs(float(dy) + 0.5) / 2.0
				var new_a: float = clampf(t_len * t_thick, 0.0, 1.0)
				var existing: Color = img.get_pixel(x, py)
				img.set_pixel(x, py, Color(1, 1, 1, maxf(existing.a, new_a)))
		# 세로 막대 — x 30~33 (두께 4), y 12~52 (길이 40)
		for y in range(12, 52):
			var t_len: float = clampf(1.0 - abs(float(y) - 32.0) / 20.0, 0.0, 1.0)
			for dx in range(-2, 2):
				var px: int = 32 + dx
				var t_thick: float = 1.0 - abs(float(dx) + 0.5) / 2.0
				var new_a: float = clampf(t_len * t_thick, 0.0, 1.0)
				var existing: Color = img.get_pixel(px, y)
				img.set_pixel(px, y, Color(1, 1, 1, maxf(existing.a, new_a)))
		_sparkle_tex = ImageTexture.create_from_image(img)
	return _sparkle_tex

# 비행 hearts halo — 2단 alpha (안쪽 0.5 + 바깥 0.3) 가산 글로우.
# 원본 draw_circle(r*0.7, alpha 0.5) + draw_circle(r*1.4, alpha 0.3) 매핑.
# 64×64, 안쪽 반경 16 (r*0.7 영역), 바깥 반경 32 (r*1.4). size_base ≈ 22.86 (32/1.4).
static func halo_tex() -> Texture2D:
	if _halo_tex == null:
		var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
		img.fill(Color.TRANSPARENT)
		var cx := 31.5
		var cy := 31.5
		for y in 64:
			for x in 64:
				var dx := float(x) - cx
				var dy := float(y) - cy
				var d := sqrt(dx * dx + dy * dy)
				if d <= 16.0:
					img.set_pixel(x, y, Color(1, 1, 1, 0.5))  # 안쪽 halo
				elif d <= 32.0:
					img.set_pixel(x, y, Color(1, 1, 1, 0.3))  # 바깥 halo
		_halo_tex = ImageTexture.create_from_image(img)
	return _halo_tex

# 꽃잎 — 가로:세로 0.55:1 타원 (infatuation petal). 흰색 (modulate 로 색).
# 64×64, 가로 반경 16.5, 세로 반경 30. size_base=30.
static func petal_tex() -> Texture2D:
	if _petal_tex == null:
		var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
		img.fill(Color.TRANSPARENT)
		for y in 64:
			for x in 64:
				var dx := (float(x) - 31.5) / 16.5
				var dy := (float(y) - 31.5) / 30.0
				var d := dx * dx + dy * dy
				if d <= 1.0:
					var a := clampf(1.0 - d * d, 0.0, 1.0)
					img.set_pixel(x, y, Color(1, 1, 1, a))
		_petal_tex = ImageTexture.create_from_image(img)
	return _petal_tex

# 독액 방울 — 본체 큰 원 + 작은 빛반사 원 (poison_splash drip).
# 텍스처 자체에 연한 녹색 미리. 64×64, 본체 반경 23 (size_base 23).
# 원본: draw_circle(r*0.85, COL_DRIP) + draw_circle(offset, r*0.3, COL_DRIP_HL).
static func drip_tex() -> Texture2D:
	if _drip_tex == null:
		var col_body := Color(0.549, 0.824, 0.196)  # 원본 COL_DRIP
		var col_hl := Color(0.863, 1.0, 0.627)       # 원본 COL_DRIP_HL
		var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
		img.fill(Color.TRANSPARENT)
		var cx := 31.5
		var cy := 31.5
		# 본체 — 반경 23 솔리드 (alpha 0.9)
		for y in 64:
			for x in 64:
				var dx := float(x) - cx
				var dy := float(y) - cy
				var d := sqrt(dx * dx + dy * dy)
				if d <= 22.0:
					img.set_pixel(x, y, Color(col_body.r, col_body.g, col_body.b, 0.9))
				elif d <= 23.0:
					img.set_pixel(x, y, Color(col_body.r, col_body.g, col_body.b, 0.9 * (23.0 - d)))
		# 빛반사 작은 원 — 좌상단 offset (-23*0.2, -23*0.4) = (-4.6, -9.2), 반경 6.9
		for y in 64:
			for x in 64:
				var dx := float(x) - (cx - 4.6)
				var dy := float(y) - (cy - 9.2)
				var d := sqrt(dx * dx + dy * dy)
				if d <= 6.5:
					img.set_pixel(x, y, Color(col_hl.r, col_hl.g, col_hl.b, 0.7))
				elif d <= 7.5:
					var existing: Color = img.get_pixel(x, y)
					img.set_pixel(x, y, Color(col_hl.r, col_hl.g, col_hl.b, maxf(existing.a, 0.7 * (7.5 - d))))
		_drip_tex = ImageTexture.create_from_image(img)
	return _drip_tex

# 거품 — 원본 poison_splash bubble 정확 매핑:
#  - 채움 (큰 원): COL_DRIP alpha 0.25 (약한 녹)
#  - 외곽 ring (1px arc): COL_DRIP_HL alpha 0.7 (연녹)
#  - 좌상단 흰 하이라이트 alpha 0.7
# 64×64, 외곽 반경 28 (size_base 28).
static func bubble_tex() -> Texture2D:
	if _bubble_tex == null:
		var col_fill := Color(0.549, 0.824, 0.196)  # COL_DRIP
		var col_ring := Color(0.863, 1.0, 0.627)     # COL_DRIP_HL (연녹)
		var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
		img.fill(Color.TRANSPARENT)
		var cx := 31.5
		var cy := 31.5
		for y in 64:
			for x in 64:
				var dx := float(x) - cx
				var dy := float(y) - cy
				var d := sqrt(dx * dx + dy * dy)
				# 외곽 ring — 반경 26~28 (두께 2, 원본 1px arc 매칭)
				if d >= 26.0 and d <= 28.0:
					img.set_pixel(x, y, Color(col_ring.r, col_ring.g, col_ring.b, 0.7))
				# 내부 약한 채움
				elif d < 26.0:
					img.set_pixel(x, y, Color(col_fill.r, col_fill.g, col_fill.b, 0.25))
		# 좌상단 흰 하이라이트 (offset -10, -10, 반경 5)
		for y in 64:
			for x in 64:
				var dx := float(x) - (cx - 10.0)
				var dy := float(y) - (cy - 10.0)
				var d := sqrt(dx * dx + dy * dy)
				if d <= 4.0:
					img.set_pixel(x, y, Color(1, 1, 1, 0.7))
				elif d <= 5.0:
					var existing: Color = img.get_pixel(x, y)
					img.set_pixel(x, y, Color(1, 1, 1, maxf(existing.a, 0.7 * (5.0 - d))))
		_bubble_tex = ImageTexture.create_from_image(img)
	return _bubble_tex

# 하트 — charm_kiss heart_unit() 의 32점 베지어 폴리곤 fill.
# 64×64, 중심 (31.5, 31.5). 텍스처 자체에 원본 색 미리 (modulate WHITE 사용).
# 내부 COL_MID 솔리드 + 외곽 2px COL_HOT 흰분홍 outline (원본 _draw 의 polyline 1.2px 매칭).
# size_base = 32 매핑 (size 8 → scale 0.25 → 16px 직경, 원본 1.125*size = 9px 와 비슷).
static func heart_tex() -> Texture2D:
	if _heart_tex == null:
		var pts := _heart_unit_pts()
		# charm_kiss 색 hardcode (helper 는 charm_kiss 안 import — modulate WHITE 사용 위해)
		var col_inner := Color(1.0, 0.604, 0.831)   # COL_MID
		var col_outline := Color(1.0, 0.949, 0.976) # COL_HOT
		var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
		img.fill(Color.TRANSPARENT)
		# 1차: 내부 모두 COL_MID
		var inside_mask: PackedByteArray = PackedByteArray()
		inside_mask.resize(64 * 64)
		for y in 64:
			for x in 64:
				var p := Vector2(float(x) - 31.5, float(y) - 31.5)
				if _point_in_polygon(p, pts):
					inside_mask[y * 64 + x] = 1
					img.set_pixel(x, y, col_inner)
		# 2차: 외곽 2px outline (안쪽인데 인접 ±2 픽셀 중 바깥 있으면 외곽)
		for y in 64:
			for x in 64:
				if inside_mask[y * 64 + x] == 0:
					continue
				var is_edge := false
				for dy in range(-2, 3):
					for dx in range(-2, 3):
						if dx == 0 and dy == 0:
							continue
						var nx := x + dx
						var ny := y + dy
						if nx < 0 or nx >= 64 or ny < 0 or ny >= 64:
							continue
						if inside_mask[ny * 64 + nx] == 0:
							is_edge = true
							break
					if is_edge:
						break
				if is_edge:
					img.set_pixel(x, y, col_outline)
		_heart_tex = ImageTexture.create_from_image(img)
	return _heart_tex

# charm_kiss.heart_unit() 와 동일 — 32점 베지어 (4 큐빅 × 8샘플)
static func _heart_unit_pts() -> PackedVector2Array:
	var ctrl := [
		Vector2(0, 12), Vector2(-14, 4), Vector2(-18, -6), Vector2(-12, -12),
		Vector2(-12, -12), Vector2(-6, -18), Vector2(0, -14), Vector2(0, -8),
		Vector2(0, -8), Vector2(0, -14), Vector2(6, -18), Vector2(12, -12),
		Vector2(12, -12), Vector2(18, -6), Vector2(14, 4), Vector2(0, 12),
	]
	var p := PackedVector2Array()
	for seg in range(4):
		var a: Vector2 = ctrl[seg * 4]
		var b: Vector2 = ctrl[seg * 4 + 1]
		var c: Vector2 = ctrl[seg * 4 + 2]
		var d: Vector2 = ctrl[seg * 4 + 3]
		for i in range(8):
			var t := float(i) / 8.0
			var u := 1.0 - t
			p.append(u * u * u * a + 3.0 * u * u * t * b + 3.0 * u * t * t * c + t * t * t * d)
	return p

# 폴리곤 안쪽 검사 (ray casting). pts 는 단위 중심 (0,0) 기준.
static func _point_in_polygon(p: Vector2, pts: PackedVector2Array) -> bool:
	var inside := false
	var n := pts.size()
	var j := n - 1
	for i in range(n):
		var pi: Vector2 = pts[i]
		var pj: Vector2 = pts[j]
		if ((pi.y > p.y) != (pj.y > p.y)):
			var x_intersect = (pj.x - pi.x) * (p.y - pi.y) / (pj.y - pi.y) + pi.x
			if p.x < x_intersect:
				inside = not inside
		j = i
	return inside

# 깃털 — 외곽 타원 (가로 14, 세로 30, COL_FEATHER) + 내부 음영 (가로 5, 세로 16, y=-10, COL_HOT).
# 원본 holy_buff feather 의 두 폴리곤 정확 매핑. 텍스처 자체에 색 미리 그림 — modulate Color.WHITE.
# 회전은 GPUParticles2D angle/angular_velocity (disable_z=true 필수).
static func feather_tex() -> Texture2D:
	if _feather_tex == null:
		var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
		img.fill(Color.TRANSPARENT)
		var col_outer := Color(1.0, 0.96, 0.86)   # COL_FEATHER (원본 0.9, 0.63 보다 더 흰색)
		var col_inner := Color(1.0, 0.99, 0.95)   # COL_HOT (거의 흰색)
		# 외곽 타원 — alpha 0.9 base
		for y in 64:
			for x in 64:
				var dx: float = (float(x) - 32.0) / 14.0
				var dy: float = (float(y) - 32.0) / 30.0
				var d: float = dx * dx + dy * dy
				if d <= 1.0:
					var a: float = clampf(1.0 - d * d, 0.0, 1.0) * 0.9
					img.set_pixel(x, y, Color(col_outer.r, col_outer.g, col_outer.b, a))
		# 내부 작은 타원 (위쪽 y=22) — COL_HOT, 외곽 alpha 와 곱해서 덮어쓰기
		for y in 64:
			for x in 64:
				var dx: float = (float(x) - 32.0) / 5.0
				var dy: float = (float(y) - 22.0) / 16.0
				var d: float = dx * dx + dy * dy
				if d <= 1.0:
					var existing: Color = img.get_pixel(x, y)
					if existing.a > 0.0:
						# 원본: draw_colored_polygon(inner, Color(COL_HOT, 0.7 * a)). a = outer alpha.
						var inner_a: float = existing.a * 0.7 + (1.0 - d) * 0.2
						inner_a = clampf(inner_a, existing.a, 1.0)
						img.set_pixel(x, y, Color(col_inner.r, col_inner.g, col_inner.b, inner_a))
		_feather_tex = ImageTexture.create_from_image(img)
	return _feather_tex

# 단색 alpha 페이드 ramp. start_alpha (life 0) / mid_alpha (life 0.5) / end_alpha (life 1).
# RGB 는 항상 WHITE — mat.color 와 곱셈으로 색 중복 회피 (color² 어두워짐 방지).
# color 인자는 시그니처 호환용으로 유지하되 무시.
static func make_fade_ramp(_color: Color = Color.WHITE, mid_alpha: float = 0.7,
		start_alpha: float = 1.0, end_alpha: float = 0.0) -> GradientTexture1D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	g.colors = PackedColorArray([
		Color(1, 1, 1, start_alpha),
		Color(1, 1, 1, mid_alpha),
		Color(1, 1, 1, end_alpha),
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
	# 2D 모드 명시 — z-축 disable. 안 하면 angular_velocity 가 3D 회전이라 2D 평면에서 안 보일 수 있음.
	mat.particle_flag_disable_z = true
	# 입자 죽는 시점 분산 — 동시 spawn + 동시 죽음 = "틱" 효과 방지.
	# 원본 CPU 의 max_life = base + randf()*0.5~0.7 패턴 매칭. default 0.4 → 60%~100% lifetime.
	mat.lifetime_randomness = float(opts.get("lifetime_randomness", 0.4))
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
	# color_ramp 직접 주입 시 mat.color = WHITE 강제 (ramp 가 색 담당).
	# 그렇지 않으면 mat.color × ramp.color 곱셈으로 색 어두워짐 (premultiplied 효과).
	if opts.has("color_ramp"):
		mat.color = Color.WHITE
		mat.color_ramp = opts["color_ramp"]
	else:
		mat.color_ramp = make_fade_ramp(col,
			float(opts.get("mid_alpha", 0.7)),
			float(opts.get("start_alpha", 1.0)),
			float(opts.get("end_alpha", 0.0)))
	# 회전 (chunk)
	if opts.has("angle_min") and opts.has("angle_max"):
		mat.angle_min = float(opts["angle_min"])
		mat.angle_max = float(opts["angle_max"])
	if opts.has("angular_velocity_min") and opts.has("angular_velocity_max"):
		mat.angular_velocity_min = float(opts["angular_velocity_min"])
		mat.angular_velocity_max = float(opts["angular_velocity_max"])
	# 중심 끌림 (음수) / 발산 (양수) — spiral 수렴, explosion radial 등
	if opts.has("radial_accel_min") and opts.has("radial_accel_max"):
		mat.radial_accel_min = float(opts["radial_accel_min"])
		mat.radial_accel_max = float(opts["radial_accel_max"])
	# 공전 (emission center 주위 회전, rad/s) — spiral 회전
	if opts.has("orbit_velocity_min") and opts.has("orbit_velocity_max"):
		mat.orbit_velocity_min = float(opts["orbit_velocity_min"])
		mat.orbit_velocity_max = float(opts["orbit_velocity_max"])
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
# texture_filter NEAREST — 작은 사각형 (3~10px) 도 회전 명확히 보이게 (LINEAR 면 흐릿).
static func make_chunk_emitter(color: Color, count: int, lifetime: float,
		speed_min: float, speed_max: float, gravity: float = 220.0,
		size_min: float = 0.5, size_max: float = 1.2) -> GPUParticles2D:
	var ps := make_emitter({
		"count": count, "lifetime": lifetime, "color": color,
		"speed_min": speed_min, "speed_max": speed_max, "gravity": gravity,
		"size_min": size_min, "size_max": size_max,
		"size_base": 48.0,  # square_tex 한 변 48 매핑
		"additive": false, "texture": square_tex(),
		"angle_min": -180.0, "angle_max": 180.0,
		"angular_velocity_min": -360.0, "angular_velocity_max": 360.0,
		"damping": 2.0,
	})
	ps.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return ps
