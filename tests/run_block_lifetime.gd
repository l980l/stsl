extends SceneTree

# Production BattleManager checks for the hero Block lifetime rule:
# Block remains until that hero is attacked, then only the unused portion of
# the pre-attack pool expires after the complete hostile action resolves.

const Fixture = preload("res://tests/test_card_revision_runtime.gd")
const Intent = preload("res://resources/intent_resource.gd")

var passed := 0
var failed := 0
var results: Array = []

func _init() -> void:
	call_deferred("_run")

func _check(ok: bool, label: String, details: Dictionary = {}) -> void:
	results.append({"label": label, "ok": ok, "details": details})
	if ok:
		passed += 1
	else:
		failed += 1
		push_error("BLOCK LIFETIME: %s %s" % [label, JSON.stringify(details)])

func _battle(ids: Array = ["napoleon", "musashi"]) -> Dictionary:
	var fixture := Fixture.new()
	var bm = fixture._battle(ids)
	bm.turn_interval = 0.0
	# Target LOWEST_HP deterministically selects Napoleon unless a test changes it.
	bm.team_mgr.take_damage("napoleon", 1)
	return {"fixture": fixture, "bm": bm}

func _free(ctx: Dictionary) -> void:
	ctx.fixture._free(ctx.bm)

func _intent(action_type: int, value: int = 0, target: int = Intent.TargetType.LOWEST_HP) -> Resource:
	var intent := Intent.new()
	intent.action_type = action_type
	intent.value = value
	intent.target = target
	return intent

func _block(bm, hero_id: String, amount: int) -> void:
	bm._gain_block(hero_id, amount)

