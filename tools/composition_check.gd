# tools/composition_check.gd
# 헤드리스 실행: godot --headless --script tools/composition_check.gd
# 카드 풀 구성 적정성 검토 — balance_check.gd 가 다루지 않는 영역 8 종.
extends SceneTree

const HERO_FILES := [
	["cleopatra",    "res://resources/cards/cards_cleopatra.gd"],
	["napoleon",     "res://resources/cards/cards_napoleon.gd"],
	["yi_sun_sin",   "res://resources/cards/cards_yi_sun_sin.gd"],
	["joan_of_arc",  "res://resources/cards/cards_joan_of_arc.gd"],
	["genghis_khan", "res://resources/cards/cards_genghis_khan.gd"],
	["musashi",      "res://resources/cards/cards_musashi.gd"],
]

# 임계치 — plan 의 검토 영역 8개 표 기준
const COST_AVG_MIN := 1.0
const COST_AVG_MAX := 1.5
const COST_ZERO_MAX := 3
const ATTACK_RATIO_MIN := 0.25
const ATTACK_RATIO_MAX := 0.60
const POWER_MIN := 3
const POWER_MAX := 10
const ARCHETYPE_JACCARD_WARN := 0.40
const EXHAUST_MAX := 8
const INNATE_MAX := 3
const STARTER_BASIC_TOTAL := 8  # strike+defend 합 기대
const STARTER_UNIQUE_COUNT := 2

# 공통 status (영웅 공통으로 쓸 만한 표준 디버프·버프). 영웅 1명만 쓰면 WARN.
# power.* / condition 키 (enemy_count_1, low_hp 등) 는 영웅 고유 메커니즘이므로 정상.
const COMMON_STATUS := ["poison", "weak", "vulnerable", "charm", "strength", "taunt", "morale", "block"]

# 카드 풀 (영웅별)
# { hero: { "starter": [CardResource...], "pool": [CardResource...] } }
var _decks: Dictionary = {}
# WARN / FAIL 카운트
var _summary: Dictionary = {}
# i18n 한글 매핑 (card.X.Y.archetype / card.X.Y.name / status.X.name 등 키 → ko)
var _ko: Dictionary = {}

func _initialize() -> void:
	_load_all_cards()
	_load_translations(["res://resources/translations/strings_card.csv", "res://resources/translations/strings_status.csv"])
	print("══════════════════════════════════════════════")
	print("  STSL Card Composition Check")
	print("══════════════════════════════════════════════\n")
	_check_cost_curve()
	_check_card_types()
	_check_effect_coverage()
	_check_damage_types()
	_check_status_types()
	_check_archetype_diff()
	_check_tags()
	_check_starter_deck()
	_print_summary()
	quit()

# ── 데이터 로드 ───────────────────────────────────────────────

func _load_all_cards() -> void:
	for entry in HERO_FILES:
		var hero: String = entry[0]
		var path: String = entry[1]
		var HeroCards: GDScript = load(path)
		if HeroCards == null:
			push_error("로드 실패: " + path)
			continue
		_decks[hero] = {
			"starter": HeroCards.starter_deck(),
			"pool": HeroCards.pool(),
		}

# csv 들에서 ko 컬럼을 읽어 _ko 딕셔너리에 누적.
# 헤드리스 환경에서 TranslationServer 로드가 불완전할 수 있어 csv 직접 읽음.
func _load_translations(paths: Array) -> void:
	for path in paths:
		var f := FileAccess.open(path, FileAccess.READ)
		if f == null:
			push_error("로드 실패: " + path)
			continue
		var header := f.get_csv_line()
		var ko_idx := -1
		for i in range(header.size()):
			if header[i] == "ko":
				ko_idx = i
				break
		if ko_idx < 0:
			continue
		while not f.eof_reached():
			var row := f.get_csv_line()
			if row.size() <= ko_idx:
				continue
			_ko[row[0]] = row[ko_idx]

# 키 → 한글 (없으면 fallback)
func _t(key: String, fallback: String = "") -> String:
	return _ko.get(key, fallback if fallback != "" else key)

# 영웅별 pool 카드 (검토 대부분 pool 기준 — starter 는 strike/defend 위주라 분포 왜곡)
func _pool(hero: String) -> Array:
	return _decks[hero]["pool"]

func _all_pool() -> Array:
	var out: Array = []
	for hero in _decks.keys():
		out.append_array(_pool(hero))
	return out

func _hero_names() -> Array:
	var out: Array = []
	for entry in HERO_FILES:
		out.append(entry[0])
	return out

# ── [1/8] Cost Curve ─────────────────────────────────────────

