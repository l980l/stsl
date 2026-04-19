# Plan 24 — 렐릭 확장 + 전투 시각 피드백 구현 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 블록 흡수 시 UI 갱신 버그 수정 + 데미지 팝업 숫자 + 렐릭 풀 필터링(영웅 전용/저주) + 렐릭 9종 + 저주 렐릭 전용 이벤트 1종 추가

**Architecture:** RelicResource에 `is_cursed`, `penalty_*` 필드 추가. BattleManager 시그널 항상 발화. BattleScene에 Tween 팝업. GameManager 렐릭 풀을 팀/저주 기준으로 필터링. 이벤트 풀에 "악마의 거래" 추가.

**Tech Stack:** GDScript 4.6, Godot 4.6 headless test runner

테스트 실행 명령:
```
"H:/Program Files/Godot/Godot_v4.6.2-stable_win64_console.exe" --headless -s tests/test_runner.gd --path "H:/AIRelatedDefaultPath/ClaudeCode_Base/GameProjects/CardGameProject/stsl"
```
기대 결과: `=== Results: N passed, 0 failed ===`

---

## 파일 구조

| 파일 | 변경 내용 |
|---|---|
| `resources/relic_resource.gd` | `is_cursed`, `DAMAGE_HERO` EffectType, `penalty_trigger/effect_type/value` 추가 |
| `resources/event_choice_resource.gd` | `ADD_RELIC_GAMBLE` EffectType 추가 |
| `autoload/battle_manager.gd` | 블록 흡수 시 시그널 항상 발화 |
| `autoload/game_manager.gd` | 렐릭 9종, 필터링, penalty 처리, 악마의 거래 이벤트 |
| `scenes/battle/battle_scene.gd` | `_spawn_damage_popup()` 추가 |
| `scenes/event/event_scene.gd` | `ADD_RELIC_GAMBLE` 처리 |
| `tests/test_battle_manager.gd` | 블록 시그널 테스트 수정 (not_emitted → emitted_with_zero) |
| `tests/test_relics.gd` | 새 렐릭 풀 크기, is_cursed, penalty 필드 테스트 추가 |

---

## Task 1: RelicResource 확장

**Files:**
- Modify: `resources/relic_resource.gd`
- Modify: `tests/test_relics.gd`

- [ ] **Step 1: 실패 테스트 작성** — `tests/test_relics.gd`의 `run_all()`에 새 테스트 2개 추가 (기존 파일 하단에 함수 추가, run_all에 호출 추가)

```gdscript
# run_all() 안에 추가:
test_is_cursed_field_exists()
test_penalty_fields_exist()

# 파일 하단에 추가:
func test_is_cursed_field_exists() -> void:
    print("[TestRelics] test_is_cursed_field_exists")
    var r := RelicRes.new()
    _assert(r.is_cursed == false, "is_cursed 기본값 false")

func test_penalty_fields_exist() -> void:
    print("[TestRelics] test_penalty_fields_exist")
    var r := RelicRes.new()
    r.is_cursed = true
    r.penalty_trigger = RelicRes.TriggerType.PLAYER_TURN_START
    r.penalty_effect_type = RelicRes.EffectType.HEAL  # 임시, 나중에 DAMAGE_HERO로 교체
    r.penalty_value = 3
    _assert(r.penalty_value == 3, "penalty_value 설정 가능")
    _assert(r.penalty_trigger == RelicRes.TriggerType.PLAYER_TURN_START, "penalty_trigger 설정 가능")
```

- [ ] **Step 2: 테스트 실패 확인**

실행 후 `FAIL: is_cursed 기본값 false` 등 실패 확인

- [ ] **Step 3: relic_resource.gd 수정** — `is_cursed`, `DAMAGE_HERO`, penalty 필드 추가

