## Actual-scene campaign smoke bot.
##
## Run through tools/run_campaign_bot.sh so `user://` is a fresh, bot-only
## directory.  This deliberately drives the production GameManager and scenes:
## it never changes HP, enemy state, rewards, or win conditions.
extends SceneTree

const FRAME_PROBE := preload("res://tools/campaign_frame_probe.gd")
const MapGenerator := preload("res://autoload/map_generator.gd")
const MapNode := preload("res://resources/map_node_resource.gd")
const EventChoice := preload("res://resources/event_choice_resource.gd")
const Effect := preload("res://resources/effect_resource.gd")
const GPU_HELPERS := preload("res://scenes/vfx/gpu_particle_helpers.gd")
const CLASSIC_CARD := preload("res://scenes/card/card_scene.gd")
const MODERN_CARD := preload("res://scenes/card/card_scene_v2.gd")

const DEFAULT_MAX_SECONDS := 3600.0
const MAX_ACTIONS := 12000
const POLL_SECONDS := 0.05

var _chapter_arg := "both"
var _initial_hero := "cleopatra"
var _seed := 42
var _max_seconds := DEFAULT_MAX_SECONDS
var _report_path := ""
var _speed := 1.0
var _profile_frames := false
var _diagnose_battles := false
var _replay_encounter := ""
var _policy := "corrected"
var _started_usec := 0
var _last_activity_usec := 0
var _actions := 0
var _last_scene := ""
var _last_scene_instance_id := 0
var _battle_context_scene_id := 0
var _scene_acted := false
var _last_act_seeded := -1
var _battle_waiting := false
var _hero_input_ready := false
var _hero_turn_scene_id := 0
var _hero_turn_actor := ""
var _pending_bot_card: Resource
var _outcome := "running" # clear | defeat | stall | error
var _reason := ""
var _chapters: Array = []
var _chapter_index := 0
var _runs: Array[Dictionary] = []
var _route: Array[Dictionary] = []
var _action_counts: Dictionary = {}
var _action_log: Array[Dictionary] = []
var _probe: Node
# `--script` starts before a scene is instanced, so autoloads are accessed as
# root children rather than relying on editor-only singleton identifiers.
var GameManager: Node
var TeamManager: Node
var DeckManager: Node
var BattleManager: Node

func _init() -> void:
	_parse_args()
	_started_usec = Time.get_ticks_usec()
	_last_activity_usec = _started_usec
	Engine.time_scale = _speed
	call_deferred("_start")

func _parse_args() -> void:
	for raw in OS.get_cmdline_user_args():
		if raw == "--diagnose-battles":
			_diagnose_battles = true
		elif raw.begins_with("--replay-encounter="):
			_replay_encounter = raw.trim_prefix("--replay-encounter=")
		elif raw.begins_with("--policy="):
			_policy = raw.trim_prefix("--policy=")
		if raw == "--profile-frames":
			_profile_frames = true
		if raw.begins_with("--chapter="):
			_chapter_arg = raw.trim_prefix("--chapter=")
		elif raw.begins_with("--seed="):
			_seed = raw.trim_prefix("--seed=").to_int()
		elif raw.begins_with("--hero="):
			_initial_hero = raw.trim_prefix("--hero=")
		elif raw.begins_with("--max-seconds="):
			_max_seconds = maxf(1.0, raw.trim_prefix("--max-seconds=").to_float())
		elif raw.begins_with("--report="):
			_report_path = raw.trim_prefix("--report=")
		elif raw.begins_with("--speed="):
			_speed = clampf(raw.trim_prefix("--speed=").to_float(), 0.1, 8.0)
	if _chapter_arg == "1":
		_chapters = [1]
	elif _chapter_arg == "2":
		_chapters = [2]
	elif _chapter_arg == "both":
		_chapters = [1, 2]
	else:
		_chapters = []
	if _report_path == "":
		_report_path = "user://campaign_bot_report.json"

func _start() -> void:
	# This must be the first side-effecting guard: malformed arguments must never
	# create user:// reports beside a player's own save data.
	if not _isolated_user_directory():
		_finish("error", "Refusing to run outside STSL-campaign-bot-* custom user directory")
		return
	var audio := root.get_node_or_null("AudioManager")
	if audio != null:
		audio.set_bus_volume("master", 0.0)
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), true)
	if DisplayServer.get_name() != "headless":
		root.show()
		root.grab_focus()
	GameManager = root.get_node_or_null("GameManager")
	TeamManager = root.get_node_or_null("TeamManager")
	DeckManager = root.get_node_or_null("DeckManager")
	BattleManager = root.get_node_or_null("BattleManager")
	if GameManager == null or TeamManager == null or DeckManager == null or BattleManager == null:
		_finish("error", "Required gameplay autoload was unavailable")
		return
	if _chapters.is_empty():
		_finish("error", "--chapter must be 1, 2, or both")
		return
	if _policy not in ["baseline", "corrected", "status-aware"]:
		_finish("error", "--policy must be baseline, corrected or status-aware")
		return
	var progress := root.get_node("ProgressManager")
	if not progress.is_hero_unlocked(_initial_hero):
		_finish("error", "--hero must be an unlocked starting hero")
		return
	GameManager.run_ended.connect(_on_run_ended)
	BattleManager.turn_started.connect(_on_actor_turn_started)
	BattleManager.hero_turn_skipped.connect(_on_hero_turn_skipped)
	BattleManager.card_effects_resolved.connect(_on_card_resolved)
	BattleManager.battle_won.connect(_on_battle_won)
	if _diagnose_battles or _replay_encounter != "":
		_diagnose_battles = true
		BattleManager.hero_damaged.connect(func(hid: String, amount: int, kind: String, _crit: bool): _act("hero_damage", {"hero": hid, "amount": amount, "kind": kind, "state": _combat_snapshot()}))
		BattleManager.poison_tick_applied.connect(func(target: String, amount: int): _act("poison_tick", {"target": target, "amount": amount}))
	if _profile_frames:
		_probe = FRAME_PROBE.new()
		root.add_child(_probe)
		_probe.configure(_report_path + ".frames.jsonl")
	_mark("boot")
	# SceneTransition is a real production autoload; loading the menu first makes
	# this a rendered project run rather than a data-only test.
	change_scene_to_file("res://scenes/main_menu/main_menu_scene.tscn")
	await process_frame
	if _replay_encounter != "":
		if not _restore_encounter():
			return
	else:
		await _start_chapter()
	await _tick()