func _check_cost_curve() -> void:
	print("[1/8] Cost Curve (pool 기준, 영웅별 0/1/2/3+ 코스트 분포)")
	print("  %-14s %4s %4s %4s %4s   %s" % ["영웅", "0코", "1코", "2코", "3+", "평균"])
	var warn := 0
	var fail := 0
	for hero in _hero_names():
		var pool: Array = _pool(hero)
		var counts := [0, 0, 0, 0]
		var sum := 0
		for c in pool:
			var idx: int = clamp(c.cost, 0, 3)
			counts[idx] += 1
			sum += c.cost
		var avg: float = float(sum) / max(1, pool.size())
		var mark := ""
		if counts[0] > COST_ZERO_MAX:
			mark = " ⚠ 0코 %d 장 — 권장 ≤ %d" % [counts[0], COST_ZERO_MAX]
			warn += 1
		elif avg < COST_AVG_MIN or avg > COST_AVG_MAX:
			mark = " ⚠ 평균 코스트 %.2f — 권장 %.1f~%.1f" % [avg, COST_AVG_MIN, COST_AVG_MAX]
			warn += 1
		print("  %-14s %4d %4d %4d %4d   %.2f%s" % [hero, counts[0], counts[1], counts[2], counts[3], avg, mark])
	_summary["cost_curve"] = {"warn": warn, "fail": fail}
	print("")

# ── [2/8] Card Type ──────────────────────────────────────────

func _check_card_types() -> void:
	print("[2/8] Card Type 분포 (pool 기준 — ATTACK/SKILL/POWER)")
	print("  %-14s %6s %6s %6s   %s" % ["영웅", "ATTACK", "SKILL", "POWER", "ATTACK 비율"])
	var warn := 0
	var fail := 0
	for hero in _hero_names():
		var pool: Array = _pool(hero)
		var c := [0, 0, 0]
		for card in pool:
			c[card.card_type] += 1
		var total: int = pool.size()
		var atk_ratio: float = float(c[0]) / max(1, total)
		var mark := ""
		if atk_ratio < ATTACK_RATIO_MIN:
			mark = " ⚠ ATTACK 비율 %d%% — 데미지 부족" % int(atk_ratio * 100)
			warn += 1
		elif atk_ratio > ATTACK_RATIO_MAX:
			mark = " ⚠ ATTACK 비율 %d%% — 유틸 부족" % int(atk_ratio * 100)
			warn += 1
		if c[2] < POWER_MIN or c[2] > POWER_MAX:
			mark += " ⚠ POWER %d 장 — 권장 %d~%d" % [c[2], POWER_MIN, POWER_MAX]
			warn += 1
		print("  %-14s %6d %6d %6d   %d%%%s" % [hero, c[0], c[1], c[2], int(atk_ratio * 100), mark])
	_summary["card_type"] = {"warn": warn, "fail": fail}
	print("")

# ── [3/8] EffectType Coverage ────────────────────────────────

func _check_effect_coverage() -> void:
	print("[3/8] EffectType 커버리지 (enum 전체 중 어떤 카드도 안 쓰는 것)")
	var EffRes := preload("res://resources/effect_resource.gd")
	var enum_dict: Dictionary = EffRes.EffectType
	var used: Dictionary = {}
	for hero in _hero_names():
		for card in _pool(hero) + _decks[hero]["starter"]:
			for eff in card.effects:
				used[eff.effect_type] = true
	var unused: Array = []
	for name in enum_dict.keys():
		var val: int = enum_dict[name]
		if not used.has(val):
			unused.append(name)
	var total: int = enum_dict.size()
	var used_n: int = total - unused.size()
	print("  사용: %d / %d  |  미사용: %d 종" % [used_n, total, unused.size()])
	var fail := 0
	if unused.size() > 0:
		print("  ❌ 미사용 EffectType (정의됐으나 카드 0장):")
		for name in unused:
			print("     - %s" % name)
		fail = unused.size()
	_summary["effect_coverage"] = {"warn": 0, "fail": fail}
	print("")

# ── [4/8] damage_type ────────────────────────────────────────

func _check_damage_types() -> void:
	print("[4/8] damage_type 다양성 (DAMAGE 계열 effect.damage_type 분포, 영웅별 집합)")
	var warn := 0
	for hero in _hero_names():
		var types: Dictionary = {}
		for card in _pool(hero):
			for eff in card.effects:
				if eff.damage_type != "":
					types[eff.damage_type] = types.get(eff.damage_type, 0) + 1
		var keys: Array = types.keys()
		keys.sort()
		var pairs: Array = []
		for k in keys:
			pairs.append("%s×%d" % [k, types[k]])
		var mark := ""
		if keys.size() <= 1:
			mark = "  ⚠ 단일 damage_type — 다양성 부족"
			warn += 1
		print("  %-14s  %s%s" % [hero, ", ".join(pairs) if pairs.size() > 0 else "(없음)", mark])
	_summary["damage_type"] = {"warn": warn, "fail": 0}
	print("")

