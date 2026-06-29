# 튜토리얼 Phase 1 (인프라 + glow + L1 기초 전투) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 메인메뉴에서 옵트인으로 진입하는 첫 튜토리얼 레슨(L1 기초 전투)을, 재사용 가능한 TutorialDriver 인프라 + 모던 프레임 glow 보강과 함께 구현한다.

**Architecture:** 기존 `battle_scene`를 그대로 재사용하되, `GameManager.tutorial_lesson_id`가 설정되면 battle_scene이 `TutorialDriver`(오버레이 CanvasLayer)를 띄워 스텝 시퀀스를 구동한다. 레슨은 영웅/덱/적을 코드로 생성(`is_innate`로 손패 보장, `intent_pattern` 고정)하고, 결정성은 `BattleManager.tutorial_force_crit` 플래그로 확보한다. 진행도는 `ProgressManager`에 영속화한다.

**Tech Stack:** Godot 4.6.2, GDScript. 테스트는 `tests/test_runner.gd`(SceneTree, RefCounted suite) 헤드리스.

## Global Constraints

- Godot 4.6.2 / GDScript. 네이밍: 클래스 PascalCase, 변수·함수 snake_case, 상수 UPPER_SNAKE_CASE, 시그널 동사_명사.
- 타입 힌트 명시. `_process()` 남용 금지(글로우 펄스는 `_pulse_period>0`일 때만).
- i18n: 영어 raw 문자열 UI 삽입 금지 — 모든 표시 텍스트는 `strings_tutorial.csv` 키. CSV 14열: `keys,ko,en,fr,it,es,ja,el,zh,zh_TW,ru,pt,pl,de`. ko/en 필수, 나머지는 en 복사 허용.
- 방어도는 "누적·유지"로 설명(한 턴 지속 아님).
- 헤드리스 Godot 절대경로: `H:/Program Files/Godot/Godot_v4.6.2-stable_win64_console.exe`.
- 테스트 전체 실행: `"H:/Program Files/Godot/Godot_v4.6.2-stable_win64_console.exe" --headless -s tests/test_runner.gd`
- 커밋만, push/PR은 사용자 승인 후. 브랜치 `feat/tutorial-system` 에서 작업.

---

## 파일 구조

**생성**
- `scenes/tutorial/tutorial_driver.gd` — 스텝 시퀀스 엔진 + 오버레이(지시문/딤). 시그널·데이터 기반, battle 비의존(단위 테스트 가능).
- `scenes/tutorial/tutorial_select_scene.gd` + `.tscn` — 레슨 목록 메뉴.
- `scenes/tutorial/lessons/lesson_basics.gd` — L1 데이터: 영웅/덱/적 빌더 + 스텝 정의.
- `resources/translations/strings_tutorial.csv` — i18n.
- `tests/test_tutorial.gd` — 단위 테스트.

**수정**
- `autoload/battle_manager.gd` — `tutorial_force_crit` 훅.
- `autoload/progress_manager.gd` — `tutorial_completed` 플래그 + 메서드 + 직렬화.
- `autoload/game_manager.gd` — `tutorial_lesson_id` 상태 + 정리.
- `scenes/card/card_scene_v2.gd` — glow 6종 실제 구현.
- `scenes/main_menu/main_menu_scene.gd` — "튜토리얼" ledger 행.
- `scenes/battle/battle_scene.gd` — 튜토리얼 모드 부트스트랩(드라이버 생성 + 시그널 브리지 + 승리 처리 + 입력 게이팅).
- `tests/test_runner.gd` — `TestTutorial` 등록.
- `project.godot` — `scenes/tutorial/` 신규 디렉토리(코드만, 등록 불필요). `strings_tutorial.csv`를 LocaleManager 로드 목록에 추가(아래 Task 7).

---

## Task 1: BattleManager `tutorial_force_crit` 훅

**Files:**
- Modify: `autoload/battle_manager.gd` (전역 변수 추가 + `_roll_crit` 분기, :2682 인근)
- Test: `tests/test_tutorial.gd`

**Interfaces:**
- Produces: `BattleManager.tutorial_force_crit: bool` (기본 false). true면 `_roll_crit(...)`가 항상 `{"crit_mult": CRIT_MULTIPLIER, "is_crit": true}` 반환.

- [ ] **Step 1: 실패 테스트 작성** — `tests/test_tutorial.gd` 신규 생성

```gdscript
# tests/test_tutorial.gd
class_name TestTutorial
extends RefCounted

const BM = preload("res://autoload/battle_manager.gd")

var passed: int = 0
var failed: int = 0

func run_all() -> Dictionary:
	test_force_crit_returns_crit()
	test_force_crit_off_by_default()
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
```

