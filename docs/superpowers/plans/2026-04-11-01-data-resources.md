# Plan 01: 데이터 구조 & Autoload 기반

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 게임 전체의 기반이 되는 Resource 데이터 클래스와 Autoload 싱글톤을 정의한다.

**Architecture:** GDD에 정의된 CardResource, HeroResource, EnemyResource, RelicResource, EffectResource를 GDScript `class_name` Resource로 구현한다. GameManager, TeamManager, DeckManager는 Autoload 싱글톤으로 등록해 모든 씬에서 접근 가능하게 한다. 헤드리스 테스트로 Resource 기본값 및 핵심 Autoload 로직을 검증한다.

**Tech Stack:** Godot 4.6, GDScript (타입 힌트 명시), 헤드리스 테스트 (`godot --headless -s`)

---

## 파일 구조

```
stsl/
  resources/
    effect_resource.gd       ← 카드/릴릭 효과 원자 단위
    card_resource.gd         ← 카드 데이터 (play_animation 포함)
    hero_resource.gd         ← 팀원(역사 인물) 데이터 (character_scene 참조)
    intent_resource.gd       ← 몬스터 1회 행동 데이터 (play_animation 포함)
    enemy_resource.gd        ← 몬스터 데이터 (character_scene 참조)
    relic_resource.gd        ← 유물 데이터
  autoload/
    game_manager.gd          ← 런 상태, 현재 층/챕터, 골드, 릴릭 목록
    team_manager.gd          ← 팀원 목록, 현재 HP, 생사 상태
    deck_manager.gd          ← 드로우/손패/버림/소진 더미, 에너지
  characters/
    heroes/
      napoleon/
        napoleon.tscn        ← 나폴레옹 플레이스홀더 씬
      yi_sun_sin/
        yi_sun_sin.tscn      ← 이순신 플레이스홀더 씬
      cleopatra/
        cleopatra.tscn       ← 클레오파트라 플레이스홀더 씬
    enemies/
      satyr/
        satyr.tscn           ← 사티로스 플레이스홀더 씬
  tests/
    test_runner.gd           ← SceneTree 기반 헤드리스 진입점
    test_resources.gd        ← Resource 기본값 검증
    test_team_manager.gd     ← TeamManager 로직 검증
    test_deck_manager.gd     ← DeckManager 로직 검증
  project.godot              ← Autoload 등록 (수정)
```

> **애니메이션 설계 원칙**
> - 캐릭터/몬스터 씬은 `PackedScene`으로 Resource에서 참조. 씬 내부에 `AnimationPlayer` + `ColorRect`(플레이스홀더)
> - Blender로 스프라이트 시트 제작 후 씬 내부의 `ColorRect`만 `AnimatedSprite2D`로 교체하면 됨
> - 카드 플레이 시 `CardResource.play_animation` → 해당 캐릭터 씬의 `AnimationPlayer.play()` 호출
> - 카드 아트(`art: Texture2D`)는 정적 이미지이므로 Texture2D 유지

---

### Task 1: 테스트 러너 뼈대 작성

**Files:**
- Create: `tests/test_runner.gd`

- [ ] **Step 1: test_runner.gd 작성**

```gdscript
# tests/test_runner.gd
extends SceneTree

func _init() -> void:
    var total_passed: int = 0
    var total_failed: int = 0

    # 테스트 클래스 목록 — 이후 태스크에서 추가
    var suites: Array = []

    for suite in suites:
        var result: Dictionary = suite.run_all()
        total_passed += result.passed
        total_failed += result.failed

    print("\n=== Results: %d passed, %d failed ===" % [total_passed, total_failed])
    quit(1 if total_failed > 0 else 0)
```

- [ ] **Step 2: 헤드리스 실행 확인**

```bash
cd "H:/AIRelatedDefaultPath/ClaudeCode_Base/GameProjects/CardGameProject/stsl"
godot --headless -s tests/test_runner.gd
```

Expected output:
```
=== Results: 0 passed, 0 failed ===
```
종료 코드 0이면 성공.

- [ ] **Step 3: 커밋**

```bash
git add tests/test_runner.gd
git commit -m "test: 헤드리스 테스트 러너 뼈대"
```

---

### Task 2: EffectResource

**Files:**
- Create: `resources/effect_resource.gd`
- Modify: `tests/test_resources.gd` (신규 생성)
- Modify: `tests/test_runner.gd` (suite 등록)

- [ ] **Step 1: 실패하는 테스트 작성**

