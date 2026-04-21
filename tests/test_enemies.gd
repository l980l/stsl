# tests/test_enemies.gd
class_name TestEnemies
extends RefCounted

const GameManagerClass = preload("res://autoload/game_manager.gd")
const GreekNormals  = preload("res://resources/enemies/greek/greek_normals.gd")
const GreekAct1     = preload("res://resources/enemies/greek/greek_act1.gd")
const EgyptianNormals = preload("res://resources/enemies/egyptian/egyptian_normals.gd")
const EgyptianAct2    = preload("res://resources/enemies/egyptian/egyptian_act2.gd")
const IntentRes = preload("res://resources/intent_resource.gd")
const NorseNormals = preload("res://resources/enemies/norse/norse_normals.gd")
const NorseAct3    = preload("res://resources/enemies/norse/norse_act3.gd")

var passed: int = 0
var failed: int = 0

func run_all() -> Dictionary:
	test_normal_enemy_variety()
	test_harpy_pattern_length()
	test_cyclops_first_intent_is_buff()
	test_snake_pattern_length()
	test_discard_random()
	test_elite_enemy_hp()
	test_minotaur_pattern()
	test_medusa_pattern_and_status_type()
	test_scylla_pattern()
	test_hydra_phase_count()
	test_phase_transition()
	test_phase2_transition()
	test_act2_boss_name()
	test_act2_boss_phase_heal_ratios()
	test_act2_normal_sand_scout()
	test_act2_normal_desert_scorpion()
	test_act2_normal_mummy_warrior()
	test_act2_normal_sphinx_cub()
	test_act2_normal_sand_ifrit()
	test_act2_normal_ka_spirit()
	test_act2_elite_apep_snake()
	test_act2_elite_seth_hound()
	test_act2_elite_ba_bird()
	test_act2_osiris_structure()
	test_act2_osiris_phase_transition_heals()
	test_act2_gm_act_switch()
	test_greek_normals_encounters()
	test_egyptian_normals_encounters()
	test_normal_enemy_multi_encounter()
	test_norse_normals_shape()
	test_norse_encounters_shape()
	test_norse_act3_boss_name()
	test_norse_act3_elites()
	test_relic_pool_count()
	test_act3_event_pool_shape()
	test_greek_act2_shape()
	test_egyptian_act1_shape()
	test_norse_act1_shape()
	test_norse_act2_shape()
	test_greek_act3_shape()
	test_egyptian_act3_shape()
	test_mythology_randomization_structure()
	test_korean_normals_shape()
	test_korean_act1_shape()
	test_korean_act2_shape()
	return {"passed": passed, "failed": failed}

func _assert(cond: bool, msg: String) -> void:
	if cond:
		passed += 1
		print("  PASS: " + msg)
	else:
		failed += 1
		push_error("  FAIL: " + msg)

func _make_gm() -> GameManagerClass:
	var gm := GameManagerClass.new()
	gm.act_mythologies = ["greek", "egyptian"]
	gm.run_map = preload("res://autoload/map_generator.gd").generate()
	gm.available_node_ids = [0, 1, 2]
	gm.current_node_id = -1
	gm.pending_enemies = []
	gm.card_rewards = []
	return gm

func test_normal_enemy_variety() -> void:
	print("[TestEnemies] test_normal_enemy_variety")
	var gm := _make_gm()
	var seen := {}
	for _i in range(30):
		var enemies := gm._make_normal_enemies()
		seen[enemies[0].enemy_name] = true
	_assert(seen.size() >= 2, "랜덤 일반 적 — 30회 중 2종 이상 등장")

func test_harpy_pattern_length() -> void:
	print("[TestEnemies] test_harpy_pattern_length")
	var gm := _make_gm()
	var harpy: Resource = GreekNormals.harpy(_make_dummy_scene())
	_assert(harpy.intent_pattern.size() == 5, "하르피아 패턴 5개")
	_assert(harpy.enemy_name == "하르피아", "하르피아 이름")
	_assert(harpy.max_hp == 280, "하르피아 HP = 280")

func test_cyclops_first_intent_is_buff() -> void:
	print("[TestEnemies] test_cyclops_first_intent_is_buff")
	var gm := _make_gm()
	var cyclops: Resource = GreekNormals.cyclops(_make_dummy_scene())
	_assert(cyclops.intent_pattern.size() == 2, "사이클롭스 패턴 2개")
	_assert(cyclops.intent_pattern[0].action_type == IntentRes.ActionType.PREPARE,
		"사이클롭스 첫 행동 = PREPARE(준비)")
	_assert(cyclops.intent_pattern[1].value == 200, "사이클롭스 강타 = 200")

