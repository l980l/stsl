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
	# 북유럽 — 차가운 푸른/회색 톤. Act 3 라그나뢰크(검은+핏빛).
	"norse": [
		{"sky": Color("#4a6080"), "horizon": Color("#a09070"), "silhouette": Color("#1a2030"), "scenery": Color("#2a3a30")},
		{"sky": Color("#3a4a60"), "horizon": Color("#705060"), "silhouette": Color("#150e1e"), "scenery": Color("#1a2028")},
		{"sky": Color("#1a0e10"), "horizon": Color("#7a2020"), "silhouette": Color("#080000"), "scenery": Color("#160808")},
	],
	# 이집트 — 사막 톤. Act 1 밝은 푸른+모래, Act 2 황혼 주황/금, Act 3 사후세계 어두운 보라.
	"egyptian": [
		{"sky": Color("#6890b0"), "horizon": Color("#d8b070"), "silhouette": Color("#4a3820"), "scenery": Color("#6a5028")},
		{"sky": Color("#b06840"), "horizon": Color("#f0a050"), "silhouette": Color("#5a2818"), "scenery": Color("#8a4828")},
		{"sky": Color("#2a1830"), "horizon": Color("#503040"), "silhouette": Color("#100808"), "scenery": Color("#281828")},
	],
	# 불교 — 짙은 녹+주황. Act 1 평화 산골, Act 2 노을 사찰, Act 3 어두운 명부.
	"buddhist": [
		{"sky": Color("#7090a0"), "horizon": Color("#c8a868"), "silhouette": Color("#2a3a28"), "scenery": Color("#3a5028")},
		{"sky": Color("#a06038"), "horizon": Color("#e09040"), "silhouette": Color("#3a1808"), "scenery": Color("#6a3818")},
		{"sky": Color("#180810"), "horizon": Color("#403018"), "silhouette": Color("#060000"), "scenery": Color("#180a10")},
	],
}

# 신화별 SVG 오브젝트 풀 + spawn 가중치
const OBJECTS := {
	"greek": {
		"large":  ["temple_small_a", "temple_small_b", "temple_small_d"],
		"medium": ["statue_warrior_a", "statue_warrior_b", "statue_warrior_d",
				   "altar_a", "altar_b", "altar_c", "altar_d"],
		"small":  ["cypress_a", "cypress_b", "cypress_c", "cypress_d",
				   "olive_tree_a", "olive_tree_b", "olive_tree_c", "olive_tree_d",
				   "grass_a", "grass_b",
				   "flower_a", "flower_b", "flower_c"],
		"pillars":["column_doric_a", "column_doric_b", "column_doric_c", "column_doric_d"],
	},
	"norse": {
		"large":  ["longhouse_a", "longhouse_b"],
		"medium": ["rune_stone_a", "rune_stone_b",
				   "altar_norse_a", "altar_norse_b"],
		"small":  ["birch_a", "birch_b", "birch_c", "birch_d",
				   "spruce_a", "spruce_b", "spruce_c", "spruce_d",
				   "tundra_grass_a", "tundra_grass_b",
				   "edelweiss_a", "edelweiss_b"],
		"pillars":["rune_pillar_a", "rune_pillar_b"],
	},
	"egyptian": {
		"large":  ["pyramid_small_a", "pyramid_small_b"],
		"medium": ["obelisk_a", "obelisk_b",
				   "altar_egyptian_a", "altar_egyptian_b"],
		"small":  ["palm_a", "palm_b", "palm_c", "palm_d",
				   "acacia_a", "acacia_b", "acacia_c", "acacia_d",
				   "desert_grass_a", "desert_grass_b",
				   "egypt_lotus_a", "egypt_lotus_b"],
		"pillars":["column_lotus_a", "column_lotus_b"],
	},
	"buddhist": {
		"large":  ["pagoda_a", "pagoda_b"],
		"medium": ["buddha_statue_a", "buddha_statue_b",
				   "altar_buddhist_a", "altar_buddhist_b"],
		"small":  ["bamboo_a", "bamboo_b", "bamboo_c", "bamboo_d",
				   "banyan_a", "banyan_b", "banyan_c", "banyan_d",
				   "bamboo_grass_a", "bamboo_grass_b",
				   "buddhist_lotus_a", "buddhist_lotus_b"],
		"pillars":["column_buddhist_a", "column_buddhist_b"],
	},
}

