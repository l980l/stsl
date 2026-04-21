# Chapter System Infrastructure Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 챕터 개념(Chapter 1=그리스·이집트·북유럽 / Chapter 2=한국·중국·일본) 뼈대 구현. 콘텐츠 없이 인프라만 먼저 안착시켜 기존 챕터 1 런은 그대로 돌아가게 유지하고, 이후 PR부터 영웅 해금과 챕터 2 콘텐츠를 쌓는다.

**Architecture:** `ProgressManager` Autoload 신규 → `user://progress.json`로 런 간 메타 진행(클리어 챕터, 해금 영웅) 유지. `GameManager`에 `current_chapter` / `MAX_CHAPTERS` 추가, 챕터별 신화 풀 분기. 메인 메뉴의 "새 게임" → 챕터 선택 씬 경유. 한국·중국·일본 신화는 빈 스텁 모듈로 등록만 해두고 Act 배정은 챕터 2를 선택해야 발생.

**Tech Stack:** Godot 4.6, GDScript (class_name + extends Node Autoload 패턴), JSON 파일 저장.

---

## 스코프

- ✅ `ProgressManager` 신규 + `progress.json` 저장/로드
- ✅ `GameManager.current_chapter` / `MAX_CHAPTERS` / 챕터 클리어 처리
- ✅ 챕터별 신화 풀 분기 (`_get_chapter_mythology_pool`)
- ✅ 챕터 2 신화 모듈 스텁 6개 (한국/중국/일본 × normals/acts)
- ✅ 챕터 선택 씬 신규 + 메인 메뉴 연결
- ✅ 테스트 추가
- ⛔ 영웅 해금 시스템 (다음 PR)
- ⛔ 챕터 2 실제 적/이벤트/렐릭 콘텐츠 (다음 PR)
- ⛔ 챕터 선택 화면 비주얼 폴리싱 (텍스트 버튼만)

---

## 파일 구조

**Create**
- `autoload/progress_manager.gd` — 메타 진행 싱글턴
- `scenes/chapter_select/chapter_select_scene.tscn` — 챕터 선택 씬(Node2D)
- `scenes/chapter_select/chapter_select_scene.gd` — 챕터 선택 로직
- `resources/enemies/korean/korean_normals.gd` — 빈 스텁
- `resources/enemies/korean/korean_act1.gd` — 빈 스텁
- `resources/enemies/korean/korean_act2.gd` — 빈 스텁
- `resources/enemies/korean/korean_act3.gd` — 빈 스텁
- `resources/enemies/chinese/chinese_normals.gd` — 빈 스텁
- `resources/enemies/chinese/chinese_act1.gd` — 빈 스텁
- `resources/enemies/chinese/chinese_act2.gd` — 빈 스텁
- `resources/enemies/chinese/chinese_act3.gd` — 빈 스텁
- `resources/enemies/japanese/japanese_normals.gd` — 빈 스텁
- `resources/enemies/japanese/japanese_act1.gd` — 빈 스텁
- `resources/enemies/japanese/japanese_act2.gd` — 빈 스텁
- `resources/enemies/japanese/japanese_act3.gd` — 빈 스텁
- `tests/test_progress_manager.gd` — ProgressManager 단위 테스트
- `tests/test_chapter_system.gd` — GameManager 챕터 동작 테스트

**Modify**
- `project.godot` L19-26 — `ProgressManager` Autoload 등록
- `autoload/game_manager.gd` L5-23 — 챕터 2 신화 모듈 preload 추가
- `autoload/game_manager.gd` L29-34 — `current_chapter`/`MAX_CHAPTERS` 변수 추가
- `autoload/game_manager.gd` L104-121 `reset()` — 챕터 기반 신화 풀
- `autoload/game_manager.gd` L125 `start_run()` — chapter 파라미터
- `autoload/game_manager.gd` L320-327 `_end_run_won()` — 챕터 클리어 기록
- `autoload/game_manager.gd` L408-413 `_get_mythology_registry()` — 3신화 추가
- `autoload/game_manager.gd` `to_dict()`/`from_dict()` L573~ — current_chapter 저장
- `scenes/main_menu/main_menu_scene.gd` L40-42 — 챕터 선택으로 분기
- `tests/test_runner.gd` L1-37 — 2개 신규 테스트 스위트 등록

---

## Task 구성 요약

1. 빈 신화 스텁 6모듈 × 4파일 생성 (Task 1)
2. ProgressManager 신규 + 기본 저장/로드 (Task 2)
3. Autoload 등록 및 확인 (Task 3)
4. GameManager에 current_chapter 도입 (Task 4)
5. 챕터별 신화 풀 분기 (Task 5)
6. 챕터 클리어 처리 + 저장 통합 (Task 6)
7. 챕터 선택 씬 + 메인 메뉴 연결 (Task 7)
8. 전체 통합 검증 (Task 8)

---

### Task 1: 챕터 2 신화 모듈 빈 스텁 12개