- [ ] **Step 2: 테스트 러너에 등록 후 실패 확인**

`tests/test_runner.gd`의 preload 목록과 suites 배열에 추가:
```gdscript
var TestTutorial = preload("res://tests/test_tutorial.gd")
```
suites 배열 끝에 `TestTutorial.new(),` 추가.

Run: `"H:/Program Files/Godot/Godot_v4.6.2-stable_win64_console.exe" --headless -s tests/test_runner.gd`
Expected: TestTutorial에서 FAIL (`tutorial_force_crit` 미정의 → 파스/런타임 에러 또는 assert 실패)

- [ ] **Step 3: 최소 구현** — `autoload/battle_manager.gd`

CRIT 상수 블록(:51~53) 아래에 변수 추가:
```gdscript
# 튜토리얼 — true면 치명타 확정 (시연용). debug_hero_invincible 패턴.
var tutorial_force_crit: bool = false
```
`_roll_crit`(:2682) 함수 본문 첫 줄(`if _test_disable_crit:` 위)에 추가:
```gdscript
	if tutorial_force_crit:
		return {"crit_mult": CRIT_MULTIPLIER, "is_crit": true}
```

- [ ] **Step 4: 테스트 통과 확인**

Run: `"H:/Program Files/Godot/Godot_v4.6.2-stable_win64_console.exe" --headless -s tests/test_runner.gd`
Expected: TestTutorial 2 PASS, 전체 0 failed

- [ ] **Step 5: 커밋**

```bash
git add autoload/battle_manager.gd tests/test_tutorial.gd tests/test_runner.gd
git commit -m "feat: BattleManager tutorial_force_crit hook"
```

---

## Task 2: ProgressManager 튜토리얼 진행 플래그

**Files:**
- Modify: `autoload/progress_manager.gd` (변수 + 메서드 + reset/to_dict/from_dict)
- Test: `tests/test_tutorial.gd`

**Interfaces:**
- Produces:
  - `ProgressManager.tutorial_completed: Array`
  - `func complete_tutorial(lesson_id: String) -> bool` (신규면 append+save+true)
  - `func is_tutorial_completed(lesson_id: String) -> bool`
  - to_dict/from_dict에 `"tutorial_completed"` 포함

- [ ] **Step 1: 실패 테스트 추가** — `tests/test_tutorial.gd`

`run_all()`에 `test_tutorial_completed_roundtrip()` 추가하고 함수 작성:
```gdscript
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
```

- [ ] **Step 2: 실패 확인**

Run: `"H:/Program Files/Godot/Godot_v4.6.2-stable_win64_console.exe" --headless -s tests/test_runner.gd`
Expected: FAIL (`complete_tutorial` 미정의)

- [ ] **Step 3: 구현** — `autoload/progress_manager.gd`

변수(`discovered_monsters` 아래, :18 인근)에 추가:
```gdscript
var tutorial_completed: Array = []  # 완료한 튜토리얼 레슨 id 목록. 영구 저장.
```
`reset_progress()`에 추가: `tutorial_completed.clear()`
메서드 추가(`discover_monster` 인근):
```gdscript
func complete_tutorial(lesson_id: String) -> bool:
	if lesson_id == "" or lesson_id in tutorial_completed:
		return false
	tutorial_completed.append(lesson_id)
	save_progress()
	return true

func is_tutorial_completed(lesson_id: String) -> bool:
	return lesson_id in tutorial_completed
```
`to_dict()` 딕셔너리에 추가: `"tutorial_completed": tutorial_completed.duplicate(),`
`from_dict()`에 추가: `tutorial_completed = data.get("tutorial_completed", []).duplicate()`

- [ ] **Step 4: 통과 확인**

Run: `"H:/Program Files/Godot/Godot_v4.6.2-stable_win64_console.exe" --headless -s tests/test_runner.gd`
Expected: 전체 0 failed

- [ ] **Step 5: 커밋**

```bash
git add autoload/progress_manager.gd tests/test_tutorial.gd
git commit -m "feat: ProgressManager tutorial_completed persistence"
```

---

## Task 3: 모던 프레임(card_scene_v2) glow 구현

**Files:**
- Modify: `scenes/card/card_scene_v2.gd` (glow 6종 no-op → 실제 구현, :46~49 변수·:193~198 함수·_ready)
- Test: `tests/test_tutorial.gd`