```gdscript
# tests/test_resources.gd
class_name TestResources
extends RefCounted

var passed: int = 0
var failed: int = 0

func run_all() -> Dictionary:
    test_effect_resource_defaults()
    return {"passed": passed, "failed": failed}

func _assert(condition: bool, msg: String) -> void:
    if condition:
        passed += 1
        print("  PASS: " + msg)
    else:
        failed += 1
        push_error("  FAIL: " + msg)

func test_effect_resource_defaults() -> void:
    print("[TestResources] test_effect_resource_defaults")
    var effect = EffectResource.new()
    _assert(effect.value == 0, "기본 value == 0")
    _assert(effect.target == "SINGLE", "기본 target == SINGLE")
    _assert(effect.status_type == "", "기본 status_type 비어있음")
```

test_runner.gd의 suites 배열 수정:
```gdscript
# tests/test_runner.gd — suites 줄 교체
var suites: Array = [TestResources.new()]
```

- [ ] **Step 2: 실패 확인**

```bash
godot --headless -s tests/test_runner.gd
```

Expected: `Parse Error` 또는 `Identifier 'EffectResource' not found` — EffectResource가 없으므로 실패.

- [ ] **Step 3: EffectResource 구현**

```gdscript
# resources/effect_resource.gd
class_name EffectResource
extends Resource

enum EffectType {
    DAMAGE,       # 피해
    BLOCK,        # 방어도
    APPLY_STATUS, # 상태이상 부여 (status_type 참조)
    DRAW,         # 카드 드로우
    ENERGY,       # 에너지 획득
    SUMMON_TOKEN, # 병사 토큰 소환 (나폴레옹)
    CHARM,        # 매혹 부여 (클레오파트라)
    HEAL,         # HP 회복
}

@export var effect_type: EffectType = EffectType.DAMAGE
@export var value: int = 0
@export var target: String = "SINGLE"   # SINGLE / ALL / SELF
@export var status_type: String = ""    # APPLY_STATUS 시 상태이상 종류
                                        # "poison","weak","vulnerable","taunt","strength"
```

- [ ] **Step 4: 통과 확인**

```bash
godot --headless -s tests/test_runner.gd
```

Expected:
```
[TestResources] test_effect_resource_defaults
  PASS: 기본 value == 0
  PASS: 기본 target == SINGLE
  PASS: 기본 status_type 비어있음

=== Results: 3 passed, 0 failed ===
```

- [ ] **Step 5: 커밋**

```bash
git add resources/effect_resource.gd tests/test_resources.gd tests/test_runner.gd
git commit -m "feat: EffectResource 데이터 클래스"
```

---

### Task 3: CardResource

**Files:**
- Create: `resources/card_resource.gd`
- Modify: `tests/test_resources.gd`

- [ ] **Step 1: 실패하는 테스트 추가**

`test_resources.gd`의 `run_all()` 내 마지막 줄 앞에 추가:
```gdscript
func run_all() -> Dictionary:
    test_effect_resource_defaults()
    test_card_resource_defaults()      # 추가
    return {"passed": passed, "failed": failed}
```

아래 메서드 추가:
```gdscript
func test_card_resource_defaults() -> void:
    print("[TestResources] test_card_resource_defaults")
    var card = CardResource.new()
    _assert(card.cost == 1, "기본 cost == 1")
    _assert(card.upgraded == false, "기본 upgraded == false")
    _assert(card.card_type == CardResource.CardType.ATTACK, "기본 타입 ATTACK")
    _assert(card.effects.size() == 0, "기본 effects 비어있음")
    _assert(card.owner_id == "", "기본 owner_id 비어있음")
    _assert(card.play_animation == "", "기본 play_animation 비어있음")
```

- [ ] **Step 2: 실패 확인**

```bash
godot --headless -s tests/test_runner.gd
```

Expected: `Identifier 'CardResource' not found`

- [ ] **Step 3: CardResource 구현**

```gdscript
# resources/card_resource.gd
class_name CardResource
extends Resource

enum CardType { ATTACK, SKILL, POWER }

@export var card_name: String = ""
@export var owner_id: String = ""          # HeroResource.hero_id 참조
@export var cost: int = 1
@export var card_type: CardType = CardType.ATTACK
@export var effects: Array[EffectResource] = []
@export var upgraded: bool = false
@export var description: String = ""
@export var art: Texture2D                 # 카드 일러스트 (정적 이미지)
@export var play_animation: String = ""    # 카드 사용 시 캐릭터가 재생할 애니메이션 이름
                                           # 예: "attack_blitz", "skill_turtle_ship"
```

- [ ] **Step 4: 통과 확인**

```bash
godot --headless -s tests/test_runner.gd
```

Expected: `=== Results: 8 passed, 0 failed ===`

- [ ] **Step 5: 커밋**

```bash
git add resources/card_resource.gd tests/test_resources.gd
git commit -m "feat: CardResource 데이터 클래스"
```

---

### Task 4: HeroResource