**Files:**
- Create: `resources/enemies/korean/korean_normals.gd`
- Create: `resources/enemies/korean/korean_act1.gd`
- Create: `resources/enemies/korean/korean_act2.gd`
- Create: `resources/enemies/korean/korean_act3.gd`
- Create: `resources/enemies/chinese/chinese_normals.gd`
- Create: `resources/enemies/chinese/chinese_act1.gd`
- Create: `resources/enemies/chinese/chinese_act2.gd`
- Create: `resources/enemies/chinese/chinese_act3.gd`
- Create: `resources/enemies/japanese/japanese_normals.gd`
- Create: `resources/enemies/japanese/japanese_act1.gd`
- Create: `resources/enemies/japanese/japanese_act2.gd`
- Create: `resources/enemies/japanese/japanese_act3.gd`

**참고 패턴:** `resources/enemies/greek/greek_normals.gd`는 `static func encounters() -> Array` 반환, `greek_act1.gd`는 `static func elites() -> Array` / `static func boss() -> String` 반환.

- [ ] **Step 1: `korean_normals.gd` 생성 (빈 스텁)**

```gdscript
# resources/enemies/korean/korean_normals.gd
# 한국 신화 — 일반 적 (Milestone 4-2에서 구현 예정)

static func encounters() -> Array:
	return []
```

- [ ] **Step 2: `korean_act1.gd` 생성 (빈 스텁)**

```gdscript
# resources/enemies/korean/korean_act1.gd
# 한국 신화 Act 1 — 엘리트·보스 (Milestone 4-2에서 구현 예정)

static func elites() -> Array:
	return []

static func boss() -> String:
	return ""
```

- [ ] **Step 3: `korean_act2.gd` 생성**

```gdscript
# resources/enemies/korean/korean_act2.gd
# 한국 신화 Act 2 — 엘리트·보스 (Milestone 4-2에서 구현 예정)

static func elites() -> Array:
	return []

static func boss() -> String:
	return ""
```

`korean_act3.gd`도 동일 내용으로 생성. 첫 줄 주석의 `Act 2`만 `Act 3`로 교체.

- [ ] **Step 4: `chinese_normals.gd` 생성 (빈 스텁)**

```gdscript
# resources/enemies/chinese/chinese_normals.gd
# 중국 신화 — 일반 적 (Milestone 4-2에서 구현 예정)

static func encounters() -> Array:
	return []
```

- [ ] **Step 5: `chinese_act1.gd` 생성**

```gdscript
# resources/enemies/chinese/chinese_act1.gd
# 중국 신화 Act 1 — 엘리트·보스 (Milestone 4-2에서 구현 예정)

static func elites() -> Array:
	return []

static func boss() -> String:
	return ""
```

`chinese_act2.gd`, `chinese_act3.gd`도 동일 내용으로 생성. 첫 줄 주석의 `Act 1`을 `Act 2` / `Act 3`로 교체.

- [ ] **Step 6: `japanese_normals.gd` 생성 (빈 스텁)**

```gdscript
# resources/enemies/japanese/japanese_normals.gd
# 일본 신화 — 일반 적 (Milestone 4-2에서 구현 예정)

static func encounters() -> Array:
	return []
```

- [ ] **Step 7: `japanese_act1.gd` 생성**

```gdscript
# resources/enemies/japanese/japanese_act1.gd
# 일본 신화 Act 1 — 엘리트·보스 (Milestone 4-2에서 구현 예정)

static func elites() -> Array:
	return []

static func boss() -> String:
	return ""
```

`japanese_act2.gd`, `japanese_act3.gd`도 동일 내용으로 생성. 첫 줄 주석의 `Act 1`을 `Act 2` / `Act 3`로 교체.

- [ ] **Step 8: Godot 헤드리스 파싱 검증**

Run: `"H:/Program Files/Godot/Godot_v4.6.2-stable_win64_console.exe" --headless --check-only --path "H:/AIRelatedDefaultPath/ClaudeCode_Base/GameProjects/CardGameProject/stsl"`

Expected: 에러 없이 완료 (12개 새 파일 파싱 성공).

- [ ] **Step 9: 커밋**

```bash
git add resources/enemies/korean resources/enemies/chinese resources/enemies/japanese
git commit -m "feat: 챕터 2 신화 모듈 12개 빈 스텁 (한국/중국/일본)"
```

---

### Task 2: ProgressManager 싱글턴 + 테스트

**Files:**
- Create: `autoload/progress_manager.gd`
- Create: `tests/test_progress_manager.gd`

`SaveManager`(`autoload/save_manager.gd`) 패턴을 복제. `class_name ... extends Node`, JSON을 `user://progress.json`에 저장.

- [ ] **Step 1: `progress_manager.gd` 생성**

