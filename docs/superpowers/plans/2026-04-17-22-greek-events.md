# Plan 22 — 그리스 신화 이벤트 5종 추가 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** EventScene에 ADD_RELIC·GOLD cost_hp 처리를 추가하고 그리스 신화 테마 이벤트 5종을 _build_event_pool()에 추가한다.

**Architecture:** EventChoiceResource.EffectType.ADD_RELIC은 이미 enum에 있지만 event_scene.gd에서 처리하지 않는다. GOLD도 cost_hp를 무시한다. 이 두 가지를 먼저 수정한 뒤, game_manager.gd의 `_build_event_pool()`에 그리스 신화 5종 이벤트를 추가한다. 이벤트 풀은 총 10종이 된다.

**Tech Stack:** GDScript 4.6, Godot 4.6 headless test runner (`"H:/Program Files/Godot/Godot_v4.6.2-stable_win64_console.exe" --headless -s tests/test_runner.gd`)

---

## 파일 맵

- **Modify:** `scenes/event/event_scene.gd` — ADD_RELIC 케이스 추가, GOLD에 cost_hp 지원
- **Modify:** `autoload/game_manager.gd` — `_build_event_pool()`에 이벤트 5종 추가
- **Modify:** `tests/test_event.gd` — 풀 크기 10, 신규 이벤트 구조 검증 테스트

---

## 5종 신규 이벤트

| 이름 | 설명 | 선택 A | 선택 B |
|------|------|--------|--------|
| 프로메테우스의 불 | 티탄이 불씨를 건넨다 | DRAW_UP +1 (cost_hp 20) | NONE |
| 헤라클레스의 시련 | 힘을 겨루자는 제안 | GOLD +60 (cost_hp 25) | NONE |
| 키르케의 마법 | 마법으로 체력 회복 제안 | HEAL +25 (cost_gold 50) | NONE |
| 하데스의 계약 | 저승신이 유물을 제시 | ADD_RELIC (cost_hp 30) | NONE |
| 헤르메스의 도박 | 황금 vs 덱 경량화 | GOLD +50 | REMOVE_CARD |

---

### Task 1: EventScene — ADD_RELIC + GOLD cost_hp 처리

**Files:**
- Modify: `scenes/event/event_scene.gd`
- Modify: `tests/test_event.gd`

**배경:**
현재 `_apply_choice()`에서 `ADD_RELIC`은 누락, `GOLD`는 `cost_hp`를 무시한다.

현재 `_apply_choice()`:
```gdscript
func _apply_choice(choice: Resource) -> void:
	match choice.effect_type:
		choice.EffectType.GOLD:
			GameManager.add_gold(choice.value)
		choice.EffectType.HEAL:
			if GameManager.spend_gold(choice.cost_gold):
				for hero in TeamManager.heroes:
					TeamManager.heal(hero.hero_id, choice.value)
		choice.EffectType.DRAW_UP:
			if choice.cost_hp > 0:
				for hero in TeamManager.heroes:
					TeamManager.take_damage(hero.hero_id, choice.cost_hp)
			DeckManager.base_draw_count += choice.value
		choice.EffectType.REMOVE_CARD:
			if not DeckManager.draw_pile.is_empty():
				DeckManager.draw_pile.remove_at(
					randi() % DeckManager.draw_pile.size())
		choice.EffectType.ADD_HERO:
			GameManager.recruit_random_hero()
		choice.EffectType.NONE:
			pass
```

- [ ] **Step 1: 실패하는 테스트 작성**

`tests/test_event.gd`의 `run_all()`에 추가:
```gdscript
	test_add_relic_choice_structure()
	test_gold_with_cost_hp_structure()
```

