# Plan 02: 전투 로직 (BattleManager) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 카드 플레이, 상태이상, 적 턴 실행, 승/패 판정을 담당하는 BattleManager Autoload를 구현한다.

**Architecture:** BattleManager는 Node Autoload로 등록되며, TeamManager(HP/생사)와 DeckManager(덱/에너지)에 의존한다. 테스트 가능성을 위해 두 의존성을 외부에서 주입(team_mgr, deck_mgr 변수)한다. UI는 이 플랜에서 구현하지 않으며, 전투 로직만 헤드리스 테스트로 검증한다.

**Tech Stack:** Godot 4.6, GDScript (타입 힌트 명시), 헤드리스 테스트 (`godot --headless -s`)

---

## 파일 구조

```
stsl/
  autoload/
    battle_manager.gd    ← 전투 상태 관리, 카드 효과 적용, 적 턴 실행, 승/패 판정
  tests/
    test_battle_manager.gd  ← BattleManager 헤드리스 테스트 (13개)
  tests/
    test_runner.gd       ← TestBattleManager 추가 (기존 파일 수정)
  project.godot          ← BattleManager Autoload 등록 (기존 파일 수정)
```

---

## 턴 흐름 설계

```
start_player_turn()
  → 영웅 블록 초기화, 영웅 독 틱
  → DeckManager.start_turn() (5장 드로우, 에너지 3 충전)

play_card(card, target_enemy_index)
  → DeckManager.play_card() (에너지 차감, 손패→버림)
  → _apply_card_effects() (피해/블록/상태이상/드로우/에너지/회복)

end_player_turn()
  → DeckManager.discard_hand()
  → _execute_enemy_turn()

_execute_enemy_turn()
  → 각 적: 블록 초기화, 독 틱, 현재 의도 실행, 의도 인덱스 순환
  → _check_win_condition() / _check_lose_condition()
```

## 상태이상 처리 규칙

| 상태         | 효과                                  | 감소 시점                       |
| ---------- | ----------------------------------- | --------------------------- |
| BLOCK      | 피해 흡수 (HP 이전)                       | 각 유닛의 턴 시작 시 0으로 초기화        |
| POISON     | 턴 시작 시 스택 수만큼 HP 감소                 | 틱마다 1 감소                    |
| WEAK       | 공격자 피해 25% 감소 (`int(value * 0.75)`) | 별도 감소 없음 (이 플랜에서는 스택 소모 없음) |
| VULNERABLE | 피해 50% 증가 (`int(value * 1.5)`)      | 별도 감소 없음 (이 플랜에서는 스택 소모 없음) |

---

## Task 1: BattleManager 기반 + setup_battle

**Files**:
- Create: `tests/test_battle_manager.gd`
- Create: `autoload/battle_manager.gd`

### Step 1: 테스트 파일 생성 (setup_battle 테스트만)

```gdscript
# tests/test_battle_manager.gd
class_name TestBattleManager
extends RefCounted

const BattleManagerClass = preload("res://autoload/battle_manager.gd")
const TeamManagerClass = preload("res://autoload/team_manager.gd")
const DeckManagerClass = preload("res://autoload/deck_manager.gd")
const EffectRes = preload("res://resources/effect_resource.gd")
const CardRes = preload("res://resources/card_resource.gd")
const HeroRes = preload("res://resources/hero_resource.gd")
const EnemyRes = preload("res://resources/enemy_resource.gd")
const IntentRes = preload("res://resources/intent_resource.gd")

var passed: int = 0
var failed: int = 0

func run_all() -> Dictionary:
    test_setup_battle()
    return { "passed": passed, "failed": failed }

func _assert(condition: bool, msg: String) -> void:
    if condition:
        print("  PASS: " + msg)
        passed += 1
    else:
        print("  FAIL: " + msg)
        failed += 1

# 헬퍼: BattleManager + 의존성 생성
func _make_bm() -> BattleManagerClass:
    var bm := BattleManagerClass.new()
    bm.team_mgr = TeamManagerClass.new()
    bm.deck_mgr = DeckManagerClass.new()
    return bm

func _make_hero(id: String, hp: int) -> Resource:
    var h := HeroRes.new()
    h.hero_id = id
    h.max_hp = hp
    return h

func _make_enemy(hp: int, intents: Array) -> Resource:
    var e := EnemyRes.new()
    e.max_hp = hp
    e.intent_pattern = intents
    return e

func _make_intent(action_type: int, value: int, target: int) -> Resource:
    var i := IntentRes.new()
    i.action_type = action_type
    i.value = value
    i.target = target
    return i

func _make_card(owner_id: String, cost: int, effects: Array) -> Resource:
    var c := CardRes.new()
    c.owner_id = owner_id
    c.cost = cost
    c.effects = effects
    return c

func _make_effect(effect_type: int, value: int, target: String) -> Resource:
    var e := EffectRes.new()
    e.effect_type = effect_type
    e.value = value
    e.target = target
    return e

# --- 테스트 ---

func test_setup_battle() -> void:
    print("[TestBattleManager] test_setup_battle")
    var bm := _make_bm()
    var enemy := _make_enemy(30, [])
    bm.setup_battle([enemy])
    _assert(bm.get_enemy_hp(0) == 30, "적 HP == max_hp(30)")
    _assert(bm.is_enemy_alive(0), "셋업 후 적 생존")
    _assert(bm.is_battle_active, "배틀 활성")
    _assert(bm.get_enemy_block(0) == 0, "초기 블록 0")
```

