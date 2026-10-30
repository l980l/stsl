extends RefCounted

# 덱 정체성 개편 1단계(나폴레옹 자원 정리): 사기 보상은 사기를 실제로 소비하고,
# 군단 카드는 병사를 만들거나 병사 수로 강해진다.
# 2단계(칭기즈칸 질주): 병사는 소비하지 않고 즉시 쏘며, 모든 적보다 빠르면 한 번 더 쏜다.
# 3단계(이순신 거북선/함대 분리): 병사 카드는 학익진으로, 철갑 충각은 방어를 유지한 채 방어만큼 광역 피해.
# 4단계(잔다르크 삼각 순환): 성전 공격은 아군이 실제로 회복한 양을 모든 적 피해로 바꾼다.
# 5단계(클레오파트라 저주 보상): 약화된 적 수만큼 드로우, 취약한 적을 아군이 칠 때 클레오파트라 방어.
# 6단계(시작 덱 규칙): 스트라이크·디펜드·카운터를 뺀 시작 카드가 영웅의 세 아키타입을 모두 담는다.
#   보상 화면은 아키타입과 덱 보유 장수를 보여 주고, 수치형 영웅 조합 시너지 4개는 자원 다리로 바뀐다.
# 기존 단위(×10) 수치로 검사한다.

const BM = preload("res://autoload/battle_manager.gd")
const TM = preload("res://autoload/team_manager.gd")
const DM = preload("res://autoload/deck_manager.gd")
const Hero = preload("res://resources/hero_resource.gd")
const Enemy = preload("res://resources/enemy_resource.gd")
const Intent = preload("res://resources/intent_resource.gd")
const Catalog = preload("res://resources/card_catalog.gd")
const ArchetypeTally = preload("res://resources/cards/archetype_tally.gd")
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
	_run_starters()
	_run_party_synergies()
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

# 보상 풀에서 주 태그(첫 태그)로 5장 이상 쓰이는 아키타입 = 그 영웅의 덱 방향.
func _run_starters() -> void:
	for hid in Catalog.HERO_ORDER:
		var source = Catalog._HERO_CARDS[hid]
		var counts := {}
		for card in source.pool():
			if not card.archetype.is_empty():
				var label: String = TranslationServer.translate(card.archetype[0])
				counts[label] = counts.get(label, 0) + 1
		var seen := {}
		for card in source.starter_deck():
			if card.card_name.ends_with(".strike.name") or card.card_name.ends_with(".defend.name") or card.card_name == "card.counter.name":
				continue
			for tag in card.archetype:
				seen[TranslationServer.translate(tag)] = true
		var missing: Array = []
		for label in counts:
			if counts[label] >= 5 and not seen.has(label):
				missing.append(label)
		_check(missing.is_empty(), "%s starter covers every archetype (missing %s)" % [hid, missing])
	# 보상 화면 태그: 나폴레옹 시작 덱에서 군단 카드는 참호 구축 1장(스트라이크·디펜드 제외).
	var deck: Array = Catalog._HERO_CARDS["napoleon"].starter_deck()
	var tally: Dictionary = ArchetypeTally.of(_card("imperial_artillery"), deck)
	_check(tally.get("label", "") == TranslationServer.translate("card.napoleon.trench_construction.archetype") and tally.get("owned", -1) == 1, "reward tag counts owned legion cards (got %s)" % tally)
	_check(ArchetypeTally.of(_card("imperial_artillery"), Catalog._HERO_CARDS["cleopatra"].starter_deck()).get("owned", -1) == 0, "reward tag ignores other heroes' cards")

func _party(ids: Array, enemy_count: int = 1):
	var bm = BM.new()
	bm.team_mgr = TM.new()
	bm.deck_mgr = DM.new()
	bm._test_disable_crit = true
	for hid in ids:
		var hero = Hero.new()
		hero.hero_id = hid
		hero.max_hp = 1000
		bm.team_mgr.add_hero(hero)
	var enemies: Array = []
	for i in range(enemy_count):
		var enemy = Enemy.new()
		enemy.max_hp = 5000
		enemy.signatures_enabled = false
		var intent = Intent.new()
		intent.action_type = Intent.ActionType.ATTACK
		intent.value = 100
		enemy.intent_pattern = [intent]
		enemies.append(enemy)
	bm.setup_battle(enemies)
	return bm

func _attack(owner: String, value: int) -> Resource:
	var card = load("res://resources/card_resource.gd").new()
	card.card_name = "test_attack"
	card.owner_id = owner
	card.card_type = card.CardType.ATTACK
	var eff = load("res://resources/effect_resource.gd").new()
	eff.effect_type = eff.EffectType.DAMAGE
	eff.value = value
	eff.base_value = value
	eff.target = "SINGLE"
	card.effects = [eff]
	return card