**Files:**
- Create: `resources/hero_resource.gd`
- Modify: `tests/test_resources.gd`

- [ ] **Step 1: 실패하는 테스트 추가**

`run_all()` 내 추가:
```gdscript
func run_all() -> Dictionary:
    test_effect_resource_defaults()
    test_card_resource_defaults()
    test_hero_resource_defaults()      # 추가
    return {"passed": passed, "failed": failed}
```

```gdscript
func test_hero_resource_defaults() -> void:
    print("[TestResources] test_hero_resource_defaults")
    var hero = HeroResource.new()
    _assert(hero.max_hp == 70, "기본 max_hp == 70")
    _assert(hero.card_pool.size() == 0, "기본 카드풀 비어있음")
    _assert(hero.hero_id == "", "기본 hero_id 비어있음")
```

- [ ] **Step 2: 실패 확인**

```bash
godot --headless -s tests/test_runner.gd
```

Expected: `Identifier 'HeroResource' not found`

- [ ] **Step 3: HeroResource 구현**

```gdscript
# resources/hero_resource.gd
class_name HeroResource
extends Resource

@export var hero_id: String = ""             # 고유 식별자 (예: "napoleon")
@export var hero_name: String = ""           # 표시명
@export var historical_figure: String = ""   # 역사 인물 원래 이름
@export var max_hp: int = 70
@export var card_pool: Array[CardResource] = []
@export var character_scene: PackedScene     # 캐릭터 애니메이션 씬 (AnimationPlayer 포함)
                                             # Blender 스프라이트 시트 교체 시 씬 내부만 수정
@export var portrait: Texture2D              # UI용 초상화 (정적 이미지)
```

- [ ] **Step 4: 통과 확인**

```bash
godot --headless -s tests/test_runner.gd
```

Expected: `=== Results: 11 passed, 0 failed ===`

- [ ] **Step 5: 커밋**

```bash
git add resources/hero_resource.gd tests/test_resources.gd
git commit -m "feat: HeroResource 데이터 클래스"
```

---

### Task 5: IntentResource & EnemyResource

**Files:**
- Create: `resources/intent_resource.gd`
- Create: `resources/enemy_resource.gd`
- Modify: `tests/test_resources.gd`

- [ ] **Step 1: 실패하는 테스트 추가**

`run_all()` 내 추가:
```gdscript
func run_all() -> Dictionary:
    test_effect_resource_defaults()
    test_card_resource_defaults()
    test_hero_resource_defaults()
    test_enemy_resource_defaults()    # 추가
    return {"passed": passed, "failed": failed}
```

```gdscript
func test_enemy_resource_defaults() -> void:
    print("[TestResources] test_enemy_resource_defaults")
    var enemy = EnemyResource.new()
    _assert(enemy.grade == EnemyResource.Grade.NORMAL, "기본 등급 NORMAL")
    _assert(enemy.max_hp == 30, "기본 max_hp == 30")
    _assert(enemy.intent_pattern.size() == 0, "기본 행동 패턴 비어있음")
    _assert(enemy.phase_thresholds.size() == 0, "기본 페이즈 비어있음")

    var intent = IntentResource.new()
    _assert(intent.value == 0, "intent 기본 value == 0")
    _assert(intent.action_type == IntentResource.ActionType.ATTACK, "기본 행동 ATTACK")
    _assert(intent.target == IntentResource.TargetType.RANDOM, "기본 타겟 RANDOM")
    _assert(intent.play_animation == "", "기본 play_animation 비어있음")
```

- [ ] **Step 2: 실패 확인**

```bash
godot --headless -s tests/test_runner.gd
```

Expected: `Identifier 'EnemyResource' not found`

- [ ] **Step 3: IntentResource 구현**

```gdscript
# resources/intent_resource.gd
class_name IntentResource
extends Resource

enum ActionType { ATTACK, BUFF, DEBUFF, SPECIAL }
enum TargetType { LOWEST_HP, LAST_ATTACKER, RANDOM, ALL }

@export var action_type: ActionType = ActionType.ATTACK
@export var value: int = 0
@export var target: TargetType = TargetType.RANDOM
@export var condition: String = ""         # 발동 조건 표현식 (빈 문자열 = 항상)
@export var play_animation: String = ""    # 이 행동 실행 시 몬스터가 재생할 애니메이션
                                           # 예: "attack_charge", "buff_enrage"
```

- [ ] **Step 4: EnemyResource 구현**

```gdscript
# resources/enemy_resource.gd
class_name EnemyResource
extends Resource

enum Grade { NORMAL, ELITE, BOSS }

@export var enemy_name: String = ""
@export var mythology: String = ""          # 소속 신화권 (예: "greek")
@export var grade: Grade = Grade.NORMAL
@export var max_hp: int = 30
@export var intent_pattern: Array[IntentResource] = []
@export var phase_thresholds: Array[float] = []  # 페이즈 전환 HP 비율 (예: [0.6, 0.3])
@export var character_scene: PackedScene    # 몬스터 애니메이션 씬 (AnimationPlayer 포함)
```

