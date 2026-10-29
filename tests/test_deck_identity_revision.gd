extends RefCounted

# 덱 정체성 개편 1단계(나폴레옹 자원 정리): 사기 보상은 사기를 실제로 소비하고,
# 군단 카드는 병사를 만들거나 병사 수로 강해진다.
# 2단계(칭기즈칸 질주): 병사는 소비하지 않고 즉시 쏘며, 모든 적보다 빠르면 한 번 더 쏜다.
# 3단계(이순신 거북선/함대 분리): 병사 카드는 학익진으로, 철갑 충각은 방어를 유지한 채 방어만큼 광역 피해.
# 4단계(잔다르크 삼각 순환): 성전 공격은 아군이 실제로 회복한 양을 모든 적 피해로 바꾼다.
# 5단계(클레오파트라 저주 보상): 약화된 적 수만큼 드로우, 취약한 적을 아군이 칠 때 클레오파트라 방어.
# 기존 단위(×10) 수치로 검사한다.

const BM = preload("res://autoload/battle_manager.gd")
const TM = preload("res://autoload/team_manager.gd")
const DM = preload("res://autoload/deck_manager.gd")
const Hero = preload("res://resources/hero_resource.gd")
const Enemy = preload("res://resources/enemy_resource.gd")
const Intent = preload("res://resources/intent_resource.gd")
const Catalog = preload("res://resources/card_catalog.gd")
var passed := 0
var failed := 0

func _check(ok: bool, label: String) -> void:
	if ok:
		passed += 1
	else:
		failed += 1
		print("  FAIL: deck identity " + label)

func _battle(hero_id: String = "napoleon", enemy_speed: int = 0):
	var bm = BM.new()
	bm.team_mgr = TM.new()
	bm.deck_mgr = DM.new()
	bm._test_disable_crit = true
	var hero = Hero.new()
	hero.hero_id = hero_id
	hero.max_hp = 1000
	bm.team_mgr.add_hero(hero)
	var enemy = Enemy.new()
	enemy.max_hp = 5000
	enemy.signatures_enabled = false
	enemy.speed = enemy_speed
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

func _card(key: String, hero_id: String = "napoleon") -> Resource:
	for card in Catalog.get_all_cards():
		if card.card_name == "card.%s.%s.name" % [hero_id, key]:
			return card.duplicate(true)
	return null

# 사기 morale 으로 카드를 낸 뒤 (적이 잃은 HP, 남은 사기, 방어) 를 돌려준다.
func _play(key: String, morale: int, tokens: int = 0) -> Dictionary:
	var bm = _battle()
	bm._hero_status["napoleon"] = {"morale": morale, "tokens": tokens}
	bm._apply_card_effects(_card(key), 0)
	var out := {"damage": 5000 - bm.get_enemy_hp(0), "morale": bm._hero_status["napoleon"].get("morale", 0), "block": bm._hero_block.get("napoleon", 0), "tokens": bm._hero_status["napoleon"].get("tokens", 0), "vulnerable": bm._enemy_status[0].get("vulnerable", 0)}
	_free(bm)
	return out

func run_all() -> Dictionary:
	for key in ["one_man_army", "emperors_assault", "borodino_bombardment", "trench_construction", "imperial_artillery"]:
		_check(_card(key) != null and _card(key).has_meta("deck_identity_revision"), key + " revised")
	var r := _play("one_man_army", 1)
	_check(r.damage == 160 and r.morale == 0, "one man army spends 1 morale for 16")
	r = _play("one_man_army", 0)
	_check(r.damage == 60, "one man army without morale deals 6 and no extra hit")
	r = _play("emperors_assault", 3)
	_check(r.damage == 340 and r.morale == 1 and r.block == 100, "emperors assault spends 2 for 34 instead of adding base damage")
	r = _play("emperors_assault", 1)
	_check(r.damage == 160 and r.morale == 1, "emperors assault keeps morale it cannot fully pay")
	r = _play("borodino_bombardment", 2)
	_check(r.damage == 300 and r.morale == 1, "borodino now consumes 1 morale")
	r = _play("trench_construction", 0)
	_check(r.block == 50 and r.tokens == 1 and r.morale == 0, "trench recruits a soldier instead of morale")
	r = _play("imperial_artillery", 0, 3)
	_check(r.damage == 80 and r.vulnerable == 1, "artillery adds 1 per living soldier")
	r = _play("imperial_artillery", 0, 0)
	_check(r.damage == 50, "artillery without soldiers deals base damage")
	_run_genghis()
	_run_yi()
	_run_joan()
	_run_cleopatra()
	return {"passed": passed, "failed": failed}

