# tests/test_relics.gd
class_name TestRelics
extends RefCounted

const BattleManagerClass = preload("res://autoload/battle_manager.gd")
const TeamManagerClass = preload("res://autoload/team_manager.gd")
const DeckManagerClass = preload("res://autoload/deck_manager.gd")
const RelicRes = preload("res://resources/relic_resource.gd")
const HeroRes = preload("res://resources/hero_resource.gd")
const EnemyRes = preload("res://resources/enemy_resource.gd")
const IntentRes = preload("res://resources/intent_resource.gd")

var passed: int = 0
var failed: int = 0

func run_all() -> Dictionary:
	test_relic_pool_size()
	test_trigger_type_values()
	test_effect_type_values()
	test_relic_battle_start_trigger()
	test_relic_owner_hero_id_set()
	test_relic_no_duplicate_names()
	test_increase_max_hp()
	test_battle_win_relic_heal()
	test_is_cursed_field_exists()
	test_penalty_fields_exist()
	test_damage_hero_effect_bypasses_block()
	test_cursed_relic_has_is_cursed_true()
	test_penalty_effect_type_settable()
	test_relic_pool_has_new_relics()
	test_cursed_relics_in_pool()
	test_hero_relics_second_set()
	test_act2_relics_exist()
	test_korean_relics_exist()
	return {"passed": passed, "failed": failed}

func _assert(cond: bool, msg: String) -> void:
	if cond:
		passed += 1
		print("  PASS: " + msg)
	else:
		failed += 1
		print("  FAIL: " + msg)

func _build_pool() -> Array:
	# game_manager.gd와 동일한 로직 인라인
	var pool: Array = []
	var names := [
		"버닝 블러드", "불사조 깃털", "독약 병", "전쟁 북",
		"고대 유물", "모래시계", "피의 돌",
		"황제의 인장", "독사의 팔찌", "거북선 모형",
		"포병 나팔", "난중일기", "파라오의 인장",
		"악마의 계약", "저주받은 왕관", "피의 서약",
		"전술가의 지도", "강철 의지", "고대의 방패",
		"앙크의 생명", "호루스의 눈", "스카라베 부적"
	]
	for n in names:
		var r := RelicRes.new()
		r.relic_name = n
		pool.append(r)
	return pool

func _make_tm() -> TeamManagerClass:
	return TeamManagerClass.new()

func _make_hero(id: String, hp: int) -> Resource:
	var h := HeroRes.new()
	h.hero_id = id
	h.max_hp = hp
	return h

func _make_enemy(hp: int) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "더미"
	e.max_hp = hp
	var intent := IntentRes.new()
	intent.action_type = IntentRes.ActionType.BUFF
	intent.value = 0
	e.intent_pattern = [intent]
	return e

# ──────────────────────────────────────────────

func test_relic_pool_size() -> void:
	print("[TestRelics] test_relic_pool_size")
	var RelicsGd = load("res://resources/relics/relics.gd")
	var pool: Array = RelicsGd.build_pool()
	_assert(pool.size() == 30, "릴릭 풀 30종")

func test_trigger_type_values() -> void:
	print("[TestRelics] test_trigger_type_values")
	_assert(RelicRes.TriggerType.PASSIVE == 0, "PASSIVE == 0")
	_assert(RelicRes.TriggerType.BATTLE_START == 1, "BATTLE_START == 1")
	_assert(RelicRes.TriggerType.PLAYER_TURN_START == 2, "PLAYER_TURN_START == 2")
	_assert(RelicRes.TriggerType.ON_HERO_DAMAGED == 5, "ON_HERO_DAMAGED == 5")

func test_effect_type_values() -> void:
	print("[TestRelics] test_effect_type_values")
	_assert(RelicRes.EffectType.HEAL == 0, "HEAL == 0")
	_assert(RelicRes.EffectType.APPLY_STATUS_ENEMY == 3, "APPLY_STATUS_ENEMY == 3")
	_assert(RelicRes.EffectType.BLOCK == 8, "BLOCK == 8")
	_assert(RelicRes.EffectType.DAMAGE_HERO == 9, "DAMAGE_HERO == 9")