- [ ] **Step 5: 통과 확인**

```bash
godot --headless -s tests/test_runner.gd
```

Expected: `=== Results: 18 passed, 0 failed ===`

- [ ] **Step 6: 커밋**

```bash
git add resources/intent_resource.gd resources/enemy_resource.gd tests/test_resources.gd
git commit -m "feat: IntentResource + EnemyResource 데이터 클래스"
```

---

### Task 6: RelicResource

**Files:**
- Create: `resources/relic_resource.gd`
- Modify: `tests/test_resources.gd`

- [ ] **Step 1: 실패하는 테스트 추가**

`run_all()` 내 추가:
```gdscript
func run_all() -> Dictionary:
    test_effect_resource_defaults()
    test_card_resource_defaults()
    test_hero_resource_defaults()
    test_enemy_resource_defaults()
    test_relic_resource_defaults()    # 추가
    return {"passed": passed, "failed": failed}
```

```gdscript
func test_relic_resource_defaults() -> void:
    print("[TestResources] test_relic_resource_defaults")
    var relic = RelicResource.new()
    _assert(relic.owner_id == "", "기본 owner_id 비어있음 = 공용 릴릭")
    _assert(relic.relic_name == "", "기본 relic_name 비어있음")
```

- [ ] **Step 2: 실패 확인**

```bash
godot --headless -s tests/test_runner.gd
```

Expected: `Identifier 'RelicResource' not found`

- [ ] **Step 3: RelicResource 구현**

```gdscript
# resources/relic_resource.gd
class_name RelicResource
extends Resource

@export var relic_name: String = ""
@export var owner_id: String = ""            # "" = 공용. hero_id 값 = 전용 릴릭
@export var base_effect: EffectResource      # 항상 적용되는 기본 효과
@export var bonus_effect: EffectResource     # owner_id 캐릭터 생존 시 추가 효과
@export var description: String = ""
@export var art: Texture2D
```

- [ ] **Step 4: 통과 확인**

```bash
godot --headless -s tests/test_runner.gd
```

Expected: `=== Results: 20 passed, 0 failed ===`

- [ ] **Step 5: 커밋**

```bash
git add resources/relic_resource.gd tests/test_resources.gd
git commit -m "feat: RelicResource 데이터 클래스"
```

---

### Task 7: TeamManager Autoload

TeamManager는 팀원 목록, 현재 HP, 생사 상태를 관리한다. 이 로직은 씬 없이 단독으로 테스트 가능하다.

**Files:**
- Create: `autoload/team_manager.gd`
- Create: `tests/test_team_manager.gd`
- Modify: `tests/test_runner.gd`

- [ ] **Step 1: 실패하는 테스트 작성**

```gdscript
# tests/test_team_manager.gd
class_name TestTeamManager
extends RefCounted

var passed: int = 0
var failed: int = 0

func run_all() -> Dictionary:
    test_add_hero()
    test_take_damage()
    test_hero_death()
    return {"passed": passed, "failed": failed}

func _assert(condition: bool, msg: String) -> void:
    if condition:
        passed += 1
        print("  PASS: " + msg)
    else:
        failed += 1
        push_error("  FAIL: " + msg)

func _make_hero(id: String, hp: int) -> HeroResource:
    var hero = HeroResource.new()
    hero.hero_id = id
    hero.max_hp = hp
    return hero

func test_add_hero() -> void:
    print("[TestTeamManager] test_add_hero")
    var tm = TeamManagerClass.new()
    var hero = _make_hero("napoleon", 80)
    tm.add_hero(hero)
    _assert(tm.get_current_hp("napoleon") == 80, "추가 후 HP == max_hp")
    _assert(tm.is_alive("napoleon") == true, "추가 후 생존 상태")

func test_take_damage() -> void:
    print("[TestTeamManager] test_take_damage")
    var tm = TeamManagerClass.new()
    tm.add_hero(_make_hero("napoleon", 80))
    tm.take_damage("napoleon", 20)
    _assert(tm.get_current_hp("napoleon") == 60, "20 피해 후 HP == 60")

func test_hero_death() -> void:
    print("[TestTeamManager] test_hero_death")
    var tm = TeamManagerClass.new()
    tm.add_hero(_make_hero("napoleon", 80))
    tm.take_damage("napoleon", 80)
    _assert(tm.get_current_hp("napoleon") == 0, "치사 피해 후 HP == 0")
    _assert(tm.is_alive("napoleon") == false, "치사 피해 후 사망 상태")
```

