extends SceneTree

func _init() -> void:
	AudioServer.set_bus_mute(0, true)
	var result: Dictionary = preload("res://tests/test_small_number_runtime.gd").new().run_all()
	print("Small-number runtime: %d passed, %d failed" % [result.passed, result.failed])
	quit(1 if result.failed > 0 else 0)
