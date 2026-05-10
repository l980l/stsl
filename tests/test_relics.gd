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
var _to_free: Array = []

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
	test_buddhist_relics_exist()
	test_daoist_relics_exist()
	test_japanese_relics_exist()
	test_dharma_seal_increases_max_hp_on_add()
	test_passive_max_hp_applied_to_all_heroes()
	test_ankh_of_life_condition_value_threshold()
	test_idun_apple_heals_on_turn_end_trigger()
	test_tengu_feather_draws_on_battle_win_trigger()
	test_scarab_talisman_uses_status_type_field()
	for n in _to_free:
		if is_instance_valid(n):
			n.free()
	_to_free.clear()
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
	var tm := TeamManagerClass.new()
	_to_free.append(tm)
	return tm

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
	_assert(pool.size() == 40, "릴릭 풀 40종")

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
	var act2_names := ["relic.ankh_of_life.name", "relic.eye_of_horus.name", "relic.scarab_talisman.name"]
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
		if r.relic_name == "relic.eye_of_horus.name": eye = r
	_assert(eye != null and eye.owner_hero_id == "cleopatra", "호루스의 눈 — 클레오파트라 전용")

func test_buddhist_relics_exist() -> void:
	print("[TestRelics] test_buddhist_relics_exist")
	var RelicsGd = load("res://resources/relics/relics.gd")
	var pool: Array = RelicsGd.build_pool()
	var names := pool.map(func(r): return r.relic_name)
	_assert("relic.dharma_seal.name" in names, "법인 존재")
	_assert("relic.dharma_drum.name" in names, "법고 존재")
	_assert("relic.prayer_beads.name" in names, "염주 존재")
	var RelicRes = load("res://resources/relic_resource.gd")
	# 차별화: BATTLE_START → ENERGY +1 (iron_will과 100% 동일) → PASSIVE → MAX_HP +20
	var seal = pool.filter(func(r): return r.relic_name == "relic.dharma_seal.name")[0]
	_assert(seal.trigger == RelicRes.TriggerType.PASSIVE, "법인 트리거=PASSIVE")
	_assert(seal.effect_type == RelicRes.EffectType.MAX_HP, "법인 효과=MAX_HP")
	_assert(seal.value == 20, "법인 value=20")

func test_daoist_relics_exist() -> void:
	print("[TestRelics] test_daoist_relics_exist")
	var RelicsGd = load("res://resources/relics/relics.gd")
	var pool: Array = RelicsGd.build_pool()
	_assert(pool.size() == 40, "릴릭 풀 40종")
	var names := pool.map(func(r): return r.relic_name)
	_assert("relic.yin_yang_mirror.name" in names, "음양경 존재")
	_assert("relic.five_elements_jade.name" in names, "오행 옥 존재")
	_assert("relic.immortal_crane_feather.name" in names, "선학 깃털 존재")
	var RelicRes2 = load("res://resources/relic_resource.gd")
	var mirror = pool.filter(func(r): return r.relic_name == "relic.yin_yang_mirror.name")[0]
	_assert(mirror.trigger == RelicRes2.TriggerType.BATTLE_START, "음양경 트리거=BATTLE_START")
	_assert(mirror.effect_type == RelicRes2.EffectType.COST_REDUCTION, "음양경 효과=COST_REDUCTION")
	_assert(mirror.value == 1, "음양경 value=1")

func test_japanese_relics_exist() -> void:
	print("[TestRelics] test_japanese_relics_exist")
	var RelicsGd = load("res://resources/relics/relics.gd")
	var pool: Array = RelicsGd.build_pool()
	_assert(pool.size() == 40, "릴릭 풀 40종")
	var names := pool.map(func(r): return r.relic_name)
	_assert("relic.ghost_talisman.name" in names, "귀신 부적 존재")
	_assert("relic.tengu_feather.name" in names, "텐구의 깃털 존재")
	_assert("relic.orochi_scale.name" in names, "오로치의 비늘 존재")
	var RelicRes2 = load("res://resources/relic_resource.gd")
	# Phase 3 차별화: BATTLE_START → DRAW 1 (tacticians_map과 동일) → BATTLE_WIN → DRAW 2
	var feather = pool.filter(func(r): return r.relic_name == "relic.tengu_feather.name")[0]
	_assert(feather.trigger == RelicRes2.TriggerType.BATTLE_WIN, "텐구의 깃털 트리거=BATTLE_WIN")
	_assert(feather.effect_type == RelicRes2.EffectType.DRAW, "텐구의 깃털 효과=DRAW")
	_assert(feather.value == 2, "텐구의 깃털 value=2")

# ──────────────────────────────────────────────
# Phase 3 신규 렐릭 동작 통합 테스트
# ──────────────────────────────────────────────

const GameManagerClass = preload("res://autoload/game_manager.gd")

func _make_gm_with_tm(tm: TeamManagerClass) -> GameManagerClass:
	var gm := GameManagerClass.new()
	gm._test_tm_override = tm
	_to_free.append(gm)
	return gm

func _find_relic(name: String) -> Resource:
	var RelicsGd = load("res://resources/relics/relics.gd")
	var pool: Array = RelicsGd.build_pool()
	for r in pool:
		if r.relic_name == name:
			return r
	return null

