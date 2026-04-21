# 한국 신화 콘텐츠 구현 플랜

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 챕터 2 한국 신화 모듈(적 18종·이벤트 10종·렐릭 3종)을 구현하고 챕터 2가 실제로 플레이 가능하도록 한다.

**Architecture:** 빈 스텁인 `korean_normals.gd` / `korean_act1~3.gd` 4개 파일에 팩토리 함수를 채운다. 새 파일 `events_korean.gd`를 만들어 한국 이벤트 10종을 담고, `game_manager.gd`의 `_build_event_pool()`을 신화 기반 분기로 확장한다. `relics.gd`에 렐릭 3종을 추가하고, `_get_chapter_mythology_pool()`을 빈 스텁 자동 필터 방식으로 수정해 챕터 2가 한국 신화로 실행 가능하게 한다.

**Tech Stack:** GDScript 4.6, Godot headless test runner (`tests/test_runner.gd`)

---

## 파일 구조

| 파일 | 작업 |
|---|---|
| `resources/enemies/korean/korean_normals.gd` | 팩토리 6종 + `encounters()` 채우기 (스텁 → 구현) |
| `resources/enemies/korean/korean_act1.gd` | 엘리트 3 + 보스 해모수 |
| `resources/enemies/korean/korean_act2.gd` | 엘리트 3 + 보스 동명성왕 |
| `resources/enemies/korean/korean_act3.gd` | 엘리트 3 + 보스 염라대왕 |
| `resources/events/events_korean.gd` | NEW — 한국 이벤트 10종 |
| `resources/relics/relics.gd` | 한국 렐릭 3종 추가 + `build_pool()` 확장 |
| `autoload/game_manager.gd` | `_build_event_pool()` 신화 분기 + `_get_chapter_mythology_pool()` 스텁 필터 |
| `tests/test_enemies.gd` | 한국 shape 테스트 4개 추가 |
| `tests/test_event.gd` | 한국 이벤트 풀 테스트 추가 |
| `tests/test_relics.gd` | 풀 크기 25→28 + 한국 렐릭 존재 테스트 |
| `tests/test_chapter_system.gd` | 챕터 2 스텁 필터 테스트 추가 |

## 패턴 참고

- 적 팩토리 패턴: `resources/enemies/greek/greek_normals.gd`, `greek_act1.gd`
- 이벤트 패턴: `resources/events/events_act3.gd`
- 렐릭 패턴: `resources/relics/relics.gd` L166-184 (북유럽 렐릭 섹션)
- BUFF intent: `action_type = IntentRes.ActionType.BUFF; value = N; status_type = "strength"` (target 없음)
- DEBUFF intent: `action_type = IntentRes.ActionType.DEBUFF; value = N; status_type = "weak"; target = IntentRes.TargetType.RANDOM`
- LOWEST_HP 타겟: `IntentRes.TargetType.LOWEST_HP` (히드라 Phase 1에서 사용 중 — 존재 확인됨)

## 테스트 실행 커맨드

```bash
"H:/Program Files/Godot/Godot_v4.6.2-stable_win64_console.exe" --headless -s tests/test_runner.gd --path "H:/AIRelatedDefaultPath/ClaudeCode_Base/GameProjects/CardGameProject/stsl"
```
기대 출력: `=== Results: N passed, 0 failed ===`

---

## Task 1: 한국 일반 적 6종

**Files:**
- Modify: `resources/enemies/korean/korean_normals.gd`
- Modify: `tests/test_enemies.gd`

- [ ] **Step 1: 실패 테스트 작성 — `tests/test_enemies.gd`에 추가**

`test_enemies.gd` 파일 내에서 `run_all()` 호출 목록에 `test_korean_normals_shape()` 추가하고, 파일 끝에 다음 함수 추가:

```gdscript
func test_korean_normals_shape() -> void:
	print("[TestEnemies] test_korean_normals_shape")
	var M = load("res://resources/enemies/korean/korean_normals.gd")
	var scene = load("res://characters/summons/soldier/soldier.tscn")
	var encs := M.encounters()
	_assert(encs.size() >= 5, "한국 인카운터 5조합 이상")
	var e1 := M.death_reaper(scene)
	_assert(e1.max_hp == 320, "저승사자 HP 320")
	_assert(e1.mythology == "korean", "저승사자 mythology=korean")
	_assert(e1.intent_pattern.size() == 3, "저승사자 인텐트 3개")
	var e2 := M.bulgasari(scene)
	_assert(e2.max_hp == 900, "불가사리 HP 900")
	_assert(e2.intent_pattern.size() == 3, "불가사리 인텐트 3개")
	var e3 := M.three_legged_crow(scene)
	_assert(e3.max_hp == 280, "삼족오 HP 280")
```

- [ ] **Step 2: 테스트 실행 — 실패 확인**

```bash
"H:/Program Files/Godot/Godot_v4.6.2-stable_win64_console.exe" --headless -s tests/test_runner.gd --path "H:/AIRelatedDefaultPath/ClaudeCode_Base/GameProjects/CardGameProject/stsl"
```
기대: `test_korean_normals_shape` 관련 에러 (스텁이라 함수 없음)

- [ ] **Step 3: `korean_normals.gd` 구현**

