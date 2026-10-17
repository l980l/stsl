extends SceneTree

# Paired, actual-rule local-card experiment, NOT a campaign/win-rate estimate.
const Profile = preload("res://resources/balance/small_number_profile.gd")
const Catalog = preload("res://resources/card_catalog.gd")
const Fixture = preload("res://tests/test_card_revision_runtime.gd")
const GM = preload("res://autoload/game_manager.gd")
const Card = preload("res://resources/card_resource.gd")
const OWNERS = ["napoleon", "cleopatra", "yi_sun_sin", "joan_of_arc", "genghis_khan", "musashi"]
var _power_turns := 0
var _poison_ticks := 0
var _weak := false
var _vulnerable := false

func _init() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg == "--weak":
			_weak = true
		elif arg == "--vulnerable":
			_vulnerable = true
		elif arg.begins_with("--poison-ticks="):
			_poison_ticks = clampi(arg.trim_prefix("--poison-ticks=").to_int(), 0, 3)
		if arg.begins_with("--power-turns="):
			_power_turns = clampi(arg.trim_prefix("--power-turns=").to_int(), 0, 5)
	call_deferred("_run")

func _run() -> void:
	AudioServer.set_bus_mute(0, true)
	var gm = GM.new()
	var rows: Array = []
	var flagged := 0
	var pending := 0
	var profile_notes: Dictionary = {}
	var candidates: Array = []
	for source in Catalog.get_all_cards():
		var pair: Dictionary = Profile.candidate_pair(source, gm)
		candidates.append({"card": Catalog.card_key(source), "base": _card_data(pair.base), "upgraded": _card_data(pair.upgraded)})
		profile_notes[Catalog.card_key(source)] = {"unsupported_fields": pair.get("unsupported_fields", []), "hazards": pair.get("hazards", [])}
		for grade in [0, 1]:
			var legacy = source.duplicate(true)
			if grade == 1:
				gm.upgrade_card(legacy)
			var candidate = pair.base if grade == 0 else pair.upgraded
			for stocked in [false, true]:
				for party_size in [1, 3]:
					var old: Dictionary = _execute(legacy, 1, stocked, party_size)
					var small: Dictionary = _execute(candidate, 10, stocked, party_size)
					var differences: Array = []
					for metric in old.metrics:
						var count_metric: bool = metric.ends_with(".hand") or metric.ends_with(".energy") or metric.ends_with(".morale") or metric.ends_with(".tokens")
						var expected := float(old.metrics[metric]) / (1.0 if count_metric else 10.0)
						var actual := float(small.metrics[metric])
						# Diagnostic acceptance: one new unit OR 15%, not proof of balance.
						var zero_transition: bool = (expected == 0.0) != (actual == 0.0)
						if zero_transition or (count_metric and actual != expected) or (not count_metric and abs(actual - expected) > max(1.0, abs(expected) * 0.15)):
							differences.append({"metric": metric, "expected": expected, "candidate": actual})
					if not differences.is_empty():
						flagged += 1
					if old.pending_selection or small.pending_selection:
						pending += 1
					rows.append({"card": Catalog.card_key(source), "grade": grade, "stocked": stocked,
						"party_size": party_size, "legacy": old, "candidate": small, "outliers": differences,
						"coverage": "selection_pending" if old.pending_selection or small.pending_selection else ("immediate_plus_selection" if old.selection_resolution != "none" else "immediate_only")})
	gm.free()
	var report := {
		"profile": Profile.PROFILE_ID, "schema": 1, "paired_cases": rows.size(),
		"outlier_cases": flagged, "pending_selection_cases": pending,
		"criteria": "Zero/nonzero transitions require review; HP-domain absolute difference <= 1 small unit OR <= 15% of normalized baseline; counts exactly equal",
		"scope": "216 cards, grades 0/1, empty/stocked state, solo/three heroes; actual BattleManager effects and first-card/optional-skip selection resolution",
		"power_turns": _power_turns,
		"context": {"weak": _weak, "vulnerable": _vulnerable, "poison_ticks": _poison_ticks},
		"context_policy": "weak/vulnerable held constant during local callbacks; poison/power callbacks are not full scheduled actor turns",
		"power_policy": "trigger registered player_turn_start powers for each owner; no enemy turns, token attacks, or full ATB phases in this local-effect experiment",
		"gaps": ["No campaign clear rate or human playtest", "No revive/death, relic/event/signature coverage in this card-effect experiment", "Optional discard chooses skip; other player choices require separate tests"],
		"cases": rows,
		"profile_notes": profile_notes,
		"candidate_cards": candidates,
		"source_sha256": _fingerprints(),
		"revision": "unspecified", "dirty": "unspecified",
	}
	var output := "user://small_number_comparison.json"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="):
			output = arg.trim_prefix("--output=")
		elif arg.begins_with("--revision="):
			report.revision = arg.trim_prefix("--revision=")
		elif arg.begins_with("--dirty="):
			report.dirty = arg.trim_prefix("--dirty=")
	var file := FileAccess.open(output, FileAccess.WRITE)
	if file == null:
		push_error("Cannot write comparison report: " + output)
		quit(1)
		return
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print("Small-number comparison: %d paired cases; %d outliers; %d pending selections. Report: %s" % [rows.size(), flagged, pending, ProjectSettings.globalize_path(output)])
	quit(0)

