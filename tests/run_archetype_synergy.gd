extends SceneTree

# Focused production-rule regression checks for the 36-card archetype revision.
# These deliberately exercise BattleManager, rather than duplicating rule logic
# in the test, so a data/UI-looking change cannot silently break runtime play.

const Catalog = preload("res://resources/card_catalog.gd")
const Profile = preload("res://resources/balance/small_number_profile.gd")
const GM = preload("res://autoload/game_manager.gd")
const Fixture = preload("res://tests/test_card_revision_runtime.gd")

var passed := 0
var failed := 0
var results: Array = []
var cards: Dictionary = {}

func _init() -> void:
	call_deferred("_run")

func _check(ok: bool, label: String, details: Dictionary = {}) -> void:
	results.append({"label": label, "ok": ok, "details": details})
	if ok:
		passed += 1
	else:
		failed += 1
		push_error("ARCHETYPE SYNERGY: " + label + " " + JSON.stringify(details))

func _run() -> void:
	AudioServer.set_bus_mute(0, true)
	_prepare_live_cards()
	_test_data_contract()
	await _test_napoleon()
	await _test_cleopatra()
	await _test_yi()
	await _test_joan()
	await _test_genghis()
	await _test_musashi()
	await _test_boundaries()
	await _test_smoke_matrix()
	_test_old_save_restore()
	_write_report()
	print("ARCHETYPE SYNERGY: %d passed, %d failed" % [passed, failed])
	quit(1 if failed else 0)

func _prepare_live_cards() -> void:
	# Build the authored source with the legacy switch, then generate the exact
	# live card pair used by runtime. This prevents a candidate card from being
	# rounded a second time in the fixture.
	OS.set_environment("STSL_LEGACY_COMBAT", "1")
	var gm := GM.new()
	for source in Catalog.get_all_cards():
		var pair: Dictionary = Profile.candidate_pair(source, gm)
		var legacy_upgraded: Resource = source.duplicate(true)
		gm.upgrade_card(legacy_upgraded)
		cards[source.card_name] = {"base": pair.base, "upgraded": pair.upgraded, "legacy": source.duplicate(true), "legacy_upgraded": legacy_upgraded, "unsupported": pair.unsupported_fields}
	gm.free()
	OS.set_environment("STSL_LEGACY_COMBAT", "0")

func _card(name: String, upgraded: bool = false) -> Resource:
	return cards[name]["upgraded" if upgraded else "base"].duplicate(true)

func _battle(ids: Array, enemy_count: int = 1) -> Dictionary:
	# Fixture intentionally starts at authored (large) units. Convert only after
	# setup, mirroring the live profile while keeping this test deterministic.
	var fixture := Fixture.new()
	var bm = fixture._battle(ids, enemy_count)
	bm.combat_unit_divisor = 10
	bm.turn_interval = 0.0
	for hero in bm.team_mgr.heroes:
		hero.max_hp = 100
		bm.team_mgr._hero_hp[hero.hero_id] = 100
		bm._hero_status[hero.hero_id] = {}
	for i in range(enemy_count):
		bm._enemies[i].max_hp = 500
		bm._enemy_hp[i] = 500
	return {"fixture": fixture, "bm": bm}

func _free(ctx: Dictionary) -> void:
	ctx.fixture._free(ctx.bm)

func _apply(bm, card: Resource, target: int = 0, ally: String = "") -> void:
	await bm._apply_card_effects(card, target, ally)

func _draw_filler(owner: String, count: int) -> Array:
	var out: Array = []
	for i in range(count):
		var c := _card("card.%s.defend.name" % owner)
		out.append(c)
	return out