**Interfaces:**
- Produces: `card_scene_v2` 인스턴스의 `set_glow_color/show_glow/hide_glow/start_glow_pulse/stop_glow_pulse/tween_glow`가 `_glow_mat`(ShaderMaterial) 셰이더 파라미터를 실제로 설정. 클래식 `card_scene.gd`(:80~151)와 동일 시그니처·동작.
- 모던 카드 크기 196×280 (card_scene_v2.tscn 루트).

- [ ] **Step 1: 실패 테스트 추가** — `tests/test_tutorial.gd`

`run_all()`에 `test_modern_card_glow_sets_opacity()` 추가:
```gdscript
func test_modern_card_glow_sets_opacity() -> void:
	print("[TestTutorial] test_modern_card_glow_sets_opacity")
	var scn = load("res://scenes/card/card_scene_v2.tscn")
	var card = scn.instantiate()
	# _ready 가 _create_glow_rect 를 호출하도록 트리에 추가
	var root = Engine.get_main_loop().root
	root.add_child(card)
	card.show_glow(1.0)
	var op = card._glow_mat.get_shader_parameter("opacity")
	_assert(op == 1.0, "show_glow 시 opacity=1.0")
	card.hide_glow()
	_assert(card._glow_mat.get_shader_parameter("opacity") == 0.0, "hide_glow 시 opacity=0.0")
	card.queue_free()
```

- [ ] **Step 2: 실패 확인**

Run: `"H:/Program Files/Godot/Godot_v4.6.2-stable_win64_console.exe" --headless -s tests/test_runner.gd`
Expected: FAIL (`_glow_mat` null — no-op)

- [ ] **Step 3: 구현** — `scenes/card/card_scene_v2.gd`

(a) 노드 참조 블록 아래(:65 인근)에 glow 상태 변수 추가:
```gdscript
var _glow_rect: ColorRect = null
var _glow_mat: ShaderMaterial = null
var _glow_color: Color = SacredPalette.BRASS_300
var _glow_tween: Tween = null
var _pulse_color_a: Color = Color.WHITE
var _pulse_color_b: Color = Color.WHITE
var _pulse_period: float = 0.0
var _pulse_age: float = 0.0
```

(b) `_ready()`(:76) 끝(`refresh()` 호출 뒤)에 추가:
```gdscript
	_create_glow_rect()
```

(c) glow 6종 no-op(:193~198) 전체를 다음으로 교체:
```gdscript
func _create_glow_rect() -> void:
	const PAD := 14.0
	const INSET := 8.0
	const W := 196.0 + PAD * 2.0
	const H := 280.0 + PAD * 2.0
	var glow := ColorRect.new()
	var mat := ShaderMaterial.new()
	var _theme := get_node_or_null("/root/SacredTheme")
	if _theme:
		mat.shader = _theme._get_card_glow_shader()
	mat.set_shader_parameter("opacity", 0.0)
	mat.set_shader_parameter("radius", 0.0)
	mat.set_shader_parameter("edge_uv", Vector2((PAD + INSET) / W, (PAD + INSET) / H))
	mat.set_shader_parameter("glow_color", Vector4(_glow_color.r, _glow_color.g, _glow_color.b, 1.0))
	glow.material = mat
	glow.position = Vector2(-PAD, -PAD)
	glow.size = Vector2(W, H)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(glow)
	move_child(glow, 0)
	_glow_rect = glow
	_glow_mat = mat

func show_glow(intensity: float = 1.0) -> void:
	if _glow_mat:
		_glow_mat.set_shader_parameter("opacity", intensity)
		_glow_mat.set_shader_parameter("radius", 1.0)

func hide_glow() -> void:
	if _glow_mat:
		_glow_mat.set_shader_parameter("opacity", 0.0)
		_glow_mat.set_shader_parameter("radius", 0.0)

func set_glow_color(color: Color) -> void:
	_glow_color = color
	_pulse_period = 0.0
	if _glow_mat:
		_glow_mat.set_shader_parameter("glow_color", Vector4(color.r, color.g, color.b, 1.0))

func start_glow_pulse(color_a: Color, color_b: Color, period: float = 1.2) -> void:
	_pulse_color_a = color_a
	_pulse_color_b = color_b
	_pulse_period = period
	_pulse_age = 0.0
	set_process(true)

func stop_glow_pulse() -> void:
	_pulse_period = 0.0

func _process(delta: float) -> void:
	if _pulse_period > 0.0 and _glow_mat:
		_pulse_age += delta
		var t: float = (sin(_pulse_age * TAU / _pulse_period) + 1.0) * 0.5
		var c: Color = _pulse_color_a.lerp(_pulse_color_b, t)
		_glow_mat.set_shader_parameter("glow_color", Vector4(c.r, c.g, c.b, 1.0))

func tween_glow(alpha: float, duration: float) -> void:
	if not _glow_mat:
		return
	if _glow_tween and _glow_tween.is_valid():
		_glow_tween.kill()
	var entering := alpha > 0.0
	var _theme2 := get_node_or_null("/root/SacredTheme")
	if _theme2:
		_glow_tween = _theme2.tween_glow_material(self, _glow_mat, alpha, 1.0 if entering else 0.0, duration, not entering)
```

