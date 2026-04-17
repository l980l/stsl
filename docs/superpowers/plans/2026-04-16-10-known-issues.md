# Known Issues Fix Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 문서화된 버그 3건을 수정한다 — TargetType.ALL 전체 대상 미적용, game_manager.gd 컴파일 에러, 블록 완전 흡수 시 0 피해 시그널 발화.

**Architecture:** battle_manager.gd의 `_execute_intent()`에서 ALL 타겟 분기를 별도 처리한다. game_manager.gd에 `_get_tm()` / `_get_dm()` 헬퍼를 추가하고 직접 참조를 모두 교체한다. `_deal_damage_to_hero()` / `_deal_damage_to_enemy()`에서 amount > 0 조건 후에만 시그널을 발화한다.

**Tech Stack:** GDScript 4.6, Godot 4.6 headless test runner

---

## 파일 맵

- **Modify:** `autoload/battle_manager.gd` — TargetType.ALL 분기 + amount=0 시그널 가드
- **Modify:** `autoload/game_manager.gd` — TeamManager/DeckManager 직접 참조 제거
- **Modify:** `tests/test_battle_manager.gd` — ALL 공격 테스트 추가

---

### Task 1: TargetType.ALL 전체 영웅 공격 버그 수정

**Files:**
- Modify: `autoload/battle_manager.gd:269-311`
- Modify: `tests/test_battle_manager.gd`

**배경:**
현재 `_execute_intent()`에서 ATTACK 인텐트는 `_pick_hero_target()`을 호출하는데, `TargetType.ALL`인 경우 `living[0].hero_id`만 반환한다. 히드라 보스 3페이즈 전체 공격이 첫 번째 영웅만 타격하는 원인이다.

- [ ] **Step 1: 실패하는 테스트 작성**

`tests/test_battle_manager.gd` 파일 끝에 다음을 추가:

```gdscript
func test_enemy_all_attack_hits_all_heroes() -> void:
	print("[TestBattleManager] test_enemy_all_attack_hits_all_heroes")
	var bm := _make_bm()
	var hero1 := _make_hero("napoleon", 70)
	var hero2 := _make_hero("cleopatra", 60)
	bm.team_mgr.add_hero(hero1)
	bm.team_mgr.add_hero(hero2)
	# ALL 공격 인텐트 생성
	var intent := IntentRes.new()
	intent.action_type = IntentRes.ActionType.ATTACK
	intent.value = 10
	intent.target = IntentRes.TargetType.ALL
	var enemy := _make_enemy(30, [intent])
	bm.setup_battle([enemy])
	bm.start_player_turn()
	bm.end_player_turn()  # 적 턴 실행
	_assert(bm.team_mgr.get_current_hp("napoleon") == 60, "ALL 공격 → napoleon HP 70→60")
	_assert(bm.team_mgr.get_current_hp("cleopatra") == 50, "ALL 공격 → cleopatra HP 60→50")
```

`run_all()`에 `test_enemy_all_attack_hits_all_heroes()` 추가:

```gdscript
func run_all() -> Dictionary:
	test_setup_battle()
	test_play_card_damage()
	test_play_card_block()
	test_block_absorbs_damage()
	test_block_resets_on_player_turn()
	test_weak_reduces_damage()
	test_vulnerable_increases_damage()
	test_poison_tick_enemy()
	test_poison_tick_hero()
	test_enemy_turn_attacks_hero()
	test_enemy_intent_advances()
	test_win_condition()
	test_lose_condition()
	test_enemy_all_attack_hits_all_heroes()
	return { "passed": passed, "failed": failed }
```

- [ ] **Step 2: 테스트 실패 확인**

```bash
"H:/Program Files/Godot/Godot_v4.6.2-stable_win64_console.exe" --headless -s tests/test_runner.gd 2>&1 | grep -E "FAIL|Results"
```

Expected: `FAIL: ALL 공격 → napoleon HP 70→60` (또는 cleopatra) 포함, Results에 failed > 0