test_runner.gd suites 갱신:
```gdscript
var suites: Array = [TestResources.new(), TestTeamManager.new()]
```

- [ ] **Step 2: 실패 확인**

```bash
godot --headless -s tests/test_runner.gd
```

Expected: `Identifier 'TeamManagerClass' not found`

- [ ] **Step 3: TeamManager 구현**

테스트에서는 Autoload 싱글톤에 직접 접근하기 어려우므로, 로직을 담은 클래스를 `TeamManagerClass`로 정의하고 Autoload는 이를 상속한다.

```gdscript
# autoload/team_manager.gd
class_name TeamManagerClass
extends Node

var heroes: Array[HeroResource] = []
var _hero_hp: Dictionary = {}      # hero_id -> int
var _hero_alive: Dictionary = {}   # hero_id -> bool

signal hero_died(hero_id: String)
signal hero_revived(hero_id: String)

func add_hero(hero: HeroResource) -> void:
    heroes.append(hero)
    _hero_hp[hero.hero_id] = hero.max_hp
    _hero_alive[hero.hero_id] = true

func take_damage(hero_id: String, amount: int) -> void:
    if not _hero_alive.get(hero_id, false):
        return
    _hero_hp[hero_id] = max(0, _hero_hp[hero_id] - amount)
    if _hero_hp[hero_id] == 0:
        _hero_alive[hero_id] = false
        hero_died.emit(hero_id)

func heal(hero_id: String, amount: int) -> void:
    if not _hero_alive.get(hero_id, false):
        return
    var hero: HeroResource = get_hero(hero_id)
    if hero == null:
        return
    _hero_hp[hero_id] = min(hero.max_hp, _hero_hp[hero_id] + amount)

func revive(hero_id: String, hp: int) -> void:
    if not _hero_hp.has(hero_id):
        return
    _hero_alive[hero_id] = true
    _hero_hp[hero_id] = hp
    hero_revived.emit(hero_id)

func get_current_hp(hero_id: String) -> int:
    return _hero_hp.get(hero_id, 0)

func is_alive(hero_id: String) -> bool:
    return _hero_alive.get(hero_id, false)

func get_hero(hero_id: String) -> HeroResource:
    for hero in heroes:
        if hero.hero_id == hero_id:
            return hero
    return null

func get_living_heroes() -> Array[HeroResource]:
    var result: Array[HeroResource] = []
    for hero in heroes:
        if _hero_alive.get(hero.hero_id, false):
            result.append(hero)
    return result

func clear() -> void:
    heroes.clear()
    _hero_hp.clear()
    _hero_alive.clear()
```

- [ ] **Step 4: 통과 확인**

```bash
godot --headless -s tests/test_runner.gd
```

Expected: `=== Results: 26 passed, 0 failed ===`

- [ ] **Step 5: 커밋**

```bash
git add autoload/team_manager.gd tests/test_team_manager.gd tests/test_runner.gd
git commit -m "feat: TeamManager — 팀원 HP/생사 관리"
```

---

### Task 8: DeckManager Autoload

DeckManager는 드로우/손패/버림/소진 더미와 에너지를 관리한다.

**Files:**
- Create: `autoload/deck_manager.gd`
- Create: `tests/test_deck_manager.gd`
- Modify: `tests/test_runner.gd`

- [ ] **Step 1: 실패하는 테스트 작성**