func _run() -> void:
	AudioServer.set_bus_mute(0, true)
	await _test_single_target_and_unaffected_ally()
	await _test_charge_payoffs_are_one_action()
	await _test_non_attack_dot_and_direct_damage_do_not_expire()
	await _test_zero_and_fully_blocked_attack_expire()
	await _test_aoe_and_mimic_are_hostile_actions()
	await _test_reactive_block_charge_and_double_actions()
	await _test_hero_turn_and_self_cost_preserve_block()
	_test_localized_rule()
	_write_report()
	print("Block lifetime checks: %d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)

func _test_single_target_and_unaffected_ally() -> void:
	var ctx := _battle()
	var bm = ctx.bm
	_block(bm, "napoleon", 10)
	_block(bm, "musashi", 10)
	var hp_before: int = bm.team_mgr.get_current_hp("napoleon")
	var changes: Array = []
	bm.hero_block_gained.connect(func(hero_id: String, amount: int) -> void:
		changes.append([hero_id, amount]))
	await bm._execute_intent(0, _intent(Intent.ActionType.ATTACK, 3))
	_check(bm._hero_block.napoleon == 0, "single attack expires targeted hero remainder")
	_check(bm._hero_block.musashi == 10, "single attack leaves other hero block intact")
	_check(bm.team_mgr.get_current_hp("napoleon") == hp_before, "single attack applies initial block before expiry")
	_check(changes == [["napoleon", -7]], "expiry emits remaining block delta for UI refresh")
	_free(ctx)

func _test_charge_payoffs_are_one_action() -> void:
	var ctx := _battle(["napoleon"])
	var bm = ctx.bm
	_block(bm, "napoleon", 10)
	var hp_before: int = bm.team_mgr.get_current_hp("napoleon")
	var charge := _intent(Intent.ActionType.CHARGE_UP)
	charge.charge_turns = 1
	charge.payoff_intents = [
		_intent(Intent.ActionType.ATTACK, 3),
		_intent(Intent.ActionType.ATTACK, 3),
	]
	await bm._execute_intent(0, charge)
	_check(bm.team_mgr.get_current_hp("napoleon") == hp_before, "charge payoff retains block through every nested hit")
	_check(bm._hero_block.napoleon == 0, "charge payoff expires remainder only after composite action")
	_free(ctx)

func _test_non_attack_dot_and_direct_damage_do_not_expire() -> void:
	var ctx := _battle(["napoleon"])
	var bm = ctx.bm
	_block(bm, "napoleon", 10)
	var buff := _intent(Intent.ActionType.BUFF, 2)
	buff.status_type = "strength"
	await bm._execute_intent(0, buff)
	var debuff := _intent(Intent.ActionType.DEBUFF, 1)
	debuff.status_type = "weak"
	await bm._execute_intent(0, debuff)
	_check(bm._hero_block.napoleon == 10, "enemy buff and debuff do not consume hero block")
	bm._apply_status_to_hero("napoleon", "poison", 3)
	bm._tick_hero_poison("napoleon")
	_check(bm._hero_block.napoleon == 10, "poison DOT does not consume hero block")
	var hp_before: int = bm.team_mgr.get_current_hp("napoleon")
	bm._deal_damage_to_hero("napoleon", 3, "", false, 0)
	_check(bm.team_mgr.get_current_hp("napoleon") == hp_before and bm._hero_block.napoleon == 7, "direct damage still uses block but does not expire it outside an action")
	_free(ctx)

func _test_zero_and_fully_blocked_attack_expire() -> void:
	var ctx := _battle(["napoleon"])
	var bm = ctx.bm
	_block(bm, "napoleon", 10)
	await bm._execute_intent(0, _intent(Intent.ActionType.ATTACK, 3))
	_check(bm._hero_block.napoleon == 0, "fully blocked attack still expires remaining block")
	_block(bm, "napoleon", 7)
	await bm._execute_intent(0, _intent(Intent.ActionType.ATTACK, 0))
	_check(bm._hero_block.napoleon == 0, "zero-damage attack still expires remaining block")
	_free(ctx)

func _test_aoe_and_mimic_are_hostile_actions() -> void:
	var ctx := _battle()
	var bm = ctx.bm
	_block(bm, "napoleon", 10)
	_block(bm, "musashi", 10)
	var aoe := _intent(Intent.ActionType.ATTACK, 3, Intent.TargetType.ALL)
	await bm._execute_intent(0, aoe)
	_check(bm._hero_block.napoleon == 0 and bm._hero_block.musashi == 0, "AOE expires every attacked hero block")
	_block(bm, "napoleon", 10)
	bm._player_damage_this_turn = 6
	await bm._execute_intent(0, _intent(Intent.ActionType.MIMIC, 50))
	_check(bm._hero_block.napoleon == 0, "MIMIC reflection counts as a hostile attack action")
	_free(ctx)

func _test_reactive_block_charge_and_double_actions() -> void:
	var ctx := _battle(["napoleon"])
	var bm = ctx.bm
	_block(bm, "napoleon", 10)
	var full_reactive := {"done": false}
	bm.hero_damaged.connect(func(hero_id: String, _amount: int, _damage_type: String, _is_crit: bool) -> void:
		if hero_id == "napoleon" and not full_reactive.done:
			full_reactive.done = true
			bm._gain_block(hero_id, 4))
	var charge := _intent(Intent.ActionType.CHARGE_UP)
	charge.charge_turns = 1
	charge.payoff_intents = [_intent(Intent.ActionType.ATTACK, 3), _intent(Intent.ActionType.ATTACK, 3)]
	await bm._execute_intent(0, charge)
	_check(bm._hero_block.napoleon == 4, "reactive block from a full initial pool survives composite-action expiry", {"block": bm._hero_block.napoleon, "reacted": full_reactive.done})
	_free(ctx)
	ctx = _battle(["napoleon"])
	bm = ctx.bm
	# A one-shot reactive grant distinguishes the old pool from new Block: with
	# only 2 initial Block, 3+3 damage must leak exactly one HP, while the new
	# 4 Block gained after the first hit remains for the next action.
	_block(bm, "napoleon", 2)
	var hp_before: int = bm.team_mgr.get_current_hp("napoleon")
	var reacted := {"done": false}
	bm.hero_damaged.connect(func(hero_id: String, _amount: int, _damage_type: String, _is_crit: bool) -> void:
		if hero_id == "napoleon" and not reacted.done:
			reacted.done = true
			bm._gain_block(hero_id, 4))
	charge = _intent(Intent.ActionType.CHARGE_UP)
	charge.charge_turns = 1
	charge.payoff_intents = [_intent(Intent.ActionType.ATTACK, 3), _intent(Intent.ActionType.ATTACK, 3)]
	await bm._execute_intent(0, charge)
	_check(bm.team_mgr.get_current_hp("napoleon") == hp_before - 1 and bm._hero_block.napoleon == 1, "charge keeps one-shot reactive block through later payoff hit and preserves its remainder", {"hp_before": hp_before, "hp_after": bm.team_mgr.get_current_hp("napoleon"), "block": bm._hero_block.napoleon, "reacted": reacted.done})
	_free(ctx)
	ctx = _battle(["napoleon"])
	bm = ctx.bm
	_block(bm, "napoleon", 10)
	bm._enemies[0].intent_pattern = [_intent(Intent.ActionType.ATTACK, 3), _intent(Intent.ActionType.ATTACK, 3)]
	bm._enemy_status[0]["double_action"] = 1
	hp_before = bm.team_mgr.get_current_hp("napoleon")
	await bm._run_one_enemy_turn(0, true)
	_check(bm.team_mgr.get_current_hp("napoleon") == hp_before - 3 and bm._hero_block.napoleon == 0, "double_action uses two separate expiry actions")
	_free(ctx)

func _test_hero_turn_and_self_cost_preserve_block() -> void:
	var ctx := _battle(["napoleon"])
	var bm = ctx.bm
	_block(bm, "napoleon", 10)
	await bm._start_hero_turn("napoleon")
	_check(bm._hero_block.napoleon == 10, "starting the owning hero turn does not expire block")
	var self_cost = ctx.fixture._card("napoleon", 0, 0)
	self_cost.effects[0].rule_id = "sacrifice_then_power"
	self_cost.effects[0].rule_params = {"sacrifice": 3, "power": "power.test_block_lifetime", "amount": 1}
	var hp_before: int = bm.team_mgr.get_current_hp("napoleon")
	await bm._apply_card_effects(self_cost, 0)
	_check(bm.team_mgr.get_current_hp("napoleon") == hp_before - 3 and bm._hero_block.napoleon == 10, "card self-cost does not consume block")
	_free(ctx)

func _test_localized_rule() -> void:
	var original := TranslationServer.get_locale()
	for locale in ["ko", "en", "fr", "it", "es", "ja", "el", "zh", "zh_TW", "ru", "pt", "pl", "de"]:
		TranslationServer.set_locale(locale)
		var tooltip := tr("keyword.block.lifetime")
		var tutorial := tr("tutorial.basics.s2_block")
		_check(tooltip != "keyword.block.lifetime" and not tooltip.is_empty(), "block lifetime tooltip translated " + locale)
		_check(tutorial != "tutorial.basics.s2_block" and not tutorial.is_empty(), "block tutorial translated " + locale)
		if locale == "ko":
			_check(tooltip.contains("사라집니다") and tutorial.contains("연타") and not tutorial.contains("누적·유지"), "Korean imported text describes new expiry")
		elif locale == "en":
			_check(tooltip.contains("expires") and tutorial.contains("all hits") and not tutorial.contains("until consumed"), "English imported text describes new expiry")
	TranslationServer.set_locale(original)

func _write_report() -> void:
	var sources := ["autoload/battle_manager.gd", "autoload/team_manager.gd", "resources/translations/strings_status.csv", "resources/translations/strings_tutorial.csv", "scenes/battle/battle_scene.gd", "tests/test_card_revision_runtime.gd", "tests/run_block_lifetime.gd"]
	var hashes := {}
	for path in sources:
		hashes[path] = FileAccess.get_sha256("res://" + path)
	var report := {
		"schema": 1,
		"source_commit": OS.get_environment("STSL_BOT_SOURCE_COMMIT"),
		"dirty": OS.get_environment("STSL_BOT_SOURCE_DIRTY"),
		"sources_sha256": hashes,
		"boundary": "BattleManager block-lifetime behavior; excludes visual timing and player comprehension.",
		"passed": passed,
		"failed": failed,
		"results": results,
	}
	var path := "user://block_lifetime_checks.json"
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("BLOCK LIFETIME: cannot write report")
		failed += 1
		return
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print("Block lifetime report: " + ProjectSettings.globalize_path(path))
