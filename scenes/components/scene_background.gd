# scenes/components/scene_background.gd
# M7.5 v2 — SVG 오브젝트 컴포지션 + 환경 무작위.
# parallax 5 layer (sky/far/mid/near/fg) 에 신화별 SVG Sprite2D 무작위 배치.
# EnvSpec: time_of_day(dawn/day/dusk/night) × weather(clear/cloudy/overcast/rain/snow)
# 신화 호환성으로 안전한 조합만 선택.
class_name SceneBackground
extends Node2D

# _back (layer=-100): sky/far/mid/near — 캐릭터 뒤 (ParallaxBackground/CanvasLayer)
# fg(전경) 은 CanvasLayer 안에 두면 캐릭터와 y-sort 비교 불가 → 별도 spawn 안 하고
# specs 만 저장. battle_scene 이 받아서 자체 자식으로 add_child + y_sort 처리
var _back: ParallaxBackground = null
var front_specs: Array = []  # Array[Dictionary{path, pos, scale}]

const W := 1920.0
const H := 1080.0
const HORIZON_Y := 270.0  # 화면 상단 25%

# 신화별 베이스 팔레트 (Act 별 — v1 유지)
const PALETTES := {
	"greek": [
		{"sky": Color("#3a5a7a"), "horizon": Color("#c9a064"), "silhouette": Color("#1a2a3a"), "scenery": Color("#3a4a3a")},
		{"sky": Color("#5a7090"), "horizon": Color("#e0b070"), "silhouette": Color("#2a3a4a"), "scenery": Color("#4a5040")},
		{"sky": Color("#1a1024"), "horizon": Color("#6a3030"), "silhouette": Color("#080608"), "scenery": Color("#1a1018")},
	],
}

# 신화별 SVG 오브젝트 풀 + spawn 가중치 (1차 PR = greek 만)
const OBJECTS := {
	"greek": {
		"large":  ["temple_small"],
		"medium": ["statue_warrior", "altar"],
		"small":  ["cypress", "olive_tree"],
		"pillars":["column_doric"],
	},
}

# SVG viewBox 크기 (충돌 검사용)
const OBJECT_SIZE := {
	"temple_small":   Vector2(600, 460),
	"statue_warrior": Vector2(220, 580),
	"altar":          Vector2(240, 280),
	"cypress":        Vector2(160, 480),
	"olive_tree":     Vector2(280, 360),
	"column_doric":   Vector2(200, 600),
}

# Sprite 의 발 anchor 기준 박스 (centered → x ± w*sc/2, y - h*sc ~ y)
static func _sprite_rect(svg_id: String, anchor: Vector2, sc: float) -> Rect2:
	var sz: Vector2 = OBJECT_SIZE.get(svg_id, Vector2(120, 240)) * sc
	return Rect2(anchor.x - sz.x * 0.5, anchor.y - sz.y, sz.x, sz.y)

# anchor_y < rect 발 y 면 — sprite 가 캐릭터 뒤(z 작음) → 통과.
static func _overlaps_any(rect: Rect2, anchor_y: float, occupied: Array) -> bool:
	for r_v in occupied:
		var r: Rect2 = r_v
		if not rect.intersects(r):
			continue
		if anchor_y < r.end.y:
			continue
		return true
	return false

# 시각/날씨 호환성 (신화별)
# weather: clear/cloudy/overcast/rain/snow
# snow 호환: norse/buddhist Act3/japanese Act2-3/daoist Act3 (1차 = greek 은 snow X)
const WEATHER_COMPAT := {
	"greek":    ["clear", "cloudy", "overcast", "rain"],
	"norse":    ["clear", "cloudy", "overcast", "rain", "snow"],
	"egyptian": ["clear", "cloudy", "overcast", "rain"],
	"buddhist": ["clear", "cloudy", "overcast", "rain"],
	"daoist":   ["clear", "cloudy", "overcast", "rain"],
	"japanese": ["clear", "cloudy", "overcast", "rain"],
}
const TIMES := ["dawn", "day", "dusk", "night"]

