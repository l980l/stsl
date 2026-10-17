extends SceneTree

# Production-rule coverage for the martyr reward buff.  Each assertion exercises
# the same CardCatalog -> small-number profile -> BattleManager path used in play.

const Catalog = preload("res://resources/card_catalog.gd")
const Profile = preload("res://resources/balance/small_number_profile.gd")
const GM = preload("res://autoload/game_manager.gd")
const Fixture = preload("res://tests/test_card_revision_runtime.gd")

const MARTYR_STEPS := "card.joan_of_arc.martyrdom_steps.name"
const LAST_SHIELD := "card.joan_of_arc.last_shield.name"
const SAINTS_REVELATION := "card.joan_of_arc.saints_revelation.name"
const MARTYRS_LIGHT := "card.joan_of_arc.martyrs_light.name"

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
		push_error("MARTYR REWARDS: %s %s" % [label, JSON.stringify(details)])

func _run() -> void:
	AudioServer.set_bus_mute(0, true)
	_prepare_cards()
	_test_authored_and_live_contract()
	await _test_bank_draw()
	await _test_last_shield()
	await _test_payoffs_and_preview()
	_test_tooltips()
	_test_save_restore()
	_write_report()
	print("MARTYR REWARDS: %d passed, %d failed" % [passed, failed])
	quit(1 if failed else 0)

func _prepare_cards() -> void:
	OS.set_environment("STSL_LEGACY_COMBAT", "1")
	var gm := GM.new()
	for source in Catalog.get_all_cards():
		if source.card_name not in [MARTYR_STEPS, LAST_SHIELD, SAINTS_REVELATION, MARTYRS_LIGHT]:
			continue
		var pair: Dictionary = Profile.candidate_pair(source, gm)
		var legacy_upgraded: Resource = source.duplicate(true)
		gm.upgrade_card(legacy_upgraded)
		cards[source.card_name] = {
			"legacy": source.duplicate(true), "legacy_upgraded": legacy_upgraded,
			"live": pair.base, "live_upgraded": pair.upgraded,
		}
	gm.free()
	OS.set_environment("STSL_LEGACY_COMBAT", "0")

func _card(name: String, live: bool, upgraded: bool) -> Resource:
	var key := ("live" if live else "legacy") + ("_upgraded" if upgraded else "")
	return cards[name][key].duplicate(true)

func _battle(live: bool, enemy_count: int = 2) -> Dictionary:
	var fixture := Fixture.new()
	var bm = fixture._battle(["joan_of_arc", "napoleon"], enemy_count)
	bm.turn_interval = 0.0
	bm.combat_unit_divisor = 10 if live else 1
	var scale := 1 if live else 10
	for hero in bm.team_mgr.heroes:
		hero.max_hp = 100 * scale
		bm.team_mgr._hero_hp[hero.hero_id] = 100 * scale
		bm._hero_status[hero.hero_id] = {}
	for index in range(enemy_count):
		bm._enemies[index].max_hp = 500 * scale
		bm._enemy_hp[index] = 500 * scale
	return {"fixture": fixture, "bm": bm}

func _free(ctx: Dictionary) -> void:
	ctx.fixture._free(ctx.bm)

func _apply(bm: Node, card: Resource, ally := "") -> void:
	await bm._apply_card_effects(card, 0, ally)

func _effect(card: Resource, rule_id: String) -> Resource:
	for effect in card.effects:
		if effect.rule_id == rule_id:
			return effect
	return null

func _draw_fillers(live: bool, count: int) -> Array:
	var result: Array = []
	for _index in range(count):
		result.append(_card(LAST_SHIELD, live, false))
	return result

func _test_authored_and_live_contract() -> void:
	_check(cards.size() == 4, "all four martyr reward cards catalogued", {"actual": cards.size()})
	for live in [false, true]:
		var scale := 1 if live else 10
		for upgraded in [false, true]:
			var grade := "upgraded" if upgraded else "base"
			var steps: Resource = _effect(_card(MARTYR_STEPS, live, upgraded), "bank_draw")
			_check(steps.rule_params.consume_cap == 5 * scale and steps.rule_params.draw == 1 and steps.rule_params.bonus_draw == (3 if upgraded else 2), "steps %s/%s has fixed bank draw contract" % ["live" if live else "legacy", grade])
			var shield_card := _card(LAST_SHIELD, live, upgraded)
			var sacrifice: Resource = shield_card.effects[0]
			var shield: Resource = _effect(shield_card, "block_transfer")
			_check(sacrifice.value == 5 * scale and shield.rule_params.consume_cap == (14 if upgraded else 10) * scale and shield.rule_params.base == (7 if upgraded else 5) * scale, "last shield %s/%s keeps HP cost and upgrades transfer/base" % ["live" if live else "legacy", grade])
			var revelation: Resource = _effect(_card(SAINTS_REVELATION, live, upgraded), "sacrifice_bank_payoff")
			_check(revelation.value == (13 if upgraded else 10) * scale and revelation.rule_params.consume_cap == 15 * scale, "revelation %s/%s has payoff and unchanged cap" % ["live" if live else "legacy", grade])
			var light: Resource = _effect(_card(MARTYRS_LIGHT, live, upgraded), "sacrifice_bank_team_block")
			_check(light.rule_params.base == (11 if upgraded else 8) * scale and light.rule_params.consume_cap == 15 * scale, "light %s/%s has team block and unchanged cap" % ["live" if live else "legacy", grade])

