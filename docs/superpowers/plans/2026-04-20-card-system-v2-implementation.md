# 카드 시스템 v2 구현 플랜

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** HP 1000 스케일 + 5등급 카드 체계 구현 — CardResource 스키마 변경, 강화 로직 재작성, 카드·적 데이터 전면 재설정.

**Architecture:** CardResource에 `rarity` enum과 `upgrade_level` int를 추가하고, EffectResource에 `base_value` 필드를 추가해 강화 계산 기준값을 보존한다. upgrade_card()는 등급별 비율(10~16%)로 계산하며, 카드·적 데이터 파일을 HP 1000 스케일로 전면 재작성한다.

**Tech Stack:** GDScript 4, Godot 4.6.2, 헤드리스 테스트 러너

**Godot 실행 경로:** `"H:/Program Files/Godot/Godot_v4.6.2-stable_win64_console.exe"`

**테스트 실행 기본 명령:**
```bash
cd "H:/AIRelatedDefaultPath/ClaudeCode_Base/GameProjects/CardGameProject/stsl"
"H:/Program Files/Godot/Godot_v4.6.2-stable_win64_console.exe" --headless -s tests/test_runner.gd 2>&1
```

**기획 문서 위치:**
- `docs/game_design/cards_framework_v1.md` — 등급·강화 규칙
- `docs/game_design/cards_napoleon_v2.md` — 나폴레옹 40장
- `docs/game_design/cards_cleopatra_v2.md` — 클레오파트라 40장
- `docs/game_design/cards_yi_sun_sin_v2.md` — 이순신 40장
- `docs/game_design/enemies_act1_v1.md` — 적 10종

---

## 파일 구조

| 파일 | 변경 | 내용 |
|---|---|---|
| `resources/effect_resource.gd` | 수정 | `base_value: int` 필드 추가 |
| `resources/card_resource.gd` | 수정 | `Rarity` enum, `upgrade_level`, `can_upgrade()`, `max_upgrade_level()` 추가; `upgraded: bool` 제거 |
| `autoload/game_manager.gd` | 수정 | `upgrade_card()` 재작성, 영웅 HP 1000으로 변경 |
| `resources/cards/cards_napoleon.gd` | **전면 재작성** | 40장, HP 1000 스케일, rarity 설정 |
| `resources/cards/cards_cleopatra.gd` | **전면 재작성** | 40장 |
| `resources/cards/cards_yi_sun_sin.gd` | **전면 재작성** | 40장 |
| `resources/enemies/enemies_act1.gd` | **전면 재작성** | 10종, HP 300~4500 스케일 |

---

## Task 1: EffectResource — base_value 필드 추가

**Files:**
- Modify: `resources/effect_resource.gd`

강화 계산의 기준값(0강 수치)을 보존하기 위해 `base_value` 필드를 추가한다. 카드 생성 시 `e.base_value = e.value`로 초기화한다.

- [ ] **Step 1: base_value 필드 추가**

`resources/effect_resource.gd`의 마지막 줄 뒤에 추가:

```gdscript
@export var base_value: int = 0         # 0강 기준값. 강화 공식의 베이스. 카드 생성 시 value와 동일하게 초기화.
```

최종 파일:
```gdscript
# resources/effect_resource.gd
class_name EffectResource
extends Resource

enum EffectType {
	DAMAGE,
	BLOCK,
	APPLY_STATUS,
	DRAW,
	ENERGY,
	SUMMON_TOKEN,
	CHARM,
	HEAL,
	GAIN_MORALE,
	CONSUME_MORALE,
	POISON_BURST,
	COUNTER_BLOCK,
	BLOCK_ALL,
	HEAL_ALL,
	FORMATION_BLOCK,
	COST_NEXT,
	CONDITIONAL_DMG,
}

@export var effect_type: EffectType = EffectType.DAMAGE
@export var value: int = 0
@export var target: String = "SINGLE"
@export var status_type: String = ""
@export var bonus_value: int = 0
@export var base_value: int = 0
@export var base_bonus_value: int = 0   # bonus_value의 0강 기준값
```

- [ ] **Step 2: 기존 테스트 통과 확인**

```bash
cd "H:/AIRelatedDefaultPath/ClaudeCode_Base/GameProjects/CardGameProject/stsl"
"H:/Program Files/Godot/Godot_v4.6.2-stable_win64_console.exe" --headless -s tests/test_runner.gd 2>&1
```

기존 테스트가 깨지지 않아야 함 (base_value 기본값 0이므로 하위 호환).

- [ ] **Step 3: 커밋**

```bash
git add resources/effect_resource.gd
git commit -m "feat: EffectResource — base_value, base_bonus_value 필드 추가"
```