파일 끝에 추가:
```gdscript
func test_add_relic_choice_structure() -> void:
	print("[TestEvent] test_add_relic_choice_structure")
	var ChoiceRes = load("res://resources/event_choice_resource.gd")
	var choice: Resource = ChoiceRes.new()
	choice.effect_type = ChoiceRes.EffectType.ADD_RELIC
	choice.cost_hp = 30
	_assert(choice.effect_type == ChoiceRes.EffectType.ADD_RELIC, "ADD_RELIC 타입 설정 가능")
	_assert(choice.cost_hp == 30, "cost_hp 30 설정 가능")

func test_gold_with_cost_hp_structure() -> void:
	print("[TestEvent] test_gold_with_cost_hp_structure")
	var ChoiceRes = load("res://resources/event_choice_resource.gd")
	var choice: Resource = ChoiceRes.new()
	choice.effect_type = ChoiceRes.EffectType.GOLD
	choice.value = 60
	choice.cost_hp = 25
	_assert(choice.effect_type == ChoiceRes.EffectType.GOLD, "GOLD 타입 설정 가능")
	_assert(choice.value == 60, "value 60")
	_assert(choice.cost_hp == 25, "cost_hp 25 설정 가능")
```

- [ ] **Step 2: 테스트 실행 확인**

```bash
cd "H:/AIRelatedDefaultPath/ClaudeCode_Base/GameProjects/CardGameProject/stsl" && "H:/Program Files/Godot/Godot_v4.6.2-stable_win64_console.exe" --headless -s tests/test_runner.gd > /tmp/test_out.txt 2>&1; grep -E "FAIL|Results" /tmp/test_out.txt
```

Expected: `=== Results: 359 passed, 0 failed ===` (이 테스트들은 구조 검증이라 즉시 통과)

- [ ] **Step 3: EventScene 수정**

`scenes/event/event_scene.gd`의 `_apply_choice()` 전체를 교체:

```gdscript
func _apply_choice(choice: Resource) -> void:
	match choice.effect_type:
		choice.EffectType.GOLD:
			if choice.cost_hp > 0:
				for hero in TeamManager.heroes:
					TeamManager.take_damage(hero.hero_id, choice.cost_hp)
			GameManager.add_gold(choice.value)
		choice.EffectType.HEAL:
			if GameManager.spend_gold(choice.cost_gold):
				for hero in TeamManager.heroes:
					TeamManager.heal(hero.hero_id, choice.value)
		choice.EffectType.DRAW_UP:
			if choice.cost_hp > 0:
				for hero in TeamManager.heroes:
					TeamManager.take_damage(hero.hero_id, choice.cost_hp)
			DeckManager.base_draw_count += choice.value
		choice.EffectType.REMOVE_CARD:
			if not DeckManager.draw_pile.is_empty():
				DeckManager.draw_pile.remove_at(
					randi() % DeckManager.draw_pile.size())
		choice.EffectType.ADD_RELIC:
			if choice.cost_hp > 0:
				for hero in TeamManager.heroes:
					TeamManager.take_damage(hero.hero_id, choice.cost_hp)
			var relic = GameManager.get_random_relic()
			if relic:
				GameManager.add_relic(relic)
		choice.EffectType.ADD_HERO:
			GameManager.recruit_random_hero()
		choice.EffectType.NONE:
			pass
```

- [ ] **Step 4: 테스트 통과 확인**

```bash
cd "H:/AIRelatedDefaultPath/ClaudeCode_Base/GameProjects/CardGameProject/stsl" && "H:/Program Files/Godot/Godot_v4.6.2-stable_win64_console.exe" --headless -s tests/test_runner.gd > /tmp/test_out.txt 2>&1; grep -E "FAIL|Results" /tmp/test_out.txt
```

Expected: `=== Results: 359 passed, 0 failed ===`

- [ ] **Step 5: 커밋**

```bash
cd "H:/AIRelatedDefaultPath/ClaudeCode_Base/GameProjects/CardGameProject/stsl" && git checkout -b feat/plan-22-greek-events && git add scenes/event/event_scene.gd tests/test_event.gd && git commit -m "feat: EventScene ADD_RELIC 처리 + GOLD cost_hp 지원"
```

---

### Task 2: GameManager — 그리스 신화 이벤트 5종 추가

**Files:**
- Modify: `autoload/game_manager.gd`
- Modify: `tests/test_event.gd`

