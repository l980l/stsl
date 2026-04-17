# Main Menu + Game Over Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 메인 메뉴 씬을 프로젝트 시작 화면으로 설정하고, 게임오버/승리 시 게임오버 씬으로 이동한다.

**Architecture:** 현재 MapScene이 담당하던 "새 게임/이어하기" 분기를 MainMenuScene으로 이전한다. GameManager에 GAME_OVER 상태와 run_won 플래그를 추가하고, 전투 패배/보스 처치 완료 경로를 GameOverScene으로 리다이렉트한다.

**Tech Stack:** GDScript, Godot 4.6, 기존 autoload 패턴 (get_tree().change_scene_to_file)

---

## File Structure

- Create: `scenes/main_menu/main_menu_scene.gd`
- Create: `scenes/main_menu/main_menu_scene.tscn`
- Create: `scenes/game_over/game_over_scene.gd`
- Create: `scenes/game_over/game_over_scene.tscn`
- Modify: `autoload/game_manager.gd` — GAME_OVER 상태, run_won 플래그, 씬 리다이렉트
- Modify: `scenes/map/map_scene.gd` — continue dialog 제거
- Modify: `project.godot` — main_scene → main_menu_scene.tscn
- Modify: `tests/test_game_manager.gd` — 패배 시 GAME_OVER 상태 테스트 추가

---

### Task 1: GameManager GAME_OVER 상태 추가 + 씬 리다이렉트

**Files:**
- Modify: `autoload/game_manager.gd:5,11,78-89,194-213`
- Modify: `tests/test_game_manager.gd:11-16,35-64`

- [ ] **Step 1: 테스트 추가 (실패 확인용)**

`tests/test_game_manager.gd`의 `run_all()`과 본문에 추가:

```gdscript
func run_all() -> Dictionary:
	test_run_map_initialized()
	test_enter_node_marks_visited()
	test_enter_battle_sets_pending_enemies()
	test_complete_battle_generates_rewards()
	test_battle_lost_goes_to_game_over()
	return {"passed": passed, "failed": failed}
```

파일 끝에 추가:
```gdscript
func test_battle_lost_goes_to_game_over() -> void:
	print("[TestGameManager] test_battle_lost_goes_to_game_over")
	var gm := _make_gm()
	gm.enter_node(0)
	gm.complete_battle(false)
	_assert(gm.run_won == false, "패배 시 run_won == false")
	_assert(gm.current_state == 6, "패배 시 상태 GAME_OVER(6)으로 변경")
```

- [ ] **Step 2: 테스트 실패 확인**

```bash
"C:/Users/k9102/AppData/Local/Programs/Godot_v4.6-dev6_win64/Godot_v4.6-dev6_win64.exe" \
  --headless -s tests/test_runner.gd \
  --path "H:/AIRelatedDefaultPath/ClaudeCode_Base/GameProjects/CardGameProject/stsl" 2>&1 | tail -30
```

Expected: `test_battle_lost_goes_to_game_over`에서 FAIL (run_won, GAME_OVER 상태 없음)

- [ ] **Step 3: GameManager 수정**

`autoload/game_manager.gd` 수정:

**Line 5** — enum에 GAME_OVER 추가:
```gdscript
enum GameState { MAP, BATTLE, CARD_PICK, EVENT, SHOP, REST, GAME_OVER }
```

**Line 11 이후** — run_won 변수 추가 (`var relics: Array = []` 아래):
```gdscript
var run_won: bool = false
```

**reset() 함수** — `pending_event = null` 아래에 추가:
```gdscript
	run_won = false
```

**complete_battle() 함수의 else 블록** (현재 lines 194-200) 교체:
```gdscript
	else:
		run_won = false
		run_ended.emit(false)
		var _sm_fail = Engine.get_singleton("SaveManager") if Engine.has_singleton("SaveManager") else null
		if _sm_fail:
			_sm_fail.clear_save()
		change_state(GameState.GAME_OVER)
		_request_scene("res://scenes/game_over/game_over_scene.tscn")
```

**complete_card_pick() 함수의 보스 처치 블록** (현재 lines 206-210) 교체:
```gdscript
	if node.room_type == MapNodeRes.RoomType.BOSS:
		run_won = true
		run_ended.emit(true)
		var _sm_win = Engine.get_singleton("SaveManager") if Engine.has_singleton("SaveManager") else null
		if _sm_win:
			_sm_win.clear_save()
		card_rewards.clear()
		change_state(GameState.GAME_OVER)
		_request_scene("res://scenes/game_over/game_over_scene.tscn")
		return
```

그리고 보스가 아닌 경우의 기존 코드 (`card_rewards.clear()`, `change_state(GameState.MAP)`, `_request_scene(map)`) 는 유지.