---

## Task 2: CardResource — Rarity enum + upgrade_level 추가

**Files:**
- Modify: `resources/card_resource.gd`

`upgraded: bool`을 제거하고 `rarity: Rarity`와 `upgrade_level: int`를 도입한다. 헬퍼 메서드로 강화 가능 여부와 최대 강화 횟수를 캡슐화한다.

- [ ] **Step 1: card_resource.gd 전체 재작성**

```gdscript
# resources/card_resource.gd
class_name CardResource
extends Resource

enum CardType { ATTACK, SKILL, POWER }

enum Rarity {
	COMMON,     # 0강 고정
	UNCOMMON,   # 1강까지
	RARE,       # 1강까지
	LEGENDARY,  # 2강까지
	DIVINE,     # 2강까지 + 단계별 유니크 효과
}

@export var card_name: String = ""
@export var owner_id: String = ""
@export var cost: int = 1
@export var card_type: CardType = CardType.ATTACK
@export var rarity: Rarity = Rarity.COMMON
@export var upgrade_level: int = 0
@export var effects: Array = []
@export var description: String = ""
@export var art: Texture2D
@export var play_animation: String = ""

func max_upgrade_level() -> int:
	match rarity:
		Rarity.COMMON:
			return 0
		Rarity.UNCOMMON, Rarity.RARE:
			return 1
		Rarity.LEGENDARY, Rarity.DIVINE:
			return 2
	return 0

func can_upgrade() -> bool:
	return upgrade_level < max_upgrade_level()
```

- [ ] **Step 2: 테스트 실행**

```bash
"H:/Program Files/Godot/Godot_v4.6.2-stable_win64_console.exe" --headless -s tests/test_runner.gd 2>&1
```

`card.upgraded` 참조가 있는 파일에서 에러가 발생할 수 있음. 다음 Task에서 game_manager.gd를 수정하면 해소됨. 파싱 에러만 아니면 진행.

- [ ] **Step 3: 커밋**

```bash
git add resources/card_resource.gd
git commit -m "feat: CardResource — Rarity enum, upgrade_level, can_upgrade() 추가 / upgraded 제거"
```

---

## Task 3: game_manager.gd — upgrade_card() 재작성

**Files:**
- Modify: `autoload/game_manager.gd` (라인 309~334 범위)

현재 고정값 +3 방식을 등급별 비율(UNCOMMON 10% / RARE 12% / LEGENDARY 14% / DIVINE 16%) 방식으로 교체한다. 정수 효과(DRAW, ENERGY 등)는 `base_value + upgrade_level`로 처리.

- [ ] **Step 1: upgrade_card 함수 교체**

`autoload/game_manager.gd`에서 `func upgrade_card(card: Resource) -> void:` 함수 전체를 아래로 교체:

```gdscript
func upgrade_card(card: Resource) -> void:
	if not card.can_upgrade():
		return
	card.upgrade_level += 1
	var level: int = card.upgrade_level
	var CardRes = load("res://resources/card_resource.gd")
	var EffRes = load("res://resources/effect_resource.gd")

	# 등급별 강화 비율
	var rate: float = 0.0
	match card.rarity:
		CardRes.Rarity.UNCOMMON:   rate = 0.10
		CardRes.Rarity.RARE:       rate = 0.12
		CardRes.Rarity.LEGENDARY:  rate = 0.14
		CardRes.Rarity.DIVINE:     rate = 0.16

	# 비율 적용 효과 타입 (base_value × (1 + rate × level))
	const PERCENT_TYPES = [
		EffRes.EffectType.DAMAGE,
		EffRes.EffectType.BLOCK,
		EffRes.EffectType.HEAL,
		EffRes.EffectType.BLOCK_ALL,
		EffRes.EffectType.HEAL_ALL,
		EffRes.EffectType.FORMATION_BLOCK,
		EffRes.EffectType.COUNTER_BLOCK,
		EffRes.EffectType.POISON_BURST,
		EffRes.EffectType.CONSUME_MORALE,
		EffRes.EffectType.CONDITIONAL_DMG,
	]

	# 정수 +1 효과 타입 (base_value + level)
	const INT_TYPES = [
		EffRes.EffectType.DRAW,
		EffRes.EffectType.ENERGY,
		EffRes.EffectType.GAIN_MORALE,
		EffRes.EffectType.APPLY_STATUS,
		EffRes.EffectType.CHARM,
		EffRes.EffectType.COST_NEXT,
		EffRes.EffectType.SUMMON_TOKEN,
	]

	for effect in card.effects:
		if effect.effect_type in PERCENT_TYPES:
			effect.value = int(effect.base_value * (1.0 + rate * level))
			effect.bonus_value = int(effect.base_bonus_value * (1.0 + rate * level))
		elif effect.effect_type in INT_TYPES:
			effect.value = effect.base_value + level
			effect.bonus_value = effect.base_bonus_value + level if effect.base_bonus_value > 0 else 0
```

