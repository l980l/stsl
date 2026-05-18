# tests/test_power_cards.gd
# 권능 카드 7장 테스트 (Plan 26 Step 7)
class_name TestPowerCards
extends RefCounted

const BattleManagerClass = preload("res://autoload/battle_manager.gd")
const TeamManagerClass   = preload("res://autoload/team_manager.gd")
const DeckManagerClass   = preload("res://autoload/deck_manager.gd")
const EffectRes  = preload("res://resources/effect_resource.gd")
const CardRes    = preload("res://resources/card_resource.gd")
const HeroRes    = preload("res://resources/hero_resource.gd")
const EnemyRes   = preload("res://resources/enemy_resource.gd")
const IntentRes  = preload("res://resources/intent_resource.gd")

var passed: int = 0
var failed: int = 0
var _to_free: Array = []

func run_all() -> Dictionary:
	print("[TestPowerCards] 권능 카드 테스트 시작")
	test_poison_per_turn_register()
	test_poison_per_turn_trigger()
	test_block_per_turn_register()
	test_block_per_turn_trigger()
	test_block_per_turn_permanent()
	test_counter_per_attack_register()
	test_counter_per_attack_trigger()
	test_heal_team_per_turn_register()
	test_heal_team_per_turn_trigger()
	test_draw_per_turn_register()
	test_draw_per_turn_trigger()
	test_block_per_turn_musashi_register()
	test_block_per_turn_musashi_trigger()
	test_setup_battle_clears_powers()
	for n in _to_free:
		if is_instance_valid(n):
			n.free()
	_to_free.clear()
	return { "passed": passed, "failed": failed }

func _assert(condition: bool, msg: String) -> void:
	if condition:
		print("  PASS: " + msg)
		passed += 1
	else:
		print("  FAIL: " + msg)
		failed += 1

func _make_bm() -> BattleManagerClass:
	var bm := BattleManagerClass.new()
	bm._test_disable_crit = true  # 테스트 — 정확 데미지 검증
	bm.team_mgr = TeamManagerClass.new()
	bm.deck_mgr = DeckManagerClass.new()
	_to_free.append(bm)
	_to_free.append(bm.team_mgr)
	_to_free.append(bm.deck_mgr)
	return bm

func _make_hero(id: String, hp: int) -> Resource:
	var h := HeroRes.new()
	h.hero_id = id
	h.max_hp = hp
	return h

func _make_enemy(hp: int) -> Resource:
	var e := EnemyRes.new()
	e.max_hp = hp
	return e

func _make_power_card(owner_id: String, status_type: String, value: int) -> Resource:
	var c := CardRes.new()
	c.card_name = "Test Power"
	c.owner_id = owner_id
	c.cost = 0
	c.card_type = CardRes.CardType.POWER
	var e := EffectRes.new()
	e.effect_type = EffectRes.EffectType.APPLY_STATUS
	e.status_type = status_type
	e.value = value
	c.effects = [e]
	return c

# ---------- 1. 독의 왕좌 (poison_per_turn) ----------

func test_poison_per_turn_register() -> void:
	print("[TestPowerCards] test_poison_per_turn_register")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("cleopatra", 50))
	bm.setup_battle([_make_enemy(100)])
	bm.start_player_turn()

	var card := _make_power_card("cleopatra", "power.poison_per_turn", 3)
	bm.deck_mgr.hand.append(card)
	bm.deck_mgr.current_energy = 3
	bm.play_card(card, 0)

	var powers := bm.get_all_active_powers()
	_assert(powers.has("power.poison_per_turn:cleopatra"), "독의 왕좌 권능 등록됨")
	_assert(powers.get("power.poison_per_turn:cleopatra", {}).get("value", 0) == 3, "독의 왕좌 value == 3")

func test_poison_per_turn_trigger() -> void:
	print("[TestPowerCards] test_poison_per_turn_trigger")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("cleopatra", 50))
	bm.setup_battle([_make_enemy(100)])
	bm.start_player_turn()

	var card := _make_power_card("cleopatra", "power.poison_per_turn", 3)
	bm.deck_mgr.hand.append(card)
	bm.deck_mgr.current_energy = 3
	bm.play_card(card, 0)

	# 다음 턴 시작 시 trigger
	bm.start_player_turn()
	var poison_stack: int = bm._enemy_status[0].get("poison_dmg", 0)
	_assert(poison_stack >= 3, "다음 턴 시작 시 적 독 스택 +3 이상 (poison_dmg >= 3)")

# ---------- 2. 전사의 각오 (block_per_turn) — 이순신 ----------

func test_block_per_turn_register() -> void:
	print("[TestPowerCards] test_block_per_turn_register")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("yi_sun_sin", 60))
	bm.setup_battle([_make_enemy(100)])
	bm.start_player_turn()

	var card := _make_power_card("yi_sun_sin", "power.block_per_turn", 20)
	bm.deck_mgr.hand.append(card)
	bm.deck_mgr.current_energy = 3
	bm.play_card(card, 0)

	var powers := bm.get_all_active_powers()
	_assert(powers.has("power.block_per_turn:yi_sun_sin"), "전사의 각오 권능 등록됨")
	_assert(powers.get("power.block_per_turn:yi_sun_sin", {}).get("value", 0) == 20, "전사의 각오 value == 20")

