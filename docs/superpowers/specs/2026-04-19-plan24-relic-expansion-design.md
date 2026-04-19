# Plan 24 — 렐릭 확장 + 전투 시각 피드백 설계

> 작성일: 2026-04-19

---

## 범위

1. **전투 시각 피드백** — 데미지/블록 흡수 팝업 숫자 + 시그널 발화 버그 수정
2. **렐릭 풀 필터링** — 영웅 전용 렐릭: 팀 기준 필터, 저주 렐릭: 일반 풀 제외
3. **렐릭 9종 추가** — 영웅 전용 2번째 3종 + 저주 렐릭 3종 + 공용 3종
4. **저주 렐릭 전용 이벤트 1종** — "악마의 거래" 이벤트

---

## 1. 전투 시각 피드백

### 1-1. 블록 흡수 시그널 버그 수정

**현재 버그:** `_deal_damage_to_enemy` / `_deal_damage_to_hero`에서 블록이 피해를 완전 흡수하면 `amount == 0`이 되어 시그널이 발화하지 않음. 결과적으로 전투 UI가 갱신되지 않음.

**수정:** `enemy_damaged` / `hero_damaged` 시그널을 `amount` 값과 무관하게 항상 발화. `amount == 0`은 "블록이 완전 흡수했음"을 의미하며 UI 갱신에 활용.

### 1-2. 데미지 팝업 숫자

피해 또는 블록 흡수 발생 시 해당 유닛 위치에 숫자 레이블이 위로 뜨며 페이드아웃.

**색상 규칙:**
- 실제 피해 (amount > 0): 빨강 `Color(1.0, 0.2, 0.2)`
- 블록 완전 흡수 (amount == 0): 파랑 `Color(0.4, 0.8, 1.0)`, 텍스트 "BLOCK"
- 블록 일부 흡수 후 피해: 빨강으로 실제 피해량 표시 (별도 BLOCK 팝업 없음)

**애니메이션:** Tween으로 0.8초간 y -60 이동 + alpha 0→1→0.

**구현 위치:** `battle_scene.gd`에 `_spawn_damage_popup(pos: Vector2, amount: int, is_blocked: bool)` 함수 추가.

**팝업 트리거:**
- 적 피해: `_on_enemy_damaged(index, amount)` 에서 해당 적 패널 위치 기준
- 영웅 피해: `_on_hero_damaged(hero_id, amount)` 에서 해당 영웅 패널 위치 기준

---

## 2. 렐릭 시스템 개선

### 2-1. RelicResource 필드 추가

```gdscript
@export var is_cursed: bool = false  # true = 저주 렐릭, 특정 이벤트에서만 획득 가능
```

### 2-2. 렐릭 풀 필터링 (`get_random_relic()`)

현재: 전체 풀에서 미보유 렐릭 랜덤 선택.

변경 후:
1. `is_cursed == true` 인 렐릭 → 항상 제외
2. `owner_hero_id != ""` 인 렐릭 → 해당 영웅이 현재 팀에 없으면 제외

```
get_random_relic():
  pool = _build_relic_pool()
  pool = pool.filter(not is_cursed)
  pool = pool.filter(owner_hero_id == "" or hero in team)
  pool = pool.filter(not already owned)
  return random from pool
```

**저주 렐릭 전용 함수** `get_random_cursed_relic()` 추가: 저주 렐릭 풀에서만 선택.

---

## 3. 렐릭 9종

### 영웅 전용 2번째 (3종)

| 이름 | 영웅 | Trigger | 효과 |
|---|---|---|---|
| 포병 나팔 | 나폴레옹 | PLAYER_TURN_START | 턴 시작 시 사기 +1 (나폴레옹 생존 시 적용) |
| 난중일기 | 이순신 | BATTLE_WIN | 전투 승리 시 팀 HP +8 (이순신 생존 시 적용) |
| 파라오의 인장 | 클레오파트라 | PLAYER_TURN_START | 턴 시작 시 무작위 적 독 +1 (클레오파트라 생존 시 적용) |

- `owner_hero_id`가 설정된 렐릭은 `trigger_relics()`에서 해당 영웅 생존 시에만 발동 (기존 로직 유지).
- `value = 0, bonus_value = 효과값` 패턴 유지.

### 저주 렐릭 (3종)

저주 렐릭은 이중 효과 구조: 강력한 이득 + 지속적 패널티.

| 이름 | 이득 | 패널티 |
|---|---|---|
| 악마의 계약 | 전투 승리 시 팀 HP +20 | 매 플레이어 턴 시작 시 무작위 영웅 HP -3 |
| 저주받은 왕관 | 최대 HP +25 (PASSIVE) | 매 전투 시작 시 팀 전체 HP -8 |
| 피의 서약 | 에너지 +1 (PLAYER_TURN_START) | 매 플레이어 턴 종료 시 무작위 영웅 HP -4 |

**패널티 구현:** 새 EffectType `DAMAGE_HERO` 추가. `_apply_relic_effect()`에서 무작위 살아있는 영웅에게 직접 HP 감소 (블록 우회, TeamManager.take_damage 직접 호출).

저주 렐릭은 `is_cursed = true` 설정.

### 공용 렐릭 (3종)

| 이름 | Trigger | 효과 |
|---|---|---|
| 전술가의 지도 | BATTLE_START | 전투 시작 시 카드 1장 추가 드로우 |
| 강철 의지 | PASSIVE | 최대 HP +10, 전투 시작 에너지 +1 (PASSIVE 대신 BATTLE_START ENERGY +1로 구현) |
| 고대의 방패 | BATTLE_START | 전투 시작 시 팀 전체 방어도 +4 |

> 고대의 방패는 새 EffectType `BLOCK_ALL` 필요 (전체 영웅 방어도 부여).

---

## 4. 저주 렐릭 전용 이벤트

### "악마의 거래" 이벤트

> "어둠 속 제단에서 목소리가 들린다. '내 힘을 원하느냐? 대가는 네가 치르게 될 것이다.'"

**선택지:**
- **[받아들인다]** → 50% 좋은 렐릭 (`get_random_relic()`) / 50% 저주 렐릭 (`get_random_cursed_relic()`)
- **[거절한다]** → 아무 일도 없음

**구현:** `game_manager.gd`의 이벤트 풀에 추가. `EventType.ADD_RELIC` 결과를 `get_random_cursed_relic()` 또는 `get_random_relic()`으로 분기.

---

## 영향받는 파일

| 파일 | 변경 내용 |
|---|---|
| `resources/relic_resource.gd` | `is_cursed` 필드, `DAMAGE_HERO` / `BLOCK_ALL` EffectType 추가 |
| `autoload/game_manager.gd` | 렐릭 9종 추가, 필터링 로직, 악마의 거래 이벤트, `get_random_cursed_relic()` |
| `autoload/battle_manager.gd` | 블록 흡수 시 시그널 항상 발화 |
| `scenes/battle/battle_scene.gd` | 데미지 팝업 `_spawn_damage_popup()` |

---

## 테스트 항목

- 블록 완전 흡수 시 UI 갱신 확인
- 데미지 팝업 빨강/파랑 색상 분기
- 영웅 전용 렐릭이 팀에 없는 영웅 렐릭 제외 확인
- 저주 렐릭이 일반 `get_random_relic()`에서 나오지 않음
- 악마의 거래 이벤트 분기 (수락/거절)
- 저주 렐릭 패널티 발동 확인 (DAMAGE_HERO)