func _test_bank_draw() -> void:
	for live in [false, true]:
		var scale := 1 if live else 10
		for upgraded in [false, true]:
			for bank in [0, 3 * scale, 5 * scale]:
				var ctx := _battle(live); var bm: Node = ctx.bm
				bm._hero_status.joan_of_arc.sacrifice_bank = bank
				bm.deck_mgr._heroes.joan_of_arc.draw.assign(_draw_fillers(live, 6))
				await _apply(bm, _card(MARTYR_STEPS, live, upgraded))
				var expected_draw := 1 + ((3 if upgraded else 2) if bank >= 5 * scale else 0)
				_check(bm.deck_mgr.get_hand("joan_of_arc").size() == expected_draw and bm._hero_status.joan_of_arc.sacrifice_bank == 0, "steps consumes bank %d and draws %d (%s, %s)" % [bank, expected_draw, "live" if live else "legacy", "up" if upgraded else "base"])
				_free(ctx)

func _test_last_shield() -> void:
	for live in [false, true]:
		var scale := 1 if live else 10
		for upgraded in [false, true]:
			var cap := (14 if upgraded else 10) * scale
			var base := (7 if upgraded else 5) * scale
			var hp_cost := 5 * scale
			var ctx := _battle(live); var bm: Node = ctx.bm
			bm._hero_block.joan_of_arc = cap + 4 * scale
			await _apply(bm, _card(LAST_SHIELD, live, upgraded), "napoleon")
			_check(bm.team_mgr.get_current_hp("joan_of_arc") == 100 * scale - hp_cost and bm.get_hero_block("joan_of_arc") == 4 * scale and bm.get_hero_block("napoleon") == cap + base, "last shield transfers capped own block and spends fixed HP (%s, %s)" % ["live" if live else "legacy", "up" if upgraded else "base"])
			_free(ctx)
			ctx = _battle(live); bm = ctx.bm
			await _apply(bm, _card(LAST_SHIELD, live, upgraded), "napoleon")
			_check(bm.get_hero_block("napoleon") == base and bm.team_mgr.get_current_hp("joan_of_arc") == 100 * scale - hp_cost, "last shield grants base protection without pre-existing block")
			_free(ctx)
			ctx = _battle(live); bm = ctx.bm
			bm._hero_block.joan_of_arc = cap
			await _apply(bm, _card(LAST_SHIELD, live, upgraded), "joan_of_arc")
			_check(bm.get_hero_block("joan_of_arc") == cap + base, "last shield self target retains block and gains only base (%s, %s)" % ["live" if live else "legacy", "up" if upgraded else "base"])
			_free(ctx)
			ctx = _battle(live); bm = ctx.bm
			bm.team_mgr._hero_hp.joan_of_arc = hp_cost - 1
			bm._hero_block.joan_of_arc = cap
			await _apply(bm, _card(LAST_SHIELD, live, upgraded), "napoleon")
			_check(not bm.team_mgr.is_alive("joan_of_arc") and bm.get_hero_block("napoleon") == 0, "fatal last shield sacrifice interrupts transfer (%s, %s)" % ["live" if live else "legacy", "up" if upgraded else "base"])
			_free(ctx)

func _test_payoffs_and_preview() -> void:
	for live in [false, true]:
		var scale := 1 if live else 10
		for upgraded in [false, true]:
			for bank in [0, 9 * scale, 20 * scale]:
				var ctx := _battle(live); var bm: Node = ctx.bm
				bm._hero_status.joan_of_arc.sacrifice_bank = bank
				var revelation := _card(SAINTS_REVELATION, live, upgraded)
				var expected := ((13 if upgraded else 10) * scale) + mini(bank, 15 * scale)
				var preview: Dictionary = bm._estimate_card_damage(revelation, 0)
				var hp0: int = bm.get_enemy_hp(0); var hp1: int = bm.get_enemy_hp(1)
				await _apply(bm, revelation)
				_check(preview.get(0, -1) == expected and preview.get(1, -1) == expected and hp0 - bm.get_enemy_hp(0) == expected and hp1 - bm.get_enemy_hp(1) == expected and bm._hero_status.joan_of_arc.sacrifice_bank == maxi(0, bank - 15 * scale), "revelation preview and all-target payoff agree at bank %d (%s, %s)" % [bank, "live" if live else "legacy", "up" if upgraded else "base"])
				_free(ctx)
				ctx = _battle(live); bm = ctx.bm
				bm._hero_status.joan_of_arc.sacrifice_bank = bank
				var light := _card(MARTYRS_LIGHT, live, upgraded)
				var block := ((11 if upgraded else 8) * scale) + mini(bank, 15 * scale)
				await _apply(bm, light)
				_check(bm.get_hero_block("joan_of_arc") == block and bm.get_hero_block("napoleon") == block and bm._hero_status.joan_of_arc.sacrifice_bank == maxi(0, bank - 15 * scale), "light grants both living heroes its base plus spent bank at %d (%s, %s)" % [bank, "live" if live else "legacy", "up" if upgraded else "base"])
				_free(ctx)

