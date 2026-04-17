# Plan 05: 추가 적 + 보스 페이즈 시스템

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 챕터 1 그리스 신화 적을 완성한다. 일반 적 3종 추가, 엘리트 적 2종 추가, 히드라 보스(페이즈 시스템) 구현. GameManager에서 층/룸 타입에 따라 적을 랜덤 선택하도록 개선.

**Architecture:**
- 적 데이터는 GDScript로 하드코딩 (GameManager._make_enemies_for_node 확장)
- 보스 페이즈는 BattleManager에 `phase_thresholds` 체크 로직 추가
- 엘리트/보스 룸에서 GameManager가 적 조합 결정
- 기존 사티로스 씬을 모든 적이 공유 (ColorRect 색상으로 구분)

**Tech Stack:** Godot 4.6, GDScript, 헤드리스 테스트 (기존 73개 + 신규 ~8개 → ~81개)

---

## 브랜치

```bash
git checkout -b feat/plan-05-enemies-boss
```

---

## 파일 구조

```
autoload/
  game_manager.gd      ← (수정) _make_enemies_for_node + 층별 적 풀
  battle_manager.gd    ← (수정) 페이즈 전환 + 페이즈별 intent_pattern
tests/
  test_enemies.gd      ← (신규) 적 생성 + 보스 페이즈 테스트 ~8개
  test_runner.gd       ← (수정) TestEnemies 추가
```

---

## 적 목록 (챕터 1 그리스 신화)

### 일반 적 (GameManager._make_normal_enemies)

| 이름 | HP | 패턴 |
|------|-----|------|
| 사티로스 | 30 | ATTACK(6) → ATTACK(6) → BUFF(5) 반복 |
| 하르피아 | 25 | ATTACK(4) → ATTACK(4) → DEBUFF(discard 1) 반복 |
| 사이클롭스 | 45 | BUFF(0/준비) → ATTACK(18) 반복 |
| 메두사의 뱀 | 20 | ATTACK(5)+DEBUFF(vulnerable 1) 반복 |

> `discard` 의도는 IntentResource.ActionType.SPECIAL로 표현, BattleManager에서 DeckManager.discard_random() 호출

### 엘리트 적 (GameManager._make_elite_enemies)

| 이름 | HP | 패턴 |
|------|-----|------|
| 미노타우로스 | 90 | ATTACK(12) → ATTACK(12) → ATTACK(20, ALL) 반복 |
| 메두사 | 75 | ATTACK(10)+DEBUFF(weak 2) → DEBUFF(vulnerable 2) → ATTACK(15) 반복 |

### 보스 (GameManager._make_boss_enemies)

| 이름 | HP | 페이즈 |
|------|-----|--------|
| 히드라 | 200 | 페이즈 1(100%~60%): ATTACK(10)×2 반복<br>페이즈 2(60%~30%): ATTACK(12)×3 반복<br>페이즈 3(30%~0%): ATTACK(12)×3 + BUFF(10) 반복 |

---

## Task 1: 일반 적 3종 추가 + GameManager 층별 랜덤 선택

- [ ] **Step 1: game_manager.gd — _make_normal_enemies() 구현**

`_make_satyr` 방식으로 하르피아, 사이클롭스, 메두사의 뱀 빌더 추가.
`_make_enemies_for_node`의 BATTLE 케이스에서 `_make_normal_enemies()`를 호출해 랜덤 1종 반환.

