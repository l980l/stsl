extends SceneTree

func _init() -> void:
	AudioServer.set_bus_mute(0, true)
	var result: Dictionary = preload("res://tests/test_enemy_small_numbers.gd").new().run_all()
	print("Enemy small numbers: %d passed, %d failed" % [result.passed, result.failed])
	quit(1 if result.failed > 0 else 0)