func _test_tooltips() -> void:
	for live in [false, true]:
		var scale := 1 if live else 10
		for upgraded in [false, true]:
			var texts: Array[String] = []
			for name in [MARTYR_STEPS, LAST_SHIELD, SAINTS_REVELATION, MARTYRS_LIGHT]:
				for effect in _card(name, live, upgraded).effects:
					texts.append(effect.display_text())
			var joined := "\n".join(texts)
			for pair in [[MARTYR_STEPS, "bank_draw", str(3 if upgraded else 2)], [LAST_SHIELD, "block_transfer", str((7 if upgraded else 5) * scale)], [SAINTS_REVELATION, "sacrifice_bank_payoff", str((13 if upgraded else 10) * scale)], [MARTYRS_LIGHT, "sacrifice_bank_team_block", str((11 if upgraded else 8) * scale)]]:
				var specific: String = _effect(_card(pair[0], live, upgraded), pair[1]).display_text()
				_check(specific.contains(pair[2]) and not specific.contains("{"), "individual reward tooltip resolves its buff " + pair[0] + "/" + str(live) + "/" + str(upgraded))
			var numbers := [str(5 * scale), str(15 * scale), str(3 if upgraded else 2), str((14 if upgraded else 10) * scale), str((7 if upgraded else 5) * scale), str((13 if upgraded else 10) * scale), str((11 if upgraded else 8) * scale)]
			var visible := true
			for number in numbers:
				visible = visible and joined.contains(number)
			_check(visible and not joined.contains("{") and not joined.contains("}"), "tooltip resolves all martyr reward numbers (%s, %s)" % ["live" if live else "legacy", "up" if upgraded else "base"], {"text": joined})

func _test_save_restore() -> void:
	for upgraded in [false, true]:
		var dm := preload("res://autoload/deck_manager.gd").new()
		var saved: Array = []
		for name in [MARTYR_STEPS, LAST_SHIELD, SAINTS_REVELATION, MARTYRS_LIGHT]:
			saved.append({"card_name": name, "owner_id": "joan_of_arc", "upgrade_level": int(upgraded), "cost": 99, "effects": []})
		dm.from_dict({"version": 3, "full_deck": saved})
		_check(dm.get_full_deck().size() == 4, "save restores four martyr cards")
		for index in range(4):
			var restored: Resource = dm.get_full_deck()[index]
			_check(Profile._candidate_signature(restored) == Profile._candidate_signature(_card(saved[index].card_name, true, upgraded)), "save rebuilds buffed current rules " + saved[index].card_name + "/" + str(upgraded))
		dm.free()

func _write_report() -> void:
	var sources := ["resources/cards/archetype_synergy_revision.gd", "resources/cards/card_revision_v3.gd", "resources/balance/small_number_profile.gd", "autoload/battle_manager.gd", "resources/effect_resource.gd", "resources/card_catalog.gd", "autoload/game_manager.gd", "autoload/team_manager.gd", "autoload/deck_manager.gd", "resources/cards/cards_joan_of_arc.gd", "resources/translations/strings_card.csv", "tests/test_card_revision_runtime.gd", "tests/run_martyr_rewards.gd"]
	var hashes := {}
	for path in sources:
		hashes[path] = FileAccess.get_sha256("res://" + path)
	var report := {"passed": passed, "failed": failed, "source_commit": OS.get_environment("STSL_BOT_SOURCE_COMMIT"), "dirty": OS.get_environment("STSL_BOT_SOURCE_DIRTY"), "contract": "martyr reward buff: deterministic authoring/live runtime, preview, and tooltip checks", "boundary": "does not establish encounter-level difficulty or player enjoyment", "sources": hashes, "results": results}
	var file := FileAccess.open("user://martyr_reward_checks.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print("MARTYR REWARDS REPORT: " + ProjectSettings.globalize_path("user://martyr_reward_checks.json"))