- [ ] **Step 2: `card.upgraded` 참조를 `card.can_upgrade()` 또는 `card.upgrade_level > 0`으로 일괄 교체**

game_manager.gd 내에서 `card.upgraded`를 사용하는 곳 찾기:

```bash
grep -n "\.upgraded" H:/AIRelatedDefaultPath/ClaudeCode_Base/GameProjects/CardGameProject/stsl/autoload/game_manager.gd
```

각 참조를 문맥에 맞게 교체:
- 강화 여부 체크: `card.upgraded` → `card.upgrade_level > 0`
- 강화 가능 체크: `card.upgraded` → `!card.can_upgrade()`

- [ ] **Step 3: 프로젝트 전체 .upgraded 참조 확인**

```bash
grep -rn "\.upgraded" H:/AIRelatedDefaultPath/ClaudeCode_Base/GameProjects/CardGameProject/stsl --include="*.gd"
```

발견된 모든 `.upgraded` 참조를 `upgrade_level > 0`으로 교체.

- [ ] **Step 4: 테스트 실행**

```bash
"H:/Program Files/Godot/Godot_v4.6.2-stable_win64_console.exe" --headless -s tests/test_runner.gd 2>&1
```

- [ ] **Step 5: 커밋**

```bash
git add autoload/game_manager.gd
git commit -m "feat: upgrade_card() 재작성 — 등급별 비율 강화 (10/12/14/16%)"
```

---

## Task 4: game_manager.gd — 영웅 HP 1000으로 재설정

**Files:**
- Modify: `autoload/game_manager.gd` (라인 133~150 및 453, 462 근방)

- [ ] **Step 1: _make_hero_by_id의 max_hp 값 변경**

`autoload/game_manager.gd`에서:

```gdscript
# 변경 전
"napoleon":
    hero.max_hp = 70
"cleopatra":
    hero.max_hp = 60
"yi_sun_sin":
    hero.max_hp = 75

# 변경 후 (세 영웅 모두 1000)
"napoleon":
    hero.max_hp = 1000
"cleopatra":
    hero.max_hp = 1000
"yi_sun_sin":
    hero.max_hp = 1000
```

- [ ] **Step 2: 453, 462번 줄 근방의 max_hp 참조도 확인 및 수정**

```bash
grep -n "max_hp\s*=" H:/AIRelatedDefaultPath/ClaudeCode_Base/GameProjects/CardGameProject/stsl/autoload/game_manager.gd
```

모든 초기값 설정 위치를 1000으로 변경.

- [ ] **Step 3: 이벤트/렐릭에서 HP 증감량 비례 조정 필요 여부 확인**

```bash
grep -n "max_hp\|increase_max_hp\|heal\|damage" H:/AIRelatedDefaultPath/ClaudeCode_Base/GameProjects/CardGameProject/stsl/autoload/game_manager.gd | head -30
```

이벤트/렐릭에서 HP를 직접 수치로 증감하는 코드가 있으면 비례 조정 (예: +5 → +50). 단, 이번 Task에서는 영웅 초기 HP만 1000으로 변경하는 것을 목표로 함. 이벤트/렐릭 수치 조정은 별도 판단.

- [ ] **Step 4: 테스트 실행**

```bash
"H:/Program Files/Godot/Godot_v4.6.2-stable_win64_console.exe" --headless -s tests/test_runner.gd 2>&1
```

- [ ] **Step 5: 커밋**

```bash
git add autoload/game_manager.gd
git commit -m "feat: 영웅 HP 초기값 1000으로 재설정"
```

---

## Task 5: cards_napoleon.gd — 40장 전면 재작성

**Files:**
- Rewrite: `resources/cards/cards_napoleon.gd`

기획 문서 `docs/game_design/cards_napoleon_v2.md`의 40장을 GDScript로 변환한다.

### 카드 생성 패턴 규칙

**기본 패턴 (단일 효과):**
```gdscript
static func _strike() -> Resource:
    var c := CardRes.new()
    c.card_name = "스트라이크"
    c.owner_id = "napoleon"
    c.cost = 1
    c.card_type = CardRes.CardType.ATTACK
    c.rarity = CardRes.Rarity.COMMON
    c.play_animation = "attack"
    var e := EffRes.new()
    e.effect_type = EffRes.EffectType.DAMAGE
    e.value = 100; e.base_value = 100
    e.target = "SINGLE"
    c.effects = [e]
    return c
```