# 토큰 일제 사격: 모든 적 40 + 병사 수 x 25, 적보다 빠르면 병사가 한 번 더 쏜다.
func _volley(tokens: int, enemy_speed: int) -> Dictionary:
	var bm = _battle("genghis_khan", enemy_speed)
	bm._hero_status["genghis_khan"] = {"tokens": tokens}
	bm._apply_card_effects(_card("horde_volley", "genghis_khan"), 0)
	var out := {"damage": 5000 - bm.get_enemy_hp(0), "tokens": bm._hero_status["genghis_khan"].get("tokens", 0)}
	_free(bm)
	return out

func _run_genghis() -> void:
	for key in ["horde_volley", "khans_banner", "war_horse_power"]:
		_check(_card(key, "genghis_khan") != null and _card(key, "genghis_khan").has_meta("deck_identity_revision"), key + " revised")
	var sprint = _card("cavalry_charge_speed", "genghis_khan")
	_check(sprint.archetype == ["card.genghis_khan.cavalry_summon.archetype"], "sprint order joins the cavalry deck")
	var r := _volley(3, 0)
	_check(r.damage == 40 + 2 * 3 * 25 and r.tokens == 3, "volley fires soldiers twice when faster and keeps them")
	r = _volley(3, 99)
	_check(r.damage == 40 + 3 * 25 and r.tokens == 3, "volley fires soldiers once when an enemy is faster")
	r = _volley(0, 0)
	_check(r.damage == 40, "volley without soldiers deals only its area damage")
	var bm = _battle("genghis_khan")
	bm._apply_card_effects(_card("khans_banner", "genghis_khan"), 0)
	bm._fire_token("genghis_khan", 0)
	_check(5000 - bm.get_enemy_hp(0) == 25 + 10, "banner adds 10 to every soldier attack")
	_free(bm)
	bm = _battle("genghis_khan")
	var before: int = bm._hero_effective_speed("genghis_khan")
	bm._apply_card_effects(_card("war_horse_power", "genghis_khan"), 0)
	_check(bm._hero_effective_speed("genghis_khan") == before + 8, "war horse power grants permanent speed 8")
	_check(bm._active_powers.has("power.summon_per_turn:genghis_khan"), "war horse power keeps soldier summoning")
	_free(bm)

func _run_yi() -> void:
	for key in ["naval_muster", "volley_fire", "fleet_fire"]:
		var card = _card(key, "yi_sun_sin")
		_check(card != null and TranslationServer.translate(card.archetype[0]) == TranslationServer.translate("card.yi_sun_sin.formation_bond.archetype"), key + " joins the formation fleet")
	var ram = _card("iron_ram", "yi_sun_sin")
	_check(ram != null and ram.has_meta("deck_identity_revision") and ram.is_exhaust, "iron ram revised and still exhausts")
	var bm = _battle("yi_sun_sin")
	bm._hero_block["yi_sun_sin"] = 240
	bm._apply_card_effects(ram, 0)
	_check(5000 - bm.get_enemy_hp(0) == 240 and bm._hero_block.get("yi_sun_sin", 0) == 240, "iron ram deals current block to all and keeps it")
	_free(bm)