- [ ] **Step 3: battle_manager.gd `_execute_intent()` 수정**

`autoload/battle_manager.gd`의 `_execute_intent()` 함수(line ~269)를 다음으로 교체:

```gdscript
func _execute_intent(enemy_index: int, intent: Resource) -> void:
	match intent.action_type:
		IntentRes.ActionType.ATTACK:
			var dmg: int = intent.value
			if _enemy_status[enemy_index].get("weak", 0) > 0:
				dmg = int(dmg * 0.75)
			if intent.target == IntentRes.TargetType.ALL:
				if team_mgr:
					for hero in team_mgr.get_living_heroes():
						_deal_damage_to_hero(hero.hero_id, dmg)
			else:
				var target_id: String = _pick_hero_target(intent.target, enemy_index)
				if target_id != "":
					_deal_damage_to_hero(target_id, dmg)
		IntentRes.ActionType.BUFF:
			_enemy_block[enemy_index] += intent.value
		IntentRes.ActionType.DEBUFF:
			var stype: String = intent.status_type
			if intent.target == IntentRes.TargetType.ALL:
				if team_mgr:
					for hero in team_mgr.get_living_heroes():
						_apply_status_to_hero(hero.hero_id, stype, intent.value)
			else:
				var target_id: String = _pick_hero_target(intent.target, enemy_index)
				if target_id != "":
					_apply_status_to_hero(target_id, stype, intent.value)
		IntentRes.ActionType.SPECIAL:
			if deck_mgr:
				deck_mgr.discard_random(intent.value)
```

`_pick_hero_target()`에서 `TargetType.ALL` 케이스 제거 (line ~309):

```gdscript
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
	return ""
```

- [ ] **Step 4: 테스트 통과 확인**

```bash
"H:/Program Files/Godot/Godot_v4.6.2-stable_win64_console.exe" --headless -s tests/test_runner.gd 2>&1 | grep -E "Results"
```

Expected: `=== Results: 266 passed, 0 failed ===`

- [ ] **Step 5: 커밋**

```bash
git checkout -b fix/known-issues
git add autoload/battle_manager.gd tests/test_battle_manager.gd
git commit -m "fix: TargetType.ALL 전체 영웅 공격 미적용 버그 수정"
```

---

### Task 2: game_manager.gd TeamManager/DeckManager 직접 참조 컴파일 에러 수정

**Files:**
- Modify: `autoload/game_manager.gd`

**배경:**
`game_manager.gd`에서 `TeamManager`, `DeckManager`를 직접 식별자로 참조한다. Godot는 autoload를 project.godot 순서대로 로드하므로 GameManager가 TeamManager보다 먼저 컴파일된다. 결과적으로 hot-reload 시 `Identifier not found: TeamManager` 컴파일 에러가 발생한다.

해결: `Engine.get_singleton()`을 사용하는 `_get_tm()` / `_get_dm()` 헬퍼를 추가하고 모든 직접 참조를 교체한다.

직접 참조 위치 목록:
- `TeamManager`: lines 73, 80, 191, 192, 395, 405, 902, 909, 910, 920, 933, 934
- `DeckManager`: lines 83, 97, 108, 444, 449, 455, 462, 913, 914, 917, 939, 940

- [ ] **Step 1: 헬퍼 함수 추가**

`game_manager.gd`의 `change_state()` 앞(약 line 29)에 두 헬퍼를 추가:

```gdscript
func _get_tm() -> Object:
	return Engine.get_singleton("TeamManager") if Engine.has_singleton("TeamManager") else null

func _get_dm() -> Object:
	return Engine.get_singleton("DeckManager") if Engine.has_singleton("DeckManager") else null
```

- [ ] **Step 2: `start_run()` 수정 (line 69~114)**

