# Plan 03: 전투 씬 UI (BattleScene) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 카드 선택·적 타겟팅·턴 진행이 가능한 기본 전투 씬을 구현하여 BattleManager 로직을 시각적으로 플레이할 수 있게 한다.

**Architecture:** BattleScene(Node2D)이 모든 UI를 GDScript 코드로 직접 생성한다(.tscn은 루트 노드만 보유). BattleManager.team_mgr/deck_mgr를 Autoload로 연결한 뒤 _start_test_battle()로 하드코딩 데이터를 주입해 즉시 실행 가능한 상태로 만든다. 캐릭터 씬(Node2D)은 BattleScene에 직접 자식으로 추가해 애니메이션을 재생한다.

**Tech Stack:** Godot 4.6, GDScript, 헤드리스 테스트 (기존 65개 회귀 확인), 시각 확인 (`godot --path <프로젝트> res://scenes/battle/battle_scene.tscn`)

---

## 화면 레이아웃 (1920 × 1080)

```
┌──────────────┬──────────────────────────┬──────────────┐
│  HERO AREA   │                          │  ENEMY AREA  │
│  x: 20~400   │       FIELD              │  x:1520~1900 │
│              │                          │              │
│  [Char]      │                          │  ⚔ 6        │
│  나폴레옹     │                          │  [Char]      │
│  HP 70/70    │                          │  사티로스     │
│  🛡 0        │                          │  HP 30/30    │
├──────────────┴──────────────────────────┴──────────────┤
│ ⚡ 3/3  [스트라이크][디펜드][...][...][...]  [턴 종료]  │
│         y: 840 ~ 1080                                  │
└────────────────────────────────────────────────────────┘
```

---

## 파일 구조

```
scenes/battle/
  battle_scene.tscn    ← 루트 노드(Node2D) + 스크립트 참조만
  battle_scene.gd      ← 전체 UI 빌드, BattleManager 연결, 인터랙션
autoload/
  battle_manager.gd    ← get_enemy(index) getter 추가
project.godot          ← display/window 크기 + main_scene 등록
```

---

## 레이아웃 상수

```
WINDOW_W  = 1920    WINDOW_H  = 1080
HERO_X    = 20      ENEMY_X   = 1520
SLOT_W    = 360     SLOT_H    = 280
BOTTOM_Y  = 840     CARD_W    = 110     CARD_H = 160
HERO_CHAR_Y_BASE = 160   ENEMY_CHAR_Y_BASE = 160
SLOT_GAP  = 20
```

---

## Task 1: 씬 파일 + 기본 UI 구조

**Files:**
- Create: `scenes/battle/battle_scene.tscn`
- Create: `scenes/battle/battle_scene.gd`
- Modify: `project.godot`

- [ ] **Step 1: battle_scene.tscn 생성**

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scenes/battle/battle_scene.gd" id="1"]

[node name="BattleScene" type="Node2D"]
script = ExtResource("1")
```

- [ ] **Step 2: project.godot에 display 설정 추가**

`[application]` 섹션 뒤에 추가:

```ini
[display]

window/size/viewport_width=1920
window/size/viewport_height=1080
window/size/resizable=false
```

- [ ] **Step 3: battle_scene.gd 생성 — _build_ui() + 상수만 포함**

```gdscript
# scenes/battle/battle_scene.gd
extends Node2D

const EffectRes = preload("res://resources/effect_resource.gd")
const IntentRes = preload("res://resources/intent_resource.gd")

const WINDOW_W := 1920
const WINDOW_H := 1080
const HERO_X := 20
const ENEMY_X := 1520
const SLOT_W := 360
const SLOT_H := 280
const BOTTOM_Y := 840
const CARD_W := 110
const CARD_H := 160
const SLOT_GAP := 20

# UI 참조 (Dictionary 배열)
# hero entry: {panel, name_lbl, hp_lbl, block_lbl, hero_id}
# enemy entry: {panel, intent_lbl, btn, name_lbl, hp_lbl, block_lbl}
var _hero_nodes: Array = []
var _enemy_nodes: Array = []
var _card_buttons: Array = []
var _hero_char_nodes: Dictionary = {}  # hero_id → Node2D
var _enemy_char_nodes: Array = []      # index → Node2D

var _energy_label: Label
var _end_turn_btn: Button
var _message_label: Label
var _selected_card: Resource = null