# SVG 콘텐츠 BBox 크기 (tools/trim_svg_viewbox.py 로 viewBox 정리 후 자동 측정).
# split 쌍 (trunk/leaves, base/flame) 은 같은 viewBox 공유.
const OBJECT_SIZE := {
	"altar_a":                  Vector2(200, 220),
	"altar_b":                  Vector2(172, 210),
	"altar_c":                  Vector2(204, 210),
	"altar_d":                  Vector2(184, 200),
	"altar_norse_a":            Vector2(180, 220),
	"altar_norse_b":            Vector2(160, 220),
	"birch_a":                  Vector2(136, 450),
	"birch_b":                  Vector2(116, 420),
	"birch_c":                  Vector2(148, 465),
	"birch_d":                  Vector2(139, 443),
	"column_doric_a":           Vector2(160, 546),
	"column_doric_b":           Vector2(160, 497),
	"column_doric_c":           Vector2(168, 554),
	"column_doric_d":           Vector2(180, 562),
	"cypress_a":                Vector2(104, 452),
	"cypress_b":                Vector2(80, 430),
	"cypress_c":                Vector2(116, 460),
	"cypress_d":                Vector2(110, 448),
	# flower / edelweiss — g transform="translate" 자식 ellipse 좌표 trim 부정확 → 원본 viewBox 유지
	"edelweiss_a":              Vector2(120, 140),
	"edelweiss_b":              Vector2(130, 130),
	"flower_a":                 Vector2(120, 140),
	"flower_b":                 Vector2(130, 130),
	"flower_c":                 Vector2(110, 110),
	"grass_a":                  Vector2(59, 76),
	"grass_b":                  Vector2(119, 98),
	"longhouse_a":              Vector2(540, 370),
	"longhouse_b":              Vector2(480, 290),
	"olive_tree_a":             Vector2(240, 300),
	"olive_tree_b":             Vector2(250, 281),
	"olive_tree_c":             Vector2(270, 302),
	"olive_tree_d":             Vector2(193, 322),
	"rune_pillar_a":            Vector2(110, 532),
	"rune_pillar_b":            Vector2(110, 517),
	"rune_stone_a":             Vector2(125, 539),
	"rune_stone_b":             Vector2(116, 418),
	"spruce_a":                 Vector2(170, 330),
	"spruce_b":                 Vector2(140, 310),
	"spruce_c":                 Vector2(190, 340),
	"spruce_d":                 Vector2(160, 320),
	"statue_warrior_a":         Vector2(180, 486),
	"statue_warrior_b":         Vector2(180, 530),
	"statue_warrior_d":         Vector2(180, 386),
	"temple_small_a":           Vector2(600, 430),
	"temple_small_b":           Vector2(560, 414),
	"temple_small_d":           Vector2(540, 420),
	"tundra_grass_a":           Vector2(59, 72),
	"tundra_grass_b":           Vector2(117, 96),
	# egyptian — trim_svg_viewbox.py 측정 결과 (g transform 사용 egypt_lotus 는 원본 유지).
	"pyramid_small_a":          Vector2(580, 418),
	"pyramid_small_b":          Vector2(560, 363),
	"obelisk_a":                Vector2(160, 547),
	"obelisk_b":                Vector2(156, 412),
	"altar_egyptian_a":         Vector2(200, 234),
	"altar_egyptian_b":         Vector2(184, 178),
	"palm_a":                   Vector2(150, 466),
	"palm_b":                   Vector2(160, 471),
	"palm_c":                   Vector2(160, 477),
	"palm_d":                   Vector2(144, 471),
	"acacia_a":                 Vector2(275, 325),
	"acacia_b":                 Vector2(240, 307),
	"acacia_c":                 Vector2(283, 325),
	"acacia_d":                 Vector2(196, 334),
	"column_lotus_a":           Vector2(160, 568),
	"column_lotus_b":           Vector2(156, 448),
	"desert_grass_a":           Vector2(72, 71),
	"desert_grass_b":           Vector2(117, 98),
	"egypt_lotus_a":            Vector2(120, 140),
	"egypt_lotus_b":            Vector2(130, 130),
	# buddhist
	"pagoda_a":                 Vector2(306, 424),
	"pagoda_b":                 Vector2(408, 290),
	"buddha_statue_a":          Vector2(140, 389),
	"buddha_statue_b":          Vector2(140, 378),
	"altar_buddhist_a":         Vector2(200, 256),
	"altar_buddhist_b":         Vector2(170, 248),
	"bamboo_a":                 Vector2(100, 415),
	"bamboo_b":                 Vector2(88, 386),
	"bamboo_c":                 Vector2(138, 430),
	"bamboo_d":                 Vector2(92, 400),
	"banyan_a":                 Vector2(275, 311.5),
	"banyan_b":                 Vector2(240, 285),
	"banyan_c":                 Vector2(295, 334.5),
	"banyan_d":                 Vector2(193, 323),
	"column_buddhist_a":        Vector2(120, 512),
	"column_buddhist_b":        Vector2(156, 423),
	"bamboo_grass_a":           Vector2(72, 77),
	"bamboo_grass_b":           Vector2(117, 100),
	"buddhist_lotus_a":         Vector2(120, 140),
	"buddhist_lotus_b":         Vector2(130, 130),
}