func _test_data_contract() -> void:
	var revised: Array = []
	for name in cards:
		var c: Resource = cards[name].base
		if c.has_meta("archetype_synergy_revision"):
			revised.append(name)
			_check(c.has_explicit_upgrade and Profile.is_upgrade_meaningful(c, cards[name].upgraded), "explicit meaningful upgrade " + name)
			_check((cards[name].unsupported as Array).is_empty(), "supported numeric parameters " + name, {"unsupported": cards[name].unsupported})
	_check(revised.size() == 36, "exactly 36 revised cards", {"actual": revised.size()})
	_check(Catalog.get_all_cards().size() == 216, "catalog remains 216")
	var pool_count := 0
	var starter_keys: Dictionary = {}
	for source in [
		preload("res://resources/cards/cards_napoleon.gd"), preload("res://resources/cards/cards_cleopatra.gd"),
		preload("res://resources/cards/cards_yi_sun_sin.gd"), preload("res://resources/cards/cards_joan_of_arc.gd"),
		preload("res://resources/cards/cards_genghis_khan.gd"), preload("res://resources/cards/cards_musashi.gd")]:
		var pool: Array = source.pool()
		pool_count += pool.size()
		var starters: Array = source.starter_deck()
		_check(starters.size() == 10, "starter deck stays at ten cards")
		var pool_names: Array = pool.map(func(card: Resource) -> String: return card.card_name)
		for starter in starters:
			starter_keys[starter.owner_id + "|" + starter.card_name] = true
			# 시작 덱에 넣은 보상 카드(예: 이판사판)는 보상 풀과 같은 개편 효과를 쓴다.
			if starter.card_name in pool_names:
				continue
			_check(not starter.has_meta("archetype_synergy_revision"), "starter effect preserved " + starter.owner_id + "/" + starter.card_name)
	_check(pool_count == 189, "reward pool remains 189", {"actual": pool_count})

func _test_napoleon() -> void:
	var ctx: Dictionary = _battle(["napoleon"], 1); var bm: Node = ctx.bm
	bm._enemy_hp[0] = 5
	await _apply(bm, _card("card.napoleon.cavalry_threat.name"))
	_check(bm._hero_status["napoleon"].get("morale", 0) == 0, "cavalry threat grants no morale on kill")
	bm._enemy_alive[0] = true; bm._enemy_hp[0] = 100
	await _apply(bm, _card("card.napoleon.cavalry_threat.name"))
	_check(bm._hero_status["napoleon"].get("morale", 0) == 1, "cavalry threat grants morale only when target survives")
	bm._hero_status["napoleon"]["morale"] = 2
	await _apply(bm, _card("card.napoleon.arcole_breakthrough.name"))
	_check(bm.get_hero_block("napoleon") == 8 and bm._hero_status["napoleon"].morale == 0, "morale resource block consumes capped morale")
	bm._hero_status["napoleon"]["tokens"] = 6
	bm.deck_mgr._heroes["napoleon"]["draw"].append_array(_draw_filler("napoleon", 2))
	await _apply(bm, _card("card.napoleon.artillery_gather.name"))
	_check(bm.deck_mgr.get_hand("napoleon").size() == 2 and bm._hero_status["napoleon"].tokens == 6, "recruit draws only at token cap")
	bm._hero_status["napoleon"]["tokens"] = 0
	await _apply(bm, _card("card.napoleon.artillery_gather.name"))
	_check(bm._hero_status["napoleon"].tokens == 1, "recruit adds one token below cap")
	bm._hero_status["napoleon"]["morale"] = 1
	await _apply(bm, _card("card.napoleon.charge_bugle.name"))
	var attack: Resource = _card("card.napoleon.cavalry_threat.name")
	_check(bm.deck_mgr.get_effective_cost("napoleon", attack) == 0 and bm._hero_status["napoleon"].morale == 1, "bugle spends existing morale before gaining its own")
	_free(ctx)