func _ready() -> void:
    _build_ui()
    BattleManager.team_mgr = TeamManager
    BattleManager.deck_mgr = DeckManager
    _connect_signals()
    _start_test_battle()

# ─────────────────────────────────────────────
# UI 빌드
# ─────────────────────────────────────────────

func _build_ui() -> void:
    # 배경
    var bg := ColorRect.new()
    bg.color = Color(0.08, 0.08, 0.12)
    bg.position = Vector2.ZERO
    bg.size = Vector2(WINDOW_W, WINDOW_H)
    add_child(bg)

    # 상단 메시지 레이블
    _message_label = Label.new()
    _message_label.position = Vector2(WINDOW_W / 2.0 - 300, 16)
    _message_label.size = Vector2(600, 50)
    _message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _message_label.add_theme_font_size_override("font_size", 26)
    add_child(_message_label)

    # 에너지 레이블
    _energy_label = Label.new()
    _energy_label.position = Vector2(30, BOTTOM_Y + 16)
    _energy_label.size = Vector2(160, 50)
    _energy_label.add_theme_font_size_override("font_size", 26)
    _energy_label.text = "⚡ 0 / 3"
    add_child(_energy_label)

    # 턴 종료 버튼
    _end_turn_btn = Button.new()
    _end_turn_btn.position = Vector2(WINDOW_W - 220, BOTTOM_Y + 16)
    _end_turn_btn.size = Vector2(200, 60)
    _end_turn_btn.text = "턴 종료"
    _end_turn_btn.add_theme_font_size_override("font_size", 22)
    _end_turn_btn.disabled = true
    _end_turn_btn.pressed.connect(_on_end_turn_pressed)
    add_child(_end_turn_btn)

    # 영웅 슬롯 3개 (초기 숨김)
    for i in range(3):
        _hero_nodes.append(_make_hero_slot(i))
        _enemy_char_nodes.append(null)  # 적 캐릭터 노드 예약

    # 적 슬롯 3개 (초기 숨김)
    for i in range(3):
        _enemy_nodes.append(_make_enemy_slot(i))

func _make_hero_slot(index: int) -> Dictionary:
    var y := 80 + index * (SLOT_H + SLOT_GAP)
    var panel := ColorRect.new()
    panel.color = Color(0.12, 0.12, 0.2)
    panel.position = Vector2(HERO_X, y)
    panel.size = Vector2(SLOT_W, SLOT_H)
    panel.visible = false
    add_child(panel)

    var name_lbl := _make_label(Vector2(HERO_X + 10, y + 196), Vector2(SLOT_W - 20, 28), 18)
    var hp_lbl   := _make_label(Vector2(HERO_X + 10, y + 226), Vector2(SLOT_W - 20, 24), 15)
    var block_lbl := _make_label(Vector2(HERO_X + 10, y + 250), Vector2(SLOT_W - 20, 22), 14)
    block_lbl.modulate = Color(0.5, 0.8, 1.0)

    return { "panel": panel, "name_lbl": name_lbl,
             "hp_lbl": hp_lbl, "block_lbl": block_lbl, "hero_id": "" }

func _make_enemy_slot(index: int) -> Dictionary:
    var y := 80 + index * (SLOT_H + SLOT_GAP)
    var panel := ColorRect.new()
    panel.color = Color(0.18, 0.10, 0.10)
    panel.position = Vector2(ENEMY_X, y)
    panel.size = Vector2(SLOT_W, SLOT_H)
    panel.visible = false
    add_child(panel)

    var intent_lbl := _make_label(Vector2(ENEMY_X + 10, y + 8), Vector2(SLOT_W - 20, 30), 20)
    intent_lbl.modulate = Color(1.0, 0.8, 0.2)
    intent_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

    # 클릭 버튼 (투명, 캐릭터 영역 위에 올림)
    var btn := Button.new()
    btn.flat = true
    btn.position = Vector2(ENEMY_X + 20, y + 40)
    btn.size = Vector2(SLOT_W - 40, 160)
    btn.add_theme_font_size_override("font_size", 14)
    btn.text = "▶ 공격"
    var captured_index := index
    btn.pressed.connect(func(): _on_enemy_pressed(captured_index))
    add_child(btn)

    var name_lbl  := _make_label(Vector2(ENEMY_X + 10, y + 204), Vector2(SLOT_W - 20, 26), 16)
    var hp_lbl    := _make_label(Vector2(ENEMY_X + 10, y + 230), Vector2(SLOT_W - 20, 24), 14)
    var block_lbl := _make_label(Vector2(ENEMY_X + 10, y + 254), Vector2(SLOT_W - 20, 22), 13)
    block_lbl.modulate = Color(0.5, 0.8, 1.0)

    return { "panel": panel, "intent_lbl": intent_lbl, "btn": btn,
             "name_lbl": name_lbl, "hp_lbl": hp_lbl, "block_lbl": block_lbl }

