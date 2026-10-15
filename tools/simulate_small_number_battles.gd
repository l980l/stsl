extends SceneTree

# Paired, deterministic combat sampler for the comparison-only small-number
# profile. It is not campaign simulation or a win-rate claim: it alternates
# actual BattleManager hero/enemy phases, using only starter decks plus one
# labelled reward-card probe segment.
const Profile = preload("res://resources/balance/small_number_profile.gd")
const Catalog = preload("res://resources/card_catalog.gd")
const Monsters = preload("res://resources/monster_catalog.gd")
const HeroRegistry = preload("res://resources/heroes/hero_registry.gd")
const BM = preload("res://autoload/battle_manager.gd")
const TM = preload("res://autoload/team_manager.gd")
const DM = preload("res://autoload/deck_manager.gd")
const Enemy = preload("res://resources/enemy_resource.gd")
const Intent = preload("res://resources/intent_resource.gd")
const EnemySmallNumbers = preload("res://resources/balance/enemy_small_numbers.gd")

const UNIT_DIVISOR := 10
const DEFAULT_SEEDS := [101, 202, 303]
const DEFAULT_CAP := 24
const HERO_SEGMENTS := [["napoleon"], ["cleopatra"], ["yi_sun_sin"], ["joan_of_arc"], ["genghis_khan"], ["musashi"]]
const REWARD_PROBES := [
	{"hero_ids": ["genghis_khan"], "card": "card.genghis_khan.desert_cavalry.name"},
	{"hero_ids": ["cleopatra"], "card": "card.cleopatra.nile_fury.name"},
]
const FULL_ENEMY_SEGMENT := {"label": "full_catalog:napoleon,cleopatra,yi_sun_sin", "hero_ids": ["napoleon", "cleopatra", "yi_sun_sin"], "probe_card": ""}

var _seeds: Array = DEFAULT_SEEDS.duplicate()
var _cap := DEFAULT_CAP
var _output := "user://small_number_battle_simulation.json"
var _source_commit := "unspecified"
var _dirty := "unspecified"
var _pressure := "normal"
var _all_enemies := false

func _init() -> void:
	_parse_args()
	call_deferred("_run")

func _parse_args() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="):
			_output = arg.trim_prefix("--output=")
		elif arg.begins_with("--seeds="):
			_seeds = _parse_seeds(arg.trim_prefix("--seeds="))
		elif arg.begins_with("--cap="):
			_cap = max(1, int(arg.trim_prefix("--cap=")))
		elif arg.begins_with("--pressure="):
			_pressure = arg.trim_prefix("--pressure=")
		elif arg == "--all-enemies":
			_all_enemies = true
		elif arg.begins_with("--revision="):
			_source_commit = arg.trim_prefix("--revision=")
		elif arg.begins_with("--dirty="):
			_dirty = arg.trim_prefix("--dirty=")
	_source_commit = OS.get_environment("STSL_BOT_SOURCE_COMMIT") if OS.get_environment("STSL_BOT_SOURCE_COMMIT") != "" else _source_commit
	_dirty = OS.get_environment("STSL_BOT_SOURCE_DIRTY") if OS.get_environment("STSL_BOT_SOURCE_DIRTY") != "" else _dirty

func _parse_seeds(raw: String) -> Array:
	var result: Array = []
	for item in raw.split(",", false):
		if item.is_valid_int():
			result.append(int(item))
	return result if not result.is_empty() else DEFAULT_SEEDS.duplicate()