```gdscript
# tests/test_deck_manager.gd
class_name TestDeckManager
extends RefCounted

var passed: int = 0
var failed: int = 0

func run_all() -> Dictionary:
    test_draw_cards()
    test_energy_cost()
    test_reshuffle_on_empty()
    test_discard_hand()
    return {"passed": passed, "failed": failed}

func _assert(condition: bool, msg: String) -> void:
    if condition:
        passed += 1
        print("  PASS: " + msg)
    else:
        failed += 1
        push_error("  FAIL: " + msg)

func _make_card(name: String, cost: int = 1) -> CardResource:
    var card = CardResource.new()
    card.card_name = name
    card.cost = cost
    return card

func test_draw_cards() -> void:
    print("[TestDeckManager] test_draw_cards")
    var dm = DeckManagerClass.new()
    for i in range(10):
        dm.draw_pile.append(_make_card("card_%d" % i))
    dm.draw_cards(5)
    _assert(dm.hand.size() == 5, "5장 드로우 후 손패 5장")
    _assert(dm.draw_pile.size() == 5, "드로우 후 드로우 파일 5장")

func test_energy_cost() -> void:
    print("[TestDeckManager] test_energy_cost")
    var dm = DeckManagerClass.new()
    dm.current_energy = 3
    var card = _make_card("attack", 2)
    dm.hand.append(card)
    dm.draw_pile.append(_make_card("dummy"))  # discard 후 draw_pile에 넣기 위해
    var result = dm.play_card(card)
    _assert(result == true, "에너지 충분 시 카드 사용 성공")
    _assert(dm.current_energy == 1, "2 비용 카드 후 에너지 == 1")
    _assert(dm.hand.size() == 0, "플레이 후 손패에서 제거됨")
    _assert(dm.discard_pile.size() == 1, "플레이 후 버림 더미에 추가됨")

func test_reshuffle_on_empty() -> void:
    print("[TestDeckManager] test_reshuffle_on_empty")
    var dm = DeckManagerClass.new()
    for i in range(3):
        dm.discard_pile.append(_make_card("card_%d" % i))
    dm.draw_cards(5)  # 드로우 파일 비어있음 → 버림 더미 셔플해서 충전
    _assert(dm.hand.size() == 3, "버림 더미 3장 → 손패 3장 드로우")
    _assert(dm.discard_pile.size() == 0, "셔플 후 버림 더미 비어있음")

func test_discard_hand() -> void:
    print("[TestDeckManager] test_discard_hand")
    var dm = DeckManagerClass.new()
    for i in range(5):
        dm.hand.append(_make_card("card_%d" % i))
    dm.discard_hand()
    _assert(dm.hand.size() == 0, "턴 종료 후 손패 비어있음")
    _assert(dm.discard_pile.size() == 5, "턴 종료 후 버림 더미 5장")
```

test_runner.gd suites 갱신:
```gdscript
var suites: Array = [TestResources.new(), TestTeamManager.new(), TestDeckManager.new()]
```

- [ ] **Step 2: 실패 확인**

```bash
godot --headless -s tests/test_runner.gd
```

Expected: `Identifier 'DeckManagerClass' not found`

- [ ] **Step 3: DeckManager 구현**

```gdscript
# autoload/deck_manager.gd
class_name DeckManagerClass
extends Node

const HAND_SIZE: int = 5
const MAX_ENERGY: int = 3

var draw_pile: Array[CardResource] = []
var hand: Array[CardResource] = []
var discard_pile: Array[CardResource] = []
var exhaust_pile: Array[CardResource] = []
var current_energy: int = 0

signal card_drawn(card: CardResource)
signal card_played(card: CardResource)
signal hand_changed()
signal energy_changed(new_energy: int)

func start_turn() -> void:
    current_energy = MAX_ENERGY
    energy_changed.emit(current_energy)
    draw_cards(HAND_SIZE)

func draw_cards(count: int) -> void:
    for i in range(count):
        if draw_pile.is_empty():
            _reshuffle()
        if draw_pile.is_empty():
            break
        var card: CardResource = draw_pile.pop_back()
        hand.append(card)
        card_drawn.emit(card)
    hand_changed.emit()

func _reshuffle() -> void:
    draw_pile = discard_pile.duplicate()
    draw_pile.shuffle()
    discard_pile.clear()

func can_play(card: CardResource) -> bool:
    return hand.has(card) and current_energy >= card.cost

func play_card(card: CardResource) -> bool:
    if not can_play(card):
        return false
    current_energy -= card.cost
    energy_changed.emit(current_energy)
    hand.erase(card)
    discard_pile.append(card)
    card_played.emit(card)
    hand_changed.emit()
    return true

func exhaust_card(card: CardResource) -> void:
    hand.erase(card)
    exhaust_pile.append(card)
    hand_changed.emit()

func discard_hand() -> void:
    for card in hand:
        discard_pile.append(card)
    hand.clear()
    hand_changed.emit()

func add_card_to_deck(card: CardResource) -> void:
    discard_pile.append(card)

func get_full_deck() -> Array[CardResource]:
    var full: Array[CardResource] = []
    full.append_array(draw_pile)
    full.append_array(hand)
    full.append_array(discard_pile)
    return full

func clear() -> void:
    draw_pile.clear()
    hand.clear()
    discard_pile.clear()
    exhaust_pile.clear()
    current_energy = 0
```

- [ ] **Step 4: 통과 확인**

```bash
godot --headless -s tests/test_runner.gd
```

Expected: `=== Results: 40 passed, 0 failed ===`

- [ ] **Step 5: 커밋**

```bash
git add autoload/deck_manager.gd tests/test_deck_manager.gd tests/test_runner.gd
git commit -m "feat: DeckManager — 드로우/손패/에너지 관리"
```

---

### Task 9: GameManager Autoload

GameManager는 런 상태(어느 씬에 있는지), 현재 층/챕터, 골드, 릴릭 목록을 관리한다.

**Files:**
- Create: `autoload/game_manager.gd`

> GameManager는 씬 전환을 다루므로 헤드리스 환경에서 완전한 테스트가 어렵다. 기본값 검증만 test_resources.gd에 추가한다.