func _test_cleopatra() -> void:
	var ctx: Dictionary = _battle(["cleopatra"], 2); var bm: Node = ctx.bm
	await _apply(bm, _card("card.cleopatra.poison_seed.name"), 0)
	_check(bm._enemy_status[0].poison_dmg == 2 and bm._enemy_status[1].get("poison_dmg", 0) == 0, "poison seed starts a target")
	await _apply(bm, _card("card.cleopatra.poison_seed.name"), 0)
	_check(bm._enemy_status[1].poison_dmg == 1, "poison seed spreads only from an existing poison target")
	bm._enemy_block[0] = 99
	var hp: int = bm.get_enemy_hp(0)
	await _apply(bm, _card("card.cleopatra.poison_party.name"), 0)
	_check(bm.get_enemy_hp(0) == hp - 2 and bm._enemy_status[0].poison_dur == 2, "poison party tick bypasses block and decrements duration")
	bm._enemy_status[0]["weak"] = 1
	await _apply(bm, _card("card.cleopatra.snake_gaze.name"), 0)
	_check(bm._enemy_status[0].get("vulnerable", 0) == 2, "curse weave uses prior weak state to add vulnerable")
	var filler: Resource = _draw_filler("cleopatra", 1)[0]
	bm.deck_mgr._heroes["cleopatra"]["draw"].append(filler)
	await _apply(bm, _card("card.cleopatra.snake_gaze.name"), 0)
	_check(bm.deck_mgr.get_hand("cleopatra").has(filler), "curse weave draws only when both prior curses exist")
	bm._enemy_status[0]["weak"] = 1; bm._enemy_status[0]["vulnerable"] = 1
	bm._enemy_block[0] = 0
	var fury: Resource = _card("card.cleopatra.pharaoh_fury.name")
	var expected: int = bm._estimate_card_damage(fury, 0).get(0, 0)
	hp = bm.get_enemy_hp(0)
	await _apply(bm, fury, 0)
	_check(hp - bm.get_enemy_hp(0) == expected and bm._enemy_status[0].weak == 0 and bm._enemy_status[0].vulnerable == 0, "debuff cash spends before damage and preview matches")
	bm._enemy_status[0]["charm"] = 8
	await _apply(bm, _card("card.cleopatra.charming_perfume.name"), 0)
	_check(bm._enemy_status[0].get("enthrall", 0) == 1 and bm._enemy_status[0].get("charm", 0) == 0, "perfume enthrall resets charm before charm cash")
	_free(ctx)

func _test_yi() -> void:
	var ctx: Dictionary = _battle(["yi_sun_sin", "napoleon"], 1); var bm: Node = ctx.bm
	bm._hero_block["yi_sun_sin"] = 6
	await _apply(bm, _card("card.yi_sun_sin.charge_stance.name"), 0)
	_check(bm.get_hero_block("yi_sun_sin") == 3, "charge stance consumes own block only once")
	bm._hero_block["yi_sun_sin"] = 6
	await _apply(bm, _card("card.yi_sun_sin.formation_boost.name"), 0, "napoleon")
	_check(bm.get_hero_block("yi_sun_sin") == 0 and bm.get_hero_block("napoleon") == 10, "block transfer conserves moved block plus base")
	bm._hero_block["yi_sun_sin"] = 5; bm._hero_block["napoleon"] = 0
	await _apply(bm, _card("card.yi_sun_sin.naval_training.name"), 0)
	_check(bm._hero_status["yi_sun_sin"].get("morale", 0) >= 1 and bm.get_hero_block("napoleon") == 4, "formation drill turns held block into morale and grants empty ally block")
	bm._hero_block["yi_sun_sin"] = 5
	await _apply(bm, _card("card.yi_sun_sin.consecutive_defense.name"), 0)
	var attack: Resource = _card("card.yi_sun_sin.charge_stance.name")
	_check(bm.deck_mgr.get_effective_cost("yi_sun_sin", attack) == 0, "guard discount reads block before its own block effect")
	_free(ctx)

func _test_joan() -> void:
	var ctx: Dictionary = _battle(["joan_of_arc", "napoleon"], 1); var bm: Node = ctx.bm
	bm.team_mgr._hero_hp["napoleon"] = 98
	await _apply(bm, _card("card.joan_of_arc.holy_touch.name"), 0, "napoleon")
	_check(bm.team_mgr.get_current_hp("napoleon") == 100 and bm.get_hero_block("napoleon") == 4, "overflow converts only actual overheal to block")
	bm._hero_status["napoleon"]["heal_block"] = 1
	await _apply(bm, _card("card.joan_of_arc.holy_touch.name"), 0, "napoleon")
	_check(bm.get_hero_block("napoleon") == 4, "overflow grants no block when heal is blocked")
	bm._hero_block["napoleon"] = 4
	var draw: Resource = _draw_filler("joan_of_arc", 1)[0]; bm.deck_mgr._heroes["joan_of_arc"]["draw"].append(draw)
	await _apply(bm, _card("card.joan_of_arc.communion.name"), 0, "napoleon")
	_check(bm.get_hero_block("napoleon") == 0 and bm.deck_mgr.get_hand("joan_of_arc").has(draw), "communion consumes chosen ally block and draws for owner")
	bm._hero_status["joan_of_arc"]["sacrifice_bank"] = 5
	await _apply(bm, _card("card.joan_of_arc.martyrdom_steps.name"))
	_check(bm._hero_status["joan_of_arc"].sacrifice_bank == 0, "bank draw refunds partial bank without bonus")
	_free(ctx)

