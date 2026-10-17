extends SceneTree

const Production = preload("res://autoload/battle_manager.gd")
const Ablation = preload("res://tests/block_balance_battle_manager.gd")
const Fixture = preload("res://tests/test_card_revision_runtime.gd")
var failed := 0
var passed := 0

func _init() -> void:
	call_deferred("_run")

func _check(ok: bool, label: String) -> void:
	if ok:
		passed += 1
	else:
		failed += 1
		push_error(label)

func _battle(script: GDScript):
	var bm = script.new()
	bm.team_mgr = Fixture.TM.new()
	bm.deck_mgr = Fixture.DM.new()
	bm._test_disable_crit = true
	bm.turn_interval = 0.0
	var hero := Fixture.Hero.new()
	hero.hero_id = "napoleon"
	hero.max_hp = 100
	bm.team_mgr.add_hero(hero)
	var enemy := Fixture.Enemy.new()
	enemy.max_hp = 500
	enemy.signatures_enabled = false
	bm.setup_battle([enemy])
	bm._gain_block("napoleon", 10)
	return bm

func _run() -> void:
	AudioServer.set_bus_mute(0, true)
	for hits in [1, 2]:
		var states: Array = []
		for mode in ["production", "new_fixture", "permanent"]:
			var bm = _battle(Production if mode == "production" else Ablation)
			if mode != "production":
				bm.keep_block = mode == "permanent"
			var attack := Fixture.Intent.new()
			attack.value = 3
			attack.target = Fixture.Intent.TargetType.LOWEST_HP
			var intent: Resource = attack
			if hits == 2:
				intent = Fixture.Intent.new()
				intent.action_type = Fixture.Intent.ActionType.CHARGE_UP
				intent.charge_turns = 1
				intent.payoff_intents = [attack, attack.duplicate(true)]
			await bm._execute_intent(0, intent)
			states.append([bm.team_mgr.get_current_hp("napoleon"), bm.get_hero_block("napoleon")])
			if mode == "new_fixture":
				_check(bm.expired_block == 10 - 3 * hits, "expiry meter matches unused pool")
			bm.team_mgr.free()
			bm.deck_mgr.free()
			bm.free()
		_check(states[0] == states[1] and states[0] == [100, 0], "new ablation matches production attack")
		_check(states[2] == [100, 10 - 3 * hits], "old ablation retains only unused block")
	print("Block balance fixture: %d passed, %d failed" % [passed, failed])
	quit(1 if failed else 0)