func test_snake_pattern_length() -> void:
	print("[TestEnemies] test_snake_pattern_length")
	var gm := _make_gm()
	var snake: Resource = GreekNormals.snake(_make_dummy_scene())
	_assert(snake.intent_pattern.size() == 2, "메두사의 뱀 패턴 2개")
	_assert(snake.enemy_name == "메두사의 뱀", "메두사의 뱀 이름")
	_assert(snake.intent_pattern[1].status_type == "vulnerable", "메두사의 뱀 DEBUFF = vulnerable")

func test_elite_enemy_hp() -> void:
	print("[TestEnemies] test_elite_enemy_hp")
	var gm := _make_gm()
	var enemies := gm._make_elite_enemies()
	_assert(enemies.size() >= 1, "엘리트 룸 적 1마리 이상")
	_assert(enemies[0].max_hp >= 1700, "엘리트 HP >= 1700")

func test_minotaur_pattern() -> void:
	print("[TestEnemies] test_minotaur_pattern")
	var gm := _make_gm()
	var m: Resource = GreekAct1.minotaur(_make_dummy_scene())
	_assert(m.intent_pattern.size() == 3, "미노타우로스 패턴 3개")
	_assert(m.intent_pattern[2].value == 260, "미노타우로스 세 번째 공격 260")

func test_medusa_pattern_and_status_type() -> void:
	print("[TestEnemies] test_medusa_pattern_and_status_type")
	var gm := _make_gm()
	var med: Resource = GreekAct1.medusa(_make_dummy_scene())
	_assert(med.intent_pattern.size() == 4, "메두사 패턴 4개")
	_assert(med.intent_pattern[1].status_type == "weak", "메두사 2번째 = weak")
	_assert(med.intent_pattern[2].status_type == "vulnerable", "메두사 3번째 = vulnerable")
	_assert(med.max_hp == 1700, "메두사 HP = 1700")

func test_scylla_pattern() -> void:
	print("[TestEnemies] test_scylla_pattern")
	var gm := _make_gm()
	var s: Resource = GreekAct1.scylla(_make_dummy_scene())
	_assert(s.enemy_name == "스킬라", "스킬라 이름")
	_assert(s.max_hp == 1900, "스킬라 HP = 1900")
	_assert(s.phase_thresholds.size() == 1, "스킬라 페이즈 임계값 1개")
	_assert(s.phase_patterns.size() == 2, "스킬라 페이즈 패턴 2개")
	_assert(s.phase_patterns[0].size() == 7, "스킬라 페이즈 0 패턴 7개")
	_assert(s.phase_patterns[1].size() == 3, "스킬라 페이즈 1 패턴 3개")
	_assert(s.phase_patterns[1][1].status_type == "poison", "스킬라 페이즈 1 독 DEBUFF")

func _make_hydra() -> Array:
	# game_manager._make_boss_enemies()와 동일 로직 — Autoload 없이 테스트용
	var EnemyRes = preload("res://resources/enemy_resource.gd")
	var IntentRes = preload("res://resources/intent_resource.gd")
	var hydra: Resource = EnemyRes.new()
	hydra.enemy_name = "히드라"
	hydra.max_hp = 200
	hydra.phase_thresholds = [0.6, 0.3]
	var p0a1: Resource = IntentRes.new(); p0a1.action_type = IntentRes.ActionType.ATTACK; p0a1.value = 10; p0a1.target = IntentRes.TargetType.RANDOM
	var p0a2: Resource = IntentRes.new(); p0a2.action_type = IntentRes.ActionType.ATTACK; p0a2.value = 10; p0a2.target = IntentRes.TargetType.RANDOM
	var p1a1: Resource = IntentRes.new(); p1a1.action_type = IntentRes.ActionType.ATTACK; p1a1.value = 12; p1a1.target = IntentRes.TargetType.RANDOM
	var p1a2: Resource = IntentRes.new(); p1a2.action_type = IntentRes.ActionType.ATTACK; p1a2.value = 12; p1a2.target = IntentRes.TargetType.RANDOM
	var p1a3: Resource = IntentRes.new(); p1a3.action_type = IntentRes.ActionType.ATTACK; p1a3.value = 12; p1a3.target = IntentRes.TargetType.LOWEST_HP
	var p2a1: Resource = IntentRes.new(); p2a1.action_type = IntentRes.ActionType.ATTACK; p2a1.value = 12; p2a1.target = IntentRes.TargetType.RANDOM
	var p2a2: Resource = IntentRes.new(); p2a2.action_type = IntentRes.ActionType.ATTACK; p2a2.value = 12; p2a2.target = IntentRes.TargetType.RANDOM
	var p2a3: Resource = IntentRes.new(); p2a3.action_type = IntentRes.ActionType.ATTACK; p2a3.value = 12; p2a3.target = IntentRes.TargetType.LOWEST_HP
	var p2b: Resource = IntentRes.new(); p2b.action_type = IntentRes.ActionType.BUFF; p2b.value = 10
	hydra.phase_patterns = [[p0a1, p0a2], [p1a1, p1a2, p1a3], [p2a1, p2a2, p2a3, p2b]]
	hydra.intent_pattern = hydra.phase_patterns[0]
	return [hydra]