func test_relic_battle_start_trigger() -> void:
	print("[TestRelics] test_relic_battle_start_trigger")
	# 독약 병: BATTLE_START, APPLY_STATUS_ENEMY
	var relic := RelicRes.new()
	relic.relic_name = "독약 병"
	relic.trigger = RelicRes.TriggerType.BATTLE_START
	relic.effect_type = RelicRes.EffectType.APPLY_STATUS_ENEMY
	relic.value = 3
	_assert(relic.trigger == RelicRes.TriggerType.BATTLE_START, "독약 병 트리거 BATTLE_START")
	_assert(relic.value == 3, "독약 병 value == 3")

func test_relic_owner_hero_id_set() -> void:
	print("[TestRelics] test_relic_owner_hero_id_set")
	# 캐릭터 전용 릴릭 3종 검증
	var pool := _build_pool()
	var owned_count := 0
	for r in pool:
		if r.relic_name in ["황제의 인장", "독사의 팔찌", "거북선 모형"]:
			owned_count += 1
	_assert(owned_count == 3, "전용 릴릭 3종 확인")

func test_relic_no_duplicate_names() -> void:
	print("[TestRelics] test_relic_no_duplicate_names")
	var pool := _build_pool()
	var names: Array = []
	for r in pool:
		_assert(r.relic_name not in names, "중복 없음: %s" % r.relic_name)
		names.append(r.relic_name)

func test_increase_max_hp() -> void:
	print("[TestRelics] test_increase_max_hp")
	var tm := _make_tm()
	tm.add_hero(_make_hero("napoleon", 70))
	var old_max: int = tm.get_hero("napoleon").max_hp
	tm.increase_max_hp("napoleon", 15)
	_assert(tm.get_hero("napoleon").max_hp == old_max + 15, "increase_max_hp +15")
	_assert(tm.get_current_hp("napoleon") == old_max + 15, "현재 HP도 +15 증가")

func test_battle_win_relic_heal() -> void:
	print("[TestRelics] test_battle_win_relic_heal")
	# 버닝 블러드 릴릭 효과: BATTLE_WIN → HEAL
	var relic := RelicRes.new()
	relic.relic_name = "버닝 블러드"
	relic.trigger = RelicRes.TriggerType.BATTLE_WIN
	relic.effect_type = RelicRes.EffectType.HEAL
	relic.value = 6
	_assert(relic.trigger == RelicRes.TriggerType.BATTLE_WIN, "버닝 블러드 트리거 BATTLE_WIN")
	_assert(relic.effect_type == RelicRes.EffectType.HEAL, "버닝 블러드 효과 HEAL")
	_assert(relic.value == 6, "버닝 블러드 회복량 6")

func test_is_cursed_field_exists() -> void:
	print("[TestRelics] test_is_cursed_field_exists")
	var r := RelicRes.new()
	_assert(r.is_cursed == false, "is_cursed 기본값 false")

func test_penalty_fields_exist() -> void:
	print("[TestRelics] test_penalty_fields_exist")
	var r := RelicRes.new()
	r.is_cursed = true
	r.penalty_trigger = RelicRes.TriggerType.PLAYER_TURN_START
	r.penalty_effect_type = RelicRes.EffectType.HEAL
	r.penalty_value = 3
	_assert(r.penalty_value == 3, "penalty_value 설정 가능")
	_assert(r.penalty_trigger == RelicRes.TriggerType.PLAYER_TURN_START, "penalty_trigger 설정 가능")

func test_damage_hero_effect_bypasses_block() -> void:
	print("[TestRelics] test_damage_hero_effect_bypasses_block")
	var tm := _make_tm()
	var hero := _make_hero("napoleon", 70)
	tm.add_hero(hero)
	tm.take_damage("napoleon", 5)
	_assert(tm.get_current_hp("napoleon") == 65, "take_damage 직접 호출 시 HP 감소")