- [ ] **Step 4: 통과 확인**

Run: `"H:/Program Files/Godot/Godot_v4.6.2-stable_win64_console.exe" --headless -s tests/test_runner.gd`
Expected: 전체 0 failed

- [ ] **Step 5: 커밋**

```bash
git add scenes/card/card_scene_v2.gd tests/test_tutorial.gd
git commit -m "feat: implement glow on modern card frame (card_scene_v2)"
```

---

## Task 4: TutorialDriver 스텝 엔진

**Files:**
- Create: `scenes/tutorial/tutorial_driver.gd`
- Test: `tests/test_tutorial.gd`

**Interfaces:**
- Produces (`TutorialDriver` extends CanvasLayer):
  - signal `lesson_completed`
  - `func start(steps: Array) -> void` — steps[i] = Dictionary{ "text": String(i18n key), "complete_event": String, "complete_check": Callable(또는 미설정), "allowed_cards": Array[String] }
  - `func notify(event: String, data: Dictionary = {}) -> void` — 현재 스텝의 `complete_event`와 일치하고 (`complete_check` 없거나 `complete_check.call(data)==true`)면 다음 스텝. 마지막 스텝 통과 시 `lesson_completed` emit.
  - `func current_step() -> Dictionary` (없으면 {})
  - `func current_allowed_cards() -> Array` (현재 스텝의 allowed_cards, 없으면 [])
  - `func is_finished() -> bool`
- Consumes: `BattleManager.CRIT_MULTIPLIER` 불필요. i18n `tr()`.

- [ ] **Step 1: 실패 테스트 추가** — `tests/test_tutorial.gd`

`run_all()`에 `test_driver_advances_and_completes()` 추가:
```gdscript
func test_driver_advances_and_completes() -> void:
	print("[TestTutorial] test_driver_advances_and_completes")
	var TD = load("res://scenes/tutorial/tutorial_driver.gd")
	var d = TD.new()
	Engine.get_main_loop().root.add_child(d)
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
```

- [ ] **Step 2: 실패 확인**

Run: `"H:/Program Files/Godot/Godot_v4.6.2-stable_win64_console.exe" --headless -s tests/test_runner.gd`
Expected: FAIL (tutorial_driver.gd 없음)

- [ ] **Step 3: 구현** — `scenes/tutorial/tutorial_driver.gd`

```gdscript
# scenes/tutorial/tutorial_driver.gd
# 튜토리얼 레슨 스텝 시퀀스 구동 오버레이. 시그널·데이터 기반(battle 비의존).
class_name TutorialDriver
extends CanvasLayer

signal lesson_completed

var _steps: Array = []
var _idx: int = -1
var _label: Label = null
var _dim: ColorRect = null

func _ready() -> void:
	layer = 60
	_dim = ColorRect.new()
	_dim.color = Color(0, 0, 0, 0.45)
	_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_dim)
	_label = Label.new()
	_label.theme_type_variation = "TitleLabel"
	_label.add_theme_font_size_override("font_size", 28)
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_label.offset_left = -520
	_label.offset_right = 520
	_label.offset_top = -220
	_label.offset_bottom = -120
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)

func start(steps: Array) -> void:
	_steps = steps
	_idx = -1
	_advance()

func _advance() -> void:
	_idx += 1
	if _idx >= _steps.size():
		_render("")
		lesson_completed.emit()
		return
	_render(tr(_steps[_idx].get("text", "")))

func _render(text: String) -> void:
	if _label:
		_label.text = text

func notify(event: String, data: Dictionary = {}) -> void:
	if is_finished():
		return
	var step: Dictionary = _steps[_idx]
	if step.get("complete_event", "") != event:
		return
	var check = step.get("complete_check", null)
	if check is Callable and not check.call(data):
		return
	_advance()

func current_step() -> Dictionary:
	if _idx < 0 or _idx >= _steps.size():
		return {}
	return _steps[_idx]

func current_allowed_cards() -> Array:
	var step: Dictionary = current_step()
	return step.get("allowed_cards", [])

func is_finished() -> bool:
	return _idx >= _steps.size()
```

- [ ] **Step 4: 통과 확인**

Run: `"H:/Program Files/Godot/Godot_v4.6.2-stable_win64_console.exe" --headless -s tests/test_runner.gd`
Expected: 전체 0 failed