func _run_joan() -> void:
	var wrath = _card("archangels_wrath", "joan_of_arc")
	var fury = _card("holy_fury", "joan_of_arc")
	_check(wrath.has_meta("deck_identity_revision") and fury.has_meta("deck_identity_revision"), "crusade payoffs revised")
	# 대천사의 분노: 회복 20 이 먼저 적용되고(체력이 깎인 잔다르크 20 회복), 피해 60 + 이번 차례 회복의 50%.
	var bm = _battle("joan_of_arc")
	bm.team_mgr.take_damage("joan_of_arc", 300)
	bm._team_healed_turn = 100
	bm._apply_card_effects(wrath, 0)
	_check(5000 - bm.get_enemy_hp(0) == 60 + (100 + 20) / 2, "archangel's wrath adds half of this turn's healing")
	_free(bm)
	# 체력이 가득 차면 실제 회복은 0 — 넘친 회복은 세지 않는다.
	bm = _battle("joan_of_arc")
	bm._apply_card_effects(wrath, 0)
	_check(5000 - bm.get_enemy_hp(0) == 60, "overheal does not count as healing")
	_free(bm)
	bm = _battle("joan_of_arc")
	bm._team_healed_battle = 200
	bm._apply_card_effects(fury, 0)
	_check(5000 - bm.get_enemy_hp(0) == 80 + 60, "holy fury adds 30% of battle healing")
	bm._team_healed_battle = 5000
	var before: int = bm.get_enemy_hp(0)
	bm._apply_card_effects(fury, 0)
	_check(before - bm.get_enemy_hp(0) == 80 + 150, "holy fury bonus is capped")
	_free(bm)

func _run_cleopatra() -> void:
	var recipe = _card("desert_recipe", "cleopatra")
	var shield = _card("ramesses_shield", "cleopatra")
	_check(recipe.has_meta("deck_identity_revision") and recipe.cost == 1 and shield.has_meta("deck_identity_revision"), "curse payoffs revised")
	# 약화된 적 1명 → 1 + 1 장. 손패 변화량으로 검사.
	var bm = _battle("cleopatra")
	var drawn := _recipe_draw(bm, recipe, 1)
	_check(drawn == 2, "desert recipe draws 1 + 1 per weakened enemy (drew %d)" % drawn)
	_free(bm)
	bm = _battle("cleopatra")
	drawn = _recipe_draw(bm, recipe, 0)
	_check(drawn == 1, "desert recipe without weak draws 1 (drew %d)" % drawn)
	_free(bm)
	bm = _battle("cleopatra")
	bm._apply_card_effects(shield, 0)
	bm._current_actor_id = "hero:cleopatra"
	bm._enemy_status[0]["vulnerable"] = 2
	var block_before: int = bm._hero_block.get("cleopatra", 0)
	for i in range(5):
		bm._deal_damage_to_enemy(0, 10)
	_check(bm._hero_block.get("cleopatra", 0) - block_before == 3 * 20, "ramesses shield guards on vulnerable hits, three per turn")
	bm._enemy_status[0]["vulnerable"] = 0
	bm._vulnerable_guard_hits = 0
	block_before = bm._hero_block.get("cleopatra", 0)
	bm._deal_damage_to_enemy(0, 10)
	_check(bm._hero_block.get("cleopatra", 0) == block_before, "no guard without vulnerable")
	_free(bm)

func _recipe_draw(bm, recipe: Resource, weak: int) -> int:
	if not bm.deck_mgr._heroes.has("cleopatra"):
		bm.deck_mgr._heroes["cleopatra"] = {"draw": [], "hand": [], "discard": [], "exhaust": [], "draws_this_turn": 0}
	var entry: Dictionary = bm.deck_mgr._heroes["cleopatra"]
	for i in range(6):
		(entry["draw"] as Array).append(_card("desert_recipe", "cleopatra"))
	bm._enemy_status[0]["weak"] = weak
	var before: int = (entry["hand"] as Array).size()
	bm._apply_card_effects(recipe, 0)
	return (entry["hand"] as Array).size() - before