- [ ] **Step 2: 테스트 실행 — 실패 확인 (파일 없음)**

```bash
"H:/Program Files/Godot/Godot_v4.6.2-stable_win64_console.exe" --headless -s "H:/AIRelatedDefaultPath/ClaudeCode_Base/GameProjects/CardGameProject/stsl/tests/test_runner.gd" --path "H:/AIRelatedDefaultPath/ClaudeCode_Base/GameProjects/CardGameProject/stsl"
```

예상: `preload` 오류 또는 test_runner에 TestBattleManager가 없어 실행 안 됨.

- [ ] **Step 3: BattleManager 전체 구현 (battle_manager.gd 생성)**

```gdscript
# autoload/battle_manager.gd
class_name BattleManagerClass
extends Node

const EffectRes = preload("res://resources/effect_resource.gd")
const IntentRes = preload("res://resources/intent_resource.gd")

# 의존성 주입 — 프로덕션: BattleScene이 설정, 테스트: 직접 할당
var team_mgr = null
var deck_mgr = null

# 배틀 상태
var is_battle_active: bool = false
var is_player_turn: bool = false

# 적 상태
var _enemies: Array = []
var _enemy_hp: Array = []
var _enemy_alive: Array = []
var _enemy_block: Array = []
var _enemy_status: Array = []      # Array[Dictionary] {"poison":n, "weak":n, ...}
var _enemy_intent_index: Array = []
var _last_attacker: Dictionary = {}  # enemy_index → hero_id

# 영웅 상태 (HP는 TeamManager가 관리)
var _hero_block: Dictionary = {}   # hero_id → int
var _hero_status: Dictionary = {}  # hero_id → Dictionary

signal battle_started()
signal battle_won()
signal battle_lost()
signal player_turn_started()
signal enemy_turn_started()
signal enemy_died(enemy_index: int)
signal enemy_damaged(enemy_index: int, amount: int)
signal hero_damaged(hero_id: String, amount: int)
signal status_applied(target: String, status_type: String, stacks: int)

# ──────────────────────────────────────────────
# 공개 API
# ──────────────────────────────────────────────

func setup_battle(enemies: Array) -> void:
    _enemies = enemies.duplicate()
    _enemy_hp.clear()
    _enemy_alive.clear()
    _enemy_block.clear()
    _enemy_status.clear()
    _enemy_intent_index.clear()
    _hero_block.clear()
    _hero_status.clear()
    _last_attacker.clear()
    for enemy in _enemies:
        _enemy_hp.append(enemy.max_hp)
        _enemy_alive.append(true)
        _enemy_block.append(0)
        _enemy_status.append({})
        _enemy_intent_index.append(0)
    is_battle_active = true
    battle_started.emit()

func start_player_turn() -> void:
    if not is_battle_active:
        return
    is_player_turn = true
    # 영웅 블록 초기화 & 독 틱
    if team_mgr:
        for hero in team_mgr.heroes:
            _hero_block[hero.hero_id] = 0
            _tick_hero_poison(hero.hero_id)
    if deck_mgr:
        deck_mgr.start_turn()
    player_turn_started.emit()

func play_card(card: Resource, target_enemy_index: int) -> bool:
    if not is_player_turn or not is_battle_active:
        return false
    if deck_mgr == null or not deck_mgr.play_card(card):
        return false
    _apply_card_effects(card, target_enemy_index)
    return true

func end_player_turn() -> void:
    if not is_player_turn or not is_battle_active:
        return
    is_player_turn = false
    if deck_mgr:
        deck_mgr.discard_hand()
    _execute_enemy_turn()

# ──────────────────────────────────────────────
# 카드 효과 적용
# ──────────────────────────────────────────────

func _apply_card_effects(card: Resource, target_enemy_index: int) -> void:
    for effect in card.effects:
        match effect.effect_type:
            EffectRes.EffectType.DAMAGE:
                var dmg: int = effect.value
                # weak: 카드 소유 영웅이 약화 상태면 피해 25% 감소
                var owner_status: Dictionary = _hero_status.get(card.owner_id, {})
                if owner_status.get("weak", 0) > 0:
                    dmg = int(dmg * 0.75)
                if effect.target == "ALL":
                    for i in range(_enemies.size()):
                        if _enemy_alive[i]:
                            _deal_damage_to_enemy(i, dmg)
                            _last_attacker[i] = card.owner_id
                else:  # SINGLE
                    if target_enemy_index >= 0 and target_enemy_index < _enemies.size():
                        _deal_damage_to_enemy(target_enemy_index, dmg)
                        _last_attacker[target_enemy_index] = card.owner_id
            EffectRes.EffectType.BLOCK:
                _hero_block[card.owner_id] = _hero_block.get(card.owner_id, 0) + effect.value
            EffectRes.EffectType.APPLY_STATUS:
                if effect.target == "ALL":
                    for i in range(_enemies.size()):
                        if _enemy_alive[i]:
                            _apply_status_to_enemy(i, effect.status_type, effect.value)
                elif effect.target == "SELF":
                    _apply_status_to_hero(card.owner_id, effect.status_type, effect.value)
                else:  # SINGLE
                    if target_enemy_index >= 0 and target_enemy_index < _enemies.size():
                        _apply_status_to_enemy(target_enemy_index, effect.status_type, effect.value)
            EffectRes.EffectType.DRAW:
                if deck_mgr:
                    deck_mgr.draw_cards(effect.value)
            EffectRes.EffectType.ENERGY:
                if deck_mgr:
                    deck_mgr.current_energy += effect.value
                    deck_mgr.energy_changed.emit(deck_mgr.current_energy)
            EffectRes.EffectType.HEAL:
                if team_mgr:
                    team_mgr.heal(card.owner_id, effect.value)

# ──────────────────────────────────────────────
# 피해 처리
# ──────────────────────────────────────────────

func _deal_damage_to_enemy(enemy_index: int, amount: int) -> void:
    if not _enemy_alive[enemy_index]:
        return
    # vulnerable: 취약 상태면 피해 50% 증가
    if _enemy_status[enemy_index].get("vulnerable", 0) > 0:
        amount = int(amount * 1.5)
    # 블록 흡수
    var absorbed: int = min(_enemy_block[enemy_index], amount)
    _enemy_block[enemy_index] -= absorbed
    amount -= absorbed
    _enemy_hp[enemy_index] = max(0, _enemy_hp[enemy_index] - amount)
    enemy_damaged.emit(enemy_index, amount)
    if _enemy_hp[enemy_index] == 0:
        _enemy_alive[enemy_index] = false
        enemy_died.emit(enemy_index)
    _check_win_condition()

func _deal_damage_to_hero(hero_id: String, amount: int) -> void:
    if team_mgr == null or not team_mgr.is_alive(hero_id):
        return
    # vulnerable
    var status: Dictionary = _hero_status.get(hero_id, {})
    if status.get("vulnerable", 0) > 0:
        amount = int(amount * 1.5)
    # 블록 흡수
    var block: int = _hero_block.get(hero_id, 0)
    var absorbed: int = min(block, amount)
    _hero_block[hero_id] = block - absorbed
    amount -= absorbed
    if amount > 0:
        team_mgr.take_damage(hero_id, amount)
    hero_damaged.emit(hero_id, amount)
    _check_lose_condition()

# ──────────────────────────────────────────────
# 상태이상
# ──────────────────────────────────────────────

func _apply_status_to_enemy(enemy_index: int, status_type: String, stacks: int) -> void:
    _enemy_status[enemy_index][status_type] = \
        _enemy_status[enemy_index].get(status_type, 0) + stacks
    status_applied.emit("enemy_%d" % enemy_index, status_type, stacks)

func _apply_status_to_hero(hero_id: String, status_type: String, stacks: int) -> void:
    if not _hero_status.has(hero_id):
        _hero_status[hero_id] = {}
    _hero_status[hero_id][status_type] = _hero_status[hero_id].get(status_type, 0) + stacks
    status_applied.emit(hero_id, status_type, stacks)

func _tick_hero_poison(hero_id: String) -> void:
    var status: Dictionary = _hero_status.get(hero_id, {})
    var poison: int = status.get("poison", 0)
    if poison <= 0:
        return
    team_mgr.take_damage(hero_id, poison)   # 블록 우회, HP 직접 감소
    _hero_status[hero_id]["poison"] = max(0, poison - 1)

func _tick_enemy_poison(enemy_index: int) -> void:
    var poison: int = _enemy_status[enemy_index].get("poison", 0)
    if poison <= 0:
        return
    _enemy_hp[enemy_index] = max(0, _enemy_hp[enemy_index] - poison)
    enemy_damaged.emit(enemy_index, poison)
    _enemy_status[enemy_index]["poison"] = poison - 1
    if _enemy_hp[enemy_index] == 0:
        _enemy_alive[enemy_index] = false
        enemy_died.emit(enemy_index)

# ──────────────────────────────────────────────
# 적 턴
# ──────────────────────────────────────────────

func _execute_enemy_turn() -> void:
    enemy_turn_started.emit()
    for i in range(_enemies.size()):
        if not _enemy_alive[i]:
            continue
        _enemy_block[i] = 0            # 적 블록 초기화
        _tick_enemy_poison(i)
        if not _enemy_alive[i]:        # 독으로 사망
            continue
        var pattern: Array = _enemies[i].intent_pattern
        if pattern.is_empty():
            continue
        var intent: Resource = pattern[_enemy_intent_index[i]]
        _execute_intent(i, intent)
        _enemy_intent_index[i] = (_enemy_intent_index[i] + 1) % pattern.size()
    _check_win_condition()
    _check_lose_condition()

func _execute_intent(enemy_index: int, intent: Resource) -> void:
    match intent.action_type:
        IntentRes.ActionType.ATTACK:
            var target_id: String = _pick_hero_target(intent.target, enemy_index)
            if target_id != "":
                var dmg: int = intent.value
                # weak: 해당 적이 weak 상태면 피해 25% 감소
                if _enemy_status[enemy_index].get("weak", 0) > 0:
                    dmg = int(dmg * 0.75)
                _deal_damage_to_hero(target_id, dmg)
        IntentRes.ActionType.BUFF:
            _enemy_block[enemy_index] += intent.value
        IntentRes.ActionType.DEBUFF:
            var target_id: String = _pick_hero_target(intent.target, enemy_index)
            if target_id != "":
                _apply_status_to_hero(target_id, "weak", intent.value)
        IntentRes.ActionType.SPECIAL:
            pass  # MVP 미사용

func _pick_hero_target(target_type: int, enemy_index: int) -> String:
    if team_mgr == null:
        return ""
    var living: Array = team_mgr.get_living_heroes()
    if living.is_empty():
        return ""
    match target_type:
        IntentRes.TargetType.RANDOM:
            return living[randi() % living.size()].hero_id
        IntentRes.TargetType.LOWEST_HP:
            var lowest: Resource = living[0]
            for hero in living:
                if team_mgr.get_current_hp(hero.hero_id) < team_mgr.get_current_hp(lowest.hero_id):
                    lowest = hero
            return lowest.hero_id
        IntentRes.TargetType.LAST_ATTACKER:
            var last_id: String = _last_attacker.get(enemy_index, "")
            if last_id != "" and team_mgr.is_alive(last_id):
                return last_id
            return living[randi() % living.size()].hero_id
        IntentRes.TargetType.ALL:
            # ALL 타겟은 _execute_intent 호출 전에 별도 루프로 처리해야 함
            # 현재는 첫 번째 생존 영웅만 타겟 (MVP 단순화)
            return living[0].hero_id
    return ""

# ──────────────────────────────────────────────
# 승/패 판정
# ──────────────────────────────────────────────

func _check_win_condition() -> void:
    if not is_battle_active:
        return
    for alive in _enemy_alive:
        if alive:
            return
    is_battle_active = false
    battle_won.emit()

func _check_lose_condition() -> void:
    if not is_battle_active:
        return
    if team_mgr == null:
        return
    if team_mgr.get_living_heroes().is_empty():
        is_battle_active = false
        battle_lost.emit()

# ──────────────────────────────────────────────
# 조회
# ──────────────────────────────────────────────

func get_enemy_hp(index: int) -> int:
    if index < 0 or index >= _enemy_hp.size():
        return 0
    return _enemy_hp[index]

func get_enemy_block(index: int) -> int:
    if index < 0 or index >= _enemy_block.size():
        return 0
    return _enemy_block[index]

func is_enemy_alive(index: int) -> bool:
    if index < 0 or index >= _enemy_alive.size():
        return false
    return _enemy_alive[index]

func get_enemy_current_intent(index: int) -> Resource:
    if index < 0 or index >= _enemies.size():
        return null
    var pattern: Array = _enemies[index].intent_pattern
    if pattern.is_empty():
        return null
    return pattern[_enemy_intent_index[index]]

func clear() -> void:
    _enemies.clear()
    _enemy_hp.clear()
    _enemy_alive.clear()
    _enemy_block.clear()
    _enemy_status.clear()
    _enemy_intent_index.clear()
    _hero_block.clear()
    _hero_status.clear()
    _last_attacker.clear()
    is_battle_active = false
    is_player_turn = false
```