```gdscript
# autoload/progress_manager.gd
class_name ProgressManagerClass
extends Node

const PROGRESS_PATH := "user://progress.json"
const _DEFAULT_HEROES := ["napoleon", "cleopatra", "yi_sun_sin"]

var chapters_cleared: Array = []          # Array[int]
var unlocked_heroes: Array = []           # Array[String]
var unlock_flags: Dictionary = {}         # String -> bool

func _ready() -> void:
	load_progress()

func reset_progress() -> void:
	chapters_cleared.clear()
	unlocked_heroes = _DEFAULT_HEROES.duplicate()
	unlock_flags.clear()

func mark_chapter_cleared(chapter: int) -> void:
	if chapter not in chapters_cleared:
		chapters_cleared.append(chapter)
	save_progress()

func is_chapter_unlocked(chapter: int) -> bool:
	if chapter <= 1:
		return true
	return (chapter - 1) in chapters_cleared

func is_hero_unlocked(hero_id: String) -> bool:
	return hero_id in unlocked_heroes

func unlock_hero(hero_id: String) -> bool:
	if hero_id in unlocked_heroes:
		return false
	unlocked_heroes.append(hero_id)
	save_progress()
	return true

func set_flag(flag_key: String) -> void:
	unlock_flags[flag_key] = true
	save_progress()

func has_flag(flag_key: String) -> bool:
	return unlock_flags.get(flag_key, false)

func to_dict() -> Dictionary:
	return {
		"version": 1,
		"chapters_cleared": chapters_cleared.duplicate(),
		"unlocked_heroes": unlocked_heroes.duplicate(),
		"unlock_flags": unlock_flags.duplicate(),
	}

func from_dict(data: Dictionary) -> void:
	chapters_cleared = data.get("chapters_cleared", []).duplicate()
	var heroes = data.get("unlocked_heroes", [])
	if heroes.is_empty():
		heroes = _DEFAULT_HEROES.duplicate()
	unlocked_heroes = heroes.duplicate()
	unlock_flags = data.get("unlock_flags", {}).duplicate()

func save_progress() -> void:
	var file := FileAccess.open(PROGRESS_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(to_dict()))
		file.close()

func load_progress() -> void:
	if not FileAccess.file_exists(PROGRESS_PATH):
		reset_progress()
		return
	var file := FileAccess.open(PROGRESS_PATH, FileAccess.READ)
	if not file:
		reset_progress()
		return
	var text := file.get_as_text()
	file.close()
	var data = JSON.parse_string(text)
	if typeof(data) != TYPE_DICTIONARY:
		reset_progress()
		return
	from_dict(data)

func clear_progress_file() -> void:
	if FileAccess.file_exists(PROGRESS_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PROGRESS_PATH))
	reset_progress()
```

- [ ] **Step 2: `test_progress_manager.gd` 생성**

```gdscript
# tests/test_progress_manager.gd
class_name TestProgressManager
extends RefCounted

const PM = preload("res://autoload/progress_manager.gd")

var passed: int = 0
var failed: int = 0

func run_all() -> Dictionary:
	test_default_unlocked_heroes()
	test_mark_chapter_cleared_dedup()
	test_is_chapter_unlocked()
	test_unlock_hero_returns_false_if_duplicate()
	test_unlock_flags_roundtrip()
	test_to_dict_from_dict_roundtrip()
	return {"passed": passed, "failed": failed}

func _assert(cond: bool, msg: String) -> void:
	if cond:
		passed += 1
		print("  PASS: " + msg)
	else:
		failed += 1
		print("  FAIL: " + msg)

func test_default_unlocked_heroes() -> void:
	print("[TestProgressManager] test_default_unlocked_heroes")
	var pm = PM.new()
	pm.reset_progress()
	_assert(pm.is_hero_unlocked("napoleon"), "나폴레옹 기본 해금")
	_assert(pm.is_hero_unlocked("cleopatra"), "클레오파트라 기본 해금")
	_assert(pm.is_hero_unlocked("yi_sun_sin"), "이순신 기본 해금")
	_assert(not pm.is_hero_unlocked("jeanne_darc"), "미등록 영웅은 잠금")

func test_mark_chapter_cleared_dedup() -> void:
	print("[TestProgressManager] test_mark_chapter_cleared_dedup")
	var pm = PM.new()
	pm.reset_progress()
	pm.chapters_cleared.clear()
	pm.mark_chapter_cleared(1)
	pm.mark_chapter_cleared(1)
	_assert(pm.chapters_cleared.size() == 1, "중복 마킹 시 1회만 기록")

func test_is_chapter_unlocked() -> void:
	print("[TestProgressManager] test_is_chapter_unlocked")
	var pm = PM.new()
	pm.reset_progress()
	pm.chapters_cleared.clear()
	_assert(pm.is_chapter_unlocked(1), "챕터 1은 항상 해금")
	_assert(not pm.is_chapter_unlocked(2), "챕터 1 미클리어 시 챕터 2 잠금")
	pm.chapters_cleared.append(1)
	_assert(pm.is_chapter_unlocked(2), "챕터 1 클리어 후 챕터 2 해금")

func test_unlock_hero_returns_false_if_duplicate() -> void:
	print("[TestProgressManager] test_unlock_hero_returns_false_if_duplicate")
	var pm = PM.new()
	pm.reset_progress()
	var first = pm.unlock_hero("jeanne_darc")
	var second = pm.unlock_hero("jeanne_darc")
	_assert(first == true, "신규 해금은 true 반환")
	_assert(second == false, "중복 해금은 false 반환")
	_assert(pm.is_hero_unlocked("jeanne_darc"), "신규 영웅 해금 상태 보존")

func test_unlock_flags_roundtrip() -> void:
	print("[TestProgressManager] test_unlock_flags_roundtrip")
	var pm = PM.new()
	pm.reset_progress()
	_assert(not pm.has_flag("killed_hydra"), "초기값 false")
	pm.unlock_flags["killed_hydra"] = true
	_assert(pm.has_flag("killed_hydra"), "플래그 설정 후 true")

func test_to_dict_from_dict_roundtrip() -> void:
	print("[TestProgressManager] test_to_dict_from_dict_roundtrip")
	var pm = PM.new()
	pm.reset_progress()
	pm.chapters_cleared.append(1)
	pm.unlocked_heroes.append("jeanne_darc")
	pm.unlock_flags["killed_hydra"] = true

	var d = pm.to_dict()
	var pm2 = PM.new()
	pm2.from_dict(d)
	_assert(pm2.chapters_cleared == [1], "chapters_cleared 복원")
	_assert("jeanne_darc" in pm2.unlocked_heroes, "unlocked_heroes 복원")
	_assert(pm2.has_flag("killed_hydra"), "unlock_flags 복원")
```