```gdscript
# resources/enemies/korean/korean_normals.gd
# 한국 신화 — 일반 적 6종 + 인카운터 조합 테이블
const EnemyRes  = preload("res://resources/enemy_resource.gd")
const IntentRes = preload("res://resources/intent_resource.gd")

static func death_reaper(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "저승사자"; e.max_hp = 320; e.character_scene = scene
	e.mythology = "korean"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 70; i1.target = IntentRes.TargetType.LOWEST_HP
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.DEBUFF; i2.value = 2; i2.status_type = "weak"
	i2.target = IntentRes.TargetType.RANDOM
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 90; i3.target = IntentRes.TargetType.LOWEST_HP
	e.intent_pattern = [i1, i2, i3]
	return e

static func cheoyong(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "처용"; e.max_hp = 450; e.character_scene = scene
	e.mythology = "korean"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.BUFF; i1.value = 40; i1.status_type = "block"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 100; i2.target = IntentRes.TargetType.RANDOM
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 120; i3.target = IntentRes.TargetType.RANDOM
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.BUFF; i4.value = 20; i4.status_type = "block"
	e.intent_pattern = [i1, i2, i3, i4]
	return e

static func dokkaebi(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "도깨비"; e.max_hp = 380; e.character_scene = scene
	e.mythology = "korean"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.BUFF; i1.value = 1; i1.status_type = "strength"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.DEBUFF; i2.value = 2; i2.status_type = "vulnerable"
	i2.target = IntentRes.TargetType.RANDOM
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 90; i3.target = IntentRes.TargetType.RANDOM
	e.intent_pattern = [i1, i2, i3]
	return e

static func three_legged_crow(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "삼족오"; e.max_hp = 280; e.character_scene = scene
	e.mythology = "korean"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.BUFF; i1.value = 1; i1.status_type = "strength"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 60; i2.target = IntentRes.TargetType.ALL
	e.intent_pattern = [i1, i2]
	return e

static func gumiho(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "구미호"; e.max_hp = 350; e.character_scene = scene
	e.mythology = "korean"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.DEBUFF; i1.value = 1; i1.status_type = "vulnerable"
	i1.target = IntentRes.TargetType.RANDOM
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 80; i2.target = IntentRes.TargetType.RANDOM
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.DEBUFF; i3.value = 2; i3.status_type = "weak"
	i3.target = IntentRes.TargetType.RANDOM
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.ATTACK; i4.value = 60; i4.target = IntentRes.TargetType.RANDOM
	e.intent_pattern = [i1, i2, i3, i4]
	return e

static func bulgasari(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "불가사리"; e.max_hp = 900; e.character_scene = scene
	e.mythology = "korean"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.BUFF; i1.value = 2; i1.status_type = "strength"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 100; i2.target = IntentRes.TargetType.RANDOM
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 130; i3.target = IntentRes.TargetType.RANDOM
	e.intent_pattern = [i1, i2, i3]
	return e

static func encounters() -> Array:
	return [
		["death_reaper"],
		["death_reaper", "death_reaper"],
		["cheoyong"],
		["death_reaper", "cheoyong"],
		["dokkaebi", "dokkaebi"],
		["three_legged_crow", "three_legged_crow"],
		["gumiho"],
		["gumiho", "dokkaebi"],
		["bulgasari"],
		["death_reaper", "three_legged_crow"],
		["dokkaebi", "dokkaebi", "three_legged_crow"],
	]
```

- [ ] **Step 4: 테스트 실행 — 통과 확인**

기대: `test_korean_normals_shape` PASS, 기존 690개 유지

- [ ] **Step 5: 커밋**

```bash
git add resources/enemies/korean/korean_normals.gd tests/test_enemies.gd
git commit -m "feat: 한국 일반 적 6종 구현 — 저승사자·처용·도깨비·삼족오·구미호·불가사리"
```

---

## Task 2: 한국 Act 1 엘리트 3종 + 보스 해모수

**Files:**
- Modify: `resources/enemies/korean/korean_act1.gd`
- Modify: `tests/test_enemies.gd`

- [ ] **Step 1: 실패 테스트 작성 — `test_enemies.gd` run_all()에 추가 + 함수 추가**

```gdscript
func test_korean_act1_shape() -> void:
	print("[TestEnemies] test_korean_act1_shape")
	var M = load("res://resources/enemies/korean/korean_act1.gd")
	_assert(M.elites().size() == 3, "korean_act1 엘리트 3종")
	_assert(M.boss() == "haemosu", "korean_act1 보스는 haemosu")
	var scene = load("res://characters/summons/soldier/soldier.tscn")
	var b := M.haemosu(scene)
	_assert(b.max_hp == 4500, "해모수 HP 4500")
	_assert(b.phase_thresholds.size() == 2, "해모수 3페이즈")
	_assert(b.mythology == "korean", "해모수 mythology=korean")
	_assert(b.charm_resistance == 2, "해모수 charm_resistance=2")
```

- [ ] **Step 2: 테스트 실행 — 실패 확인**

- [ ] **Step 3: `korean_act1.gd` 구현**

