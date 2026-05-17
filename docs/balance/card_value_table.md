# 카드 CP (cost-point) 밸런스 표

**코드 진실원: `tools/balance_check.gd`**  
이 문서를 수정할 때 `balance_check.gd`의 상수도 반드시 동시에 갱신하세요.

---

## 1. 기본 단위 CP 상수

| 상수명 | 단위 | CP값 | 비고 |
|---|---|---|---|
| `DMG_SINGLE` | 1 dmg (단일) | 0.010 | |
| `DMG_ALL` | 1 dmg (전체) | 0.017 | AOE 보정 포함 |
| `BLOCK_SELF` | 1 block (자신) | 0.008 | |
| `BLOCK_ALL` | 1 block (전체) | 0.013 | |
| `HEAL_SELF` | 1 heal (자신) | 0.013 | |
| `HEAL_ALL` | 1 heal (전체) | 0.020 | |
| `WEAK_SGL` | 1 weak (단일) | 0.3 | |
| `WEAK_ALL_V` | 1 weak (전체) | 0.6 | |
| `POISON_SGL` | 1 poison (단일) | 0.4 | |
| `POISON_ALL_V` | 1 poison (전체) | 0.8 | |
| `CHARM_SGL` | 1 charm (단일) | **0.030** | 임계치 100 기준 (개정 2026-05-04) |
| `CHARM_ALL` | 1 charm (전체) | **0.045** | AOE 보정 (×1.5) |
| `STRENGTH_V` | 1 strength | 0.5 | |
| `MORALE_V` | 1 morale | 0.4 | |
| `TAUNT_V` | 1 taunt | 0.3 | |
| `DRAW_V` | 1 드로우 | 0.8 | |
| `ENERGY_V` | 1 에너지 | 0.7 | |
| `TOKEN_V` | 1 토큰 | 0.8 | |
| `REVIVE_BASE` | REVIVE 기본 | 3.0 | |
| `COST_NEXT_V` | 다음 카드 비용 -1 | 0.7 | |
| `COST_ZERO_V` | 이번 턴 비용 0화 | 2.5 | |
| `SPEED_PER_TURN_V` | BUFF/DEBUFF_SPEED 1 speed × 1 turn dur | **0.08** | duration 곱 |
| `SPEED_POWER_V` | power.speed_buff 1 speed (전투 끝까지) | **0.40** | |
| `SPEED_ALLY_MULT` | ALLY (단일 동맹 선택) | 1.1 | |
| `SPEED_ALL_ALLIES_MULT` | ALL_ALLIES (영웅 전체) | 1.8 | 3 영웅 보정 |
| `SPEED_ALL_ENEMY_MULT` | DEBUFF_SPEED ALL (적 전체) | 1.5 | |
| `EXHAUST_P` | 소모(exhaust) | **-0.8** | 패널티 |
| `ETHEREAL_P` | 일회성(ethereal) | **-0.5** | 패널티 |
| `INNATE_B` | 항상 시작 손패 | +0.3 | 보너스 |
| `RETAIN_B` | 유지 | +0.4 | 보너스 |
| `SACR_PER_10` | 10 HP 희생 | -0.04 | 패널티 |

---

## 2. 희귀도 배수 (RARITY_MULT)

| 희귀도 | 인덱스 | 배수 |
|---|---|---|
| COMMON | 0 | 1.0 |
| UNCOMMON | 1 | 1.1 |
| RARE | 2 | 1.2 |
| LEGENDARY | 3 | 1.3 |
| DIVINE | 4 | 1.4 |

---

## 3. 산정 공식

```
raw_cp = Σ(각 효과의 CP) + 카드 특성 보정
adj_cp = raw_cp / RARITY_MULT[rarity]
delta  = adj_cp - cost
OK: |delta| ≤ TOLERANCE (0.20)          ← 기본 카드
OK: |delta| ≤ TOLERANCE_UP (0.30)       ← 업그레이드 카드
```

카드 특성 보정:
- is_exhaust = true → raw_cp += EXHAUST_P (-0.8)
- is_ethereal = true → raw_cp += ETHEREAL_P (-0.5)
- is_innate = true → raw_cp += INNATE_B (+0.3)
- is_retain = true → raw_cp += RETAIN_B (+0.4)

---

## 4. EffectType별 CP 계산 (balance_check.gd 발췌)

