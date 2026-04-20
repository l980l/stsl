# 이순신 카드 기획 v1

## 영웅 정체성

이순신은 **방어도를 자원으로 쓰는 반격형 탱커**다.
방어도를 쌓아 피해를 버티면서, 쌓인 방어도를 소비해 강력한 반격 피해를 낸다.
팀 전체 방어/버프 지원도 겸한다.

### 3대 아키타입

| 아키타입 | 핵심 메카닉 | 키워드 |
|---|---|---|
| **거북선** | 방어도 축적 → COUNTER_BLOCK 반격 | BLOCK, COUNTER_BLOCK |
| **학익진** | 팀 전체 방어도/버프 지원 | BLOCK_ALL, FORMATION_BLOCK, BLOCK_ALL |
| **필사즉생** | 저HP 조건부 강화, 팀 회복 | CONDITIONAL_DMG, HEAL_ALL, HEAL |

---

## 시작덱 (4장 고정)

| 이름 | 등급 | 코스트 | 카드타입 | 효과 |
|---|---|---|---|---|
| 방패 | COMMON | 1 | SKILL | BLOCK 80 (자신) |
| 방패 | COMMON | 1 | SKILL | BLOCK 80 (자신) |
| 역공 | COMMON | 1 | ATTACK | BLOCK 30 + DAMAGE 30 (단일) |
| 역공 | COMMON | 1 | ATTACK | BLOCK 30 + DAMAGE 30 (단일) |

> 시작덱 카드는 COMMON — 강화 불가, 수치 고정.
> HP 1000 기준 스타터 공격 100이 기준이나, 시작덱은 방어+반격 분할이므로 절반씩 배분.

---

## 전체 카드 15장

### 수치 강화 계산 규칙
- UNCOMMON 1강: 베이스 × 1.10 (반올림)
- RARE 1강: 베이스 × 1.12 (반올림)
- LEGENDARY 1강: 베이스 × 1.14 / 2강: 베이스 × 1.28 (반올림)
- DIVINE 1강: 베이스 × 1.16 / 2강: 베이스 × 1.32 (반올림) + 단계별 유니크 효과
- 정수 효과(DRAW, ENERGY, 상태이상 스택/지속): 1강당 +1

---

| # | 이름 | 등급 | 코스트 | 카드타입 | 아키타입 | 0강 효과 | 1강 효과 | 2강 효과 | 메모 |
|---|---|---|---|---|---|---|---|---|---|
| 1 | 거북선 돌격 | UNCOMMON | 2 | ATTACK | 거북선 | DAMAGE 120 + COUNTER_BLOCK 60% | DAMAGE 132 + COUNTER_BLOCK 60% | — | 방어도가 높을수록 반격 강해짐 |
| 2 | 반격 | UNCOMMON | 1 | ATTACK | 거북선 | COUNTER_BLOCK 100% | COUNTER_BLOCK 100% + BLOCK 30 | — | 방어도 전량 반격. 1강은 소블록 추가 |
| 3 | 철갑 | RARE | 2 | SKILL | 거북선 | BLOCK 150 | BLOCK 168 | — | 순수 대형 방어도 카드 |
| 4 | 거북선 방패 | COMMON | 1 | SKILL | 거북선 | BLOCK 80 | — | — | 강화 불가. 저코 안정 방어 |
| 5 | 학익진 | RARE | 2 | SKILL | 학익진 | BLOCK_ALL 80 | BLOCK_ALL 90 | — | 팀 전체 방어도 핵심 |
| 6 | 진형 강화 | UNCOMMON | 1 | SKILL | 학익진 | FORMATION_BLOCK 40 | FORMATION_BLOCK 44 | — | 생존 영웅 수 × 40 BLOCK |
| 7 | 수군 훈련 | UNCOMMON | 1 | SKILL | 학익진 | BLOCK 50 + DRAW 1 | BLOCK 55 + DRAW 2 | — | 드로우 겸 소방어 |
| 8 | 한산대첩 | LEGENDARY | 3 | ATTACK | 학익진 | DAMAGE 100 (전체) + BLOCK_ALL 80 | DAMAGE 114 (전체) + BLOCK_ALL 91 | DAMAGE 128 (전체) + BLOCK_ALL 102 | 공격+팀방어 동시, 코스트 무거움 |
| 9 | 엄정한 훈련 | RARE | 1 | SKILL | 학익진 | DRAW 2 + BLOCK 40 | DRAW 3 + BLOCK 45 | — | 패 보충 + 소방어 |
| 10 | 배수진 | RARE | 1 | SKILL | 필사즉생 | HEAL -80 (자신) + BLOCK 180 | HEAL -80 + BLOCK 202 | — | HP 깎아 대형 방어도. 저HP 빌드와 시너지 |
| 11 | 필사즉생 | LEGENDARY | 1 | ATTACK | 필사즉생 | CONDITIONAL_DMG: HP≤50% → 200, 아니면 100 | CONDITIONAL_DMG: HP≤50% → 228, 아니면 114 | CONDITIONAL_DMG: HP≤50% → 256, 아니면 128 | 저HP 조건부 2배 피해 |
| 12 | 불굴 | UNCOMMON | 2 | SKILL | 필사즉생 | HEAL_ALL 100 | HEAL_ALL 110 | — | 팀 전체 회복, 후반 지속력 |
| 13 | 해군 기동 | COMMON | 0 | SKILL | 거북선 | BLOCK 30 | — | — | 0코스트 소방어. 강화 불가 |
| 14 | 노량 해전 | DIVINE | 3 | ATTACK | 거북선 | DAMAGE 250 (단일) | DAMAGE 290 + 이번 전투 COUNTER_BLOCK 비율 +20% | DAMAGE 330 + 이번 전투 COUNTER_BLOCK 비율 +20% + 공격 후 BLOCK 120 | 이순신의 마지막 필살기 |
| 15 | 학익진 완성 | DIVINE | 2 | SKILL | 학익진 | BLOCK_ALL 100 + 아군 전체 strength +1 | BLOCK_ALL 116 + strength +1 + DRAW 1 | BLOCK_ALL 132 + strength +2 + DRAW 1 + 이번 턴 에너지 회복 1 | 진화형 팀 버프 |