func test_block_per_turn_trigger() -> void:
	print("[TestPowerCards] test_block_per_turn_trigger")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("yi_sun_sin", 60))
	bm.setup_battle([_make_enemy(100)])
	bm.start_player_turn()

	var card := _make_power_card("yi_sun_sin", "power.block_per_turn", 20)
	bm.deck_mgr.hand.append(card)
	bm.deck_mgr.current_energy = 3
	bm.play_card(card, 0)

	# 다음 턴 시작 → 블록 +20
	bm.start_player_turn()
	var blk: int = bm._hero_block.get("yi_sun_sin", 0)
	_assert(blk == 20, "턴 시작 시 이순신 블록 +20 (blk == 20)")

func test_block_per_turn_permanent() -> void:
	print("[TestPowerCards] test_block_per_turn_permanent")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("yi_sun_sin", 60))
	bm.setup_battle([_make_enemy(100)])
	bm.start_player_turn()

	var card := _make_power_card("yi_sun_sin", "power.block_per_turn", 20)
	bm.deck_mgr.hand.append(card)
	bm.deck_mgr.current_energy = 3
	bm.play_card(card, 0)

	# 2번째 턴
	bm.start_player_turn()
	# 3번째 턴 — 권능 여전히 존재해야 함
	bm.start_player_turn()
	var powers := bm.get_all_active_powers()
	_assert(powers.has("power.block_per_turn:yi_sun_sin"), "3번째 턴에도 권능 유지 (영구성 확인)")
	var blk: int = bm._hero_block.get("yi_sun_sin", 0)
	_assert(blk == 20, "3번째 턴에도 블록 +20 발동")

# ---------- 3. 반격 태세 (counter_per_attack) ----------

func test_counter_per_attack_register() -> void:
	print("[TestPowerCards] test_counter_per_attack_register")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("yi_sun_sin", 60))
	bm.setup_battle([_make_enemy(100)])
	bm.start_player_turn()

	var card := _make_power_card("yi_sun_sin", "power.counter_per_attack", 50)
	bm.deck_mgr.hand.append(card)
	bm.deck_mgr.current_energy = 3
	bm.play_card(card, 0)

	var powers := bm.get_all_active_powers()
	_assert(powers.has("power.counter_per_attack:yi_sun_sin"), "반격 태세 권능 등록됨")
	_assert(powers.get("power.counter_per_attack:yi_sun_sin", {}).get("value", 0) == 50, "반격 태세 value == 50")

func test_counter_per_attack_trigger() -> void:
	print("[TestPowerCards] test_counter_per_attack_trigger")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("yi_sun_sin", 60))
	bm.setup_battle([_make_enemy(100)])
	bm.start_player_turn()

	# 반격 태세 등록
	var card := _make_power_card("yi_sun_sin", "power.counter_per_attack", 50)
	bm.deck_mgr.hand.append(card)
	bm.deck_mgr.current_energy = 3
	bm.play_card(card, 0)

	# 이순신에게 블록 40 부여
	bm._hero_block["yi_sun_sin"] = 40

	var hp_before: int = bm._enemy_hp[0]
	# 반격 trigger — 블록 40의 50% = 20 데미지 예상
	bm._trigger_active_powers("enemy_attack", {"enemy_index": 0, "target_hero_id": "yi_sun_sin"})
	var hp_after: int = bm._enemy_hp[0]

	_assert(hp_after < hp_before, "반격 태세 발동: 적 HP 감소")
	_assert(hp_before - hp_after == 20, "반격 데미지 == 블록(40) * 50% == 20")

# ---------- 4. 성가대 (heal_team_per_turn) — 잔 다르크 ----------

func test_heal_team_per_turn_register() -> void:
	print("[TestPowerCards] test_heal_team_per_turn_register")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("joan_of_arc", 60))
	bm.setup_battle([_make_enemy(100)])
	bm.start_player_turn()

	var card := _make_power_card("joan_of_arc", "power.heal_team_per_turn", 5)
	bm.deck_mgr.hand.append(card)
	bm.deck_mgr.current_energy = 3
	bm.play_card(card, 0)

	var powers := bm.get_all_active_powers()
	_assert(powers.has("power.heal_team_per_turn:joan_of_arc"), "성가대 권능 등록됨")
	_assert(powers.get("power.heal_team_per_turn:joan_of_arc", {}).get("value", 0) == 5, "성가대 value == 5")