func _isolated_user_directory() -> bool:
	var user_dir := ProjectSettings.globalize_path("user://").get_base_dir().get_file()
	return user_dir.begins_with("STSL-campaign-bot-")

func _start_chapter() -> void:
	if _chapter_index >= _chapters.size():
		_finish("clear", "Requested chapters cleared")
		return
	var chapter: int = int(_chapters[_chapter_index])
	seed(_seed + chapter * 100000)
	GameManager.start_run(_initial_hero, chapter)
	_seed_current_act_map()
	_mark("chapter_%d_start" % chapter)
	await change_scene_to_file("res://scenes/map/map_scene.tscn")

func _seed_current_act_map() -> void:
	# GameManager normally randomizes MapGenerator internally.  Replacing only
	# the generated route before its first node is chosen preserves real rooms,
	# enemies and transitions while making the bot's route repeatable.
	var map_seed: int = _seed + GameManager.current_chapter * 1000 + GameManager.current_act
	GameManager.run_map = MapGenerator.generate(GameManager.current_act, map_seed)
	GameManager.available_node_ids.clear()
	for node in GameManager.run_map:
		if node.floor_num == 0:
			GameManager.available_node_ids.append(node.node_id)
	_last_act_seeded = GameManager.current_act
	_mark("map_seed_%d" % map_seed)

func _tick() -> void:
	while _outcome == "running":
		if Time.get_ticks_usec() - _last_activity_usec > 120000000:
			_finish("stall", "No gameplay action for 120 wall-clock seconds")
			break
		if _elapsed_seconds() > _max_seconds:
			_finish("stall", "Wall-clock limit %.1fs reached" % _max_seconds)
			break
		if _actions >= MAX_ACTIONS:
			_finish("stall", "Action limit %d reached" % MAX_ACTIONS)
			break
		await create_timer(POLL_SECONDS, true, false, true).timeout
		if _outcome != "running":
			break
		var scene := current_scene
		var scene_path := scene.scene_file_path if scene else ""
		var scene_id: int = scene.get_instance_id() if scene else 0
		if scene_id != _last_scene_instance_id:
			_last_scene_instance_id = scene_id
			_scene_acted = false
		if scene_path != _last_scene:
			_last_scene = scene_path
			_mark("scene:" + scene_path.get_file())
		_drive_current_scene(scene, scene_path)

func _drive_current_scene(scene: Node, path: String) -> void:
	if GameManager.current_act != _last_act_seeded and GameManager.current_floor == 0 and GameManager.current_node_id == -1:
		_seed_current_act_map()
	if path.ends_with("battle_scene.tscn"):
		_record_battle_context()
		_drive_battle(scene)
		return
	# A GameManager completion starts SceneTransition asynchronously.  Do not
	# activate controls from a newly-instanced scene until the prior fade is
	# fully released, otherwise a second transition can cancel the first one.
	if not _transition_ready():
		return
	if path.ends_with("event_scene.tscn") and _event_overlay_open(scene):
		_choose_event(scene)
		return
	if _scene_acted:
		return
	# All non-battle scene handlers cause a transition.  One action per concrete
	# scene instance avoids double rewards while SceneTransition fades it out.
	_scene_acted = true
	if path.ends_with("map_scene.tscn"):
		_choose_map_node()
	elif path.ends_with("card_pick_scene.tscn"):
		_choose_reward()
	elif path.ends_with("rest_scene.tscn"):
		_choose_rest(scene)
	elif path.ends_with("shop_scene.tscn"):
		_leave_shop(scene)
	elif path.ends_with("event_scene.tscn"):
		_choose_event(scene)
	elif path.ends_with("hero_select_scene.tscn"):
		_choose_recruit(scene)
	elif path.ends_with("card_upgrade_scene.tscn"):
		_choose_upgrade(scene)
	elif path.ends_with("chapter_clear_scene.tscn"):
		_record_chapter_clear()
	elif path.ends_with("game_over_scene.tscn"):
		_finish("defeat", "Game over scene reached")

func _transition_ready() -> bool:
	var transition := root.get_node_or_null("SceneTransition")
	if transition == null:
		return true
	var overlay: Control = transition.get("_overlay")
	return overlay != null and overlay.mouse_filter == Control.MOUSE_FILTER_IGNORE and overlay.modulate.a <= 0.01

func _choose_map_node() -> void:
	var candidates: Array = GameManager.available_node_ids.duplicate()
	if candidates.is_empty():
		_finish("stall", "Map had no available nodes")
		return
	var chosen: int = int(candidates[0])
	var best_score := -INF
	var memo: Dictionary = {}
	for id in candidates:
		var score := _route_score(int(id), memo)
		if score > best_score:
			best_score = score
			chosen = int(id)
	var node: Resource = GameManager.run_map[chosen]
	_route.append({"chapter": GameManager.current_chapter, "act": GameManager.current_act,
		"floor": node.floor_num, "node_id": chosen, "room_type": node.room_type})
	_act("enter_node")
	if _diagnose_battles and node.room_type in [MapNode.RoomType.BATTLE, MapNode.RoomType.ELITE, MapNode.RoomType.BOSS]:
		_capture_encounter(chosen)
		if _outcome != "running":
			return
	GameManager.enter_node(chosen)