# 바람/펄럭임 sway — 풀/꽃 (통째 sway) + split 식생/altar (위쪽만 sway).
# 신화 추가 시 풀/꽃 prefix 추가. 구조물 X (temple/statue/column).
const _WIND_SMALL_PREFIXES := [
	"grass", "flower",                # greek
	"tundra_grass", "edelweiss",      # norse
	"desert_grass", "egypt_lotus",    # egyptian
	"bamboo_grass", "buddhist_lotus", # buddhist
]

static func _wind_eligible(svg_id: String) -> bool:
	for prefix in _WIND_SMALL_PREFIXES:
		if svg_id.begins_with(prefix):
			return true
	return _split_suffixes(svg_id).size() > 0

# 정지/sway 두 sprite 로 spawn — base + sway 부분. 빈 배열이면 split 아님.
# 나무: trunk(정지) + leaves(sway). altar: base(정지) + flame(sway).
# 신화 추가 시 식생 prefix 만 늘리면 됨. altar 는 prefix "altar" 자동 매칭 (altar_norse 등).
static func _split_suffixes(svg_id: String) -> Array:
	# bamboo_grass 는 풀(통째) — split 제외. bamboo_a/b/c/d 식생만 split.
	if svg_id.begins_with("bamboo_") and not svg_id.begins_with("bamboo_grass"):
		return ["_trunk", "_leaves"]
	if (svg_id.begins_with("cypress") or svg_id.begins_with("olive_tree")
			or svg_id.begins_with("birch") or svg_id.begins_with("spruce")
			or svg_id.begins_with("palm") or svg_id.begins_with("acacia")
			or svg_id.begins_with("banyan")):
		return ["_trunk", "_leaves"]
	if svg_id.begins_with("altar"):
		return ["_base", "_flame"]
	return []

# Sprite 의 발 anchor 기준 박스 (centered → x ± w*sc/2, y - h*sc ~ y)
static func _sprite_rect(svg_id: String, anchor: Vector2, sc: float) -> Rect2:
	var sz: Vector2 = OBJECT_SIZE.get(svg_id, Vector2(120, 240)) * sc
	return Rect2(anchor.x - sz.x * 0.5, anchor.y - sz.y, sz.x, sz.y)

# 캐릭터 영역 회피 — anchor_y < rect 발 y 면 sprite 가 뒤(z 작음) → 통과.
static func _overlaps_any(rect: Rect2, anchor_y: float, occupied: Array) -> bool:
	for r_v in occupied:
		var r: Rect2 = r_v
		if not rect.intersects(r):
			continue
		if anchor_y < r.end.y:
			continue
		return true
	return false

