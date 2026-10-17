extends SceneTree

const GM = preload("res://autoload/game_manager.gd")
const Maps = preload("res://autoload/map_generator.gd")
const Room = preload("res://resources/map_node_resource.gd")
const Catalog = preload("res://resources/monster_catalog.gd")
var passed := 0
var failed := 0
var checks: Array = []

func _init() -> void:
	call_deferred("_run")

func _check(ok: bool, label: String) -> void:
	checks.append({"ok": ok, "label": label})
	if ok:
		passed += 1
	else:
		failed += 1
		push_error("ENCOUNTER DIVERSITY: " + label)

func _run() -> void:
	AudioServer.set_bus_mute(0, true)
	_unit_checks()
	_save_file_checks()
	var rows := _sample_paths()
	var summary := {}
	var unique_paths := {}
	for row in rows:
		unique_paths[row.path_hash] = true
		for arm in row.arms:
			if not summary.has(arm):
				summary[arm] = {"normals": 0, "normal_repeats": 0, "normal_consecutive": 0, "species_repeats": 0, "species_visits": 0, "elites": 0, "elite_repeats": 0, "elite_consecutive": 0, "band_violations": 0, "normal_index_sum": 0, "unique_sequences": {}}
			var totals: Dictionary = summary[arm]
			for key in row.arms[arm]:
				if key != "sequence":
					totals[key] += int(row.arms[arm][key])
			totals.unique_sequences[JSON.stringify(row.arms[arm].sequence).sha256_text()] = true
	for arm in summary:
		summary[arm].unique_sequences = summary[arm].unique_sequences.size()
	_check(rows.size() == 3600, "six myths x three acts x hundred seeds x two paths")
	_check(summary.new.band_violations == 0, "new selector never leaves difficulty window")
	_check(summary.new.normal_consecutive == 0 and summary.new.elite_consecutive == 0, "authored pools never repeat consecutive same-kind encounters")
	_check(summary.new.normal_repeats < summary.old.normal_repeats, "normal repeated packs decrease versus old policy")
	_check(summary.new.elite_repeats < summary.old.elite_repeats, "elite repeated packs decrease versus old policy")
	_check(checks.size() == 45, "all mandatory rule and real-save checks executed")
	var sources := {}
	for path in ["autoload/game_manager.gd", "autoload/map_generator.gd", "autoload/save_manager.gd", "resources/map_node_resource.gd", "tests/run_encounter_diversity.gd"]:
		sources[path] = FileAccess.get_sha256("res://" + path)
	for myth in Catalog.MYTH_ORDER:
		for suffix in ["normals", "act1", "act2", "act3"]:
			var path: String = "resources/enemies/%s/%s_%s.gd" % [myth, myth, suffix]
			sources[path] = FileAccess.get_sha256("res://" + path)
	var report := {"schema": 1, "contract": "docs/game_design/encounter_diversity.md", "source_commit": OS.get_environment("STSL_BOT_SOURCE_COMMIT"), "dirty": OS.get_environment("STSL_BOT_SOURCE_DIRTY"), "source_sha256": sources, "unit": "one authored-map act path, not a won campaign", "seeds": "0..99", "paths": ["left", "right"], "unique_path_fixtures": unique_paths.size(), "passed": passed, "failed": failed, "checks": checks, "summary": summary, "runs": rows}
	var file := FileAccess.open("user://encounter_diversity.json", FileAccess.WRITE)
	if file == null:
		push_error("Cannot write encounter diversity report")
		quit(1)
		return
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print("Encounter diversity report: " + ProjectSettings.globalize_path("user://encounter_diversity.json"))
	print(JSON.stringify(summary))
	print("Encounter diversity: %d passed, %d failed" % [passed, failed])
	quit(1 if failed else 0)