- [ ] **Step 1: GameManager 구현**

```gdscript
# autoload/game_manager.gd
class_name GameManagerClass
extends Node

enum GameState { MAP, BATTLE, CARD_PICK, EVENT, SHOP, REST }

var current_state: GameState = GameState.MAP
var current_floor: int = 0
var current_chapter: int = 1
var gold: int = 0
var relics: Array[RelicResource] = []

signal state_changed(new_state: GameState)
signal gold_changed(new_gold: int)
signal relic_added(relic: RelicResource)

func change_state(new_state: GameState) -> void:
    current_state = new_state
    state_changed.emit(new_state)

func add_gold(amount: int) -> void:
    gold += amount
    gold_changed.emit(gold)

func spend_gold(amount: int) -> bool:
    if gold < amount:
        return false
    gold -= amount
    gold_changed.emit(gold)
    return true

func add_relic(relic: RelicResource) -> void:
    relics.append(relic)
    relic_added.emit(relic)

func has_relic(relic_name: String) -> bool:
    for r in relics:
        if r.relic_name == relic_name:
            return true
    return false

func reset() -> void:
    current_state = GameState.MAP
    current_floor = 0
    current_chapter = 1
    gold = 0
    relics.clear()
```

- [ ] **Step 2: GameManager 기본값 테스트 추가**

`tests/test_resources.gd`의 `run_all()` 내 추가:
```gdscript
func run_all() -> Dictionary:
    test_effect_resource_defaults()
    test_card_resource_defaults()
    test_hero_resource_defaults()
    test_enemy_resource_defaults()
    test_relic_resource_defaults()
    test_game_manager_defaults()    # 추가
    return {"passed": passed, "failed": failed}
```

```gdscript
func test_game_manager_defaults() -> void:
    print("[TestResources] test_game_manager_defaults")
    var gm = GameManagerClass.new()
    _assert(gm.current_state == GameManagerClass.GameState.MAP, "초기 상태 MAP")
    _assert(gm.current_chapter == 1, "초기 챕터 1")
    _assert(gm.gold == 0, "초기 골드 0")
    _assert(gm.relics.size() == 0, "초기 릴릭 없음")
```

- [ ] **Step 3: 통과 확인**

```bash
godot --headless -s tests/test_runner.gd
```

Expected: `=== Results: 44 passed, 0 failed ===`

- [ ] **Step 4: 커밋**

```bash
git add autoload/game_manager.gd tests/test_resources.gd
git commit -m "feat: GameManager — 런 상태/골드/릴릭 관리"
```

---

### Task 10: Autoload 등록 (project.godot)

**Files:**
- Modify: `project.godot`

- [ ] **Step 1: project.godot에 Autoload 섹션 추가**

`project.godot` 파일 끝에 추가:
```ini
[autoload]

GameManager="*res://autoload/game_manager.gd"
TeamManager="*res://autoload/team_manager.gd"
DeckManager="*res://autoload/deck_manager.gd"
```

- [ ] **Step 2: Godot 에디터에서 확인**

Godot 에디터 열기 → Project → Project Settings → Autoload 탭에 3개의 싱글톤이 보여야 함:
- `GameManager`
- `TeamManager`
- `DeckManager`

- [ ] **Step 3: 헤드리스 최종 테스트**

```bash
godot --headless -s tests/test_runner.gd
```

Expected: `=== Results: 44 passed, 0 failed ===`

- [ ] **Step 4: 최종 커밋**

```bash
git add project.godot
git commit -m "feat: Autoload 싱글톤 등록 (GameManager, TeamManager, DeckManager)"
git push origin main
```

---

### Task 11: 플레이스홀더 캐릭터 씬 제작

각 캐릭터/몬스터 씬에 `AnimationPlayer` + `ColorRect`(색상 블록)로 구성된 플레이스홀더를 만든다.
Blender 스프라이트 시트가 나오면 `ColorRect`만 `AnimatedSprite2D`로 교체하면 된다.

**Files:**
- Create: `characters/heroes/napoleon/napoleon.tscn`
- Create: `characters/heroes/yi_sun_sin/yi_sun_sin.tscn`
- Create: `characters/heroes/cleopatra/cleopatra.tscn`
- Create: `characters/enemies/satyr/satyr.tscn`

> 씬은 Godot 에디터에서 직접 생성한다. 헤드리스 테스트 대상이 아니며, 에디터에서 씬을 열어 애니메이션이 재생되는지 확인한다.

- [ ] **Step 1: 공통 캐릭터 베이스 구조 파악**