- [ ] **Step 5: 커밋**

```bash
git add scenes/tutorial/tutorial_driver.gd tests/test_tutorial.gd
git commit -m "feat: TutorialDriver step sequence engine"
```

---

## Task 5: L1 레슨 데이터 빌더 (lesson_basics)

**Files:**
- Create: `scenes/tutorial/lessons/lesson_basics.gd`
- Test: `tests/test_tutorial.gd`

**Interfaces:**
- Produces (`LessonBasics`, 정적 함수 모음):
  - `static func lesson_id() -> String` → `"basics"`
  - `static func build_enemy() -> EnemyResource` — `intent_pattern` 고정(ATTACK value 6 RANDOM 반복), max_hp 40
  - `static func build_deck() -> Array` — `CardResource` 3장(공격/방어/파워), 전부 `is_innate=true`, owner_id="napoleon"
  - `static func steps() -> Array` — TutorialDriver step 배열
- Consumes: `EnemyResource`, `IntentResource`, `CardResource`, `EffectResource` (전역 class_name).

- [ ] **Step 1: 실패 테스트 추가** — `tests/test_tutorial.gd`

`run_all()`에 `test_lesson_basics_builders()` 추가:
```gdscript
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
```

- [ ] **Step 2: 실패 확인**

Run: `"H:/Program Files/Godot/Godot_v4.6.2-stable_win64_console.exe" --headless -s tests/test_runner.gd`
Expected: FAIL (lesson_basics.gd 없음)

- [ ] **Step 3: 구현** — `scenes/tutorial/lessons/lesson_basics.gd`

```gdscript
# scenes/tutorial/lessons/lesson_basics.gd
# L1 기초 전투 — 영웅/덱/적 빌더 + 스텝 정의.
class_name LessonBasics
extends RefCounted

const HERO_ID := "napoleon"

static func lesson_id() -> String:
	return "basics"

static func _make_effect(etype: int, value: int, target: String = "SINGLE", status_type: String = "") -> EffectResource:
	var e := EffectResource.new()
	e.effect_type = etype
	e.value = value
	e.base_value = value
	e.target = target
	e.status_type = status_type
	return e

static func _make_card(name_key: String, cost: int, ctype: int, effect: EffectResource) -> CardResource:
	var c := CardResource.new()
	c.card_name = name_key
	c.owner_id = HERO_ID
	c.cost = cost
	c.card_type = ctype
	c.effects = [effect]
	c.is_innate = true
	return c

static func build_deck() -> Array:
	var atk := _make_card("tutorial.card.strike.name", 1, CardResource.CardType.ATTACK,
		_make_effect(EffectResource.EffectType.DAMAGE, 6))
	var blk := _make_card("tutorial.card.guard.name", 1, CardResource.CardType.SKILL,
		_make_effect(EffectResource.EffectType.BLOCK, 5))
	var pwr := _make_card("tutorial.card.resolve.name", 1, CardResource.CardType.POWER,
		_make_effect(EffectResource.EffectType.APPLY_STATUS, 2, "SELF", "strength"))
	return [atk, blk, pwr]

static func build_enemy() -> EnemyResource:
	var e := EnemyResource.new()
	e.enemy_name = "tutorial.enemy.dummy.name"
	e.mythology = "greek"
	e.grade = EnemyResource.Grade.NORMAL
	e.max_hp = 40
	e.signatures_enabled = false
	var atk := IntentResource.new()
	atk.action_type = IntentResource.ActionType.ATTACK
	atk.value = 6
	atk.target = IntentResource.TargetType.RANDOM
	atk.damage_type = "slash"
	e.intent_pattern = [atk]
	return e

# 스텝: text(i18n) + 완료 이벤트. 이벤트는 battle_scene 브리지가 notify.
static func steps() -> Array:
	return [
		{"text": "tutorial.basics.s1_intro", "complete_event": "card_played"},
		{"text": "tutorial.basics.s2_block", "complete_event": "card_played"},
		{"text": "tutorial.basics.s3_endturn", "complete_event": "turn_ended"},
		{"text": "tutorial.basics.s4_crit", "complete_event": "crit_landed"},
		{"text": "tutorial.basics.s5_win", "complete_event": "battle_won"},
	]
```

- [ ] **Step 4: 통과 확인**

Run: `"H:/Program Files/Godot/Godot_v4.6.2-stable_win64_console.exe" --headless -s tests/test_runner.gd`
Expected: 전체 0 failed

- [ ] **Step 5: 커밋**

```bash
git add scenes/tutorial/lessons/lesson_basics.gd tests/test_tutorial.gd
git commit -m "feat: L1 lesson_basics data builders"
```