func _test_genghis() -> void:
	var ctx: Dictionary = _battle(["genghis_khan"], 2); var bm: Node = ctx.bm
	bm.deck_mgr._heroes["genghis_khan"]["cards_played_this_turn"] = 1
	await _apply(bm, _card("card.genghis_khan.cavalry_crossing.name"))
	var energy: int = bm.deck_mgr.get_energy("genghis_khan")
	await _apply(bm, _card("card.genghis_khan.cavalry_crossing.name"))
	_check(energy == 1 and bm.deck_mgr.get_energy("genghis_khan") == 1, "combo energy fires once per owner turn")
	var scout: Resource = _card("card.genghis_khan.loot.name")
	var d1 := _draw_filler("genghis_khan", 3); bm.deck_mgr._heroes["genghis_khan"]["draw"].append_array(d1)
	await _apply(bm, scout, 0)
	await _apply(bm, scout, 0)
	_check(bm._enemy_status[0].marked_by.is_empty() and bm.deck_mgr.get_hand("genghis_khan").size() == 3, "scout marks then cashes only its own mark once")
	_free(ctx)

func _test_musashi() -> void:
	var ctx: Dictionary = _battle(["musashi"], 1); var bm: Node = ctx.bm
	await _apply(bm, _card("card.musashi.courage.name"), 0)
	var hp: int = bm.get_enemy_hp(0)
	await _apply(bm, _card("card.musashi.niten_slash.name"), 0)
	_check(hp - bm.get_enemy_hp(0) == 13, "niten bonus applies only to next attack first hit")
	bm._hero_block["musashi"] = 4; hp = bm.get_enemy_hp(0)
	var whirl: Resource = _card("card.musashi.whirlwind_cut.name")
	var preview: int = bm._estimate_card_damage(whirl, 0).get(0, 0)
	await _apply(bm, whirl, 0)
	_check(bm.get_hero_block("musashi") == 0 and hp - bm.get_enemy_hp(0) == preview + 3, "block multi-hit spends once, formula plus previous niten first-hit reservation matches")
	bm._enemy_status[0]["weak"] = 1
	hp = bm.get_enemy_hp(0)
	await _apply(bm, _card("card.musashi.single_cut.name"), 0)
	_check(hp - bm.get_enemy_hp(0) == 28 and bm._enemy_status[0].weak == 0, "duel single-enemy branch consumes weak")
	_free(ctx)
	ctx = _battle(["musashi"], 2); bm = ctx.bm
	bm._enemy_status[0]["weak"] = 1; hp = bm.get_enemy_hp(0)
	await _apply(bm, _card("card.musashi.single_cut.name"), 0)
	_check(hp - bm.get_enemy_hp(0) == 16 and bm._enemy_status[0].weak == 1, "duel multi-enemy branch does not consume weak")
	bm.deck_mgr._heroes["musashi"]["hand"].clear()
	var reload := _card("card.musashi.empty_state.name")
	bm.deck_mgr._heroes["musashi"]["draw"].append_array(_draw_filler("musashi", 2))
	await _apply(bm, reload)
	_check(bm.get_hero_block("musashi") == 7 and bm.deck_mgr.get_hand("musashi").size() == 2, "empty reload sees post-play empty hand")
	_free(ctx)
	ctx = _battle(["yi_sun_sin", "napoleon"], 1); bm = ctx.bm
	bm.team_mgr._hero_hp["yi_sun_sin"] = 3
	bm._active_powers["power.echo_next_attack:yi_sun_sin"] = {"value": 1, "params": {}}
	hp = bm.get_enemy_hp(0)
	await _apply(bm, _card("card.yi_sun_sin.all_in.name"), 0)
	_check(not bm.team_mgr.is_alive("yi_sun_sin") and bm.get_enemy_hp(0) == hp and bm._active_powers.has("power.echo_next_attack:yi_sun_sin"), "fatal all-in stops damage and does not replay echo while another hero lives")
	_free(ctx)

