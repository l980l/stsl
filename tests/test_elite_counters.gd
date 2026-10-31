extends RefCounted

# 엘리트 상성 기반(docs/game_design/elite_counter_design.md):
# 영웅 상태 지우기(방어 포함, 일부만 줄이기), 적 자기 정화(독·약화/취약·마킹), 가시.
# 같은 이름의 일반·엘리트 몬스터가 카탈로그에 둘 다 들어간다.
# 기존 단위(×10) 수치로 검사한다.

const BM = preload("res://autoload/battle_manager.gd")
const TM = preload("res://autoload/team_manager.gd")
const DM = preload("res://autoload/deck_manager.gd")
const Hero = preload("res://resources/hero_resource.gd")
const Enemy = preload("res://resources/enemy_resource.gd")
const Intent = preload("res://resources/intent_resource.gd")
const CardRes = preload("res://resources/card_resource.gd")
const EffectRes = preload("res://resources/effect_resource.gd")
const Monsters = preload("res://resources/monster_catalog.gd")
const Signatures = preload("res://autoload/enemy_signature_system.gd")
var passed := 0
var failed := 0

func _check(ok: bool, label: String) -> void:
	if ok:
		passed += 1
	else:
		failed += 1
		print("  FAIL: elite counters " + label)

func _party(ids: Array):
	var bm = BM.new()
	bm.team_mgr = TM.new()
	bm.deck_mgr = DM.new()
	bm._test_disable_crit = true
	for hid in ids:
		var hero = Hero.new()
		hero.hero_id = hid
		hero.max_hp = 1000
		bm.team_mgr.add_hero(hero)
	var enemy = Enemy.new()
	enemy.max_hp = 5000
	enemy.signatures_enabled = false
	var intent = Intent.new()
	intent.action_type = Intent.ActionType.ATTACK
	intent.value = 100
	enemy.intent_pattern = [intent]
	bm.setup_battle([enemy])
	return bm

func _free(bm) -> void:
	bm.deck_mgr.free()
	bm.team_mgr.free()
	bm.free()

func _intent(action: int, status_type: String = "", value: int = 0, target: int = Intent.TargetType.ALL) -> Resource:
	var intent = Intent.new()
	intent.action_type = action
	intent.status_type = status_type
	intent.value = value
	intent.target = target
	return intent

func _card(owner: String, card_type: int, hits: int = 1) -> Resource:
	var card = CardRes.new()
	card.card_name = "test_card"
	card.owner_id = owner
	card.card_type = card_type
	var eff = EffectRes.new()
	eff.effect_type = EffectRes.EffectType.DAMAGE
	eff.value = 30
	eff.base_value = 30
	eff.hit_count = hits
	eff.target = "SINGLE"
	card.effects = [eff]
	return card

func run_all() -> Dictionary:
	_run_dispel()
	_run_cleanse()
	_run_thorns()
	_run_catalog()
	_run_karma()
	return {"passed": passed, "failed": failed}

func _run_dispel() -> void:
	# 방어 지우기는 영웅 방어(_hero_block)를 실제로 지운다. 하데스·대일여래가 쓰는 기본 지우기(힘+방어)도 같다.
	var bm = _party(["yi_sun_sin", "napoleon"])
	bm._hero_block["yi_sun_sin"] = 120
	bm._hero_block["napoleon"] = 40
	bm._execute_intent_effects(0, _intent(Intent.ActionType.DISPEL, "block"), {})
	_check(bm._hero_block.get("yi_sun_sin", 0) == 0 and bm._hero_block.get("napoleon", 0) == 0, "dispel block clears every hero's block")
	bm._hero_block["yi_sun_sin"] = 120
	bm._apply_status_to_hero("yi_sun_sin", "strength", 3)
	bm._execute_intent_effects(0, _intent(Intent.ActionType.DISPEL), {})
	_check(bm._hero_block.get("yi_sun_sin", 0) == 0 and bm._hero_status["yi_sun_sin"].get("strength", 0) == 0, "default dispel clears strength and block")
	# 병사 지우기는 value 만큼만 줄인다. value 0 이면 전부 지운다.
	bm._apply_status_to_hero("napoleon", "tokens", 5)
	bm._execute_intent_effects(0, _intent(Intent.ActionType.DISPEL, "tokens", 2), {})
	_check(bm._hero_status["napoleon"].get("tokens", 0) == 3, "dispel tokens with value removes only that many soldiers")
	bm._execute_intent_effects(0, _intent(Intent.ActionType.DISPEL, "tokens"), {})
	_check(bm._hero_status["napoleon"].get("tokens", 0) == 0, "dispel tokens without value removes all soldiers")
	bm._apply_status_to_hero("napoleon", "morale", 4)
	bm._execute_intent_effects(0, _intent(Intent.ActionType.DISPEL, "morale"), {})
	_check(bm._hero_status["napoleon"].get("morale", 0) == 0, "dispel morale clears Napoleon's morale")
	_free(bm)