전체 `complete_card_pick()` 함수 최종 형태:
```gdscript
func complete_card_pick() -> void:
	var node: Resource = run_map[current_node_id]
	_advance_nodes_from(current_node_id)
	var MapNodeRes = load("res://resources/map_node_resource.gd")
	if node.room_type == MapNodeRes.RoomType.BOSS:
		run_won = true
		run_ended.emit(true)
		var _sm_win = Engine.get_singleton("SaveManager") if Engine.has_singleton("SaveManager") else null
		if _sm_win:
			_sm_win.clear_save()
		card_rewards.clear()
		change_state(GameState.GAME_OVER)
		_request_scene("res://scenes/game_over/game_over_scene.tscn")
		return
	card_rewards.clear()
	change_state(GameState.MAP)
	_request_scene("res://scenes/map/map_scene.tscn")
```

- [ ] **Step 4: 테스트 통과 확인**

```bash
"C:/Users/k9102/AppData/Local/Programs/Godot_v4.6-dev6_win64/Godot_v4.6-dev6_win64.exe" \
  --headless -s tests/test_runner.gd \
  --path "H:/AIRelatedDefaultPath/ClaudeCode_Base/GameProjects/CardGameProject/stsl" 2>&1 | tail -30
```

Expected: 전체 PASS, 이전 304개 + 신규 1개 = 305개 이상

- [ ] **Step 5: 커밋**

```bash
cd H:/AIRelatedDefaultPath/ClaudeCode_Base/GameProjects/CardGameProject/stsl
git add autoload/game_manager.gd tests/test_game_manager.gd
git commit -m "feat: GameManager에 GAME_OVER 상태 추가 — 패배/보스 처치 시 game_over_scene으로 이동"
```

---

### Task 2: MainMenuScene 생성

**Files:**
- Create: `scenes/main_menu/main_menu_scene.gd`
- Create: `scenes/main_menu/main_menu_scene.tscn`

- [ ] **Step 1: 폴더 생성 확인**

```bash
mkdir -p "H:/AIRelatedDefaultPath/ClaudeCode_Base/GameProjects/CardGameProject/stsl/scenes/main_menu"
```

- [ ] **Step 2: main_menu_scene.gd 생성**

```gdscript
# scenes/main_menu/main_menu_scene.gd
extends Node2D

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.1)
	bg.position = Vector2.ZERO
	bg.size = Vector2(1920, 1080)
	add_child(bg)

	var title := Label.new()
	title.text = "STSL"
	title.position = Vector2(660, 200)
	title.size = Vector2(600, 100)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 72)
	title.modulate = Color(1.0, 0.9, 0.4)
	add_child(title)

	var btn_new := Button.new()
	btn_new.text = "새 게임"
	btn_new.position = Vector2(810, 420)
	btn_new.size = Vector2(300, 60)
	btn_new.add_theme_font_size_override("font_size", 24)
	btn_new.pressed.connect(_on_new_game)
	add_child(btn_new)

	if SaveManager.has_save():
		var btn_cont := Button.new()
		btn_cont.text = "이어하기"
		btn_cont.position = Vector2(810, 500)
		btn_cont.size = Vector2(300, 60)
		btn_cont.add_theme_font_size_override("font_size", 24)
		btn_cont.pressed.connect(_on_continue)
		add_child(btn_cont)

func _on_new_game() -> void:
	SaveManager.clear_save()
	GameManager.start_run()
	get_tree().change_scene_to_file("res://scenes/map/map_scene.tscn")

func _on_continue() -> void:
	SaveManager.load_save()
	get_tree().change_scene_to_file("res://scenes/map/map_scene.tscn")
```

- [ ] **Step 3: main_menu_scene.tscn 생성**

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scenes/main_menu/main_menu_scene.gd" id="1"]