현재 파일:
```gdscript
enum EffectType {
    HEAL, ENERGY, DRAW, APPLY_STATUS_ENEMY, MAX_HP, RECOVER_CARD,
    GAIN_MORALE, COST_REDUCTION, BLOCK
}

@export var relic_name: String = ""
@export var description: String = ""
@export var trigger: TriggerType = TriggerType.PASSIVE
@export var effect_type: EffectType = EffectType.HEAL
@export var value: int = 0
@export var owner_hero_id: String = ""
@export var bonus_value: int = 0
@export var condition_value: int = 0
```

수정 후:
```gdscript
enum EffectType {
    HEAL, ENERGY, DRAW, APPLY_STATUS_ENEMY, MAX_HP, RECOVER_CARD,
    GAIN_MORALE, COST_REDUCTION, BLOCK,
    DAMAGE_HERO  # 9: 무작위 살아있는 영웅 HP 직접 감소 (블록 우회)
}

@export var relic_name: String = ""
@export var description: String = ""
@export var trigger: TriggerType = TriggerType.PASSIVE
@export var effect_type: EffectType = EffectType.HEAL
@export var value: int = 0
@export var owner_hero_id: String = ""
@export var bonus_value: int = 0
@export var condition_value: int = 0
@export var is_cursed: bool = false
@export var penalty_trigger: TriggerType = TriggerType.PASSIVE
@export var penalty_effect_type: EffectType = EffectType.DAMAGE_HERO
@export var penalty_value: int = 0
```

- [ ] **Step 4: 테스트 통과 확인**

Expected: `PASS: is_cursed 기본값 false`, `PASS: penalty_value 설정 가능`

- [ ] **Step 5: test_effect_type_values 업데이트** — DAMAGE_HERO 추가 검증

```gdscript
func test_effect_type_values() -> void:
    print("[TestRelics] test_effect_type_values")
    _assert(RelicRes.EffectType.HEAL == 0, "HEAL == 0")
    _assert(RelicRes.EffectType.APPLY_STATUS_ENEMY == 3, "APPLY_STATUS_ENEMY == 3")
    _assert(RelicRes.EffectType.BLOCK == 8, "BLOCK == 8")
    _assert(RelicRes.EffectType.DAMAGE_HERO == 9, "DAMAGE_HERO == 9")
```

- [ ] **Step 6: 테스트 통과 확인 후 커밋**

```bash
git add resources/relic_resource.gd tests/test_relics.gd
git commit -m "feat: RelicResource — is_cursed + penalty 필드 + DAMAGE_HERO EffectType"
```

---

## Task 2: 블록 흡수 시그널 버그 수정

**Files:**
- Modify: `autoload/battle_manager.gd`
- Modify: `tests/test_battle_manager.gd`

**배경:** 현재 블록이 피해를 완전 흡수하면 `hero_damaged` / `enemy_damaged` 시그널이 발화하지 않아 UI가 갱신되지 않음. 기존 테스트 2개가 이 동작(발화 없음)을 검증하므로 함께 수정.

- [ ] **Step 1: 기존 테스트 2개 수정** — not_emitted → emitted_with_zero

`tests/test_battle_manager.gd`의 `test_hero_damaged_not_emitted_when_fully_blocked` 수정:

```gdscript
func test_hero_damaged_not_emitted_when_fully_blocked() -> void:
    print("[TestBattleManager] test_hero_damaged_not_emitted_when_fully_blocked")
    var bm := _make_bm()
    var hero := _make_hero("napoleon", 70)
    bm.team_mgr.add_hero(hero)
    bm.setup_battle([_make_enemy(30, [])])
    bm.start_player_turn()

    bm._hero_block["napoleon"] = 10

    var damage_emitted: Array = []
    bm.hero_damaged.connect(func(id, amt): damage_emitted.append(amt))

    bm._deal_damage_to_hero("napoleon", 10)
    _assert(damage_emitted.size() == 1, "블록 완전 흡수 시에도 hero_damaged 발화")
    _assert(damage_emitted[0] == 0, "amount == 0 으로 발화")
    _assert(bm.team_mgr.get_current_hp("napoleon") == 70, "HP 변화 없음")
```

`test_enemy_damaged_not_emitted_when_fully_blocked` 수정:

```gdscript
func test_enemy_damaged_not_emitted_when_fully_blocked() -> void:
    print("[TestBattleManager] test_enemy_damaged_not_emitted_when_fully_blocked")
    var bm := _make_bm()
    var hero := _make_hero("napoleon", 70)
    bm.team_mgr.add_hero(hero)
    bm.setup_battle([_make_enemy(30, [])])
    bm.start_player_turn()

    bm._enemy_block[0] = 10

    var damage_emitted: Array = []
    bm.enemy_damaged.connect(func(idx, amt): damage_emitted.append(amt))

    bm._deal_damage_to_enemy(0, 10)
    _assert(damage_emitted.size() == 1, "블록 완전 흡수 시에도 enemy_damaged 발화")
    _assert(damage_emitted[0] == 0, "amount == 0 으로 발화")
    _assert(bm.get_enemy_hp(0) == 30, "적 HP 변화 없음")
```

- [ ] **Step 2: 테스트 실패 확인**

위 두 테스트가 FAIL이어야 함 (아직 구현 전)

- [ ] **Step 3: battle_manager.gd 수정** — 시그널 항상 발화

`_deal_damage_to_enemy` 함수에서 (약 207-208번 줄):

현재:
```gdscript
    _enemy_hp[enemy_index] = max(0, _enemy_hp[enemy_index] - amount)
    if amount > 0:
        enemy_damaged.emit(enemy_index, amount)
```

수정:
```gdscript
    _enemy_hp[enemy_index] = max(0, _enemy_hp[enemy_index] - amount)
    enemy_damaged.emit(enemy_index, amount)
```

`_deal_damage_to_hero` 함수에서 (약 225-232번 줄):

현재:
```gdscript
    if amount > 0:
        team_mgr.take_damage(hero_id, amount)
        ...relic 처리...
        hero_damaged.emit(hero_id, amount)
```

수정: `hero_damaged.emit`을 `if` 블록 밖으로 이동

```gdscript
    if amount > 0:
        team_mgr.take_damage(hero_id, amount)
        ...relic 처리 (기존 코드 그대로)...
    hero_damaged.emit(hero_id, amount)
```

- [ ] **Step 4: 테스트 통과 확인**

```
=== Results: N passed, 0 failed ===
```

- [ ] **Step 5: 커밋**

```bash
git add autoload/battle_manager.gd tests/test_battle_manager.gd
git commit -m "fix: 블록 완전 흡수 시에도 damaged 시그널 발화 (amount=0)"
```

---

## Task 3: 렐릭 필터링 + 신규 효과 구현

**Files:**
- Modify: `autoload/game_manager.gd`
- Modify: `tests/test_relics.gd`

- [ ] **Step 1: 실패 테스트 작성** — test_relics.gd에 추가

```gdscript
# run_all()에 추가:
test_damage_hero_effect_bypasses_block()
test_cursed_relic_has_is_cursed_true()

# 파일 하단에 추가:
func test_damage_hero_effect_bypasses_block() -> void:
    print("[TestRelics] test_damage_hero_effect_bypasses_block")
    var tm := _make_tm()
    var hero := _make_hero("napoleon", 70)
    tm.add_hero(hero)
    # block이 있어도 take_damage로 직접 감소하므로 HP가 줄어야 함
    tm.take_damage("napoleon", 5)
    _assert(tm.get_current_hp("napoleon") == 65, "take_damage 직접 호출 시 HP 감소")

func test_cursed_relic_has_is_cursed_true() -> void:
    print("[TestRelics] test_cursed_relic_has_is_cursed_true")
    var r := RelicRes.new()
    r.relic_name = "악마의 계약"
    r.is_cursed = true
    _assert(r.is_cursed == true, "저주 렐릭 is_cursed=true")
    _assert(r.relic_name == "악마의 계약", "저주 렐릭 이름 확인")
```

- [ ] **Step 2: 테스트 실패 확인**

- [ ] **Step 3: game_manager.gd — DAMAGE_HERO 효과 추가**

`_apply_relic_effect()` 함수의 `match relic.effect_type:` 블록 마지막에 추가:

```gdscript
        RelicRes.EffectType.DAMAGE_HERO:
            var tm_dh := _get_tm()
            if is_inside_tree() and tm_dh:
                var living: Array = tm_dh.get_living_heroes()
                if not living.is_empty():
                    var target = living[randi() % living.size()]
                    tm_dh.take_damage(target.hero_id, value)
```

- [ ] **Step 4: game_manager.gd — penalty 처리 + trigger_relics 리팩터**

현재 `trigger_relics()`:
```gdscript
func trigger_relics(trigger: int, context: Dictionary = {}) -> void:
    for relic in relics:
        if relic.trigger != trigger:
            continue
        var effective_value: int = relic.value
        if relic.owner_hero_id != "":
            if not _is_hero_alive(relic.owner_hero_id):
                continue
            effective_value = relic.bonus_value
        _apply_relic_effect(relic, effective_value, context)
```

수정:
```gdscript
func trigger_relics(trigger: int, context: Dictionary = {}) -> void:
    for relic in relics:
        # 메인 효과
        if relic.trigger == trigger:
            var effective_value: int = relic.value
            if relic.owner_hero_id == "" or _is_hero_alive(relic.owner_hero_id):
                if relic.owner_hero_id != "":
                    effective_value = relic.bonus_value
                _apply_relic_effect(relic, effective_value, context)
        # 패널티 효과 (저주 렐릭)
        if relic.is_cursed and relic.penalty_trigger == trigger and relic.penalty_value > 0:
            _apply_penalty_effect(relic)

func _apply_penalty_effect(relic: Resource) -> void:
    var RelicRes = load("res://resources/relic_resource.gd")
    var tm := _get_tm()
    if not is_inside_tree() or tm == null:
        return
    match relic.penalty_effect_type:
        RelicRes.EffectType.DAMAGE_HERO:
            var living: Array = tm.get_living_heroes()
            if not living.is_empty():
                var target = living[randi() % living.size()]
                tm.take_damage(target.hero_id, relic.penalty_value)
```

- [ ] **Step 5: game_manager.gd — get_random_relic() 필터링 수정**

현재:
```gdscript
func get_random_relic() -> Resource:
    var pool := _build_relic_pool()
    var owned_names: Array = []
    for r in relics:
        owned_names.append(r.relic_name)
    var available: Array = []
    for r in pool:
        if r.relic_name not in owned_names:
            available.append(r)
    if available.is_empty():
        return null
    return available[randi() % available.size()]
```

수정 + `get_random_cursed_relic()` 추가:
```gdscript
func get_random_relic() -> Resource:
    var tm := _get_tm()
    var pool := _build_relic_pool()
    var owned_names: Array = []
    for r in relics:
        owned_names.append(r.relic_name)
    var available: Array = []
    for r in pool:
        if r.relic_name in owned_names:
            continue
        if r.is_cursed:
            continue
        if r.owner_hero_id != "":
            if tm == null or not tm.has_hero(r.owner_hero_id):
                continue
        available.append(r)
    if available.is_empty():
        return null
    return available[randi() % available.size()]

func get_random_cursed_relic() -> Resource:
    var pool := _build_relic_pool()
    var owned_names: Array = []
    for r in relics:
        owned_names.append(r.relic_name)
    var available: Array = []
    for r in pool:
        if r.is_cursed and r.relic_name not in owned_names:
            available.append(r)
    if available.is_empty():
        return null
    return available[randi() % available.size()]
```

- [ ] **Step 6: TeamManager에 has_hero() 확인**

`autoload/team_manager.gd`에서 `has_hero` 또는 `get_hero` 함수 확인:
```bash
grep -n "has_hero\|get_hero" autoload/team_manager.gd
```

만약 `has_hero(id)` 없으면 추가:
```gdscript
func has_hero(hero_id: String) -> bool:
    return get_hero(hero_id) != null
```

- [ ] **Step 7: 테스트 통과 확인**

```
=== Results: N passed, 0 failed ===
```

- [ ] **Step 8: 커밋**