func _make_label(pos: Vector2, sz: Vector2, font_size: int) -> Label:
    var lbl := Label.new()
    lbl.position = pos
    lbl.size = sz
    lbl.add_theme_font_size_override("font_size", font_size)
    add_child(lbl)
    return lbl

# ─────────────────────────────────────────────
# 시그널 연결 (스텁 — Task 3~5에서 채움)
# ─────────────────────────────────────────────

func _connect_signals() -> void:
    DeckManager.hand_changed.connect(_refresh_hand)
    DeckManager.energy_changed.connect(_on_energy_changed)
    DeckManager.card_played.connect(_on_card_played)
    BattleManager.player_turn_started.connect(_on_player_turn_started)
    BattleManager.enemy_turn_started.connect(_on_enemy_turn_started)
    BattleManager.hero_damaged.connect(_on_hero_damaged)
    BattleManager.enemy_damaged.connect(_on_enemy_damaged)
    BattleManager.enemy_died.connect(_on_enemy_died)
    BattleManager.battle_won.connect(_on_battle_won)
    BattleManager.battle_lost.connect(_on_battle_lost)
    TeamManager.hero_died.connect(_on_hero_died)

# ─────────────────────────────────────────────
# 테스트 배틀 초기화 (Task 2에서 완성)
# ─────────────────────────────────────────────

func _start_test_battle() -> void:
    pass  # Task 2에서 구현

# ─────────────────────────────────────────────
# 영웅/적 표시 (Task 2에서 구현)
# ─────────────────────────────────────────────

func _setup_heroes() -> void:
    pass

func _setup_enemies() -> void:
    pass

func _update_hero_ui(_hero_id: String) -> void:
    pass

func _update_enemy_ui(_index: int) -> void:
    pass

# ─────────────────────────────────────────────
# 카드 핸드 (Task 3에서 구현)
# ─────────────────────────────────────────────

func _refresh_hand() -> void:
    pass

# ─────────────────────────────────────────────
# 인터랙션 핸들러 (Task 4~5에서 구현)
# ─────────────────────────────────────────────

func _on_card_pressed(_card: Resource) -> void:
    pass

func _on_enemy_pressed(_index: int) -> void:
    pass

func _on_end_turn_pressed() -> void:
    pass

func _on_player_turn_started() -> void:
    pass

func _on_enemy_turn_started() -> void:
    pass

func _on_energy_changed(_new_energy: int) -> void:
    pass

func _on_card_played(_card: Resource) -> void:
    pass

func _on_hero_damaged(_hero_id: String, _amount: int) -> void:
    pass

func _on_enemy_damaged(_index: int, _amount: int) -> void:
    pass

func _on_enemy_died(_index: int) -> void:
    pass

func _on_hero_died(_hero_id: String) -> void:
    pass

func _on_battle_won() -> void:
    pass

func _on_battle_lost() -> void:
    pass
```

- [ ] **Step 4: 기존 테스트 회귀 확인**

```bash
"H:/Program Files/Godot/Godot_v4.6.2-stable_win64_console.exe" --headless -s "H:/AIRelatedDefaultPath/ClaudeCode_Base/GameProjects/CardGameProject/stsl/tests/test_runner.gd" --path "H:/AIRelatedDefaultPath/ClaudeCode_Base/GameProjects/CardGameProject/stsl"
```

예상: `=== Results: 65 passed, 0 failed ===`

- [ ] **Step 5: 커밋**

```bash
cd "H:/AIRelatedDefaultPath/ClaudeCode_Base/GameProjects/CardGameProject/stsl"
git add scenes/battle/battle_scene.tscn scenes/battle/battle_scene.gd project.godot
git commit -m "feat: BattleScene 기본 구조 + UI 골격 (Plan 03 Task 1)"
```

---

## Task 2: 영웅/적 표시 + 테스트 배틀 초기화

**Files:**
- Modify: `scenes/battle/battle_scene.gd` — _start_test_battle, _setup_heroes, _setup_enemies, _update_hero_ui, _update_enemy_ui 구현
- Modify: `autoload/battle_manager.gd` — get_enemy() getter 추가

- [ ] **Step 1: battle_manager.gd에 getter 추가**

`get_enemy_current_intent()` 함수 바로 아래에 추가:

```gdscript
func get_enemy(index: int) -> Resource:
    if index < 0 or index >= _enemies.size():
        return null
    return _enemies[index]
