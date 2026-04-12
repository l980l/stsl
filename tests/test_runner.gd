# tests/test_runner.gd
extends SceneTree

# tests 디렉토리의 테스트 클래스들
var TestResources = preload("res://tests/test_resources.gd")
var TestTeamManager = preload("res://tests/test_team_manager.gd")
var TestDeckManager = preload("res://tests/test_deck_manager.gd")

func _init() -> void:
	var total_passed: int = 0
	var total_failed: int = 0

	# 테스트 클래스 목록 — 이후 태스크에서 추가
	var suites: Array = [TestResources.new(), TestTeamManager.new(), TestDeckManager.new()]

	for suite in suites:
		var result: Dictionary = suite.run_all()
		total_passed += result.passed
		total_failed += result.failed

	print("\n=== Results: %d passed, %d failed ===" % [total_passed, total_failed])
	quit(1 if total_failed > 0 else 0)