func _capture_encounter(chosen: int) -> void:
	# Test-only pre-entry checkpoint. The normal save format deliberately omits
	# transient battle state, so capture BEFORE entering, never midway through it.
	var entry_seed: int = _seed + GameManager.current_chapter * 100000 + GameManager.current_act * 1000 + chosen
	var sm := root.get_node("SaveManager")
	var data := {"kind": "stsl_encounter_checkpoint_v1", "combat_units": BattleManager.combat_unit_divisor,
		"entry_seed": entry_seed, "node_id": chosen, "game_manager": GameManager.to_dict(),
		"act_mythologies": GameManager.act_mythologies.duplicate(),
		"team_manager": TeamManager.to_dict(), "deck_manager": DeckManager.to_dict(),
		"relics": sm._serialize_relics(GameManager), "source_hash": OS.get_environment("STSL_BOT_SOURCE_HASH"), "gameplay_hash": OS.get_environment("STSL_BOT_GAMEPLAY_HASH")}
	var path := _report_path.get_base_dir().path_join("encounter-c%d-a%d-n%d.json" % [GameManager.current_chapter, GameManager.current_act, chosen])
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_finish("error", "Could not write encounter checkpoint")
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	_act("encounter_checkpoint", {"path": path, "team": data.team_manager, "relics": data.relics})
	seed(entry_seed)

func _restore_encounter() -> bool:
	var data = JSON.parse_string(FileAccess.get_file_as_string(_replay_encounter))
	if not (data is Dictionary) or data.get("kind", "") != "stsl_encounter_checkpoint_v1" or int(data.get("combat_units", 0)) != BattleManager.combat_unit_divisor:
		_finish("error", "Invalid or incompatible encounter checkpoint")
		return false
	if data.get("gameplay_hash", "") != "" and data.gameplay_hash != OS.get_environment("STSL_BOT_GAMEPLAY_HASH"):
		_finish("error", "Checkpoint gameplay rules changed; recapture before paired testing")
		return false
	GameManager.start_run(_initial_hero, int(data.game_manager.current_chapter))
	GameManager.from_dict(data.game_manager)
	var mythologies: Array = data.get("act_mythologies", [])
	if mythologies.is_empty():
		# Early diagnostic checkpoints lacked this non-save field. Recover only
		# the current encounter's observed mythology from its original report;
		# never silently reroll a different encounter and call it a paired test.
		var original = JSON.parse_string(FileAccess.get_file_as_string(_replay_encounter.get_base_dir().path_join("report.json")))
		var floor_num: int = int(data.game_manager.run_map[int(data.node_id)].floor_num)
		if original is Dictionary:
			for action in original.get("action_log", []):
				if action.label == "battle_context" and int(action.chapter) == GameManager.current_chapter and int(action.act) == GameManager.current_act and int(action.floor) == floor_num:
					var names: Array = action.detail.enemies
					if not names.is_empty():
						var myth: String = String(names[0]).split(".")[1]
						mythologies = [myth, myth, myth]
						_act("checkpoint_context_recovered", {"current_mythology": myth, "from_original_report": true})
	if mythologies.size() != 3:
		_finish("error", "Checkpoint lacks proven mythology context")
		return false
	GameManager.act_mythologies.assign(mythologies)
	# JSON numbers are floats; Array.has compares their Variant types. Keep
	# replay's legal-node IDs integral before enter_node's membership guard.
	GameManager.available_node_ids = _integer_ids(GameManager.available_node_ids)
	TeamManager.from_dict(data.team_manager)
	DeckManager.from_dict(data.deck_manager)
	root.get_node("SaveManager")._deserialize_relics(GameManager, data.relics)
	var node_id: int = int(data.node_id)
	if node_id not in GameManager.available_node_ids:
		_finish("error", "Checkpoint node is not available")
		return false
	_last_act_seeded = GameManager.current_act
	seed(int(data.entry_seed))
	_act("encounter_replay", {"checkpoint": _replay_encounter, "checkpoint_source_hash": data.source_hash, "team": data.team_manager})
	GameManager.enter_node(node_id)
	return true

static func _integer_ids(values: Array) -> Array:
	return values.map(func(value): return int(value))

func _combat_snapshot() -> Dictionary:
	var heroes: Array = []
	for hero in TeamManager.heroes:
		heroes.append({"id": hero.hero_id, "hp": TeamManager.get_current_hp(hero.hero_id), "block": BattleManager.get_hero_block(hero.hero_id), "status": BattleManager._hero_status.get(hero.hero_id, {}).duplicate(true)})
	return {"heroes": heroes, "enemy_hp": BattleManager._enemy_hp.duplicate(), "enemy_status": BattleManager._enemy_status.duplicate(true), "actor": BattleManager._current_actor_id}

func _on_battle_won() -> void:
	if _diagnose_battles:
		_act("battle_result", {"won": true, "state": _combat_snapshot()})
	if _replay_encounter != "":
		_runs.append(_run_summary("clear", "Checkpoint encounter won (not a chapter clear)"))
		_finish.call_deferred("clear", "Checkpoint encounter won (not a chapter clear)")

func _route_score(id: int, memo: Dictionary) -> float:
	if memo.has(id):
		return memo[id]
	var node: Resource = GameManager.run_map[id]
	# Plan over legal connections, not just the next room. One early elite buys
	# the normal recruit opportunity; thereafter favour recovery over attrition.
	var value := 0.0
	match node.room_type:
		MapNode.RoomType.ELITE:
			value = 45.0 if not GameManager.first_elite_recruit_done else -35.0
		MapNode.RoomType.REST:
			value = 25.0
		MapNode.RoomType.EVENT:
			value = 12.0
		MapNode.RoomType.SHOP, MapNode.RoomType.SECRET:
			value = 5.0
		MapNode.RoomType.BATTLE:
			value = -8.0
	var future := -INF
	for next_id in node.connections:
		future = maxf(future, _route_score(int(next_id), memo))
	if future != -INF:
		value += future * 0.85
	memo[id] = value
	return value