```

- [ ] **Step 2: battle_scene.gd — _start_test_battle 구현**

기존 `func _start_test_battle() -> void:` 를 아래로 교체:

```gdscript
func _start_test_battle() -> void:
    var HeroRes = load("res://resources/hero_resource.gd")
    var EnemyRes = load("res://resources/enemy_resource.gd")
    var CardRes = load("res://resources/card_resource.gd")

    # 영웅 설정
    TeamManager.clear()
    var napoleon = HeroRes.new()
    napoleon.hero_id = "napoleon"
    napoleon.hero_name = "나폴레옹"
    napoleon.max_hp = 70
    napoleon.character_scene = load("res://characters/heroes/napoleon/napoleon.tscn")
    TeamManager.add_hero(napoleon)

    # 덱 설정 (스트라이크 3장 + 디펜드 2장)
    DeckManager.clear()
    for _i in range(3):
        var card = CardRes.new()
        card.card_name = "스트라이크"
        card.owner_id = "napoleon"
        card.cost = 1
        card.play_animation = "attack"
        var eff = EffectRes.new()
        eff.effect_type = EffectRes.EffectType.DAMAGE
        eff.value = 6
        eff.target = "SINGLE"
        card.effects = [eff]
        DeckManager.add_card_to_deck(card)
    for _i in range(2):
        var card = CardRes.new()
        card.card_name = "디펜드"
        card.owner_id = "napoleon"
        card.cost = 1
        card.play_animation = "idle"
        var eff = EffectRes.new()
        eff.effect_type = EffectRes.EffectType.BLOCK
        eff.value = 5
        eff.target = "SELF"
        card.effects = [eff]
        DeckManager.add_card_to_deck(card)

    # 적 설정
    var IntentResClass = load("res://resources/intent_resource.gd")
    var satyr = EnemyRes.new()
    satyr.enemy_name = "사티로스"
    satyr.max_hp = 30
    satyr.character_scene = load("res://characters/enemies/satyr/satyr.tscn")
    var intent = IntentResClass.new()
    intent.action_type = IntentResClass.ActionType.ATTACK
    intent.value = 6
    intent.target = IntentResClass.TargetType.RANDOM
    satyr.intent_pattern = [intent]

    BattleManager.setup_battle([satyr])
    _setup_heroes()
    _setup_enemies()
    BattleManager.start_player_turn()
```

- [ ] **Step 3: _setup_heroes 구현**

기존 `func _setup_heroes()` 교체:

```gdscript
func _setup_heroes() -> void:
    # 기존 캐릭터 노드 정리
    for char_node in _hero_char_nodes.values():
        char_node.queue_free()
    _hero_char_nodes.clear()
    for entry in _hero_nodes:
        entry["panel"].visible = false
        entry["hero_id"] = ""

    var heroes := TeamManager.heroes
    for i in range(min(heroes.size(), 3)):
        var hero: Resource = heroes[i]
        var entry: Dictionary = _hero_nodes[i]
        entry["panel"].visible = true
        entry["hero_id"] = hero.hero_id
        entry["name_lbl"].text = hero.get("hero_name") if hero.get("hero_name") != null else hero.hero_id

        # 캐릭터 씬 인스턴스화
        if hero.character_scene != null:
            var char_node = hero.character_scene.instantiate()
            char_node.position = Vector2(HERO_X + 170, 80 + i * (SLOT_H + SLOT_GAP) + 120)
            add_child(char_node)
            _hero_char_nodes[hero.hero_id] = char_node

        _update_hero_ui(hero.hero_id)
