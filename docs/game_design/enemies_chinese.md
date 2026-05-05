# 중국 신화 적 디자인

## 시스템 정보

- **챕터**: 2 (Chapter 2 풀: 한국 / 일본 / 중국)
- **Act 배정**: 챕터 진입 시 3신화를 셔플 → Act 1/2/3에 1:1 무작위 배정. 한 액트는 1신화로만 진행
- **Act 난이도 배율**: HP × {Act1: 1.0 / Act2: 1.3 / Act3: 1.6}, ATK × {Act1: 1.0 / Act2: 1.2 / Act3: 1.4}
- **코드 위치**: `resources/enemies/chinese/chinese_{normals,act1,act2,act3}.gd`
- **구현 출처**: `autoload/game_manager.gd:555-664`

---

## 테마 시그니처

**주 테마 — "신성한 권위와 근력 폭발"**
봉신연의·서유기 등 중국 신화의 신격들. 신성(divine) 데미지를 중심으로 근력 누적·방어 쌓기·취약 부여가 결합된 정통 전략형 적.

**부 테마 — "사신수·창조신의 단계적 압박"**
Act 3에서 사신수(백호·주작·현무)와 반고(창조신)가 등장. 반고는 권능(POWER) 카드를 쓸 때마다 전체 약화 2를 부여하는 카드 트리거로 특정 덱 타입을 강하게 카운터.

**차별 포인트 (한국·일본 대비)**: 한국은 저주+LOWEST_HP 처형 중심, 일본은 다속성 분산. 중국은 신성(divine) 데미지 일관성 + 누적형 근력 증폭으로 "버티다가 터지는" 구조. immortal_trainee의 3연속 근력 버프→대공격이 가장 극단적 예시.

---

## 일반 적 풀 (모든 Act 공통)

> Act 난이도 배율 적용 기준값 = Act 1 (코드 원본 값)

---

### 1. 야차 (yaksha)

- **enemy_name**: `enemy.chinese.yaksha` / **HP**: 340
- **인텐트 시퀀스** (3턴 순환):
  ① ATK 70 [RANDOM] (slash) → ② BUFF 근력 1 → ③ ATK 90 [RANDOM] (slash)