```gdscript
func _make_normal_enemies() -> Array:
    var pool := [
        _make_satyr(_satyr_scene(), 30, 6),
        _make_harpy(_satyr_scene(), 25),
        _make_cyclops(_satyr_scene(), 45),
        _make_snake(_satyr_scene(), 20),
    ]
    return [pool[randi() % pool.size()]]

func _make_harpy(scene: PackedScene, hp: int) -> Resource:
    var EnemyRes = load("res://resources/enemy_resource.gd")
    var IntentRes = load("res://resources/intent_resource.gd")
    var enemy := EnemyRes.new()
    enemy.enemy_name = "하르피아"
    enemy.max_hp = hp
    enemy.character_scene = scene
    # ATTACK(4) → ATTACK(4) → SPECIAL(discard)
    var a1 := IntentRes.new(); a1.action_type = IntentRes.ActionType.ATTACK
    a1.value = 4; a1.target = IntentRes.TargetType.RANDOM
    var a2 := IntentRes.new(); a2.action_type = IntentRes.ActionType.ATTACK
    a2.value = 4; a2.target = IntentRes.TargetType.RANDOM
    var sp := IntentRes.new(); sp.action_type = IntentRes.ActionType.SPECIAL
    sp.value = 1  # discard 1장
    enemy.intent_pattern = [a1, a2, sp]
    return enemy

func _make_cyclops(scene: PackedScene, hp: int) -> Resource:
    var EnemyRes = load("res://resources/enemy_resource.gd")
    var IntentRes = load("res://resources/intent_resource.gd")
    var enemy := EnemyRes.new()
    enemy.enemy_name = "사이클롭스"
    enemy.max_hp = hp
    enemy.character_scene = scene
    # BUFF(0/준비) → ATTACK(18)
    var prep := IntentRes.new(); prep.action_type = IntentRes.ActionType.BUFF
    prep.value = 0  # 준비 행동 (블록 0)
    var atk := IntentRes.new(); atk.action_type = IntentRes.ActionType.ATTACK
    atk.value = 18; atk.target = IntentRes.TargetType.RANDOM
    enemy.intent_pattern = [prep, atk]
    return enemy

func _make_snake(scene: PackedScene, hp: int) -> Resource:
    var EnemyRes = load("res://resources/enemy_resource.gd")
    var IntentRes = load("res://resources/intent_resource.gd")
    var enemy := EnemyRes.new()
    enemy.enemy_name = "메두사의 뱀"
    enemy.max_hp = hp
    enemy.character_scene = scene
    # ATTACK(5) + DEBUFF(vulnerable 1)
    var atk := IntentRes.new(); atk.action_type = IntentRes.ActionType.ATTACK
    atk.value = 5; atk.target = IntentRes.TargetType.RANDOM
    var deb := IntentRes.new(); deb.action_type = IntentRes.ActionType.DEBUFF
    deb.value = 1  # vulnerable 1
    enemy.intent_pattern = [atk, deb]
    return enemy

func _satyr_scene() -> PackedScene:
    return load("res://characters/enemies/satyr/satyr.tscn")
```

- [ ] **Step 2: BattleManager — SPECIAL(discard) 처리**

`_execute_intent`의 SPECIAL 케이스에 `deck_mgr.discard_random(intent.value)` 호출 추가.
`DeckManager`에 `discard_random(n: int)` 메서드 추가 (hand에서 랜덤 n장 버림).

```gdscript
# deck_manager.gd에 추가
func discard_random(n: int) -> void:
    for _i in range(min(n, hand.size())):
        var idx := randi() % hand.size()
        discard_pile.append(hand[idx])
        hand.remove_at(idx)
    hand_changed.emit(hand.duplicate())
```

- [ ] **Step 3: test_enemies.gd 작성**

```gdscript
# tests/test_enemies.gd
class_name TestEnemies
extends RefCounted

const GameManagerClass = preload("res://autoload/game_manager.gd")

var passed: int = 0
var failed: int = 0

func run_all() -> Dictionary:
    test_normal_enemy_variety()
    test_elite_enemy_count()
    test_harpy_pattern_length()
    test_cyclops_first_intent_is_buff()
    return {"passed": passed, "failed": failed}

func _assert(cond: bool, msg: String) -> void:
    if cond: passed += 1
    else:
        failed += 1
        push_error("  FAIL: " + msg)
    if cond: print("  PASS: " + msg)

func _make_gm() -> GameManagerClass:
    var gm := GameManagerClass.new()
    gm.run_map = preload("res://autoload/map_generator.gd").generate()
    gm.available_node_ids = [0, 1, 2]
    gm.current_node_id = -1
    gm.pending_enemies = []
    gm.card_rewards = []
    return gm

func test_normal_enemy_variety() -> void:
    print("[TestEnemies] test_normal_enemy_variety")
    var gm := _make_gm()
    var seen := {}
    for _i in range(20):
        var enemies := gm._make_normal_enemies()
        seen[enemies[0].enemy_name] = true
    # 20번 중 적어도 2종 이상 등장해야 함
    _assert(seen.size() >= 2, "랜덤 일반 적 — 20회 중 2종 이상 등장")

func test_elite_enemy_count() -> void:
    print("[TestEnemies] test_elite_enemy_count")
    var gm := _make_gm()
    var enemies := gm._make_elite_enemies()
    _assert(enemies.size() >= 1, "엘리트 룸 적 1마리 이상")
    _assert(enemies[0].max_hp >= 60, "엘리트 HP >= 60")

func test_harpy_pattern_length() -> void:
    print("[TestEnemies] test_harpy_pattern_length")
    var gm := _make_gm()
    var harpy := gm._make_harpy(gm._satyr_scene(), 25)
    _assert(harpy.intent_pattern.size() == 3, "하르피아 패턴 3개")

func test_cyclops_first_intent_is_buff() -> void:
    print("[TestEnemies] test_cyclops_first_intent_is_buff")
    var gm := _make_gm()
    var IntentRes = load("res://resources/intent_resource.gd")
    var cyclops := gm._make_cyclops(gm._satyr_scene(), 45)
    _assert(cyclops.intent_pattern[0].action_type == IntentRes.ActionType.BUFF,
        "사이클롭스 첫 행동 = BUFF(준비)")
```