# fg sprite 끼리 — 겹치는 면적 비율이 80% 이상이면 reject (한 쪽이 다른 쪽을 거의 가리는 경우).
# 부분 겹침(끝쪽/절반)은 OK.
static func _overlaps_fg(rect: Rect2, fg_rects: Array) -> bool:
	const MAX_OVERLAP_RATIO := 0.80
	var area_a: float = rect.size.x * rect.size.y
	if area_a <= 0.0:
		return false
	for r_v in fg_rects:
		var r: Rect2 = r_v
		var inter: Rect2 = rect.intersection(r)
		if inter.size.x <= 0 or inter.size.y <= 0:
			continue
		var inter_area: float = inter.size.x * inter.size.y
		var area_b: float = r.size.x * r.size.y
		# 큰 쪽이 작은 쪽을 가리는 비율 vs 작은 쪽이 큰 쪽에 가린 비율 — 큰 쪽 사용
		var ratio: float = max(inter_area / area_a, inter_area / max(area_b, 1.0))
		if ratio >= MAX_OVERLAP_RATIO:
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

	# 2.5 땅 원근감 — 지평선~화면 하단 그라데이션 + 작은 디테일 점
	_add_ground_layer(palette, rng)

	# 3~5. 모든 SVG 오브젝트 — front_specs.
	# 엄격한 perspective — y 작음(멀리) → scale 작음 / y 큼(가까이) → scale 큼.
	# sc_lo/sc_hi 둘 다 y 비례 lerp. ±10% jitter 로 다양성.
	var pool: Dictionary = OBJECTS.get(myth, {})
	var occupied_local: Array = occupied.duplicate()
	var fg_local: Array = []  # 이번 setup 에서 배치된 fg sprite rect 누적
	if pool.has("large") and pool["large"].size() > 0:
		var large_id: String = pool["large"][rng.randi() % pool["large"].size()]
		var y_rand: float = rng.randf_range(HORIZON_Y + 10.0, 700.0)
		var t: float = (y_rand - HORIZON_Y) / 430.0
		var sc_base: float = lerp(0.18, 0.55, t)
		_try_place(large_id, myth, rng, sc_base * 0.9, sc_base * 1.1, occupied_local, y_rand, fg_local)
	if pool.has("medium") and rng.randf() < 0.7:
		var med_id: String = pool["medium"][rng.randi() % pool["medium"].size()]
		var y_rand: float = rng.randf_range(HORIZON_Y + 50.0, 1000.0)
		var t: float = (y_rand - HORIZON_Y) / 730.0
		var sc_base: float = lerp(0.25, 0.85, t)
		_try_place(med_id, myth, rng, sc_base * 0.9, sc_base * 1.1, occupied_local, y_rand, fg_local)
	if pool.has("pillars") and rng.randf() < 0.50:
		var pillar_id: String = pool["pillars"][rng.randi() % pool["pillars"].size()]
		var y_rand: float = rng.randf_range(500.0, 1050.0)
		var t: float = (y_rand - 500.0) / 550.0
		var sc_base: float = lerp(0.35, 0.95, t)
		_try_place(pillar_id, myth, rng, sc_base * 0.9, sc_base * 1.1, occupied_local, y_rand, fg_local)
	if pool.has("small"):
		var fg_count: int = rng.randi_range(8, 14)
		for i in fg_count:
			var small_id: String = pool["small"][rng.randi() % pool["small"].size()]
			var y_rand: float = rng.randf_range(HORIZON_Y + 30.0, 1050.0)
			var t: float = (y_rand - HORIZON_Y) / 780.0
			var sc_base: float = lerp(0.18, 0.90, t)
			_try_place(small_id, myth, rng, sc_base * 0.9, sc_base * 1.1, occupied_local, y_rand, fg_local)

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
func _try_place(svg_id: String, myth: String, rng: RandomNumberGenerator, sc_lo: float, sc_hi: float, occupied_local: Array, anchor_y: float = 770.0, fg_local: Array = []) -> void:
	const MAX_TRIES := 30
	for _try in MAX_TRIES:
		var sc: float = rng.randf_range(sc_lo, sc_hi)
		var x: float = rng.randf_range(-50.0, 1970.0)
		var anchor := Vector2(x, anchor_y)
		var rect := _sprite_rect(svg_id, anchor, sc)
		# 1) 캐릭터 회피: anchor_y < rect.end.y 면 통과 (z 작아 안 가림)
		if _overlaps_any(rect, anchor.y, occupied_local):
			continue
		# 2) fg 끼리 — 80% 이상 가림 reject (부분 겹침 OK)
		if _overlaps_fg(rect, fg_local):
			continue
		var spec: Dictionary = {
			"path": "res://assets/art/backgrounds/objects/%s/%s.svg" % [myth, svg_id],
			"pos": anchor, "scale": sc,
			"svg_id": svg_id,
		}
		# sway 메타 — shader (1-UV.y) 가중치로 위쪽만 흔들림.
		# grass/flower/altar(flame): 동일 amp/speed. cypress/olive_tree(leaves): 좀 더 느리고 작게.
		if _wind_eligible(svg_id):
			spec["wind"] = true
			var suffixes: Array = _split_suffixes(svg_id)
			var is_tree: bool = svg_id.begins_with("cypress") or svg_id.begins_with("olive_tree")
			spec["wind_phase"] = rng.randf_range(0.0, TAU)
			if is_tree:
				spec["wind_amp"] = rng.randf_range(4.0, 8.0)
				spec["wind_speed"] = rng.randf_range(0.7, 1.3)
			else:
				spec["wind_amp"] = rng.randf_range(5.0, 9.0)
				spec["wind_speed"] = rng.randf_range(0.8, 1.6)
			if suffixes.size() > 0:
				spec["split"] = true
				spec["split_suffixes"] = suffixes
		front_specs.append(spec)
		fg_local.append(rect)
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