func test_hydra_phase_count() -> void:
	print("[TestEnemies] test_hydra_phase_count")
	var enemies: Array = _make_hydra()
	_assert(enemies.size() == 1, "보스 1마리")
	_assert(enemies[0].enemy_name == "히드라", "보스 이름 = 히드라")
	_assert(enemies[0].phase_thresholds.size() == 2, "히드라 페이즈 임계값 2개")
	_assert(enemies[0].phase_patterns.size() == 3, "히드라 페이즈 패턴 3개")

func test_phase_transition() -> void:
	print("[TestEnemies] test_phase_transition")
	var BM = preload("res://autoload/battle_manager.gd")
	var TM = preload("res://autoload/team_manager.gd")
	var HeroRes = preload("res://resources/hero_resource.gd")
	var bm: Node = BM.new()
	var tm: Node = TM.new()
	var hero: Resource = HeroRes.new()
	hero.hero_id = "napoleon"; hero.max_hp = 70; hero.hero_name = "나폴레옹"
	tm.add_hero(hero)
	bm.team_mgr = tm
	var enemies: Array = _make_hydra()
	bm.setup_battle(enemies)
	_assert(bm._enemy_phase[0] == 0, "초기 페이즈 = 0")
	# HP를 59%로 설정
	bm._enemy_hp[0] = int(enemies[0].max_hp * 0.59)
	bm._check_phase_transition(0)
	_assert(bm._enemy_phase[0] == 1, "HP 59% → 페이즈 1")
	bm.free()
	tm.free()

func test_phase2_transition() -> void:
	print("[TestEnemies] test_phase2_transition")
	var BM = preload("res://autoload/battle_manager.gd")
	var TM = preload("res://autoload/team_manager.gd")
	var HeroRes = preload("res://resources/hero_resource.gd")
	var bm: Node = BM.new()
	var tm: Node = TM.new()
	var hero: Resource = HeroRes.new()
	hero.hero_id = "napoleon"; hero.max_hp = 70; hero.hero_name = "나폴레옹"
	tm.add_hero(hero)
	bm.team_mgr = tm
	var enemies: Array = _make_hydra()
	bm.setup_battle(enemies)
	bm._enemy_hp[0] = int(enemies[0].max_hp * 0.59)
	bm._check_phase_transition(0)
	bm._enemy_hp[0] = int(enemies[0].max_hp * 0.29)
	bm._check_phase_transition(0)
	_assert(bm._enemy_phase[0] == 2, "HP 29% → 페이즈 2")
	bm.free()
	tm.free()

func test_discard_random() -> void:
	print("[TestEnemies] test_discard_random")
	var DM = preload("res://autoload/deck_manager.gd")
	var dm := DM.new()
	var CardRes = preload("res://resources/card_resource.gd")
	var EffRes = preload("res://resources/effect_resource.gd")
	# 손패에 카드 3장 추가
	for i in range(3):
		var c := CardRes.new(); c.card_name = "test%d" % i; c.owner_id = "napoleon"; c.cost = 1
		var e := EffRes.new(); e.effect_type = EffRes.EffectType.DAMAGE; e.value = 1
		c.effects = [e]
		dm.hand.append(c)
	dm.discard_random(2)
	_assert(dm.hand.size() == 1, "discard_random(2) 후 hand 1장 남음")
	_assert(dm.discard_pile.size() == 2, "discard_pile에 2장 추가")

# ──────────────────────────────────────────────
# Act 2 적 테스트
# ──────────────────────────────────────────────

func _make_dummy_scene() -> PackedScene:
	return load("res://characters/enemies/satyr/satyr.tscn")

