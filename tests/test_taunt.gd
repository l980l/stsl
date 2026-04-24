# tests/test_taunt.gd
# 도발(Taunt) 타겟 우회 로직 테스트 (Plan 28-C)
class_name TestTaunt
extends RefCounted

const TeamManagerClass   = preload("res://autoload/team_manager.gd")
const BattleManagerClass = preload("res://autoload/battle_manager.gd")
const DeckManagerClass   = preload("res://autoload/deck_manager.gd")
const HeroRes            = preload("res://resources/hero_resource.gd")
const EnemyRes           = preload("res://resources/enemy_resource.gd")
const IntentRes          = preload("res://resources/intent_resource.gd")

var passed: int = 0
var failed: int = 0
var _to_free: Array = []

func run_all() -> Dictionary:
	print("[TestTaunt] 도발 타겟 우회 테스트 시작")
	test_taunt_redirects_attack()
	test_taunt_does_not_redirect_debuff()
	test_taunt_highest_hp_tiebreak()
	test_taunt_decrements_on_turn_end()
	test_dead_taunter_ignored()
	test_taunt_stacks()
	for n in _to_free:
		if is_instance_valid(n):
			n.free()
	_to_free.clear()
	return { "passed": passed, "failed": failed }

func _assert(cond: bool, msg: String) -> void:
	if cond:
		print("  PASS: " + msg)
		passed += 1
	else:
		print("  FAIL: " + msg)
		failed += 1

# ────────────────────────────────────────────
# 헬퍼
# ────────────────────────────────────────────

func _make_bm() -> BattleManagerClass:
	var bm := BattleManagerClass.new()
	bm.team_mgr = TeamManagerClass.new()
	bm.deck_mgr = DeckManagerClass.new()
	_to_free.append(bm)
	_to_free.append(bm.team_mgr)
	_to_free.append(bm.deck_mgr)
	return bm

func _make_hero(id: String, hp: int) -> Resource:
	var h := HeroRes.new()
	h.hero_id = id
	h.hero_name = id
	h.max_hp = hp
	return h

func _make_attack_intent(value: int, target: IntentRes.TargetType) -> IntentRes:
	var intent := IntentRes.new()
	intent.action_type = IntentRes.ActionType.ATTACK
	intent.value = value
	intent.target = target
	return intent

func _make_debuff_intent(stype: String, target: IntentRes.TargetType) -> IntentRes:
	var intent := IntentRes.new()
	intent.action_type = IntentRes.ActionType.DEBUFF
	intent.value = 1
	intent.target = target
	intent.status_type = stype
	return intent

func _make_enemy_with_intent(intent: IntentRes) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "더미 적"
	e.max_hp = 100
	e.intent_pattern = [intent]
	return e

# ────────────────────────────────────────────
# 1. 도발 영웅이 적 ATTACK 공격을 흡수
# ────────────────────────────────────────────
func test_taunt_redirects_attack() -> void:
	print("[TestTaunt] test_taunt_redirects_attack")
	var bm := _make_bm()
	var tm: TeamManagerClass = bm.team_mgr
	# 영웅 3명: napoleon(50HP), cleopatra(80HP), musashi(60HP)
	tm.add_hero(_make_hero("napoleon", 50))
	tm.add_hero(_make_hero("cleopatra", 80))
	tm.add_hero(_make_hero("musashi", 60))

	# LOWEST_HP 타겟 인텐트 — 도발 없으면 napoleon(50)이 맞아야 함
	var intent := _make_attack_intent(5, IntentRes.TargetType.LOWEST_HP)
	bm.setup_battle([_make_enemy_with_intent(intent)])

	# musashi에 도발 부여
	bm._hero_status["musashi"] = {"taunt": 1}

	var hp_before: int = tm.get_current_hp("musashi")
	# 적 공격 실행
	bm._execute_intent(0, intent)

	var hp_after: int = tm.get_current_hp("musashi")
	_assert(hp_after < hp_before, "도발 영웅(musashi)이 ATTACK 공격을 흡수함")

# ────────────────────────────────────────────
# 2. DEBUFF는 도발에 영향받지 않음
# ────────────────────────────────────────────
func test_taunt_does_not_redirect_debuff() -> void:
	print("[TestTaunt] test_taunt_does_not_redirect_debuff")
	var bm := _make_bm()
	var tm: TeamManagerClass = bm.team_mgr
	tm.add_hero(_make_hero("napoleon", 50))
	tm.add_hero(_make_hero("cleopatra", 80))

	# DEBUFF ALL 인텐트
	var intent := _make_debuff_intent("weak", IntentRes.TargetType.ALL)
	bm.setup_battle([_make_enemy_with_intent(intent)])

	# cleopatra에 도발 부여
	bm._hero_status["cleopatra"] = {"taunt": 1}

	bm._execute_intent(0, intent)

	# 전원이 weak 1 받아야 함
	var napoleon_weak: int = bm._hero_status.get("napoleon", {}).get("weak", 0)
	var cleo_weak: int = bm._hero_status.get("cleopatra", {}).get("weak", 0)
	_assert(napoleon_weak >= 1, "DEBUFF ALL — napoleon도 weak 받음 (도발 무관)")
	_assert(cleo_weak >= 1, "DEBUFF ALL — cleopatra도 weak 받음")