**복합 효과 패턴 (DMG + MORALE):**
```gdscript
static func _swift_advance() -> Resource:
    var c := CardRes.new()
    c.card_name = "신속 기동"
    c.owner_id = "napoleon"
    c.cost = 1
    c.card_type = CardRes.CardType.ATTACK
    c.rarity = CardRes.Rarity.COMMON
    c.play_animation = "attack"
    var e1 := EffRes.new()
    e1.effect_type = EffRes.EffectType.DAMAGE
    e1.value = 100; e1.base_value = 100; e1.target = "SINGLE"
    var e2 := EffRes.new()
    e2.effect_type = EffRes.EffectType.GAIN_MORALE
    e2.value = 1; e2.base_value = 1
    c.effects = [e1, e2]
    return c
```

**CONSUME_MORALE 패턴 (황제의 기개):**
```gdscript
# CONSUME_MORALE: value = 소모할 사기량, bonus_value = 발동 피해
static func _emperors_spirit() -> Resource:
    var c := CardRes.new()
    c.card_name = "황제의 기개"
    c.owner_id = "napoleon"
    c.cost = 0
    c.card_type = CardRes.CardType.ATTACK
    c.rarity = CardRes.Rarity.DIVINE
    c.play_animation = "attack"
    var e := EffRes.new()
    e.effect_type = EffRes.EffectType.CONSUME_MORALE
    e.value = 3; e.base_value = 3        # 소모 사기 (정수, 강화 무관)
    e.bonus_value = 300; e.base_bonus_value = 300  # 피해 (비율 강화)
    e.target = "SINGLE"
    var e2 := EffRes.new()
    e2.effect_type = EffRes.EffectType.APPLY_STATUS
    e2.value = 1; e2.base_value = 1      # WEAK 1 스택 (정수 강화)
    e2.status_type = "weak"; e2.target = "SINGLE"
    c.effects = [e, e2]
    return c
```

**CONDITIONAL_DMG 패턴:**
```gdscript
# value = 조건 미충족 피해, bonus_value = 조건 충족 피해
static func _borodino_bombardment() -> Resource:
    var c := CardRes.new()
    c.card_name = "보로디노 포격"
    c.owner_id = "napoleon"
    c.cost = 2
    c.card_type = CardRes.CardType.ATTACK
    c.rarity = CardRes.Rarity.RARE
    c.play_animation = "attack"
    var e := EffRes.new()
    e.effect_type = EffRes.EffectType.CONDITIONAL_DMG
    e.value = 140; e.base_value = 140            # 사기 없을 때
    e.bonus_value = 200; e.base_bonus_value = 200  # 사기 있을 때
    e.status_type = "has_morale"; e.target = "SINGLE"
    c.effects = [e]
    return c
```

**SUMMON_TOKEN 패턴:**
```gdscript
static func _imperial_infantry_call() -> Resource:
    var c := CardRes.new()
    c.card_name = "제국 보병 소집"
    c.owner_id = "napoleon"
    c.cost = 2
    c.card_type = CardRes.CardType.SKILL
    c.rarity = CardRes.Rarity.RARE
    c.play_animation = "idle"
    var e := EffRes.new()
    e.effect_type = EffRes.EffectType.SUMMON_TOKEN
    e.value = 2; e.base_value = 2   # 생성할 토큰 수 (정수 효과)
    c.effects = [e]
    return c
```

### 전체 파일 구조

```gdscript
# resources/cards/cards_napoleon.gd
const CardRes = preload("res://resources/card_resource.gd")
const EffRes  = preload("res://resources/effect_resource.gd")

static func starter_deck() -> Array:
    var cards: Array = []
    for _i in range(3):
        cards.append(_strike())
    for _i in range(2):
        cards.append(_defend())
    return cards

static func pool() -> Array:
    return [
        # v1 카드 (15장)
        _swift_advance(), _line_reform(),
        _hussar_charge(), _grand_armee_shield(),
        _salvo(), _marshal_appointment(),
        _arcole_breakthrough(), _artillery_volley(),
        _jena_surprise(), _borodino_bombardment(),
        _total_assault_order(), _emperors_command(),
        _emperors_spirit(),
        # v2 추가 카드 (25장) — 기획 문서 순서대로
        _cavalry_threat(), _breakthrough_advance(),
        # ... 나머지 23장
    ]

# --- v1 카드 함수들 (13개) ---
# (위 패턴으로 작성)

# --- v2 추가 카드 함수들 (25개) ---
# (기획 문서 cards_napoleon_v2.md의 v2 추가 카드들)
```