```gdscript
func start_run() -> void:
	reset()

	# TeamManager 초기화 (나폴레옹 1명)
	var tm := _get_tm()
	if tm:
		tm.clear()
	var HeroRes = load("res://resources/hero_resource.gd")
	var napoleon: Resource = HeroRes.new()
	napoleon.hero_id = "napoleon"
	napoleon.hero_name = "나폴레옹"
	napoleon.max_hp = 70
	napoleon.character_scene = load("res://characters/heroes/napoleon/napoleon.tscn")
	if tm:
		tm.add_hero(napoleon)

	# DeckManager 초기화 (스트라이크 3 + 디펜드 2)
	var dm := _get_dm()
	if dm:
		dm.clear()
	var CardRes = load("res://resources/card_resource.gd")
	var EffRes = load("res://resources/effect_resource.gd")
	for _i in range(3):
		var card: Resource = CardRes.new()
		card.card_name = "스트라이크"
		card.owner_id = "napoleon"
		card.cost = 1
		card.play_animation = "attack"
		var eff: Resource = EffRes.new()
		eff.effect_type = EffRes.EffectType.DAMAGE
		eff.value = 6
		eff.target = "SINGLE"
		card.effects = [eff]
		if dm:
			dm.add_card_to_deck(card)
	for _i in range(2):
		var card: Resource = CardRes.new()
		card.card_name = "디펜드"
		card.owner_id = "napoleon"
		card.cost = 1
		card.play_animation = "idle"
		var eff: Resource = EffRes.new()
		eff.effect_type = EffRes.EffectType.BLOCK
		eff.value = 5
		card.effects = [eff]
		if dm:
			dm.add_card_to_deck(card)

	# 맵 생성
	var MapGen = load("res://autoload/map_generator.gd")
	run_map = MapGen.generate()
	available_node_ids = [0, 1, 2]  # floor 0 전체 접근 가능
	run_started.emit()
	# 씬 전환 없음 — MapScene._ready()에서 호출되므로 이미 MapScene에 있음
```

- [ ] **Step 3: `_heal_all_heroes()` 수정 (line ~188)**

```gdscript
func _heal_all_heroes(amount: int) -> void:
	if not is_inside_tree():
		return
	var tm := _get_tm()
	if tm == null:
		return
	for hero in tm.heroes:
		tm.heal(hero.hero_id, amount)
```

- [ ] **Step 4: `_generate_card_rewards()` 수정 (line ~393)**

```gdscript
func _generate_card_rewards() -> Array:
	var tm := _get_tm()
	if tm == null:
		return []
	var pool: Array = []
	for hero in tm.heroes:
		match hero.hero_id:
			"napoleon":   pool.append_array(_napoleon_card_pool())
			"cleopatra":  pool.append_array(_cleopatra_card_pool())
			"yi_sun_sin": pool.append_array(_yi_sun_sin_card_pool())
	pool.shuffle()
	return pool.slice(0, min(3, pool.size()))
```

- [ ] **Step 5: `_recruit_hero_pool()` 수정 (line ~403)**

```gdscript
func _recruit_hero_pool() -> Array:
	var tm := _get_tm()
	if tm == null:
		return []
	var existing := []
	for h in tm.heroes:
		existing.append(h.hero_id)
	var pool := []
	if "cleopatra" not in existing:
		pool.append(_make_cleopatra_hero())
	if "yi_sun_sin" not in existing:
		pool.append(_make_yi_sun_sin_hero())
	return pool
```

- [ ] **Step 6: `_add_initial_deck_for()` 수정**

함수 내 모든 `DeckManager.add_card_to_deck(c)` 호출을 다음 패턴으로 교체:

함수 최상단에 `var dm := _get_dm()` 추가 후, 모든 `DeckManager.add_card_to_deck(c)` → `if dm: dm.add_card_to_deck(c)` 로 변경.

현재 코드(약 line 432~470)를 다음으로 교체:

```gdscript
func _add_initial_deck_for(hero: Resource) -> void:
	var CardRes = load("res://resources/card_resource.gd")
	var EffRes = load("res://resources/effect_resource.gd")
	var dm := _get_dm()
	match hero.hero_id:
		"cleopatra":
			for _i in range(2):
				var c: Resource = CardRes.new(); c.card_name = "독침"
				c.owner_id = "cleopatra"; c.cost = 1; c.play_animation = "attack"
				var e: Resource = EffRes.new(); e.effect_type = EffRes.EffectType.DAMAGE
				e.value = 3; e.target = "SINGLE"
				var ep: Resource = EffRes.new(); ep.effect_type = EffRes.EffectType.APPLY_STATUS
				ep.status_type = "poison"; ep.value = 3; ep.target = "SINGLE"
				c.effects = [e, ep]
				if dm: dm.add_card_to_deck(c)
			for _i in range(2):
				var c: Resource = CardRes.new(); c.card_name = "왕실 방어"
				c.owner_id = "cleopatra"; c.cost = 1; c.play_animation = "idle"
				var e: Resource = EffRes.new(); e.effect_type = EffRes.EffectType.BLOCK; e.value = 6
				c.effects = [e]
				if dm: dm.add_card_to_deck(c)
		"yi_sun_sin":
			for _i in range(2):
				var c: Resource = CardRes.new(); c.card_name = "방패"
				c.owner_id = "yi_sun_sin"; c.cost = 1; c.play_animation = "idle"
				var e: Resource = EffRes.new(); e.effect_type = EffRes.EffectType.BLOCK; e.value = 7
				c.effects = [e]
				if dm: dm.add_card_to_deck(c)
			for _i in range(2):
				var c: Resource = CardRes.new(); c.card_name = "역공"
				c.owner_id = "yi_sun_sin"; c.cost = 1; c.play_animation = "attack"
				var eb: Resource = EffRes.new(); eb.effect_type = EffRes.EffectType.BLOCK; eb.value = 3
				var ed: Resource = EffRes.new(); ed.effect_type = EffRes.EffectType.DAMAGE
				ed.value = 3; ed.target = "SINGLE"
				c.effects = [eb, ed]
				if dm: dm.add_card_to_deck(c)
```

> **참고:** `yi_sun_sin` 브랜치의 나머지 카드가 있다면 동일 패턴 적용.

- [ ] **Step 7: `_is_hero_alive()` 수정 (line ~899)**

```gdscript
func _is_hero_alive(hero_id: String) -> bool:
	if not is_inside_tree():
		return false
	var tm := _get_tm()
	return tm != null and tm.is_alive(hero_id)
```

- [ ] **Step 8: `_apply_relic_effect()` 수정 (line ~904)**

```gdscript
func _apply_relic_effect(relic: Resource, value: int, context: Dictionary) -> void:
	var RelicRes = load("res://resources/relic_resource.gd")
	var tm := _get_tm()
	var dm := _get_dm()
	match relic.effect_type:
		RelicRes.EffectType.HEAL:
			if is_inside_tree() and tm:
				for hero in tm.heroes:
					tm.heal(hero.hero_id, value)
		RelicRes.EffectType.ENERGY:
			if is_inside_tree() and dm:
				dm.current_energy += value
				dm.energy_changed.emit(dm.current_energy)
		RelicRes.EffectType.DRAW:
			if is_inside_tree() and dm:
				dm.draw_cards(value)
		RelicRes.EffectType.BLOCK:
			if is_inside_tree() and BattleManager and tm:
				for hero in tm.heroes:
					BattleManager._hero_block[hero.hero_id] = \
						BattleManager._hero_block.get(hero.hero_id, 0) + value
		RelicRes.EffectType.APPLY_STATUS_ENEMY:
			if is_inside_tree() and BattleManager and BattleManager.is_battle_active:
				for i in range(BattleManager._enemies.size()):
					if BattleManager._enemy_alive[i]:
						BattleManager._apply_status_to_enemy(i, "poison", value)
		RelicRes.EffectType.GAIN_MORALE:
			if is_inside_tree() and BattleManager:
				BattleManager._apply_status_to_hero(relic.owner_hero_id, "morale", value)
		RelicRes.EffectType.MAX_HP:
			if is_inside_tree() and tm:
				for hero in tm.heroes:
					tm.increase_max_hp(hero.hero_id, value)
		RelicRes.EffectType.ON_HERO_DAMAGED:
			var amount: int = context.get("amount", 0)
			if amount >= relic.condition_value and is_inside_tree() and dm:
				dm.current_energy += 1
				dm.energy_changed.emit(dm.current_energy)
```