- [ ] **Step 4: test_runner.gd에 TestBattleManager 임시 추가**

`tests/test_runner.gd` 상단에 preload 추가, suites에 추가:

```gdscript
# tests/test_runner.gd
extends SceneTree

var TestResources = preload("res://tests/test_resources.gd")
var TestTeamManager = preload("res://tests/test_team_manager.gd")
var TestDeckManager = preload("res://tests/test_deck_manager.gd")
var TestBattleManager = preload("res://tests/test_battle_manager.gd")

func _init() -> void:
    var total_passed: int = 0
    var total_failed: int = 0

    var suites: Array = [
        TestResources.new(),
        TestTeamManager.new(),
        TestDeckManager.new(),
        TestBattleManager.new(),
    ]

    for suite in suites:
        var result: Dictionary = suite.run_all()
        total_passed += result.passed
        total_failed += result.failed

    print("\n=== Results: %d passed, %d failed ===" % [total_passed, total_failed])
    quit(1 if total_failed > 0 else 0)
```

- [ ] **Step 5: 테스트 실행 — 통과 확인**

```bash
"H:/Program Files/Godot/Godot_v4.6.2-stable_win64_console.exe" --headless -s "H:/AIRelatedDefaultPath/ClaudeCode_Base/GameProjects/CardGameProject/stsl/tests/test_runner.gd" --path "H:/AIRelatedDefaultPath/ClaudeCode_Base/GameProjects/CardGameProject/stsl"
```