func _drive_battle(scene: Node) -> void:
	if not BattleManager.is_battle_active:
		return
	if not BattleManager._pending_discard_pick.is_empty():
		_resolve_discard(scene)
		return
	if _battle_waiting:
		return
	if not BattleManager.is_player_turn or not _input_matches_turn(scene.get_instance_id(), _hero_turn_scene_id, BattleManager._current_actor_id, _hero_turn_actor, _hero_input_ready):
		return
	var hero_id: String = BattleManager.get_current_hero_id()
	var hand: Array = DeckManager.get_hand(hero_id)
	var selected: Resource = _best_playable_card(hero_id, hand)
	if _diagnose_battles:
		var options: Array = []
		for card in hand:
			options.append({"card": card.card_name, "cost": DeckManager.get_effective_cost(hero_id, card), "playable": DeckManager.can_play_hero(hero_id, card), "score": _card_score(card, hero_id)})
		_act("card_decision", {"hero": hero_id, "energy": DeckManager.get_energy(hero_id), "chosen": selected.card_name if selected else "", "options": options, "state": _combat_snapshot()})
	if selected != null:
		_battle_waiting = true
		_pending_bot_card = selected
		var enemy_target := _target_for_card(selected)
		var ok: bool = BattleManager.play_card(selected, enemy_target, _lowest_hero())
		if not ok:
			_battle_waiting = false
			_pending_bot_card = null
			_act("card_rejected", {"card": selected.card_name, "owner": hero_id})
		else:
			_act("play_card", {"card": selected.card_name, "owner": hero_id, "enemy_target": enemy_target, "hero_target": _lowest_hero()})
		return
	_act("end_turn", {"owner": hero_id})
	_hero_input_ready = false
	BattleManager.end_player_turn()

func _on_actor_turn_started(actor_id: String) -> void:
	_hero_input_ready = actor_id.begins_with("hero:")
	_hero_turn_actor = actor_id
	_hero_turn_scene_id = current_scene.get_instance_id() if current_scene != null else 0
	if _diagnose_battles:
		_act("actor_turn", {"state": _combat_snapshot()})

static func _input_matches_turn(scene_id: int, turn_scene_id: int, actor: String, announced_actor: String, ready: bool) -> bool:
	return ready and scene_id == turn_scene_id and actor.begins_with("hero:") and actor == announced_actor

func _on_hero_turn_skipped(hero_id: String) -> void:
	# The manager shows a stun toast before its automatic end-turn. Do not use
	# that animation interval to play cards after the stun stack was decremented.
	_hero_input_ready = false
	_act("stunned_turn_skipped", {"owner": hero_id})

func _on_card_resolved(card: Resource) -> void:
	if card == _pending_bot_card:
		_battle_waiting = false
		_pending_bot_card = null

func _best_playable_card(hero_id: String, hand: Array) -> Resource:
	if BattleManager._hero_status.get(hero_id, {}).get("silence", 0) > 0:
		return null
	var playable: Array = []
	var scores: Array = []
	var costs: Array = []
	var fallback: Resource = null
	for card in hand:
		if not DeckManager.can_play_hero(hero_id, card):
			continue
		var score := _card_score(card, hero_id)
		if score >= 0.0 and fallback == null and not _is_unavailable_counter(card) and not _is_redundant_power(card):
			fallback = card
		playable.append(card)
		scores.append(score)
		costs.append(DeckManager.get_effective_cost(hero_id, card))
	var index := _budget_pick(scores, costs, DeckManager.get_energy(hero_id))
	return playable[index] if index >= 0 else fallback

static func _budget_pick(scores: Array, costs: Array, energy: int) -> int:
	# Free draws/energy should precede paid cards. Then solve the small energy
	# budget rather than selecting one expensive card solely by its raw score.
	var free := -1
	for i in scores.size():
		if costs[i] == 0 and scores[i] > 0.0 and (free < 0 or scores[i] > scores[free]):
			free = i
	if free >= 0:
		return free
	var plans: Array = []
	for _budget in energy + 1:
		plans.append({"value": 0.0, "cards": []})
	for i in scores.size():
		var cost: int = int(costs[i])
		if cost <= 0 or cost > energy or scores[i] <= 0.0:
			continue
		for budget in range(energy, cost - 1, -1):
			var value: float = float(plans[budget - cost].value) + float(scores[i])
			if value > plans[budget].value:
				var cards: Array = plans[budget - cost].cards.duplicate()
				cards.append(i)
				plans[budget] = {"value": value, "cards": cards}
	var selected := -1
	for index in plans[energy].cards:
		if selected < 0 or scores[index] > scores[selected]:
			selected = int(index)
	return selected

func _is_redundant_power(card: Resource) -> bool:
	if int(card.card_type) != 2:
		return false
	var powers: Dictionary = BattleManager.get_all_active_powers()
	for effect in card.effects:
		if not effect.status_type.begins_with("power."):
			return false
		var active: Dictionary = powers.get(effect.status_type + ":" + card.owner_id, {})
		if effect.status_type == "power.strength_player":
			if active.get("params", {}).get("sources", {}).get(card.card_name, 0) < effect.value:
				return false
		elif active.get("value", 0) < effect.value:
			return false
	return true

func _is_unavailable_counter(card: Resource) -> bool:
	for effect in card.effects:
		if effect.effect_type == Effect.EffectType.COUNTER_REFLECT:
			for index in BattleManager._enemy_hp.size():
				if BattleManager.is_counter_window_active(index):
					return false
			return _policy_hp_value(_incoming_damage()) < 120.0
	return false

func _incoming_damage() -> float:
	var damage := 0.0
	for enemy in BattleManager._enemy_hp.size():
		if BattleManager.is_enemy_alive(enemy):
			for intent in BattleManager.get_enemy_current_intents(enemy):
				if int(intent.action_type) == 0:
					damage += BattleManager.get_intent_display_damage(enemy, intent) if _policy == "status-aware" else intent.value
	return damage

static func _cleanse_value(status: Dictionary, unit_divisor: int) -> float:
	# Actual runtime keys, and the remaining HP loss (poison bypasses block).
	return float(status.get("poison_dmg", 0)) * float(status.get("poison_dur", 0)) * unit_divisor * 3.0 + float(status.get("weak", 0) + status.get("vulnerable", 0)) * 50.0