func _make_bm_with_hero() -> Node:
	var BM = preload("res://autoload/battle_manager.gd")
	var TM = preload("res://autoload/team_manager.gd")
	var HeroRes = preload("res://resources/hero_resource.gd")
	var bm: Node = BM.new()
	var tm: Node = TM.new()
	var hero: Resource = HeroRes.new()
	hero.hero_id = "napoleon"; hero.max_hp = 1000; hero.hero_name = "나폴레옹"
	tm.add_hero(hero)
	bm.team_mgr = tm
	return bm

func test_act2_boss_name() -> void:
	print("[TestEnemies] test_act2_boss_name")
	var e := EgyptianAct2.osiris(_make_dummy_scene())
	_assert(e.enemy_name == "오시리스", "Act2 보스 이름 오시리스")

func test_act2_boss_phase_heal_ratios() -> void:
	print("[TestEnemies] test_act2_boss_phase_heal_ratios")
	var e := EgyptianAct2.osiris(_make_dummy_scene())
	_assert(e.phase_heal_ratios.size() == 1, "phase_heal_ratios 1개")
	_assert(e.phase_heal_ratios[0] == 0.6, "부활 비율 60%")

func test_act2_normal_sand_scout() -> void:
	print("[TestEnemies] test_act2_normal_sand_scout")
	var e := EgyptianNormals.sand_scout(_make_dummy_scene())
	_assert(e.enemy_name == "사막 척후병", "이름 확인")
	_assert(e.max_hp == 380, "HP 380")
	_assert(e.intent_pattern.size() == 3, "인텐트 3개")
	var has_buff := false
	for i in e.intent_pattern:
		if i.action_type == IntentRes.ActionType.BUFF: has_buff = true
	_assert(has_buff, "strength BUFF 존재")

func test_act2_normal_desert_scorpion() -> void:
	print("[TestEnemies] test_act2_normal_desert_scorpion")
	var e := EgyptianNormals.desert_scorpion(_make_dummy_scene())
	_assert(e.max_hp == 420, "HP 420")
	var has_poison := false
	for i in e.intent_pattern:
		if i.action_type == IntentRes.ActionType.DEBUFF and i.status_type == "poison":
			has_poison = true
	_assert(has_poison, "poison DEBUFF 존재")

func test_act2_normal_mummy_warrior() -> void:
	print("[TestEnemies] test_act2_normal_mummy_warrior")
	var e := EgyptianNormals.mummy_warrior(_make_dummy_scene())
	_assert(e.max_hp == 600, "HP 600 (가장 높은 일반 적)")

func test_act2_normal_sphinx_cub() -> void:
	print("[TestEnemies] test_act2_normal_sphinx_cub")
	var e := EgyptianNormals.sphinx_cub(_make_dummy_scene())
	_assert(e.max_hp == 350, "HP 350")
	var has_special := false
	for i in e.intent_pattern:
		if i.action_type == IntentRes.ActionType.SPECIAL: has_special = true
	_assert(has_special, "SPECIAL 인텐트 존재")

func test_act2_normal_sand_ifrit() -> void:
	print("[TestEnemies] test_act2_normal_sand_ifrit")
	var e := EgyptianNormals.sand_ifrit(_make_dummy_scene())
	_assert(e.intent_pattern.size() == 2, "인텐트 2개 (준비+강타)")
	_assert(e.intent_pattern[0].action_type == IntentRes.ActionType.BUFF, "첫 턴 BUFF(준비)")
	_assert(e.intent_pattern[1].target == IntentRes.TargetType.ALL, "강타 ALL 타겟")
	_assert(e.intent_pattern[1].value >= 200, "강타 200 이상")

func test_act2_normal_ka_spirit() -> void:
	print("[TestEnemies] test_act2_normal_ka_spirit")
	var e := EgyptianNormals.ka_spirit(_make_dummy_scene())
	var has_weak := false; var has_vuln := false
	for i in e.intent_pattern:
		if i.action_type == IntentRes.ActionType.DEBUFF:
			if i.status_type == "weak": has_weak = true
			if i.status_type == "vulnerable": has_vuln = true
	_assert(has_weak and has_vuln, "weak + vulnerable 모두 존재")

func test_act2_elite_apep_snake() -> void:
	print("[TestEnemies] test_act2_elite_apep_snake")
	var e := EgyptianAct2.apep_snake(_make_dummy_scene())
	_assert(e.max_hp == 1600, "HP 1600")
	var has_poison := false
	for i in e.intent_pattern:
		if i.action_type == IntentRes.ActionType.DEBUFF and i.status_type == "poison":
			has_poison = true
	_assert(has_poison, "poison DEBUFF 존재")

