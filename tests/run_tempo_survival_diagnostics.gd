extends "res://tests/run_tempo_policy_balance.gd"

const Tempo = preload("res://tools/tempo_decision_policy.gd")
var _arm := ""
var _diagnostic := {}

func _run() -> void:
	AudioServer.set_bus_mute(0, true)
	_set_legacy_combat(true)
	_all_enemies = true
	_cap = 120
	_revert_martyr = false
	for card in Catalog.get_all_cards(): _sources[card.card_name] = card
	var monsters := {}
	for enemy in Monsters.get_all_monsters(): monsters[enemy.enemy_name] = enemy
	_encounter.clear()
	for name in TEMPO_SCENARIOS.egyptian_trio: _encounter.append(monsters["enemy." + name])
	var paths := _source_paths() + ["res://tests/run_tempo_survival_diagnostics.gd"]
	var start := _source_hashes(paths)
	var runs := []
	for definition in Definitions.DECKS:
		if definition.id not in ["joan_martyr", "genghis_horde"]: continue
		_owner = definition.hero
		_package = definition.cards
		_hp_percent = 50 if definition.id == "joan_martyr" else 25
		for arm in ["guard", "tempo", "guard_targets", "guard_order"]:
			_arm = arm
			var segment := {"label": definition.id + ":solo", "hero_ids": [_owner], "probe_card": ""}
			var result := await _simulate(_encounter[0], segment, 0, 505, true)
			result.erase("trace")
			runs.append({"deck": definition.id, "arm": arm, "hp_percent": _hp_percent, "seed": 505, "result": result})
	var report := {"contract": "docs/game_design/tempo_survival_v4.md", "source_commit": _source_commit, "dirty": _dirty, "source_sha256_start": start, "source_sha256_end": _source_hashes(paths), "runs": runs}
	var output := FileAccess.open("user://tempo_survival_diagnostics.json", FileAccess.WRITE)
	output.store_string(JSON.stringify(report, "\t"))
	output.close()
	print("Tempo survival diagnostics: ", ProjectSettings.globalize_path("user://tempo_survival_diagnostics.json"))
	for row in runs: print(row.deck, " / ", row.arm, " / ", row.result.outcome, " / HP", row.result.remaining_hp)
	quit(0 if report.source_sha256_start == report.source_sha256_end else 1)

func _on_battle_ready(bm: Object) -> void:
	super._on_battle_ready(bm)
	_diagnostic[bm.get_instance_id()] = []

func _play_hand_order(bm: Object, hid: String) -> int:
	if hid == _owner: _record_checkpoint(bm, hid)
	var played := 0
	while bm.is_player_turn:
		var old: Dictionary = Guard.choose(bm, hid)
		var tempo: Dictionary = Tempo.choose(bm, hid)
		var choice: Dictionary = old if _arm == "guard" else tempo
		if _arm in ["guard_targets", "guard_order"]:
			var ordered: Dictionary = tempo if _arm == "guard_targets" else old
			choice = ordered
			var card: Resource = ordered.get("card")
			if card != null:
				var evaluate_policy = Guard if _arm == "guard_targets" else Tempo
				var best_score := -INF
				for target in range(bm._enemy_alive.size()):
					if not bm.is_enemy_alive(target): continue
					var lock: int = bm._get_taunt_lock_target(hid)
					if lock >= 0 and bm._card_has_single_target(card) and target != lock: continue
					var value: Dictionary = evaluate_policy.evaluate(bm, card, target, ordered.ally)
					if value.score > best_score:
						best_score = value.score
						choice = ordered.duplicate()
						choice.target = target
		var card: Resource = choice.get("card")
		var scores := []
		for option in bm.deck_mgr.get_hand(hid):
			if not bm.deck_mgr.can_play_hero(hid, option): continue
			for target in range(bm._enemy_alive.size()):
				if not bm.is_enemy_alive(target): continue
				scores.append({"card": option.card_name, "target": target, "guard": Guard.evaluate(bm, option, target, hid), "tempo": Tempo.evaluate(bm, option, target, hid)})
		var enemies := []
		for i in range(bm._enemy_alive.size()):
			var intents := []
			for intent in bm.get_enemy_current_intents(i): intents.append({"type": intent.action_type, "target": intent.target, "display_damage": bm.get_intent_display_damage(i, intent)})
			enemies.append({"index": i, "alive": bm.is_enemy_alive(i), "hp": bm.get_enemy_hp(i), "intents": intents})
		_diagnostic[bm.get_instance_id()].append({"owner_input": _telemetry[bm.get_instance_id()].owner_inputs, "hp": bm.team_mgr.get_current_hp(hid), "block": bm.get_hero_block(hid), "energy": bm.deck_mgr.get_energy(hid), "incoming": Policy.incoming(bm, hid), "enemies": enemies, "queue": bm.get_turn_queue_preview(12), "scores": scores, "choice": {"card": card.card_name if card else "", "target": choice.get("target", -1)}})
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
	var diagnostics: Array = _diagnostic[bm.get_instance_id()]
	_diagnostic.erase(bm.get_instance_id())
	var result := super._result(bm, turns, trace, reason)
	result["diagnostics"] = diagnostics
	return result