static func _guard_demand(incoming: float, block: int, max_hp: int) -> float:
	# Block persists across turns; keep a small reserve even on debuff turns.
	# Do not count poison as blockable damage.
	return maxf(0.0, incoming + ceil(max_hp * 0.1) - block)

# Strategy scores use the original policy's comparison scale. This changes
# no game state: damage/HP inputs alone are normalized so draw/energy weights
# don't become ten times more attractive after the combat-unit migration.
func _policy_hp_value(value: float) -> float:
	return value * float(BattleManager.combat_unit_divisor)

func _karma_reserve() -> float:
	# Buddhist death retaliation is 25% of cumulative damage, to EVERY hero.
	# A large boss can return more than an entire HP bar. Bank persistent block
	# before racing its HP; counter_pending does not mitigate this damage path.
	var retaliation := 0.0
	for index in BattleManager._enemies.size():
		var enemy: Resource = BattleManager._enemies[index]
		if BattleManager.is_enemy_alive(index) and enemy.mythology == "buddhist" and enemy.signatures_enabled:
			retaliation += maxf(enemy.max_hp, BattleManager._enemy_status[index].get("damage_taken", 0)) * 0.25
	return retaliation * 1.5 + 300.0 / float(BattleManager.combat_unit_divisor) if retaliation > 0.0 else 0.0

func _best_guard_health() -> float:
	var best := 0.0
	for hero in TeamManager.heroes:
		if TeamManager.is_alive(hero.hero_id):
			best = maxf(best, TeamManager.get_current_hp(hero.hero_id) + BattleManager.get_hero_block(hero.hero_id))
	return best

static func _karma_damage_risk(effect: Resource) -> bool:
	return effect.damage_type != "" or effect.effect_type in [Effect.EffectType.COUNTER_REFLECT, Effect.EffectType.SUMMON_TOKEN] or effect.status_type == "poison"

func _card_score(card: Resource, hero_id: String) -> float:
	var hero: Resource = TeamManager.get_hero(hero_id)
	var hp_ratio := float(TeamManager.get_current_hp(hero_id)) / maxf(1.0, float(hero.max_hp))
	var score := 0.0
	if _is_redundant_power(card):
		return -1000.0
	var target := _target_for_card(card)
	var incoming := _incoming_damage()
	var unblocked := maxf(0.0, incoming - BattleManager.get_hero_block(hero_id))
	if _policy == "status-aware":
		unblocked = _guard_demand(incoming, BattleManager.get_hero_block(hero_id), hero.max_hp)
	var karma_reserve := _karma_reserve()
	var preparing_karma := karma_reserve > _best_guard_health()
	# Do not seed delayed poison/token/counter kills while still banking a
	# survival reserve. Multi-hit and critical damage can also outrun a nominal
	# lethal estimate. This is a strategy gate, not a change to combat rules.
	if preparing_karma and target >= 0 and BattleManager._enemies[target].mythology == "buddhist":
		for effect in card.effects:
			if _karma_damage_risk(effect):
				return -1000.0
	var projected_damage := 0
	for effect in card.effects:
		match effect.rule_id:
			"poison_burst_multiplier":
				var burst: int = BattleManager._card_effect_base_damage(effect, hero_id, target, true)
				projected_damage += burst
				score += _policy_hp_value(burst) * 1.8
			"next_cards_cost_reduction", "next_attack_cost_reduction":
				score += float(effect.rule_params.get("amount", 0)) * 120.0
			"formation_block":
				score += _policy_hp_value(float(effect.rule_params.get("base", 0))) * (5.0 if preparing_karma else 1.5)
		match effect.effect_type:
			Effect.EffectType.DAMAGE, Effect.EffectType.CONSUME_MORALE, Effect.EffectType.CONDITIONAL_DMG, Effect.EffectType.DAMAGE_PER_BLOCK, Effect.EffectType.DAMAGE_PER_HAND_SIZE, Effect.EffectType.DAMAGE_PER_TOKEN, Effect.EffectType.ENERGY_TO_DAMAGE, Effect.EffectType.CHARM_TO_DAMAGE, Effect.EffectType.DAMAGE_PER_STATUS_TYPE, Effect.EffectType.DAMAGE_PER_TEAM_MORALE, Effect.EffectType.DAMAGE_PER_TEAM_TOKEN, Effect.EffectType.PER_DRAW_DMG:
				var damage: int = BattleManager.estimate_effect_damage(effect, hero_id, target)
				projected_damage += damage
				if target >= 0:
					if BattleManager._enemies[target].mythology == "buddhist" and damage >= BattleManager._enemy_hp[target] and preparing_karma:
						return -1000.0
					damage = mini(damage, BattleManager._enemy_hp[target])
				score += _policy_hp_value(damage) * 1.8
			Effect.EffectType.BLOCK, Effect.EffectType.BLOCK_ALL, Effect.EffectType.FORMATION_BLOCK, Effect.EffectType.MORALE_TO_BLOCK:
				score += _policy_hp_value(effect.value) * 5.0 if preparing_karma else _policy_hp_value(minf(effect.value, unblocked)) * (2.5 if hp_ratio < 0.65 else 1.5)
			Effect.EffectType.HEAL, Effect.EffectType.HEAL_ALL:
				for ally in TeamManager.heroes:
					if not TeamManager.is_alive(ally.hero_id):
						continue
					if effect.effect_type != Effect.EffectType.HEAL_ALL and effect.target == "SELF" and ally.hero_id != hero_id:
						continue
					if effect.effect_type != Effect.EffectType.HEAL_ALL and effect.target != "SELF" and ally.hero_id != _lowest_hero():
						continue
					var hp: int = TeamManager.get_current_hp(ally.hero_id)
					var ratio := float(hp) / maxf(1.0, ally.max_hp)
					score += _policy_hp_value(mini(effect.value, ally.max_hp - hp)) * (6.0 if ratio < 0.35 else (3.0 if ratio < 0.7 else 0.5))
			Effect.EffectType.DRAW:
				score += 45.0
			Effect.EffectType.ENERGY:
				score += effect.value * 200.0
			Effect.EffectType.COST_NEXT:
				score += effect.value * 120.0
			Effect.EffectType.COST_ZERO_TURN:
				score += DeckManager.get_hand(hero_id).size() * 150.0
			Effect.EffectType.GAIN_MORALE, Effect.EffectType.SUMMON_TOKEN:
				score += 32.0
			Effect.EffectType.CHARM:
				score += _policy_hp_value(effect.value) * 2.5
			Effect.EffectType.PURGE_STATUS:
				if _policy != "baseline":
					for ally in TeamManager.heroes:
						if TeamManager.is_alive(ally.hero_id) and (effect.target == "ALL" or ally.hero_id == hero_id):
							score += _cleanse_value(BattleManager._hero_status.get(ally.hero_id, {}), BattleManager.combat_unit_divisor)
				else:
					for status in ["poison", "weak", "vulnerable"]:
						score += float(BattleManager._hero_status.get(hero_id, {}).get(status, 0)) * 4.0
			Effect.EffectType.APPLY_STATUS:
				if effect.status_type.begins_with("power."):
					score += 1000.0 if preparing_karma and "block" in effect.status_type else 150.0
				elif effect.status_type == "poison":
					score += _policy_hp_value(effect.value) * 4.0
				elif effect.status_type in ["weak", "vulnerable"]:
					score += effect.value * 50.0
			Effect.EffectType.COUNTER_REFLECT:
				score += 700.0 if target >= 0 and BattleManager.is_counter_window_active(target) else _policy_hp_value(incoming) * 1.5
			_:
				pass
	if int(card.card_type) == 0 and target >= 0 and BattleManager._enemy_hp[target] <= 0:
		score -= 1000.0
	if target >= 0 and BattleManager._enemies[target].mythology == "buddhist" and preparing_karma and projected_damage >= BattleManager._enemy_hp[target]:
		return -1000.0
	return score

