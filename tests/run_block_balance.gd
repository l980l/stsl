extends "res://tests/run_archetype_playtest.gd"

const BalanceBM = preload("res://tests/block_balance_battle_manager.gd")
const SCENARIOS := {
	"egyptian_trio": ["egyptian.anubis_guard", "egyptian.sand_scout", "egyptian.nile_crocodile"],
	"sekhmet": ["egyptian.sekhmet"],
	"osiris": ["egyptian.osiris"],
	"surtr": ["norse.surtr"],
}
var _keep := false
var _hp_percent := 100

func _run() -> void:
	AudioServer.set_bus_mute(0, true)
	_set_legacy_combat(true)
	_all_enemies = true
	_cap = 120
	for card in Catalog.get_all_cards():
		_sources[card.card_name] = card
	var enemies := {}
	for enemy in Monsters.get_all_monsters():
		enemies[enemy.enemy_name] = enemy
	var rows: Array = []
	var invalid := 0
	for hero_id in PACKAGES:
		_owner = hero_id
		var heroes: Array = [hero_id]
		for partner in ["napoleon", "yi_sun_sin", "cleopatra"]:
			if partner not in heroes and heroes.size() < 3:
				heroes.append(partner)
		for package in PACKAGES[hero_id]:
			_package = package
			for encounter in SCENARIOS:
				_encounter.clear()
				for id in SCENARIOS[encounter]:
					if not enemies.has("enemy." + id):
						push_error("Missing enemy " + id)
						quit(1)
						return
					_encounter.append(enemies["enemy." + id])
				for hp_percent in [100, 50]:
					_hp_percent = hp_percent
					var segment := {"label": hero_id + ":" + ",".join(package), "hero_ids": heroes, "probe_card": ""}
					_keep = true
					var before := await _simulate(_encounter[0], segment, 0, 101, true)
					_keep = false
					var after := await _simulate(_encounter[0], segment, 0, 101, true)
					var initial_equal: bool = before.initial_hash == after.initial_hash
					if not initial_equal or before.outcome == "incomplete" or after.outcome == "incomplete":
						invalid += 1
					var trajectory := JSON.stringify([before.trace, after.trace]).sha256_text()
					before.erase("trace")
					after.erase("trace")
					rows.append({"hero": hero_id, "package": package.duplicate(), "heroes": heroes.duplicate(), "encounter": encounter, "initial_hp_percent": hp_percent, "seed": 101, "grade": 0, "before": before, "after": after, "initial_equal": initial_equal, "trajectory_hash": trajectory, "hp_delta": after.remaining_hp - before.remaining_hp, "input_delta": after.hero_input_turns - before.hero_input_turns})
		print("Block balance completed: " + hero_id)
	var hashes := _fingerprints()
	for path in ["res://tests/run_block_balance.gd", "res://tests/block_balance_battle_manager.gd", "res://tests/run_archetype_playtest.gd"]:
		hashes[path] = FileAccess.get_sha256(path)
	var report := {"schema": 1, "contract": "docs/game_design/block_balance_evaluation.md", "source_commit": _source_commit, "dirty": _dirty, "source_sha256": hashes, "scenarios": SCENARIOS, "seed": 101, "cap": _cap, "policy": "first affordable hand-order; first living enemy; lowest-HP ally; transfers exclude self", "fixtures": "18 owner starter10+reward2 packages; two partners starter10; base grade; no relic; crit off; 100/50 percent initial HP; both sides small units", "integrity_failures": invalid, "summary": _summary(rows), "runs": rows}
	var path := "user://block_balance.json"
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Cannot write block balance report")
		quit(1)
		return
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print("Block balance report: " + ProjectSettings.globalize_path(path))
	print(JSON.stringify(report.summary))
	quit(0 if invalid == 0 and rows.size() == 144 else 1)

func _make_battle_manager():
	var bm := BalanceBM.new()
	bm.keep_block = _keep
	return bm

func _on_battle_ready(bm: Object) -> void:
	for hero in bm.team_mgr.heroes:
		bm.team_mgr._hero_hp[hero.hero_id] = maxi(1, hero.max_hp * _hp_percent / 100)
	bm.set_meta("initial_hash", JSON.stringify(_snapshot(bm, "initial", "", 0)).sha256_text())

func _result(bm: Object, turns: int, trace: Array, reason: String = "") -> Dictionary:
	var result := super._result(bm, turns, trace, reason)
	result["initial_hash"] = bm.get_meta("initial_hash")
	result["expired_block"] = bm.expired_block
	result["attacked_actions"] = bm.attacked_actions
	result["living_heroes"] = bm.team_mgr.get_living_heroes().size()
	result["trajectory_hash"] = JSON.stringify(trace).sha256_text()
	return result

func _summary(rows: Array) -> Dictionary:
	var out := {"pairs": rows.size(), "unique_paired_trajectories": 0, "before": {}, "after": {}, "new_losses": 0, "new_caps": 0, "hp_delta_min": 0, "hp_delta_sum": 0, "expired_block": 0, "segments": {}}
	var unique := {}
	for row in rows:
		unique[row.trajectory_hash] = true
		for side in ["before", "after"]:
			out[side][row[side].outcome] = int(out[side].get(row[side].outcome, 0)) + 1
		if row.before.outcome == "win" and row.after.outcome == "loss":
			out.new_losses += 1
		if row.before.outcome == "win" and row.after.outcome == "capped":
			out.new_caps += 1
		out.hp_delta_min = mini(out.hp_delta_min, row.hp_delta)
		out.hp_delta_sum += row.hp_delta
		out.expired_block += row.after.expired_block
		var key: String = "%s:%s:%d" % [row.hero, ",".join(row.package), row.initial_hp_percent]
		if not out.segments.has(key):
			out.segments[key] = {"pairs": 0, "before_wins": 0, "after_wins": 0, "hp_delta_sum": 0, "input_delta_sum": 0}
		var segment: Dictionary = out.segments[key]
		segment.pairs += 1
		segment.before_wins += int(row.before.won)
		segment.after_wins += int(row.after.won)
		segment.hp_delta_sum += row.hp_delta
		segment.input_delta_sum += row.input_delta
	out.unique_paired_trajectories = unique.size()
	return out
