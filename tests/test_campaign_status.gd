extends SceneTree

class DeathTurnBattle extends "res://autoload/battle_manager.gd":
	var progressed := false
	func _run_next_actor_turn() -> void:
		progressed = true

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	if not ProjectSettings.globalize_path("user://").get_base_dir().get_file().begins_with("STSL-campaign-bot-"):
		printerr("Use a fresh isolated campaign-bot project")
		quit(2)
		return
	var tm = root.get_node("TeamManager")
	var gm = root.get_node("GameManager")
	var bm = root.get_node("BattleManager")
	tm.clear()
	for id in ["napoleon", "yi_sun_sin"]:
		tm.add_hero(gm._make_hero_by_id(id))
	bm.is_battle_active = false
	bm._hero_status = {"napoleon": {"silence": 2}, "yi_sun_sin": {"silence": 1}}
	bm._phase_hero_post("napoleon")
	var ok: bool = bm._hero_status.napoleon.silence == 1 and bm._hero_status.yi_sun_sin.silence == 1
	bm._phase_hero_post("napoleon")
	ok = ok and bm._hero_status.napoleon.silence == 0
	var local_team = load("res://autoload/team_manager.gd").new()
	for id in ["napoleon", "yi_sun_sin"]:
		local_team.add_hero(gm._make_hero_by_id(id))
	var death_battle := DeathTurnBattle.new()
	death_battle.team_mgr = local_team
	death_battle.turn_interval = 0.0
	death_battle.is_battle_active = true
	death_battle._hero_status = {"napoleon": {"poison_dmg": 10000, "poison_dur": 1}}
	var announced := [false]
	death_battle.turn_started.connect(func(_actor: String) -> void: announced[0] = true)
	await death_battle._start_hero_turn("napoleon")
	ok = ok and death_battle.progressed and not announced[0]
	death_battle._hero_status["yi_sun_sin"] = {"poison_dmg": 10000, "poison_dur": 1}
	var lost := [false]
	death_battle.battle_lost.connect(func() -> void: lost[0] = true)
	death_battle._tick_hero_poison("yi_sun_sin")
	ok = ok and lost[0] and not death_battle.is_battle_active
	death_battle.free()
	local_team.free()
	print("Campaign silence and poison-death lifecycle: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