func _target_for_card(card: Resource) -> int:
	for effect in card.effects:
		if effect.effect_type == Effect.EffectType.COUNTER_REFLECT:
			for index in BattleManager._enemy_hp.size():
				if BattleManager.is_counter_window_active(index):
					return index
	return _lowest_enemy()

func _lowest_enemy() -> int:
	var best := -1
	var hp := 2147483647
	for index in BattleManager._enemy_hp.size():
		if BattleManager.is_enemy_alive(index) and BattleManager._enemy_hp[index] < hp:
			best = index
			hp = BattleManager._enemy_hp[index]
	return best

func _lowest_hero() -> String:
	var best := ""
	var hp := 2147483647
	for hero in TeamManager.heroes:
		if TeamManager.is_alive(hero.hero_id) and TeamManager.get_current_hp(hero.hero_id) < hp:
			best = hero.hero_id
			hp = TeamManager.get_current_hp(hero.hero_id)
	return best

func _resolve_discard(scene: Node) -> void:
	var owner: String = BattleManager.get_pending_discard_owner()
	var hand: Array = DeckManager.get_hand(owner)
	if BattleManager.is_discard_pick_optional():
		if scene.has_method("_on_optional_pick_skipped"):
			scene.call("_on_optional_pick_skipped")
		else:
			BattleManager.resolve_pending_discard_pick(null)
		_act("discard_optional_skip")
		return
	if hand.is_empty():
		_finish("stall", "Mandatory discard requested with an empty hand")
		return
	if scene.has_method("_on_card_clicked") and scene.has_method("_on_pick_confirmed"):
		scene.call("_on_card_clicked", hand[0])
		scene.call("_on_pick_confirmed")
	else:
		BattleManager.resolve_pending_discard_pick(hand[0])
	_act("discard_pick")

func _choose_reward() -> void:
	if GameManager.card_rewards.is_empty():
		GameManager.complete_card_pick()
		return
	# Choose real generated cards through the deck manager, then use the same
	# progression completion path the card-pick scene uses after its last pick.
	var count := mini(GameManager.card_rewards_pick_count, GameManager.card_rewards.size())
	var choices: Array = GameManager.card_rewards.duplicate()
	choices.sort_custom(func(a: Resource, b: Resource) -> bool: return _reward_score(a) > _reward_score(b))
	for idx in count:
		if _reward_score(choices[idx]) <= 0.0:
			continue
		DeckManager.add_card_to_deck(choices[idx])
		_act("reward_card", {"card": choices[idx].card_name, "owner": choices[idx].owner_id})
	GameManager.complete_card_pick()
	_act("take_reward")

func _reward_score(card: Resource) -> float:
	if _policy != "baseline" and not TeamManager.is_alive(card.owner_id):
		return -1.0
	var score := 0.0
	for effect in card.effects:
		match effect.effect_type:
			Effect.EffectType.DAMAGE, Effect.EffectType.CONDITIONAL_DMG:
				score += _policy_hp_value(effect.value) * maxi(1, effect.hit_count)
			Effect.EffectType.BLOCK, Effect.EffectType.BLOCK_ALL:
				score += _policy_hp_value(effect.value) * 0.5
			Effect.EffectType.HEAL, Effect.EffectType.HEAL_ALL:
				score += _policy_hp_value(effect.value)
			Effect.EffectType.APPLY_STATUS:
				if effect.status_type.begins_with("power."):
					score += 160.0
					for owned in DeckManager.get_full_deck():
						if owned.owner_id == card.owner_id and owned.card_name == card.card_name:
							score -= 300.0
							break
			Effect.EffectType.DRAW:
				score += 40.0 * effect.value
			Effect.EffectType.CHARM:
				score += _policy_hp_value(effect.value) * 2.0
			Effect.EffectType.PURGE_STATUS:
				score += 100.0
	return score / maxf(1.0, float(card.cost))

func _choose_rest(scene: Node) -> void:
	# Healing is the safer non-destructive policy.  It still goes through the
	# exact scene handler and progression method used by a player click.
	if scene.has_method("_on_heal_pressed"):
		scene.call("_on_heal_pressed")
	else:
		GameManager.complete_rest()
	_act("rest_heal")