- [ ] **Step 4: test_runner.gd에 TestEnemies 추가**

```gdscript
var TestEnemies = preload("res://tests/test_enemies.gd")
# suites 배열에 TestEnemies.new() 추가
```

- [ ] **Step 5: 테스트 실행 (실패 확인)**

- [ ] **Step 6: 구현 완료 후 테스트 통과 확인**

---

## Task 2: 엘리트 적 2종 추가

- [ ] **Step 1: _make_elite_enemies() 구현**

```gdscript
func _make_elite_enemies() -> Array:
    if randi() % 2 == 0:
        return [_make_minotaur(_satyr_scene())]
    else:
        return [_make_medusa(_satyr_scene())]

func _make_minotaur(scene: PackedScene) -> Resource:
    var EnemyRes = load("res://resources/enemy_resource.gd")
    var IntentRes = load("res://resources/intent_resource.gd")
    var enemy := EnemyRes.new()
    enemy.enemy_name = "미노타우로스"
    enemy.max_hp = 90
    enemy.character_scene = scene
    var a1 := IntentRes.new(); a1.action_type = IntentRes.ActionType.ATTACK
    a1.value = 12; a1.target = IntentRes.TargetType.RANDOM
    var a2 := IntentRes.new(); a2.action_type = IntentRes.ActionType.ATTACK
    a2.value = 12; a2.target = IntentRes.TargetType.RANDOM
    var a3 := IntentRes.new(); a3.action_type = IntentRes.ActionType.ATTACK
    a3.value = 20; a3.target = IntentRes.TargetType.ALL
    enemy.intent_pattern = [a1, a2, a3]
    return enemy

func _make_medusa(scene: PackedScene) -> Resource:
    var EnemyRes = load("res://resources/enemy_resource.gd")
    var IntentRes = load("res://resources/intent_resource.gd")
    var enemy := EnemyRes.new()
    enemy.enemy_name = "메두사"
    enemy.max_hp = 75
    enemy.character_scene = scene
    var a1 := IntentRes.new(); a1.action_type = IntentRes.ActionType.ATTACK
    a1.value = 10; a1.target = IntentRes.TargetType.RANDOM
    var d1 := IntentRes.new(); d1.action_type = IntentRes.ActionType.DEBUFF
    d1.value = 2  # weak 2
    var d2 := IntentRes.new(); d2.action_type = IntentRes.ActionType.DEBUFF
    d2.value = 2  # vulnerable 2 (target 구분은 DEBUFF 처리에서 status_type으로)
    var a2 := IntentRes.new(); a2.action_type = IntentRes.ActionType.ATTACK
    a2.value = 15; a2.target = IntentRes.TargetType.RANDOM
    enemy.intent_pattern = [a1, d1, d2, a2]
    return enemy
```

> **Note:** `_execute_intent`의 DEBUFF는 현재 `weak`만 부여. `vulnerable` 부여도 지원하도록 `IntentResource`에 `status_type: String` 필드 추가.

- [ ] **Step 2: IntentResource에 status_type 필드 추가**

```gdscript
# resources/intent_resource.gd에 추가
@export var status_type: String = "weak"  # DEBUFF 시 부여할 상태이상 키
```

- [ ] **Step 3: BattleManager._execute_intent DEBUFF 처리 개선**

```gdscript
IntentRes.ActionType.DEBUFF:
    var target_id: String = _pick_hero_target(intent.target, enemy_index)
    if target_id != "":
        var stype := intent.status_type if intent.status_type != "" else "weak"
        _apply_status_to_hero(target_id, stype, intent.value)
```

- [ ] **Step 4: 기존 IntentResource 생성 코드에 status_type 기본값 확인**

기존 `_make_satyr`에서 생성한 DEBUFF intent는 status_type 기본값 "weak" 사용 → 별도 수정 불필요.