### 수치 변환 규칙

기획 문서의 0강 수치를 그대로 `value`와 `base_value`에 동일하게 설정. 강화는 upgrade_card()가 처리.

| 기획 효과 | effect_type | value | base_value | bonus_value | base_bonus_value |
|---|---|---|---|---|---|
| DMG 100 | DAMAGE | 100 | 100 | 0 | 0 |
| BLOCK 80 | BLOCK | 80 | 80 | 0 | 0 |
| MORALE+1 | GAIN_MORALE | 1 | 1 | 0 | 0 |
| ENERGY+1 | ENERGY | 1 | 1 | 0 | 0 |
| DRAW 2 | DRAW | 2 | 2 | 0 | 0 |
| CONSUME_MORALE 3 → DMG 300 | CONSUME_MORALE | 3 | 3 | 300 | 300 |
| DMG 140(없음)/200(있음) | CONDITIONAL_DMG | 140 | 140 | 200 | 200 |
| SUMMON_TOKEN 2기 | SUMMON_TOKEN | 2 | 2 | 0 | 0 |
| POISON 3 | APPLY_STATUS (status_type="poison") | 3 | 3 | 0 | 0 |
| WEAK 1 | APPLY_STATUS (status_type="weak") | 1 | 1 | 0 | 0 |

- [ ] **Step 1: cards_napoleon.gd 전면 재작성**

기획 문서 `docs/game_design/cards_napoleon_v2.md`를 읽고, pool()에 들어갈 **40장 전체** (시작덱 2종 제외)를 위 패턴으로 작성. 파일 저장 위치: `resources/cards/cards_napoleon.gd`.

- [ ] **Step 2: 기획 문서 대조 — 40장 카드 수 확인**

```bash
grep -c "static func _" H:/AIRelatedDefaultPath/ClaudeCode_Base/GameProjects/CardGameProject/stsl/resources/cards/cards_napoleon.gd
```

42 이상 (시작덱 2종 + 풀 40장) 이어야 함.

- [ ] **Step 3: Godot 파싱 에러 없음 확인**

```bash
"H:/Program Files/Godot/Godot_v4.6.2-stable_win64_console.exe" --headless -s tests/test_runner.gd 2>&1 | head -30
```

- [ ] **Step 4: 커밋**

```bash
git add resources/cards/cards_napoleon.gd
git commit -m "feat: 나폴레옹 카드 40장 재작성 — HP 1000 스케일, rarity/base_value 설정"
```

---

## Task 6: cards_cleopatra.gd — 40장 전면 재작성

**Files:**
- Rewrite: `resources/cards/cards_cleopatra.gd`

기획 문서 `docs/game_design/cards_cleopatra_v2.md`의 40장을 Task 5와 동일 패턴으로 변환.

### 클레오파트라 추가 패턴

**POISON_BURST 패턴 (나일의 분노):**
```gdscript
# value = 독 스택 곱수 (int, 비율 효과로 처리)
# 기획: 0강 ×3 → 실제 value=300 (100 단위). battle_manager에서 독스택 × value / 100
static func _nile_fury() -> Resource:
    var c := CardRes.new()
    c.card_name = "나일의 분노"
    c.owner_id = "cleopatra"
    c.cost = 1
    c.card_type = CardRes.CardType.ATTACK
    c.rarity = CardRes.Rarity.LEGENDARY
    c.play_animation = "attack"
    var e := EffRes.new()
    e.effect_type = EffRes.EffectType.POISON_BURST
    e.value = 300; e.base_value = 300   # 배율 300 = ×3.0 (100 단위)
    e.target = "SINGLE"
    c.effects = [e]
    return c
```

> ⚠️ **POISON_BURST 구현 메모**: battle_manager에서 `독_스택 × effect.value / 100.0`으로 피해 계산. 기존 로직이 다를 경우 Task 6 커밋 후 별도 수정 필요.

**CHARM 패턴 (유혹):**
```gdscript
static func _temptation() -> Resource:
    var c := CardRes.new()
    c.card_name = "유혹"
    c.owner_id = "cleopatra"
    c.cost = 2
    c.card_type = CardRes.CardType.SKILL
    c.rarity = CardRes.Rarity.UNCOMMON
    c.play_animation = "idle"
    var e := EffRes.new()
    e.effect_type = EffRes.EffectType.CHARM
    e.value = 2; e.base_value = 2   # 정수 효과: 강화 시 +1
    e.target = "SINGLE"
    c.effects = [e]
    return c
```

**시작덱 변경 (독침×2 + 왕실 방어×2):**
```gdscript
static func starter_deck() -> Array:
    var cards: Array = []
    for _i in range(2):
        cards.append(_venom_needle())
    for _i in range(2):
        cards.append(_royal_guard())
    return cards
```