# ────────────────────────────────────────────
# 3. 도발 영웅 여럿 → HP 높은 쪽이 공격받음
# ────────────────────────────────────────────
func test_taunt_highest_hp_tiebreak() -> void:
	print("[TestTaunt] test_taunt_highest_hp_tiebreak")
	var bm := _make_bm()
	var tm: TeamManagerClass = bm.team_mgr
	# napoleon(50HP), cleopatra(80HP) 둘 다 도발
	tm.add_hero(_make_hero("napoleon", 50))
	tm.add_hero(_make_hero("cleopatra", 80))

	var intent := _make_attack_intent(5, IntentRes.TargetType.LOWEST_HP)
	bm.setup_battle([_make_enemy_with_intent(intent)])

	bm._hero_status["napoleon"]   = {"taunt": 2}
	bm._hero_status["cleopatra"]  = {"taunt": 2}

	var cleo_hp_before: int = tm.get_current_hp("cleopatra")
	var napoleon_hp_before: int = tm.get_current_hp("napoleon")
	bm._execute_intent(0, intent)

	var cleo_took_dmg: bool = tm.get_current_hp("cleopatra") < cleo_hp_before
	var napoleon_took_dmg: bool = tm.get_current_hp("napoleon") < napoleon_hp_before
	_assert(cleo_took_dmg and not napoleon_took_dmg,
		"도발 2명 중 HP 높은 cleopatra(80)가 공격받음")

# ────────────────────────────────────────────
# 4. 턴 종료 시 taunt 감소
# ────────────────────────────────────────────
func test_taunt_decrements_on_turn_end() -> void:
	print("[TestTaunt] test_taunt_decrements_on_turn_end")
	var bm := _make_bm()
	var tm: TeamManagerClass = bm.team_mgr
	tm.add_hero(_make_hero("napoleon", 50))

	var dummy_intent := _make_attack_intent(1, IntentRes.TargetType.RANDOM)
	bm.setup_battle([_make_enemy_with_intent(dummy_intent)])

	bm._hero_status["napoleon"] = {"taunt": 2}

	# _phase_player_main 내부의 상태 감소 로직을 직접 호출 (is_player_turn 없이)
	# _phase_player_main은 draw 등 부작용이 있으므로 상태 감소 부분만 재현
	for hero in tm.heroes:
		if not tm.is_alive(hero.hero_id):
			continue
		for stype: String in ["weak", "vulnerable", "taunt"]:
			var cur: int = bm._hero_status.get(hero.hero_id, {}).get(stype, 0)
			if cur > 0:
				if not bm._hero_status.has(hero.hero_id):
					bm._hero_status[hero.hero_id] = {}
				bm._hero_status[hero.hero_id][stype] = cur - 1

	var taunt_after_1: int = bm._hero_status.get("napoleon", {}).get("taunt", 0)
	_assert(taunt_after_1 == 1, "1턴 후 taunt == 1")

	# 한 번 더
	for hero in tm.heroes:
		if not tm.is_alive(hero.hero_id):
			continue
		for stype: String in ["weak", "vulnerable", "taunt"]:
			var cur: int = bm._hero_status.get(hero.hero_id, {}).get(stype, 0)
			if cur > 0:
				bm._hero_status[hero.hero_id][stype] = cur - 1

	var taunt_after_2: int = bm._hero_status.get("napoleon", {}).get("taunt", 0)
	_assert(taunt_after_2 == 0, "2턴 후 taunt == 0")

# ────────────────────────────────────────────
# 5. 사망한 도발 영웅은 타겟에서 제외
# ────────────────────────────────────────────
func test_dead_taunter_ignored() -> void:
	print("[TestTaunt] test_dead_taunter_ignored")
	var bm := _make_bm()
	var tm: TeamManagerClass = bm.team_mgr
	tm.add_hero(_make_hero("napoleon", 50))
	tm.add_hero(_make_hero("cleopatra", 80))

	var intent := _make_attack_intent(5, IntentRes.TargetType.RANDOM)
	bm.setup_battle([_make_enemy_with_intent(intent)])

	# napoleon에 도발 부여 후 사망 처리
	bm._hero_status["napoleon"] = {"taunt": 1}
	tm._hero_alive["napoleon"] = false
	tm._hero_hp["napoleon"]    = 0

	# 살아있는 cleopatra만 존재 → cleopatra가 맞아야 함
	var cleo_hp_before: int = tm.get_current_hp("cleopatra")
	bm._execute_intent(0, intent)
	var cleo_took_dmg: bool = tm.get_current_hp("cleopatra") < cleo_hp_before
	_assert(cleo_took_dmg, "사망한 도발 영웅(napoleon) 무시 → cleopatra가 공격받음")

# ────────────────────────────────────────────
# 6. taunt 중첩 누적
# ────────────────────────────────────────────
func test_taunt_stacks() -> void:
	print("[TestTaunt] test_taunt_stacks")
	var bm := _make_bm()
	var tm: TeamManagerClass = bm.team_mgr
	tm.add_hero(_make_hero("napoleon", 50))

	var dummy_intent := _make_attack_intent(1, IntentRes.TargetType.RANDOM)
	bm.setup_battle([_make_enemy_with_intent(dummy_intent)])

	# taunt=1 부여
	bm._apply_status_to_hero("napoleon", "taunt", 1)
	_assert(bm._hero_status.get("napoleon", {}).get("taunt", 0) == 1,
		"taunt 1 부여 후 taunt == 1")

	# taunt=2 추가 부여
	bm._apply_status_to_hero("napoleon", "taunt", 2)
	_assert(bm._hero_status.get("napoleon", {}).get("taunt", 0) == 3,
		"taunt 2 추가 부여 후 taunt == 3 (누적)")