func _leave_shop(scene: Node) -> void:
	var inventory: Dictionary = scene.get("_inventory")
	var price: int = int(inventory.get("heal_price", 30))
	var amount: int = int(inventory.get("heal_amount", 20))
	if price > 0 and amount > 0:
		var missing := 0
		for hero in TeamManager.heroes:
			if TeamManager.is_alive(hero.hero_id):
				missing = maxi(missing, hero.max_hp - TeamManager.get_current_hp(hero.hero_id))
		var purchases := mini(int(ceil(float(missing) / amount)), int(GameManager.gold / price))
		for _purchase in purchases:
			scene.call("_on_heal", amount, price)
			_act("shop_heal", {"amount": amount, "price": price})
	if scene.has_method("_on_exit"):
		scene.call("_on_exit")
	else:
		GameManager.complete_shop()
	_act("shop_leave")

func _choose_event(scene: Node) -> void:
	# A card-removal overlay is deliberately a separate scene-layer interaction.
	# Select its first card and fire its production confirmation signal exactly once.
	for child in scene.get_children():
		if child.has_method("_on_confirm") and child.has_signal("confirmed") and child.get("_selected_card") == null:
			var deck: Array = DeckManager.get_full_deck()
			if deck.is_empty():
				_finish("stall", "Event card-removal overlay had an empty deck")
				return
			child.set("_selected_card", deck[0])
			child.call("_on_confirm")
			_act("event_remove_card", {"card": deck[0].card_name})
			return
	var event: Resource = GameManager.pending_event
	if event == null or event.choices.is_empty():
		GameManager.complete_event()
		return
	# First affordable non-battle option where possible; events with only combat
	# still exercise the normal event-battle branch.
	var choice: Resource = event.choices[0]
	var best_value := -INF
	for candidate in event.choices:
		var available: bool = scene.call("_is_choice_available", candidate) if scene.has_method("_is_choice_available") else candidate.cost_gold <= GameManager.gold
		var is_battle: bool = candidate.effect_type == EventChoice.EffectType.TRIGGER_BATTLE
		if available:
			var value: float = -_policy_hp_value(candidate.cost_hp) * 2.0 - float(candidate.cost_gold) * 0.25
			if is_battle:
				value -= 500.0
			elif candidate.effect_type == EventChoice.EffectType.HEAL:
				value += _policy_hp_value(candidate.value) * 2.0
			elif candidate.effect_type in [EventChoice.EffectType.ADD_HERO, EventChoice.EffectType.ADD_RELIC, EventChoice.EffectType.DRAW_UP]:
				value += 100.0
			elif candidate.effect_type == EventChoice.EffectType.GOLD:
				value += candidate.value * 0.25
			if value > best_value:
				best_value = value
				choice = candidate
	if scene.has_method("_on_choice_selected"):
		scene.call("_on_choice_selected", choice)
	else:
		GameManager.complete_event()
	_act("event_choice")

func _choose_recruit(scene: Node) -> void:
	var pool: Array = GameManager._recruit_hero_pool()
	for hero in pool:
		var hero_id: String = hero.hero_id
		if scene.has_method("_on_hero_selected"):
			scene.call("_on_hero_selected", hero_id)
		else:
			GameManager.complete_hero_recruit(hero_id)
		_act("recruit", {"hero": hero_id})
		return
	_finish("stall", "Recruit scene had no eligible hero")

func _choose_upgrade(scene: Node) -> void:
	var cards: Array = DeckManager.get_full_deck()
	for card in cards:
		if card.can_upgrade():
			if scene.has_method("_on_card_selected"):
				scene.call("_on_card_selected", card)
			else:
				GameManager.upgrade_card(card)
				GameManager.complete_card_upgrade()
			_act("upgrade_card")
			return
	GameManager.complete_card_upgrade()
	_act("upgrade_skip")

func _record_chapter_clear() -> void:
	if not GameManager.run_won or GameManager.current_act != GameManager.MAX_ACTS:
		_finish("stall", "Chapter-clear scene did not have a completed campaign state")
		return
	_runs.append(_run_summary("clear", "Chapter clear scene reached"))
	_chapter_index += 1
	_mark("chapter_clear")
	_start_chapter()

func _act(label: String, detail: Dictionary = {}) -> void:
	_last_activity_usec = Time.get_ticks_usec()
	if label not in ["actor_turn", "hero_damage", "poison_tick", "battle_entry", "battle_result", "card_decision", "encounter_checkpoint", "encounter_replay"]:
		_actions += 1
	_action_counts[label] = int(_action_counts.get(label, 0)) + 1
	if _action_log.size() < MAX_ACTIONS:
		_action_log.append({"index": _actions, "label": label, "chapter": GameManager.current_chapter,
			"act": GameManager.current_act, "floor": GameManager.current_floor,
			"at_usec": Time.get_ticks_usec(), "detail": detail})
	var context := detail.duplicate(true)
	context["action_index"] = _actions
	_mark(label, context)

func _record_battle_context() -> void:
	# Exactly one context row per battle scene: enough to replay the map route and
	# identify which encounter/card action preceded a performance sample.
	if current_scene == null or current_scene.get_instance_id() == _battle_context_scene_id:
		return
	_battle_context_scene_id = current_scene.get_instance_id()
	_battle_waiting = false
	_pending_bot_card = null
	var enemies: Array[String] = []
	for enemy in GameManager.pending_enemies:
		enemies.append(String(enemy.enemy_name))
	_act("battle_context", {"enemies": enemies})
	if _diagnose_battles:
		_act("battle_entry", {"state": _combat_snapshot(), "deck": DeckManager.to_dict(), "relics": root.get_node("SaveManager")._serialize_relics(GameManager)})

func _event_overlay_open(scene: Node) -> bool:
	for child in scene.get_children():
		if child.has_method("_on_confirm") and child.has_signal("confirmed"):
			return true
	return false