```

- [ ] **Step 4: _setup_enemies 구현**

```gdscript
func _setup_enemies() -> void:
    # 기존 캐릭터 노드 정리
    for i in range(_enemy_char_nodes.size()):
        if _enemy_char_nodes[i] != null:
            _enemy_char_nodes[i].queue_free()
            _enemy_char_nodes[i] = null
    for entry in _enemy_nodes:
        entry["panel"].visible = false

    var count := 0
    while count < 3 and BattleManager.get_enemy(count) != null:
        count += 1

    for i in range(count):
        var enemy: Resource = BattleManager.get_enemy(i)
        var entry: Dictionary = _enemy_nodes[i]
        entry["panel"].visible = true
        entry["btn"].disabled = false
        entry["name_lbl"].text = enemy.get("enemy_name") if enemy.get("enemy_name") != null else "적"

        # 캐릭터 씬 인스턴스화 (좌우 반전: scale.x = -1)
        if enemy.character_scene != null:
            var char_node = enemy.character_scene.instantiate()
            char_node.position = Vector2(ENEMY_X + 190, 80 + i * (SLOT_H + SLOT_GAP) + 120)
            char_node.scale = Vector2(-1, 1)  # 적은 왼쪽 향함
            add_child(char_node)
            _enemy_char_nodes[i] = char_node

        _update_enemy_ui(i)
```

- [ ] **Step 5: _update_hero_ui 구현**

```gdscript
func _update_hero_ui(hero_id: String) -> void:
    for entry in _hero_nodes:
        if entry["hero_id"] != hero_id:
            continue
        var hero: Resource = TeamManager.get_hero(hero_id)
        if hero == null:
            return
        var cur_hp: int = TeamManager.get_current_hp(hero_id)
        entry["hp_lbl"].text = "HP  %d / %d" % [cur_hp, hero.max_hp]
        var block: int = BattleManager._hero_block.get(hero_id, 0)
        entry["block_lbl"].text = "🛡 %d" % block if block > 0 else ""
        if not TeamManager.is_alive(hero_id):
            entry["panel"].modulate = Color(0.4, 0.4, 0.4)
        return
```

- [ ] **Step 6: _update_enemy_ui 구현**

```gdscript
func _update_enemy_ui(index: int) -> void:
    var entry: Dictionary = _enemy_nodes[index]
    var enemy: Resource = BattleManager.get_enemy(index)
    if enemy == null:
        return
    var cur_hp: int = BattleManager.get_enemy_hp(index)
    entry["hp_lbl"].text = "HP  %d / %d" % [cur_hp, enemy.max_hp]
    var block: int = BattleManager.get_enemy_block(index)
    entry["block_lbl"].text = "🛡 %d" % block if block > 0 else ""

    # 의도 표시
    var intent: Resource = BattleManager.get_enemy_current_intent(index)
    if intent != null:
        match intent.action_type:
            IntentRes.ActionType.ATTACK:
                entry["intent_lbl"].text = "⚔ %d" % intent.value
            IntentRes.ActionType.BUFF:
                entry["intent_lbl"].text = "🛡 %d" % intent.value
            IntentRes.ActionType.DEBUFF:
                entry["intent_lbl"].text = "💀 약화"
            _:
                entry["intent_lbl"].text = "?"

    if not BattleManager.is_enemy_alive(index):
        entry["panel"].modulate = Color(0.3, 0.3, 0.3)
        entry["btn"].disabled = true
        entry["intent_lbl"].text = "✝"