**배경:**
`_build_event_pool()`에 현재 5종이 있다. 끝의 `return events` 앞에 5종을 추가해 총 10종으로 만든다.

- [ ] **Step 1: 실패하는 테스트 작성**

`tests/test_event.gd`의 `_build_pool()` 함수 끝(return events 앞)에 5개 이벤트 추가:

```gdscript
	# 6. 프로메테우스의 불
	var e6: Resource = EventRes.new(); e6.event_name = "프로메테우스의 불"
	var c6a: Resource = ChoiceRes.new(); c6a.label = "불씨를 받는다 (드로우 +1, HP -20)"
	c6a.effect_type = ChoiceRes.EffectType.DRAW_UP; c6a.value = 1; c6a.cost_hp = 20
	var c6b: Resource = ChoiceRes.new(); c6b.label = "거절한다"
	c6b.effect_type = ChoiceRes.EffectType.NONE
	e6.choices = [c6a, c6b]; events.append(e6)

	# 7. 헤라클레스의 시련
	var e7: Resource = EventRes.new(); e7.event_name = "헤라클레스의 시련"
	var c7a: Resource = ChoiceRes.new(); c7a.label = "맞선다 (골드 +60, HP -25)"
	c7a.effect_type = ChoiceRes.EffectType.GOLD; c7a.value = 60; c7a.cost_hp = 25
	var c7b: Resource = ChoiceRes.new(); c7b.label = "포기한다"
	c7b.effect_type = ChoiceRes.EffectType.NONE
	e7.choices = [c7a, c7b]; events.append(e7)

	# 8. 키르케의 마법
	var e8: Resource = EventRes.new(); e8.event_name = "키르케의 마법"
	var c8a: Resource = ChoiceRes.new(); c8a.label = "마법을 받는다 (HP +25, 골드 -50)"
	c8a.effect_type = ChoiceRes.EffectType.HEAL; c8a.value = 25; c8a.cost_gold = 50
	var c8b: Resource = ChoiceRes.new(); c8b.label = "거절한다"
	c8b.effect_type = ChoiceRes.EffectType.NONE
	e8.choices = [c8a, c8b]; events.append(e8)

	# 9. 하데스의 계약
	var e9: Resource = EventRes.new(); e9.event_name = "하데스의 계약"
	var c9a: Resource = ChoiceRes.new(); c9a.label = "계약한다 (렐릭 획득, HP -30)"
	c9a.effect_type = ChoiceRes.EffectType.ADD_RELIC; c9a.cost_hp = 30
	var c9b: Resource = ChoiceRes.new(); c9b.label = "거절한다"
	c9b.effect_type = ChoiceRes.EffectType.NONE
	e9.choices = [c9a, c9b]; events.append(e9)

	# 10. 헤르메스의 도박
	var e10: Resource = EventRes.new(); e10.event_name = "헤르메스의 도박"
	var c10a: Resource = ChoiceRes.new(); c10a.label = "황금을 받는다 (골드 +50)"
	c10a.effect_type = ChoiceRes.EffectType.GOLD; c10a.value = 50
	var c10b: Resource = ChoiceRes.new(); c10b.label = "덱을 가볍게 한다 (카드 1장 제거)"
	c10b.effect_type = ChoiceRes.EffectType.REMOVE_CARD; c10b.value = 1
	e10.choices = [c10a, c10b]; events.append(e10)
```

`run_all()`에 추가:
```gdscript
	test_pool_has_ten_events()
	test_prometheus_event_exists()
	test_hades_event_uses_add_relic()
	test_hermes_event_has_two_choices()
```