---

## Task 6: 메뉴 진입 + battle_scene 튜토리얼 브리지

**Files:**
- Modify: `autoload/game_manager.gd` (`tutorial_lesson_id` 상태)
- Create: `scenes/tutorial/tutorial_select_scene.gd` + `.tscn`
- Modify: `scenes/main_menu/main_menu_scene.gd` (ledger 행)
- Modify: `scenes/battle/battle_scene.gd` (튜토리얼 부트스트랩 + 시그널 브리지 + 승리 처리 + 입력 게이팅)

**Interfaces:**
- Consumes: `LessonBasics`(Task 5), `TutorialDriver`(Task 4), `BattleManager.tutorial_force_crit`(Task 1), `ProgressManager.complete_tutorial`(Task 2).
- Produces: `GameManager.tutorial_lesson_id: String`, 레슨 부팅 함수 `GameManager.start_tutorial(lesson_id: String)`.

- [ ] **Step 1: GameManager 상태 + 부팅 함수**

`autoload/game_manager.gd` 상단 상태 변수 영역에 추가:
```gdscript
var tutorial_lesson_id: String = ""
```
함수 추가(`start_run` 인근):
```gdscript
# 튜토리얼 레슨 부팅 — 영웅/덱/적을 코드로 세팅 후 battle_scene 진입.
func start_tutorial(lesson_id: String) -> void:
	var LB = load("res://scenes/tutorial/lessons/lesson_basics.gd")
	reset()
	var tm := _get_tm()
	if tm: tm.clear()
	var dm := _get_dm()
	if dm: dm.clear()
	var hero := _make_hero_by_id(LB.HERO_ID)
	if tm: tm.add_hero(hero)
	if dm:
		for c in LB.build_deck():
			dm.add_card_to_deck(c)
	pending_enemies = [LB.build_enemy()]
	tutorial_lesson_id = lesson_id
	change_state(GameState.BATTLE)
	_request_scene("res://scenes/battle/battle_scene.tscn")
```
`complete_battle(won)`(:279) 시작부에 튜토리얼 정리 추가:
```gdscript
	if tutorial_lesson_id != "":
		tutorial_lesson_id = ""
```

- [ ] **Step 2: tutorial_select_scene 생성**

`scenes/tutorial/tutorial_select_scene.tscn` — 루트 `Node2D`(name=`TutorialSelectScene`), 스크립트 `tutorial_select_scene.gd` 연결. (빈 씬; UI는 코드 생성)

`scenes/tutorial/tutorial_select_scene.gd`:
```gdscript
# scenes/tutorial/tutorial_select_scene.gd
extends Node2D

const MONO_FONT := preload("res://assets/fonts/SpaceMono-Regular.ttf")

func _ready() -> void:
	var P := SacredPalette
	var bg := ColorRect.new()
	bg.color = P.INK_900
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	vb.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	vb.offset_left = -300
	vb.offset_right = 300
	root.add_child(vb)
	var title := Label.new()
	title.theme_type_variation = "TitleLabel"
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", P.BRASS_300)
	title.text = tr("tutorial.select.title")
	vb.add_child(title)
	_add_lesson_row(vb, "tutorial.lesson.basics.name", "basics")
	_add_back_row(vb)

func _add_lesson_row(parent: VBoxContainer, name_key: String, lesson_id: String) -> void:
	var P := SacredPalette
	var b := Button.new()
	b.text = tr(name_key) + ("  ✓" if ProgressManager.is_tutorial_completed(lesson_id) else "")
	b.custom_minimum_size = Vector2(0, 64)
	b.add_theme_color_override("font_color", P.BONE_100)
	parent.add_child(b)
	b.pressed.connect(func() -> void: GameManager.start_tutorial(lesson_id))

func _add_back_row(parent: VBoxContainer) -> void:
	var b := Button.new()
	b.text = tr("ui.common.back")
	b.custom_minimum_size = Vector2(0, 48)
	parent.add_child(b)
	b.pressed.connect(func() -> void: SceneTransition.go("res://scenes/main_menu/main_menu_scene.tscn"))
```
(주: `ui.common.back` 키가 strings_ui.csv에 없으면 Task 7에서 strings_tutorial.csv에 `tutorial.select.back`로 대체 — 존재 확인 후 키 선택)

- [ ] **Step 3: 메인메뉴 ledger 행 추가**