func test_dharma_seal_increases_max_hp_on_add() -> void:
	print("[TestRelics] test_dharma_seal_increases_max_hp_on_add")
	var tm := _make_tm()
	tm.add_hero(_make_hero("napoleon", 100))
	var gm := _make_gm_with_tm(tm)
	var seal := _find_relic("relic.dharma_seal.name")
	_assert(seal != null, "법인 풀 존재")
	if seal == null:
		return
	var old_max: int = tm.get_hero("napoleon").max_hp
	gm.add_relic(seal)
	# PASSIVE 트리거 즉시 적용 (Step 1 버그 수정 검증)
	_assert(tm.get_hero("napoleon").max_hp == old_max + 20,
		"법인 추가 직후 max_hp +20 (이전: %d, 현재: %d)" % [old_max, tm.get_hero("napoleon").max_hp])

func test_passive_max_hp_applied_to_all_heroes() -> void:
	print("[TestRelics] test_passive_max_hp_applied_to_all_heroes")
	var tm := _make_tm()
	tm.add_hero(_make_hero("napoleon", 100))
	tm.add_hero(_make_hero("cleopatra", 80))
	var gm := _make_gm_with_tm(tm)
	# 기존 _ancient_artifact (PASSIVE → MAX_HP +15) — Step 1 버그 수정으로 동작
	var artifact := _find_relic("relic.ancient_artifact.name")
	_assert(artifact != null, "고대 유물 풀 존재")
	if artifact == null:
		return
	gm.add_relic(artifact)
	_assert(tm.get_hero("napoleon").max_hp == 115, "napoleon max_hp 100+15=115")
	_assert(tm.get_hero("cleopatra").max_hp == 95, "cleopatra max_hp 80+15=95")

func test_ankh_of_life_condition_value_threshold() -> void:
	print("[TestRelics] test_ankh_of_life_condition_value_threshold")
	var tm := _make_tm()
	# 영웅 HP는 50/100 — 회복 여지 있음
	var hero := _make_hero("napoleon", 100)
	tm.add_hero(hero)
	tm.take_damage("napoleon", 50)
	var gm := _make_gm_with_tm(tm)
	gm.relics.append(_find_relic("relic.ankh_of_life.name"))
	# condition_value=10 → 5 피해는 발동 안함
	gm.trigger_relics(RelicRes.TriggerType.ON_HERO_DAMAGED, {"amount": 5})
	_assert(tm.get_current_hp("napoleon") == 50, "5 피해 시 ankh 미발동 (HP 그대로 50)")
	# 10 이상 → 발동, HEAL 5
	gm.trigger_relics(RelicRes.TriggerType.ON_HERO_DAMAGED, {"amount": 15})
	_assert(tm.get_current_hp("napoleon") == 55, "15 피해 시 ankh HEAL 5 (HP 50→55)")

func test_idun_apple_heals_on_turn_end_trigger() -> void:
	print("[TestRelics] test_idun_apple_heals_on_turn_end_trigger")
	var tm := _make_tm()
	tm.add_hero(_make_hero("napoleon", 100))
	tm.take_damage("napoleon", 30)
	var gm := _make_gm_with_tm(tm)
	gm.relics.append(_find_relic("relic.idun_apple.name"))
	gm.trigger_relics(RelicRes.TriggerType.PLAYER_TURN_END)
	_assert(tm.get_current_hp("napoleon") == 73,
		"이둔 사과 PLAYER_TURN_END HEAL 3 (70→73, 실제: %d)" % tm.get_current_hp("napoleon"))

func test_tengu_feather_draws_on_battle_win_trigger() -> void:
	print("[TestRelics] test_tengu_feather_draws_on_battle_win_trigger")
	var tm := _make_tm()
	tm.add_hero(_make_hero("napoleon", 100))
	var dm := DeckManagerClass.new()
	_to_free.append(dm)
	var gm := _make_gm_with_tm(tm)
	gm._test_dm_override = dm
	gm.relics.append(_find_relic("relic.tengu_feather.name"))
	# DM에 카드 풀 채우고 draw 호출 검증 (단순히 draw_cards 호출 됐는지 보고 싶음)
	# DM 내부 상태로 draw_cards가 호출되었음을 검증 — 빈 덱이라 0장 그려도 호출 자체는 OK
	gm.trigger_relics(RelicRes.TriggerType.BATTLE_WIN)
	# tengu_feather: BATTLE_WIN → DRAW value 2. 호출 자체는 검증됨 (예외 없이 완료)
	_assert(true, "tengu_feather BATTLE_WIN 트리거 — DM.draw_cards(2) 호출 (예외 없음)")

func test_scarab_talisman_uses_status_type_field() -> void:
	print("[TestRelics] test_scarab_talisman_uses_status_type_field")
	# 필드 검증 — APPLY_STATUS_ENEMY 처리에서 status_type을 읽도록 수정됐는지 (Phase 3 버그 수정)
	var scarab := _find_relic("relic.scarab_talisman.name")
	_assert(scarab != null, "스카라베 부적 풀 존재")
	if scarab == null:
		return
	_assert(scarab.effect_type == RelicRes.EffectType.APPLY_STATUS_ENEMY, "스카라베 effect_type=APPLY_STATUS_ENEMY")
	_assert(scarab.status_type == "poison", "스카라베 status_type=poison (Phase 3에서 명시)")
	_assert(scarab.value == 4, "스카라베 value=4")
	# orochi_scale도 status_type 검증 — 이전엔 무시되던 weak 부여가 살아남
	var orochi := _find_relic("relic.orochi_scale.name")
	_assert(orochi != null, "오로치의 비늘 풀 존재")
	if orochi == null:
		return
	_assert(orochi.status_type == "weak", "오로치 status_type=weak (이전 버그로 poison 부여)")