파일 끝에 추가:
```gdscript
func test_pool_has_ten_events() -> void:
	print("[TestEvent] test_pool_has_ten_events")
	var pool := _build_pool()
	_assert(pool.size() == 10, "이벤트 풀 10종")

func test_prometheus_event_exists() -> void:
	print("[TestEvent] test_prometheus_event_exists")
	var pool := _build_pool()
	var found := false
	for e in pool:
		if e.event_name == "프로메테우스의 불":
			found = true
			var ChoiceRes = load("res://resources/event_choice_resource.gd")
			_assert(e.choices[0].effect_type == ChoiceRes.EffectType.DRAW_UP, "선택 A: DRAW_UP")
			_assert(e.choices[0].cost_hp == 20, "cost_hp == 20")
	_assert(found, "프로메테우스의 불 이벤트 존재")

func test_hades_event_uses_add_relic() -> void:
	print("[TestEvent] test_hades_event_uses_add_relic")
	var pool := _build_pool()
	var found := false
	for e in pool:
		if e.event_name == "하데스의 계약":
			found = true
			var ChoiceRes = load("res://resources/event_choice_resource.gd")
			_assert(e.choices[0].effect_type == ChoiceRes.EffectType.ADD_RELIC, "선택 A: ADD_RELIC")
			_assert(e.choices[0].cost_hp == 30, "cost_hp == 30")
	_assert(found, "하데스의 계약 이벤트 존재")

func test_hermes_event_has_two_choices() -> void:
	print("[TestEvent] test_hermes_event_has_two_choices")
	var pool := _build_pool()
	var found := false
	for e in pool:
		if e.event_name == "헤르메스의 도박":
			found = true
			var ChoiceRes = load("res://resources/event_choice_resource.gd")
			_assert(e.choices.size() == 2, "선택지 2개")
			_assert(e.choices[0].effect_type == ChoiceRes.EffectType.GOLD, "선택 A: GOLD")
			_assert(e.choices[1].effect_type == ChoiceRes.EffectType.REMOVE_CARD, "선택 B: REMOVE_CARD")
	_assert(found, "헤르메스의 도박 이벤트 존재")
```

- [ ] **Step 2: 테스트 실패 확인**

```bash
cd "H:/AIRelatedDefaultPath/ClaudeCode_Base/GameProjects/CardGameProject/stsl" && "H:/Program Files/Godot/Godot_v4.6.2-stable_win64_console.exe" --headless -s tests/test_runner.gd > /tmp/test_out.txt 2>&1; grep -E "FAIL|Results" /tmp/test_out.txt
```

Expected: `FAIL: 이벤트 풀 10종` 포함, failed > 0

- [ ] **Step 3: game_manager.gd 수정**

`autoload/game_manager.gd`의 `_build_event_pool()`에서 `return events` 바로 앞에 5개 이벤트를 추가:

```gdscript
	# 6. 프로메테우스의 불
	var e6: Resource = EventRes.new()
	e6.event_name = "프로메테우스의 불"
	e6.description = "제우스에게 불을 훔친 티탄이 불씨를 건넨다. 받겠는가?"
	var c6a: Resource = ChoiceRes.new(); c6a.label = "불씨를 받는다 (드로우 +1, HP -20)"
	c6a.effect_type = ChoiceRes.EffectType.DRAW_UP; c6a.value = 1; c6a.cost_hp = 20
	var c6b: Resource = ChoiceRes.new(); c6b.label = "거절한다"
	c6b.effect_type = ChoiceRes.EffectType.NONE
	e6.choices = [c6a, c6b]; events.append(e6)

	# 7. 헤라클레스의 시련
	var e7: Resource = EventRes.new()
	e7.event_name = "헤라클레스의 시련"
	e7.description = "헤라클레스가 힘겨루기를 제안한다. 이기면 황금을 준다."
	var c7a: Resource = ChoiceRes.new(); c7a.label = "맞선다 (골드 +60, HP -25)"
	c7a.effect_type = ChoiceRes.EffectType.GOLD; c7a.value = 60; c7a.cost_hp = 25
	var c7b: Resource = ChoiceRes.new(); c7b.label = "포기한다"
	c7b.effect_type = ChoiceRes.EffectType.NONE
	e7.choices = [c7a, c7b]; events.append(e7)

	# 8. 키르케의 마법
	var e8: Resource = EventRes.new()
	e8.event_name = "키르케의 마법"
	e8.description = "마법사 키르케가 황금을 받고 체력을 회복시켜 주겠다고 한다."
	var c8a: Resource = ChoiceRes.new(); c8a.label = "마법을 받는다 (HP +25, 골드 -50)"
	c8a.effect_type = ChoiceRes.EffectType.HEAL; c8a.value = 25; c8a.cost_gold = 50
	var c8b: Resource = ChoiceRes.new(); c8b.label = "거절한다"
	c8b.effect_type = ChoiceRes.EffectType.NONE
	e8.choices = [c8a, c8b]; events.append(e8)

	# 9. 하데스의 계약
	var e9: Resource = EventRes.new()
	e9.event_name = "하데스의 계약"
	e9.description = "저승의 신 하데스가 강력한 유물을 제시한다. 대신 생명력을 요구한다."
	var c9a: Resource = ChoiceRes.new(); c9a.label = "계약한다 (렐릭 획득, HP -30)"
	c9a.effect_type = ChoiceRes.EffectType.ADD_RELIC; c9a.cost_hp = 30
	var c9b: Resource = ChoiceRes.new(); c9b.label = "거절한다"
	c9b.effect_type = ChoiceRes.EffectType.NONE
	e9.choices = [c9a, c9b]; events.append(e9)

	# 10. 헤르메스의 도박
	var e10: Resource = EventRes.new()
	e10.event_name = "헤르메스의 도박"
	e10.description = "교활한 헤르메스가 황금과 덱 경량화 중 하나를 선택하라 한다."
	var c10a: Resource = ChoiceRes.new(); c10a.label = "황금을 받는다 (골드 +50)"
	c10a.effect_type = ChoiceRes.EffectType.GOLD; c10a.value = 50
	var c10b: Resource = ChoiceRes.new(); c10b.label = "덱을 가볍게 한다 (카드 1장 제거)"
	c10b.effect_type = ChoiceRes.EffectType.REMOVE_CARD; c10b.value = 1
	e10.choices = [c10a, c10b]; events.append(e10)
```

- [ ] **Step 4: 테스트 통과 확인**

```bash
cd "H:/AIRelatedDefaultPath/ClaudeCode_Base/GameProjects/CardGameProject/stsl" && "H:/Program Files/Godot/Godot_v4.6.2-stable_win64_console.exe" --headless -s tests/test_runner.gd > /tmp/test_out.txt 2>&1; grep -E "FAIL|Results" /tmp/test_out.txt
```

Expected: `=== Results: 373 passed, 0 failed ===` (기존 357 + 신규 16 assertions)

- [ ] **Step 5: 커밋**

```bash
cd "H:/AIRelatedDefaultPath/ClaudeCode_Base/GameProjects/CardGameProject/stsl" && git add autoload/game_manager.gd tests/test_event.gd && git commit -m "feat: 그리스 신화 이벤트 5종 추가 (프로메테우스·헤라클레스·키르케·하데스·헤르메스)"
```

---

### Task 3: PR 생성

- [ ] **Step 1: push 및 PR 생성**

```bash
cd "H:/AIRelatedDefaultPath/ClaudeCode_Base/GameProjects/CardGameProject/stsl" && git push -u origin feat/plan-22-greek-events
```

GitHub MCP로 PR 생성:
- owner: l980l
- repo: stsl
- title: "feat: Plan 22 — 그리스 신화 이벤트 5종 추가"
- head: feat/plan-22-greek-events
- base: main
- body:
```
## Summary
- EventScene에 ADD_RELIC 이벤트 처리 추가 (기존 누락)
- GOLD 이벤트에 cost_hp 지원 추가
- 그리스 신화 테마 이벤트 5종 추가: 프로메테우스의 불, 헤라클레스의 시련, 키르케의 마법, 하데스의 계약, 헤르메스의 도박
- 이벤트 풀 5종 → 10종

## Test Plan
- [x] 모든 테스트 통과 (0 failed)
- [x] 이벤트 풀 10종 검증
- [x] ADD_RELIC·GOLD cost_hp 구조 검증

🤖 Generated with Claude Code
```