# 땅 원근감 — 지평선 ~ 화면 하단 그라데이션 + 가까이 디테일 점들.
# silhouette(0.15) 보다 약간 빠른 0.30 motion 으로 ParallaxBackground 안에 추가.
# z 무관 — _back layer=-100 이라 캐릭터 뒤.
func _add_ground_layer(palette: Dictionary, rng: RandomNumberGenerator) -> void:
	var pl := ParallaxLayer.new()
	pl.motion_scale = Vector2(0.30, 0.30)
	_back.add_child(pl)
	# 그라데이션 — 4 stop. 지평선 부근 transparent → 안개 → 중경 → 진한 근경
	var horizon: Color = palette.get("horizon", Color("#c9a064"))
	var scenery: Color = palette.get("scenery", Color("#3a4a3a"))
	var fog: Color = Color(horizon.r * 0.5, horizon.g * 0.5, horizon.b * 0.5, 0.6)
	var grad := Gradient.new()
	grad.colors = PackedColorArray([
		Color(scenery.r, scenery.g, scenery.b, 0.0),
		fog,
		Color(scenery.r, scenery.g, scenery.b, 0.85),
		scenery.darkened(0.30),
	])
	grad.offsets = PackedFloat32Array([0.0, 0.15, 0.55, 1.0])
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.fill_to = Vector2(0, 1)
	tex.width = 64
	tex.height = int(H - HORIZON_Y)
	var ground := TextureRect.new()
	ground.texture = tex
	ground.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ground.stretch_mode = TextureRect.STRETCH_SCALE
	ground.size = Vector2(W * 1.2, H - HORIZON_Y)
	ground.position = Vector2(-W * 0.1, HORIZON_Y)
	pl.add_child(ground)
	# 디테일 — 가까이(y > 700) 작은 사각 점들 (풀잎/돌 흉내). 시드 기반 결정적
	var detail_color: Color = scenery.darkened(0.45)
	for _i in 60:
		var px: float = rng.randf_range(-60, W + 60)
		var py: float = rng.randf_range(700, H - 8)
		var pw: float = rng.randf_range(2.0, 5.0)
		var ph: float = rng.randf_range(1.5, 3.5)
		var dot := Polygon2D.new()
		dot.color = Color(detail_color.r, detail_color.g, detail_color.b, 0.45)
		dot.polygon = PackedVector2Array([
			Vector2(px, py), Vector2(px + pw, py),
			Vector2(px + pw, py + ph), Vector2(px, py + ph),
		])
		pl.add_child(dot)