func _fingerprints() -> Dictionary:
	var result: Dictionary = {}
	for path in ["res://autoload/battle_manager.gd", "res://autoload/game_manager.gd",
		"res://autoload/deck_manager.gd", "res://autoload/team_manager.gd",
		"res://resources/effect_resource.gd", "res://resources/card_resource.gd",
		"res://tests/test_card_revision_runtime.gd", "res://resources/translations/strings_card.csv",
		"res://resources/balance/small_number_profile.gd", "res://resources/cards/card_revision_v3.gd", "res://resources/cards/archetype_synergy_revision.gd",
		"res://resources/card_catalog.gd", "res://tools/evaluate_small_numbers.gd"]:
		result[path] = FileAccess.get_sha256(path)
	for owner in OWNERS:
		var path: String = "res://resources/cards/cards_%s.gd" % owner
		result[path] = FileAccess.get_sha256(path)
	return result

func _card_data(card: Resource) -> Dictionary:
	var effects: Array = []
	for effect in card.effects:
		effects.append({"type": effect.effect_type, "value": effect.value, "bonus_value": effect.bonus_value,
			"status": effect.status_type, "target": effect.target, "hit_count": effect.hit_count,
			"condition": effect.condition, "rule_id": effect.rule_id, "rule_params": effect.rule_params.duplicate(true),
			"text": effect.display_text()})
	return {"name": tr(card.card_name), "cost": card.cost, "effects": effects}

