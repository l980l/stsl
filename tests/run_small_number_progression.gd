extends SceneTree

const TestSmallNumberProgression = preload("res://tests/test_small_number_progression.gd")

func _init() -> void:
	var result: Dictionary = TestSmallNumberProgression.new().run_all()
	print("=== Small-number progression: %d passed, %d failed ===" % [result.passed, result.failed])
	quit(1 if result.failed > 0 else 0)