# ── [5/8] status_type ────────────────────────────────────────

func _check_status_types() -> void:
	print("[5/8] status_type 다양성 (APPLY_STATUS·POISON_BURST 등의 status_type 분포)")
	var hero_types: Dictionary = {}
	var global_count: Dictionary = {}
	for hero in _hero_names():
		var types: Dictionary = {}
		for card in _pool(hero):
			for eff in card.effects:
				if eff.status_type != "":
					types[eff.status_type] = types.get(eff.status_type, 0) + 1
					global_count[eff.status_type] = global_count.get(eff.status_type, 0) + 1
		hero_types[hero] = types
	for hero in _hero_names():
		var keys: Array = hero_types[hero].keys()
		keys.sort()
		var pairs: Array = []
		for k in keys:
			pairs.append("%s×%d" % [k, hero_types[hero][k]])
		print("  %-14s  %s" % [hero, ", ".join(pairs) if pairs.size() > 0 else "(없음)"])
	# global 사용 빈도 — 공통 status (poison/weak/vulnerable 등) 만 영웅 다양성 체크.
	# power.* / condition (low_hp/enemy_count_1 등) 은 영웅 고유 메커니즘이라 1 영웅 전용이 정상.
	print("  -- 공통 status 사용 빈도 (정해진 표준 디버프·버프) --")
	var common_keys: Array = []
	var other_keys: Array = []
	for k in global_count.keys():
		if COMMON_STATUS.has(k):
			common_keys.append(k)
		else:
			other_keys.append(k)
	common_keys.sort_custom(func(a, b): return global_count[a] > global_count[b])
	other_keys.sort_custom(func(a, b): return global_count[a] > global_count[b])
	var warn := 0
	for k in common_keys:
		var hero_use: int = 0
		for hero in _hero_names():
			if hero_types[hero].has(k):
				hero_use += 1
		var mark := ""
		if hero_use == 1:
			mark = "  ⚠ 공통 status 인데 1 영웅 전용 (다양성 부족)"
			warn += 1
		var label: String = _t("status.%s.name" % k, k)
		print("     %-12s (%-10s) ×%d  (사용 영웅 %d/6)%s" % [label, k, global_count[k], hero_use, mark])
	print("  -- 고유 power/condition (영웅 고유 메커니즘 — 정상) --")
	for k in other_keys:
		var hero_use: int = 0
		for hero in _hero_names():
			if hero_types[hero].has(k):
				hero_use += 1
		print("     %-36s ×%d  (사용 영웅 %d/6)" % [k, global_count[k], hero_use])
	_summary["status_type"] = {"warn": warn, "fail": 0}
	print("")

# ── [6/8] Archetype 차별성 (Jaccard) ─────────────────────────

func _check_archetype_diff() -> void:
	print("[6/8] Archetype 차별성 (영웅별 archetype 그룹의 effect_type set Jaccard 유사도)")
	print("  각 카드의 archetype 키는 한글 번역으로 그룹화 (예: '독살', '저주', '조종').")
	print("  유사도 = effect_type 집합의 Jaccard. > %.2f 면 메커니즘 중복으로 WARN.\n" % ARCHETYPE_JACCARD_WARN)
	var warn := 0
	for hero in _hero_names():
		# archetype 한글명 → set(effect_type), card_count
		var arche_sets: Dictionary = {}
		var arche_counts: Dictionary = {}
		for card in _pool(hero):
			# 다중 archetype: 카드가 여러 archetype 에 속하면 각각에 카운트·effect 집합 추가
			for arche_key in card.archetype:
				if arche_key == "":
					continue
				var arche: String = _t(arche_key, arche_key)
				if not arche_sets.has(arche):
					arche_sets[arche] = {}
					arche_counts[arche] = 0
				for eff in card.effects:
					arche_sets[arche][eff.effect_type] = true
				arche_counts[arche] += 1
		var keys: Array = arche_sets.keys()
		keys.sort()
		var summary: Array = []
		for k in keys:
			summary.append("%s(%d장)" % [k, arche_counts[k]])
		print("  %s — %s" % [hero, ", ".join(summary)])
		for i in range(keys.size()):
			for j in range(i + 1, keys.size()):
				var a: String = keys[i]
				var b: String = keys[j]
				var sa: Dictionary = arche_sets[a]
				var sb: Dictionary = arche_sets[b]
				var inter := 0
				for k in sa.keys():
					if sb.has(k):
						inter += 1
				var uni: int = sa.size() + sb.size() - inter
				var jac: float = float(inter) / max(1, uni)
				var mark := ""
				if jac > ARCHETYPE_JACCARD_WARN:
					mark = "  ⚠ effect 패턴 중복 높음"
					warn += 1
				print("    %s vs %s: %.2f%s" % [a, b, jac, mark])
		print("")
	_summary["archetype_diff"] = {"warn": warn, "fail": 0}