```gdscript
# resources/enemies/korean/korean_act1.gd
# 한국 신화 — Act 1 엘리트 3종 + 보스(해모수)
const EnemyRes  = preload("res://resources/enemy_resource.gd")
const IntentRes = preload("res://resources/intent_resource.gd")

static func haechi(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "해치"; e.max_hp = 1600; e.character_scene = scene
	e.mythology = "korean"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.BUFF; i1.value = 60; i1.status_type = "block"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.DEBUFF; i2.value = 2; i2.status_type = "vulnerable"
	i2.target = IntentRes.TargetType.RANDOM
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.BUFF; i3.value = 60; i3.status_type = "block"
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.BUFF; i4.value = 1; i4.status_type = "strength"
	var i5 := IntentRes.new()
	i5.action_type = IntentRes.ActionType.ATTACK; i5.value = 180; i5.target = IntentRes.TargetType.RANDOM
	e.intent_pattern = [i1, i2, i3, i4, i5]
	e.charm_resistance = 1
	return e

static func jangseung(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "장승"; e.max_hp = 1700; e.character_scene = scene
	e.mythology = "korean"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.DEBUFF; i1.value = 2; i1.status_type = "vulnerable"
	i1.target = IntentRes.TargetType.ALL
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 150; i2.target = IntentRes.TargetType.LOWEST_HP
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.DEBUFF; i3.value = 2; i3.status_type = "weak"
	i3.target = IntentRes.TargetType.ALL
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.ATTACK; i4.value = 120; i4.target = IntentRes.TargetType.RANDOM
	e.intent_pattern = [i1, i2, i3, i4]
	e.charm_resistance = 1
	return e

static func samsin_grandma(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "삼신할머니"; e.max_hp = 1800; e.character_scene = scene
	e.mythology = "korean"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.DEBUFF; i1.value = 3; i1.status_type = "poison"
	i1.target = IntentRes.TargetType.RANDOM
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.DEBUFF; i2.value = 3; i2.status_type = "poison"
	i2.target = IntentRes.TargetType.ALL
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 160; i3.target = IntentRes.TargetType.RANDOM
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.DEBUFF; i4.value = 2; i4.status_type = "vulnerable"
	i4.target = IntentRes.TargetType.RANDOM
	e.intent_pattern = [i1, i2, i3, i4]
	e.charm_resistance = 1
	return e

static func haemosu(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "해모수"; e.max_hp = 4500; e.character_scene = scene
	e.mythology = "korean"
	e.phase_thresholds = [0.66, 0.33]
	var p0i1 := IntentRes.new()
	p0i1.action_type = IntentRes.ActionType.ATTACK; p0i1.value = 160; p0i1.target = IntentRes.TargetType.RANDOM
	var p0i2 := IntentRes.new()
	p0i2.action_type = IntentRes.ActionType.BUFF; p0i2.value = 1; p0i2.status_type = "strength"
	var p0i3 := IntentRes.new()
	p0i3.action_type = IntentRes.ActionType.ATTACK; p0i3.value = 130; p0i3.target = IntentRes.TargetType.ALL
	var p1i1 := IntentRes.new()
	p1i1.action_type = IntentRes.ActionType.ATTACK; p1i1.value = 200; p1i1.target = IntentRes.TargetType.RANDOM
	var p1i2 := IntentRes.new()
	p1i2.action_type = IntentRes.ActionType.ATTACK; p1i2.value = 160; p1i2.target = IntentRes.TargetType.ALL
	var p1i3 := IntentRes.new()
	p1i3.action_type = IntentRes.ActionType.ATTACK; p1i3.value = 180; p1i3.target = IntentRes.TargetType.LOWEST_HP
	var p1i4 := IntentRes.new()
	p1i4.action_type = IntentRes.ActionType.DEBUFF; p1i4.value = 2; p1i4.status_type = "vulnerable"
	p1i4.target = IntentRes.TargetType.RANDOM
	var p2i1 := IntentRes.new()
	p2i1.action_type = IntentRes.ActionType.ATTACK; p2i1.value = 240; p2i1.target = IntentRes.TargetType.LOWEST_HP
	var p2i2 := IntentRes.new()
	p2i2.action_type = IntentRes.ActionType.DEBUFF; p2i2.value = 2; p2i2.status_type = "vulnerable"
	p2i2.target = IntentRes.TargetType.ALL
	var p2i3 := IntentRes.new()
	p2i3.action_type = IntentRes.ActionType.ATTACK; p2i3.value = 200; p2i3.target = IntentRes.TargetType.ALL
	e.phase_patterns = [
		[p0i1, p0i2, p0i3],
		[p1i1, p1i2, p1i3, p1i4],
		[p2i1, p2i2, p2i3]
	]
	e.intent_pattern = e.phase_patterns[0]
	e.charm_resistance = 2
	return e

static func elites() -> Array:
	return ["haechi", "jangseung", "samsin_grandma"]

static func boss() -> String:
	return "haemosu"
```

- [ ] **Step 4: 테스트 실행 — 통과 확인**

- [ ] **Step 5: 커밋**

```bash
git add resources/enemies/korean/korean_act1.gd tests/test_enemies.gd
git commit -m "feat: 한국 Act1 엘리트(해치·장승·삼신할머니) + 보스 해모수"
```

---

## Task 3: 한국 Act 2 엘리트 3종 + 보스 동명성왕

**Files:**
- Modify: `resources/enemies/korean/korean_act2.gd`
- Modify: `tests/test_enemies.gd`

- [ ] **Step 1: 실패 테스트 작성 — run_all()에 추가 + 함수 추가**

```gdscript
func test_korean_act2_shape() -> void:
	print("[TestEnemies] test_korean_act2_shape")
	var M = load("res://resources/enemies/korean/korean_act2.gd")
	_assert(M.elites().size() == 3, "korean_act2 엘리트 3종")
	_assert(M.boss() == "dongmyeong", "korean_act2 보스는 dongmyeong")
	var scene = load("res://characters/summons/soldier/soldier.tscn")
	var b := M.dongmyeong(scene)
	_assert(b.max_hp == 4800, "동명성왕 HP 4800")
	_assert(b.phase_thresholds.size() == 2, "동명성왕 3페이즈")
	_assert(b.mythology == "korean", "동명성왕 mythology=korean")
	_assert(b.charm_resistance == 2, "동명성왕 charm_resistance=2")
```

- [ ] **Step 2: 테스트 실행 — 실패 확인**

- [ ] **Step 3: `korean_act2.gd` 구현**

