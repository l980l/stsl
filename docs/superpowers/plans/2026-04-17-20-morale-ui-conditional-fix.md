# Plan 20 — 사기 UI + CONDITIONAL_DMG 수정 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** BattleScene에서 나폴레옹의 사기(Morale) 수치를 실시간으로 표시하고, CONDITIONAL_DMG 효과가 card 소유 영웅의 상태를 올바르게 검사하도록 수정한다.

**Architecture:** BattleManager에 `morale_changed(hero_id, new_value)` 시그널을 추가해 GAIN_MORALE/CONSUME_MORALE 적용 시 emit한다. BattleScene `_update_hero_ui()`에서 사기 수치를 HP 옆에 `★N` 형태로 표시한다. CONDITIONAL_DMG 효과는 `status_type`이 "morale"인 경우 `_enemy_status` 대신 card 소유 영웅의 `_hero_status`를 검사하도록 분기한다.

**Tech Stack:** GDScript 4.6, Godot 4.6 headless test runner (`"H:/Program Files/Godot/Godot_v4.6.2-stable_win64_console.exe" --headless -s tests/test_runner.gd`)

---

## 파일 맵

- **Modify:** `autoload/battle_manager.gd` — morale_changed 시그널 추가, GAIN_MORALE/CONSUME_MORALE에서 emit, CONDITIONAL_DMG 분기 수정
- **Modify:** `scenes/battle/battle_scene.gd` — `_update_hero_ui()`에 사기 표시, `morale_changed` 시그널 연결
- **Modify:** `tests/test_battle_manager.gd` — CONDITIONAL_DMG 사기 조건 테스트 추가

---

### Task 1: BattleManager — morale_changed 시그널 + CONDITIONAL_DMG 수정

**Files:**
- Modify: `autoload/battle_manager.gd`
- Modify: `tests/test_battle_manager.gd`

**배경:**
현재 GAIN_MORALE/CONSUME_MORALE은 사기를 변경하지만 UI에 알리는 시그널이 없다.
또한 CONDITIONAL_DMG(`보로디노 포격` 등)는 대상 *적*의 status를 검사하는데, 나폴레옹 카드에서는 카드 소유자 영웅의 사기를 검사해야 한다.

- [ ] **Step 1: 실패하는 테스트 작성**

`tests/test_battle_manager.gd`의 `run_all()` 안에 아래 두 호출을 추가:
```gdscript
	test_conditional_dmg_checks_owner_morale()
	test_morale_changed_signal_emitted()
```

파일 끝에 두 함수 추가:
```gdscript
func test_conditional_dmg_checks_owner_morale() -> void:
	print("[TestBattleManager] test_conditional_dmg_checks_owner_morale")
	var bm := _make_bm()
	var hero := _make_hero("napoleon", 70)
	bm.team_mgr.add_hero(hero)
	var enemy := _make_enemy(100, [])
	bm.setup_battle([enemy])
	bm.start_player_turn()

	# 사기 없을 때: value=14 피해
	var card_no_morale := CardRes.new()
	card_no_morale.card_name = "보로디노 포격"
	card_no_morale.owner_id = "napoleon"
	card_no_morale.cost = 0
	var eff_cond := EffectRes.new()
	eff_cond.effect_type = EffectRes.EffectType.CONDITIONAL_DMG
	eff_cond.value = 14
	eff_cond.bonus_value = 20
	eff_cond.status_type = "morale"
	eff_cond.target = "SINGLE"
	card_no_morale.effects = [eff_cond]
	bm._apply_card_effects(card_no_morale, 0)
	_assert(bm.get_enemy_hp(0) == 86, "사기 0 → 14 피해 (100-14=86)")

	# 사기 1 부여 후: bonus_value=20 피해
	bm._hero_status["napoleon"] = {"morale": 1}
	bm._apply_card_effects(card_no_morale, 0)
	_assert(bm.get_enemy_hp(0) == 66, "사기 1 → 20 피해 (86-20=66)")

func test_morale_changed_signal_emitted() -> void:
	print("[TestBattleManager] test_morale_changed_signal_emitted")
	var bm := _make_bm()
	var hero := _make_hero("napoleon", 70)
	bm.team_mgr.add_hero(hero)
	bm.setup_battle([_make_enemy(30, [])])
	bm.start_player_turn()

	var signals_received: Array = []
	bm.morale_changed.connect(func(hid, val): signals_received.append([hid, val]))

	# GAIN_MORALE 카드 사용
	var card := CardRes.new()
	card.card_name = "gain_morale_test"
	card.owner_id = "napoleon"
	card.cost = 0
	var eff := EffectRes.new()
	eff.effect_type = EffectRes.EffectType.GAIN_MORALE
	eff.value = 2
	card.effects = [eff]
	bm._apply_card_effects(card, -1)

	_assert(signals_received.size() == 1, "morale_changed 시그널 1회 발화")
	_assert(signals_received[0][0] == "napoleon", "hero_id = napoleon")
	_assert(signals_received[0][1] == 2, "new morale value = 2")
```