| 인덱스 | EffectType | 공식 |
|---|---|---|
| 0 | DAMAGE | `value × (DMG_ALL 또는 DMG_SINGLE) × hit_count` |
| 1 | BLOCK | `value × (BLOCK_ALL 또는 BLOCK_SELF)` |
| 2 | APPLY_STATUS | → 아래 상태 테이블 참조 |
| 3 | DRAW | `value × DRAW_V` |
| 4 | ENERGY | `value × ENERGY_V` |
| 5 | SUMMON_TOKEN | `value × TOKEN_V` |
| 6 | CHARM | `value × (CHARM_ALL 또는 CHARM_SGL)` |
| 7 | HEAL | `value × (HEAL_ALL 또는 HEAL_SELF)` |
| 8 | GAIN_MORALE | `value × MORALE_V` |
| 9 | CONSUME_MORALE | `value × 0.15` |
| 10 | POISON_BURST | SKIP (복합) |
| 11 | COUNTER_BLOCK | `AVG_BLOCK × value / 100 × DMG_SINGLE` |
| 12 | BLOCK_ALL | `value × BLOCK_ALL` |
| 13 | HEAL_ALL | `value × HEAL_ALL` |
| 14 | FORMATION_BLOCK | `AVG_TEAM × value × BLOCK_SELF` |
| 15 | COST_REDUCE_NEXT | `COST_NEXT_V` |
| 16 | CONDITIONAL_DMG | `bonus_value × DMG_SINGLE × 0.7` |
| 17 | REVIVE | `REVIVE_BASE + 보너스(value≥100: +0.4 / ≥50: +0.2)` |
| 18 | SACRIFICE_HP | `value × SACR_PER_10 / 10` |
| 19 | COST_ZERO_TURN | `COST_ZERO_V` |
| 20 | BLOCK_PER_CARDS_PLAYED | `AVG_CARDS_PLAYED × value × BLOCK_SELF` |
| 21 | ON_KILL_DRAW | SKIP (복합) |
| 22 | PURGE_STATUS | `0.5` |
| 23 | PER_DRAW_DMG | `AVG_DRAW × value × DMG_SINGLE` |
| 24 | DAMAGE_PER_BLOCK | `AVG_BLOCK × value / 100 × DMG_SINGLE` |
| 25 | DAMAGE_PER_DEAD_ALLY | `AVG_DEAD × value × DMG_SINGLE` |
| 26 | DOUBLE_NEXT_DAMAGE | SKIP (복합) |
| 27 | DISCARD_PICK_DRAW | `value × DRAW_V + ENERGY_V` |
| 28 | MORALE_TO_BLOCK | `AVG_MORALE × value × BLOCK_SELF` |
| 29 | DAMAGE_PER_HAND_SIZE | `AVG_HAND × value × DMG_SINGLE` |
| 30 | DAMAGE_PER_TOKEN | `AVG_TOKEN_PAYOFF × value × (DMG_ALL\|DMG_SINGLE)` |
| 31 | HEAL_PER_DEAD_ALLY | `AVG_DEAD × value × HEAL_SELF` |
| 32 | ENERGY_TO_DAMAGE | `AVG_ENERGY × value × DMG_SINGLE - AVG_ENERGY × ENERGY_V` |
| 33 | STATUS_DOUBLE | SKIP (복합) |
| 34 | SACRIFICE_PAYOFF | SKIP (복합) |
| 35 | CHARM_TO_DAMAGE | `AVG_CHARM_AT_PAYOFF × bonus_value × (DMG_ALL\|DMG_SINGLE)` |
| 36 | MULTI_HIT_RANDOM | SKIP (복합) |
| 37 | DAMAGE_PER_STATUS_TYPE | SKIP (복합) |
| 38 | DRAW_PER_ENTHRALL | SKIP (반함 발동 확률 산정 불가) |
| 39 | DAMAGE_PER_CHARMED_ENEMY | SKIP (매혹 적 수 런타임 의존) |
| 40 | BUFF_SPEED | `value × bonus_value × SPEED_PER_TURN_V × (ALL_ALLIES/ALLY/SELF 배수)` |
| 41 | DEBUFF_SPEED | `value × bonus_value × SPEED_PER_TURN_V × (ALL/SINGLE 배수)` |

APPLY_STATUS 상태별:

| status_type | 공식 |
|---|---|
| weak | `value × (WEAK_ALL_V 또는 WEAK_SGL)` |
| vulnerable | `value × (WEAK_ALL_V 또는 WEAK_SGL)` |
| poison | `value × (POISON_ALL_V 또는 POISON_SGL)` |
| charm | `value × (CHARM_ALL 또는 CHARM_SGL)` |
| strength | `value × STRENGTH_V` |
| morale | `value × MORALE_V` |
| taunt | `value × TAUNT_V` |
| power.* | SKIP (지속 효과) |
| power.on_enthrall_strength | SKIP (Quest형 영구 누적) |
| power.speed_buff | `value × SPEED_POWER_V` (전투 끝까지) |

---

## 5. 업그레이드 시스템

### 희귀도별 업그레이드 배율 (UPGRADE_RATE)

| 희귀도 | 배율 | 의미 |
|---|---|---|
| COMMON | 0.00 | 업그레이드 없음 |
| UNCOMMON | 0.10 | 기본 raw_cp의 10%씩 레벨업 |
| RARE | 0.12 | 기본 raw_cp의 12%씩 레벨업 |
| LEGENDARY | 0.14 | 기본 raw_cp의 14%씩 레벨업 |
| DIVINE | 0.16 | 기본 raw_cp의 16%씩 레벨업 |

