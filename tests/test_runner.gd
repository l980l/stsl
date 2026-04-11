# tests/test_runner.gd
extends SceneTree

func _init() -> void:
	var total_passed: int = 0
	var total_failed: int = 0

	# 테스트 클래스 목록 — 이후 태스크에서 추가
	var suites: Array = []

	for suite in suites:
		var result: Dictionary = suite.run_all()
		total_passed += result.passed
		total_failed += result.failed

	print("\n=== Results: %d passed, %d failed ===" % [total_passed, total_failed])
	quit(1 if total_failed > 0 else 0)