- [ ] **Step 2: 테스트 실패 확인**

```bash
"H:/Program Files/Godot/Godot_v4.6.2-stable_win64_console.exe" --headless -s tests/test_runner.gd 2>&1 | grep -E "FAIL|Results"
```

Expected: `FAIL: 사기 0 → 14 피해` 또는 `morale_changed 시그널` 포함, failed > 0

- [ ] **Step 3: BattleManager 수정**

`autoload/battle_manager.gd`의 시그널 목록(line ~38)에 추가:
```gdscript
signal morale_changed(hero_id: String, new_value: int)
```

`_apply_card_effects()`의 GAIN_MORALE 블록(line ~145)을 다음으로 교체:
```gdscript
			EffectRes.EffectType.GAIN_MORALE:
				if not _hero_status.has(card.owner_id):
					_hero_status[card.owner_id] = {}
				var new_morale: int = _hero_status[card.owner_id].get("morale", 0) + effect.value
				_hero_status[card.owner_id]["morale"] = new_morale
				status_applied.emit(card.owner_id, "morale", effect.value)
				morale_changed.emit(card.owner_id, new_morale)
```

`_apply_card_effects()`의 CONSUME_MORALE 블록(line ~151)을 다음으로 교체:
```gdscript
			EffectRes.EffectType.CONSUME_MORALE:
				var morale: int = _hero_status.get(card.owner_id, {}).get("morale", 0)
				if morale >= effect.value:
					var new_morale: int = morale - effect.value
					_hero_status[card.owner_id]["morale"] = new_morale
					morale_changed.emit(card.owner_id, new_morale)
					if target_enemy_index >= 0 and target_enemy_index < _enemies.size():
						_deal_damage_to_enemy(target_enemy_index, effect.bonus_value)
```

`_apply_card_effects()`의 CONDITIONAL_DMG 블록(line ~180)을 다음으로 교체:
```gdscript
			EffectRes.EffectType.CONDITIONAL_DMG:
				if target_enemy_index >= 0 and target_enemy_index < _enemies.size():
					var condition_met: bool
					if effect.status_type == "morale":
						# 소유자 영웅의 사기 확인
						condition_met = _hero_status.get(card.owner_id, {}).get("morale", 0) > 0
					else:
						# 대상 적의 상태이상 확인
						condition_met = _enemy_status[target_enemy_index].get(effect.status_type, 0) > 0
					var dmg: int = effect.bonus_value if condition_met else effect.value
					_deal_damage_to_enemy(target_enemy_index, dmg)
```

- [ ] **Step 4: 테스트 통과 확인**

```bash
"H:/Program Files/Godot/Godot_v4.6.2-stable_win64_console.exe" --headless -s tests/test_runner.gd 2>&1 | grep "Results"
```

Expected: `=== Results: 102 passed, 0 failed ===`

- [ ] **Step 5: 커밋**

```bash
git add autoload/battle_manager.gd tests/test_battle_manager.gd
git commit -m "fix: morale_changed 시그널 + CONDITIONAL_DMG 소유자 사기 조건 수정"
```

---

### Task 2: BattleScene — 사기 UI 표시

**Files:**
- Modify: `scenes/battle/battle_scene.gd`

**배경:**
나폴레옹의 사기(Morale) 수치가 BattleManager에서 추적되지만 화면에 표시되지 않는다.
`_update_hero_ui()`에서 영웅의 사기를 `★N` 형태로 HP 옆에 표시하고,
`morale_changed` 시그널을 받아 즉시 UI를 갱신한다.