# ── [7/8] Tags ───────────────────────────────────────────────

func _check_tags() -> void:
	print("[7/8] 태그 분포 (pool 기준 — exhaust/ethereal/retain/innate)")
	print("  %-14s %8s %9s %7s %7s" % ["영웅", "exhaust", "ethereal", "retain", "innate"])
	var warn := 0
	for hero in _hero_names():
		var c := [0, 0, 0, 0]
		for card in _pool(hero):
			if card.is_exhaust: c[0] += 1
			if card.is_ethereal: c[1] += 1
			if card.is_retain: c[2] += 1
			if card.is_innate: c[3] += 1
		var mark := ""
		if c[0] > EXHAUST_MAX:
			mark = " ⚠ exhaust %d — 권장 ≤ %d (덱 회전 부족)" % [c[0], EXHAUST_MAX]
			warn += 1
		if c[3] > INNATE_MAX:
			mark += " ⚠ innate %d — 권장 ≤ %d (시작 핸드 강제)" % [c[3], INNATE_MAX]
			warn += 1
		print("  %-14s %8d %9d %7d %7d%s" % [hero, c[0], c[1], c[2], c[3], mark])
	_summary["tags"] = {"warn": warn, "fail": 0}
	print("")

# ── [8/8] Starter Deck ───────────────────────────────────────

func _check_starter_deck() -> void:
	print("[8/8] Starter Deck 구성 (각 영웅 starter_deck() 10장)")
	var warn := 0
	for hero in _hero_names():
		var starter: Array = _decks[hero]["starter"]
		var by_id: Dictionary = {}
		for card in starter:
			var id: String = card.card_name
			by_id[id] = by_id.get(id, 0) + 1
		# strike·defend 합
		var basic: int = 0
		var unique_extra: int = 0
		var parts: Array = []
		var keys: Array = by_id.keys()
		keys.sort()
		for id in keys:
			var n: int = by_id[id]
			parts.append("%s×%d" % [_t(id, _card_short(id)), n])
			if id.ends_with(".strike.name") or id.ends_with(".defend.name"):
				basic += n
			else:
				unique_extra += 1
		var mark := ""
		if basic != STARTER_BASIC_TOTAL:
			mark = " ⚠ strike+defend 합 %d (기대 %d)" % [basic, STARTER_BASIC_TOTAL]
			warn += 1
		if unique_extra != STARTER_UNIQUE_COUNT:
			mark += " ⚠ 고유 카드 %d (기대 %d)" % [unique_extra, STARTER_UNIQUE_COUNT]
			warn += 1
		print("  %-14s %d장: %s%s" % [hero, starter.size(), ", ".join(parts), mark])
	_summary["starter_deck"] = {"warn": warn, "fail": 0}
	print("")

func _card_short(card_name_key: String) -> String:
	# i18n 키 (예: card.cleopatra.poison_seed.name) → 마지막 두 번째 segment (poison_seed)
	if card_name_key.begins_with("card.") and card_name_key.ends_with(".name"):
		var parts: PackedStringArray = card_name_key.split(".")
		return parts[parts.size() - 2] if parts.size() >= 4 else card_name_key
	return card_name_key

# ── Summary ──────────────────────────────────────────────────

func _print_summary() -> void:
	print("══════════════════════════════════════════════")
	print("SUMMARY")
	var total_warn := 0
	var total_fail := 0
	var order := ["cost_curve", "card_type", "effect_coverage", "damage_type", "status_type", "archetype_diff", "tags", "starter_deck"]
	for k in order:
		var s: Dictionary = _summary.get(k, {"warn": 0, "fail": 0})
		var status: String
		if s["fail"] > 0:
			status = "%d FAIL" % s["fail"]
		elif s["warn"] > 0:
			status = "%d WARN" % s["warn"]
		else:
			status = "OK"
		print("  %-18s %s" % [k, status])
		total_warn += s["warn"]
		total_fail += s["fail"]
	print("")
	if total_fail == 0 and total_warn == 0:
		print("  ✅ 모든 영역 통과")
	else:
		print("  Outlier 총: %d FAIL / %d WARN — 별도 PR 에서 수정 결정" % [total_fail, total_warn])
	print("══════════════════════════════════════════════")