- [ ] **Step 9: 테스트 실행 — 컴파일 에러 소멸 확인**

```bash
"H:/Program Files/Godot/Godot_v4.6.2-stable_win64_console.exe" --headless -s tests/test_runner.gd 2>&1 | head -20
```

Expected: `Compile Error: Identifier not found: TeamManager` 줄이 더 이상 없음.

최종 Results 확인:
```bash
"H:/Program Files/Godot/Godot_v4.6.2-stable_win64_console.exe" --headless -s tests/test_runner.gd 2>&1 | grep "Results"
```

Expected: `=== Results: 266 passed, 0 failed ===`

- [ ] **Step 10: 커밋**

```bash
git add autoload/game_manager.gd
git commit -m "fix: game_manager.gd TeamManager/DeckManager 직접 참조 → Engine.get_singleton 패턴"
```

---

### Task 3: 블록 완전 흡수 시 amount=0 시그널 발화 수정

**Files:**
- Modify: `autoload/battle_manager.gd:182-216`
- Modify: `tests/test_battle_manager.gd`

**배경:**
`_deal_damage_to_hero()`에서 블록이 모든 피해를 흡수해 `amount == 0`이 되어도 `hero_damaged.emit(hero_id, 0)`이 발화된다. 이는 UI에서 0 피해 이펙트를 표시하는 원인이 된다. `_deal_damage_to_enemy()`도 동일 패턴이다.

- [ ] **Step 1: 실패하는 테스트 작성**

`tests/test_battle_manager.gd`에 추가:

```gdscript
func test_hero_damaged_not_emitted_when_fully_blocked() -> void:
	print("[TestBattleManager] test_hero_damaged_not_emitted_when_fully_blocked")
	var bm := _make_bm()
	var hero := _make_hero("napoleon", 70)
	bm.team_mgr.add_hero(hero)
	bm.setup_battle([_make_enemy(30, [])])
	bm.start_player_turn()

	# 블록 10 부여
	bm._hero_block["napoleon"] = 10

	var damage_emitted: Array = []
	bm.hero_damaged.connect(func(id, amt): damage_emitted.append(amt))

	# 피해 10 → 블록 10이 전부 흡수 → amount == 0
	bm._deal_damage_to_hero("napoleon", 10)
	_assert(damage_emitted.is_empty(), "블록 완전 흡수 시 hero_damaged 발화 없음")
	_assert(bm.team_mgr.get_current_hp("napoleon") == 70, "HP 변화 없음")

func test_enemy_damaged_not_emitted_when_fully_blocked() -> void:
	print("[TestBattleManager] test_enemy_damaged_not_emitted_when_fully_blocked")
	var bm := _make_bm()
	var hero := _make_hero("napoleon", 70)
	bm.team_mgr.add_hero(hero)
	bm.setup_battle([_make_enemy(30, [])])
	bm.start_player_turn()

	# 적 블록 10 부여
	bm._enemy_block[0] = 10

	var damage_emitted: Array = []
	bm.enemy_damaged.connect(func(idx, amt): damage_emitted.append(amt))

	# 피해 10 → 블록 10이 전부 흡수
	bm._deal_damage_to_enemy(0, 10)
	_assert(damage_emitted.is_empty(), "블록 완전 흡수 시 enemy_damaged 발화 없음")
	_assert(bm.get_enemy_hp(0) == 30, "적 HP 변화 없음")
```

`run_all()`에 두 테스트 추가:

```gdscript
	test_hero_damaged_not_emitted_when_fully_blocked()
	test_enemy_damaged_not_emitted_when_fully_blocked()
```

- [ ] **Step 2: 테스트 실패 확인**