- [ ] **Step 1: cards_cleopatra.gd 전면 재작성**

기획 문서 `docs/game_design/cards_cleopatra_v2.md`를 읽고 40장 전체 작성.

- [ ] **Step 2: 카드 수 확인**

```bash
grep -c "static func _" H:/AIRelatedDefaultPath/ClaudeCode_Base/GameProjects/CardGameProject/stsl/resources/cards/cards_cleopatra.gd
```

42 이상이어야 함.

- [ ] **Step 3: 파싱 에러 없음 확인**

```bash
"H:/Program Files/Godot/Godot_v4.6.2-stable_win64_console.exe" --headless -s tests/test_runner.gd 2>&1 | head -30
```

- [ ] **Step 4: 커밋**

```bash
git add resources/cards/cards_cleopatra.gd
git commit -m "feat: 클레오파트라 카드 40장 재작성"
```

---

## Task 7: cards_yi_sun_sin.gd — 40장 전면 재작성

**Files:**
- Rewrite: `resources/cards/cards_yi_sun_sin.gd`

기획 문서 `docs/game_design/cards_yi_sun_sin_v2.md`의 40장을 변환.

### 이순신 추가 패턴

**COUNTER_BLOCK 패턴:**
```gdscript
# value = 현재 방어도 × (value/100) 피해. 100 = 100%, 60 = 60%
static func _counterattack() -> Resource:
    var c := CardRes.new()
    c.card_name = "반격"
    c.owner_id = "yi_sun_sin"
    c.cost = 1
    c.card_type = CardRes.CardType.ATTACK
    c.rarity = CardRes.Rarity.UNCOMMON
    c.play_animation = "attack"
    var e := EffRes.new()
    e.effect_type = EffRes.EffectType.COUNTER_BLOCK
    e.value = 100; e.base_value = 100   # 방어도의 100% 반격 (비율 효과)
    e.target = "SINGLE"
    c.effects = [e]
    return c
```

**FORMATION_BLOCK 패턴:**
```gdscript
static func _formation_reinforce() -> Resource:
    var c := CardRes.new()
    c.card_name = "진형 강화"
    c.owner_id = "yi_sun_sin"
    c.cost = 1
    c.card_type = CardRes.CardType.SKILL
    c.rarity = CardRes.Rarity.UNCOMMON
    c.play_animation = "idle"
    var e := EffRes.new()
    e.effect_type = EffRes.EffectType.FORMATION_BLOCK
    e.value = 40; e.base_value = 40   # 생존 영웅 × 40 BLOCK (비율 효과)
    c.effects = [e]
    return c
```

**CONDITIONAL_DMG 저HP 패턴 (필사즉생):**
```gdscript
# status_type = "low_hp" (HP ≤ 50% 조건)
static func _death_or_glory() -> Resource:
    var c := CardRes.new()
    c.card_name = "필사즉생"
    c.owner_id = "yi_sun_sin"
    c.cost = 1
    c.card_type = CardRes.CardType.ATTACK
    c.rarity = CardRes.Rarity.LEGENDARY
    c.play_animation = "attack"
    var e := EffRes.new()
    e.effect_type = EffRes.EffectType.CONDITIONAL_DMG
    e.value = 100; e.base_value = 100          # HP > 50% 시
    e.bonus_value = 200; e.base_bonus_value = 200  # HP ≤ 50% 시
    e.status_type = "low_hp"; e.target = "SINGLE"
    c.effects = [e]
    return c
```

**자해 HEAL 패턴 (배수진, value < 0):**
```gdscript
static func _last_stand() -> Resource:
    var c := CardRes.new()
    c.card_name = "배수진"
    c.owner_id = "yi_sun_sin"
    c.cost = 1
    c.card_type = CardRes.CardType.SKILL
    c.rarity = CardRes.Rarity.RARE
    c.play_animation = "idle"
    var e1 := EffRes.new()
    e1.effect_type = EffRes.EffectType.HEAL
    e1.value = -80; e1.base_value = -80   # 자해 (음수 힐)
    e1.target = "SELF"
    var e2 := EffRes.new()
    e2.effect_type = EffRes.EffectType.BLOCK
    e2.value = 180; e2.base_value = 180
    c.effects = [e1, e2]
    return c
```

**시작덱 (방패×2 + 역공×2):**
```gdscript
static func starter_deck() -> Array:
    var cards: Array = []
    for _i in range(2):
        cards.append(_shield())
    for _i in range(2):
        cards.append(_retaliation())
    return cards
```