func _open_turn(bm: Node, owner: String, hand: Array) -> void:
	bm.is_battle_active = true
	bm.is_player_turn = true
	bm._current_actor_id = "hero:" + owner
	bm.deck_mgr._heroes[owner].hand.assign(hand)
	bm.deck_mgr._heroes[owner].energy = 5

func _test_boundaries() -> void:
	# Actual paid play, including removal from hand and optional discard modal.
	var ctx := _battle(["napoleon"]); var bm: Node = ctx.bm
	var reform := _card("card.napoleon.line_reform.name")
	var filler: Resource = _draw_filler("napoleon", 1)[0]
	_open_turn(bm, "napoleon", [reform, filler])
	bm.deck_mgr._heroes.napoleon.draw.assign(_draw_filler("napoleon", 4))
	_check(bm.play_card(reform, 0), "reform is playable")
	bm.resolve_pending_discard_pick(null)
	_check(bm.deck_mgr.get_hand("napoleon").size() == 1 and bm.deck_mgr.get_energy("napoleon") == 5, "skip discard grants neither draw nor energy")
	reform = _card("card.napoleon.line_reform.name")
	bm.deck_mgr.get_hand("napoleon").append(reform)
	_check(bm.play_card(reform, 0), "second reform requests a valid pick")
	bm.resolve_pending_discard_pick(filler)
	_check(bm.deck_mgr.get_hand("napoleon").size() == 2 and bm.deck_mgr.get_energy("napoleon") == 5, "actual discard draws two without legacy energy refund")
	bm.deck_mgr.get_hand("napoleon").clear()
	await _apply(bm, _card("card.napoleon.line_reform.name"))
	_check(bm.deck_mgr.get_hand("napoleon").is_empty(), "empty hand cannot self-fund optional discard")
	_free(ctx)
	# A/B order produces distinct resources through real play, not an invented score.
	var order_states: Array = []
	for reverse in [false, true]:
		ctx = _battle(["napoleon"]); bm = ctx.bm
		var threat := _card("card.napoleon.cavalry_threat.name")
		var bugle := _card("card.napoleon.charge_bugle.name")
		_open_turn(bm, "napoleon", [threat, bugle])
		var sequence := [bugle, threat] if reverse else [threat, bugle]
		for card in sequence:
			_check(bm.play_card(card, 0), "paid order probe")
		order_states.append({"cost": bm.deck_mgr.get_effective_cost("napoleon", threat), "morale": bm._hero_status.napoleon.get("morale", 0)})
		_free(ctx)
	_check(order_states[0].cost == 0 and order_states[1].cost == 1 and order_states[0].morale != order_states[1].morale, "threat/bugle order changes next attack cost versus stored morale", {"states": order_states})
	ctx = _battle(["yi_sun_sin", "napoleon"]); bm = ctx.bm
	await _apply(bm, _card("card.yi_sun_sin.consecutive_defense.name"))
	_check(bm.deck_mgr.get_effective_cost("yi_sun_sin", _card("card.yi_sun_sin.charge_stance.name")) == 1, "guard cannot satisfy its own pre-block gate")
	bm._hero_block.yi_sun_sin = 6
	await _apply(bm, _card("card.yi_sun_sin.formation_boost.name"), 0, "yi_sun_sin")
	_check(bm.get_hero_block("yi_sun_sin") == 10, "self transfer adds only base, not a duplicated six block")
	bm.team_mgr.take_damage("napoleon", 100)
	await _apply(bm, _card("card.yi_sun_sin.formation_boost.name"), 0, "napoleon")
	_check(bm.get_hero_block("yi_sun_sin") == 10 and bm.get_hero_block("napoleon") == 0, "dead recipient cannot consume source block")
	_free(ctx)
	ctx = _battle(["joan_of_arc", "napoleon"]); bm = ctx.bm
	for bank in [0, 3, 5]:
		bm._hero_status.joan_of_arc["sacrifice_bank"] = bank
		bm.deck_mgr.get_hand("joan_of_arc").clear()
		bm.deck_mgr._heroes.joan_of_arc.draw.assign(_draw_filler("joan_of_arc", 4))
		await _apply(bm, _card("card.joan_of_arc.martyrdom_steps.name"))
		_check(bm.deck_mgr.get_hand("joan_of_arc").size() == (3 if bank == 5 else 1) and bm._hero_status.joan_of_arc.sacrifice_bank == 0, "bank draw full versus partial payment " + str(bank))
	bm.team_mgr.take_damage("napoleon", 100)
	await _apply(bm, _card("card.joan_of_arc.holy_touch.name"), 0, "napoleon")
	_check(not bm.team_mgr.is_alive("napoleon") and bm.get_hero_block("napoleon") == 0, "overflow cannot revive or shield dead recipient")
	_free(ctx)
	ctx = _battle(["genghis_khan", "napoleon"], 2); bm = ctx.bm
	bm._enemy_status[0]["marked_by"] = ["napoleon", "genghis_khan"]
	var hp: int = bm.get_enemy_hp(0)
	var other_hp: int = bm.get_enemy_hp(1)
	await _apply(bm, _card("card.genghis_khan.war_tribute.name"))
	_check(bm._enemy_status[0].marked_by == ["napoleon"] and hp - bm.get_enemy_hp(0) == 10 and other_hp - bm.get_enemy_hp(1) == 6, "tribute consumes only own mark and still hits unmarked enemies")
	bm.deck_mgr._heroes.genghis_khan.cards_played_this_turn = 3
	await _apply(bm, _card("card.genghis_khan.cavalry_crossing.name"))
	await _apply(bm, _card("card.genghis_khan.cavalry_crossing.name"))
	_check(bm.deck_mgr.get_energy("genghis_khan") == 2, "third-card energy cannot refund twice through copies")
	_free(ctx)
	ctx = _battle(["musashi"]); bm = ctx.bm
	bm._hero_block.musashi = 4
	bm._active_powers["power.bonus_per_hit:musashi"] = {"value": 2, "owner_id": "musashi", "params": {}}
	bm._active_powers["power.every_nth_attack_bonus:musashi"] = {"value": 7, "owner_id": "musashi", "params": {"bonus_value": 2}}
	hp = bm.get_enemy_hp(0)
	await _apply(bm, _card("card.musashi.whirlwind_cut.name"))
	_check(hp - bm.get_enemy_hp(0) == 18, "whirlwind keeps separate per-hit power on both hits")
	hp = bm.get_enemy_hp(0)
	await _apply(bm, _card("card.musashi.whirlwind_cut.name"))
	_check(hp - bm.get_enemy_hp(0) == 17, "rhythm counts one damage effect, not two hits")
	bm._active_powers["power.echo_next_attack:musashi"] = {"value": 1, "owner_id": "musashi", "params": {}}
	hp = bm.get_enemy_hp(0)
	await _apply(bm, _card("card.musashi.whirlwind_cut.name"))
	_check(hp - bm.get_enemy_hp(0) == 20 and bm._active_powers["power.every_nth_attack_bonus:musashi"].params.count == 1, "echo retains per-hit power without a second rhythm count")
	_free(ctx)