func test_act2_elite_seth_hound() -> void:
	print("[TestEnemies] test_act2_elite_seth_hound")
	var e := EgyptianAct2.seth_hound(_make_dummy_scene())
	_assert(e.max_hp == 1800, "HP 1800 (최고 엘리트)")
	var last_intent: Resource = e.intent_pattern[e.intent_pattern.size() - 1]
	_assert(last_intent.target == IntentRes.TargetType.LOWEST_HP, "마지막 인텐트 LOWEST_HP")
	_assert(last_intent.value >= 280, "암살 280 이상")

func test_act2_elite_ba_bird() -> void:
	print("[TestEnemies] test_act2_elite_ba_bird")
	var e := EgyptianAct2.ba_bird(_make_dummy_scene())
	_assert(e.max_hp == 1500, "HP 1500")
	var has_special := false
	for i in e.intent_pattern:
		if i.action_type == IntentRes.ActionType.SPECIAL and i.value == 2: has_special = true
	_assert(has_special, "SPECIAL value=2 존재")

func test_act2_osiris_structure() -> void:
	print("[TestEnemies] test_act2_osiris_structure")
	var e := EgyptianAct2.osiris(_make_dummy_scene())
	_assert(e.max_hp == 3000, "HP 3000")
	_assert(e.phase_thresholds.size() == 1, "phase_thresholds 1개")
	_assert(e.phase_thresholds[0] == 0.5, "전환 50%")
	_assert(e.phase_patterns.size() == 2, "페이즈 패턴 2개")
	_assert(e.phase_patterns[0].size() >= 4, "페이즈0 4턴 이상")
	_assert(e.phase_patterns[1].size() >= 5, "페이즈1 5턴 이상")
	var revival_intent: Resource = e.phase_patterns[1][0]
	_assert(revival_intent.action_type == IntentRes.ActionType.BUFF, "페이즈1 첫 턴 BUFF")
	_assert(revival_intent.condition == "부활", "condition='부활'")

func test_act2_osiris_phase_transition_heals() -> void:
	print("[TestEnemies] test_act2_osiris_phase_transition_heals")
	var bm := _make_bm_with_hero()
	var enemy := EgyptianAct2.osiris(_make_dummy_scene())
	bm.setup_battle([enemy])
	bm._enemy_hp[0] = int(enemy.max_hp * 0.49)
	bm._check_phase_transition(0)
	var expected_hp := int(enemy.max_hp * 0.6)
	_assert(bm._enemy_phase[0] == 1, "페이즈 1로 전환")
	_assert(bm._enemy_hp[0] == expected_hp, "HP %d으로 복구" % expected_hp)
	bm.free()

func test_act2_gm_act_switch() -> void:
	print("[TestEnemies] test_act2_gm_act_switch")
	var gm := GameManagerClass.new()
	gm.act_mythologies = ["greek", "egyptian"]
	gm.current_act = 1
	var boss_act1 := gm._make_boss_enemies()
	_assert(boss_act1[0].enemy_name == "히드라", "Act1 보스: 히드라")
	gm.current_act = 2
	var boss_act2 := gm._make_boss_enemies()
	_assert(boss_act2[0].enemy_name == "오시리스", "Act2 보스: 오시리스")

func test_greek_normals_encounters() -> void:
	print("[TestEnemies] test_greek_normals_encounters")
	var enc: Array = GreekNormals.encounters()
	_assert(enc.size() >= 3, "그리스 인카운터 조합 3개 이상")
	for combo in enc:
		_assert(combo.size() >= 1, "인카운터 적 1마리 이상")
		_assert(combo.size() <= 6, "인카운터 적 6마리 이하")

func test_egyptian_normals_encounters() -> void:
	print("[TestEnemies] test_egyptian_normals_encounters")
	var enc: Array = EgyptianNormals.encounters()
	_assert(enc.size() >= 3, "이집트 인카운터 조합 3개 이상")
	for combo in enc:
		_assert(combo.size() >= 1, "인카운터 적 1마리 이상")
		_assert(combo.size() <= 6, "인카운터 적 6마리 이하")

func test_normal_enemy_multi_encounter() -> void:
	print("[TestEnemies] test_normal_enemy_multi_encounter")
	var gm := _make_gm()
	gm.act_mythologies = ["greek", "egyptian"]
	var saw_multi := false
	for _i in range(30):
		var enemies := gm._make_normal_enemies()
		_assert(enemies.size() >= 1, "인카운터 적 1마리 이상")
		if enemies.size() >= 2:
			saw_multi = true
	_assert(saw_multi, "30회 중 다수 인카운터 최소 1회")