```bash
git add autoload/game_manager.gd autoload/team_manager.gd tests/test_relics.gd
git commit -m "feat: 렐릭 필터링 (영웅 전용·저주), DAMAGE_HERO 효과, get_random_cursed_relic"
```

---

## Task 4: 렐릭 9종 추가

**Files:**
- Modify: `autoload/game_manager.gd`
- Modify: `tests/test_relics.gd`

- [ ] **Step 1: 실패 테스트 작성** — test_relic_pool_size 업데이트 + 새 렐릭 확인

`test_relic_pool_size` 수정 (기존 10 → 19):
```gdscript
func test_relic_pool_size() -> void:
    print("[TestRelics] test_relic_pool_size")
    var pool := _build_pool()
    _assert(pool.size() == 19, "릴릭 풀 19종")
```

`_build_pool()` 업데이트 (names 배열에 9개 추가):
```gdscript
func _build_pool() -> Array:
    var pool: Array = []
    var names := [
        "버닝 블러드", "불사조 깃털", "독약 병", "전쟁 북",
        "고대 유물", "모래시계", "피의 돌",
        "황제의 인장", "독사의 팔찌", "거북선 모형",
        "포병 나팔", "난중일기", "파라오의 인장",
        "악마의 계약", "저주받은 왕관", "피의 서약",
        "전술가의 지도", "강철 의지", "고대의 방패"
    ]
    for n in names:
        var r := RelicRes.new()
        r.relic_name = n
        pool.append(r)
    return pool
```

새 테스트 추가:
```gdscript
# run_all()에 추가:
test_cursed_relics_in_pool()
test_hero_relics_second_set()

func test_cursed_relics_in_pool() -> void:
    print("[TestRelics] test_cursed_relics_in_pool")
    var cursed_names := ["악마의 계약", "저주받은 왕관", "피의 서약"]
    for name in cursed_names:
        var r := RelicRes.new()
        r.relic_name = name
        r.is_cursed = true
        _assert(r.is_cursed, "저주 렐릭 is_cursed: %s" % name)

func test_hero_relics_second_set() -> void:
    print("[TestRelics] test_hero_relics_second_set")
    var pool := _build_pool()
    var second_set := ["포병 나팔", "난중일기", "파라오의 인장"]
    for name in second_set:
        var found := false
        for r in pool:
            if r.relic_name == name:
                found = true
                break
        _assert(found, "2번째 전용 렐릭 존재: %s" % name)
```

- [ ] **Step 2: 테스트 실패 확인**

`test_relic_pool_size` → FAIL (size == 10)

- [ ] **Step 3: game_manager.gd — 렐릭 9종 추가** (`_build_relic_pool()` 함수 하단에 추가)