func _run() -> void:
	AudioServer.set_bus_mute(0, true)
	# Source fixtures are always constructed in original units.  Candidate
	# runtime temporarily opts into live units only after the fixture exists.
	_set_legacy_combat(true)
	if _pressure not in ["normal", "hard"]:
		push_error("Unknown pressure preset: " + _pressure)
		quit(1)
		return
	var admitted := _admitted_normals()
	var entries: Array = _all_catalog_entries() if _all_enemies else admitted.accepted
	var segments: Array = [FULL_ENEMY_SEGMENT] if _all_enemies else _segments()
	var grades: Array = [0] if _all_enemies else [0, 1]
	var rows: Array = []
	for entry in entries:
		for segment in segments:
			for grade in grades:
				for seed in _seeds:
					rows.append(await _paired_run(entry.enemy, segment, grade, seed))
	var report := {
		"schema": 2,
		"profile": Profile.PROFILE_ID + "-battle-sampler",
		"metric_contract": {
			"unit": "one deterministic battle trajectory",
			"population": "all catalog enemies x one three-hero starter segment x base grade x seeds" if _all_enemies else "admitted NORMAL factory enemies x starter/reward segments x grades x seeds",
			"policy": "hero turns use first affordable hand-order card; first living enemy is selected; required discard picks discard first hand-order card",
			"comparison": "legacy uses original units; candidate uses combat_unit_divisor=10 and explicit HP-domain enemy/hero conversion",
			"scheduler": "production BattleManager ATB queue via start_player_turn/end_player_turn; enemy phases are automatically advanced between hero input turns",
			"critical_hits": "disabled through BattleManager test hook in both paired sides",
			"cap": {"hero_input_turns": _cap, "counting": "each input-open hero turn; on the capped turn the sampler stops before advancing the queue into a new actor phase"},
			"boundary": "paired rules evidence only; no campaign, rewards, relics, player adaptation, or fun claim",
		},
		"source_commit": _source_commit,
		"dirty": _dirty,
		"seeds": _seeds,
		"pressure": {"preset": _pressure, "synthetic": _pressure == "hard", "enemy_hp_multiplier": 8 if _pressure == "hard" else 1, "enemy_attack_multiplier": 4 if _pressure == "hard" else 1, "other_intents": "unchanged; scale applied before candidate conversion"},
		"mode": "all_enemies" if _all_enemies else "admitted_normals",
		"full_catalog_segment": FULL_ENEMY_SEGMENT if _all_enemies else {},
		"admitted_normals": admitted.names,
		"unsupported_normals": admitted.unsupported,
		"runs": rows,
		"summary": _summarize(rows),
		"source_sha256": _fingerprints(),
	}
	var file := FileAccess.open(_output, FileAccess.WRITE)
	if file == null:
		push_error("Cannot write simulation report: " + _output)
		quit(1)
		return
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	_set_legacy_combat(true)
	print("Small-number battle simulation: %d paired trajectories; mode=%s; report: %s" % [rows.size(), "all_enemies" if _all_enemies else "admitted_normals", ProjectSettings.globalize_path(_output)])
	quit(0)

func _segments() -> Array:
	var result: Array = []
	for ids in HERO_SEGMENTS:
		result.append({"label": "starter:" + ",".join(ids), "hero_ids": ids, "probe_card": ""})
	for probe in REWARD_PROBES:
		result.append({"label": "reward_probe:" + probe.card, "hero_ids": probe.hero_ids, "probe_card": probe.card})
	return result

func _admitted_normals() -> Dictionary:
	var accepted: Array = []
	var names: Array = []
	var unsupported: Array = []
	for source in Monsters.get_all_monsters():
		if source.grade != Enemy.Grade.NORMAL:
			continue
		var reason := _unsupported_enemy_reason(source)
		if reason == "":
			accepted.append({"enemy": source, "mythology": source.mythology})
			names.append(source.enemy_name)
		else:
			unsupported.append({"enemy": source.enemy_name, "mythology": source.mythology, "reason": reason})
	return {"accepted": accepted, "names": names, "unsupported": unsupported}

func _all_catalog_entries() -> Array:
	var entries: Array = []
	for enemy in Monsters.get_all_monsters():
		entries.append({"enemy": enemy, "mythology": enemy.mythology})
	return entries