func _run_cleanse() -> void:
	var bm = _party(["cleopatra", "genghis_khan"])
	bm._apply_status_to_enemy(0, "poison", 50)
	bm._apply_status_to_enemy(0, "weak", 2)
	bm._apply_status_to_enemy(0, "vulnerable", 2)
	bm._enemy_status[0]["marked_by"] = ["genghis_khan"]
	bm._execute_intent_effects(0, _intent(Intent.ActionType.SPECIAL, "cleanse_poison"), {})
	var st: Dictionary = bm._enemy_status[0]
	_check(st.get("poison_dmg", 0) == 0 and st.get("poison_dur", 0) == 0, "cleanse poison removes the enemy's poison")
	_check(st.get("weak", 0) == 2 and st.get("vulnerable", 0) == 2 and st.get("marked_by", []).size() == 1, "cleanse poison leaves other statuses")
	bm._execute_intent_effects(0, _intent(Intent.ActionType.SPECIAL, "cleanse_debuff"), {})
	_check(st.get("weak", 0) == 0 and st.get("vulnerable", 0) == 0, "cleanse debuff removes weak and vulnerable")
	_check(st.get("marked_by", []).size() == 1, "cleanse debuff leaves marks")
	bm._execute_intent_effects(0, _intent(Intent.ActionType.SPECIAL, "cleanse_marks"), {})
	_check(st.get("marked_by", ["x"]).is_empty(), "cleanse marks removes every mark on the enemy")
	_free(bm)

func _run_thorns() -> void:
	# 가시 20: 공격 카드의 타격마다 카드 주인이 20 피해. 방어가 먼저 막는다.
	var bm = _party(["musashi", "napoleon"])
	bm._enemy_status[0]["thorns"] = 20
	bm._start_card_effects(_card("musashi", CardRes.CardType.ATTACK, 3), 0, "")
	_check(bm.team_mgr.get_current_hp("musashi") == 940, "thorns hit the attacker once per hit (3 hits x 20)")
	_check(bm._thorns_attacker == "", "thorns attacker resets after the card resolves")
	bm._hero_block["musashi"] = 30
	bm._start_card_effects(_card("musashi", CardRes.CardType.ATTACK, 2), 0, "")
	_check(bm.team_mgr.get_current_hp("musashi") == 930 and bm._hero_block.get("musashi", 0) == 0, "block absorbs thorns first")
	# 스킬 카드의 피해와 병사 공격에는 가시가 없다.
	bm._start_card_effects(_card("musashi", CardRes.CardType.SKILL), 0, "")
	_check(bm.team_mgr.get_current_hp("musashi") == 930, "skill card damage does not trigger thorns")
	bm._apply_status_to_hero("napoleon", "tokens", 2)
	bm._fire_token("napoleon", 0)
	bm._fire_token("napoleon", 1)
	_check(bm.team_mgr.get_current_hp("napoleon") == 1000, "soldier attacks do not trigger thorns")
	_free(bm)

func _run_catalog() -> void:
	# 일반 케르베로스와 2막 엘리트 케르베로스는 이름이 같아도 둘 다 카탈로그에 있다.
	var grades: Array = []
	for enemy in Monsters.get_all_monsters():
		if enemy.enemy_name == "enemy.greek.cerberus":
			grades.append(int(enemy.grade))
	grades.sort()
	_check(grades == [Enemy.Grade.NORMAL, Enemy.Grade.ELITE], "catalog keeps normal and elite Cerberus")

func _run_karma() -> void:
	# 인과응보는 받은 피해 25%를 반사하지만 영웅 체력을 1 아래로 내리지 않는다(이긴 전투를 뒤집지 않음).
	var bm = _party(["joan_of_arc", "napoleon"])
	bm._enemies[0].mythology = "buddhist"
	bm._enemies[0].signatures_enabled = true
	bm._enemy_status[0]["damage_taken"] = 4000
	bm.team_mgr._hero_hp["joan_of_arc"] = 300
	bm._hero_block["napoleon"] = 200
	Signatures.on_enemy_death(bm, 0)
	_check(bm.team_mgr.get_current_hp("joan_of_arc") == 1, "karma leaves a wounded hero at 1 HP")
	_check(bm.team_mgr.get_current_hp("napoleon") == 200, "karma still deals damage past block when survivable (1000 - 800)")
	_free(bm)