func test_norse_normals_shape() -> void:
	print("[TestEnemies] test_norse_normals_shape")
	var scene := _make_dummy_scene()
	var enemies := [
		NorseNormals.draugr(scene), NorseNormals.urdr_spider(scene),
		NorseNormals.jotun_soldier(scene), NorseNormals.volva_witch(scene),
		NorseNormals.hrimfaxi_rider(scene), NorseNormals.garlarr_snake(scene),
	]
	for e in enemies:
		_assert(e.enemy_name != "", "이름 비어있지 않음")
		_assert(e.max_hp > 0, "HP > 0")
		_assert(e.mythology == "norse", "mythology = norse")

func test_norse_encounters_shape() -> void:
	print("[TestEnemies] test_norse_encounters_shape")
	var enc: Array = NorseNormals.encounters()
	_assert(enc.size() >= 3, "북유럽 인카운터 조합 3개 이상")
	for combo in enc:
		_assert(combo.size() >= 1, "인카운터 적 1마리 이상")
		_assert(combo.size() <= 6, "인카운터 적 6마리 이하")

func test_norse_act3_boss_name() -> void:
	print("[TestEnemies] test_norse_act3_boss_name")
	var e := NorseAct3.jormungandr(_make_dummy_scene())
	_assert(e.enemy_name == "요르문간드르", "보스 이름 요르문간드르")
	_assert(e.max_hp == 5000, "보스 HP 5000")
	_assert(e.phase_thresholds.size() == 2, "보스 페이즈 임계값 2개 (3페이즈)")
	_assert(e.phase_patterns.size() == 3, "보스 페이즈 패턴 3개")

func test_norse_act3_elites() -> void:
	print("[TestEnemies] test_norse_act3_elites")
	var elites: Array = NorseAct3.elites()
	_assert(elites.size() == 3, "엘리트 3종")
	var scene := _make_dummy_scene()
	var elite_enemies := [
		NorseAct3.fenrir_cub(scene),
		NorseAct3.valkyrie(scene),
		NorseAct3.jormungandr_shard(scene),
	]
	for e in elite_enemies:
		_assert(e.max_hp >= 1800, "HP >= 1800")
		_assert(e.mythology == "norse", "mythology = norse")

func test_relic_pool_count() -> void:
	print("[TestEnemies] test_relic_pool_count")
	var RelicData = load("res://resources/relics/relics.gd")
	var pool: Array = RelicData.build_pool()
	assert(pool.size() == 25, "렐릭 풀 25종이어야 함 (기존 22 + Act 3 3종)")
	_assert(pool.size() == 25, "렐릭 풀 25종 (기존 22 + Act 3 3종)")

func test_act3_event_pool_shape() -> void:
	print("[TestEnemies] test_act3_event_pool_shape")
	var EventsAct3 = load("res://resources/events/events_act3.gd")
	var pool: Array = EventsAct3.build_pool()
	assert(pool.size() == 10, "Act 3 이벤트는 10종이어야 함")
	for ev in pool:
		assert(ev.event_name != "", "이벤트 이름 비어있으면 안 됨")
		assert(ev.choices.size() >= 2, "선택지 최소 2개")
	passed += 1

func test_greek_act2_shape() -> void:
	print("[TestEnemies] test_greek_act2_shape")
	var M = load("res://resources/enemies/greek/greek_act2.gd")
	assert(M.elites().size() == 3, "greek_act2 엘리트 3종")
	assert(M.boss() == "hades", "greek_act2 보스는 하데스")
	var scene = load("res://characters/summons/soldier/soldier.tscn")
	var b = M.hades(scene)
	assert(b.max_hp == 4800, "하데스 HP 4800")
	assert(b.phase_thresholds.size() == 2, "하데스 3페이즈")
	assert(b.mythology == "greek", "하데스 mythology=greek")
	_assert(M.elites().size() == 3, "greek_act2 엘리트 3종")
	_assert(M.boss() == "hades", "greek_act2 보스는 하데스")
	_assert(b.max_hp == 4800, "하데스 HP 4800")
	_assert(b.phase_thresholds.size() == 2, "하데스 3페이즈")
	_assert(b.mythology == "greek", "하데스 mythology=greek")