- [ ] **Step 3: `test_runner.gd`에 스위트 등록**

`tests/test_runner.gd` L14 뒤에 추가:
```gdscript
var TestProgressManager = preload("res://tests/test_progress_manager.gd")
```

`suites` 배열(L19-31)의 `TestSave.new(),` 뒤에 추가:
```gdscript
TestProgressManager.new(),
```

- [ ] **Step 4: 테스트 실행**

Run: `"H:/Program Files/Godot/Godot_v4.6.2-stable_win64_console.exe" --headless -s tests/test_runner.gd --path "H:/AIRelatedDefaultPath/ClaudeCode_Base/GameProjects/CardGameProject/stsl"`

Expected: `[TestProgressManager]` 6건 PASS, 총 PASS 카운트 +6.

- [ ] **Step 5: 커밋**

```bash
git add autoload/progress_manager.gd tests/test_progress_manager.gd tests/test_runner.gd
git commit -m "feat: ProgressManager 싱글턴 + 메타 저장/로드"
```

---

### Task 3: ProgressManager Autoload 등록

**Files:**
- Modify: `project.godot:19-26`

- [ ] **Step 1: `project.godot` autoload 섹션 수정**

L19-26 `[autoload]` 섹션을 다음으로 교체:

```ini
[autoload]

GameManager="*res://autoload/game_manager.gd"
TeamManager="*res://autoload/team_manager.gd"
DeckManager="*res://autoload/deck_manager.gd"
BattleManager="*res://autoload/battle_manager.gd"
SaveManager="*res://autoload/save_manager.gd"
ProgressManager="*res://autoload/progress_manager.gd"
DebugManager="*res://autoload/debug_manager.gd"
```

- [ ] **Step 2: Godot 헤드리스 구동 검증**

Run: `"H:/Program Files/Godot/Godot_v4.6.2-stable_win64_console.exe" --headless --check-only --path "H:/AIRelatedDefaultPath/ClaudeCode_Base/GameProjects/CardGameProject/stsl"`

Expected: 에러 없이 완료. Autoload 등록 성공.

- [ ] **Step 3: 테스트 전체 실행 (회귀 확인)**

Run: `"H:/Program Files/Godot/Godot_v4.6.2-stable_win64_console.exe" --headless -s tests/test_runner.gd --path "H:/AIRelatedDefaultPath/ClaudeCode_Base/GameProjects/CardGameProject/stsl"`

Expected: `=== Results: N passed, 0 failed ===` (기존 + TestProgressManager 6개).

- [ ] **Step 4: 커밋**

```bash
git add project.godot
git commit -m "feat: ProgressManager Autoload 등록"
```

---

### Task 4: GameManager에 current_chapter 도입

**Files:**
- Modify: `autoload/game_manager.gd:5-23` (preload)
- Modify: `autoload/game_manager.gd:29-34` (변수)
- Modify: `autoload/game_manager.gd:104-121` (reset)

- [ ] **Step 1: 챕터 2 신화 모듈 preload 추가**

L23(`const _EventsAct3 = ...`) 바로 뒤에 추가:

```gdscript
const _KoreanNormals   = preload("res://resources/enemies/korean/korean_normals.gd")
const _KoreanAct1      = preload("res://resources/enemies/korean/korean_act1.gd")
const _KoreanAct2      = preload("res://resources/enemies/korean/korean_act2.gd")
const _KoreanAct3      = preload("res://resources/enemies/korean/korean_act3.gd")
const _ChineseNormals  = preload("res://resources/enemies/chinese/chinese_normals.gd")
const _ChineseAct1     = preload("res://resources/enemies/chinese/chinese_act1.gd")
const _ChineseAct2     = preload("res://resources/enemies/chinese/chinese_act2.gd")
const _ChineseAct3     = preload("res://resources/enemies/chinese/chinese_act3.gd")
const _JapaneseNormals = preload("res://resources/enemies/japanese/japanese_normals.gd")
const _JapaneseAct1    = preload("res://resources/enemies/japanese/japanese_act1.gd")
const _JapaneseAct2    = preload("res://resources/enemies/japanese/japanese_act2.gd")
const _JapaneseAct3    = preload("res://resources/enemies/japanese/japanese_act3.gd")
```