```

- [ ] **Step 7: 기존 테스트 회귀 확인**

```bash
"H:/Program Files/Godot/Godot_v4.6.2-stable_win64_console.exe" --headless -s "H:/AIRelatedDefaultPath/ClaudeCode_Base/GameProjects/CardGameProject/stsl/tests/test_runner.gd" --path "H:/AIRelatedDefaultPath/ClaudeCode_Base/GameProjects/CardGameProject/stsl"
```

예상: 65 passed, 0 failed

- [ ] **Step 8: 커밋**

```bash
git add scenes/battle/battle_scene.gd autoload/battle_manager.gd
git commit -m "feat: 영웅/적 슬롯 표시 + 테스트 배틀 초기화 (Plan 03 Task 2)"
```

---

## Task 3: 카드 핸드 + 에너지 표시

**Files:**
- Modify: `scenes/battle/battle_scene.gd` — _refresh_hand, _on_energy_changed 구현

- [ ] **Step 1: _refresh_hand 구현**

기존 `func _refresh_hand()` 교체:

```gdscript
func _refresh_hand() -> void:
    for btn in _card_buttons:
        if is_instance_valid(btn):
            btn.queue_free()
    _card_buttons.clear()

    var hand: Array = DeckManager.hand
    if hand.is_empty():
        return

    var total_w: float = hand.size() * (CARD_W + 10) - 10
    var start_x: float = (WINDOW_W - total_w) / 2.0

    for i in range(hand.size()):
        var card: Resource = hand[i]
        var can_play: bool = DeckManager.can_play(card)

        var btn := Button.new()
        btn.position = Vector2(start_x + i * (CARD_W + 10), BOTTOM_Y)
        btn.size = Vector2(CARD_W, CARD_H)

        var card_name: String = card.get("card_name") if card.get("card_name") != null else "?"
        var owner_id: String = card.get("owner_id") if card.get("owner_id") != null else ""
        btn.text = "[%d]\n%s\n%s" % [card.cost, card_name, owner_id]
        btn.add_theme_font_size_override("font_size", 13)
        btn.disabled = not can_play

        var captured_card := card
        btn.pressed.connect(func(): _on_card_pressed(captured_card))
        add_child(btn)
        _card_buttons.append(btn)
```

- [ ] **Step 2: _on_energy_changed 구현**

```gdscript
func _on_energy_changed(new_energy: int) -> void:
    _energy_label.text = "⚡ %d / %d" % [new_energy, DeckManager.MAX_ENERGY]
    # 카드 버튼 활성/비활성 갱신
    var hand: Array = DeckManager.hand
    for i in range(min(_card_buttons.size(), hand.size())):
        _card_buttons[i].disabled = not DeckManager.can_play(hand[i])
```

- [ ] **Step 3: 기존 테스트 회귀 확인**

```bash
"H:/Program Files/Godot/Godot_v4.6.2-stable_win64_console.exe" --headless -s "H:/AIRelatedDefaultPath/ClaudeCode_Base/GameProjects/CardGameProject/stsl/tests/test_runner.gd" --path "H:/AIRelatedDefaultPath/ClaudeCode_Base/GameProjects/CardGameProject/stsl"
```

예상: 65 passed, 0 failed

- [ ] **Step 4: 커밋**

```bash
git add scenes/battle/battle_scene.gd
git commit -m "feat: 카드 핸드 + 에너지 표시 (Plan 03 Task 3)"
```

---

## Task 4: 카드 인터랙션 + 적 타겟팅

**Files:**
- Modify: `scenes/battle/battle_scene.gd` — _on_card_pressed, _on_enemy_pressed, _on_card_played, _on_hero/enemy_damaged/died

- [ ] **Step 1: _on_card_pressed 구현**

```gdscript
func _on_card_pressed(card: Resource) -> void:
    if not BattleManager.is_player_turn or not DeckManager.can_play(card):
        return

    # 타겟 선택이 필요한지 확인 (SINGLE DAMAGE 효과)
    var needs_target := false
    for effect in card.effects:
        if effect.effect_type == EffectRes.EffectType.DAMAGE and effect.target == "SINGLE":
            needs_target = true
            break

    if needs_target:
        _selected_card = card
        _message_label.text = "공격 대상을 선택하세요 ▶"
        # 선택된 카드 강조 (이미 눌린 버튼이므로 시각 피드백 없음)
    else:
        # 즉시 플레이 (블록, 전체 공격 등)
        BattleManager.play_card(card, -1)
        _selected_card = null
        _message_label.text = ""
```

- [ ] **Step 2: _on_enemy_pressed 구현**

```gdscript
func _on_enemy_pressed(index: int) -> void:
    if _selected_card == null or not BattleManager.is_player_turn:
        return
    if not BattleManager.is_enemy_alive(index):
        return
    BattleManager.play_card(_selected_card, index)
    _selected_card = null
    _message_label.text = ""
```

- [ ] **Step 3: _on_card_played 구현 (애니메이션 트리거)**

```gdscript
func _on_card_played(card: Resource) -> void:
    var anim_name: String = card.get("play_animation") if card.get("play_animation") != null else ""
    if anim_name == "":
        return
    var char_node = _hero_char_nodes.get(card.get("owner_id", ""))
    if char_node == null or not char_node.has_node("AnimationPlayer"):
        return
    var anim_player: AnimationPlayer = char_node.get_node("AnimationPlayer")
    if anim_player.has_animation(anim_name):
        anim_player.play(anim_name)