# TimeOfDay 별 modulate (전체 배경에 적용)
const TIME_TINT := {
	"dawn":  Color(1.05, 0.92, 0.88, 1.0),  # warm pink
	"day":   Color(1.0, 1.0, 1.0, 1.0),     # 정상
	"dusk":  Color(1.10, 0.88, 0.72, 1.0),  # 주황
	"night": Color(0.55, 0.62, 0.85, 1.0),  # 푸른 어두움
}

# 마지막 setup 환경 — battle_scene 의 critters/weather 가 같은 env 공유
var current_env: Dictionary = {}

func setup(myth: String, variant: int = 1, seed_val: int = -1, occupied: Array = []) -> void:
	_setup_internal(myth, variant, seed_val, "", "", occupied)

# 디버그 — 시각/날씨 강제 (preview 씬용)
func force_env(myth: String, variant: int, seed_val: int, time_force: String, weather_force: String, occupied: Array = []) -> void:
	_setup_internal(myth, variant, seed_val, time_force, weather_force, occupied)

func _setup_internal(myth: String, variant: int, seed_val: int, time_force: String, weather_force: String, occupied: Array) -> void:
	for c in get_children():
		c.queue_free()
	front_specs.clear()
	_back = ParallaxBackground.new()
	_back.layer = -100
	add_child(_back)
	if not PALETTES.has(myth):
		myth = "greek"
	var v: int = clamp(variant, 1, 3) - 1
	var palette: Dictionary = PALETTES[myth][v]

	# 무작위 시드
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val if seed_val >= 0 else int(Time.get_ticks_msec()) + randi()

	# 환경 결정 (force 가 ""/random 아니면 우선)
	var time_of_day: String = time_force if (time_force != "" and time_force != "random") else TIMES[rng.randi() % TIMES.size()]
	var weather_pool: Array = WEATHER_COMPAT.get(myth, ["clear"])
	var weather: String
	if weather_force != "" and weather_force != "random":
		weather = weather_force if weather_force in weather_pool else weather_pool[0]
	else:
		weather = weather_pool[rng.randi() % weather_pool.size()]
	current_env = {"myth": myth, "variant": variant, "time_of_day": time_of_day, "weather": weather, "seed": rng.seed}

	# 1. 하늘 그라데이션 (TimeOfDay 보정 적용)
	var sky_top: Color = palette["sky"]
	var sky_bot: Color = palette["horizon"]
	if time_of_day == "night":
		sky_top = sky_top.darkened(0.55)
		sky_bot = sky_bot.darkened(0.45)
	elif time_of_day == "dusk":
		sky_bot = sky_bot.lerp(Color("#ff7838"), 0.35)
	elif time_of_day == "dawn":
		sky_bot = sky_bot.lerp(Color("#ffd0b8"), 0.30)
	_add_sky_layer(sky_top, sky_bot)

	# 1.5 천체 (시각/날씨 따라)
	_add_celestial(time_of_day, weather, palette, rng)

	# 1.7 구름 (날씨 따라 밀도)
	if weather != "clear":
		var density: int = {"cloudy": 5, "overcast": 10, "rain": 8, "snow": 7}.get(weather, 0)
		_add_clouds(palette["horizon"], density, time_of_day, rng)

	# 1.8 horizon glow (밤엔 약함)
	var glow_alpha: float = 0.5 if time_of_day != "night" else 0.18
	_add_horizon_glow(palette["horizon"], glow_alpha)

	# 2. 원경 산 실루엣 (도형 — _back 안, parallax 시차)
	_add_silhouette_layer(palette["silhouette"], 0.15, HORIZON_Y, 10, 95.0)

	# 3~5. 모든 SVG 오브젝트 — front_specs.
	# 엄격한 perspective — y 작음(멀리) → scale 작음 / y 큼(가까이) → scale 큼.
	# sc_lo/sc_hi 둘 다 y 비례 lerp. ±10% jitter 로 다양성.
	var pool: Dictionary = OBJECTS.get(myth, {})
	var occupied_local: Array = occupied.duplicate()
	if pool.has("large") and pool["large"].size() > 0:
		var large_id: String = pool["large"][rng.randi() % pool["large"].size()]
		var y_rand: float = rng.randf_range(HORIZON_Y + 10.0, 700.0)
		var t: float = (y_rand - HORIZON_Y) / 430.0
		var sc_base: float = lerp(0.18, 0.55, t)
		_try_place(large_id, myth, rng, sc_base * 0.9, sc_base * 1.1, occupied_local, y_rand)
	if pool.has("medium") and rng.randf() < 0.7:
		var med_id: String = pool["medium"][rng.randi() % pool["medium"].size()]
		var y_rand: float = rng.randf_range(HORIZON_Y + 50.0, 1000.0)
		var t: float = (y_rand - HORIZON_Y) / 730.0
		var sc_base: float = lerp(0.25, 0.85, t)
		_try_place(med_id, myth, rng, sc_base * 0.9, sc_base * 1.1, occupied_local, y_rand)
	if pool.has("pillars") and rng.randf() < 0.50:
		var pillar_id: String = pool["pillars"][0]
		var y_rand: float = rng.randf_range(500.0, 1050.0)
		var t: float = (y_rand - 500.0) / 550.0
		var sc_base: float = lerp(0.35, 0.95, t)
		_try_place(pillar_id, myth, rng, sc_base * 0.9, sc_base * 1.1, occupied_local, y_rand)
	if pool.has("small"):
		var fg_count: int = rng.randi_range(8, 14)
		for i in fg_count:
			var small_id: String = pool["small"][rng.randi() % pool["small"].size()]
			var y_rand: float = rng.randf_range(HORIZON_Y + 30.0, 1050.0)
			var t: float = (y_rand - HORIZON_Y) / 780.0
			var sc_base: float = lerp(0.18, 0.90, t)
			_try_place(small_id, myth, rng, sc_base * 0.9, sc_base * 1.1, occupied_local, y_rand)

	# 시각 modulate — _back 의 ParallaxLayer 자식 CanvasItem 에 일괄 적용
	current_env["tint"] = TIME_TINT.get(time_of_day, Color.WHITE)
	var tint: Color = current_env["tint"]
	for pl_node in _back.get_children():
		if pl_node is ParallaxLayer:
			for child in pl_node.get_children():
				if child is CanvasItem:
					child.modulate = tint