- [ ] **Step 5: 테스트 추가 및 통과 확인**

```gdscript
func test_elite_medusa_pattern() -> void:
    var gm := _make_gm()
    var medusa := gm._make_medusa(gm._satyr_scene())
    _assert(medusa.intent_pattern.size() == 4, "메두사 패턴 4개")
    _assert(medusa.max_hp == 75, "메두사 HP = 75")
```

---

## Task 3: 히드라 보스 + 페이즈 시스템

- [ ] **Step 1: EnemyResource에 phase_thresholds 필드 추가**

```gdscript
# resources/enemy_resource.gd에 추가
@export var phase_thresholds: Array = []   # HP 비율 기준 [0.6, 0.3]
@export var phase_patterns: Array = []     # Array[Array[IntentResource]] — 페이즈별 패턴
```

- [ ] **Step 2: BattleManager — 페이즈 전환 로직 추가**

`_deal_damage_to_enemy` 호출 후 `_check_phase_transition(enemy_index)` 호출.

```gdscript
func _check_phase_transition(enemy_index: int) -> void:
    var enemy: Resource = _enemies[enemy_index]
    if enemy.phase_thresholds.is_empty():
        return
    var hp_ratio: float = float(_enemy_hp[enemy_index]) / float(enemy.max_hp)
    # 현재 페이즈 = 이미 넘어간 임계값 수 (저장: _enemy_phase)
    var current_phase: int = _enemy_phase[enemy_index]
    if current_phase < enemy.phase_thresholds.size():
        if hp_ratio <= enemy.phase_thresholds[current_phase]:
            _enemy_phase[enemy_index] += 1
            _enemy_intent_index[enemy_index] = 0
            # 페이즈 전환 시 패턴 교체는 get_current_intent에서 처리

# 변수 추가
var _enemy_phase: Array = []

# setup_battle에 추가
_enemy_phase.clear()
for enemy in _enemies:
    _enemy_phase.append(0)

# clear()에도 추가
_enemy_phase.clear()

# get_enemy_current_intent 수정
func get_enemy_current_intent(index: int) -> Resource:
    if index < 0 or index >= _enemies.size():
        return null
    var enemy: Resource = _enemies[index]
    var pattern: Array = _get_active_pattern(index)
    if pattern.is_empty():
        return null
    return pattern[_enemy_intent_index[index]]

func _get_active_pattern(enemy_index: int) -> Array:
    var enemy: Resource = _enemies[enemy_index]
    var phase: int = _enemy_phase[enemy_index]
    if not enemy.phase_patterns.is_empty() and phase < enemy.phase_patterns.size():
        return enemy.phase_patterns[phase]
    return enemy.intent_pattern  # 페이즈 없거나 초과 시 기본 패턴
```

- [ ] **Step 3: _execute_enemy_turn에서 _get_active_pattern 사용**

```gdscript
# 기존: var pattern: Array = _enemies[i].intent_pattern
# 변경: var pattern: Array = _get_active_pattern(i)
```

`_deal_damage_to_enemy` 마지막에 `_check_phase_transition(enemy_index)` 추가.

- [ ] **Step 4: GameManager._make_boss_enemies() 구현**