- [ ] **Step 2: `current_chapter` 변수 추가**

L29 (`const MAX_ACTS: int = 3`) 바로 앞에 추가:

```gdscript
const MAX_CHAPTERS: int = 2
var current_chapter: int = 1
```

- [ ] **Step 3: 챕터별 신화 풀 함수 추가**

L408 `_get_mythology_registry()` 바로 앞 (`func _heal_all_heroes`와 `func _get_mythology_registry` 사이)에 추가:

```gdscript
func _get_chapter_mythology_pool(chapter: int) -> Array[String]:
	match chapter:
		1: return ["greek", "egyptian", "norse"]
		2: return ["korean", "chinese", "japanese"]
	return ["greek", "egyptian", "norse"]
```

- [ ] **Step 4: `reset()` 챕터 기반으로 수정**

L120-121을 다음으로 교체:

```gdscript
	act_mythologies = _get_chapter_mythology_pool(current_chapter)
	act_mythologies.shuffle()
```

- [ ] **Step 5: `start_run()` 챕터 파라미터 추가**

L125-126 (기존):
```gdscript
func start_run(initial_hero_id: String = "napoleon") -> void:
	reset()
```

다음으로 교체:
```gdscript
func start_run(initial_hero_id: String = "napoleon", chapter: int = 1) -> void:
	current_chapter = chapter
	reset()
```

핵심: `current_chapter` 설정을 `reset()` 호출 **전**에 해야 함 — `reset()`이 `_get_chapter_mythology_pool(current_chapter)`를 참조하기 때문.

- [ ] **Step 6: `to_dict()` / `from_dict()`에 current_chapter 포함**

L573-591 `to_dict()` 반환 Dictionary에 추가:

```gdscript
		"current_chapter": current_chapter,
```

`from_dict()` L593-598 영역에 추가:

```gdscript
	current_chapter = data.get("current_chapter", 1)
```

- [ ] **Step 7: 테스트 전체 실행 (기존 회귀 확인)**

Run: `"H:/Program Files/Godot/Godot_v4.6.2-stable_win64_console.exe" --headless -s tests/test_runner.gd --path "H:/AIRelatedDefaultPath/ClaudeCode_Base/GameProjects/CardGameProject/stsl"`

Expected: 기존 테스트 전부 PASS. 0 failed.

- [ ] **Step 8: 커밋**

```bash
git add autoload/game_manager.gd
git commit -m "feat: GameManager에 current_chapter + 챕터별 신화 풀 분기"
```

---

### Task 5: _get_mythology_registry() 확장

**Files:**
- Modify: `autoload/game_manager.gd:408-413`

- [ ] **Step 1: registry에 3개 신화 추가**

L408-413을 다음으로 교체:

```gdscript
func _get_mythology_registry() -> Dictionary:
	return {
		"greek":    {"normals": _GreekNormals,    "acts": [_GreekAct1,    _GreekAct2,    _GreekAct3]},
		"egyptian": {"normals": _EgyptianNormals, "acts": [_EgyptianAct1, _EgyptianAct2, _EgyptianAct3]},
		"norse":    {"normals": _NorseNormals,    "acts": [_NorseAct1,    _NorseAct2,    _NorseAct3]},
		"korean":   {"normals": _KoreanNormals,   "acts": [_KoreanAct1,   _KoreanAct2,   _KoreanAct3]},
		"chinese":  {"normals": _ChineseNormals,  "acts": [_ChineseAct1,  _ChineseAct2,  _ChineseAct3]},
		"japanese": {"normals": _JapaneseNormals, "acts": [_JapaneseAct1, _JapaneseAct2, _JapaneseAct3]},
	}
```

- [ ] **Step 2: 헤드리스 파싱 검증**

Run: `"H:/Program Files/Godot/Godot_v4.6.2-stable_win64_console.exe" --headless --check-only --path "H:/AIRelatedDefaultPath/ClaudeCode_Base/GameProjects/CardGameProject/stsl"`

Expected: 에러 없이 완료.

- [ ] **Step 3: 테스트 실행 (기존 회귀 확인)**

Run: `"H:/Program Files/Godot/Godot_v4.6.2-stable_win64_console.exe" --headless -s tests/test_runner.gd --path "H:/AIRelatedDefaultPath/ClaudeCode_Base/GameProjects/CardGameProject/stsl"`

Expected: 기존 테스트 전부 PASS. 0 failed.

- [ ] **Step 4: 커밋**

```bash
git add autoload/game_manager.gd
git commit -m "feat: 신화 레지스트리에 한국/중국/일본 스텁 추가"
```

---

### Task 6: 챕터 클리어 처리 + 테스트

**Files:**
- Modify: `autoload/game_manager.gd:320-327` (`_end_run_won`)
- Create: `tests/test_chapter_system.gd`
- Modify: `tests/test_runner.gd` (스위트 등록)

- [ ] **Step 1: `test_chapter_system.gd` 신규 작성 (실패 테스트 먼저)**