### 업그레이드 공식

```
raw_cp_up = raw_cp × (1 + UPGRADE_RATE × level)
adj_up    = raw_cp_up / RARITY_MULT[rarity]
OK: |adj_up - adj_cp| ≥ UPGRADE_CP_STEP (0.15) — 강화가 의미 있음
허용 오차: |adj_up - cost_up| ≤ TOLERANCE_UP (0.30)
```

- `UPGRADE_CP_STEP = 0.15` — 레벨당 adj_cp 차이가 0.15 미만이면 해당 레벨 SKIP (스케일링 없는 효과에서 발생)
- `TOLERANCE_UP = 0.30` — 업그레이드 카드는 기본보다 허용 범위 +0.10 넓게 적용

### 예시: 나일의 속삭임 (CHARM 25 ALL, 1코 UNCOMMON)

| 레벨 | CHARM | raw_cp | adj_up | delta | 통과 |
|---|---|---|---|---|---|
| 0 | 25 | 1.125 | 1.023 | +0.023 | ✓ |
| 1 | +25×0.10 → 2.5 → 27.5 | 1.238 | 1.125 | +0.125 | ✓ |
| 2 | 30 | 1.350 | 1.227 | +0.227 | ✓ (TOLERANCE_UP) |

---

## 6. 기준값 (평균값 상수)

| 상수 | 값 | 의미 |
|---|---|---|
| AVG_HAND | 4.0 | 평균 패 장수 |
| AVG_DEAD | 0.5 | 평균 사망 아군 수 |
| AVG_BLOCK | 80.0 | 평균 방어도 |
| AVG_TOKEN | 2.0 | SUMMON_TOKEN 기준 평균 토큰 수 |
| AVG_TOKEN_PAYOFF | 3.0 | DAMAGE_PER_TOKEN 사용 시점 평균 토큰 수 (빌드업 후) |
| AVG_CARDS_PLAYED | 4 | BLOCK_PER_CARDS_PLAYED 사용 시점 평균 카드 수 |
| AVG_TEAM | 2 | FORMATION_BLOCK 기준 살아있는 영웅 수 (보수치) |
| AVG_CHARM_AT_PAYOFF | 50 | CHARM_TO_DAMAGE 사용 시점 평균 누적 스택 (임계 100 절반) |
| AVG_DRAW | 5.0 | 평균 드로우 수 |
| AVG_MORALE | 3.0 | 평균 사기 스택 |
| AVG_ENERGY | 2.0 | 평균 에너지 |
| AVG_CHARMED | 1.5 | 평균 매혹된 적 수 (매혹 빌드 기준) |

---

## 6. 매혹 시스템 (2026-05-04 개정)

### 임계치
- **NORMAL 적**: 100 스택 → 반함(enthrall) 발동
- **저항 적** (charm_resistance=20): 120 스택 → 반함
- `power.charm_threshold_minus value=20`: 임계치 -20 (NORMAL: 80, 저항: 100)
- `power.charm_double_apply value=1`: 부여 스택 ×2

### CHARM CP 산정 근거
임계치 100 기준:
- 반함 1회 ≈ 3.0 CP (적 공격 무효화 + 다른 적 공격)
- 스택당 기대 CP = 3.0 / 100 = 0.030 (단일)
- AOE는 ×1.5 = 0.045

### 클레오파트라 조종 카드 밸런스 (Phase 4 기준)

| 카드 | 주요 효과 | 비용 | 희귀도 | adj_cp | Δ | 비고 |
|---|---|---|---|---|---|---|
| 유혹 | CHARM 30 SINGLE | 1 | U | 0.818 | −0.182 ✓ | 베이스라인 단일 |
| 나일의 속삭임 | CHARM 25 ALL | 1 | U | 1.023 | +0.023 ✓ | 베이스라인 광역 |
| 클레오파트라의 입맞춤 | CHARM 60 SINGLE + DRAW_PER_ENTHRALL 2 | 2 | D | — | SKIP | 입맞춤=반함 즉발 드로우 |
| 여왕의 위엄 | power.charm_threshold_minus=20 | 1 | R | — | SKIP (POWER) | 임계치 100→80 |
| 매혹의 향기 | power.charm_double_apply=1 | 2 | R | — | SKIP (POWER) | 부여 ×2 |
| 매혹의 처형 | CHARM_TO_DAMAGE bonus=2 | 2 | R | — | SKIP | 100스택=200dmg |
| 뱀의 의식 | power.on_enthrall_strength=1 (EXHAUST) | 2 | L | — | SKIP | Quest형 영구 strength |
| 황금 왕좌 | DMG 20 ALL + PER_CHARMED 20 (EXHAUST) | 2 | L | — | SKIP | 스케일 페이오프 |
