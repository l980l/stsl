extends SceneTree

const Suite = preload("res://tests/test_card_upgrade_completeness.gd")

func _init() -> void:
	var result: Dictionary = Suite.new().run_all()
	print("=== Card upgrade completeness: %d passed, %d failed ===" % [result.passed, result.failed])
	quit(1 if result.failed > 0 else 0)
