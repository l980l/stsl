extends SceneTree

const TestCardContentEffects = preload("res://tests/test_card_content_effects.gd")

func _init() -> void:
	var result: Dictionary = TestCardContentEffects.new().run_all()
	print("[CardContentEffects] %d passed, %d failed" % [result.passed, result.failed])
	quit(1 if result.failed > 0 else 0)