- [ ] **Step 1: `_ready()`에서 morale_changed 시그널 연결**

`scenes/battle/battle_scene.gd`에서 `BattleManager.status_applied.connect(_on_status_applied)` 라인을 찾아 바로 아래에 추가:
```gdscript
	BattleManager.morale_changed.connect(_on_morale_changed)
```

- [ ] **Step 2: `_update_hero_ui()` 수정**

현재 (line ~355):
```gdscript
func _update_hero_ui(hero_id: String) -> void:
	for entry in _hero_nodes:
		if entry["hero_id"] != hero_id:
			continue
		var hero: Resource = TeamManager.get_hero(hero_id)
		if hero == null:
			return
		var cur_hp: int = TeamManager.get_current_hp(hero_id)
		var block: int = BattleManager.get_hero_block(hero_id)
		var block_str: String = "  🛡%d" % block if block > 0 else ""
		entry["hp_lbl"].text = "HP %d/%d%s" % [cur_hp, hero.max_hp, block_str]
		entry["block_lbl"].text = ""
		if not TeamManager.is_alive(hero_id):
			entry["panel"].modulate = Color(0.4, 0.4, 0.4)
		_refresh_status_icons_hero(hero_id)
		return
```

다음으로 교체:
```gdscript
func _update_hero_ui(hero_id: String) -> void:
	for entry in _hero_nodes:
		if entry["hero_id"] != hero_id:
			continue
		var hero: Resource = TeamManager.get_hero(hero_id)
		if hero == null:
			return
		var cur_hp: int = TeamManager.get_current_hp(hero_id)
		var block: int = BattleManager.get_hero_block(hero_id)
		var block_str: String = "  🛡%d" % block if block > 0 else ""
		var status: Dictionary = BattleManager.get_hero_status(hero_id)
		var morale: int = status.get("morale", 0)
		var morale_str: String = "  ★%d" % morale if morale > 0 else ""
		entry["hp_lbl"].text = "HP %d/%d%s%s" % [cur_hp, hero.max_hp, block_str, morale_str]
		entry["block_lbl"].text = ""
		if not TeamManager.is_alive(hero_id):
			entry["panel"].modulate = Color(0.4, 0.4, 0.4)
		_refresh_status_icons_hero(hero_id)
		return
```

- [ ] **Step 3: `_on_morale_changed()` 함수 추가**

`_on_status_applied()` 함수 근처에 추가:
```gdscript
func _on_morale_changed(hero_id: String, _new_value: int) -> void:
	_update_hero_ui(hero_id)
```

- [ ] **Step 4: 직접 테스트**

게임을 실행해 나폴레옹으로 사기 획득 카드(`경기병 돌격`, `총공세 명령` 등)를 사용했을 때:
- HP 옆에 `★1`, `★2` 등이 표시되는지 확인
- 사기 소모 카드(`황제의 기개`) 사용 시 사기가 줄어드는지 확인
- `보로디노 포격` 사용 시 사기 있을 때 20 피해, 없을 때 14 피해가 들어가는지 확인

- [ ] **Step 5: 커밋**

```bash
git add scenes/battle/battle_scene.gd
git commit -m "feat: 전투 화면 사기(Morale) UI 표시"
```

---

### Task 3: PR 생성

- [ ] **Step 1: 브랜치 확인 및 PR 생성**

```bash
git push -u origin HEAD
gh pr create --title "feat: Plan 20 — 사기 UI + CONDITIONAL_DMG 수정" --body "$(cat <<'EOF'
## Summary
- 나폴레옹의 사기(Morale) 수치를 전투 화면 HP 옆에 ★N 형태로 실시간 표시
- BattleManager에 morale_changed(hero_id, new_value) 시그널 추가
- CONDITIONAL_DMG 효과에서 status_type=morale 조건은 카드 소유자 영웅의 사기를 검사하도록 수정 (보로디노 포격 버그 수정)

## Test Plan
- [ ] 102 passed, 0 failed
- [ ] 나폴레옹 사기 획득 카드 사용 시 ★N 표시 확인
- [ ] 보로디노 포격 — 사기 있을 때 20, 없을 때 14 피해 확인
EOF
)"
```