```

- [ ] **Step 4: _on_hero/enemy_damaged/died 구현**

```gdscript
func _on_hero_damaged(hero_id: String, _amount: int) -> void:
    _update_hero_ui(hero_id)
    # hurt 애니메이션 트리거
    var char_node = _hero_char_nodes.get(hero_id)
    if char_node and char_node.has_node("AnimationPlayer"):
        var ap: AnimationPlayer = char_node.get_node("AnimationPlayer")
        if ap.has_animation("hurt"):
            ap.play("hurt")

func _on_enemy_damaged(index: int, _amount: int) -> void:
    _update_enemy_ui(index)
    var char_node = _enemy_char_nodes[index] if index < _enemy_char_nodes.size() else null
    if char_node and char_node.has_node("AnimationPlayer"):
        var ap: AnimationPlayer = char_node.get_node("AnimationPlayer")
        if ap.has_animation("hurt"):
            ap.play("hurt")

func _on_enemy_died(index: int) -> void:
    _update_enemy_ui(index)
    var char_node = _enemy_char_nodes[index] if index < _enemy_char_nodes.size() else null
    if char_node and char_node.has_node("AnimationPlayer"):
        var ap: AnimationPlayer = char_node.get_node("AnimationPlayer")
        if ap.has_animation("death"):
            ap.play("death")

func _on_hero_died(hero_id: String) -> void:
    _update_hero_ui(hero_id)
    var char_node = _hero_char_nodes.get(hero_id)
    if char_node and char_node.has_node("AnimationPlayer"):
        var ap: AnimationPlayer = char_node.get_node("AnimationPlayer")
        if ap.has_animation("death"):
            ap.play("death")
```

- [ ] **Step 5: 기존 테스트 회귀 확인**

```bash
"H:/Program Files/Godot/Godot_v4.6.2-stable_win64_console.exe" --headless -s "H:/AIRelatedDefaultPath/ClaudeCode_Base/GameProjects/CardGameProject/stsl/tests/test_runner.gd" --path "H:/AIRelatedDefaultPath/ClaudeCode_Base/GameProjects/CardGameProject/stsl"
```

예상: 65 passed, 0 failed

- [ ] **Step 6: 커밋**

```bash
git add scenes/battle/battle_scene.gd
git commit -m "feat: 카드 인터랙션 + 적 타겟팅 + 애니메이션 트리거 (Plan 03 Task 4)"
```

---

## Task 5: 턴 흐름 + 승/패 + 메인 씬 등록

**Files:**
- Modify: `scenes/battle/battle_scene.gd` — 턴 핸들러, 승/패 구현
- Modify: `project.godot` — main_scene 등록

- [ ] **Step 1: 턴 핸들러 구현**

```gdscript
func _on_player_turn_started() -> void:
    _end_turn_btn.disabled = false
    _message_label.text = "플레이어 턴"
    _energy_label.text = "⚡ %d / %d" % [DeckManager.current_energy, DeckManager.MAX_ENERGY]
    # 영웅 블록 UI 갱신 (start_player_turn이 블록 초기화했으므로)
    for entry in _hero_nodes:
        var hid: String = entry["hero_id"]
        if hid != "":
            _update_hero_ui(hid)
    # 적 의도 갱신
    for i in range(_enemy_nodes.size()):
        if _enemy_nodes[i]["panel"].visible:
            _update_enemy_ui(i)

func _on_enemy_turn_started() -> void:
    _end_turn_btn.disabled = true
    _selected_card = null
    _message_label.text = "적 턴..."
    # 적 클릭 버튼 비활성
    for entry in _enemy_nodes:
        if entry["panel"].visible and not entry["btn"].disabled:
            entry["btn"].disabled = true

func _on_end_turn_pressed() -> void:
    _selected_card = null
    _message_label.text = ""
    _end_turn_btn.disabled = true
    BattleManager.end_player_turn()
    # 적 턴 완료 후 적 클릭 버튼 재활성
    for i in range(_enemy_nodes.size()):
        if _enemy_nodes[i]["panel"].visible and BattleManager.is_enemy_alive(i):
            _enemy_nodes[i]["btn"].disabled = false
```

- [ ] **Step 2: 승/패 핸들러 구현**

```gdscript
func _on_battle_won() -> void:
    _message_label.text = "🏆 승리!"
    _end_turn_btn.disabled = true
    _selected_card = null
    for entry in _enemy_nodes:
        entry["btn"].disabled = true

