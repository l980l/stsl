# 일본 신화 적 디자인

## 시스템 정보

- **챕터**: 2 (Chapter 2 풀: 한국 / 일본 / 중국)
- **Act 배정**: 챕터 진입 시 3신화를 셔플 → Act 1/2/3에 1:1 무작위 배정. 한 액트는 1신화로만 진행
- **Act 난이도 배율**: HP × {Act1: 1.0 / Act2: 1.3 / Act3: 1.6}, ATK × {Act1: 1.0 / Act2: 1.2 / Act3: 1.4}
- **코드 위치**: `resources/enemies/japanese/japanese_{normals,act1,act2,act3}.gd`
- **구현 출처**: `autoload/game_manager.gd:555-664`

---

## 테마 시그니처

**주 테마 — "요괴와 신들의 혼돈"**
일본 민간 신앙의 다양한 요괴·신화 존재들. 속성(번개·얼음·저주)이 가장 다양하여 고정 저항 빌드로 완전 대응이 어려움.

**부 테마 — "근력 폭발 + 다속성 광역"**
라이덴·야마타노오로치 등 보스가 점층적 근력 증가 + 광역 딜 구조. 슈텐도지는 전체 약화+전체 강타 조합으로 버프 해소를 강제.

**차별 포인트 (한국·중국 대비)**: 한국은 LOWEST_HP 처형 + 독 중심, 중국은 신성(divine) + 근력 누적 중심. 일본은 번개·얼음·저주·독·화염 등 속성 분산으로 특정 저항 덱의 범용성을 떨어뜨림. Act 3 야마타노오로치는 독+화염 동시 사용으로 복합 대응 요구.

---

## 일반 적 풀 (모든 Act 공통)

> Act 난이도 배율 적용 기준값 = Act 1 (코드 원본 값)

---

### 1. 오니 (oni)

- **enemy_name**: `enemy.japanese.oni` / **HP**: 420
- **인텐트 시퀀스** (3턴 순환):
  ① ATK 90 [RANDOM] (blunt) → ② BUFF 근력 1 → ③ ATK 110 [RANDOM] (blunt)