- **핵심 메카닉**: 공격→근력→강화 공격. 매 사이클 근력 1 누적.
- **시너지**: 2마리 조합(encounters #2, #4, #6, #10)에서 근력 누적 가속. 가장 자주 등장하는 적.
- **밸런스 메모**: HP 340으로 낮아 처리가 쉽지만 여러 마리 조합이 많음.

---

### 2. 나타의 병사 (nezha_soldier)

- **enemy_name**: `enemy.chinese.nezha_soldier` / **HP**: 280
- **인텐트 시퀀스** (3턴 순환):
  ① ATK 50 [RANDOM] (slash) → ② ATK 50 [RANDOM] (slash) → ③ BUFF 근력 1
- **핵심 메카닉**: 2타 선행 후 근력 적립. HP 280으로 가장 낮아 빠른 처치 가능.
- **시너지**: 2마리 조합(encounters #3, #4)에서 4타 선공 압박 + 근력 동시 적립.
- **밸런스 메모**: 단독으로는 약하지만 조합 시 초반 블록 소모 강제.

---

### 3. 천왕의 병사 (heavenly_king_soldier)

- **enemy_name**: `enemy.chinese.heavenly_king_soldier` / **HP**: 450
- **인텐트 시퀀스** (4턴 순환):
  ① BUFF 방어 50 → ② ATK 110 [RANDOM] (slash) → ③ ATK 90 [RANDOM] (slash) → ④ BUFF 방어 30
- **핵심 메카닉**: 방어 80을 2번에 나눠 쌓고 2타 공격. 높은 방어+꾸준한 딜.
- **시너지**: 야차와 조합(encounters #6, #11)에서 방어형 + 근력형 콤보.
- **밸런스 메모**: HP 450 + 방어 80 = 실질 내구도 530. 관통 카드 없으면 장기전.

---

### 4. 산해경 야수 (shanhaijing_beast)

- **enemy_name**: `enemy.chinese.shanhaijing_beast` / **HP**: 380
- **인텐트 시퀀스** (4턴 순환):
  ① DEBUFF 취약 2 [RANDOM] → ② ATK 80 [RANDOM] (slash) → ③ ATK 60 [ALL] (slash) → ④ DEBUFF 취약 1 [ALL]
- **핵심 메카닉**: 취약 2 단일 부여 후 2타, 마지막에 전체 취약 1 추가. 사이클당 최대 취약 3 부여.
- **시너지**: 2마리 조합(encounters #7, #10)에서 취약 6을 빠르게 쌓을 수 있어 위험.
- **밸런스 메모**: 취약 누적 후 중국 보스의 신성 딜이 더욱 치명적.

---

### 5. 선인 수련생 (immortal_trainee)

- **enemy_name**: `enemy.chinese.immortal_trainee` / **HP**: 300
- **인텐트 시퀀스** (4턴 순환):
  ① BUFF 근력 1 → ② BUFF 근력 1 → ③ BUFF 근력 2 → ④ ATK 120 [RANDOM] (divine)
- **핵심 메카닉**: 3턴 연속 근력 버프(총 4) 후 신성 대공격. 방치 시 공격력이 극단적으로 증폭.
- **시너지**: 2마리 조합(encounters #8, #11)에서 근력 8+ 후 120+120 신성 딜.
- **밸런스 메모**: HP 300으로 낮아 처리가 가능하지만 방치하면 근력 4 축적 후 120→200+ 신성 공격.

---

### 6. 청룡 수문장 (azure_dragon_guard)

- **enemy_name**: `enemy.chinese.azure_dragon_guard` / **HP**: 520
- **인텐트 시퀀스** (4턴 순환):
  ① BUFF 근력 1 → ② BUFF 방어 40 → ③ ATK 100 [RANDOM] (slash) → ④ ATK 120 [RANDOM] (slash)
- **핵심 메카닉**: 근력+방어 동시 선행 후 2타. 일반 적 중 최고 HP(520).
- **시너지**: 단독 인카운터(encounters #9)로 등장. 방어+근력 버프로 실질 내구도와 딜 모두 높음.
- **밸런스 메모**: HP 520 + 방어 40 = 내구도 560. 근력 보정 시 100→120/120→144.

---

### 인카운터 풀 (encounters() 반환값)

| # | 조합 | 적 수 | 합산 HP (Act 1 기준) |
|---|---|---|---|
| 1 | yaksha | 1 | 340 |
| 2 | yaksha × 2 | 2 | 680 |
| 3 | nezha_soldier × 2 | 2 | 560 |
| 4 | yaksha + nezha_soldier | 2 | 620 |
| 5 | heavenly_king_soldier | 1 | 450 |
| 6 | heavenly_king_soldier + yaksha | 2 | 790 |
| 7 | shanhaijing_beast × 2 | 2 | 760 |
| 8 | immortal_trainee × 2 | 2 | 600 |
| 9 | azure_dragon_guard | 1 | 520 |
| 10 | shanhaijing_beast + yaksha | 2 | 720 |
| 11 | immortal_trainee + heavenly_king_soldier | 2 | 750 |

---

## Act 1 — 엘리트 + 보스

> 엘리트는 3종 중 1마리 랜덤 선택. HP 수치는 코드 원본값 (Act 1 배율 ×1.0).

### 엘리트 풀 (3종)

#### 1. 금각 대왕 (golden_horn_king)

- **enemy_name**: `enemy.chinese.golden_horn_king` / **HP**: 1,600 / **charm_resistance**: 20
- **인텐트 시퀀스** (6턴 순환):
  ① BUFF 방어 40 → ② BUFF 근력 1 → ③ DEBUFF 취약 2 [ALL] → ④ ATK 160 [RANDOM] (divine) → ⑤ ATK 130 [ALL] (divine) → ⑥ DEBUFF 취약 2 [ALL]
- **핵심 메카닉**: 방어+근력 준비 → 전체 취약 → 신성 2타 → 전체 취약 재부여. 사이클마다 취약 4 누적 가능.
- **밸런스 메모**: 취약 중첩 시 신성 딜이 크게 증폭. 취약 해소 수단이 없으면 위험.

---

#### 2. 은각 대왕 (silver_horn_king)

- **enemy_name**: `enemy.chinese.silver_horn_king` / **HP**: 1,700 / **charm_resistance**: 20
- **인텐트 시퀀스** (4턴 순환):
  ① DEBUFF 약화 2 [ALL] → ② BUFF 근력 2 → ③ ATK 140 [RANDOM] (divine) → ④ ATK 170 [RANDOM] (divine)
- **핵심 메카닉**: 전체 약화 후 근력 2 적립→신성 2타. 약화 상태에서 영웅 반격 약화.
- **밸런스 메모**: 근력 2 보정 시 140→168/170→204. 약화까지 중첩되면 영웅 공격 효율도 저하.

---

#### 3. 흑풍괴 (black_wind_demon)

- **enemy_name**: `enemy.chinese.black_wind_demon` / **HP**: 1,800 / **charm_resistance**: 20
- **인텐트 시퀀스** (5턴 순환):
  ① DEBUFF 취약 2 [RANDOM] → ② ATK 120 [RANDOM] (curse) → ③ ATK 150 [ALL] (curse) → ④ BUFF 근력 2 → ⑤ DEBUFF 취약 1 [ALL]
- **핵심 메카닉**: 취약→저주 2타→근력→전체 취약. 저주 데미지 + 취약 누적 구조.
- **밸런스 메모**: Act 1 엘리트 중 최고 HP(1,800). 저주는 방어 관통 가능. 취약+저주 조합이 가장 위험.

---

### 보스 — 치우 (chiyou)

- **enemy_name**: `enemy.chinese.chiyou` / **HP**: 4,500 / **grade**: BOSS / **charm_resistance**: 20
- **페이즈 전환**: HP >66% → Phase 0 / 33~66% → Phase 1 / <33% → Phase 2
- **damage_type**: blunt

**Phase 0 — 청동 창 (HP >66%)**
① ATK 160 [RANDOM] → ② BUFF 근력 1 → ③ ATK 130 [ALL] → ④ BUFF 근력 1

**Phase 1 — 혈철 도끼 (HP 33~66%)**
① ATK 200 [RANDOM] → ② ATK 160 [ALL] → ③ DEBUFF 취약 2 [RANDOM] → ④ ATK 180 [RANDOM] → ⑤ BUFF 근력 2

**Phase 2 — 천계 혈창 (HP <33%)**
① ATK 240 [RANDOM] → ② DEBUFF 취약 3 [ALL] → ③ ATK 200 [ALL] → ④ BUFF 근력 3

**메카닉 포인트**: Phase 0에서 매 사이클 근력 2를 쌓음. Phase 2 취약 3 전체 부여 후 200 광역 + 근력 3은 치명적 피해.

---

## Act 2 — 엘리트 + 보스

> Act 2 HP 배율 ×1.3, ATK 배율 ×1.2 (HP 수치는 코드 원본 기준)

### 엘리트 풀 (3종)

#### 1. 홍해아 (red_boy)

- **enemy_name**: `enemy.chinese.red_boy` / **HP**: 1,800 / **charm_resistance**: 20
- **인텐트 시퀀스** (3턴 순환):
  ① BUFF 근력 1 → ② ATK 150 [RANDOM] (fire) → ③ ATK 170 [ALL] (fire)
- **핵심 메카닉**: 3턴 짧은 사이클로 빠르게 근력 적립 + 화염 광역 반복.
- **밸런스 메모**: 사이클이 짧아 근력 누적이 빠름. Act 2 배율로 광역 204+.

---

#### 2. 구룡 차장 (nine_dragon_general)

- **enemy_name**: `enemy.chinese.nine_dragon_general` / **HP**: 1,900 / **charm_resistance**: 20
- **인텐트 시퀀스** (5턴 순환):
  ① BUFF 근력 2 → ② BUFF 방어 30 → ③ ATK 160 [RANDOM] (divine) → ④ BUFF 근력 2 → ⑤ ATK 220 [RANDOM] (divine)
- **핵심 메카닉**: 근력 2+방어 30 후 공격, 다시 근력 2 적립 후 220 강타. 매 사이클 근력 4 누적.
- **밸런스 메모**: 근력 4 보정 시 220→308. 방어 30 방패도 갖추어 내구도까지 높음.

---

#### 3. 천구 형제 (heavenly_hound_brothers)

- **enemy_name**: `enemy.chinese.heavenly_hound_brothers` / **HP**: 1,700 / **charm_resistance**: 20
- **인텐트 시퀀스** (6턴 순환):
  ① ATK 130 [RANDOM] (slash) → ② ATK 130 [RANDOM] (slash) → ③ DEBUFF 취약 2 [RANDOM] → ④ DEBUFF 취약 1 [RANDOM] → ⑤ ATK 160 [LOWEST_HP] (slash) → ⑥ DEBUFF 약화 2 [RANDOM]
- **핵심 메카닉**: 2타 선공 → 취약 3 단일 부여 → LOWEST_HP 강타 → 약화 부여. 취약+LOWEST_HP 처형 조합.
- **밸런스 메모**: 취약 3 상태의 LOWEST_HP 영웅에게 160→208(Act 2 배율 포함) 처형 위협.

---

### 보스 — 이랑신 (erlang_shen)

- **enemy_name**: `enemy.chinese.erlang_shen` / **HP**: 4,800 / **grade**: BOSS / **charm_resistance**: 20
- **페이즈 전환**: HP >66% → Phase 0 / 33~66% → Phase 1 / <33% → Phase 2
- **damage_type**: divine

**Phase 0 — 지휘 (HP >66%)**
① BUFF 근력 1 → ② BUFF 방어 40 → ③ ATK 170 [RANDOM] → ④ ATK 140 [ALL]

**Phase 1 — 삼안 개안 (HP 33~66%)**
① ATK 200 [RANDOM] → ② ATK 160 [ALL] → ③ DEBUFF 취약 2 [RANDOM] → ④ ATK 180 [LOWEST_HP] → ⑤ BUFF 근력 2

**Phase 2 — 천군 강림 (HP <33%)**
① ATK 180 [RANDOM] → ② ATK 180 [RANDOM] → ③ ATK 220 [ALL] → ④ DEBUFF 취약 2 [ALL] → ⑤ BUFF 근력 3

**메카닉 포인트**: Phase 2 전체 취약 2 부여 후 180×2+220 광역 = 총 580 딜(배율 전). Phase 1 LOWEST_HP 타겟 180은 처형 포인트.

---

## Act 3 — 엘리트 + 보스

> Act 3 HP 배율 ×1.6, ATK 배율 ×1.4 (HP 수치는 코드 원본 기준)

### 엘리트 풀 (3종)

#### 1. 백호 신장 (white_tiger_general)

- **enemy_name**: `enemy.chinese.white_tiger_general` / **HP**: 1,900 / **charm_resistance**: 20
- **인텐트 시퀀스** (4턴 순환):
  ① BUFF 근력 3 → ② ATK 180 [RANDOM] (slash) → ③ ATK 160 [RANDOM] (slash) → ④ BUFF 근력 1
- **핵심 메카닉**: 근력 3 선행 후 2타, 추가 근력 1 적립. 매 사이클 근력 4 누적.
- **밸런스 메모**: 근력 4 보정 시 180→252/160→224. Act 3 엘리트 중 가장 높은 단기 딜.

---

#### 2. 주작 신장 (vermilion_bird_general)

- **enemy_name**: `enemy.chinese.vermilion_bird_general` / **HP**: 2,000 / **charm_resistance**: 20
- **인텐트 시퀀스** (4턴 순환):
  ① DEBUFF 취약 2 [ALL] → ② ATK 180 [ALL] (fire) → ③ ATK 200 [RANDOM] (fire) → ④ BUFF 근력 2
- **핵심 메카닉**: 전체 취약 2 → 화염 광역 180 → RANDOM 200 → 근력 2 적립. 취약 상태 전체 광역이 핵심 위협.
- **밸런스 메모**: Act 3 엘리트 중 최고 HP(2,000). 취약 2 상태의 전체 화염 180은 파티 대파 위협.

---

#### 3. 현무 신장 (black_tortoise_general)

- **enemy_name**: `enemy.chinese.black_tortoise_general` / **HP**: 1,800 / **charm_resistance**: 20
- **인텐트 시퀀스** (5턴 순환):
  ① BUFF 방어 70 → ② DEBUFF 약화 3 [ALL] → ③ BUFF 방어 50 → ④ BUFF 근력 2 → ⑤ ATK 210 [RANDOM] (blunt)
- **핵심 메카닉**: 방어 120 + 전체 약화 3 + 근력 2 선행 후 강타. 5턴 준비 후 폭발.
- **밸런스 메모**: 방어 120으로 내구도가 매우 높음. 관통 카드 없으면 5턴 후 근력+약화 조합 강타.

---

### 보스 — 반고 (pangu)

- **enemy_name**: `enemy.chinese.pangu` / **HP**: 4,800 / **grade**: BOSS / **charm_resistance**: 20
- **페이즈 전환**: HP >66% → Phase 0 / 33~66% → Phase 1 / <33% → Phase 2
- **damage_type**: divine
- **카드 트리거**: `POWER` 카드 1장마다 → 약화 2 [ALL] (repeat: true)

**Phase 0 — 혼돈 (HP >66%)**
① BUFF 방어 50 → ② BUFF 근력 1 → ③ ATK 190 [RANDOM] → ④ ATK 160 [ALL] → ⑤ DEBUFF 취약 2 [RANDOM]

**Phase 1 — 천지개벽 (HP 33~66%)**
① ATK 220 [RANDOM] → ② DEBUFF 취약 2 [ALL] → ③ ATK 190 [ALL] → ④ ATK 200 [LOWEST_HP] → ⑤ DEBUFF 약화 3 [ALL] → ⑥ BUFF 근력 2

**Phase 2 — 만물 창조 (HP <33%)**
① ATK 160 [RANDOM] → ② ATK 160 [RANDOM] → ③ ATK 160 [RANDOM] → ④ ATK 160 [RANDOM] → ⑤ ATK 220 [ALL] → ⑥ DEBUFF 취약 3 [ALL] → ⑦ BUFF 근력 3

**메카닉 포인트**: 카드 트리거로 POWER 카드 사용 시마다 전체 약화 2 부여(반복). POWER 중심 덱을 강하게 카운터. Phase 2는 4타+광역+취약 3+근력 3의 7액션으로 가장 긴 패턴.

---

## 영웅 빌드 시너지

| 중국 위협 | 약점 빌드 | 권장 대응 |
|---|---|---|
| pangu 카드 트리거 (POWER 카드) | 권능 카드 위주 덱 | POWER 카드 사용 타이밍 조절 |
| 근력 폭발 (immortal_trainee, nine_dragon_general, white_tiger_general) | 빠른 처치 불가 덱 | 근력 제거 or 선제 처치 |
| 취약 누적 (shanhaijing_beast, golden_horn_king) | 신성 저항 없는 덱 | 취약 해소 or 블록 극대화 |
| 전체 화염 광역 (red_boy, vermilion_bird_general) | 파티 HP 불균형 덱 | HP 균등 유지 / 빠른 처치 |

---

## 키 집합 검증

| 코드 키 | 구분 |
|---|---|
| `enemy.chinese.yaksha` | 일반 |
| `enemy.chinese.nezha_soldier` | 일반 |
| `enemy.chinese.heavenly_king_soldier` | 일반 |
| `enemy.chinese.shanhaijing_beast` | 일반 |
| `enemy.chinese.immortal_trainee` | 일반 |
| `enemy.chinese.azure_dragon_guard` | 일반 |
| `enemy.chinese.golden_horn_king` | Act 1 엘리트 |
| `enemy.chinese.silver_horn_king` | Act 1 엘리트 |
| `enemy.chinese.black_wind_demon` | Act 1 엘리트 |
| `enemy.chinese.chiyou` | Act 1 보스 |
| `enemy.chinese.red_boy` | Act 2 엘리트 |
| `enemy.chinese.nine_dragon_general` | Act 2 엘리트 |
| `enemy.chinese.heavenly_hound_brothers` | Act 2 엘리트 |
| `enemy.chinese.erlang_shen` | Act 2 보스 |
| `enemy.chinese.white_tiger_general` | Act 3 엘리트 |
| `enemy.chinese.vermilion_bird_general` | Act 3 엘리트 |
| `enemy.chinese.black_tortoise_general` | Act 3 엘리트 |
| `enemy.chinese.pangu` | Act 3 보스 |