- [ ] **Step 1: cards_yi_sun_sin.gd 전면 재작성**

기획 문서 `docs/game_design/cards_yi_sun_sin_v2.md`를 읽고 40장 전체 작성.

- [ ] **Step 2: 카드 수 확인**

```bash
grep -c "static func _" H:/AIRelatedDefaultPath/ClaudeCode_Base/GameProjects/CardGameProject/stsl/resources/cards/cards_yi_sun_sin.gd
```

42 이상이어야 함.

- [ ] **Step 3: 파싱 에러 없음 확인**

```bash
"H:/Program Files/Godot/Godot_v4.6.2-stable_win64_console.exe" --headless -s tests/test_runner.gd 2>&1 | head -30
```

- [ ] **Step 4: 커밋**

```bash
git add resources/cards/cards_yi_sun_sin.gd
git commit -m "feat: 이순신 카드 40장 재작성"
```

---

## Task 8: enemies_act1.gd — 10종 전면 재작성

**Files:**
- Rewrite: `resources/enemies/enemies_act1.gd`

기획 문서 `docs/game_design/enemies_act1_v1.md`의 10종을 HP 300~4500 스케일로 재작성.

### 수치 기준 (기획 문서 기준)

| 분류 | HP 범위 | 적 공격력 |
|---|---|---|
| 일반 | 300 ~ 2000 | ~80 |
| 엘리트 | 1500 ~ 2500 | 130 ~ 180 |
| 보스(히드라) | 4500 | 200 ~ 300 |

### 현재 파일 구조 유지

```gdscript
# resources/enemies/enemies_act1.gd
const EnemyRes  = preload("res://resources/enemy_resource.gd")
const IntentRes = preload("res://resources/intent_resource.gd")

# --- 일반 적 6종 ---
static func satyr(scene: PackedScene) -> Resource: ...
static func harpy(scene: PackedScene) -> Resource: ...
static func cyclops(scene: PackedScene) -> Resource: ...
static func medusa_snake(scene: PackedScene) -> Resource: ...
static func cerberus(scene: PackedScene) -> Resource: ...
static func myrmidon(scene: PackedScene) -> Resource: ...

# --- 엘리트 적 3종 ---
static func minotaur(scene: PackedScene) -> Resource: ...
static func medusa(scene: PackedScene) -> Resource: ...
static func gorgon(scene: PackedScene) -> Resource: ...

# --- 보스 ---
static func hydra(scene: PackedScene) -> Resource: ...
```

### 인텐트 패턴 예시

```gdscript
static func satyr(scene: PackedScene) -> Resource:
    var enemy := EnemyRes.new()
    enemy.enemy_name = "사티로스"
    enemy.max_hp = 400
    enemy.character_scene = scene
    # 3턴 패턴: 공격 → 공격 → 버프
    var i1 := IntentRes.new()
    i1.action_type = IntentRes.ActionType.ATTACK
    i1.value = 80; i1.target = IntentRes.TargetType.RANDOM
    var i2 := IntentRes.new()
    i2.action_type = IntentRes.ActionType.ATTACK
    i2.value = 80; i2.target = IntentRes.TargetType.RANDOM
    var i3 := IntentRes.new()
    i3.action_type = IntentRes.ActionType.BUFF
    i3.value = 20  # 방어도 획득
    enemy.intent_pattern = [i1, i2, i3]
    return enemy

static func hydra(scene: PackedScene) -> Resource:
    var enemy := EnemyRes.new()
    enemy.enemy_name = "히드라"
    enemy.max_hp = 4500
    enemy.character_scene = scene
    enemy.phase_thresholds = [0.66, 0.33]  # 66%, 33% 체력에서 페이즈 전환
    # 패턴: 공격(200) → 전체공격(150) → 특수(재생)
    var i1 := IntentRes.new()
    i1.action_type = IntentRes.ActionType.ATTACK
    i1.value = 200; i1.target = IntentRes.TargetType.RANDOM
    var i2 := IntentRes.new()
    i2.action_type = IntentRes.ActionType.ATTACK
    i2.value = 150; i2.target = IntentRes.TargetType.ALL
    var i3 := IntentRes.new()
    i3.action_type = IntentRes.ActionType.SPECIAL
    i3.value = 0  # 머리 재생 특수 행동
    enemy.intent_pattern = [i1, i2, i3]
    return enemy
```

- [ ] **Step 1: enemies_act1.gd 전면 재작성**

기획 문서 `docs/game_design/enemies_act1_v1.md`를 읽고 10종 전체를 위 패턴으로 작성. HP·공격력은 기획 문서 수치 그대로 사용.

- [ ] **Step 2: 적 수 확인**