`scenes/main_menu/main_menu_scene.gd` `_build_ui` 메뉴 항목(:110 도감 행 위 또는 아래)에 추가:
```gdscript
	_add_ledger_row(rows, "%02d" % idx, tr("tutorial.menu.entry"), "", false, _on_tutorial); idx += 1
```
핸들러 추가(`_on_codex` 인근):
```gdscript
func _on_tutorial() -> void:
	SceneTransition.go("res://scenes/tutorial/tutorial_select_scene.tscn")
```

- [ ] **Step 4: battle_scene 튜토리얼 브리지**

`scenes/battle/battle_scene.gd` `_ready()` 끝(전투 셋업 후, :1283 이후)에 추가:
```gdscript
	if GameManager.tutorial_lesson_id != "":
		_init_tutorial(GameManager.tutorial_lesson_id)
```
함수 추가:
```gdscript
var _tutorial_driver = null

func _init_tutorial(lesson_id: String) -> void:
	var LB = load("res://scenes/tutorial/lessons/lesson_basics.gd")
	var TD = load("res://scenes/tutorial/tutorial_driver.gd")
	_tutorial_driver = TD.new()
	add_child(_tutorial_driver)
	_tutorial_driver.lesson_completed.connect(_on_tutorial_lesson_completed)
	_tutorial_driver.start(LB.steps())
	# 시그널 브리지 — BattleManager 이벤트 → driver.notify
	BattleManager.card_played.connect(func(_c) -> void: _tutorial_driver.notify("card_played"))
	BattleManager.enemy_damaged.connect(func(_i, _a, _t, is_crit) -> void:
		if is_crit: _tutorial_driver.notify("crit_landed"))
	# crit 스텝 도달 시 강제 치명타 — 간단화: 레슨 동안 항상 force_crit
	BattleManager.tutorial_force_crit = true

func _on_tutorial_lesson_completed() -> void:
	ProgressManager.complete_tutorial(GameManager.tutorial_lesson_id)
```
`_on_end_turn_pressed`(:2270)에 추가(함수 시작부):
```gdscript
	if _tutorial_driver: _tutorial_driver.notify("turn_ended")
```
`_on_battle_won`(:5016)에 튜토리얼 분기 추가(함수 시작부):
```gdscript
	if GameManager.tutorial_lesson_id != "":
		BattleManager.tutorial_force_crit = false
		if _tutorial_driver: _tutorial_driver.notify("battle_won")
		ProgressManager.complete_tutorial(GameManager.tutorial_lesson_id)
		GameManager.tutorial_lesson_id = ""
		SceneTransition.go("res://scenes/tutorial/tutorial_select_scene.tscn")
		return
```

- [ ] **Step 5: 헤드리스 부팅 검증 (임시 스크립트)**

`scenes/debug/_tut_boot.gd` 임시 생성:
```gdscript
extends SceneTree
func _init() -> void:
	await create_timer(0.1).timeout
	get_root().get_node("/root/GameManager").start_tutorial("basics")
	await create_timer(1.0).timeout
	print("TUT_BOOT_OK")
	quit(0)
```
Run: `"H:/Program Files/Godot/Godot_v4.6.2-stable_win64_console.exe" --headless -s scenes/debug/_tut_boot.gd`
Expected: 출력에 `TUT_BOOT_OK`, `SCRIPT ERROR`/`Parse` 0건. 확인 후 `scenes/debug/_tut_boot.gd` 삭제.

- [ ] **Step 6: 전체 테스트 + 커밋**

Run: `"H:/Program Files/Godot/Godot_v4.6.2-stable_win64_console.exe" --headless -s tests/test_runner.gd`
Expected: 전체 0 failed
```bash
git add autoload/game_manager.gd scenes/tutorial/ scenes/main_menu/main_menu_scene.gd scenes/battle/battle_scene.gd
git commit -m "feat: tutorial menu entry + L1 battle bridge"
```

---

## Task 7: i18n strings_tutorial.csv + 로드 등록

**Files:**
- Create: `resources/translations/strings_tutorial.csv`
- Modify: LocaleManager CSV 로드 목록 (`autoload/locale_manager.gd`)
- Test: 헤드리스 키 누락 확인

**Interfaces:**
- Produces: 모든 `tutorial.*` 키 정의. ko/en 필수.

- [ ] **Step 1: CSV 생성** — `resources/translations/strings_tutorial.csv`