모든 캐릭터 씬이 같은 구조를 가진다:
```
Node2D (root)
  └ ColorRect          ← 플레이스홀더 색상 블록 (캐릭터별 고유 색상)
  └ AnimationPlayer    ← idle, attack, hurt, death 애니메이션
```

- [ ] **Step 2: napoleon.tscn 생성**

Godot 에디터에서:
1. `characters/heroes/napoleon/` 폴더 생성
2. 새 씬 생성 → Root: `Node2D`, 이름 `Napoleon`
3. 자식 노드 추가:
   - `ColorRect`: Position `(-40, -80)`, Size `(80, 80)`, Color `#4169E1` (파란색)
   - `AnimationPlayer`: 이름 `AnimationPlayer`
4. `AnimationPlayer`에 애니메이션 추가:
   - **`idle`** (loop): 길이 1.2초
     - `ColorRect` position.y: 0s→`-80`, 0.6s→`-88`, 1.2s→`-80` (살짝 위아래 bounce)
   - **`attack`**: 길이 0.5초
     - `ColorRect` position.x: 0s→`-40`, 0.2s→`20`, 0.5s→`-40` (앞으로 돌진)
   - **`hurt`**: 길이 0.4초
     - `ColorRect` modulate: 0s→`white`, 0.1s→`#FF4444`, 0.4s→`white` (빨간 flash)
   - **`death`**: 길이 0.8초
     - `ColorRect` modulate.a: 0s→`1.0`, 0.8s→`0.0` (fade out)
5. `idle` 애니메이션을 Autoplay로 설정
6. 씬 저장: `characters/heroes/napoleon/napoleon.tscn`

- [ ] **Step 3: yi_sun_sin.tscn 생성**

Step 2와 동일한 구조, 색상만 `#228B22` (초록색).
저장: `characters/heroes/yi_sun_sin/yi_sun_sin.tscn`

- [ ] **Step 4: cleopatra.tscn 생성**

Step 2와 동일한 구조, 색상만 `#DAA520` (골든색).
저장: `characters/heroes/cleopatra/cleopatra.tscn`

- [ ] **Step 5: satyr.tscn 생성 (몬스터 예시)**

1. `characters/enemies/satyr/` 폴더 생성
2. 새 씬 → Root: `Node2D`, 이름 `Satyr`
3. 자식 노드:
   - `ColorRect`: Position `(-30, -60)`, Size `(60, 60)`, Color `#8B0000` (어두운 빨간색)
   - `AnimationPlayer`
4. 애니메이션:
   - **`idle`** (loop): 길이 1.0초, ColorRect position.y bounce (`-60` → `-66` → `-60`)
   - **`attack`**: 길이 0.5초, ColorRect position.x 앞으로 돌진 (`-30` → `-90` → `-30`, 몬스터는 왼쪽 방향이므로 x 감소)
   - **`hurt`**: 길이 0.4초, ColorRect modulate 빨간 flash
   - **`death`**: 길이 0.8초, modulate.a fade out
5. 저장: `characters/enemies/satyr/satyr.tscn`

- [ ] **Step 6: 에디터에서 씬 확인**

각 씬을 열어:
- `idle` 애니메이션이 자동 재생되는지 확인
- `attack`, `hurt`, `death` 애니메이션을 수동으로 재생해 동작 확인

- [ ] **Step 7: 커밋**

```bash
git add characters/
git commit -m "feat: 플레이스홀더 캐릭터/몬스터 씬 (ColorRect + AnimationPlayer)"
git push origin main
```

---

## Self-Review

### Spec Coverage

| GDD 항목 | 구현 태스크 |
|---|---|
| CardResource 구조 + play_animation | Task 3 |
| HeroResource 구조 + character_scene | Task 4 |
| EnemyResource + IntentResource + play_animation | Task 5 |
| RelicResource 구조 (owner_id, base_effect, bonus_effect) | Task 6 |
| EffectResource (피해/방어/상태이상/드로우/에너지) | Task 2 |
| GameManager (GameState enum, 런 상태) | Task 9 |
| TeamManager (HP, 생사, 시그널) | Task 7 |
| DeckManager (드로우/손패/버림/에너지) | Task 8 |
| Autoload 등록 | Task 10 |
| 헤드리스 테스트 기반 | Task 1 |
| 플레이스홀더 캐릭터 씬 (AnimationPlayer 구조) | Task 11 |

**누락 없음.**

### Placeholder 없음
모든 태스크에 완성된 GDScript 코드 포함.

### 타입 일관성
- `owner_id: String` — CardResource, RelicResource 모두 동일 (HeroResource.hero_id 참조)
- `hero_id: String` — HeroResource, TeamManager._hero_hp 키 모두 동일
- `Array[CardResource]` — HeroResource.card_pool, DeckManager 모든 더미 동일
- `Array[RelicResource]` — GameManager.relics 동일