```gdscript
# resources/enemies/korean/korean_act2.gd
# 한국 신화 — Act 2 엘리트 3종 + 보스(동명성왕)
const EnemyRes  = preload("res://resources/enemy_resource.gd")
const IntentRes = preload("res://resources/intent_resource.gd")

static func dokkaebi_chief(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "도깨비 대장"; e.max_hp = 1800; e.character_scene = scene
	e.mythology = "korean"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.BUFF; i1.value = 2; i1.status_type = "strength"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.BUFF; i2.value = 30; i2.status_type = "block"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 170; i3.target = IntentRes.TargetType.RANDOM
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.ATTACK; i4.value = 150; i4.target = IntentRes.TargetType.ALL
	e.intent_pattern = [i1, i2, i3, i4]
	e.charm_resistance = 1
	return e

static func sea_dragon_general(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "용왕의 장군"; e.max_hp = 1900; e.character_scene = scene
	e.mythology = "korean"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.BUFF; i1.value = 2; i1.status_type = "strength"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 160; i2.target = IntentRes.TargetType.RANDOM
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 140; i3.target = IntentRes.TargetType.ALL
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.BUFF; i4.value = 1; i4.status_type = "strength"
	e.intent_pattern = [i1, i2, i3, i4]
	e.charm_resistance = 1
	return e

static func underworld_constable(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "저승 포졸"; e.max_hp = 1700; e.character_scene = scene
	e.mythology = "korean"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 140; i1.target = IntentRes.TargetType.LOWEST_HP
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.DEBUFF; i2.value = 3; i2.status_type = "weak"
	i2.target = IntentRes.TargetType.ALL
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 140; i3.target = IntentRes.TargetType.LOWEST_HP
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.ATTACK; i4.value = 170; i4.target = IntentRes.TargetType.LOWEST_HP
	var i5 := IntentRes.new()
	i5.action_type = IntentRes.ActionType.DEBUFF; i5.value = 2; i5.status_type = "vulnerable"
	i5.target = IntentRes.TargetType.RANDOM
	e.intent_pattern = [i1, i2, i3, i4, i5]
	e.charm_resistance = 1
	return e

static func dongmyeong(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "동명성왕"; e.max_hp = 4800; e.character_scene = scene
	e.mythology = "korean"
	e.phase_thresholds = [0.66, 0.33]
	var p0i1 := IntentRes.new()
	p0i1.action_type = IntentRes.ActionType.ATTACK; p0i1.value = 90; p0i1.target = IntentRes.TargetType.RANDOM
	var p0i2 := IntentRes.new()
	p0i2.action_type = IntentRes.ActionType.ATTACK; p0i2.value = 90; p0i2.target = IntentRes.TargetType.RANDOM
	var p0i3 := IntentRes.new()
	p0i3.action_type = IntentRes.ActionType.BUFF; p0i3.value = 1; p0i3.status_type = "strength"
	var p0i4 := IntentRes.new()
	p0i4.action_type = IntentRes.ActionType.BUFF; p0i4.value = 40; p0i4.status_type = "block"
	var p1i1 := IntentRes.new()
	p1i1.action_type = IntentRes.ActionType.ATTACK; p1i1.value = 140; p1i1.target = IntentRes.TargetType.RANDOM
	var p1i2 := IntentRes.new()
	p1i2.action_type = IntentRes.ActionType.ATTACK; p1i2.value = 140; p1i2.target = IntentRes.TargetType.RANDOM
	var p1i3 := IntentRes.new()
	p1i3.action_type = IntentRes.ActionType.ATTACK; p1i3.value = 160; p1i3.target = IntentRes.TargetType.ALL
	var p1i4 := IntentRes.new()
	p1i4.action_type = IntentRes.ActionType.ATTACK; p1i4.value = 120; p1i4.target = IntentRes.TargetType.LOWEST_HP
	var p1i5 := IntentRes.new()
	p1i5.action_type = IntentRes.ActionType.DEBUFF; p1i5.value = 2; p1i5.status_type = "vulnerable"
	p1i5.target = IntentRes.TargetType.RANDOM
	var p2i1 := IntentRes.new()
	p2i1.action_type = IntentRes.ActionType.ATTACK; p2i1.value = 200; p2i1.target = IntentRes.TargetType.RANDOM
	var p2i2 := IntentRes.new()
	p2i2.action_type = IntentRes.ActionType.ATTACK; p2i2.value = 200; p2i2.target = IntentRes.TargetType.RANDOM
	var p2i3 := IntentRes.new()
	p2i3.action_type = IntentRes.ActionType.ATTACK; p2i3.value = 180; p2i3.target = IntentRes.TargetType.ALL
	var p2i4 := IntentRes.new()
	p2i4.action_type = IntentRes.ActionType.BUFF; p2i4.value = 2; p2i4.status_type = "strength"
	e.phase_patterns = [
		[p0i1, p0i2, p0i3, p0i4],
		[p1i1, p1i2, p1i3, p1i4, p1i5],
		[p2i1, p2i2, p2i3, p2i4]
	]
	e.intent_pattern = e.phase_patterns[0]
	e.charm_resistance = 2
	return e

static func elites() -> Array:
	return ["dokkaebi_chief", "sea_dragon_general", "underworld_constable"]

static func boss() -> String:
	return "dongmyeong"
```

- [ ] **Step 4: 테스트 실행 — 통과 확인**

- [ ] **Step 5: 커밋**

```bash
git add resources/enemies/korean/korean_act2.gd tests/test_enemies.gd
git commit -m "feat: 한국 Act2 엘리트(도깨비 대장·용왕의 장군·저승 포졸) + 보스 동명성왕"
```

---

## Task 4: 한국 Act 3 엘리트 3종 + 보스 염라대왕

**Files:**
- Modify: `resources/enemies/korean/korean_act3.gd`
- Modify: `tests/test_enemies.gd`

- [ ] **Step 1: 실패 테스트 작성**

```gdscript
func test_korean_act3_shape() -> void:
	print("[TestEnemies] test_korean_act3_shape")
	var M = load("res://resources/enemies/korean/korean_act3.gd")
	_assert(M.elites().size() == 3, "korean_act3 엘리트 3종")
	_assert(M.boss() == "king_yama", "korean_act3 보스는 king_yama")
	var scene = load("res://characters/summons/soldier/soldier.tscn")
	var b := M.king_yama(scene)
	_assert(b.max_hp == 4800, "염라대왕 HP 4800")
	_assert(b.phase_thresholds.size() == 2, "염라대왕 3페이즈")
	_assert(b.mythology == "korean", "염라대왕 mythology=korean")
	_assert(b.charm_resistance == 2, "염라대왕 charm_resistance=2")
```