func test_heal_team_per_turn_trigger() -> void:
	print("[TestPowerCards] test_heal_team_per_turn_trigger")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("joan_of_arc", 60))
	bm.setup_battle([_make_enemy(100)])
	bm.start_player_turn()

	# HP 감소
	bm.team_mgr.take_damage("joan_of_arc", 20)
	var hp_before: int = bm.team_mgr.get_current_hp("joan_of_arc")

	# 성가대 등록
	var card := _make_power_card("joan_of_arc", "power.heal_team_per_turn", 5)
	bm.deck_mgr.hand.append(card)
	bm.deck_mgr.current_energy = 3
	bm.play_card(card, 0)

	# 다음 턴 시작 → 팀 회복 +5
	bm.start_player_turn()
	var hp_after: int = bm.team_mgr.get_current_hp("joan_of_arc")
	_assert(hp_after > hp_before, "턴 시작 시 잔 다르크 HP 회복")
	_assert(hp_after - hp_before == 5, "회복량 == 5")

# ---------- 5. 초원의 군주 (draw_per_turn) — 칭기즈칸 ----------

func test_draw_per_turn_register() -> void:
	print("[TestPowerCards] test_draw_per_turn_register")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("genghis_khan", 55))
	bm.setup_battle([_make_enemy(100)])
	bm.start_player_turn()

	var card := _make_power_card("genghis_khan", "power.draw_per_turn", 2)
	bm.deck_mgr.hand.append(card)
	bm.deck_mgr.current_energy = 3
	bm.play_card(card, 0)

	var powers := bm.get_all_active_powers()
	_assert(powers.has("power.draw_per_turn:genghis_khan"), "초원의 군주 권능 등록됨")
	_assert(powers.get("power.draw_per_turn:genghis_khan", {}).get("value", 0) == 2, "초원의 군주 value == 2")

func test_draw_per_turn_trigger() -> void:
	print("[TestPowerCards] test_draw_per_turn_trigger")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("genghis_khan", 55))
	bm.setup_battle([_make_enemy(100)])
	bm.start_player_turn()

	# 더미 카드 드로우파일에 추가
	for i in range(5):
		var dummy := CardRes.new()
		dummy.owner_id = "genghis_khan"
		dummy.cost = 0
		dummy.effects = []
		bm.deck_mgr.draw_pile.append(dummy)

	var card := _make_power_card("genghis_khan", "power.draw_per_turn", 2)
	bm.deck_mgr.hand.append(card)
	bm.deck_mgr.current_energy = 3
	bm.play_card(card, 0)

	# 다음 턴 — _cards_drawn_this_turn은 turn_start에서 0 리셋 후 draw_per_turn 발동
	bm.start_player_turn()
	_assert(bm._cards_drawn_this_turn >= 2, "_cards_drawn_this_turn >= 2 (draw_per_turn 발동)")

# ---------- 6. 검의 깨달음 (block_per_turn) — 무사시 ----------

func test_block_per_turn_musashi_register() -> void:
	print("[TestPowerCards] test_block_per_turn_musashi_register")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("musashi", 70))
	bm.team_mgr.add_hero(_make_hero("yi_sun_sin", 60))
	bm.setup_battle([_make_enemy(100)])
	bm.start_player_turn()

	var card := _make_power_card("musashi", "power.block_per_turn", 30)
	bm.deck_mgr.hand.append(card)
	bm.deck_mgr.current_energy = 3
	bm.play_card(card, 0)

	var powers := bm.get_all_active_powers()
	_assert(powers.has("power.block_per_turn:musashi"), "검의 깨달음 권능 등록됨 (musashi 키)")
	# 이순신 권능과 구분 — musashi 키만 있어야 함 (이순신 미사용 상태)
	_assert(not powers.has("power.block_per_turn:yi_sun_sin"), "이순신 block_per_turn 권능 없음 (키 구분 확인)")

func test_block_per_turn_musashi_trigger() -> void:
	print("[TestPowerCards] test_block_per_turn_musashi_trigger")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("musashi", 70))
	bm.team_mgr.add_hero(_make_hero("yi_sun_sin", 60))
	bm.setup_battle([_make_enemy(100)])
	bm.start_player_turn()

	var card := _make_power_card("musashi", "power.block_per_turn", 30)
	bm.deck_mgr.hand.append(card)
	bm.deck_mgr.current_energy = 3
	bm.play_card(card, 0)

	bm.start_player_turn()
	var musashi_blk: int = bm._hero_block.get("musashi", 0)
	var yi_blk: int = bm._hero_block.get("yi_sun_sin", 0)
	_assert(musashi_blk == 30, "무사시 블록 +30")
	_assert(yi_blk == 0, "이순신 블록은 0 (무사시 권능에 영향 없음)")

# ---------- 7. setup_battle() 리셋 ----------

func test_setup_battle_clears_powers() -> void:
	print("[TestPowerCards] test_setup_battle_clears_powers")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("cleopatra", 50))
	bm.setup_battle([_make_enemy(100)])
	bm.start_player_turn()

	# 권능 등록
	var card := _make_power_card("cleopatra", "power.poison_per_turn", 3)
	bm.deck_mgr.hand.append(card)
	bm.deck_mgr.current_energy = 3
	bm.play_card(card, 0)
	_assert(not bm._active_powers.is_empty(), "setup_battle 전 권능 존재")

	# 새 전투 시작
	bm.setup_battle([_make_enemy(80)])
	_assert(bm._active_powers.is_empty(), "setup_battle 후 _active_powers 초기화")
