# 챕터 2 일본 신화 렐릭 기획 v1

## 배분 방침

- 3종 모두 공용 렐릭 (`owner_hero_id` 없음) — 한국·중국 신화 렐릭과 동일 방식
- 일본 신화 테마 "요괴·정밀 타격"과 "다중 상태이상" 시그니처 반영
- 기존 렐릭 40종(M5 완료 기준 34종 + 중국 3종 = 37종)과 트리거·효과 조합이 겹치지 않도록 차별화

기존 챕터 2 렐릭 현황 (한국 + 중국):
- 저승 부적: BATTLE_START, ENERGY +1
- 도깨비 방망이 파편: BATTLE_WIN, GAIN_MORALE +3
- 삼태극 부적: ON_HERO_DAMAGED, BLOCK +10
- 용의 비늘: BATTLE_START, COST_REDUCTION 1
- 팔선의 부적: PLAYER_TURN_END, HEAL +15
- 서왕모의 복숭아: BATTLE_WIN, MAX_HP +10

일본 렐릭은 위와 겹치지 않는 트리거·효과 조합으로 차별화.

---

## 렐릭 목록 (3종)

RelicResource 트리거: `PASSIVE, BATTLE_START, PLAYER_TURN_START, PLAYER_TURN_END, BATTLE_WIN, ON_HERO_DAMAGED`
RelicResource 효과: `HEAL, ENERGY, DRAW, APPLY_STATUS_ENEMY, MAX_HP, RECOVER_CARD, GAIN_MORALE, COST_REDUCTION, BLOCK, DAMAGE_HERO`

---

### 1. 귀신 부적(鬼札)

> "오니를 봉인한 붉은 부적. 턴이 끝날 때마다 적에게 독이 스며든다."

| 항목 | 값 |
|---|---|
| 트리거 | PLAYER_TURN_END |
| 효과 | APPLY_STATUS_ENEMY (poison 2, RANDOM 적) |
| 수치 | value = 2 |
| owner_hero_id | 없음 (공용) |

**기획 의도**: 턴 종료마다 무작위 생존 적에게 독 2스택 자동 부여. "오니 봉인" 테마 — 전투 내내 독이 쌓임. 클레오파트라 POISON 빌드와 강한 시너지. 중국 팔선의 부적(PLAYER_TURN_END, HEAL)과 같은 트리거지만 효과가 적대 상태이상 부여로 차별화.

**밸런스 메모**: 10턴 전투 시 최대 독 20스택 누적. 클레오파트라 POISON_BURST와 연계 시 대미지 폭발. 적이 여럿일 때 RANDOM으로 분산 → 단일 보스전에서는 집중. 구현 시 `APPLY_STATUS_ENEMY`의 대상이 RANDOM 적 1명인지 ALL인지 확인.

> 구현 메모: `RelicResource.EffectType.APPLY_STATUS_ENEMY`가 이미 존재(기존 독약 병 BATTLE_START 용도). `PLAYER_TURN_END` 트리거 발화 시점에 `_apply_relic_effect`에서 RANDOM 적 1명 선택 후 `_apply_status_to_enemy(enemy, "poison", 2)` 호출.

---

### 2. 텐구의 깃털

> "날개 달린 요괴의 깃털. 전투가 시작될 때 손에 카드 한 장이 더 들어온다."

| 항목 | 값 |
|---|---|
| 트리거 | BATTLE_START |
| 효과 | DRAW +1 |
| 수치 | value = 1 |
| owner_hero_id | 없음 (공용) |

**기획 의도**: 전투 시작 추가 드로우 1장. "텐구의 빠른 비행" 테마. 북유럽 운명의 룬(BATTLE_START, DRAW +2)과 같은 트리거·효과지만 수치가 절반 → 스택을 의식한 설계. 두 렐릭 동시 보유 시 DRAW +3이 되어 강력한 시너지.

**밸런스 메모**: 매 전투 드로우 +1. 운명의 룬이 이미 DRAW +2를 제공하므로 중복 보유를 위한 "미니 버전"으로 설계. 둘 다 없는 빌드에서도 충분히 유용. 드로우 중심 빌드(무사시 이도류 연계)에서 효과 극대화.

---

### 3. 오로치의 비늘(大蛇の鱗)

> "야마타노오로치의 비늘. 영웅이 피해를 입을 때마다 모든 적에게 약화를 건넨다."

| 항목 | 값 |
|---|---|
| 트리거 | ON_HERO_DAMAGED |
| 효과 | APPLY_STATUS_ENEMY (weak 1, RANDOM 적) |
| 수치 | value = 1 |
| owner_hero_id | 없음 (공용) |

**기획 의도**: 영웅이 피해를 받을 때마다 무작위 적 1명에게 weak 1스택 자동 부여. "오로치의 독기" 테마 — 공격받을수록 반격. 한국 삼태극 부적(ON_HERO_DAMAGED, BLOCK +10)과 같은 트리거지만 효과가 "적 약화"로 완전 차별화.

**밸런스 메모**: 이순신 필사즉생 빌드(저HP 유지 → 자주 피격)에서 매 피격마다 weak 1 부여. 장기전에서 적 weak 누적. 단일 적 보스전에서 집중 weak 누적으로 아군 카드 효율 회복. 다중 피격(AOE 공격)에서 여러 번 발동 → 빠른 누적.

> 구현 메모: `ON_HERO_DAMAGED` 트리거는 `삼태극 부적`이 이미 동일 트리거 사용. `_apply_relic_effect`에서 동일 분기에 `APPLY_STATUS_ENEMY` 효과 추가. RANDOM 생존 적 1명 선택 후 `_apply_status_to_enemy(enemy, "weak", 1)` 호출.

---

## 구현 메모

- `relics.gd` `build_pool()` 배열에 3종 추가 후 기존 풀 크기 37 → 40으로 `test_relics.gd` 업데이트 필요.
- 함수명 제안: `_ghost_talisman()`, `_tengu_feather()`, `_orochi_scale()`
- 배너 주석: `# ──── 챕터 2 렐릭 (일본 신화) ────`
- `귀신 부적` + `오로치의 비늘` 모두 `APPLY_STATUS_ENEMY` 효과 — 구현 시 status_type 문자열(`"poison"` vs `"weak"`)로 구분. 기존 독약 병(`"poison"`) 구현 패턴 참조.
- `PLAYER_TURN_END` 트리거 (`귀신 부적`): 중국 팔선의 부적과 동일 트리거. 팔선의 부적 구현 시 이 트리거가 이미 추가되어 있어야 함.