- [ ] **Step 2: 테스트 실행 — 실패 확인**

- [ ] **Step 3: `korean_act3.gd` 구현**

```gdscript
# resources/enemies/korean/korean_act3.gd
# 한국 신화 — Act 3 엘리트 3종 + 보스(염라대왕)
const EnemyRes  = preload("res://resources/enemy_resource.gd")
const IntentRes = preload("res://resources/intent_resource.gd")

static func underworld_judge(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "저승 판관"; e.max_hp = 1900; e.character_scene = scene
	e.mythology = "korean"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.DEBUFF; i1.value = 2; i1.status_type = "vulnerable"
	i1.target = IntentRes.TargetType.ALL
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 140; i2.target = IntentRes.TargetType.LOWEST_HP
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 180; i3.target = IntentRes.TargetType.RANDOM
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.ATTACK; i4.value = 160; i4.target = IntentRes.TargetType.ALL
	var i5 := IntentRes.new()
	i5.action_type = IntentRes.ActionType.DEBUFF; i5.value = 2; i5.status_type = "weak"
	i5.target = IntentRes.TargetType.ALL
	e.intent_pattern = [i1, i2, i3, i4, i5]
	e.charm_resistance = 1
	return e

static func gat_spirit(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "갓신"; e.max_hp = 2000; e.character_scene = scene
	e.mythology = "korean"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.BUFF; i1.value = 2; i1.status_type = "strength"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.BUFF; i2.value = 40; i2.status_type = "block"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 180; i3.target = IntentRes.TargetType.RANDOM
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.ATTACK; i4.value = 200; i4.target = IntentRes.TargetType.LOWEST_HP
	e.intent_pattern = [i1, i2, i3, i4]
	e.charm_resistance = 1
	return e

static func cheoyong_god(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "처용신"; e.max_hp = 1800; e.character_scene = scene
	e.mythology = "korean"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.BUFF; i1.value = 50; i1.status_type = "block"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.DEBUFF; i2.value = 2; i2.status_type = "weak"
	i2.target = IntentRes.TargetType.RANDOM
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.DEBUFF; i3.value = 2; i3.status_type = "vulnerable"
	i3.target = IntentRes.TargetType.RANDOM
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.ATTACK; i4.value = 170; i4.target = IntentRes.TargetType.RANDOM
	var i5 := IntentRes.new()
	i5.action_type = IntentRes.ActionType.ATTACK; i5.value = 190; i5.target = IntentRes.TargetType.LOWEST_HP
	e.intent_pattern = [i1, i2, i3, i4, i5]
	e.charm_resistance = 1
	return e

static func king_yama(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "염라대왕"; e.max_hp = 4800; e.character_scene = scene
	e.mythology = "korean"
	e.phase_thresholds = [0.66, 0.33]
	var p0i1 := IntentRes.new()
	p0i1.action_type = IntentRes.ActionType.DEBUFF; p0i1.value = 2; p0i1.status_type = "vulnerable"
	p0i1.target = IntentRes.TargetType.ALL
	var p0i2 := IntentRes.new()
	p0i2.action_type = IntentRes.ActionType.DEBUFF; p0i2.value = 2; p0i2.status_type = "weak"
	p0i2.target = IntentRes.TargetType.ALL
	var p0i3 := IntentRes.new()
	p0i3.action_type = IntentRes.ActionType.ATTACK; p0i3.value = 200; p0i3.target = IntentRes.TargetType.LOWEST_HP
	var p0i4 := IntentRes.new()
	p0i4.action_type = IntentRes.ActionType.BUFF; p0i4.value = 2; p0i4.status_type = "strength"
	var p0i5 := IntentRes.new()
	p0i5.action_type = IntentRes.ActionType.ATTACK; p0i5.value = 160; p0i5.target = IntentRes.TargetType.RANDOM
	var p1i1 := IntentRes.new()
	p1i1.action_type = IntentRes.ActionType.DEBUFF; p1i1.value = 3; p1i1.status_type = "vulnerable"
	p1i1.target = IntentRes.TargetType.ALL
	var p1i2 := IntentRes.new()
	p1i2.action_type = IntentRes.ActionType.ATTACK; p1i2.value = 230; p1i2.target = IntentRes.TargetType.LOWEST_HP
	var p1i3 := IntentRes.new()
	p1i3.action_type = IntentRes.ActionType.ATTACK; p1i3.value = 190; p1i3.target = IntentRes.TargetType.ALL
	var p1i4 := IntentRes.new()
	p1i4.action_type = IntentRes.ActionType.DEBUFF; p1i4.value = 2; p1i4.status_type = "weak"
	p1i4.target = IntentRes.TargetType.ALL
	var p2i1 := IntentRes.new()
	p2i1.action_type = IntentRes.ActionType.ATTACK; p2i1.value = 270; p2i1.target = IntentRes.TargetType.LOWEST_HP
	var p2i2 := IntentRes.new()
	p2i2.action_type = IntentRes.ActionType.DEBUFF; p2i2.value = 3; p2i2.status_type = "vulnerable"
	p2i2.target = IntentRes.TargetType.ALL
	var p2i3 := IntentRes.new()
	p2i3.action_type = IntentRes.ActionType.ATTACK; p2i3.value = 210; p2i3.target = IntentRes.TargetType.ALL
	e.phase_patterns = [
		[p0i1, p0i2, p0i3, p0i4, p0i5],
		[p1i1, p1i2, p1i3, p1i4],
		[p2i1, p2i2, p2i3]
	]
	e.intent_pattern = e.phase_patterns[0]
	e.charm_resistance = 2
	return e

static func elites() -> Array:
	return ["underworld_judge", "gat_spirit", "cheoyong_god"]

static func boss() -> String:
	return "king_yama"
```