# 후보 위치 무작위 → 충돌 검사 → 안 겹치면 spec 추가, 겹치면 재시도.
# anchor_y 가 z_index 기준 (큰 값 = 앞). large 600 / medium 720 / fg 770 등 차등.
func _try_place(svg_id: String, myth: String, rng: RandomNumberGenerator, sc_lo: float, sc_hi: float, occupied_local: Array, anchor_y: float = 770.0) -> void:
	const MAX_TRIES := 30
	for _try in MAX_TRIES:
		var sc: float = rng.randf_range(sc_lo, sc_hi)
		# x 화면 전체 (-50~1970) — 충돌 검사가 anchor.y 비교로 캐릭터 가림 여부 결정
		var x: float = rng.randf_range(-50.0, 1970.0)
		var anchor := Vector2(x, anchor_y)
		var rect := _sprite_rect(svg_id, anchor, sc)
		if not _overlaps_any(rect, anchor.y, occupied_local):
			front_specs.append({
				"path": "res://assets/art/backgrounds/objects/%s/%s.svg" % [myth, svg_id],
				"pos": anchor, "scale": sc,
			})
			occupied_local.append(rect.grow(40.0))
			return

# 외부에서 sway 동기화 — _back 만 (fg 는 battle_scene 자체 자식, sway 영향 X)
func set_scroll_offset(o: Vector2) -> void:
	if _back:
		_back.scroll_offset = o

# ── 레이어 빌더 ──────────────────────────────────────────────────────

