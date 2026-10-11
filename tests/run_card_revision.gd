extends SceneTree

func _init() -> void:
	var result: Dictionary = load("res://tests/test_card_revision_acceptance.gd").new().run_all()
	var difficulty: Dictionary = load("res://tests/test_revision_difficulty.gd").new().run_all()
	result.passed += difficulty.passed
	result.failed += difficulty.failed
	print("Card revision: %d passed, %d failed" % [result.passed, result.failed])
	quit(1 if result.failed else 0)