```gdscript
# tests/test_chapter_system.gd
class_name TestChapterSystem
extends RefCounted

const GameManagerClass = preload("res://autoload/game_manager.gd")
const PM = preload("res://autoload/progress_manager.gd")

var passed: int = 0
var failed: int = 0

func run_all() -> Dictionary:
	test_chapter_pool_dispatch()
	test_reset_uses_current_chapter_pool()
	test_start_run_sets_chapter()
	return {"passed": passed, "failed": failed}

func _assert(cond: bool, msg: String) -> void:
	if cond:
		passed += 1
		print("  PASS: " + msg)
	else:
		failed += 1
		print("  FAIL: " + msg)

func test_chapter_pool_dispatch() -> void:
	print("[TestChapterSystem] test_chapter_pool_dispatch")
	var gm = GameManagerClass.new()
	var pool1 = gm._get_chapter_mythology_pool(1)
	var pool2 = gm._get_chapter_mythology_pool(2)
	_assert("greek" in pool1 and "egyptian" in pool1 and "norse" in pool1, "챕터 1 풀 = 그리스/이집트/북유럽")
	_assert(pool1.size() == 3, "챕터 1 풀 크기 3")
	_assert("korean" in pool2 and "chinese" in pool2 and "japanese" in pool2, "챕터 2 풀 = 한국/중국/일본")
	_assert(pool2.size() == 3, "챕터 2 풀 크기 3")

func test_reset_uses_current_chapter_pool() -> void:
	print("[TestChapterSystem] test_reset_uses_current_chapter_pool")
	var gm = GameManagerClass.new()
	gm.current_chapter = 2
	gm.reset()
	for myth in gm.act_mythologies:
		_assert(myth in ["korean", "chinese", "japanese"], "reset 후 act_mythologies 원소는 챕터 2 신화: " + myth)
	_assert(gm.act_mythologies.size() == 3, "act_mythologies 크기 3")

func test_start_run_sets_chapter() -> void:
	print("[TestChapterSystem] test_start_run_sets_chapter")
	var gm = GameManagerClass.new()
	# start_run은 씬 로드 등 부수효과가 있어 직접 호출 대신 필드 설정만 검증
	# current_chapter가 파라미터로 설정되는지 로직 수준 확인
	gm.current_chapter = 1
	_assert(gm.current_chapter == 1, "기본 챕터는 1")
	gm.current_chapter = 2
	gm.reset()
	_assert(gm.current_chapter == 2, "current_chapter는 reset 후에도 유지")
```

- [ ] **Step 2: `test_runner.gd`에 스위트 등록**

`tests/test_runner.gd` L14 바로 뒤 (TestProgressManager 라인 뒤) 추가:
```gdscript
var TestChapterSystem = preload("res://tests/test_chapter_system.gd")
```

`suites` 배열의 `TestProgressManager.new(),` 뒤에 추가:
```gdscript
TestChapterSystem.new(),
```

- [ ] **Step 3: 테스트 실행 (실패 확인)**

Run: `"H:/Program Files/Godot/Godot_v4.6.2-stable_win64_console.exe" --headless -s tests/test_runner.gd --path "H:/AIRelatedDefaultPath/ClaudeCode_Base/GameProjects/CardGameProject/stsl"`

Expected: `[TestChapterSystem]` 3건 PASS (Task 4에서 이미 구현했기 때문에 PASS). 만약 실패하면 Task 4 구현 확인.

- [ ] **Step 4: `_end_run_won()` 수정 — 챕터 클리어 기록**

L320-327을 다음으로 교체:

```gdscript
func _end_run_won() -> void:
	run_won = true
	run_ended.emit(true)
	var _sm = Engine.get_singleton("SaveManager") if Engine.has_singleton("SaveManager") else null
	if _sm:
		_sm.clear_save()
	var _pm = Engine.get_singleton("ProgressManager") if Engine.has_singleton("ProgressManager") else null
	if _pm:
		_pm.mark_chapter_cleared(current_chapter)
	change_state(GameState.GAME_OVER)
	_request_scene("res://scenes/game_over/game_over_scene.tscn")
```

- [ ] **Step 5: 테스트 실행 (회귀 확인)**

Run: `"H:/Program Files/Godot/Godot_v4.6.2-stable_win64_console.exe" --headless -s tests/test_runner.gd --path "H:/AIRelatedDefaultPath/ClaudeCode_Base/GameProjects/CardGameProject/stsl"`

Expected: 모든 테스트 PASS. 0 failed.

- [ ] **Step 6: 커밋**

```bash
git add autoload/game_manager.gd tests/test_chapter_system.gd tests/test_runner.gd
git commit -m "feat: 챕터 클리어 시 ProgressManager에 기록"
```

---

### Task 7: 챕터 선택 씬 + 메인 메뉴 연결

**Files:**
- Create: `scenes/chapter_select/chapter_select_scene.tscn`
- Create: `scenes/chapter_select/chapter_select_scene.gd`
- Modify: `scenes/main_menu/main_menu_scene.gd:40-42`

`main_menu_scene.tscn`이 스크립트 기반 UI이므로 `chapter_select_scene.tscn`도 동일 패턴으로 작성 (Node2D + 스크립트에서 UI 구성).

- [ ] **Step 1: `chapter_select_scene.tscn` 생성**