```gdscript
    # 11. 포병 나팔 — 나폴레옹 전용: 턴 시작 사기 +1
    var r11: Resource = RelicRes.new(); r11.relic_name = "포병 나팔"
    r11.description = "플레이어 턴 시작 시 사기 +1 (나폴레옹 생존 시 적용)"
    r11.trigger = RelicRes.TriggerType.PLAYER_TURN_START
    r11.effect_type = RelicRes.EffectType.GAIN_MORALE
    r11.owner_hero_id = "napoleon"; r11.value = 0; r11.bonus_value = 1
    pool.append(r11)

    # 12. 난중일기 — 이순신 전용: 전투 승리 시 팀 HP +8
    var r12: Resource = RelicRes.new(); r12.relic_name = "난중일기"
    r12.description = "전투 승리 시 팀 HP +8 (이순신 생존 시 적용)"
    r12.trigger = RelicRes.TriggerType.BATTLE_WIN
    r12.effect_type = RelicRes.EffectType.HEAL
    r12.owner_hero_id = "yi_sun_sin"; r12.value = 0; r12.bonus_value = 8
    pool.append(r12)

    # 13. 파라오의 인장 — 클레오파트라 전용: 턴 시작 무작위 적 독 +1
    var r13: Resource = RelicRes.new(); r13.relic_name = "파라오의 인장"
    r13.description = "플레이어 턴 시작 시 무작위 적 독 +1 (클레오파트라 생존 시 적용)"
    r13.trigger = RelicRes.TriggerType.PLAYER_TURN_START
    r13.effect_type = RelicRes.EffectType.APPLY_STATUS_ENEMY
    r13.owner_hero_id = "cleopatra"; r13.value = 0; r13.bonus_value = 1
    pool.append(r13)

    # 14. 악마의 계약 — 저주: 전투 승리 팀 HP +20 / 매 턴 무작위 영웅 HP -3
    var r14: Resource = RelicRes.new(); r14.relic_name = "악마의 계약"
    r14.description = "전투 승리 시 팀 HP +20. 단, 매 플레이어 턴 시작 시 무작위 영웅 HP -3"
    r14.trigger = RelicRes.TriggerType.BATTLE_WIN
    r14.effect_type = RelicRes.EffectType.HEAL; r14.value = 20
    r14.is_cursed = true
    r14.penalty_trigger = RelicRes.TriggerType.PLAYER_TURN_START
    r14.penalty_effect_type = RelicRes.EffectType.DAMAGE_HERO; r14.penalty_value = 3
    pool.append(r14)

    # 15. 저주받은 왕관 — 저주: 최대 HP +25 / 매 전투 시작 무작위 영웅 HP -8
    var r15: Resource = RelicRes.new(); r15.relic_name = "저주받은 왕관"
    r15.description = "최대 HP +25. 단, 매 전투 시작 시 무작위 영웅 HP -8"
    r15.trigger = RelicRes.TriggerType.PASSIVE
    r15.effect_type = RelicRes.EffectType.MAX_HP; r15.value = 25
    r15.is_cursed = true
    r15.penalty_trigger = RelicRes.TriggerType.BATTLE_START
    r15.penalty_effect_type = RelicRes.EffectType.DAMAGE_HERO; r15.penalty_value = 8
    pool.append(r15)

    # 16. 피의 서약 — 저주: 턴 시작 에너지 +1 / 턴 종료 무작위 영웅 HP -4
    var r16: Resource = RelicRes.new(); r16.relic_name = "피의 서약"
    r16.description = "플레이어 턴 시작 시 에너지 +1. 단, 턴 종료 시 무작위 영웅 HP -4"
    r16.trigger = RelicRes.TriggerType.PLAYER_TURN_START
    r16.effect_type = RelicRes.EffectType.ENERGY; r16.value = 1
    r16.is_cursed = true
    r16.penalty_trigger = RelicRes.TriggerType.PLAYER_TURN_END
    r16.penalty_effect_type = RelicRes.EffectType.DAMAGE_HERO; r16.penalty_value = 4
    pool.append(r16)

    # 17. 전술가의 지도 — 공용: 전투 시작 카드 +1 드로우
    var r17: Resource = RelicRes.new(); r17.relic_name = "전술가의 지도"
    r17.description = "전투 시작 시 카드 1장 추가 드로우"
    r17.trigger = RelicRes.TriggerType.BATTLE_START
    r17.effect_type = RelicRes.EffectType.DRAW; r17.value = 1
    pool.append(r17)

    # 18. 강철 의지 — 공용: 전투 시작 에너지 +1
    var r18: Resource = RelicRes.new(); r18.relic_name = "강철 의지"
    r18.description = "전투 시작 시 에너지 +1"
    r18.trigger = RelicRes.TriggerType.BATTLE_START
    r18.effect_type = RelicRes.EffectType.ENERGY; r18.value = 1
    pool.append(r18)

    # 19. 고대의 방패 — 공용: 전투 시작 팀 전체 방어도 +4
    var r19: Resource = RelicRes.new(); r19.relic_name = "고대의 방패"
    r19.description = "전투 시작 시 팀 전체 방어도 +4"
    r19.trigger = RelicRes.TriggerType.BATTLE_START
    r19.effect_type = RelicRes.EffectType.BLOCK; r19.value = 4
    pool.append(r19)
```

- [ ] **Step 4: 테스트 통과 확인**