func _run_party_synergies() -> void:
	# 검사의 약속: 이순신이 무사시에게 방어 60을 옮기면 무사시 다음 공격 첫 타 +60, 한 번 쓰면 사라진다.
	var bm = _party(["yi_sun_sin", "musashi"])
	bm._hero_block["yi_sun_sin"] = 100
	bm._apply_card_effects(_card("formation_boost", "yi_sun_sin"), -1, "musashi")
	_check(bm._hero_status.get("musashi", {}).get("next_attack_first_hit_bonus", 0) == 60, "swordsman's vow banks transferred block for Musashi")
	bm._apply_card_effects(_attack("musashi", 30), 0)
	_check(5000 - bm.get_enemy_hp(0) == 90, "swordsman's vow adds the block to Musashi's first hit")
	bm._apply_card_effects(_attack("musashi", 30), 0)
	_check(5000 - bm.get_enemy_hp(0) == 120, "swordsman's vow bonus is spent once")
	_free(bm)
	bm = _party(["yi_sun_sin"])
	bm._hero_block["yi_sun_sin"] = 100
	bm._apply_card_effects(_card("formation_boost", "yi_sun_sin"), -1, "yi_sun_sin")
	_check(not bm._hero_status.get("musashi", {}).has("next_attack_first_hit_bonus"), "swordsman's vow needs Musashi and a real transfer")
	_free(bm)
	# 검사의 약속 이월: 이순신 차례 끝 남은 방어의 절반(상한 60)이 무사시 첫 타로.
	bm = _party(["yi_sun_sin", "musashi"])
	bm._hero_block["yi_sun_sin"] = 100
	bm._phase_hero_post("yi_sun_sin")
	_check(bm._hero_status.get("musashi", {}).get("next_attack_first_hit_bonus", 0) == 50, "swordsman's vow banks half of Yi's leftover block")
	bm._hero_status["musashi"].erase("next_attack_first_hit_bonus")
	bm._hero_block["yi_sun_sin"] = 400
	bm._phase_hero_post("yi_sun_sin")
	_check(bm._hero_status.get("musashi", {}).get("next_attack_first_hit_bonus", 0) == 60, "swordsman's vow bank is capped")
	_free(bm)
	# 황제의 무도(보스전): 적이 1명뿐이면 무사시 공격마다가 아니라 차례당 1회 사기 +1.
	bm = _party(["napoleon", "musashi"])
	bm._apply_card_effects(_attack("musashi", 30), 0)
	bm._apply_card_effects(_attack("musashi", 30), 0)
	_check(bm._hero_status.get("napoleon", {}).get("morale", 0) == 1, "emperor's dance grants 1 morale per Musashi turn against a lone enemy")
	_free(bm)
	# 황제의 무도: 무사시가 처치해 적이 1명 남을 때만 나폴레옹 사기 +2.
	bm = _party(["napoleon", "musashi"], 3)
	bm._current_actor_id = "hero:musashi"
	bm._deal_damage_to_enemy(0, 99999)
	_check(bm._hero_status.get("napoleon", {}).get("morale", 0) == 0, "emperor's dance waits until one enemy remains")
	bm._deal_damage_to_enemy(1, 99999)
	_check(bm._hero_status.get("napoleon", {}).get("morale", 0) == 2, "emperor's dance grants Napoleon 2 morale")
	_free(bm)
	bm = _party(["napoleon", "musashi"], 2)
	bm._current_actor_id = "hero:napoleon"
	bm._deal_damage_to_enemy(0, 99999)
	_check(bm._hero_status.get("napoleon", {}).get("morale", 0) == 0, "emperor's dance needs Musashi's kill")
	_free(bm)
	# 초원의 결투사: 무사시가 칭기즈칸 표식 적을 치면 표식을 지우고 치명타(×2) 확정, 차례당 1회.
	bm = _party(["genghis_khan", "musashi"])
	bm._enemy_status[0]["marked_by"] = ["genghis_khan"]
	bm._apply_card_effects(_attack("genghis_khan", 30), 0)
	_check(5000 - bm.get_enemy_hp(0) == 30, "steppe duelist ignores Genghis's own hit")
	bm._apply_card_effects(_attack("musashi", 30), 0)
	_check(5000 - bm.get_enemy_hp(0) == 90 and bm._enemy_status[0].get("marked_by", []).is_empty(), "steppe duelist consumes the mark for a sure crit")
	bm._enemy_status[0]["marked_by"] = ["genghis_khan"]
	bm._apply_card_effects(_attack("musashi", 30), 0)
	_check(5000 - bm.get_enemy_hp(0) == 120, "steppe duelist fires once per turn")
	_free(bm)
