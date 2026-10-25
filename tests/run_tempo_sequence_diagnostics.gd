extends "res://tests/run_tempo_survival_balance.gd"

const ObservedBM = preload("res://tests/tempo_pressure_battle_manager.gd")
var _arm := ""
var _observed := {}
var _fallbacks := {}

func _run() -> void:
	AudioServer.set_bus_mute(0, true)
	_set_legacy_combat(true)
	_all_enemies = true
	_cap = 120
	_revert_martyr = false
	var references := []
	var reference_files := {}
	for variable in ["STSL_V4_FULL_REPORT", "STSL_V4_HOLDOUT_REPORT"]:
		var path := OS.get_environment(variable)
		if not path.is_absolute_path() or not FileAccess.file_exists(path):
			push_error("Missing absolute reference report: " + variable)
			quit(1)
			return
		var report: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
		if report.policy.baseline != "tempo-v3" or report.policy.candidate != "tempo-v4" or not report.integrity_failures.is_empty():
			push_error("Invalid reference contract")
			quit(1)
			return
		reference_files[path] = FileAccess.get_sha256(path)
		for row in report.runs:
			if row.baseline.won != row.candidate.won: references.append(row)
	for card in Catalog.get_all_cards(): _sources[card.card_name] = card
	var invalid := _validate_decks()
	var monsters := {}
	for enemy in Monsters.get_all_monsters(): monsters[enemy.enemy_name] = enemy
	var paths := _source_paths() + ["res://tools/tempo_survival_decision_policy.gd", "res://tests/run_tempo_survival_balance.gd", "res://tests/run_tempo_sequence_diagnostics.gd", "res://tests/tempo_pressure_battle_manager.gd"]
	var source_start := _source_hashes(paths)
	var rows := []
	for reference in references:
		var definition: Dictionary = Definitions.DECKS.filter(func(d: Dictionary) -> bool: return d.id == reference.deck)[0]
		_owner = definition.hero
		_package = definition.cards
		_hp_percent = int(reference.initial_hp_percent)
		_encounter.clear()
		for id in TEMPO_SCENARIOS[reference.encounter]: _encounter.append(monsters["enemy." + id])
		var results := {}
		for arm in ["v3", "v4", "v3_order_v4_targets", "v4_order_v3_targets"]:
			_arm = arm
			var segment := {"label": definition.id + ":" + reference.composition, "hero_ids": _heroes_for(_owner, reference.composition), "probe_card": ""}
			var result := await _simulate(_encounter[0], segment, 0, int(reference.seed), true)
			if result.initial_hash != reference.baseline.initial_hash: invalid.append("Initial drift: " + definition.id + arm)
			if arm in ["v3", "v4"]:
				var expected: Dictionary = reference.baseline if arm == "v3" else reference.candidate
				if result.trajectory_hash != expected.trajectory_hash: invalid.append("Frozen trajectory drift: " + definition.id + arm)
			if result.capped or result.outcome == "incomplete": invalid.append("Censored: " + definition.id + arm)
			for decision in result.decisions:
				if decision.card != "" and not decision.played: invalid.append("Rejected: " + definition.id + arm)
			result.erase("trace")
			results[arm] = result
		rows.append({"deck": definition.id, "composition": reference.composition, "encounter": reference.encounter, "hp_percent": _hp_percent, "seed": reference.seed, "reference_change": "v4_loss" if reference.baseline.won else "v4_gain", "arms": results})
		print("Sequence diagnosis: ", definition.id, "/", reference.encounter, "/", _hp_percent, "/", reference.seed)
	var source_end := _source_hashes(paths)
	if source_start != source_end: invalid.append("Source drift")
	if rows.size() != 31: invalid.append("Expected31 selected states")
	var report := {"contract": "docs/game_design/tempo_sequence_v5.md", "source_commit": _source_commit, "dirty": _dirty, "reference_sha256": reference_files, "source_sha256_start": source_start, "source_sha256_end": source_end, "selected_states": rows.size(), "battles": rows.size() * 4, "integrity_failures": invalid, "runs": rows}
	var output := FileAccess.open("user://tempo_sequence_diagnostics.json", FileAccess.WRITE)
	output.store_string(JSON.stringify(report, "\t"))
	output.close()
	print("Sequence diagnosis report: ", ProjectSettings.globalize_path("user://tempo_sequence_diagnostics.json"))
	print("Sequence diagnosis: ", rows.size(), " states / ", invalid.size(), " integrity failures")
	quit(0 if invalid.is_empty() else 1)