```gdscript
func _make_boss_enemies() -> Array:
    var EnemyRes = load("res://resources/enemy_resource.gd")
    var IntentRes = load("res://resources/intent_resource.gd")
    var scene = _satyr_scene()
    var hydra := EnemyRes.new()
    hydra.enemy_name = "히드라"
    hydra.max_hp = 200
    hydra.character_scene = scene
    hydra.phase_thresholds = [0.6, 0.3]

    # 페이즈 0 (100%~60%): ATTACK(10) × 2
    var p0a1 := IntentRes.new(); p0a1.action_type = IntentRes.ActionType.ATTACK
    p0a1.value = 10; p0a1.target = IntentRes.TargetType.RANDOM
    var p0a2 := IntentRes.new(); p0a2.action_type = IntentRes.ActionType.ATTACK
    p0a2.value = 10; p0a2.target = IntentRes.TargetType.RANDOM

    # 페이즈 1 (60%~30%): ATTACK(12) × 3
    var p1a1 := IntentRes.new(); p1a1.action_type = IntentRes.ActionType.ATTACK
    p1a1.value = 12; p1a1.target = IntentRes.TargetType.RANDOM
    var p1a2 := IntentRes.new(); p1a2.action_type = IntentRes.ActionType.ATTACK
    p1a2.value = 12; p1a2.target = IntentRes.TargetType.RANDOM
    var p1a3 := IntentRes.new(); p1a3.action_type = IntentRes.ActionType.ATTACK
    p1a3.value = 12; p1a3.target = IntentRes.TargetType.LOWEST_HP

    # 페이즈 2 (30%~0%): ATTACK(12) × 3 + BUFF(10)
    var p2a1 := IntentRes.new(); p2a1.action_type = IntentRes.ActionType.ATTACK
    p2a1.value = 12; p2a1.target = IntentRes.TargetType.RANDOM
    var p2a2 := IntentRes.new(); p2a2.action_type = IntentRes.ActionType.ATTACK
    p2a2.value = 12; p2a2.target = IntentRes.TargetType.RANDOM
    var p2a3 := IntentRes.new(); p2a3.action_type = IntentRes.ActionType.ATTACK
    p2a3.value = 12; p2a3.target = IntentRes.TargetType.LOWEST_HP
    var p2b := IntentRes.new(); p2b.action_type = IntentRes.ActionType.BUFF
    p2b.value = 10

    hydra.phase_patterns = [[p0a1, p0a2], [p1a1, p1a2, p1a3], [p2a1, p2a2, p2a3, p2b]]
    hydra.intent_pattern = hydra.phase_patterns[0]
    return [hydra]
```

- [ ] **Step 5: GameManager._make_enemies_for_node() 업데이트**

```gdscript
func _make_enemies_for_node(node: MapNodeResource) -> Array:
    match node.room_type:
        MapNodeResource.RoomType.BATTLE:
            return _make_normal_enemies()
        MapNodeResource.RoomType.ELITE:
            return _make_elite_enemies()
        MapNodeResource.RoomType.BOSS:
            return _make_boss_enemies()
        _:
            return []
```

- [ ] **Step 6: 보스 페이즈 테스트 추가**

```gdscript
func test_hydra_phase_transition() -> void:
    print("[TestEnemies] test_hydra_phase_transition")
    var gm := _make_gm()
    var BM = load("res://autoload/battle_manager.gd")
    var bm := BM.new()
    var TM = load("res://autoload/team_manager.gd")
    var tm := TM.new()
    var HeroRes = load("res://resources/hero_resource.gd")
    var hero := HeroRes.new()
    hero.hero_id = "napoleon"; hero.max_hp = 70; hero.hero_name = "나폴레옹"
    tm.add_hero(hero)
    bm.team_mgr = tm
    var enemies := gm._make_boss_enemies()
    bm.setup_battle(enemies)
    _assert(bm._enemy_phase[0] == 0, "보스 초기 페이즈 = 0")
    # HP를 60% 이하로 강제
    bm._enemy_hp[0] = int(enemies[0].max_hp * 0.59)
    bm._check_phase_transition(0)
    _assert(bm._enemy_phase[0] == 1, "HP 59% → 페이즈 1로 전환")

func test_hydra_phase2_transition() -> void:
    print("[TestEnemies] test_hydra_phase2_transition")
    var gm := _make_gm()
    var BM = load("res://autoload/battle_manager.gd")
    var bm := BM.new()
    var TM = load("res://autoload/team_manager.gd")
    var tm := TM.new()
    var HeroRes = load("res://resources/hero_resource.gd")
    var hero := HeroRes.new()
    hero.hero_id = "napoleon"; hero.max_hp = 70; hero.hero_name = "나폴레옹"
    tm.add_hero(hero)
    bm.team_mgr = tm
    var enemies := gm._make_boss_enemies()
    bm.setup_battle(enemies)
    bm._enemy_hp[0] = int(enemies[0].max_hp * 0.59)
    bm._check_phase_transition(0)
    bm._enemy_hp[0] = int(enemies[0].max_hp * 0.29)
    bm._check_phase_transition(0)
    _assert(bm._enemy_phase[0] == 2, "HP 29% → 페이즈 2로 전환")
```

- [ ] **Step 7: 전체 테스트 실행 및 통과 확인**

예상: `=== Results: ~81 passed, 0 failed ===`

- [ ] **Step 8: 커밋**

```bash
git add autoload/game_manager.gd autoload/battle_manager.gd \
        resources/enemy_resource.gd resources/intent_resource.gd \
        tests/test_enemies.gd tests/test_runner.gd
git commit -m "feat: Plan 05 — 추가 적 6종 + 히드라 보스 페이즈 시스템"
```