- [ ] **Step 4: 테스트 실행 — 통과 확인**

- [ ] **Step 5: 커밋**

```bash
git add resources/enemies/korean/korean_act3.gd tests/test_enemies.gd
git commit -m "feat: 한국 Act3 엘리트(저승 판관·갓신·처용신) + 보스 염라대왕"
```

---

## Task 5: 한국 이벤트 10종 + _build_event_pool() 신화 분기

**Files:**
- Create: `resources/events/events_korean.gd`
- Modify: `autoload/game_manager.gd`
- Modify: `tests/test_event.gd`

- [ ] **Step 1: 실패 테스트 작성 — `test_event.gd` run_all()에 추가 + 함수 추가**

```gdscript
func test_korean_event_pool_size() -> void:
	print("[TestEvent] test_korean_event_pool_size")
	var KoreanEvents = load("res://resources/events/events_korean.gd")
	var pool := KoreanEvents.build_pool()
	_assert(pool.size() == 10, "한국 이벤트 풀 10종")

func test_korean_death_reaper_event() -> void:
	print("[TestEvent] test_korean_death_reaper_event")
	var KoreanEvents = load("res://resources/events/events_korean.gd")
	var pool := KoreanEvents.build_pool()
	var ChoiceRes = load("res://resources/event_choice_resource.gd")
	var found := false
	for e in pool:
		if e.event_name == "저승사자의 방문":
			found = true
			_assert(e.choices[0].effect_type == ChoiceRes.EffectType.GOLD, "선택A: GOLD")
			_assert(e.choices[0].value == 70, "GOLD +70")
			_assert(e.choices[0].cost_hp == 40, "HP -40")
	_assert(found, "저승사자의 방문 이벤트 존재")

func test_korean_samsin_blessing_uses_max_hp() -> void:
	print("[TestEvent] test_korean_samsin_blessing_uses_max_hp")
	var KoreanEvents = load("res://resources/events/events_korean.gd")
	var pool := KoreanEvents.build_pool()
	var ChoiceRes = load("res://resources/event_choice_resource.gd")
	var found := false
	for e in pool:
		if e.event_name == "삼신할머니의 축복":
			found = true
			_assert(e.choices[0].effect_type == ChoiceRes.EffectType.MAX_HP, "선택A: MAX_HP")
	_assert(found, "삼신할머니의 축복 이벤트 존재")
```

- [ ] **Step 2: 테스트 실행 — 실패 확인** (파일 없으므로 load 에러)

- [ ] **Step 3: `events_korean.gd` 생성**

```gdscript
# resources/events/events_korean.gd
# 한국 신화 이벤트 10종
const EventRes  = preload("res://resources/event_resource.gd")
const ChoiceRes = preload("res://resources/event_choice_resource.gd")

static func build_pool() -> Array:
	return [
		_death_reaper_visit(), _dokkaebi_hammer(), _gumiho_temptation(),
		_shaman_gut(), _samsin_blessing(), _dangun_prophecy(),
		_mountain_god_bet(), _sea_king_test(), _hero_joins(),
		_underworld_deal(),
	]

static func _death_reaper_visit() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "저승사자의 방문"
	e.description = "밤길을 걷다 검은 갓을 쓴 저승사자와 마주쳤다. '아직은 아니오. 대신, 무언가를 가져가겠소.'"
	var ca: Resource = ChoiceRes.new(); ca.label = "받아들인다 (HP -40)"
	ca.effect_type = ChoiceRes.EffectType.GOLD; ca.value = 70; ca.cost_hp = 40
	var cb: Resource = ChoiceRes.new(); cb.label = "거절한다"
	cb.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb]; return e

static func _dokkaebi_hammer() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "도깨비 방망이"
	e.description = "길가에 낡은 방망이가 떨어져 있다. 잡으면 이상한 기운이 느껴진다."
	var ca: Resource = ChoiceRes.new(); ca.label = "금 나와라 뚝딱!"
	ca.effect_type = ChoiceRes.EffectType.GOLD; ca.value = 80
	var cb: Resource = ChoiceRes.new(); cb.label = "쌀 나와라 뚝딱!"
	cb.effect_type = ChoiceRes.EffectType.HEAL; cb.value = 35
	var cc: Resource = ChoiceRes.new(); cc.label = "가져간다 (도박)"
	cc.effect_type = ChoiceRes.EffectType.ADD_RELIC_GAMBLE
	e.choices = [ca, cb, cc]; return e

static func _gumiho_temptation() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "구미호의 유혹"
	e.description = "여우 눈빛의 여인이 앞을 막는다. '당신의 약점 하나를 제거해 드리죠. 대신 힘을 드릴게요.'"
	var ca: Resource = ChoiceRes.new(); ca.label = "거래한다 (카드 1장 제거)"
	ca.effect_type = ChoiceRes.EffectType.REMOVE_CARD; ca.value = 1
	var cb: Resource = ChoiceRes.new(); cb.label = "거절한다"
	cb.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb]; return e

static func _shaman_gut() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "무당의 굿판"
	e.description = "붉은 무복의 무당이 굿을 올린다. '제물이 있으면 상처를 치유해드릴 수 있어요.'"
	var ca: Resource = ChoiceRes.new(); ca.label = "굿을 부탁한다 (골드 -50)"
	ca.effect_type = ChoiceRes.EffectType.HEAL; ca.value = 30; ca.cost_gold = 50
	var cb: Resource = ChoiceRes.new(); cb.label = "구경만 한다"
	cb.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb]; return e

static func _samsin_blessing() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "삼신할머니의 축복"
	e.description = "노파가 따뜻한 빛을 내밀며 말한다. '이 사람들은 한이 많겠구만. 내가 하나 점지해줄게.'"
	var ca: Resource = ChoiceRes.new(); ca.label = "감사히 받는다"
	ca.effect_type = ChoiceRes.EffectType.MAX_HP; ca.value = 30
	var cb: Resource = ChoiceRes.new(); cb.label = "괜찮다고 한다"
	cb.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb]; return e

static func _dangun_prophecy() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "단군의 예언"
	e.description = "마니산 제단에서 고요한 목소리가 들린다. '너희의 길에는 두 갈래가 있다.'"
	var ca: Resource = ChoiceRes.new(); ca.label = "강인함의 길"
	ca.effect_type = ChoiceRes.EffectType.ADD_RELIC
	var cb: Resource = ChoiceRes.new(); cb.label = "지혜의 길"
	cb.effect_type = ChoiceRes.EffectType.DRAW_UP; cb.value = 1
	e.choices = [ca, cb]; return e

static func _mountain_god_bet() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "산신령과의 내기"
	e.description = "백발 노인이 바위 위에 앉아 말한다. '나를 이기면 소원을 들어주겠네.'"
	var ca: Resource = ChoiceRes.new(); ca.label = "내기를 수락한다"
	ca.effect_type = ChoiceRes.EffectType.ADD_RELIC_GAMBLE
	var cb: Resource = ChoiceRes.new(); cb.label = "그냥 지나친다"
	cb.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb]; return e

static func _sea_king_test() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "용왕의 시험"
	e.description = "용의 발톱이 물 속에서 드러난다. '내 바다를 지나가려면 시험을 통과하여라.'"
	var ca: Resource = ChoiceRes.new(); ca.label = "시험에 응한다 (HP -30)"
	ca.effect_type = ChoiceRes.EffectType.GOLD; ca.value = 100; ca.cost_hp = 30
	var cb: Resource = ChoiceRes.new(); cb.label = "뇌물을 바친다 (골드 -60)"
	cb.effect_type = ChoiceRes.EffectType.HEAL; cb.value = 20; cb.cost_gold = 60
	var cc: Resource = ChoiceRes.new(); cc.label = "돌아간다"
	cc.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb, cc]; return e

static func _hero_joins() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "동료 영웅의 합류"
	e.description = "전장을 헤매던 한 영웅이 당신의 팀을 발견했다."
	var ca: Resource = ChoiceRes.new(); ca.label = "함께 싸우자"
	ca.effect_type = ChoiceRes.EffectType.ADD_HERO
	var cb: Resource = ChoiceRes.new(); cb.label = "아직은 아니야"
	cb.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb]; return e

static func _underworld_deal() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "저승의 거래"
	e.description = "어둠 속 흰 도포를 입은 자가 나타난다. '내가 가진 것 하나와 당신의 것 하나를 교환하죠.'"
	var ca: Resource = ChoiceRes.new(); ca.label = "거래한다"
	ca.effect_type = ChoiceRes.EffectType.ADD_RELIC_GAMBLE
	var cb: Resource = ChoiceRes.new(); cb.label = "거절한다"
	cb.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb]; return e
```