```bash
"H:/Program Files/Godot/Godot_v4.6.2-stable_win64_console.exe" --headless -s tests/test_runner.gd 2>&1 | grep -E "FAIL|Results"
```

Expected: 두 새 테스트가 FAIL, failed > 0

- [ ] **Step 3: `_deal_damage_to_hero()` 수정**

`autoload/battle_manager.gd`의 `_deal_damage_to_hero()`(line ~198)에서 `hero_damaged.emit`을 `if amount > 0` 블록 안으로 이동:

```gdscript
func _deal_damage_to_hero(hero_id: String, amount: int) -> void:
	if team_mgr == null or not team_mgr.is_alive(hero_id):
		return
	var status: Dictionary = _hero_status.get(hero_id, {})
	if status.get("vulnerable", 0) > 0:
		amount = int(amount * 1.5)
	var block: int = _hero_block.get(hero_id, 0)
	var absorbed: int = min(block, amount)
	_hero_block[hero_id] = block - absorbed
	amount -= absorbed
	if amount > 0:
		team_mgr.take_damage(hero_id, amount)
		var _gm_hd = Engine.get_singleton("GameManager") if Engine.has_singleton("GameManager") else null
		if _gm_hd and _gm_hd.is_inside_tree():
			var RelicRes = load("res://resources/relic_resource.gd")
			_gm_hd.trigger_relics(RelicRes.TriggerType.ON_HERO_DAMAGED,
				{"hero_id": hero_id, "amount": amount})
		hero_damaged.emit(hero_id, amount)
	_check_lose_condition()
```

- [ ] **Step 4: `_deal_damage_to_enemy()` 수정**

`autoload/battle_manager.gd`의 `_deal_damage_to_enemy()`(line ~182)에서 `enemy_damaged.emit`에 조건 추가:

```gdscript
func _deal_damage_to_enemy(enemy_index: int, amount: int) -> void:
	if not _enemy_alive[enemy_index]:
		return
	if _enemy_status[enemy_index].get("vulnerable", 0) > 0:
		amount = int(amount * 1.5)
	var absorbed: int = min(_enemy_block[enemy_index], amount)
	_enemy_block[enemy_index] -= absorbed
	amount -= absorbed
	_enemy_hp[enemy_index] = max(0, _enemy_hp[enemy_index] - amount)
	if amount > 0:
		enemy_damaged.emit(enemy_index, amount)
	if _enemy_hp[enemy_index] == 0:
		_enemy_alive[enemy_index] = false
		enemy_died.emit(enemy_index)
	_check_phase_transition(enemy_index)
	_check_win_condition()
```

- [ ] **Step 5: 테스트 통과 확인**

```bash
"H:/Program Files/Godot/Godot_v4.6.2-stable_win64_console.exe" --headless -s tests/test_runner.gd 2>&1 | grep "Results"
```

Expected: `=== Results: 268 passed, 0 failed ===`

- [ ] **Step 6: 커밋 및 PR**

```bash
git add autoload/battle_manager.gd tests/test_battle_manager.gd
git commit -m "fix: 블록 완전 흡수 시 amount=0 시그널 발화 제거"
git push -u origin fix/known-issues
```

PR 생성:
```bash
gh pr create --title "fix: Known Issues 3건 수정 (ALL 공격, 컴파일 에러, 0 피해 시그널)" \
  --body "$(cat <<'EOF'
## Summary
- TargetType.ALL 인텐트가 첫 번째 영웅만 타격하던 버그 수정 → 전체 생존 영웅에게 피해 적용
- game_manager.gd에서 TeamManager/DeckManager 직접 참조 제거 → Engine.get_singleton 패턴으로 교체, hot-reload 컴파일 에러 해소
- _deal_damage_to_hero / _deal_damage_to_enemy에서 블록 완전 흡수 시 amount=0 시그널 발화 제거

## Test Plan
- [ ] 268 passed, 0 failed
- [ ] 테스트 출력 상단에 Compile Error 없음
EOF
)"
```