func _unsupported_enemy_reason(enemy: Resource) -> String:
	if enemy.signatures_enabled:
		return "signature_hooks_enabled"
	if not enemy.phase_patterns.is_empty() or not enemy.phase_thresholds.is_empty() or not enemy.turn_modes.is_empty():
		return "phase_or_form_hook"
	if enemy.death_trigger != null or not enemy.card_count_trigger.is_empty() or not enemy.counter_window_intent.is_empty():
		return "reaction_hook"
	if enemy.dynamic_affinity_pool.size() > 0 or enemy.dynamic_resistance_pool.size() > 0 or enemy.time_limit_turns > 0:
		return "dynamic_resistance_or_time_hook"
	for intent in enemy.intent_pattern:
		if not _intent_supported(intent):
			return "unsupported_intent:%d:%s" % [intent.action_type, intent.status_type]
	return ""

func _intent_supported(intent: Resource) -> bool:
	match intent.action_type:
		Intent.ActionType.ATTACK, Intent.ActionType.PREPARE:
			return true
		Intent.ActionType.BUFF:
			return intent.status_type in ["", "block", "strength"]
		Intent.ActionType.DEBUFF:
			return intent.status_type in ["poison", "weak", "vulnerable", "silence", "taunt"]
		Intent.ActionType.HEAL_ALLY:
			return true
	return false

func _paired_run(enemy_source: Resource, segment: Dictionary, grade: int, seed_value: int) -> Dictionary:
	var legacy := await _simulate(enemy_source, segment, grade, seed_value, false)
	var candidate := await _simulate(enemy_source, segment, grade, seed_value, true)
	return {
		"enemy": enemy_source.enemy_name,
		"mythology": enemy_source.mythology,
		"segment": segment.label,
		"grade": grade,
		"seed": seed_value,
		"legacy": legacy,
		"candidate": candidate,
		"deltas": {"won": int(candidate.won) - int(legacy.won), "hero_input_turns": candidate.hero_input_turns - legacy.hero_input_turns, "remaining_hp_normalized": candidate.remaining_hp - legacy.remaining_hp / float(UNIT_DIVISOR)},
		"trajectory_hash": _trajectory_hash(legacy, candidate),
	}

func _simulate(enemy_source: Resource, segment: Dictionary, grade: int, seed_value: int, candidate: bool) -> Dictionary:
	seed(seed_value)
	_set_legacy_combat(true)
	var bm := BM.new()
	bm.turn_interval = 0.0
	bm._test_disable_crit = true
	bm.combat_unit_divisor = UNIT_DIVISOR if candidate else 1
	bm.team_mgr = TM.new()
	bm.deck_mgr = DM.new()
	var hero_ids: Array = segment.hero_ids
	for hero_id in hero_ids:
		var hero: Resource = HeroRegistry.make_hero(hero_id)
		if candidate:
			hero.max_hp = _small_positive(hero.max_hp)
		bm.team_mgr.add_hero(hero)
		for card in _starter_cards(hero_id, grade, candidate):
			bm.deck_mgr.add_card_to_deck(card)
	if segment.probe_card != "":
		var probe := _catalog_card(segment.probe_card)
		if probe != null:
			bm.deck_mgr.add_card_to_deck(_variant_card(probe, grade, candidate))
	var enemy := _variant_enemy(enemy_source, candidate)
	bm.setup_battle([enemy])
	var trace: Array = []
	bm.turn_started.connect(func(actor_id: String) -> void:
		trace.append(_snapshot(bm, "turn_started", actor_id, 0))
	)
	bm.turn_ended.connect(func(actor_id: String) -> void:
		trace.append(_snapshot(bm, "turn_ended", actor_id, 0))
	)
	bm.card_effects_resolved.connect(func(card: Resource) -> void:
		trace.append(_snapshot(bm, "card_resolved", card.card_name, 0))
	)
	var hero_input_turns := 0
	# start_player_turn follows BattleManager's ATB queue. If the next actor is
	# an enemy it resolves that enemy (and any subsequent enemy chain) before it
	# returns with a hero input turn open.
	await bm.start_player_turn()
	while bm.is_battle_active and hero_input_turns < _cap:
		var hero_id: String = bm.get_current_hero_id()
		if hero_id == "" or not bm.is_player_turn:
			trace.append(_snapshot(bm, "incomplete", bm.get_current_actor_id(), 0))
			var incomplete := _result(bm, hero_input_turns, trace, "no_open_hero_input")
			_dispose_battle(bm)
			return incomplete
		var played := _play_hand_order(bm, hero_id)
		await process_frame
		_resolve_pending_discard(bm)
		trace.append(_snapshot(bm, "hero_input_complete", hero_id, played))
		hero_input_turns += 1
		if not bm.is_battle_active:
			break
		# A cap stops before the queue advances into a fresh enemy/hero phase.
		if hero_input_turns >= _cap:
			break
		# This calls the real post phase and advances ATB until the next input
		# turn; do not manually execute enemy phases in this sampler.
		await bm.end_player_turn()
	var result := _result(bm, hero_input_turns, trace)
	_dispose_battle(bm)
	return result