- **핵심 메카닉**: 공격→근력 적립→강화 공격. 매 사이클마다 근력이 누적됨.
- **시너지**: 2마리 조합(encounters #2, #4, #10)에서 근력 누적 속도가 2배.
- **밸런스 메모**: HP 420으로 일반 적 중 중간. 방치 시 근력 폭발.

---

### 2. 텐구 (tengu)

- **enemy_name**: `enemy.japanese.tengu` / **HP**: 320
- **인텐트 시퀀스** (4턴 순환):
  ① DEBUFF 약화 1 [RANDOM] → ② ATK 80 [RANDOM] (slash) → ③ ATK 70 [RANDOM] (slash) → ④ DEBUFF 취약 1 [RANDOM]
- **핵심 메카닉**: 약화→2타→취약 순환. 디버프로 영웅을 약화시키면서 공격.
- **시너지**: 2마리 조합(encounters #3, #4, #6)에서 약화+취약을 동시에 2중으로 부여 가능.
- **밸런스 메모**: HP 320으로 낮아 처리가 쉬우나, 2마리 시 디버프 누적이 빠름.

---

### 3. 유키온나 (yuki_onna)

- **enemy_name**: `enemy.japanese.yuki_onna` / **HP**: 300
- **인텐트 시퀀스** (3턴 순환):
  ① DEBUFF 약화 2 [ALL] → ② ATK 70 [LOWEST_HP] (ice) → ③ DEBUFF 취약 1 [RANDOM]
- **핵심 메카닉**: 전체 약화 2 후 LOWEST_HP 집중 얼음 공격. 취약도 추가로 부여.
- **시너지**: 약화 상태에서 다른 적 공격이 강화됨. 텐구와 조합(encounters #6) 시 3~4 디버프 누적.
- **밸런스 메모**: HP 300으로 가장 낮아 빠른 제거 가능. 단 전체 약화는 즉시 발동.

---

### 4. 갓파 (kappa)

- **enemy_name**: `enemy.japanese.kappa` / **HP**: 380
- **인텐트 시퀀스** (4턴 순환):
  ① BUFF 방어 30 → ② ATK 80 [RANDOM] (blunt) → ③ ATK 90 [RANDOM] (blunt) → ④ DEBUFF 약화 1 [ALL]
- **핵심 메카닉**: 방어 30 선행 후 2타, 마지막 전체 약화. 자기 방어를 갖추고 꾸준히 딜.
- **시너지**: 2마리 조합(encounters #7, #10)에서 방어 60 + 약화 누적.
- **밸런스 메모**: 약화가 턴마다 전체 부여되어 장기전에서 영웅 공격 효율 저하.

---

### 5. 슈텐의 부하 (shuten_minion)

- **enemy_name**: `enemy.japanese.shuten_minion` / **HP**: 350
- **인텐트 시퀀스** (4턴 순환):
  ① ATK 70 [RANDOM] (blunt) → ② ATK 70 [RANDOM] (blunt) → ③ BUFF 근력 1 → ④ ATK 100 [RANDOM] (blunt)
- **핵심 메카닉**: 2타 선행 후 근력 쌓고 강타. 총 3타 공격으로 블록 분산.
- **시너지**: 2마리 조합(encounters #8, #11)에서 6타+근력 축적 압박.
- **밸런스 메모**: 70+70+100 = 총 240 딜(근력 보정 전). 블록 분산이 핵심 위협.

---

### 6. 로닌 유령 (ronin_ghost)

- **enemy_name**: `enemy.japanese.ronin_ghost` / **HP**: 450
- **인텐트 시퀀스** (3턴 순환):
  ① BUFF 근력 2 → ② ATK 130 [LOWEST_HP] (slash) → ③ ATK 100 [RANDOM] (slash)
- **핵심 메카닉**: 근력 2 선행 후 LOWEST_HP+RANDOM 2타. 일반 적 중 고HP+고근력.
- **시너지**: 슈텐 부하와 조합(encounters #11)은 근력 3+ + 총 4타 구성.
- **밸런스 메모**: HP 450 + 근력 2 = 실질적 위협. 단독(encounters #9)도 부담스러운 적.

---

### 인카운터 풀 (encounters() 반환값)

| # | 조합 | 적 수 | 합산 HP (Act 1 기준) |
|---|---|---|---|
| 1 | oni | 1 | 420 |
| 2 | oni × 2 | 2 | 840 |
| 3 | tengu × 2 | 2 | 640 |
| 4 | oni + tengu | 2 | 740 |
| 5 | yuki_onna | 1 | 300 |
| 6 | yuki_onna + tengu | 2 | 620 |
| 7 | kappa × 2 | 2 | 760 |
| 8 | shuten_minion × 2 | 2 | 700 |
| 9 | ronin_ghost | 1 | 450 |
| 10 | kappa + oni | 2 | 800 |
| 11 | shuten_minion + ronin_ghost | 2 | 800 |

---

## Act 1 — 엘리트 + 보스

> 엘리트는 3종 중 1마리 랜덤 선택. HP 수치는 코드 원본값 (Act 1 배율 ×1.0).

### 엘리트 풀 (3종)

#### 1. 오니 장군 (ushi_oni)

- **enemy_name**: `enemy.japanese.ushi_oni` / **HP**: 1,600 / **charm_resistance**: 20
- **인텐트 시퀀스** (4턴 순환):
  ① BUFF 근력 2 → ② ATK 150 [LOWEST_HP] (blunt) → ③ ATK 130 [RANDOM] (blunt) → ④ DEBUFF 취약 2 [RANDOM]
- **핵심 메카닉**: 근력 2 선행 후 LOWEST_HP+RANDOM 2타, 취약 부여로 다음 사이클 강화.
- **밸런스 메모**: 근력 2 보정 시 실질 150→180/130→156. 취약까지 중첩 시 추가 25% 상승.

---

#### 2. 야마우바 (yamamba)

- **enemy_name**: `enemy.japanese.yamamba` / **HP**: 1,700 / **charm_resistance**: 20
- **인텐트 시퀀스** (4턴 순환):
  ① DEBUFF 약화 2 [ALL] → ② ATK 140 [RANDOM] (curse) → ③ DEBUFF 취약 2 [RANDOM] → ④ ATK 160 [LOWEST_HP] (curse)
- **핵심 메카닉**: 전체 약화→저주 공격→취약→LOWEST_HP 처형. 약화+취약 이중 디버프.
- **밸런스 메모**: 저주 데미지는 방어 관통 가능. 약화 상태의 영웅이 반격 약화됨.

---

#### 3. 무적 로닌 (invincible_ronin)

- **enemy_name**: `enemy.japanese.invincible_ronin` / **HP**: 1,800 / **charm_resistance**: 20
- **인텐트 시퀀스** (4턴 순환):
  ① BUFF 근력 3 → ② ATK 170 [LOWEST_HP] (slash) → ③ ATK 150 [RANDOM] (slash) → ④ BUFF 근력 1
- **핵심 메카닉**: 근력 3 선행 후 2타, 근력 1 추가 적립. 매 사이클마다 근력 4 누적.
- **밸런스 메모**: Act 1 엘리트 중 최고 HP(1,800). 근력 누적 방치 시 170→220+ 처형.

---

### 보스 — 라이덴 (raijin)

- **enemy_name**: `enemy.japanese.raijin` / **HP**: 4,500 / **grade**: BOSS / **charm_resistance**: 20
- **페이즈 전환**: HP >66% → Phase 0 / 33~66% → Phase 1 / <33% → Phase 2
- **damage_type**: lightning

**Phase 0 — 뇌고 (HP >66%)**
① ATK 150 [RANDOM] → ② BUFF 근력 1 → ③ ATK 130 [ALL] → ④ DEBUFF 취약 2 [RANDOM]

**Phase 1 — 번개 강림 (HP 33~66%)**
① ATK 190 [RANDOM] → ② DEBUFF 약화 2 [ALL] → ③ ATK 160 [ALL] → ④ BUFF 근력 2

**Phase 2 — 폭풍 해방 (HP <33%)**
① ATK 220 [LOWEST_HP] → ② DEBUFF 취약 3 [ALL] → ③ ATK 190 [ALL] → ④ BUFF 근력 3

**메카닉 포인트**: 페이즈마다 근력이 1→2→3으로 누적 증가. Phase 2 취약 3 전체 부여 후 190 광역은 막대한 파티 피해.

---

## Act 2 — 엘리트 + 보스

> Act 2 HP 배율 ×1.3, ATK 배율 ×1.2 (HP 수치는 코드 원본 기준)

### 엘리트 풀 (3종)

#### 1. 혼돈의 텐구 (chaos_tengu)

- **enemy_name**: `enemy.japanese.chaos_tengu` / **HP**: 1,800 / **charm_resistance**: 20
- **인텐트 시퀀스** (3턴 순환):
  ① DEBUFF 약화 2 [ALL] → ② ATK 150 [RANDOM] (slash) → ③ DEBUFF 취약 2 [RANDOM]
- **핵심 메카닉**: 전체 약화→공격→취약 순환. 3턴 사이클이 짧아 디버프가 빠르게 누적.
- **밸런스 메모**: 3턴마다 약화 2+취약 2. Act 2 배율로 실질 공격 180+.

---

#### 2. 야샤 (yasha)

- **enemy_name**: `enemy.japanese.yasha` / **HP**: 1,900 / **charm_resistance**: 20
- **인텐트 시퀀스** (4턴 순환):
  ① BUFF 근력 2 → ② ATK 170 [LOWEST_HP] (slash) → ③ ATK 150 [RANDOM] (slash) → ④ BUFF 근력 1
- **핵심 메카닉**: 무적 로닌과 유사한 근력 누적 패턴. LOWEST_HP 타겟 선공으로 처형 위협.
- **밸런스 메모**: 매 사이클 근력 3 누적. 방치 시 170→230+ LOWEST_HP 처형.

---

#### 3. 누레리온 (nureriyon)

- **enemy_name**: `enemy.japanese.nureriyon` / **HP**: 1,700 / **charm_resistance**: 20
- **인텐트 시퀀스** (5턴 순환):
  ① ATK 120 [RANDOM] (curse) → ② DEBUFF 약화 2 [RANDOM] → ③ ATK 130 [RANDOM] (curse) → ④ DEBUFF 취약 2 [RANDOM] → ⑤ ATK 150 [LOWEST_HP] (curse)
- **핵심 메카닉**: 저주 3타 + 약화+취약 순차 부여. 마지막 150이 LOWEST_HP 타겟.
- **밸런스 메모**: 저주 총 딜 400(Act 2 배율 전). 약화+취약 중첩 시 더욱 위협적.

---

### 보스 — 슈텐도지 (shuten_doji)

- **enemy_name**: `enemy.japanese.shuten_doji` / **HP**: 4,800 / **grade**: BOSS / **charm_resistance**: 20
- **페이즈 전환**: HP >66% → Phase 0 / 33~66% → Phase 1 / <33% → Phase 2
- **damage_type**: blunt

**Phase 0 — 술판 (HP >66%)**
① BUFF 근력 1 → ② ATK 160 [RANDOM] → ③ DEBUFF 약화 2 [ALL] → ④ ATK 140 [ALL]

**Phase 1 — 광란 (HP 33~66%)**
① ATK 200 [LOWEST_HP] → ② DEBUFF 취약 2 [ALL] → ③ ATK 170 [ALL] → ④ BUFF 근력 2 → ⑤ ATK 180 [RANDOM]

**Phase 2 — 주귀 해방 (HP <33%)**
① ATK 180 [RANDOM] → ② ATK 180 [RANDOM] → ③ DEBUFF 약화 3 [ALL] → ④ ATK 210 [ALL] → ⑤ BUFF 근력 3

**메카닉 포인트**: Phase 1부터 5액션으로 증가. Phase 2 약화 3 전체 후 210 전체 광타가 파티 대미지 클라이맥스.

---

## Act 3 — 엘리트 + 보스

> Act 3 HP 배율 ×1.6, ATK 배율 ×1.4 (HP 수치는 코드 원본 기준)

### 엘리트 풀 (3종)

#### 1. 아마노이와토 수문장 (iwato_guardian)

- **enemy_name**: `enemy.japanese.iwato_guardian` / **HP**: 1,900 / **charm_resistance**: 20
- **인텐트 시퀀스** (4턴 순환):
  ① BUFF 방어 70 → ② ATK 170 [RANDOM] (divine) → ③ BUFF 방어 50 → ④ ATK 190 [LOWEST_HP] (divine)
- **핵심 메카닉**: 방어 120을 2번에 나눠 쌓고 신성 2타. LOWEST_HP 타겟 최종 타.
- **밸런스 메모**: 방어 120 실드를 갖추면 내구도가 매우 높음. 관통 카드나 약화 필수.

---

#### 2. 스사노오의 검 (susanoo_blade)

- **enemy_name**: `enemy.japanese.susanoo_blade` / **HP**: 2,000 / **charm_resistance**: 20
- **인텐트 시퀀스** (4턴 순환):
  ① BUFF 근력 3 → ② ATK 190 [LOWEST_HP] (lightning) → ③ ATK 170 [RANDOM] (lightning) → ④ DEBUFF 취약 2 [ALL]
- **핵심 메카닉**: 근력 3 선행 후 번개 2타, 전체 취약으로 다음 사이클 강화.
- **밸런스 메모**: Act 3 엘리트 중 최고 HP(2,000). 근력 3 보정 시 190→247 LOWEST_HP 처형 위협.

---

#### 3. 눈보라 여왕 (jorogumo)

- **enemy_name**: `enemy.japanese.jorogumo` / **HP**: 1,800 / **charm_resistance**: 20
- **인텐트 시퀀스** (5턴 순환):
  ① DEBUFF 약화 3 [ALL] → ② ATK 160 [LOWEST_HP] (ice) → ③ DEBUFF 취약 2 [ALL] → ④ ATK 180 [RANDOM] (ice) → ⑤ BUFF 근력 2
- **핵심 메카닉**: 전체 약화 3→LOWEST_HP 얼음→전체 취약 2→RANDOM 얼음→근력 2. 디버프 최대치 누적 후 공격.
- **밸런스 메모**: 약화 3+취약 2 이중 전체 부여가 핵심 위협. 빠른 처치 필수.

---

### 보스 — 야마타노오로치 (yamata_no_orochi)

- **enemy_name**: `enemy.japanese.yamata_no_orochi` / **HP**: 4,800 / **grade**: BOSS / **charm_resistance**: 20
- **페이즈 전환**: HP >66% → Phase 0 / 33~66% → Phase 1 / <33% → Phase 2
- **damage_type**: poison + fire

**Phase 0 — 여덟 머리 (HP >66%)**
① ATK 150 [RANDOM] (poison) → ② ATK 150 [RANDOM] (poison) → ③ DEBUFF 약화 2 [ALL] → ④ ATK 140 [ALL] (fire) → ⑤ BUFF 근력 1

**Phase 1 — 다섯 머리 (HP 33~66%)**
① ATK 190 [RANDOM] (poison) → ② ATK 190 [RANDOM] (poison) → ③ DEBUFF 취약 2 [ALL] → ④ ATK 180 [ALL] (fire) → ⑤ BUFF 근력 2

**Phase 2 — 두 머리 (HP <33%)**
① ATK 230 [LOWEST_HP] (poison) → ② ATK 230 [RANDOM] (poison) → ③ DEBUFF 취약 3 [ALL] → ④ ATK 220 [ALL] (fire) → ⑤ BUFF 근력 3

**메카닉 포인트**: 독(poison) 2타 + 화염(fire) 광역의 복합 속성 구조. 페이즈마다 공격력과 근력이 단계적으로 상승. Phase 2 취약 3 전체 후 220 화염 광역은 전 영웅 치명 위협.

---

## 영웅 빌드 시너지

| 일본 위협 | 약점 빌드 | 권장 대응 |
|---|---|---|
| 근력 폭발 (oni, invincible_ronin, susanoo_blade) | 빠른 처치 불가 덱 | 근력 제거 or 선제 차단 |
| 다속성 공격 (독+화염, 번개+얼음) | 단일 속성 저항 덱 | 복합 저항 or 블록 중심 |
| 전체 약화 (yuki_onna, chaos_tengu, jorogumo) | 공격 위주 덱 | 약화 해제 / 방어 우선 전환 |
| LOWEST_HP 처형 (yamamba, ushi_oni, yasha) | 단일 영웅 선봉 덱 | HP 균등 유지 |

---

## 키 집합 검증

| 코드 키 | 구분 |
|---|---|
| `enemy.japanese.oni` | 일반 |
| `enemy.japanese.tengu` | 일반 |
| `enemy.japanese.yuki_onna` | 일반 |
| `enemy.japanese.kappa` | 일반 |
| `enemy.japanese.shuten_minion` | 일반 |
| `enemy.japanese.ronin_ghost` | 일반 |
| `enemy.japanese.ushi_oni` | Act 1 엘리트 |
| `enemy.japanese.yamamba` | Act 1 엘리트 |
| `enemy.japanese.invincible_ronin` | Act 1 엘리트 |
| `enemy.japanese.raijin` | Act 1 보스 |
| `enemy.japanese.chaos_tengu` | Act 2 엘리트 |
| `enemy.japanese.yasha` | Act 2 엘리트 |
| `enemy.japanese.nureriyon` | Act 2 엘리트 |
| `enemy.japanese.shuten_doji` | Act 2 보스 |
| `enemy.japanese.iwato_guardian` | Act 3 엘리트 |
| `enemy.japanese.susanoo_blade` | Act 3 엘리트 |
| `enemy.japanese.jorogumo` | Act 3 엘리트 |
| `enemy.japanese.yamata_no_orochi` | Act 3 보스 |
