# tests/test_tutorial.gd
class_name TestTutorial
extends RefCounted

const BM = preload("res://autoload/battle_manager.gd")

var passed: int = 0
var failed: int = 0

func run_all() -> Dictionary:
	test_force_crit_returns_crit()
	test_force_crit_off_by_default()
	test_tutorial_crit_and_lifecycle()
	test_driver_before_start_and_completion_once()
	test_tutorial_completed_roundtrip()
	test_modern_card_glow_sets_opacity()
	test_driver_advances_and_completes()
	test_lesson_basics_builders()
	test_lesson_counter_builders()
	test_lesson_status_flow()
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

func test_tutorial_crit_and_lifecycle() -> void:
	print("[TestTutorial] test_tutorial_crit_and_lifecycle")
	var bm = BM.new()
	bm.setup_battle([], true)
	var random_crit := false
	for i in range(200):
		random_crit = random_crit or bm._roll_crit(0, true).is_crit or bm._roll_crit_enemy(true).is_crit
	_assert(not random_crit, "학습 중 우연한 치명타는 비활성")
	bm.tutorial_force_crit = true
	_assert(bm._roll_crit(0, false).is_crit, "지정 치명타 단계는 여전히 확정")
	bm.setup_battle([])
	_assert(not bm.tutorial_active and not bm.tutorial_force_crit, "정규 전투 시작 시 튜토리얼 설정 초기화")
	bm.free()

func test_driver_before_start_and_completion_once() -> void:
	var d = load("res://scenes/tutorial/tutorial_driver.gd").new()
	var completions := [0]
	d.lesson_completed.connect(func(): completions[0] += 1)
	d.notify("screen_clicked")
	_assert(d.current_step().is_empty(), "시작 전 이벤트 무시")
	d.start([{"complete_event": "screen_clicked"}])
	d.notify("screen_clicked")
	d.notify("screen_clicked")
	_assert(d.is_finished() and completions[0] == 1, "완료 이벤트는 한 번만 발생")
	d.start([{"complete_event": "screen_clicked"}])
	_assert(not d.is_finished(), "드라이버 재시작 가능")
	d.free()

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
	pm.free()
	pm2.free()

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
	d.free()

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

func test_lesson_counter_builders() -> void:
	print("[TestTutorial] test_lesson_counter_builders")
	var LC = load("res://scenes/tutorial/lessons/lesson_counter.gd")
	var enemy = LC.build_enemy()
	_assert(LC.lesson_id() == "counter", "counter lesson_id")
	_assert(enemy.max_hp == 90, "카운터 레슨 적 HP = 스트라이크 1회 처치 범위")
	_assert(enemy.counter_window_intent.get("enabled", false), "카운터 윈도우 활성")
	var steps = LC.steps()
	_assert(steps.size() == 4, "카운터 레슨은 기절 확인 단계를 포함")
	_assert(steps[2].get("complete_event") == "enemy_turn_ended", "카운터 뒤 적 기절 턴을 기다림")

func test_lesson_status_flow() -> void:
	print("[TestTutorial] test_lesson_status_flow")
	var LS = load("res://scenes/tutorial/lessons/lesson_status.gd")
	var enemy = LS.build_enemy()
	var deck = LS.build_deck()
	var steps = LS.steps()
	_assert(LS.lesson_id() == "status", "status lesson_id")
	_assert(enemy.max_hp == 220, "취약 독침 2회와 독 틱 2회를 모두 보여 주는 HP")
	_assert(deck.size() == 3 and deck[1].card_name == deck[2].card_name, "독 재부여용 독침 2장 제공")
	_assert(steps.size() == 6, "상태 레슨은 독 틱·재부여 단계를 포함")
	_assert(steps[3].get("complete_event") == "enemy_poison_ticked", "첫 독 피해를 확인한 뒤 진행")
	_assert(steps[4].get("allowed_cards", []).size() == 1, "독 재부여 카드만 허용")