func _test_smoke_matrix() -> void:
	var executed := 0
	for name in cards:
		if not cards[name].base.has_meta("archetype_synergy_revision"):
			continue
		for live in [false, true]:
			for upgraded in [false, true]:
				var card: Resource = cards[name][("upgraded" if upgraded else "base") if live else ("legacy_upgraded" if upgraded else "legacy")].duplicate(true)
				var owner: String = card.owner_id
				var ally := "napoleon" if owner != "napoleon" else "yi_sun_sin"
				var ctx := _battle([owner, ally], 3); var bm: Node = ctx.bm
				var scale := 1 if live else 10
				OS.set_environment("STSL_LEGACY_COMBAT", "0" if live else "1")
				bm.combat_unit_divisor = 10 if live else 1
				for hero in bm.team_mgr.heroes:
					hero.max_hp = 100 * scale
					bm.team_mgr._hero_hp[hero.hero_id] = 70 * scale
				for i in range(3):
					bm._enemies[i].max_hp = 500 * scale
					bm._enemy_hp[i] = 500 * scale
					bm._enemy_status[i] = {"weak": 1, "vulnerable": 1, "charm": 4 * scale, "poison_dmg": 2 * scale, "poison_dur": 3, "marked_by": [owner, ally]}
				bm._hero_status[owner] = {"morale": 2, "tokens": 6, "sacrifice_bank": 5 * scale}
				bm._hero_block[owner] = 6 * scale
				bm._hero_block[ally] = 4 * scale
				_open_turn(bm, owner, [card] + _draw_filler(owner, 3))
				bm.deck_mgr._heroes[owner].draw.assign(_draw_filler(owner, 8))
				_check(bm.play_card(card, 0, ally), "matrix actual paid play " + name + "/" + str(live) + "/" + str(upgraded))
				if not bm._pending_discard_pick.is_empty():
					bm.resolve_pending_discard_pick(bm.deck_mgr.get_hand(owner)[0])
				_check(bm.get_enemy_hp(0) is int and bm.get_hero_block(owner) is int and bm.team_mgr.get_current_hp(owner) is int, "matrix integer outcomes " + name)
				_free(ctx)
				executed += 1
	OS.set_environment("STSL_LEGACY_COMBAT", "0")
	_check(executed == 144, "36 cards x grades2 x unit systems2 actually executed", {"executed": executed})

