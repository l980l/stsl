# 챕터 2 중국 신화 렐릭 기획 v1

## 배분 방침

- 3종 모두 공용 렐릭 (`owner_hero_id` 없음) — 한국 신화 렐릭 3종과 동일 방식
- 중국 신화 테마 "천계·변신"과 "계급 소환" 시그니처 반영
- 기존 렐릭과 트리거·효과 조합이 겹치지 않도록 차별화

기존 챕터 2 렐릭 현황 (한국):
- 저승 부적: BATTLE_START, ENERGY +1
- 도깨비 방망이 파편: BATTLE_WIN, GAIN_MORALE +3
- 삼태극 부적: ON_HERO_DAMAGED, BLOCK +10

중국 렐릭은 위와 겹치지 않는 트리거·효과 조합으로 차별화.

---

## 렐릭 목록 (3종)

RelicResource 트리거: `PASSIVE, BATTLE_START, PLAYER_TURN_START, PLAYER_TURN_END, BATTLE_WIN, ON_HERO_DAMAGED`
RelicResource 효과: `HEAL, ENERGY, DRAW, APPLY_STATUS_ENEMY, MAX_HP, RECOVER_CARD, GAIN_MORALE, COST_REDUCTION, BLOCK, DAMAGE_HERO`

---

### 1. 용의 비늘(龍鱗)

> "동해 용왕의 비늘. 전투 시작 시 용의 힘이 온몸을 감싸며 비용을 절감시켜 준다."

| 항목 | 값 |
|---|---|
| 트리거 | BATTLE_START |
| 효과 | COST_REDUCTION 1 |
| 수치 | value = 1 |
| owner_hero_id | 없음 (공용) |

**기획 의도**: 전투 시작 시 이번 전투 내 카드 비용 1 감소(첫 드로우 카드 중 1장). "용왕의 힘으로 비용 절감" 테마. 한국 저승 부적(ENERGY +1)과 달리 "COST_REDUCTION" 축으로 차별화. 고비용 카드 위주 빌드(나폴레옹 군단·잔다르크 부활)에서 효과 극대화.

**밸런스 메모**: 매 전투 1회. 비용 2짜리 카드를 1비용으로 사용 가능하면 거의 에너지 +1과 동등한 효과. 구현 시 COST_REDUCTION 대상 선택(첫 드로우 카드 1장 고정 vs 플레이어 선택)을 구현 PR에서 결정.

> 구현 메모: `RelicResource.EffectType.COST_REDUCTION`이 `relic_manager.gd`에서 처리되는지 확인. 없으면 `BattleManager._apply_relic_effect`에 분기 추가.

---

### 2. 팔선(八仙)의 부적

> "여덟 신선의 힘이 깃든 부적. 턴이 끝날 때마다 상처를 회복시켜 준다."

| 항목 | 값 |
|---|---|
| 트리거 | PLAYER_TURN_END |
| 효과 | HEAL +15 |
| 수치 | value = 15 |
| owner_hero_id | 없음 (공용) |

**기획 의도**: 턴 종료마다 팀 랜덤 1명 HP +15 회복. "신선의 지속 축복" 테마. `PLAYER_TURN_END` 트리거는 기존 28종 + 한국 3종 중 미사용 구간 → 완전 차별화. 장기전 빌드에서 회복 누적 효과 강력.

**밸런스 메모**: 10턴 전투 시 최대 150 누적 회복. 빠른 전투(5턴 내)에서는 75 회복으로 상대적으로 약함. 이순신 필사즉생(저HP 유지) 빌드와 상충 — 회복이 의도된 저HP를 방해할 수 있음.

> 구현 메모: `PLAYER_TURN_END` 트리거가 `BattleManager`의 `_on_player_turn_end()` 혹은 동등 신호에서 발화되는지 확인. 미구현 시 추가 필요.

---

### 3. 서왕모의 복숭아(仙桃)

> "서왕모의 불로장생 복숭아. 전투에서 승리할 때마다 팀원이 조금씩 더 강해진다."

| 항목 | 값 |
|---|---|
| 트리거 | BATTLE_WIN |
| 효과 | MAX_HP +10 |
| 수치 | value = 10 |
| owner_hero_id | 없음 (공용) |

**기획 의도**: 전투 승리마다 팀 랜덤 1명 최대 HP +10 영구 증가. 북유럽 이둔의 사과(BATTLE_WIN, HEAL +15)와 같은 트리거지만 효과가 "MAX_HP 영구 증가"로 차별화. 런이 길어질수록 점점 강해지는 성장형 렐릭.

**밸런스 메모**: 10번 전투 승리 시 +100 최대 HP (약 10% 증가). 런 초반에는 약하지만 후반 Act 3에서 강력. `team_manager.increase_max_hp()` API 재사용(M5 잔다르크 렐릭에서 이미 구현됨).

> 구현 메모: `game_manager._on_battle_won()` → `_process_relics(TriggerType.BATTLE_WIN)` → 랜덤 살아있는 영웅에게 `team_manager.increase_max_hp(hero_id, 10)` 호출. 기존 `test_increase_max_hp` 테스트 패턴 참조.

---

## 구현 메모

- `relics.gd` `build_pool()` 배열에 3종 추가 후 기존 풀 크기 34 → 37로 `test_relics.gd` 업데이트 필요.
- 함수명 제안: `_dragon_scale()`, `_eight_immortals_charm()`, `_queen_mother_peach()`
- `PLAYER_TURN_END` 트리거 미구현 시 `BattleManager`에 `_fire_relics(TriggerType.PLAYER_TURN_END)` 훅 추가 필요. 구현 PR에서 확인.
- 배너 주석: `# ──── 챕터 2 렐릭 (중국 신화) ────`