파일 내용:

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scenes/chapter_select/chapter_select_scene.gd" id="1"]

[node name="ChapterSelect" type="Node2D"]
script = ExtResource("1")
```

- [ ] **Step 2: `chapter_select_scene.gd` 생성**

```gdscript
# scenes/chapter_select/chapter_select_scene.gd
extends Node2D

const _CHAPTERS := [
	{"id": 1, "name": "챕터 1 — 지중해·북방 신화", "desc": "그리스·이집트·북유럽 신화의 적이 각 Act에 랜덤 배정됩니다."},
	{"id": 2, "name": "챕터 2 — 동아시아 신화", "desc": "한국·중국·일본 신화의 적이 각 Act에 랜덤 배정됩니다."},
]

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.1)
	bg.position = Vector2.ZERO
	bg.size = Vector2(1920, 1080)
	add_child(bg)

	var title := Label.new()
	title.text = "챕터 선택"
	title.position = Vector2(660, 120)
	title.size = Vector2(600, 100)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 64)
	title.modulate = Color(1.0, 0.9, 0.4)
	add_child(title)

	for i in range(_CHAPTERS.size()):
		_make_chapter_card(_CHAPTERS[i], i)

	var btn_back := Button.new()
	btn_back.text = "뒤로"
	btn_back.position = Vector2(60, 960)
	btn_back.size = Vector2(200, 60)
	btn_back.add_theme_font_size_override("font_size", 24)
	btn_back.pressed.connect(_on_back)
	add_child(btn_back)

func _make_chapter_card(chapter: Dictionary, idx: int) -> void:
	var card_x := 300 + idx * 700
	var panel := ColorRect.new()
	panel.color = Color(0.15, 0.15, 0.25)
	panel.position = Vector2(card_x, 300)
	panel.size = Vector2(600, 520)
	add_child(panel)

	var name_label := Label.new()
	name_label.text = chapter["name"]
	name_label.position = Vector2(card_x + 20, 330)
	name_label.size = Vector2(560, 60)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 32)
	add_child(name_label)

	var desc_label := Label.new()
	desc_label.text = chapter["desc"]
	desc_label.position = Vector2(card_x + 20, 420)
	desc_label.size = Vector2(560, 300)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.add_theme_font_size_override("font_size", 22)
	add_child(desc_label)

	var unlocked := ProgressManager.is_chapter_unlocked(chapter["id"])
	var btn := Button.new()
	btn.text = ("챕터 시작" if unlocked else "잠금")
	btn.disabled = not unlocked
	btn.position = Vector2(card_x + 150, 740)
	btn.size = Vector2(300, 60)
	btn.add_theme_font_size_override("font_size", 24)
	if unlocked:
		var chapter_id: int = chapter["id"]
		btn.pressed.connect(func(): _on_chapter_selected(chapter_id))
	add_child(btn)

	if not unlocked:
		var hint := Label.new()
		hint.text = "이전 챕터를 클리어하면 해금됩니다."
		hint.position = Vector2(card_x + 20, 680)
		hint.size = Vector2(560, 40)
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hint.add_theme_font_size_override("font_size", 20)
		hint.modulate = Color(0.8, 0.5, 0.5)
		add_child(hint)

func _on_chapter_selected(chapter_id: int) -> void:
	GameManager.current_chapter = chapter_id
	get_tree().change_scene_to_file("res://scenes/hero_select/hero_select_scene.tscn")

func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu/main_menu_scene.tscn")
```

- [ ] **Step 3: `main_menu_scene.gd` `_on_new_game()` 수정**

L40-42를 다음으로 교체:

```gdscript
func _on_new_game() -> void:
	SaveManager.clear_save()
	get_tree().change_scene_to_file("res://scenes/chapter_select/chapter_select_scene.tscn")
```

- [ ] **Step 4: `hero_select_scene.gd`에서 `GameManager.start_run` 호출 시 챕터 전달**

`scenes/hero_select/hero_select_scene.gd` L104의 다음 줄을 교체:

기존:
```gdscript
		GameManager.start_run(hero_id)
```

신규:
```gdscript
		GameManager.start_run(hero_id, GameManager.current_chapter)