func _unit_checks() -> void:
	var gm := GM.new()
	var packs: Array = [["a"], ["b"], ["c"], ["d"]]
	var seen := {}
	var previous := ""
	for i in range(8):
		var chosen: Array = gm._pick_fresh_encounter(packs, [1.0, 1.0, 1.0, 1.0], "normal:test")
		var key := gm._encounter_key("normal:test", chosen)
		_check(key != previous, "no consecutive pack " + str(i))
		if i < 4:
			_check(not seen.has(key), "unseen pack first " + str(i))
		seen[key] = true
		previous = key
	_check(gm.encounter_counts.values().all(func(n: int) -> bool: return n == 2), "exhausted pool uses every pack twice")
	_check(gm._encounter_key("normal:test", ["a", "b"]) == gm._encounter_key("normal:test", ["b", "a"]), "order aliases share history")
	_check(gm._encounter_key("normal:test", ["a", "a"]) != gm._encounter_key("normal:test", ["a"]), "pack multiplicity remains meaningful")
	gm.reset()
	gm._pick_fresh_encounter([["rat", "rat", "rat"]], [1.0], "normal:test")
	_check(gm.encounter_species_counts.get("test:rat", 0) == 1, "same-battle swarm counts once")
	_check(gm._pick_fresh_encounter([["rat"]], [1.0], "normal:other") == ["rat"], "myth namespaces do not collide")
	gm.reset()
	gm.encounter_species_counts["test:shared"] = 1
	_check(gm._pick_fresh_encounter([["shared", "x"], ["fresh"]], [1.0, 1.0], "normal:test") == ["fresh"], "unseen species break unused-pack tie")
	gm.reset()
	gm._pick_fresh_encounter([["only"], ["only"]], [1.0, 1.0], "normal:test")
	_check(gm._pick_fresh_encounter([["only"], ["only"]], [1.0, 1.0], "normal:test") == ["only"], "duplicate aliases cannot empty the fallback pool")
	_check(gm._pick_fresh_encounter([], [], "normal:test").is_empty(), "empty pool is safe")
	_check(gm._pick_fresh_encounter([["forbidden"]], [0.0], "normal:test").is_empty(), "no expansion beyond zero-weight difficulty window")
	_check(gm._normal_encounter_weights(10, 9) != gm._normal_encounter_weights(10, 12), "late progress no longer saturates at floor9")
	_check(gm._normal_encounter_weights(10, 12)[9] == 4.0, "last normal floor reaches final encounter peak")
	gm.reset()
	gm.act_mythologies = ["egyptian", "greek", "norse"]
	for _i in range(2):
		gm._make_normal_enemies()
	var first_elites := {}
	for _i in range(3):
		var elite: Resource = gm._make_elite_enemies()[0]
		_check(not first_elites.has(elite.enemy_name), "each elite occurs before reuse")
		first_elites[elite.enemy_name] = true
	var saved: Dictionary = JSON.parse_string(JSON.stringify(gm.to_dict()))
	var restored := GM.new()
	restored.from_dict(saved)
	_check(restored.act_mythologies == gm.act_mythologies, "JSON load preserves mythology order")
	_check(restored.encounter_counts == gm.encounter_counts and restored.encounter_species_counts == gm.encounter_species_counts and restored.last_encounters == gm.last_encounters, "JSON load preserves all encounter history")
	saved.encounter_history.counts.clear()
	_check(not gm.encounter_counts.is_empty(), "saved data is detached from live history")
	var last_elite: String = restored.last_encounters["elite:egyptian"]
	var next_elite: Resource = restored._make_elite_enemies()[0]
	_check(restored._encounter_key("elite:egyptian", [next_elite.enemy_name.get_slice(".", 2)]) != last_elite, "loaded elite still avoids previous elite")
	var history_before: Dictionary = restored.encounter_counts.duplicate(true)
	restored._start_next_act()
	_check(restored.encounter_counts == history_before, "act transition retains run history")
	var amount_before: int = _count(restored.encounter_counts)
	restored.start_event_battle(0, {})
	_check(_count(restored.encounter_counts) == amount_before + 1, "event battle shares normal history")
	amount_before = _count(restored.encounter_counts)
	restored._make_boss_enemies()
	Maps.generate(2, 77)
	_check(_count(restored.encounter_counts) == amount_before, "boss and unvisited map generation do not consume packs")
	restored.reset()
	_check(restored.encounter_counts.is_empty() and restored.encounter_species_counts.is_empty() and restored.last_encounters.is_empty(), "new run clears all history")
	restored.from_dict({"current_chapter": 1, "current_act": 2})
	_check(restored.act_mythologies.size() == 3 and restored.encounter_counts.is_empty(), "old save without history is supported without stale state")
	restored.from_dict({"encounter_history": {"counts": {"bad": -2, "bad2": "x", "good": 2.0}, "species_counts": [], "last": {"bad": 2}}})
	_check(restored.encounter_counts == {"good": 2} and restored.encounter_species_counts.is_empty() and restored.last_encounters.is_empty(), "invalid saved entries are ignored")
	gm.free()
	restored.free()

func _count(counts: Dictionary) -> int:
	var total := 0
	for value in counts.values():
		total += int(value)
	return total

func _save_file_checks() -> void:
	var sm = root.get_node("SaveManager")
	var path: String = ProjectSettings.globalize_path(sm.SAVE_PATH)
	var isolated: bool = path.get_base_dir().get_file().begins_with("STSL-tutorial-validation-")
	_check(isolated, "real SaveManager file checks use isolated user directory")
	if not isolated:
		return
	var gm: GM = root.get_node("GameManager")
	gm.reset()
	gm.act_mythologies.assign(["norse", "greek", "egyptian"])
	gm._pick_fresh_encounter([["a"], ["b"]], [1.0, 1.0], "normal:norse")
	var counts: Dictionary = gm.encounter_counts.duplicate(true)
	var species: Dictionary = gm.encounter_species_counts.duplicate(true)
	var last: Dictionary = gm.last_encounters.duplicate(true)
	sm.save()
	_check(FileAccess.file_exists(path), "SaveManager writes additive history format")
	gm.reset()
	_check(sm.load_save(), "SaveManager loads current save container")
	_check(gm.act_mythologies == ["norse", "greek", "egyptian"] and gm.encounter_counts == counts and gm.encounter_species_counts == species and gm.last_encounters == last, "actual save file restores mythology and encounter history")