예상 출력:
```
[TestBattleManager] test_setup_battle
  PASS: 적 HP == max_hp(30)
  PASS: 셋업 후 적 생존
  PASS: 배틀 활성
  PASS: 초기 블록 0
```

- [ ] **Step 6: 커밋**

```bash
git add autoload/battle_manager.gd tests/test_battle_manager.gd tests/test_runner.gd
git commit -m "feat: BattleManager 기반 + setup_battle (Task 1)"
```

---

## Task 2: 카드 플레이 — 피해/블록 효과

**Files:**
- Modify: `tests/test_battle_manager.gd` — 테스트 2개 추가

- [ ] **Step 1: test_battle_manager.gd에 테스트 추가**

`run_all()` 함수에 아래 두 줄 추가:
```gdscript
func run_all() -> Dictionary:
    test_setup_battle()
    test_play_card_damage()   # 추가
    test_play_card_block()    # 추가
    return { "passed": passed, "failed": failed }
```

파일 맨 끝에 테스트 함수 추가:

```gdscript
func test_play_card_damage() -> void:
    print("[TestBattleManager] test_play_card_damage")
    var bm := _make_bm()
    bm.team_mgr.add_hero(_make_hero("napoleon", 70))
    bm.setup_battle([_make_enemy(30, [])])

    var effect := _make_effect(EffectRes.EffectType.DAMAGE, 10, "SINGLE")
    var card := _make_card("napoleon", 1, [effect])
    bm.deck_mgr.hand.append(card)
    bm.deck_mgr.current_energy = 3
    bm.is_player_turn = true

    var result := bm.play_card(card, 0)
    _assert(result, "카드 플레이 성공 반환")
    _assert(bm.get_enemy_hp(0) == 20, "피해 10 적용 → HP 30 → 20")

func test_play_card_block() -> void:
    print("[TestBattleManager] test_play_card_block")
    var bm := _make_bm()
    bm.team_mgr.add_hero(_make_hero("napoleon", 70))
    bm.setup_battle([_make_enemy(30, [])])

    var effect := _make_effect(EffectRes.EffectType.BLOCK, 8, "SELF")
    var card := _make_card("napoleon", 1, [effect])
    bm.deck_mgr.hand.append(card)
    bm.deck_mgr.current_energy = 3
    bm.is_player_turn = true

    bm.play_card(card, 0)
    _assert(bm._hero_block.get("napoleon", 0) == 8, "블록 8 추가")
```