func _test_old_save_restore() -> void:
	var dm := preload("res://autoload/deck_manager.gd").new()
	var saved: Array = []
	for name in ["card.cleopatra.charming_perfume.name", "card.musashi.whirlwind_cut.name", "card.genghis_khan.war_tribute.name"]:
		var owner: String = cards[name].base.owner_id
		saved.append({"card_name": name, "owner_id": owner, "upgrade_level": 1, "cost": 99, "effects": []})
	dm.from_dict({"version": 3, "full_deck": saved})
	_check(dm.get_full_deck().size() == 3, "old save preserves card count")
	for i in range(3):
		var restored: Resource = dm.get_full_deck()[i]
		_check(restored.has_meta("archetype_synergy_revision") and restored.upgrade_level == 1 and Profile._candidate_signature(restored) == Profile._candidate_signature(cards[saved[i].card_name].upgraded), "old save restores current upgraded rule " + restored.card_name)
	dm.free()

func _write_report() -> void:
	var sources := ["resources/cards/archetype_synergy_revision.gd", "autoload/battle_manager.gd", "resources/balance/small_number_profile.gd", "resources/cards/card_revision_v3.gd", "resources/effect_resource.gd", "resources/card_catalog.gd", "autoload/game_manager.gd", "autoload/deck_manager.gd", "autoload/team_manager.gd", "tests/test_card_revision_runtime.gd", "tests/run_archetype_synergy.gd", "resources/translations/strings_card.csv"]
	for hero in ["napoleon", "cleopatra", "yi_sun_sin", "joan_of_arc", "genghis_khan", "musashi"]:
		sources.append("resources/cards/cards_%s.gd" % hero)
	var hashes := {}
	for path in sources:
		hashes[path] = FileAccess.get_sha256("res://" + path)
	var report := {"passed": passed, "failed": failed, "source_commit": OS.get_environment("STSL_BOT_SOURCE_COMMIT"), "dirty": OS.get_environment("STSL_BOT_SOURCE_DIRTY"), "contract": "docs/game_design/archetype_synergy_revision.md", "boundary": "deterministic structural cases; not player-reported fun or independent campaign samples", "runtime": {"profile": Profile.PROFILE_ID, "unit_divisor": Profile.UNIT_DIVISOR}, "sources": hashes, "results": results}
	var file := FileAccess.open("user://archetype_synergy_checks.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print("ARCHETYPE SYNERGY REPORT: " + ProjectSettings.globalize_path("user://archetype_synergy_checks.json"))