func _add_sky_layer(top: Color, bottom: Color) -> void:
	var pl := ParallaxLayer.new()
	pl.motion_scale = Vector2(0.05, 0.05)
	_back.add_child(pl)
	var grad := Gradient.new()
	grad.colors = PackedColorArray([top, bottom])
	grad.offsets = PackedFloat32Array([0.0, 1.0])
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.fill_to = Vector2(0, 1)
	tex.width = 64
	tex.height = int(H)
	var sky_tex := TextureRect.new()
	sky_tex.texture = tex
	sky_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sky_tex.stretch_mode = TextureRect.STRETCH_SCALE
	sky_tex.size = Vector2(W * 1.2, H)
	sky_tex.position = Vector2(-W * 0.1, 0)
	pl.add_child(sky_tex)

func _build_silhouette_colors(pts: PackedVector2Array, base: Color, y_base: float) -> PackedColorArray:
	var colors := PackedColorArray()
	var dark: Color = base.darkened(0.20)
	var light: Color = base.lightened(0.10)
	for p in pts:
		var t: float = clamp((p.y - (y_base - 200.0)) / 280.0, 0.0, 1.0)
		colors.append(dark.lerp(light, t))
	return colors

func _add_silhouette_layer(color: Color, motion: float, y_base: float, count: int, max_height: float) -> void:
	var pl := ParallaxLayer.new()
	pl.motion_scale = Vector2(motion, motion)
	_back.add_child(pl)
	var poly := Polygon2D.new()
	var pts := PackedVector2Array()
	pts.append(Vector2(-100, H))
	var seg_w := (W + 200.0) / float(count)
	for i in count + 1:
		var x: float = -100.0 + i * seg_w
		var y_offset: float = -randf_range(max_height * 0.4, max_height)
		pts.append(Vector2(x, y_base + y_offset))
	pts.append(Vector2(W + 100, H))
	poly.polygon = pts
	poly.vertex_colors = _build_silhouette_colors(pts, color, y_base)
	pl.add_child(poly)

# SVG 오브젝트 spawn (Sprite2D, _back ParallaxLayer 안). 캐릭터 뒤 레이어 전용.
func _add_svg_object(myth: String, obj_id: String, motion: float, pos_anchor: Vector2, scale_v: float) -> void:
	var path := "res://assets/art/backgrounds/objects/%s/%s.svg" % [myth, obj_id]
	if not ResourceLoader.exists(path):
		return
	var pl := ParallaxLayer.new()
	pl.motion_scale = Vector2(motion, motion)
	_back.add_child(pl)
	var spr := Sprite2D.new()
	spr.texture = load(path)
	spr.scale = Vector2(scale_v, scale_v)
	# pos_anchor 는 오브젝트의 바닥 중심 — Sprite2D centered 라 y 보정
	var tex_h: float = (spr.texture as Texture2D).get_height() * scale_v
	spr.position = Vector2(pos_anchor.x, pos_anchor.y - tex_h * 0.5)
	pl.add_child(spr)

# ── 천체 (시각/날씨 조건) ─────────────────────────────────────────────

func _add_celestial(time_of_day: String, weather: String, palette: Dictionary, rng: RandomNumberGenerator) -> void:
	if weather == "overcast":
		return  # 흐림이면 천체 안 보임
	var pl := ParallaxLayer.new()
	pl.motion_scale = Vector2(0.05, 0.05)
	_back.add_child(pl)
	if time_of_day == "night":
		_draw_stars(pl, 80, rng)
		_draw_moon(pl, Vector2(W * rng.randf_range(0.55, 0.85), 100 + rng.randf_range(0, 80)), 38.0)
	elif time_of_day == "day":
		_draw_sun(pl, Vector2(W * rng.randf_range(0.55, 0.85), 110 + rng.randf_range(0, 60)), 55.0, palette["horizon"])
	elif time_of_day == "dusk":
		_draw_sun(pl, Vector2(W * rng.randf_range(0.55, 0.80), 180 + rng.randf_range(0, 40)), 60.0, Color("#ff8838"))
	elif time_of_day == "dawn":
		_draw_sun(pl, Vector2(W * rng.randf_range(0.20, 0.45), 180 + rng.randf_range(0, 40)), 55.0, Color("#ffc890"))