- [ ] **Step 2: 테스트 실행 — 통과 확인**

```bash
"H:/Program Files/Godot/Godot_v4.6.2-stable_win64_console.exe" --headless -s "H:/AIRelatedDefaultPath/ClaudeCode_Base/GameProjects/CardGameProject/stsl/tests/test_runner.gd" --path "H:/AIRelatedDefaultPath/ClaudeCode_Base/GameProjects/CardGameProject/stsl"
```

예상:
```
[TestBattleManager] test_play_card_damage
  PASS: 카드 플레이 성공 반환
  PASS: 피해 10 적용 → HP 30 → 20
[TestBattleManager] test_play_card_block
  PASS: 블록 8 추가
```

- [ ] **Step 3: 커밋**

```bash
git add tests/test_battle_manager.gd
git commit -m "test: 카드 피해/블록 효과 테스트 (Task 2)"
```

---

## Task 3: 상태이상 시스템 (블록 흡수, weak, vulnerable, poison)

**Files:**
- Modify: `tests/test_battle_manager.gd` — 테스트 6개 추가

- [ ] **Step 1: test_battle_manager.gd run_all()에 6개 추가**

```gdscript
func run_all() -> Dictionary:
    test_setup_battle()
    test_play_card_damage()
    test_play_card_block()
    test_block_absorbs_damage()          # 추가
    test_block_resets_on_player_turn()   # 추가
    test_weak_reduces_damage()           # 추가
    test_vulnerable_increases_damage()   # 추가
    test_poison_tick_enemy()             # 추가
    test_poison_tick_hero()              # 추가
    return { "passed": passed, "failed": failed }
```

