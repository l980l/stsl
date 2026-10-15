extends SceneTree

const TestSmallNumberProfile = preload("res://tests/test_small_number_profile.gd")

func _init() -> void:
	var result: Dictionary = TestSmallNumberProfile.new().run_all()
	print("[SmallNumberProfile] %d passed, %d failed" % [result.passed, result.failed])
	quit(1 if result.failed > 0 else 0)
