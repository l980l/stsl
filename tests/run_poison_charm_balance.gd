extends "res://tools/simulate_small_number_battles.gd"

# Reuse the production ATB sampler, conversion, disposal and frozen traces.
# No alternate combat or card-effect implementation lives in this evaluator.
const BUILDS := {
	"starter": [],
	"poison": ["venom_needle", "venom_needle", "asp_fang", "asp_fang", "nile_mist", "defend", "defend", "serpent_power", "pharaoh_venom", "poison_ritual"],
	"charm_control": ["strike", "strike", "defend", "defend", "temptation", "temptation", "nile_whisper", "queens_dignity", "cleopatras_kiss", "serpent_ritual"],
	"charm_damage": ["strike", "strike", "defend", "defend", "temptation", "temptation", "nile_whisper", "queens_dignity", "charm_execution", "golden_throne"],
}
var _build := "starter"
var _meters: Dictionary = {}

func _run() -> void:
	AudioServer.set_bus_mute(0, true)
	_set_legacy_combat(true)
	_all_enemies = true # Full converter AND live runtime literal scaling.
	_cap = 96
	var selected: Array = []
	var seen := {}
	for enemy in Monsters.get_all_monsters():
		if enemy.mythology not in ["egyptian", "norse"]:
			continue
		var key := "%s:%s" % [enemy.mythology, enemy.grade]
		if not seen.has(key):
			seen[key] = true
			selected.append(enemy)
	var rows: Array = []
	for build in BUILDS:
		_build = build
		for enemy in selected:
			for grade in [0, 1]:
				for seed_value in DEFAULT_SEEDS:
					rows.append(await _paired_run(enemy, {"label": build, "hero_ids": ["cleopatra"], "probe_card": ""}, grade, seed_value))
	var hashes := _fingerprints()
	hashes["res://tests/run_poison_charm_balance.gd"] = FileAccess.get_sha256("res://tests/run_poison_charm_balance.gd")
	var report := {"schema": 1, "contract": "docs/game_design/poison_charm_evaluation.md", "source_commit": OS.get_environment("STSL_BOT_SOURCE_COMMIT"), "source_dirty": "evaluator additions; runtime unchanged", "source_sha256": hashes, "builds": BUILDS, "seeds": DEFAULT_SEEDS, "cap": _cap, "policy": "first affordable hand-order; first living enemy", "summary": _summarize(rows), "runs": rows}
	var path := "user://poison_charm_balance.json"
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Cannot write balance report")
		quit(1)
		return
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print(JSON.stringify(report.summary))
	print("Poison/charm report: " + ProjectSettings.globalize_path(path))
	quit(0)

func _starter_cards(hero_id: String, grade: int, candidate: bool) -> Array:
	if _build == "starter":
		return super._starter_cards(hero_id, grade, candidate)
	var result: Array = []
	for slug in BUILDS[_build]:
		var card := _catalog_card("card.cleopatra.%s.name" % slug)
		assert(card != null, "Unknown build card: " + slug)
		result.append(_variant_card(card, grade, candidate))
	return result

func _attach_meters(bm: Object) -> void:
	if not _meters.has(bm.get_instance_id()):
		var meter := {"poison_signal_damage": 0, "enthrall_applications": 0, "cards_played": 0}
		var enthrall_levels := {}
		_meters[bm.get_instance_id()] = meter
		bm.poison_tick_applied.connect(func(target: String, amount: int) -> void:
			if target.begins_with("enemy"):
				meter.poison_signal_damage += amount
		)
		bm.status_applied.connect(func(target: String, status: String, _stacks: int) -> void:
			if target.begins_with("enemy") and status == "enthrall":
				# The signal also reports remaining stacks on consumption. Count
				# positive actual-state deltas, not the signal's mixed-semantics value.
				var index := int(target.trim_prefix("enemy_"))
				var current: int = bm._enemy_status[index].get("enthrall", 0)
				meter.enthrall_applications += maxi(0, current - int(enthrall_levels.get(target, 0)))
				enthrall_levels[target] = current
		)

func _play_hand_order(bm: Object, hero_id: String) -> int:
	_attach_meters(bm)
	var played := super._play_hand_order(bm, hero_id)
	_meters[bm.get_instance_id()].cards_played += played
	return played

func _result(bm: Object, hero_input_turns: int, trace: Array, incomplete_reason: String = "") -> Dictionary:
	var result := super._result(bm, hero_input_turns, trace, incomplete_reason)
	result["telemetry"] = _meters.get(bm.get_instance_id(), {}).duplicate(true)
	_meters.erase(bm.get_instance_id())
	return result