테스트 함수 추가:

```gdscript
func test_block_absorbs_damage() -> void:
    print("[TestBattleManager] test_block_absorbs_damage")
    var bm := _make_bm()
    bm.team_mgr.add_hero(_make_hero("napoleon", 70))
    bm.setup_battle([_make_enemy(30, [])])
    bm._hero_block["napoleon"] = 10

    bm._deal_damage_to_hero("napoleon", 15)
    _assert(bm._hero_block.get("napoleon", -1) == 0, "블록 10 전부 소진")
    _assert(bm.team_mgr.get_current_hp("napoleon") == 65, "HP 70 → 65 (블록 10 흡수, 나머지 5 피해)")

func test_block_resets_on_player_turn() -> void:
    print("[TestBattleManager] test_block_resets_on_player_turn")
    var bm := _make_bm()
    bm.team_mgr.add_hero(_make_hero("napoleon", 70))
    bm.setup_battle([_make_enemy(30, [])])
    bm._hero_block["napoleon"] = 5
    bm.is_battle_active = true

    bm.start_player_turn()
    _assert(bm._hero_block.get("napoleon", -1) == 0, "턴 시작 시 블록 0으로 초기화")

func test_weak_reduces_damage() -> void:
    print("[TestBattleManager] test_weak_reduces_damage")
    var bm := _make_bm()
    bm.team_mgr.add_hero(_make_hero("napoleon", 70))
    bm.setup_battle([_make_enemy(30, [])])
    bm._hero_status["napoleon"] = {"weak": 1}

    var effect := _make_effect(EffectRes.EffectType.DAMAGE, 10, "SINGLE")
    var card := _make_card("napoleon", 1, [effect])
    bm.deck_mgr.hand.append(card)
    bm.deck_mgr.current_energy = 3
    bm.is_player_turn = true

    bm.play_card(card, 0)
    # int(10 * 0.75) = 7
    _assert(bm.get_enemy_hp(0) == 23, "약화 적용 → 피해 10 → 7 (HP 30 → 23)")

func test_vulnerable_increases_damage() -> void:
    print("[TestBattleManager] test_vulnerable_increases_damage")
    var bm := _make_bm()
    bm.team_mgr.add_hero(_make_hero("napoleon", 70))
    bm.setup_battle([_make_enemy(30, [])])
    bm._enemy_status[0]["vulnerable"] = 1

    var effect := _make_effect(EffectRes.EffectType.DAMAGE, 10, "SINGLE")
    var card := _make_card("napoleon", 1, [effect])
    bm.deck_mgr.hand.append(card)
    bm.deck_mgr.current_energy = 3
    bm.is_player_turn = true

    bm.play_card(card, 0)
    # int(10 * 1.5) = 15
    _assert(bm.get_enemy_hp(0) == 15, "취약 적용 → 피해 10 → 15 (HP 30 → 15)")

func test_poison_tick_enemy() -> void:
    print("[TestBattleManager] test_poison_tick_enemy")
    var bm := _make_bm()
    bm.team_mgr.add_hero(_make_hero("napoleon", 70))
    # BUFF 의도: 적이 무언가를 하되 공격하지 않도록
    var intent := _make_intent(IntentRes.ActionType.BUFF, 5, IntentRes.TargetType.RANDOM)
    var enemy := _make_enemy(30, [intent])
    bm.setup_battle([enemy])
    bm._enemy_status[0]["poison"] = 3

    bm._execute_enemy_turn()
    _assert(bm.get_enemy_hp(0) == 27, "독 3 틱 → HP 30 → 27")
    _assert(bm._enemy_status[0].get("poison", -1) == 2, "독 스택 3 → 2")

func test_poison_tick_hero() -> void:
    print("[TestBattleManager] test_poison_tick_hero")
    var bm := _make_bm()
    bm.team_mgr.add_hero(_make_hero("napoleon", 70))
    bm.setup_battle([_make_enemy(30, [])])
    bm._hero_status["napoleon"] = {"poison": 4}
    bm.is_battle_active = true

    bm.start_player_turn()
    _assert(bm.team_mgr.get_current_hp("napoleon") == 66, "독 4 틱 → HP 70 → 66")
    _assert(bm._hero_status["napoleon"].get("poison", -1) == 3, "독 스택 4 → 3")
```