func test_egyptian_act1_shape() -> void:
	print("[TestEnemies] test_egyptian_act1_shape")
	var M = load("res://resources/enemies/egyptian/egyptian_act1.gd")
	assert(M.elites().size() == 3, "egyptian_act1 엘리트 3종")
	assert(M.boss() == "sekhmet", "egyptian_act1 보스는 세크메트")
	var scene = load("res://characters/summons/soldier/soldier.tscn")
	var b = M.sekhmet(scene)
	assert(b.max_hp == 4500, "세크메트 HP 4500")
	assert(b.phase_thresholds.size() == 2, "세크메트 3페이즈")
	assert(b.mythology == "egyptian", "세크메트 mythology=egyptian")
	_assert(M.elites().size() == 3, "egyptian_act1 엘리트 3종")
	_assert(M.boss() == "sekhmet", "egyptian_act1 보스는 세크메트")
	_assert(b.max_hp == 4500, "세크메트 HP 4500")
	_assert(b.phase_thresholds.size() == 2, "세크메트 3페이즈")
	_assert(b.mythology == "egyptian", "세크메트 mythology=egyptian")

func test_norse_act1_shape() -> void:
	print("[TestEnemies] test_norse_act1_shape")
	var M = load("res://resources/enemies/norse/norse_act1.gd")
	assert(M.elites().size() == 3, "norse_act1 엘리트 3종")
	assert(M.boss() == "fjorgynn", "norse_act1 보스는 피요르기닌")
	var scene = load("res://characters/summons/soldier/soldier.tscn")
	var b = M.fjorgynn(scene)
	assert(b.max_hp == 4500, "피요르기닌 HP 4500")
	assert(b.phase_thresholds.size() == 2, "피요르기닌 3페이즈")
	assert(b.mythology == "norse", "피요르기닌 mythology=norse")
	_assert(M.elites().size() == 3, "norse_act1 엘리트 3종")
	_assert(M.boss() == "fjorgynn", "norse_act1 보스는 피요르기닌")
	_assert(b.max_hp == 4500, "피요르기닌 HP 4500")
	_assert(b.phase_thresholds.size() == 2, "피요르기닌 3페이즈")
	_assert(b.mythology == "norse", "피요르기닌 mythology=norse")

func test_norse_act2_shape() -> void:
	print("[TestEnemies] test_norse_act2_shape")
	var M = load("res://resources/enemies/norse/norse_act2.gd")
	assert(M.elites().size() == 3, "norse_act2 엘리트 3종")
	assert(M.boss() == "surtr", "norse_act2 보스는 수르트")
	var scene = load("res://characters/summons/soldier/soldier.tscn")
	var b = M.surtr(scene)
	assert(b.max_hp == 4800, "수르트 HP 4800")
	assert(b.phase_thresholds.size() == 2, "수르트 3페이즈")
	assert(b.mythology == "norse", "수르트 mythology=norse")
	_assert(M.elites().size() == 3, "norse_act2 엘리트 3종")
	_assert(M.boss() == "surtr", "norse_act2 보스는 수르트")
	_assert(b.max_hp == 4800, "수르트 HP 4800")
	_assert(b.phase_thresholds.size() == 2, "수르트 3페이즈")
	_assert(b.mythology == "norse", "수르트 mythology=norse")

func test_greek_act3_shape() -> void:
	print("[TestEnemies] test_greek_act3_shape")
	var M = load("res://resources/enemies/greek/greek_act3.gd")
	assert(M.elites().size() == 3, "greek_act3 엘리트 3종")
	assert(M.boss() == "kronos", "greek_act3 보스는 크로노스")
	var scene = load("res://characters/summons/soldier/soldier.tscn")
	var b = M.kronos(scene)
	assert(b.max_hp == 5200, "크로노스 HP 5200")
	assert(b.phase_thresholds.size() == 2, "크로노스 3페이즈")
	assert(b.mythology == "greek", "크로노스 mythology=greek")
	_assert(M.elites().size() == 3, "greek_act3 엘리트 3종")
	_assert(M.boss() == "kronos", "greek_act3 보스는 크로노스")
	_assert(b.max_hp == 5200, "크로노스 HP 5200")
	_assert(b.phase_thresholds.size() == 2, "크로노스 3페이즈")
	_assert(b.mythology == "greek", "크로노스 mythology=greek")

