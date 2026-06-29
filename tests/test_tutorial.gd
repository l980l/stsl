# tests/test_tutorial.gd
class_name TestTutorial
extends RefCounted

const BM = preload("res://autoload/battle_manager.gd")

var passed: int = 0
var failed: int = 0

func run_all() -> Dictionary:
	test_force_crit_returns_crit()
	test_force_crit_off_by_default()
	test_tutorial_completed_roundtrip()
	test_modern_card_glow_sets_opacity()
	test_driver_advances_and_completes()
	test_lesson_basics_builders()
	return {"passed": passed, "failed": failed}

func _assert(cond: bool, msg: String) -> void:
	if cond:
		passed += 1
		print("  PASS: " + msg)
	else:
		failed += 1
		print("  FAIL: " + msg)

func test_force_crit_off_by_default() -> void:
	print("[TestTutorial] test_force_crit_off_by_default")
	var bm = BM.new()
	_assert(bm.tutorial_force_crit == false, "tutorial_force_crit 기본 false")
	bm.free()

func test_force_crit_returns_crit() -> void:
	print("[TestTutorial] test_force_crit_returns_crit")
	var bm = BM.new()
	bm.tutorial_force_crit = true
	var r: Dictionary = bm._roll_crit(0, false)
	_assert(r["is_crit"] == true, "force_crit 시 is_crit true")
	_assert(r["crit_mult"] == BM.CRIT_MULTIPLIER, "force_crit 시 crit_mult = ×2")
	bm.free()

func test_tutorial_completed_roundtrip() -> void:
	print("[TestTutorial] test_tutorial_completed_roundtrip")
	var PM = load("res://autoload/progress_manager.gd")
	var pm = PM.new()
	pm.reset_progress()
	_assert(not pm.is_tutorial_completed("basics"), "초기 미완료")
	var first: bool = pm.complete_tutorial("basics")
	var dup: bool = pm.complete_tutorial("basics")
	_assert(first == true, "신규 완료 true")
	_assert(dup == false, "중복 완료 false")
	var d: Dictionary = pm.to_dict()
	var pm2 = PM.new()
	pm2.from_dict(d)
	_assert(pm2.is_tutorial_completed("basics"), "직렬화 복원")

func test_modern_card_glow_sets_opacity() -> void:
	print("[TestTutorial] test_modern_card_glow_sets_opacity")
	var scn = load("res://scenes/card/card_scene_v2.tscn")
	var card = scn.instantiate()
	# _create_glow_rect() 를 직접 호출 (테스트에서 트리 추가 불가)
	card._create_glow_rect()
	card.show_glow(1.0)
	var op = card._glow_mat.get_shader_parameter("opacity")
	_assert(op == 1.0, "show_glow 시 opacity=1.0")
	card.hide_glow()
	_assert(card._glow_mat.get_shader_parameter("opacity") == 0.0, "hide_glow 시 opacity=0.0")
	card.free()

func test_driver_advances_and_completes() -> void:
	print("[TestTutorial] test_driver_advances_and_completes")
	var TD = load("res://scenes/tutorial/tutorial_driver.gd")
	var d = TD.new()
	var main_loop = Engine.get_main_loop()
	if main_loop and main_loop.root:
		main_loop.root.add_child(d)
	else:
		d._ready()
	var done = [false]
	d.lesson_completed.connect(func() -> void: done[0] = true)
	d.start([
		{"text": "tutorial.basics.s1", "complete_event": "card_played"},
		{"text": "tutorial.basics.s2", "complete_event": "turn_ended"},
	])
	d.notify("turn_ended")  # 잘못된 이벤트 — 진행 안 함
	_assert(d.current_step()["text"] == "tutorial.basics.s1", "불일치 이벤트는 진행 안 함")
	d.notify("card_played")
	_assert(d.current_step()["text"] == "tutorial.basics.s2", "일치 이벤트로 다음 스텝")
	d.notify("turn_ended")
	_assert(d.is_finished(), "마지막 스텝 통과 시 종료")
	_assert(done[0] == true, "lesson_completed emit")
	d.queue_free()

func test_lesson_basics_builders() -> void:
	print("[TestTutorial] test_lesson_basics_builders")
	var LB = load("res://scenes/tutorial/lessons/lesson_basics.gd")
	_assert(LB.lesson_id() == "basics", "lesson_id basics")
	var enemy = LB.build_enemy()
	_assert(enemy.intent_pattern.size() >= 1, "적 intent_pattern 비어있지 않음")
	_assert(enemy.intent_pattern[0].action_type == IntentResource.ActionType.ATTACK, "첫 인텐트 ATTACK")
	var deck = LB.build_deck()
	_assert(deck.size() == 3, "덱 3장")
	for c in deck:
		_assert(c.is_innate == true, "모든 카드 is_innate")
	var steps = LB.steps()
	_assert(steps.size() >= 3, "스텝 3개 이상")
	_assert(steps[0].has("text") and steps[0].has("complete_event"), "스텝 형식 유효")