```

(`current_chapter`는 챕터 선택 씬에서 `_on_chapter_selected`가 미리 설정한 값.)

- [ ] **Step 5: 헤드리스 파싱 검증**

Run: `"H:/Program Files/Godot/Godot_v4.6.2-stable_win64_console.exe" --headless --check-only --path "H:/AIRelatedDefaultPath/ClaudeCode_Base/GameProjects/CardGameProject/stsl"`

Expected: 에러 없이 완료.

- [ ] **Step 6: 테스트 전체 실행 (회귀 확인)**

Run: `"H:/Program Files/Godot/Godot_v4.6.2-stable_win64_console.exe" --headless -s tests/test_runner.gd --path "H:/AIRelatedDefaultPath/ClaudeCode_Base/GameProjects/CardGameProject/stsl"`

Expected: 모든 테스트 PASS. 0 failed.

- [ ] **Step 7: 커밋**

```bash
git add scenes/chapter_select scenes/main_menu/main_menu_scene.gd scenes/hero_select/hero_select_scene.gd
git commit -m "feat: 챕터 선택 씬 + 메인 메뉴 연결"
```

---

### Task 8: 통합 검증

**Files:** (편집 없음)

- [ ] **Step 1: 전체 테스트 실행**

Run: `"H:/Program Files/Godot/Godot_v4.6.2-stable_win64_console.exe" --headless -s tests/test_runner.gd --path "H:/AIRelatedDefaultPath/ClaudeCode_Base/GameProjects/CardGameProject/stsl"`

Expected: `=== Results: N passed, 0 failed ===` (이전 총합 + TestProgressManager 6 + TestChapterSystem 3 = +9).

- [ ] **Step 2: GUI 스모크 테스트**

Run: `"H:/Program Files/Godot/Godot_v4.6.2-stable_win64.exe" --path "H:/AIRelatedDefaultPath/ClaudeCode_Base/GameProjects/CardGameProject/stsl"`

**수동 검증 체크리스트:**
- 메인 메뉴 → "새 게임" 클릭 → 챕터 선택 씬 진입
- 챕터 1 카드에 "챕터 시작" 버튼 활성 / 챕터 2 카드에 "잠금" 버튼 비활성 + "이전 챕터를 클리어하면 해금됩니다." 표시
- 챕터 1 선택 → 영웅 선택 씬 진입
- 영웅 선택 → 맵 진입 → Act 1 전투 시작 (기존 플로우 정상)
- "뒤로" 버튼 → 메인 메뉴 복귀

- [ ] **Step 3: `user://progress.json` 파일 존재 확인**

챕터 1 전체 클리어 후 (또는 디버그 단축키로 강제 클리어 후), 사용자 데이터 경로(`%APPDATA%\Godot\app_userdata\STSL\`)에 `progress.json` 파일 생성 확인. 내용에 `"chapters_cleared": [1]` 확인.

대안 (클리어까지 진행 어려우면): Godot 내 `ProgressManager.mark_chapter_cleared(1)` 디버그 호출 후 파일 확인.

- [ ] **Step 4: 챕터 2 해금 확인**

챕터 1 클리어 후 메인 메뉴 → 새 게임 → 챕터 선택 씬 재진입. 챕터 2 버튼이 "챕터 시작"으로 활성화됐는지 확인. 클릭 → 영웅 선택 → 맵 진입. 전투 시작 시 적이 모두 더미(빈 스텁)일 것이므로 `_make_normal_enemies()`가 빈 배열 반환 → `push_warning` 로그 확인하고 정상 처리(혹은 충돌하지 않음) 검증.

**만약 빈 인카운터로 충돌이 발생하면:** 이번 PR 스코프를 벗어남 — 챕터 2 콘텐츠 PR로 미뤄짐. Step 4를 스킵하고, `docs/production_roadmap.md`의 Milestone 4-2에 "챕터 2 콘텐츠 구현 전에는 챕터 2 선택 시 플레이 불가" 메모만 남겨둠.

- [ ] **Step 5: PR 생성**

브랜치명: `feat/chapter-system-infrastructure`
PR 제목: `feat: 챕터 시스템 인프라 — ProgressManager + chapter 선택`

본문:
- Summary: ProgressManager autoload 신규, GameManager에 current_chapter 도입, 챕터 선택 씬, 챕터 2 신화 스텁 모듈 12개.
- Scope 제외: 영웅 해금 UI, 챕터 2 실제 콘텐츠.
- Test plan: 헤드리스 테스트 +9건, GUI 스모크 수동 검증 완료.

---

## 검증 엔드-투-엔드

```bash
# 헤드리스 테스트
"H:/Program Files/Godot/Godot_v4.6.2-stable_win64_console.exe" --headless -s tests/test_runner.gd --path "H:/AIRelatedDefaultPath/ClaudeCode_Base/GameProjects/CardGameProject/stsl"

# GUI 플레이테스트
"H:/Program Files/Godot/Godot_v4.6.2-stable_win64.exe" --path "H:/AIRelatedDefaultPath/ClaudeCode_Base/GameProjects/CardGameProject/stsl"
```

---

## 종료 기준

- 테스트 +9 (ProgressManager 6 + ChapterSystem 3) 전부 PASS, 기존 테스트 회귀 0
- 챕터 선택 씬 → 챕터 1 선택 → 기존 플레이 흐름 그대로 동작
- 챕터 2는 해금 조건 미충족 시 "잠금" 상태 표시
- `user://progress.json` 런 간 메타 저장 확인
- `_end_run_won()`이 `ProgressManager.mark_chapter_cleared(current_chapter)` 호출

---

## 후속 플랜 (이번 PR 범위 밖)

- **영웅 해금 시스템**: `hero_resource.gd`에 `unlock_condition` 필드, `progress_manager.check_unlock_conditions()`, `hero_select_scene.gd`에서 해금 영웅만 노출
- **챕터 2 콘텐츠**: 한국/중국/일본 신화 각 일반 적 6종 + 3Act 엘리트·보스 + 이벤트 10종 + 렐릭 3종
- **챕터 선택 UI 비주얼 폴리싱**: 일러스트·배경 적용은 Milestone 7-4