- [ ] **Step 4: `game_manager.gd` 수정 — preload 추가 + `_build_event_pool()` 변경**

`_EventsAct3` preload 줄 바로 다음에 추가:
```gdscript
const _EventsKorean = preload("res://resources/events/events_korean.gd")
```

`_build_event_pool()` 함수 교체:
```gdscript
func _build_event_pool() -> Array:
	var myth: String = act_mythologies[current_act - 1]
	match myth:
		"korean": return _EventsKorean.build_pool()
	match current_act:
		2: return _EventsAct2.build_pool()
		3: return _EventsAct3.build_pool()
	return _EventsAct1.build_pool()
```

- [ ] **Step 5: 테스트 실행 — 통과 확인**

- [ ] **Step 6: 커밋**

```bash
git add resources/events/events_korean.gd autoload/game_manager.gd tests/test_event.gd
git commit -m "feat: 한국 신화 이벤트 10종 + _build_event_pool() 신화 기반 분기"
```

---

## Task 6: 한국 전용 렐릭 3종

**Files:**
- Modify: `resources/relics/relics.gd`
- Modify: `tests/test_relics.gd`

- [ ] **Step 1: 실패 테스트 작성 — `test_relics.gd`의 기존 `test_relic_pool_size()` 수정 + 새 함수 추가**

기존 `_assert(pool.size() == 25, ...)` → `_assert(pool.size() == 28, ...)` 으로 수정.

run_all()에 `test_korean_relics_exist()` 추가 후 함수 추가:
```gdscript
func test_korean_relics_exist() -> void:
	print("[TestRelics] test_korean_relics_exist")
	var RelicsGd = load("res://resources/relics/relics.gd")
	var pool: Array = RelicsGd.build_pool()
	var names := pool.map(func(r): return r.relic_name)
	_assert("저승 부적" in names, "저승 부적 존재")
	_assert("도깨비 방망이 파편" in names, "도깨비 방망이 파편 존재")
	_assert("삼태극 부적" in names, "삼태극 부적 존재")
	var talisman = pool.filter(func(r): return r.relic_name == "저승 부적")[0]
	_assert(talisman.trigger == RelicRes.TriggerType.BATTLE_START, "저승 부적 트리거=BATTLE_START")
	_assert(talisman.effect_type == RelicRes.EffectType.ENERGY, "저승 부적 효과=ENERGY")
	_assert(talisman.value == 1, "저승 부적 value=1")
```

- [ ] **Step 2: 테스트 실행 — 실패 확인** (pool.size() == 25 ≠ 28)

- [ ] **Step 3: `relics.gd` 수정**