[node name="MainMenuScene" type="Node2D"]
script = ExtResource("1")
```

- [ ] **Step 4: 커밋**

```bash
cd H:/AIRelatedDefaultPath/ClaudeCode_Base/GameProjects/CardGameProject/stsl
git add scenes/main_menu/
git commit -m "feat: MainMenuScene 생성 — 새 게임/이어하기 분기"
```

---

### Task 3: GameOverScene 생성

**Files:**
- Create: `scenes/game_over/game_over_scene.gd`
- Create: `scenes/game_over/game_over_scene.tscn`

- [ ] **Step 1: 폴더 생성 확인**

```bash
mkdir -p "H:/AIRelatedDefaultPath/ClaudeCode_Base/GameProjects/CardGameProject/stsl/scenes/game_over"
```

- [ ] **Step 2: game_over_scene.gd 생성**

```gdscript
# scenes/game_over/game_over_scene.gd
extends Node2D

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	var is_win: bool = GameManager.run_won

	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.05, 0.02) if is_win else Color(0.05, 0.02, 0.02)
	bg.position = Vector2.ZERO
	bg.size = Vector2(1920, 1080)
	add_child(bg)

	var title := Label.new()
	title.text = "승리!" if is_win else "패배"
	title.position = Vector2(660, 200)
	title.size = Vector2(600, 120)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 72)
	title.modulate = Color(1.0, 0.9, 0.3) if is_win else Color(0.9, 0.3, 0.3)
	add_child(title)

	var info := Label.new()
	info.text = "도달 층: %d / 9\n보유 골드: %d" % [GameManager.current_floor, GameManager.gold]
	info.position = Vector2(660, 380)
	info.size = Vector2(600, 80)
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.add_theme_font_size_override("font_size", 28)
	add_child(info)

	var btn := Button.new()
	btn.text = "메인 메뉴로"
	btn.position = Vector2(810, 520)
	btn.size = Vector2(300, 60)
	btn.add_theme_font_size_override("font_size", 24)
	btn.pressed.connect(_on_main_menu)
	add_child(btn)

func _on_main_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu/main_menu_scene.tscn")
```

- [ ] **Step 3: game_over_scene.tscn 생성**

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scenes/game_over/game_over_scene.gd" id="1"]

[node name="GameOverScene" type="Node2D"]
script = ExtResource("1")
```

- [ ] **Step 4: 커밋**

```bash
cd H:/AIRelatedDefaultPath/ClaudeCode_Base/GameProjects/CardGameProject/stsl
git add scenes/game_over/
git commit -m "feat: GameOverScene 생성 — 승리/패배 결과 + 메인 메뉴 복귀"
```

---

### Task 4: project.godot 메인 씬 변경

**Files:**
- Modify: `project.godot:16`

- [ ] **Step 1: main_scene 경로 수정**

`project.godot` line 16:
```
config/run/main_scene="res://scenes/main_menu/main_menu_scene.tscn"
```

- [ ] **Step 2: 커밋**

```bash
cd H:/AIRelatedDefaultPath/ClaudeCode_Base/GameProjects/CardGameProject/stsl
git add project.godot
git commit -m "feat: 프로젝트 시작 씬을 main_menu_scene으로 변경"
```

---

### Task 5: MapScene continue dialog 제거

**Files:**
- Modify: `scenes/map/map_scene.gd:16-44`

- [ ] **Step 1: _ready() 단순화 및 dialog 메서드 제거**

`_ready()` 함수를 다음으로 교체:
```gdscript
func _ready() -> void:
	_build_ui()
	_refresh_map()
```

`_show_continue_dialog()`, `_on_continue_confirmed()`, `_on_new_run()` 세 함수 전부 삭제.

- [ ] **Step 2: 테스트 통과 확인**

```bash
"C:/Users/k9102/AppData/Local/Programs/Godot_v4.6-dev6_win64/Godot_v4.6-dev6_win64.exe" \
  --headless -s tests/test_runner.gd \
  --path "H:/AIRelatedDefaultPath/ClaudeCode_Base/GameProjects/CardGameProject/stsl" 2>&1 | tail -30
```

Expected: 전체 PASS (305개 이상)

- [ ] **Step 3: 커밋**

```bash
cd H:/AIRelatedDefaultPath/ClaudeCode_Base/GameProjects/CardGameProject/stsl
git add scenes/map/map_scene.gd
git commit -m "refactor: MapScene에서 continue dialog 제거 — 메인 메뉴로 이전"
```

---

## Self-Review

**Spec coverage:**
- [x] 메인 메뉴 씬 생성 (Task 2)
- [x] 새 게임/이어하기 분기 (Task 2)
- [x] 게임오버 씬 생성 (Task 3)
- [x] 승리/패배 표시 (Task 3)
- [x] 도달 층, 골드 표시 (Task 3)
- [x] 메인 메뉴로 복귀 버튼 (Task 3)
- [x] GameManager GAME_OVER 상태 (Task 1)
- [x] 전투 패배 → 게임오버 (Task 1)
- [x] 보스 처치 완료 → 게임오버 (Task 1)
- [x] project.godot 시작 씬 변경 (Task 4)
- [x] MapScene continue dialog 제거 (Task 5)
- [x] 테스트 추가 (Task 1)

**Type consistency:**
- `GameManager.run_won: bool` — Task 1에서 정의, Task 3에서 `GameManager.run_won` 읽기 ✓
- `GameState.GAME_OVER == 6` — Task 1 테스트에서 `== 6` 확인 ✓
- `complete_card_pick()` 보스 처치 블록: `card_rewards.clear()` + `return` 추가하여 중복 실행 방지 ✓