func _execute(card: Resource, divisor: int, stocked: bool, party_size: int) -> Dictionary:
	seed(73013)
	var fixture = Fixture.new()
	var ids: Array = [card.owner_id]
	var owner_index: int = OWNERS.find(card.owner_id)
	for offset in range(1, party_size):
		ids.append(OWNERS[(owner_index + offset) % OWNERS.size()])
	var bm = fixture._battle(ids, 2)
	bm.combat_unit_divisor = divisor
	for hero in bm.team_mgr.heroes:
		hero.max_hp = 1000 / divisor
		bm.team_mgr._hero_hp[hero.hero_id] = 500 / divisor
		bm._hero_block[hero.hero_id] = (80 / divisor) if stocked else 0
		bm._hero_status[hero.hero_id] = {"morale": 3 if stocked else 0, "tokens": 3 if stocked else 0}
		if _weak:
			bm._hero_status[hero.hero_id]["weak"] = 1
		bm._hero_status[hero.hero_id]["sacrifice_bank"] = (150 / divisor) if stocked else 0
		bm.deck_mgr._heroes[hero.hero_id]["energy"] = 3
		bm.deck_mgr._heroes[hero.hero_id]["cards_played_this_turn"] = 3 if stocked else 0
		bm.deck_mgr._heroes[hero.hero_id]["draws_this_turn"] = 3 if stocked else 0
		for n in range(10):
			var filler = Card.new()
			filler.owner_id = hero.hero_id
			filler.card_name = "test.small_numbers.filler_%d" % n
			bm.deck_mgr._heroes[hero.hero_id]["draw"].append(filler)
		for n in range(3 if stocked else 0):
			bm.deck_mgr._heroes[hero.hero_id]["hand"].append(bm.deck_mgr._heroes[hero.hero_id]["draw"].pop_back())
	for i in range(2):
		bm._enemies[i].max_hp = 5000 / divisor
		bm._enemy_hp[i] = 5000 / divisor
		bm._enemies[i].intent_pattern[0].value = 100 / divisor
		bm._enemy_status[i]["charm_resistance"] = 20 / divisor
		bm._enemy_status[i]["charm"] = (40 / divisor) if stocked else 0
		bm._enemy_status[i]["poison_dmg"] = (20 / divisor) if stocked else 0
		bm._enemy_status[i]["poison_dur"] = 3 if stocked else 0
		if _vulnerable:
			bm._enemy_status[i]["vulnerable"] = 1
	var before: Dictionary = _metrics(bm)
	# Fixtures are built in legacy mode, but actual candidate calculations must
	# use the same positive-damage floor as production small-number gameplay.
	OS.set_environment("STSL_LEGACY_COMBAT", "" if divisor == 10 else "1")
	seed(73013) # Paired random targets; reproducibility, not independent samples.
	bm._apply_card_effects(card, 0, card.owner_id)
	var selection_resolution := "none"
	if not bm._pending_discard_pick.is_empty():
		var hand: Array = bm.deck_mgr.get_hand(card.owner_id)
		if bm.is_discard_pick_optional():
			bm.resolve_pending_discard_pick(null)
			selection_resolution = "optional_skip"
		elif not hand.is_empty():
			bm.resolve_pending_discard_pick(hand[0])
			selection_resolution = "first_owned_hand_card"
	for _tick in range(_power_turns):
		for hero in bm.team_mgr.heroes:
			bm._trigger_active_powers("player_turn_start", {"hero_id": hero.hero_id})
	for _tick in range(_poison_ticks):
		for i in range(2):
			if bm._enemy_alive[i]:
				bm._tick_enemy_poison(i)
	var after: Dictionary = _metrics(bm)
	for key in after:
		after[key] -= before[key]
	var result := {"metrics": after, "pending_selection": not bm._pending_discard_pick.is_empty(),
		"selection_resolution": selection_resolution,
		"energy": bm.deck_mgr.get_energy(card.owner_id), "owner_status": bm._hero_status[card.owner_id].duplicate(true),
		"active_powers": bm._active_powers.duplicate(true)}
	fixture._free(bm)
	OS.set_environment("STSL_LEGACY_COMBAT", "1")
	return result

func _metrics(bm) -> Dictionary:
	var result: Dictionary = {}
	for hero in bm.team_mgr.heroes:
		result[hero.hero_id + ".hp"] = bm.team_mgr.get_current_hp(hero.hero_id)
		result[hero.hero_id + ".block"] = bm._hero_block.get(hero.hero_id, 0)
		result[hero.hero_id + ".hand"] = bm.deck_mgr.get_hand(hero.hero_id).size()
		result[hero.hero_id + ".energy"] = bm.deck_mgr.get_energy(hero.hero_id)
		result[hero.hero_id + ".morale"] = int(bm._hero_status.get(hero.hero_id, {}).get("morale", 0))
		result[hero.hero_id + ".tokens"] = int(bm._hero_status.get(hero.hero_id, {}).get("tokens", 0))
	for i in range(2):
		result["enemy_%d.hp" % i] = bm.get_enemy_hp(i)
		result["enemy_%d.poison" % i] = int(bm._enemy_status[i].get("poison_dmg", 0))
		result["enemy_%d.charm" % i] = int(bm._enemy_status[i].get("charm", 0))
	return result