func _dispose_battle(bm: Object) -> void:
	bm.deck_mgr.free()
	bm.team_mgr.free()
	bm.free()
	# No later fixture may inherit candidate mode accidentally.
	_set_legacy_combat(true)

func _result(bm: Object, hero_input_turns: int, trace: Array, incomplete_reason: String = "") -> Dictionary:
	var won := true
	for alive in bm._enemy_alive:
		if alive:
			won = false
			break
	var all_heroes_dead: bool = bm.team_mgr.get_living_heroes().is_empty()
	var capped: bool = bm.is_battle_active and hero_input_turns >= _cap
	var outcome := "win" if won else ("loss" if all_heroes_dead else ("capped" if capped else "incomplete"))
	return {"outcome": outcome, "incomplete_reason": incomplete_reason, "won": won, "capped": capped, "hero_input_turns": hero_input_turns, "remaining_hp": _team_hp(bm), "enemy_hp": bm.get_enemy_hp(0), "trace": trace}

func _starter_cards(hero_id: String, grade: int, candidate: bool) -> Array:
	var path := "res://resources/cards/cards_%s.gd" % hero_id
	var script: GDScript = load(path)
	var result: Array = []
	if script == null:
		return result
	for card in script.starter_deck():
		result.append(_variant_card(card, grade, candidate))
	return result

func _variant_card(card: Resource, grade: int, candidate: bool) -> Resource:
	if candidate:
		var pair: Dictionary = Profile.candidate_pair(card)
		return pair.upgraded if grade == 1 else pair.base
	var actual := card.duplicate(true)
	if grade == 1:
		var gm = preload("res://autoload/game_manager.gd").new()
		gm.upgrade_card(actual)
		gm.free()
	return actual

func _variant_enemy(source: Resource, candidate: bool) -> Resource:
	var enemy: Resource = source.duplicate(true)
	if _pressure == "hard":
		enemy.max_hp *= 8
		for intent in enemy.intent_pattern:
			if intent.action_type == Intent.ActionType.ATTACK:
				intent.value *= 4
	if not candidate:
		return enemy
	if _all_enemies:
		# Runtime systems (signatures/interactions/hardcoded literals) consult
		# CombatScale at execution time, so leave candidate mode enabled until
		# this exact battle is disposed.
		_set_legacy_combat(false)
		return EnemySmallNumbers.convert(enemy)
	enemy.max_hp = _small_positive(enemy.max_hp)
	enemy.charm_resistance = _small_positive(enemy.charm_resistance) if enemy.charm_resistance > 0 else 0
	for intent in enemy.intent_pattern:
		match intent.action_type:
			Intent.ActionType.ATTACK, Intent.ActionType.HEAL_ALLY:
				intent.value = _small_positive(intent.value)
			Intent.ActionType.BUFF:
				if intent.status_type in ["", "block", "strength"]:
					intent.value = _small_positive(intent.value)
			Intent.ActionType.DEBUFF:
				if intent.status_type == "poison":
					intent.value = _small_positive(intent.value)
	return enemy