func _make_battle_manager():
	return ObservedBM.new()

func _on_battle_ready(bm: Object) -> void:
	super._on_battle_ready(bm)
	_observed[bm.get_instance_id()] = []
	_fallbacks[bm.get_instance_id()] = 0

func _choice(bm: Object, hid: String) -> Dictionary:
	var order_policy = Safe if _arm in ["v4", "v4_order_v3_targets"] else Prior
	var choice: Dictionary = order_policy.choose(bm, hid)
	var card: Resource = choice.get("card")
	if card != null and _arm in ["v3_order_v4_targets", "v4_order_v3_targets"]:
		var target_policy = Safe if _arm == "v3_order_v4_targets" else Prior
		var alternative: Dictionary = target_policy.choose(bm, hid, func(c: Resource) -> bool: return c == card)
		if alternative.get("card") == card:
			choice = choice.duplicate()
			choice.target = alternative.target
			choice.ally = alternative.ally
		else: _fallbacks[bm.get_instance_id()] += 1
	return choice

func _decision_state(bm: Object, hid: String) -> Dictionary:
	var enemies := []
	var scores := []
	var hand := []
	for card in bm.deck_mgr.get_hand(hid):
		hand.append({"card": card.card_name, "cost": bm.deck_mgr.get_effective_cost(hid, card), "playable": bm.deck_mgr.can_play_hero(hid, card)})
		if not bm.deck_mgr.can_play_hero(hid, card): continue
		for target in range(bm._enemy_alive.size()):
			if bm.is_enemy_alive(target): scores.append({"card": card.card_name, "target": target, "v3": Prior.evaluate(bm, card, target, hid), "v4": Safe.evaluate(bm, card, target, hid)})
	for i in range(bm._enemy_alive.size()):
		var intents := []
		for intent in bm.get_enemy_current_intents(i): intents.append({"type": intent.action_type, "target": intent.target, "damage": bm.get_intent_display_damage(i, intent)})
		enemies.append({"index": i, "alive": bm.is_enemy_alive(i), "hp": bm.get_enemy_hp(i), "block": bm._enemy_block[i], "intents": intents})
	return {"owner_input": _telemetry[bm.get_instance_id()].owner_inputs, "hp": bm.team_mgr.get_current_hp(hid), "block": bm.get_hero_block(hid), "energy": bm.deck_mgr.get_energy(hid), "incoming_proxy": Policy.incoming(bm, hid), "queue": bm.get_turn_queue_preview(12), "hand": hand, "scores": scores, "enemies": enemies}

func _play_hand_order(bm: Object, hid: String) -> int:
	if hid == _owner: _record_checkpoint(bm, hid)
	bm.set_meta("observed_owner_input", _telemetry[bm.get_instance_id()].owner_inputs)
	var played := 0
	while bm.is_player_turn:
		var choice := _choice(bm, hid)
		var card: Resource = choice.get("card")
		var observation := _decision_state(bm, hid)
		observation["choice"] = {"card": card.card_name if card else "", "target": choice.get("target", -1), "ally": choice.get("ally", "")}
		_observed[bm.get_instance_id()].append(observation)
		var entry := {"hero": hid, "card": card.card_name if card else "", "target": choice.get("target", -1), "ally": choice.get("ally", ""), "reason": choice.get("reason", ""), "score": choice.get("score", 0.0), "played": false}
		if card == null:
			_decisions[bm.get_instance_id()].append(entry)
			break
		var cost: int = bm.deck_mgr.get_effective_cost(hid, card)
		if hid == _owner: _queue_energy_metric(bm, card, cost)
		entry.played = bm.play_card(card, entry.target, entry.ally)
		_decisions[bm.get_instance_id()].append(entry)
		if not entry.played: break
		if hid == _owner: _record_play_metrics(bm, card, cost)
		played += 1
		_resolve_policy_discard(bm)
	return played

func _result(bm: Object, turns: int, trace: Array, reason: String = "") -> Dictionary:
	var observation: Array = _observed[bm.get_instance_id()]
	var fallbacks: int = _fallbacks[bm.get_instance_id()]
	_observed.erase(bm.get_instance_id())
	_fallbacks.erase(bm.get_instance_id())
	var events: Array = bm.pressure_events.duplicate(true)
	var result := super._result(bm, turns, trace, reason)
	result["observations"] = observation
	result["pressure_events"] = events
	result["target_policy_declined_fallbacks"] = fallbacks
	return result