```bash
grep -c "static func " H:/AIRelatedDefaultPath/ClaudeCode_Base/GameProjects/CardGameProject/stsl/resources/enemies/enemies_act1.gd
```

10 이상이어야 함.

- [ ] **Step 3: 파싱 에러 없음 확인**

```bash
"H:/Program Files/Godot/Godot_v4.6.2-stable_win64_console.exe" --headless -s tests/test_runner.gd 2>&1 | head -30
```

- [ ] **Step 4: 커밋**

```bash
git add resources/enemies/enemies_act1.gd
git commit -m "feat: Act 1 적 10종 재작성 — HP 300~4500 스케일"
```

---

## Task 9: 통합 검증 + PR

**목표:** 전체 테스트 통과, Godot 게임 정상 실행, PR 생성

- [ ] **Step 1: 전체 테스트 실행**

```bash
cd "H:/AIRelatedDefaultPath/ClaudeCode_Base/GameProjects/CardGameProject/stsl"
"H:/Program Files/Godot/Godot_v4.6.2-stable_win64_console.exe" --headless -s tests/test_runner.gd 2>&1
```

FAILED 라인이 없어야 함.

- [ ] **Step 2: 카드 로딩 연기 검사**

upgrade_card()를 UNCOMMON 카드에 1회 호출 후 value가 올바른지 확인하는 테스트 스크립트 작성 (기존 test_runner가 있으면 추가, 없으면 임시 스크립트):

```gdscript
# tests/test_upgrade.gd (임시 검증용)
extends SceneTree

func _init():
    var CardRes = load("res://resources/card_resource.gd")
    var EffRes = load("res://resources/effect_resource.gd")
    var GM = load("res://autoload/game_manager.gd")

    # 나폴레옹 경기병 돌격 (UNCOMMON, DMG 120)
    var cards = load("res://resources/cards/cards_napoleon.gd").pool()
    var hussar = null
    for c in cards:
        if c.card_name == "경기병 돌격":
            hussar = c
            break
    assert(hussar != null, "경기병 돌격 카드 없음")
    assert(hussar.effects[0].value == 120, "0강 DMG 120 기대, 실제: " + str(hussar.effects[0].value))
    
    # upgrade_card 호출 (1강)
    var gm = load("res://autoload/game_manager.gd").new()
    gm.upgrade_card(hussar)
    # UNCOMMON 10%: 120 × 1.10 = 132
    assert(hussar.effects[0].value == 132, "1강 DMG 132 기대, 실제: " + str(hussar.effects[0].value))
    assert(hussar.upgrade_level == 1, "upgrade_level 1 기대")
    assert(not hussar.can_upgrade(), "UNCOMMON은 1강이 최대")
    
    print("✅ 강화 시스템 검증 통과")
    quit()
```

실행:
```bash
"H:/Program Files/Godot/Godot_v4.6.2-stable_win64_console.exe" --headless -s tests/test_upgrade.gd 2>&1
```

Expected: `✅ 강화 시스템 검증 통과`

- [ ] **Step 3: 영웅 HP 확인**

기존 테스트에서 영웅 HP 관련 어설션이 있으면 1000으로 수정.

- [ ] **Step 4: PR 생성**

```bash
git push -u origin feat/card-system-v2-impl
```

GitHub MCP(`mcp__plugin_github_github__create_pull_request`)로 PR 생성:
- base: main
- title: `feat: 카드 시스템 v2 구현 — 5등급 체계, HP 1000 스케일, 40장 카드 풀`
- body: Task 1~8 완료 내용 요약

---

## 검증 체크리스트

- [ ] CardResource에 `rarity`, `upgrade_level`, `can_upgrade()` 존재, `upgraded` 없음
- [ ] EffectResource에 `base_value`, `base_bonus_value` 존재
- [ ] upgrade_card(UNCOMMON 카드): value = base × 1.10 (±1 허용)
- [ ] upgrade_card(LEGENDARY 카드, 2회): value = base × 1.28 (±1 허용)
- [ ] COMMON 카드: can_upgrade() = false, upgrade_card 호출 후 변화 없음
- [ ] LEGENDARY 카드 2강 후: can_upgrade() = false
- [ ] 영웅 3인 max_hp = 1000
- [ ] 나폴레옹 pool() 카드 수 ≥ 40
- [ ] 클레오파트라 pool() 카드 수 ≥ 40
- [ ] 이순신 pool() 카드 수 ≥ 40
- [ ] 적 10종 함수 존재 (satyr, harpy, cyclops, medusa_snake, cerberus, myrmidon, minotaur, medusa, gorgon, hydra)
- [ ] 전체 테스트 PASS
