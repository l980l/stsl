extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	AudioServer.set_bus_mute(0, true)
	var result: Dictionary = await preload("res://tests/test_small_number_runtime.gd").new().run_detached_token_tests()
	print("Detached token runtime: %d passed, %d failed" % [result.passed, result.failed])
	quit(1 if result.failed > 0 else 0)