func _set_legacy_combat(legacy: bool) -> void:
	OS.set_environment("STSL_LEGACY_COMBAT", "1" if legacy else "")

func _play_hand_order(bm: Object, hero_id: String) -> int:
	var played := 0
	while bm.is_player_turn:
		var card_to_play: Resource = null
		for card in bm.deck_mgr.get_hand(hero_id):
			if bm.deck_mgr.can_play_hero(hero_id, card):
				card_to_play = card
				break
		if card_to_play == null:
			break
		var target := _first_living_enemy(bm)
		if not bm.play_card(card_to_play, target):
			break
		played += 1
		if not bm._pending_discard_pick.is_empty():
			_resolve_pending_discard(bm)
	return played

func _resolve_pending_discard(bm: Object) -> void:
	if bm._pending_discard_pick.is_empty():
		return
	var owner: String = bm.get_pending_discard_owner()
	var hand: Array = bm.deck_mgr.get_hand(owner)
	bm.resolve_pending_discard_pick(hand[0] if not hand.is_empty() else null)

func _first_living_enemy(bm: Object) -> int:
	for index in range(bm._enemy_alive.size()):
		if bm._enemy_alive[index]:
			return index
	return -1

func _team_hp(bm: Object) -> int:
	var total := 0
	for hero in bm.team_mgr.heroes:
		total += bm.team_mgr.get_current_hp(hero.hero_id)
	return total

func _catalog_card(card_name: String) -> Resource:
	for card in Catalog.get_all_cards():
		if card.card_name == card_name:
			return card
	return null

func _small_positive(value: int) -> int:
	return max(1, int(floor(float(value) / UNIT_DIVISOR + 0.5))) if value > 0 else value

static func _pile_snapshot(cards: Array) -> Array:
	var result: Array = []
	for card in cards:
		result.append({"name": card.card_name, "owner": card.owner_id, "grade": card.upgrade_level, "cost": card.cost})
	return result

static func _snapshot(bm: Object, phase: String, actor: String, played: int) -> Dictionary:
	var heroes: Dictionary = {}
	for hero in bm.team_mgr.heroes:
		var hero_id: String = hero.hero_id
		var entry: Dictionary = bm.deck_mgr._heroes.get(hero_id, {})
		# Hand order is policy input; all pile orders are future draw input.
		# Freeze nested state now rather than retaining mutable live references.
		var deck: Dictionary = {}
		for pile in ["draw", "hand", "discard", "exhaust"]:
			deck[pile] = _pile_snapshot(entry.get(pile, []))
		for key in ["energy", "pending_cost_reduction", "pending_all_cost_zero", "cards_played_this_turn", "draws_this_turn"]:
			deck[key] = entry.get(key, 0)
		heroes[hero_id] = {"hp": bm.team_mgr.get_current_hp(hero_id), "alive": bm.team_mgr.is_alive(hero_id), "block": bm._hero_block.get(hero_id, 0), "status": bm._hero_status.get(hero_id, {}).duplicate(true), "deck": deck}
	return {"phase": phase, "actor": actor, "played": played, "enemy_hp": bm._enemy_hp.duplicate(), "enemy_alive": bm._enemy_alive.duplicate(), "enemy_block": bm._enemy_block.duplicate(), "enemy_status": bm._enemy_status.duplicate(true), "enemy_intent_index": bm._enemy_intent_index.duplicate(), "heroes": heroes, "powers": bm._active_powers.duplicate(true)}

func _trajectory_hash(legacy: Dictionary, candidate: Dictionary) -> String:
	return JSON.stringify({"legacy": legacy.trace, "candidate": candidate.trace}).sha256_text()