헤더 + 키(나머지 언어는 en 값 복사). 최소 키:
```
keys,ko,en,fr,it,es,ja,el,zh,zh_TW,ru,pt,pl,de
tutorial.menu.entry,튜토리얼,Tutorial,Tutorial,Tutorial,Tutorial,Tutorial,Tutorial,教程,教程,Tutorial,Tutorial,Tutorial,Tutorial
tutorial.select.title,튜토리얼,Tutorial,...(en 복사)
tutorial.select.back,뒤로,Back,...
tutorial.lesson.basics.name,기초 전투,Combat Basics,...
tutorial.card.strike.name,일격,Strike,...
tutorial.card.guard.name,방어,Guard,...
tutorial.card.resolve.name,결의,Resolve,...
tutorial.enemy.dummy.name,허수아비,Training Dummy,...
tutorial.basics.s1_intro,공격 카드를 적에게 끌어다 사용하세요.,Drag the attack card onto the enemy.,...
tutorial.basics.s2_block,방어 카드를 사용하세요. 방어도는 소모되기 전까지 누적·유지됩니다.,Play the guard card. Block accumulates and persists until consumed.,...
tutorial.basics.s3_endturn,턴 종료 버튼을 누르세요.,Press End Turn.,...
tutorial.basics.s4_crit,공격하세요. 치명타는 기본 5% 확률, 발동 시 피해 ×2(200%)입니다.,Attack. Crits land 5% of the time for ×2 (200%) damage.,...
tutorial.basics.s5_win,적을 처치해 레슨을 완료하세요.,Defeat the enemy to finish the lesson.,...
```
(실제 작성 시 14열 모두 채움 — 미번역 언어는 en 값 복사. 줄임표는 플레이스홀더가 아니라 "en 값 복사" 지시이므로 실제 CSV엔 값 채움.)

- [ ] **Step 2: LocaleManager 로드 등록**

`autoload/locale_manager.gd`에서 기존 strings_*.csv 로드 목록을 찾아 `strings_tutorial.csv` 추가. (기존 `strings_ui.csv` 등록 위치와 동일 패턴 — grep `strings_ui.csv` 로 위치 확인 후 한 줄 추가.)

- [ ] **Step 3: 키 누락 검증 (임시 스크립트)**

`scenes/debug/_tut_i18n.gd`:
```gdscript
extends SceneTree
func _init() -> void:
	var keys := ["tutorial.menu.entry","tutorial.select.title","tutorial.lesson.basics.name",
		"tutorial.card.strike.name","tutorial.basics.s1_intro","tutorial.basics.s5_win"]
	TranslationServer.set_locale("en")
	var miss := 0
	for k in keys:
		if TranslationServer.translate(k) == k:
			print("MISSING en: " + k); miss += 1
	TranslationServer.set_locale("ko")
	for k in keys:
		if TranslationServer.translate(k) == k:
			print("MISSING ko: " + k); miss += 1
	print("I18N_MISS=%d" % miss)
	quit(0)
```
Run: `"H:/Program Files/Godot/Godot_v4.6.2-stable_win64_console.exe" --headless -s scenes/debug/_tut_i18n.gd`
Expected: `I18N_MISS=0`. 확인 후 임시 스크립트 삭제.

- [ ] **Step 4: 커밋**

```bash
git add resources/translations/strings_tutorial.csv autoload/locale_manager.gd
git commit -m "feat: tutorial i18n strings"
```

---

## Self-Review (스펙 대비)

- **L1 커버리지**: 카드 사용(s1)·방어도 누적(s2)·턴 종료(s3)·치명타 5%/×2(s4)·승리(s5) ✅. 카드 3종(공격/방어/파워)은 build_deck로 손패 등장 ✅. 인텐트 색·커서 의미는 기존 battle_scene UI가 표시(추가 스텝 텍스트로 보강 가능 — Phase 1 범위 내 최소 5스텝 유지).
- **glow 보강**: Task 3 모던 프레임 구현 ✅ (선택 하이라이트 4곳 + 카운터 큐도 동시 복구).
- **결정성**: force_crit(Task1) + 고정 intent_pattern + is_innate 덱(Task5) ✅.
- **진행 저장**: Task 2 + 승리 시 complete_tutorial ✅.
- **i18n**: Task 7, 영어 raw 삽입 없음 ✅.
- **입력 게이팅/스포트라이트**: TutorialDriver에 `current_allowed_cards()` 인터페이스만 제공(Phase 1은 딤+지시문). 실제 카드 비활성 적용은 Phase 1.5/후속에서 `_apply_card_state` 연동 — **의도적 축소**(Phase 1은 "동작하는 최소 레슨" 목표).

## 비-목표 (후속 플랜)

- **Phase 2~5**: L2 카운터·차지(빛 큐 실사용) / L3 상태이상·독 / L4 팀빌딩 / 메타 첫-진입 힌트. 각각 별도 플랜 — TutorialDriver 인터페이스 확정(Phase 1) 후 작성.
- 입력 게이팅(허용 카드 외 비활성)·스포트라이트 컷아웃 정밀화.