---

## 신(Divine) 등급 카드 상세

### 14번 — 노량 해전

이순신이 마지막 전투에서 전사한 역사적 사실을 반영.
**0강**: 단순 대형 단일 피해 (250). 강력하지만 평범함.
**1강**: 거북선 빌드에 연동되는 보조 효과 추가. 이번 전투 동안 모든 COUNTER_BLOCK 비율이 20%p 상승. (60%→80%, 100%→120%)
**2강**: 전투 내 COUNTER_BLOCK 보너스 유지 + 공격 직후 자신에게 BLOCK 120 부여. "쏘고 막는다"의 집약.

> 구현 메모: 1강/2강의 COUNTER_BLOCK 비율 보너스는 전투 내 영구 버프 플래그로 처리 권장.

### 15번 — 학익진 완성

학익진 빌드의 정점 카드. 팀 지원에 특화.
**0강**: BLOCK_ALL 100 + 모든 아군에게 strength +1 (이번 전투 공격력 +1).
**1강**: BLOCK_ALL 116 + strength +1 + DRAW 1 추가. 더 공격적.
**2강**: BLOCK_ALL 132 + strength +2 + DRAW 1 + 에너지 1 회복. 한 장으로 팀 버프 + 후속 액션 제공.

> 구현 메모: `strength` 상태이상은 APPLY_STATUS로 처리. EffectResource에 `status_type = "strength"` 추가 필요.

---

## 아키타입 분포 체크

| 아키타입 | 카드 수 | 해당 카드 |
|---|---|---|
| 거북선 | 6장 | 거북선 돌격, 반격, 철갑, 거북선 방패, 해군 기동, 노량 해전 |
| 학익진 | 6장 | 학익진, 진형 강화, 수군 훈련, 한산대첩, 엄정한 훈련, 학익진 완성 |
| 필사즉생 | 3장 | 배수진, 필사즉생, 불굴 |

> 필사즉생은 거북선(배수진 → HP 깎기)과 복합 시너지를 형성하도록 설계.

### 등급 분포

| 등급 | 수 | 카드 |
|---|---|---|
| COMMON | 3장 | 거북선 방패, 해군 기동, (시작덱 방패/역공 별도) |
| UNCOMMON | 4장 | 거북선 돌격, 반격, 진형 강화, 수군 훈련, 불굴 |
| RARE | 4장 | 철갑, 학익진, 배수진, 엄정한 훈련 |
| LEGENDARY | 2장 | 한산대첩, 필사즉생 |
| DIVINE | 2장 | 노량 해전, 학익진 완성 |

---

## 크로스 시너지 연동

| 시너지 | 이순신 측 카드 | 효과 |
|---|---|---|
| 나폴레옹 × 이순신 | 철갑, 학익진, 거북선 방패 | GAIN_MORALE 발동 시 이순신 BLOCK +추가 |
| 클레오파트라 × 이순신 | 거북선 돌격, 반격, 노량 해전 | 독 상태 적 공격 시 COUNTER_BLOCK 피해에 추가 독 피해 |

---

## 밸런스 메모

- **COUNTER_BLOCK 상한**: 방어도가 극단적으로 쌓이면 반격이 과도해질 수 있음. 1000 이상 방어도에서 COUNTER_BLOCK 100% 카드가 단일 1000+ 피해 → 보스에게도 너무 강할 수 있음. 실제 구현 시 상한캡 검토.
- **배수진 밸런스**: HP -80 자해로 필사즉생 조건(HP≤50%) 빠르게 달성 가능 → 의도된 시너지이나 너무 결정적이면 다른 카드가 밀릴 수 있음.
- **0코스트 해군 기동**: 매 턴 안정적인 BLOCK 30이 사소하게 강함. 덱 압박 없이 넣어도 무방하므로 COMMON 고정. 차후 "이번 턴에 한해 1장" 제한 고려.
- **DIVINE 카드 획득 빈도**: 풀에서 낮은 확률로만 나와야 함. 노량 해전 2강은 사실상 풀 빌드 조건.