func _mark(label: String, context: Dictionary = {}) -> void:
	if _probe != null:
		_probe.mark_action(label, context)

func _elapsed_seconds() -> float:
	return (Time.get_ticks_usec() - _started_usec) / 1000000.0

func _run_summary(status: String, detail: String) -> Dictionary:
	if GameManager == null or TeamManager == null or DeckManager == null:
		return {"status": status, "detail": detail}
	var hero_state: Array[Dictionary] = []
	for hero in TeamManager.heroes:
		hero_state.append({"id": hero.hero_id, "hp": TeamManager.get_current_hp(hero.hero_id), "max_hp": hero.max_hp,
			"statuses": BattleManager._hero_status.get(hero.hero_id, {}).duplicate(true)})
	return {"chapter": GameManager.current_chapter, "status": status, "detail": detail,
		"act": GameManager.current_act, "floor": GameManager.current_floor,
		"battles_completed": GameManager.battles_completed, "gold": GameManager.gold,
		"heroes": TeamManager.heroes.size(), "deck_size": DeckManager.get_full_deck().size(),
		"hero_state": hero_state, "enemy_hp": BattleManager._enemy_hp.duplicate()}

func _finish(status: String, detail: String) -> void:
	if _outcome != "running":
		return
	_outcome = status
	_reason = detail
	if status != "clear" and GameManager != null:
		_runs.append(_run_summary(status, detail))
	var report := {
		"kind": "stsl_campaign_autoplay_v1", "outcome": _outcome, "reason": _reason,
		"environment": {"godot": Engine.get_version_info().get("string", ""), "os": OS.get_name(),
			"display_server": DisplayServer.get_name(), "max_fps": Engine.max_fps,
			"window_size": [root.size.x, root.size.y], "window_visible": root.visible,
			"window_focused": root.has_focus(), "viewport_size": [root.get_visible_rect().size.x, root.get_visible_rect().size.y],
			"master_muted": AudioServer.is_bus_mute(AudioServer.get_bus_index("Master"))},
		"config": {"chapter": _chapter_arg, "hero": _initial_hero, "seed": _seed, "max_seconds": _max_seconds,
			"policy": _policy, "diagnose_battles": _diagnose_battles, "replay_encounter": _replay_encounter,
			"combat_unit_divisor": BattleManager.combat_unit_divisor if BattleManager != null else 0, "profile_frames": _profile_frames,
			"speed": _speed, "actual_scene_run": true, "rendered_scene_run": DisplayServer.get_name() != "headless",
			"headless": DisplayServer.get_name() == "headless"},
		"elapsed_seconds": _elapsed_seconds(), "actions": _actions, "action_counts": _action_counts,
		"final_state": {"scene": _last_scene, "battle_active": BattleManager.is_battle_active,
			"player_turn": BattleManager.is_player_turn, "actor": BattleManager._current_actor_id,
			"input_ready": _hero_input_ready, "waiting_card": _battle_waiting} if BattleManager != null else {},
		"route": _route, "action_log": _action_log, "runs": _runs, "frame_probe": _probe.summary() if _probe != null else {},
		"source": {"commit": OS.get_environment("STSL_BOT_SOURCE_COMMIT"),
			"hash": OS.get_environment("STSL_BOT_SOURCE_HASH"), "gameplay_hash": OS.get_environment("STSL_BOT_GAMEPLAY_HASH"), "dirty_entries": OS.get_environment("STSL_BOT_SOURCE_DIRTY")},
		"limits": ["Uses production battle, scene transitions and win/loss rules; it does not alter HP or force wins.",
			"Map route is deliberately seeded; global VFX/random presentation may still vary.",
			"Frame intervals include transitions, VSync and scheduling; they are not GPU timings."]
	}
	# An unsafe startup must not create a report under a player's user:// either.
	if status == "error" and detail.begins_with("Refusing to run outside"):
		print("[campaign_bot] %s: %s" % [_outcome, _reason])
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(_report_path.get_base_dir())
	var file := FileAccess.open(_report_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(report, "\t"))
		file.close()
	else:
		push_error("Campaign bot could not write report: " + _report_path)
	print("[campaign_bot] %s: %s → %s" % [_outcome, _reason, _report_path])
	call_deferred("_cleanup_and_quit", 0 if _outcome == "clear" and (_probe == null or _probe.summary().get("write_error", "") == "") else 1)

func _cleanup_and_quit(exit_code: int) -> void:
	# Let the active rendered scene release VFX/tweens before the command-line
	# tree exits; this keeps bot failures distinct from shutdown-only leaks.
	var transition := root.get_node_or_null("SceneTransition")
	if transition != null and transition.get("_tween") != null:
		transition.get("_tween").kill()
	if current_scene != null:
		current_scene.queue_free()
	if BattleManager != null:
		BattleManager.is_battle_active = false
	var audio := root.get_node_or_null("AudioManager")
	if audio != null:
		for node in audio.get_children():
			if node is AudioStreamPlayer or node is AudioStreamPlayer2D:
				node.stop()
				node.stream = null
			elif node is Timer:
				node.stop()
	if _probe != null:
		_probe.set_process(false)
	await process_frame
	await process_frame
	GPU_HELPERS.release_cached_textures()
	CLASSIC_CARD._art_cache.clear()
	CLASSIC_CARD._frame_cache.clear()
	MODERN_CARD.release_cached_textures()
	# Input holds custom cursor ImageTextures beyond scene teardown unless every
	# shape is reset.  Release those references before RenderingServer shutdown.
	for shape in range(Input.CURSOR_ARROW, Input.CURSOR_HELP + 1):
		Input.set_custom_mouse_cursor(null, shape)
	var sacred_theme := root.get_node_or_null("SacredTheme")
	if sacred_theme != null:
		sacred_theme._cursor_textures_cache.clear()
		sacred_theme._cursor_hotspots_cache.clear()
	await create_timer(0.1, true, false, true).timeout
	quit(exit_code)

func _on_run_ended(won: bool) -> void:
	if not won:
		_finish("defeat", "GameManager emitted run_ended(false)")