func _path(nodes: Array, right: bool) -> Array:
	var starts: Array = nodes.filter(func(node: Resource) -> bool: return node.floor_num == 0)
	starts.sort_custom(func(a: Resource, b: Resource) -> bool: return a.column < b.column)
	var node: Resource = starts[-1] if right else starts[0]
	var result: Array = []
	while true:
		result.append(node)
		if node.connections.is_empty():
			break
		var children: Array = node.connections.map(func(id: int) -> Resource: return nodes[id])
		children.sort_custom(func(a: Resource, b: Resource) -> bool: return a.column < b.column)
		node = children[-1] if right else children[0]
	return result

func _sample_paths() -> Array:
	var gm := GM.new()
	var registry: Dictionary = gm._get_mythology_registry()
	var rows: Array = []
	for myth in Catalog.MYTH_ORDER:
		var encounters: Array = registry[myth].normals.encounters()
		for act in [1, 2, 3]:
			var elite_names: Array = registry[myth].acts[act - 1].elites()
			for seed_value in range(100):
				var nodes: Array = Maps.generate(act, seed_value)
				for right in [false, true]:
					var path := _path(nodes, right)
					var path_data: Array = path.map(func(node: Resource) -> Array: return [node.floor_num, node.column, int(node.room_type)])
					var row := {"myth": myth, "act": act, "seed": seed_value, "route": "right" if right else "left", "path": path_data, "path_hash": JSON.stringify([myth, act, path_data]).sha256_text(), "arms": {}}
					for arm in ["old", "weights_only", "new"]:
						seed(seed_value + act * 1000 + Catalog.MYTH_ORDER.find(myth) * 10000)
						gm.encounter_counts.clear()
						gm.encounter_species_counts.clear()
						gm.last_encounters.clear()
						row.arms[arm] = _sample_arm(gm, path, encounters, elite_names, myth, arm)
					rows.append(row)
		print("Encounter paths completed: " + myth)
	gm.free()
	return rows

func _sample_arm(gm: Node, path: Array, packs: Array, elite_names: Array, myth: String, arm: String) -> Dictionary:
	var result := {"normals": 0, "normal_repeats": 0, "normal_consecutive": 0, "species_repeats": 0, "species_visits": 0, "elites": 0, "elite_repeats": 0, "elite_consecutive": 0, "band_violations": 0, "normal_index_sum": 0, "sequence": []}
	var seen := {}
	var species := {}
	var previous := {"normal": "", "elite": ""}
	for node in path:
		var chosen: Array = []
		var kind := ""
		if node.room_type == Room.RoomType.BATTLE:
			kind = "normal"
			if arm == "new":
				chosen = gm._pick_weighted_encounter(packs, node.floor_num, "normal:" + myth)
			else:
				var weights: Array[float] = gm._normal_encounter_weights(packs.size(), node.floor_num)
				if arm == "old":
					weights.clear()
					var target: float = clampf(node.floor_num / 9.0, 0.0, 1.0) * (packs.size() - 1)
					for i in range(packs.size()):
						weights.append(maxf(0.0, 4.0 - absf(i - target)))
				chosen = gm._weighted_pick(packs, weights)
			var index: int = packs.find(chosen)
			result.normal_index_sum += index
			result.normals += 1
			if gm._normal_encounter_weights(packs.size(), node.floor_num)[index] <= 0.0:
				result.band_violations += 1
		elif node.room_type == Room.RoomType.ELITE:
			kind = "elite"
			if arm == "new":
				var elite_packs: Array = elite_names.map(func(name: String) -> Array: return [name])
				var weights: Array[float] = []
				weights.resize(elite_names.size())
				weights.fill(1.0)
				chosen = gm._pick_fresh_encounter(elite_packs, weights, "elite:" + myth)
			else:
				chosen = [elite_names.pick_random()]
			result.elites += 1
		else:
			continue
		var key: String = gm._encounter_key(kind + ":" + myth, chosen)
		var prefix := "normal" if kind == "normal" else "elite"
		if seen.has(key):
			result[prefix + "_repeats"] += 1
		if previous[kind] == key:
			result[prefix + "_consecutive"] += 1
		seen[key] = true
		previous[kind] = key
		var unique: Dictionary = {}
		for name in chosen:
			unique[str(name)] = true
		for name in unique:
			if kind == "normal":
				result.species_visits += 1
			if kind == "normal" and species.has(name):
				result.species_repeats += 1
			species[name] = true
		result.sequence.append({"floor": node.floor_num, "kind": kind, "pack": chosen.duplicate()})
	return result