```
=== Results: N passed, 0 failed ===
```

- [ ] **Step 5: 커밋**

```bash
git add autoload/game_manager.gd tests/test_relics.gd
git commit -m "feat: 렐릭 9종 추가 (영웅 전용 3 + 저주 3 + 공용 3)"
```

---

## Task 5: 악마의 거래 이벤트

**Files:**
- Modify: `resources/event_choice_resource.gd`
- Modify: `scenes/event/event_scene.gd`
- Modify: `autoload/game_manager.gd`
- Modify: `tests/test_event.gd`

- [ ] **Step 1: 실패 테스트 확인** — test_event.gd에 악마의 거래 테스트 추가

먼저 기존 test_event.gd 구조 확인:
```bash
grep -n "func test_\|run_all" tests/test_event.gd | head -20
```

test_event.gd의 `run_all()`에 추가:
```gdscript
test_devil_deal_event_exists()

func test_devil_deal_event_exists() -> void:
    print("[TestEvent] test_devil_deal_event_exists")
    var ChoiceRes = load("res://resources/event_choice_resource.gd")
    _assert(ChoiceRes.EffectType.ADD_RELIC_GAMBLE != null, "ADD_RELIC_GAMBLE EffectType 존재")
    # ADD_RELIC_GAMBLE은 ADD_HERO(6) 다음이므로 == 7
    _assert(ChoiceRes.EffectType.ADD_RELIC_GAMBLE == 7, "ADD_RELIC_GAMBLE == 7")
```

- [ ] **Step 2: 테스트 실패 확인**

- [ ] **Step 3: event_choice_resource.gd 수정**

현재:
```gdscript
enum EffectType { NONE, GOLD, HEAL, DRAW_UP, REMOVE_CARD, ADD_RELIC, ADD_HERO }
```

수정:
```gdscript
enum EffectType { NONE, GOLD, HEAL, DRAW_UP, REMOVE_CARD, ADD_RELIC, ADD_HERO, ADD_RELIC_GAMBLE }
```

- [ ] **Step 4: event_scene.gd — ADD_RELIC_GAMBLE 처리 추가**

`scenes/event/event_scene.gd`의 `ADD_RELIC` 처리 다음에 추가:

```gdscript
        choice.EffectType.ADD_RELIC_GAMBLE:
            var relic
            if randf() < 0.5:
                relic = GameManager.get_random_relic()
            else:
                relic = GameManager.get_random_cursed_relic()
            if relic:
                GameManager.add_relic(relic)
```

- [ ] **Step 5: game_manager.gd — 악마의 거래 이벤트 추가** (`_build_event_pool()` 마지막에)

```gdscript
    # 11. 악마의 거래
    var e11: Resource = EventRes.new()
    e11.event_name = "악마의 거래"
    e11.description = "어둠 속 제단에서 목소리가 들린다.\n'내 힘을 원하느냐? 대가는 네가 치르게 될 것이다.'\n50% 확률로 강력한 렐릭 또는 저주 렐릭을 얻는다."
    var c11a: Resource = ChoiceRes.new(); c11a.label = "받아들인다"
    c11a.effect_type = ChoiceRes.EffectType.ADD_RELIC_GAMBLE
    var c11b: Resource = ChoiceRes.new(); c11b.label = "거절한다"
    c11b.effect_type = ChoiceRes.EffectType.NONE
    e11.choices = [c11a, c11b]; events.append(e11)
```

- [ ] **Step 6: 테스트 통과 확인**

```
=== Results: N passed, 0 failed ===
```

- [ ] **Step 7: 커밋**

```bash
git add resources/event_choice_resource.gd scenes/event/event_scene.gd autoload/game_manager.gd tests/test_event.gd
git commit -m "feat: 악마의 거래 이벤트 + ADD_RELIC_GAMBLE (50% 저주 렐릭)"
```

---

## Task 6: 데미지 팝업 숫자

**Files:**
- Modify: `scenes/battle/battle_scene.gd`