func _on_battle_lost() -> void:
    _message_label.text = "💀 패배..."
    _end_turn_btn.disabled = true
    _selected_card = null
```

- [ ] **Step 3: project.godot에 메인 씬 등록**

`[application]` 섹션에 추가:

```ini
[application]

config/name="STSL"
config/features=PackedStringArray("4.6", "Mobile")
config/icon="res://icon.svg"
config/run/main_scene="res://scenes/battle/battle_scene.tscn"
```

- [ ] **Step 4: 기존 테스트 최종 회귀 확인**

```bash
"H:/Program Files/Godot/Godot_v4.6.2-stable_win64_console.exe" --headless -s "H:/AIRelatedDefaultPath/ClaudeCode_Base/GameProjects/CardGameProject/stsl/tests/test_runner.gd" --path "H:/AIRelatedDefaultPath/ClaudeCode_Base/GameProjects/CardGameProject/stsl"
```

예상: `=== Results: 65 passed, 0 failed ===`

- [ ] **Step 5: 시각 확인 (선택)**

```bash
"H:/Program Files/Godot/Godot_v4.6.2-stable_win64_console.exe" --path "H:/AIRelatedDefaultPath/ClaudeCode_Base/GameProjects/CardGameProject/stsl" res://scenes/battle/battle_scene.tscn
```

게임 창이 열리고:
- 왼쪽: 나폴레옹 (파란 사각형, idle 애니메이션)
- 오른쪽: 사티로스 (어두운 빨간 사각형) + 의도 `⚔ 6`
- 하단: 카드 5장 + ⚡ 3/3 + 턴 종료 버튼
- 카드 클릭 → "공격 대상 선택" 메시지 → 적 클릭 → 피해 적용

- [ ] **Step 6: 커밋**

```bash
git add scenes/battle/battle_scene.gd project.godot
git commit -m "feat: 턴 흐름 + 승/패 + 메인 씬 등록 (Plan 03 Task 5)"
```

---

## Self-Review

### Spec 커버리지 확인

| GDD 요구사항 | 구현 태스크 |
|---|---|
| 플레이어 턴 시작 → 드로우 + 에너지 충전 | Task 5 (start_player_turn → hand_changed → _refresh_hand) |
| 카드 플레이 → 해당 팀원 행동 (애니메이션) | Task 4 (_on_card_played → play_animation 재생) |
| 타겟 지정 (단일/전체) | Task 4 (_on_card_pressed → needs_target 분기) |
| 몬스터 의도 표시 | Task 2 (_update_enemy_ui → intent_lbl) |
| 몬스터 턴 자동 실행 | Task 5 (_on_end_turn_pressed → end_player_turn) |
| 영웅 HP/블록 표시 | Task 2 (_update_hero_ui) |
| 적 HP/블록 표시 | Task 2 (_update_enemy_ui) |
| 승/패 메시지 | Task 5 (_on_battle_won/lost) |
| 캐릭터 씬 (플레이스홀더) 표시 + idle 애니 | Task 2 (character_scene.instantiate()) |
| 피해/사망 애니메이션 | Task 4 (hurt/death 트리거) |

### 이 플랜에서 다루지 않는 것 (다음 플랜)

- **카드 UI 아트**: 현재는 텍스트만. Texture2D 아트 교체는 Blender 파이프라인 이후
- **블록 흡수 시각 피드백**: 0 피해 시 이펙트 없음
- **TargetType.ALL 적 공격**: known_issues 참조
- **맵 씬 → 전투 씬 전환**: GameManager.change_state() 연동
- **카드 강화 UI**: 보스 전투 후 카드 강화 화면

### 플레이스홀더 없음 확인

Task 1 골격의 `pass` 스텁은 후속 태스크에서 전부 교체됨. Task 5 완료 시 `pass` 없음.

### 타입 일관성 확인

- `BattleManager.get_enemy(index)` → Task 2에서 battle_manager.gd에 추가, 이후 모든 태스크에서 동일하게 사용
- `_hero_nodes[i]["hero_id"]` 키 이름 일관
- `_enemy_nodes[i]["btn"]` 키 이름 일관
- `EffectRes.EffectType.DAMAGE` / `IntentRes.ActionType.ATTACK` — 최상단 preload 상수 사용