- [ ] **Step 2: 테스트 실행 — 통과 확인**

```bash
"H:/Program Files/Godot/Godot_v4.6.2-stable_win64_console.exe" --headless -s "H:/AIRelatedDefaultPath/ClaudeCode_Base/GameProjects/CardGameProject/stsl/tests/test_runner.gd" --path "H:/AIRelatedDefaultPath/ClaudeCode_Base/GameProjects/CardGameProject/stsl"
```

예상: 6개 신규 PASS

- [ ] **Step 3: 커밋**

```bash
git add tests/test_battle_manager.gd
git commit -m "test: 상태이상 시스템 테스트 — 블록 흡수, weak, vulnerable, poison (Task 3)"
```

---

## Task 4: 적 턴 실행 (의도 패턴, 타겟팅)

**Files:**
- Modify: `tests/test_battle_manager.gd` — 테스트 2개 추가

- [ ] **Step 1: run_all()에 추가**

```gdscript
func run_all() -> Dictionary:
    # ... 기존 ...
    test_enemy_turn_attacks_hero()   # 추가
    test_enemy_intent_advances()     # 추가
    return { "passed": passed, "failed": failed }
```

테스트 함수:

```gdscript
func test_enemy_turn_attacks_hero() -> void:
    print("[TestBattleManager] test_enemy_turn_attacks_hero")
    var bm := _make_bm()
    bm.team_mgr.add_hero(_make_hero("napoleon", 70))
    var intent := _make_intent(IntentRes.ActionType.ATTACK, 6, IntentRes.TargetType.RANDOM)
    bm.setup_battle([_make_enemy(30, [intent])])

    bm._execute_enemy_turn()
    _assert(bm.team_mgr.get_current_hp("napoleon") == 64, "적 공격 6 → HP 70 → 64")

func test_enemy_intent_advances() -> void:
    print("[TestBattleManager] test_enemy_intent_advances")
    var bm := _make_bm()
    bm.team_mgr.add_hero(_make_hero("napoleon", 70))
    var intent0 := _make_intent(IntentRes.ActionType.ATTACK, 5, IntentRes.TargetType.RANDOM)
    var intent1 := _make_intent(IntentRes.ActionType.BUFF, 8, IntentRes.TargetType.RANDOM)
    bm.setup_battle([_make_enemy(30, [intent0, intent1])])

    _assert(bm._enemy_intent_index[0] == 0, "초기 인덱스 0")
    bm._execute_enemy_turn()
    _assert(bm._enemy_intent_index[0] == 1, "1회 후 인덱스 1")
    bm._execute_enemy_turn()
    _assert(bm._enemy_intent_index[0] == 0, "2회 후 인덱스 0 (순환)")
```

- [ ] **Step 2: 테스트 실행 — 통과 확인**

```bash
"H:/Program Files/Godot/Godot_v4.6.2-stable_win64_console.exe" --headless -s "H:/AIRelatedDefaultPath/ClaudeCode_Base/GameProjects/CardGameProject/stsl/tests/test_runner.gd" --path "H:/AIRelatedDefaultPath/ClaudeCode_Base/GameProjects/CardGameProject/stsl"
```

예상: 2개 신규 PASS

- [ ] **Step 3: 커밋**

```bash
git add tests/test_battle_manager.gd
git commit -m "test: 적 턴 실행 + 의도 순환 테스트 (Task 4)"
```

---

## Task 5: 승/패 조건 + Autoload 등록

**Files:**
- Modify: `tests/test_battle_manager.gd` — 테스트 2개 추가
- Modify: `project.godot` — BattleManager Autoload 등록

- [ ] **Step 1: run_all()에 추가**

```gdscript
func run_all() -> Dictionary:
    # ... 기존 ...
    test_win_condition()    # 추가
    test_lose_condition()   # 추가
    return { "passed": passed, "failed": failed }
```

테스트 함수:

```gdscript
func test_win_condition() -> void:
    print("[TestBattleManager] test_win_condition")
    var bm := _make_bm()
    bm.team_mgr.add_hero(_make_hero("napoleon", 70))
    bm.setup_battle([_make_enemy(10, [])])

    var won := false
    bm.battle_won.connect(func(): won = true)

    bm._deal_damage_to_enemy(0, 10)
    _assert(won, "모든 적 처치 → battle_won 발동")
    _assert(not bm.is_battle_active, "배틀 비활성")

func test_lose_condition() -> void:
    print("[TestBattleManager] test_lose_condition")
    var bm := _make_bm()
    bm.team_mgr.add_hero(_make_hero("napoleon", 10))
    bm.setup_battle([_make_enemy(30, [])])

    var lost := false
    bm.battle_lost.connect(func(): lost = true)

    bm._deal_damage_to_hero("napoleon", 10)
    _assert(lost, "모든 영웅 사망 → battle_lost 발동")
    _assert(not bm.is_battle_active, "배틀 비활성")
```

- [ ] **Step 2: 테스트 실행 — 통과 확인**

```bash
"H:/Program Files/Godot/Godot_v4.6.2-stable_win64_console.exe" --headless -s "H:/AIRelatedDefaultPath/ClaudeCode_Base/GameProjects/CardGameProject/stsl/tests/test_runner.gd" --path "H:/AIRelatedDefaultPath/ClaudeCode_Base/GameProjects/CardGameProject/stsl"
```

예상: 총 54개 (기존 41 + 신규 13) 중 54 passed, 0 failed

- [ ] **Step 3: project.godot에 Autoload 등록**

`project.godot`의 `[autoload]` 섹션에 추가:

```ini
[autoload]

GameManager="*res://autoload/game_manager.gd"
TeamManager="*res://autoload/team_manager.gd"
DeckManager="*res://autoload/deck_manager.gd"
BattleManager="*res://autoload/battle_manager.gd"
```

- [ ] **Step 4: 최종 테스트 실행 — 전체 통과 확인**

```bash
"H:/Program Files/Godot/Godot_v4.6.2-stable_win64_console.exe" --headless -s "H:/AIRelatedDefaultPath/ClaudeCode_Base/GameProjects/CardGameProject/stsl/tests/test_runner.gd" --path "H:/AIRelatedDefaultPath/ClaudeCode_Base/GameProjects/CardGameProject/stsl"
```

예상: `=== Results: 54 passed, 0 failed ===`

- [ ] **Step 5: 커밋**

```bash
git add tests/test_battle_manager.gd project.godot
git commit -m "feat: 승/패 조건 테스트 + BattleManager Autoload 등록 (Task 5)"
```

---

## Self-Review

### Spec 커버리지 확인

| GDD 요구사항 | 구현 태스크 |
|---|---|
| 카드 플레이 → 해당 팀원 행동 | Task 2 (owner_id 기반 블록 적용) |
| 에너지 차감 | Task 2 (DeckManager.play_card 위임) |
| 방어도(Block) 피해 흡수 + 턴 종료 초기화 | Task 3 |
| 독(Poison) 매 턴 틱 + 1 감소 | Task 3 |
| 약화(Weak) 피해 25% 감소 | Task 3 |
| 취약(Vulnerable) 피해 50% 증가 | Task 3 |
| 몬스터 의도 순환 패턴 | Task 4 |
| 몬스터 타겟팅 (RANDOM/LOWEST_HP/LAST_ATTACKER) | Task 4 |
| 승리 조건 (모든 적 처치) | Task 5 |
| 패배 조건 (모든 영웅 사망) | Task 5 |

### 이 플랜에서 다루지 않는 것 (다음 플랜)

- **도발(Taunt)**: 어그로 집중 로직
- **강화(Strength)**: 공격 피해 증가 스택
- **사기(Morale), 진형(Formation), 매혹(Charm)**: 캐릭터 전용 메카닉
- **상태이상 스택 감소**: Weak/Vulnerable 턴마다 1씩 감소
- **ALL 타겟 적 공격**: _execute_intent에서 다중 대상 처리
- **전투 씬 UI**: BattleScene, 카드 손패 표시, 에너지 UI

### 플레이스홀더 없음 확인

모든 스텝에 실제 코드 포함. `pass`는 `IntentRes.ActionType.SPECIAL`에만 사용 (MVP 미구현 명시).

### 타입 일관성 확인

- `BattleManagerClass.new()` → Task 1부터 일관
- `_make_effect(EffectRes.EffectType.DAMAGE, ...)` → EffectRes 상수 일관 사용
- `_make_intent(IntentRes.ActionType.ATTACK, ...)` → IntentRes 상수 일관 사용
- `_hero_block`, `_enemy_block`, `_hero_status`, `_enemy_status` → 모든 태스크에서 동일 필드명