func test_egyptian_act3_shape() -> void:
	print("[TestEnemies] test_egyptian_act3_shape")
	var M = load("res://resources/enemies/egyptian/egyptian_act3.gd")
	assert(M.elites().size() == 3, "egyptian_act3 엘리트 3종")
	assert(M.boss() == "ra_horakhty", "egyptian_act3 보스는 라-호라크티")
	var scene = load("res://characters/summons/soldier/soldier.tscn")
	var b = M.ra_horakhty(scene)
	assert(b.max_hp == 5000, "라-호라크티 HP 5000")
	assert(b.phase_thresholds.size() == 2, "라-호라크티 3페이즈")
	assert(b.mythology == "egyptian", "라-호라크티 mythology=egyptian")
	_assert(M.elites().size() == 3, "egyptian_act3 엘리트 3종")
	_assert(M.boss() == "ra_horakhty", "egyptian_act3 보스는 라-호라크티")
	_assert(b.max_hp == 5000, "라-호라크티 HP 5000")
	_assert(b.phase_thresholds.size() == 2, "라-호라크티 3페이즈")
	_assert(b.mythology == "egyptian", "라-호라크티 mythology=egyptian")

func test_mythology_randomization_structure() -> void:
	print("[TestEnemies] test_mythology_randomization_structure")
	# mythology 목록이 항상 3종 포함 + 중복 없음을 확인
	var gm := GameManagerClass.new()
	gm.reset()
	_assert(gm.act_mythologies.size() == 3, "act_mythologies 항상 3개")
	_assert(gm.act_mythologies.has("greek"), "그리스 포함")
	_assert(gm.act_mythologies.has("egyptian"), "이집트 포함")
	_assert(gm.act_mythologies.has("norse"), "북유럽 포함")
	# 모든 mythology×act 조합에 null 없음 확인
	var reg: Dictionary = gm._get_mythology_registry()
	for myth in gm.act_mythologies:
		for i in range(3):
			_assert(reg[myth]["acts"][i] != null, myth + " act" + str(i+1) + " null 없음")

func test_korean_normals_shape() -> void:
	print("[TestEnemies] test_korean_normals_shape")
	var M = load("res://resources/enemies/korean/korean_normals.gd")
	var scene: PackedScene = load("res://characters/summons/soldier/soldier.tscn")
	var encs: Array = M.encounters()
	_assert(encs.size() >= 5, "한국 인카운터 5조합 이상")
	var e1: Resource = M.death_reaper(scene)
	_assert(e1.max_hp == 320, "저승사자 HP 320")
	_assert(e1.mythology == "korean", "저승사자 mythology=korean")
	_assert(e1.intent_pattern.size() == 3, "저승사자 인텐트 3개")
	var e2: Resource = M.bulgasari(scene)
	_assert(e2.max_hp == 900, "불가사리 HP 900")
	_assert(e2.intent_pattern.size() == 3, "불가사리 인텐트 3개")
	var e3: Resource = M.three_legged_crow(scene)
	_assert(e3.max_hp == 280, "삼족오 HP 280")

func test_korean_act1_shape() -> void:
	print("[TestEnemies] test_korean_act1_shape")
	var M = load("res://resources/enemies/korean/korean_act1.gd")
	_assert(M.elites().size() == 3, "korean_act1 엘리트 3종")
	_assert(M.boss() == "dangun", "korean_act1 보스는 dangun")
	var scene = load("res://characters/summons/soldier/soldier.tscn")
	var b = M.dangun(scene)
	_assert(b.max_hp == 4500, "단군 HP 4500")
	_assert(b.phase_thresholds.size() == 2, "단군 3페이즈")
	_assert(b.mythology == "korean", "단군 mythology=korean")
	_assert(b.charm_resistance == 2, "단군 charm_resistance=2")
	var haemosu = M.haemosu(scene)
	_assert(haemosu.max_hp == 1900, "해모수 엘리트 HP 1900")
	_assert(haemosu.charm_resistance == 1, "해모수 charm_resistance=1")

func test_korean_act2_shape() -> void:
	print("[TestEnemies] test_korean_act2_shape")
	var M = load("res://resources/enemies/korean/korean_act2.gd")
	_assert(M.elites().size() == 3, "korean_act2 엘리트 3종")
	_assert(M.boss() == "samsin_grandma", "korean_act2 보스는 samsin_grandma")
	var scene = load("res://characters/summons/soldier/soldier.tscn")
	var b = M.samsin_grandma(scene)
	_assert(b.max_hp == 4800, "삼신할미 HP 4800")
	_assert(b.phase_thresholds.size() == 2, "삼신할미 3페이즈")
	_assert(b.mythology == "korean", "삼신할미 mythology=korean")
	_assert(b.charm_resistance == 2, "삼신할미 charm_resistance=2")
	var dongmyeong = M.dongmyeong(scene)
	_assert(dongmyeong.max_hp == 1900, "동명성왕 엘리트 HP 1900")
	_assert(dongmyeong.charm_resistance == 1, "동명성왕 charm_resistance=1")