func _draw_stars(parent: Node2D, count: int, rng: RandomNumberGenerator) -> void:
	for i in count:
		var dot := Polygon2D.new()
		dot.color = Color(1, 1, 0.95, rng.randf_range(0.4, 0.9))
		var x := rng.randf_range(0, W)
		var y := rng.randf_range(20, HORIZON_Y - 30)
		var r := rng.randf_range(1.2, 3.0)
		dot.polygon = PackedVector2Array([
			Vector2(x - r, y), Vector2(x, y - r), Vector2(x + r, y), Vector2(x, y + r),
		])
		parent.add_child(dot)

func _draw_moon(parent: Node2D, pos: Vector2, r: float) -> void:
	var halo := Polygon2D.new()
	halo.color = Color(0.95, 0.92, 0.85, 0.20)
	var hpts := PackedVector2Array()
	for i in 24:
		var a: float = TAU * float(i) / 24.0
		hpts.append(pos + Vector2(cos(a), sin(a)) * (r * 1.7))
	halo.polygon = hpts
	parent.add_child(halo)
	var moon := Polygon2D.new()
	moon.color = Color(0.95, 0.92, 0.85, 0.95)
	var pts := PackedVector2Array()
	for i in 24:
		var a: float = TAU * float(i) / 24.0
		pts.append(pos + Vector2(cos(a), sin(a)) * r)
	moon.polygon = pts
	parent.add_child(moon)

func _draw_sun(parent: Node2D, pos: Vector2, r: float, glow_color: Color) -> void:
	var halo := Polygon2D.new()
	halo.color = Color(glow_color.r, glow_color.g, glow_color.b, 0.30)
	var hpts := PackedVector2Array()
	for i in 32:
		var a: float = TAU * float(i) / 32.0
		hpts.append(pos + Vector2(cos(a), sin(a)) * (r * 2.4))
	halo.polygon = hpts
	parent.add_child(halo)
	var sun := Polygon2D.new()
	sun.color = Color(1.0, 0.95, 0.78, 0.95)
	var pts := PackedVector2Array()
	for i in 28:
		var a: float = TAU * float(i) / 28.0
		pts.append(pos + Vector2(cos(a), sin(a)) * r)
	sun.polygon = pts
	parent.add_child(sun)

func _add_clouds(horizon_color: Color, count: int, time_of_day: String, rng: RandomNumberGenerator) -> void:
	var pl := ParallaxLayer.new()
	pl.motion_scale = Vector2(0.10, 0.10)
	_back.add_child(pl)
	var alpha: float = 0.40 if time_of_day != "night" else 0.22
	var cloud_color := Color(horizon_color.r, horizon_color.g, horizon_color.b, alpha)
	for i in count:
		var cx := rng.randf_range(-100, W + 100)
		var cy := rng.randf_range(60, HORIZON_Y - 80)
		var rx := rng.randf_range(120, 220)
		var ry := rng.randf_range(18, 32)
		var cloud := Polygon2D.new()
		cloud.color = cloud_color
		var pts := PackedVector2Array()
		for k in 20:
			var a: float = TAU * float(k) / 20.0
			pts.append(Vector2(cx + cos(a) * rx, cy + sin(a) * ry))
		cloud.polygon = pts
		pl.add_child(cloud)

func _add_horizon_glow(color: Color, alpha: float) -> void:
	var pl := ParallaxLayer.new()
	pl.motion_scale = Vector2(0.08, 0.08)
	_back.add_child(pl)
	var grad := Gradient.new()
	grad.colors = PackedColorArray([
		Color(color.r, color.g, color.b, 0.0),
		Color(color.r, color.g, color.b, alpha),
		Color(color.r, color.g, color.b, 0.0),
	])
	grad.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.fill_to = Vector2(0, 1)
	tex.width = 64
	tex.height = 130
	var glow := TextureRect.new()
	glow.texture = tex
	glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glow.stretch_mode = TextureRect.STRETCH_SCALE
	glow.size = Vector2(W * 1.2, 130)
	glow.position = Vector2(-W * 0.1, HORIZON_Y - 65)
	pl.add_child(glow)