`build_pool()` 반환 배열 끝에 3개 추가:
```gdscript
static func build_pool() -> Array:
	return [
		_burning_blood(), _phoenix_feather(), _poison_vial(),
		_war_drum(), _ancient_artifact(), _hourglass(),
		_blood_stone(), _emperors_seal(), _serpent_bracelet(),
		_turtle_ship_model(), _artillery_horn(), _nanjung_ilgi(),
		_pharaoh_seal(), _devils_contract(), _cursed_crown(),
		_blood_oath(), _tacticians_map(), _iron_will(), _ancient_shield(),
		_ankh_of_life(), _eye_of_horus(), _scarab_talisman(),
		_rune_of_fate(), _mjolnir_shard(), _idun_apple(),
		_underworld_talisman(), _dokkaebi_hammer_shard(), _samtaegeuk_charm(),
	]
```

파일 끝에 렐릭 팩토리 3개 추가:
```gdscript
# ──── 챕터 2 렐릭 (한국 신화) ────

static func _underworld_talisman() -> Resource:
	var r: Resource = RelicRes.new(); r.relic_name = "저승 부적"
	r.description = "전투 시작 시 에너지 +1"
	r.trigger = RelicRes.TriggerType.BATTLE_START
	r.effect_type = RelicRes.EffectType.ENERGY; r.value = 1; return r

static func _dokkaebi_hammer_shard() -> Resource:
	var r: Resource = RelicRes.new(); r.relic_name = "도깨비 방망이 파편"
	r.description = "전투 승리 시 팀 사기 +3"
	r.trigger = RelicRes.TriggerType.BATTLE_WIN
	r.effect_type = RelicRes.EffectType.GAIN_MORALE; r.value = 3; return r

static func _samtaegeuk_charm() -> Resource:
	var r: Resource = RelicRes.new(); r.relic_name = "삼태극 부적"
	r.description = "영웅이 피해를 받을 때 방어도 +10"
	r.trigger = RelicRes.TriggerType.ON_HERO_DAMAGED
	r.effect_type = RelicRes.EffectType.BLOCK; r.value = 10; return r
```

- [ ] **Step 4: 테스트 실행 — 통과 확인**

- [ ] **Step 5: 커밋**

```bash
git add resources/relics/relics.gd tests/test_relics.gd
git commit -m "feat: 한국 신화 렐릭 3종 추가 — 저승 부적·도깨비 방망이 파편·삼태극 부적"
```

---

## Task 7: 챕터 2 스텁 자동 필터 + 통합 테스트

**Files:**
- Modify: `autoload/game_manager.gd`
- Modify: `tests/test_chapter_system.gd`

- [ ] **Step 1: 실패 테스트 작성 — `test_chapter_system.gd` run_all()에 추가 + 함수 추가**

```gdscript
func test_chapter2_pool_filters_empty_stubs() -> void:
	print("[TestChapterSystem] test_chapter2_pool_filters_empty_stubs")
	# 한국 구현됨, 중국·일본은 빈 스텁 → pool은 ["korean","korean","korean"]
	var pool := gm._get_chapter_mythology_pool(2)
	_assert(pool.size() == 3, "챕터2 풀은 항상 3개")
	for myth in pool:
		_assert(myth == "korean", "빈 스텁 필터 시 한국만 남아야 함: " + myth)
```

- [ ] **Step 2: 테스트 실행 — 실패 확인** (현재 ["korean","chinese","japanese"] 반환)

- [ ] **Step 3: `game_manager.gd`의 `_get_chapter_mythology_pool()` 수정**

```gdscript
func _get_chapter_mythology_pool(chapter: int) -> Array[String]:
	if chapter == 1:
		return ["greek", "egyptian", "norse"]
	if chapter == 2:
		var available: Array[String] = []
		if _KoreanAct1.elites().size() > 0:
			available.append("korean")
		if _ChineseAct1.elites().size() > 0:
			available.append("chinese")
		if _JapaneseAct1.elites().size() > 0:
			available.append("japanese")
		if available.is_empty():
			available = ["korean"]
		var pool: Array[String] = []
		for i in range(3):
			pool.append(available[i % available.size()])
		return pool
	return ["greek", "egyptian", "norse"]
```

- [ ] **Step 4: 테스트 실행 — 통과 확인**

기대: `test_chapter2_pool_filters_empty_stubs` PASS + 기존 `test_chapter_pool_dispatch` PASS 유지

> `test_chapter_pool_dispatch`는 `_get_chapter_mythology_pool(2)`가 "korean"을 포함하는지 검증함. 수정 후에도 `["korean","korean","korean"]`은 "korean" 포함이므로 계속 PASS.

- [ ] **Step 5: 커밋**

```bash
git add autoload/game_manager.gd tests/test_chapter_system.gd
git commit -m "feat: 챕터 2 빈 스텁 자동 필터 — 한국만 구현 시 3 Act 모두 한국 신화로"
```

- [ ] **Step 6: 전체 테스트 실행 — 최종 확인**

```bash
"H:/Program Files/Godot/Godot_v4.6.2-stable_win64_console.exe" --headless -s tests/test_runner.gd --path "H:/AIRelatedDefaultPath/ClaudeCode_Base/GameProjects/CardGameProject/stsl"
```
기대: `=== Results: N passed, 0 failed ===` (N > 690)

---

## 검증 체크리스트

- [ ] 한국 일반 적 6종: HP·mythology·intent_pattern.size() 올바름
- [ ] Act1~3 보스: max_hp, phase_thresholds.size()==2, charm_resistance==2
- [ ] 이벤트 풀: 10종, 저승사자의 방문 GOLD+70/HP-40, 삼신할머니의 축복 MAX_HP
- [ ] 렐릭 풀: 28종, 저승 부적 ENERGY+1 BATTLE_START
- [ ] 챕터 2 Pool: 항상 3개 원소, 스텁 필터 동작
- [ ] 기존 테스트 전체 PASS (regression 없음)