func _summarize(rows: Array) -> Dictionary:
	var wins := {"legacy": 0, "candidate": 0}
	var caps := {"legacy": 0, "candidate": 0}
	var outcomes := {"legacy": {}, "candidate": {}}
	var hashes: Dictionary = {}
	var outcome_mismatches := 0
	var faster := 0
	var slower := 0
	var same_turns := 0
	var largest_hp: Dictionary = {}
	var largest_turn: Dictionary = {}
	var largest_hp_abs := -1.0
	var largest_turn_abs := -1
	for row in rows:
		for side in ["legacy", "candidate"]:
			if row[side].won: wins[side] += 1
			if row[side].capped: caps[side] += 1
			var outcome: String = row[side].outcome
			outcomes[side][outcome] = int(outcomes[side].get(outcome, 0)) + 1
			hashes[row.trajectory_hash] = true
		if row.legacy.outcome != row.candidate.outcome:
			outcome_mismatches += 1
		var turn_delta: int = int(row.deltas.hero_input_turns)
		if turn_delta < 0:
			faster += 1
		elif turn_delta > 0:
			slower += 1
		else:
			same_turns += 1
		var hp_delta: float = float(row.deltas.remaining_hp_normalized)
		if absf(hp_delta) > largest_hp_abs:
			largest_hp_abs = absf(hp_delta)
			largest_hp = _delta_row(row)
		if absi(turn_delta) > largest_turn_abs:
			largest_turn_abs = absi(turn_delta)
			largest_turn = _delta_row(row)
	return {"paired_trajectories": rows.size(), "wins": wins, "caps": caps, "outcomes": outcomes, "outcome_mismatches": outcome_mismatches, "turn_delta_counts": {"candidate_faster": faster, "candidate_slower": slower, "same": same_turns}, "largest_abs_normalized_hp_delta": largest_hp, "largest_abs_turn_delta": largest_turn, "unique_paired_trajectory_hashes": hashes.size(), "effective_unique_fraction": float(hashes.size()) / max(1, rows.size())}

func _delta_row(row: Dictionary) -> Dictionary:
	return {"enemy": row.enemy, "mythology": row.mythology, "segment": row.segment, "grade": row.grade, "seed": row.seed, "deltas": row.deltas, "legacy": {"outcome": row.legacy.outcome, "hero_input_turns": row.legacy.hero_input_turns, "remaining_hp": row.legacy.remaining_hp, "enemy_hp": row.legacy.enemy_hp}, "candidate": {"outcome": row.candidate.outcome, "hero_input_turns": row.candidate.hero_input_turns, "remaining_hp": row.candidate.remaining_hp, "enemy_hp": row.candidate.enemy_hp}}


func _fingerprints() -> Dictionary:
	var paths := ["res://autoload/battle_manager.gd", "res://autoload/deck_manager.gd", "res://autoload/team_manager.gd", "res://autoload/game_manager.gd", "res://autoload/enemy_signature_system.gd", "res://autoload/enemy_interaction_system.gd", "res://resources/balance/combat_scale.gd", "res://resources/balance/enemy_small_numbers.gd", "res://resources/balance/small_number_profile.gd", "res://resources/card_catalog.gd", "res://resources/monster_catalog.gd", "res://resources/heroes/hero_registry.gd", "res://resources/enemy_resource.gd", "res://resources/effect_resource.gd", "res://resources/intent_resource.gd", "res://resources/card_resource.gd", "res://resources/cards/card_revision_v3.gd", "res://tools/simulate_small_number_battles.gd"]
	for mythology in Monsters.MYTH_ORDER:
		paths.append("res://resources/enemies/%s/%s_normals.gd" % [mythology, mythology])
		for act in [1, 2, 3]:
			paths.append("res://resources/enemies/%s/%s_act%d.gd" % [mythology, mythology, act])
	for hero_id in HeroRegistry.all_hero_ids():
		paths.append("res://resources/cards/cards_%s.gd" % hero_id)
	var result := {}
	for path in paths:
		result[path] = FileAccess.get_sha256(path)
	return result