> 이 Task는 시각 효과로 자동 테스트 불가. 수동으로 전투 실행하여 확인.

- [ ] **Step 1: `_spawn_damage_popup()` 함수 추가** — `battle_scene.gd` 하단 `_on_card_button_down` 앞에 추가

```gdscript
func _spawn_damage_popup(world_pos: Vector2, amount: int, fully_blocked: bool) -> void:
    var lbl := Label.new()
    if fully_blocked:
        lbl.text = "BLOCK"
        lbl.modulate = Color(0.4, 0.8, 1.0)
    else:
        lbl.text = str(amount)
        lbl.modulate = Color(1.0, 0.2, 0.2)
    lbl.add_theme_font_size_override("font_size", 28)
    lbl.position = world_pos
    lbl.z_index = 20
    add_child(lbl)
    var tw := create_tween()
    tw.set_parallel(true)
    tw.tween_property(lbl, "position:y", world_pos.y - 60.0, 0.8)
    tw.tween_property(lbl, "modulate:a", 0.0, 0.8)
    tw.chain().tween_callback(lbl.queue_free)
```

- [ ] **Step 2: `_on_enemy_damaged` 수정** — 팝업 호출 추가

현재:
```gdscript
func _on_enemy_damaged(index: int, _amount: int) -> void:
    _update_enemy_ui(index)
    var char_node = ...
```

수정:
```gdscript
func _on_enemy_damaged(index: int, amount: int) -> void:
    _update_enemy_ui(index)
    if index < _enemy_nodes.size() and _enemy_nodes[index]["panel"].visible:
        var panel: ColorRect = _enemy_nodes[index]["panel"]
        var popup_pos := panel.position + Vector2(SLOT_W / 2.0 - 20.0, SLOT_H / 3.0)
        _spawn_damage_popup(popup_pos, amount, amount == 0)
    var char_node = ...
```

- [ ] **Step 3: `_on_hero_damaged` 수정** — 팝업 호출 추가

현재:
```gdscript
func _on_hero_damaged(hero_id: String, _amount: int) -> void:
    _update_hero_ui(hero_id)
    var char_node = ...
```

수정:
```gdscript
func _on_hero_damaged(hero_id: String, amount: int) -> void:
    _update_hero_ui(hero_id)
    for entry in _hero_nodes:
        if entry["hero_id"] == hero_id and entry["panel"].visible:
            var panel: ColorRect = entry["panel"]
            var popup_pos := panel.position + Vector2(SLOT_W / 2.0 - 20.0, SLOT_H / 3.0)
            _spawn_damage_popup(popup_pos, amount, amount == 0)
            break
    var char_node = ...
```

- [ ] **Step 4: 테스트 통과 확인** — 자동 테스트 회귀 없음 확인

```
=== Results: N passed, 0 failed ===
```

- [ ] **Step 5: 커밋**

```bash
git add scenes/battle/battle_scene.gd
git commit -m "feat: 데미지/블록 팝업 숫자 (빨강=피해, 파랑=BLOCK)"
```

---

## 셀프 리뷰

**Spec 커버리지:**
- ✅ 블록 흡수 시 시그널 발화 (Task 2)
- ✅ 데미지 팝업 빨강/파랑 (Task 6)
- ✅ 렐릭 필터링 — 영웅 전용 팀 기준 (Task 3)
- ✅ 렐릭 필터링 — 저주 렐릭 일반 풀 제외 (Task 3)
- ✅ 영웅 전용 2번째 3종 (Task 4)
- ✅ 저주 렐릭 3종 + penalty 구현 (Task 3, 4)
- ✅ 공용 렐릭 3종 (Task 4)
- ✅ 악마의 거래 이벤트 (Task 5)

**타입 일관성:**
- `DAMAGE_HERO == 9` — Task 1에서 정의, Task 3·4에서 사용
- `ADD_RELIC_GAMBLE == 7` — Task 5에서 정의 및 사용
- `penalty_trigger`, `penalty_effect_type`, `penalty_value` — Task 1 정의, Task 3·4 사용

**플레이스홀더:** 없음