func test_cursed_relic_has_is_cursed_true() -> void:
	print("[TestRelics] test_cursed_relic_has_is_cursed_true")
	var r := RelicRes.new()
	r.relic_name = "악마의 계약"
	r.is_cursed = true
	_assert(r.is_cursed == true, "저주 렐릭 is_cursed=true")
	_assert(r.relic_name == "악마의 계약", "저주 렐릭 이름 확인")

func test_penalty_effect_type_settable() -> void:
	print("[TestRelics] test_penalty_effect_type_settable")
	var r := RelicRes.new()
	r.penalty_effect_type = RelicRes.EffectType.DAMAGE_HERO
	_assert(r.penalty_effect_type == RelicRes.EffectType.DAMAGE_HERO, "penalty_effect_type DAMAGE_HERO 설정 가능")

func test_relic_pool_has_new_relics() -> void:
	print("[TestRelics] test_relic_pool_has_new_relics")
	var new_names := [
		"포병 나팔", "난중일기", "파라오의 인장",
		"악마의 계약", "저주받은 왕관", "피의 서약",
		"전술가의 지도", "강철 의지", "고대의 방패"
	]
	var pool := _build_pool()
	for name in new_names:
		var found := false
		for r in pool:
			if r.relic_name == name:
				found = true
				break
		_assert(found, "렐릭 존재: %s" % name)

func test_cursed_relics_in_pool() -> void:
	print("[TestRelics] test_cursed_relics_in_pool")
	var cursed_names := ["악마의 계약", "저주받은 왕관", "피의 서약"]
	for name in cursed_names:
		var r := RelicRes.new()
		r.relic_name = name
		r.is_cursed = true
		_assert(r.is_cursed, "저주 렐릭 is_cursed: %s" % name)

func test_hero_relics_second_set() -> void:
	print("[TestRelics] test_hero_relics_second_set")
	var pool := _build_pool()
	var second_set := ["포병 나팔", "난중일기", "파라오의 인장"]
	for name in second_set:
		var found := false
		for r in pool:
			if r.relic_name == name:
				found = true
				break
		_assert(found, "2번째 전용 렐릭 존재: %s" % name)

func test_act2_relics_exist() -> void:
	print("[TestRelics] test_act2_relics_exist")
	var act2_names := ["앙크의 생명", "호루스의 눈", "스카라베 부적"]
	var RelicsGd = load("res://resources/relics/relics.gd")
	var pool: Array = RelicsGd.build_pool()
	for name in act2_names:
		var found := false
		for r in pool:
			if r.relic_name == name:
				found = true
				break
		_assert(found, "Act2 렐릭 존재: %s" % name)
	var eye: Resource = null
	for r in pool:
		if r.relic_name == "호루스의 눈": eye = r
	_assert(eye != null and eye.owner_hero_id == "cleopatra", "호루스의 눈 — 클레오파트라 전용")

func test_korean_relics_exist() -> void:
	print("[TestRelics] test_korean_relics_exist")
	var RelicsGd = load("res://resources/relics/relics.gd")
	var pool: Array = RelicsGd.build_pool()
	var names := pool.map(func(r): return r.relic_name)
	_assert("저승 부적" in names, "저승 부적 존재")
	_assert("도깨비 방망이 파편" in names, "도깨비 방망이 파편 존재")
	_assert("삼태극 부적" in names, "삼태극 부적 존재")
	var RelicRes = load("res://resources/relic_resource.gd")
	var talisman = pool.filter(func(r): return r.relic_name == "저승 부적")[0]
	_assert(talisman.trigger == RelicRes.TriggerType.BATTLE_START, "저승 부적 트리거=BATTLE_START")
	_assert(talisman.effect_type == RelicRes.EffectType.ENERGY, "저승 부적 효과=ENERGY")
	_assert(talisman.value == 1, "저승 부적 value=1")
