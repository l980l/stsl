# 도교 적 디자인

## 시스템 정보

- **챕터**: 2 (Chapter 2 풀: 일본 / 불교 / 도교)
- **Act 배정**: 챕터 진입 시 3신화를 셔플 → Act 1/2/3에 1:1 무작위 배정. 한 액트는 1신화로만 진행
- **Act 난이도 배율**: HP × {Act1: 1.0 / Act2: 1.3 / Act3: 1.6}, ATK × {Act1: 1.0 / Act2: 1.2 / Act3: 1.4}
- **코드 위치**: `resources/enemies/daoist/daoist_{normals,act1,act2,act3}.gd`
- **구현 출처**: `autoload/game_manager.gd:555-664`

---

## 테마 시그니처

**주 테마 — "선인(仙人)과 천계의 권능"**
도교 우주론의 신선·천군·신수. divine 신성 공격 + 근력 누적이 핵심 위협이며, 방어를 갖추면서 공격하는 패턴이 많아 지속전이 불리함.

**부 테마 — "취약(vulnerable) 전체 부여 + 근력 폭발"**
엘리트·보스가 전체 취약을 반복 부여하면서 근력을 쌓아 딜이 점층적으로 증가. 방어 중심 빌드를 무너뜨리는 설계.

**차별 포인트 (일본·불교 대비)**: 불교는 LOWEST_HP 처형+독 중심, 일본은 속성 분산. 도교는 **divine 통일 속성 + 취약 누적으로 아군 방어 가성비를 무력화**하는 것이 핵심. 옥황상제 Phase 2는 random 4연타로 블록 소모를 강제하며 POWER 카드 카운터로 권능 빌드를 직접 견제.

---

## 일반 적 풀 (모든 Act 공통)

> Act 난이도 배율 적용 기준값 = Act 1 (코드 원본 값)

---

### 1. 시해선 (hermit_ghost)

- **enemy_name**: `enemy.daoist.hermit_ghost` / **HP**: 340
- **인텐트 시퀀스** (3턴 순환):
  ① ATK 70 [RANDOM] (slash) → ② BUFF 근력 1 → ③ ATK 90 [RANDOM] (slash)
- **핵심 메카닉**: 공격→근력 적립→강화 공격. 매 사이클마다 근력 1씩 누적.
- **시너지**: 2마리 조합(#2, #4, #10)에서 근력 누적 속도 2배. 방치 시 빠른 공격력 상승.
- **밸런스 메모**: HP 340으로 중간. 단독은 위협 낮지만 2마리 이상이면 근력 폭발 주의.

---

### 2. 동자선 (child_immortal)

- **enemy_name**: `enemy.daoist.child_immortal` / **HP**: 280
- **인텐트 시퀀스** (3턴 순환):
  ① ATK 50 [RANDOM] (slash) → ② ATK 50 [RANDOM] (slash) → ③ BUFF 근력 1
- **핵심 메카닉**: 2연타 후 근력 적립. 개별 타격이 약하나 2마리 시 1턴에 4타.
- **시너지**: 2마리 조합(#3, #4)에서 4타 블록 분산 + 근력 2 동시 적립.
- **밸런스 메모**: HP 280으로 가장 낮아 빠른 처리 가능. 단 2마리가 동시에 있으면 블록 소모가 심함.

---

### 3. 천병 (celestial_soldier)

- **enemy_name**: `enemy.daoist.celestial_soldier` / **HP**: 450
- **인텐트 시퀀스** (4턴 순환):
  ① BUFF 방어 50 → ② ATK 110 [RANDOM] (slash) → ③ ATK 90 [RANDOM] (slash) → ④ BUFF 방어 30
- **핵심 메카닉**: 방어 선행 후 2타, 추가 방어. 자기 내구도를 지속 보충하는 소형 방어형 적.
- **시너지**: 시해선과 조합(#6)에서 천병이 방어를 쌓는 동안 시해선이 근력 누적.
- **밸런스 메모**: 방어 반복으로 실질 내구도가 HP보다 높음. 슬래시 피해만 투사해 속성 다양성은 낮음.

---

### 4. 산신 (mountain_spirit)

- **enemy_name**: `enemy.daoist.mountain_spirit` / **HP**: 380
- **인텐트 시퀀스** (4턴 순환):
  ① DEBUFF 취약 2 [RANDOM] → ② ATK 80 [RANDOM] (slash) → ③ ATK 60 [ALL] (slash) → ④ DEBUFF 취약 1 [ALL]
- **핵심 메카닉**: 취약 부여→단독→전체→전체 취약. 4턴 사이클 모두 취약 부여 또는 공격. 영웅 전체를 취약 상태로 유지하는 가장 꾸준한 디버프원.
- **시너지**: 2마리 조합(#7)에서 전체 취약을 2배 속도로 누적. 다른 적과 조합(#10)에서도 취약 상태를 유지.
- **밸런스 메모**: 전체 취약이 있어 방어 덱의 가성비를 계속 낮춤. 장기전일수록 불리.

---

### 5. 도사 수련생 (dao_disciple)

- **enemy_name**: `enemy.daoist.dao_disciple` / **HP**: 300
- **인텐트 시퀀스** (4턴 순환):
  ① BUFF 근력 1 → ② BUFF 근력 1 → ③ BUFF 근력 2 → ④ ATK 120 [RANDOM] (divine)
- **핵심 메카닉**: 3턴 근력 적립(합계 4) 후 1타 강타. 처음 3턴을 버티면 근력 4 상태의 강력한 divine 공격.
- **시너지**: 2마리 조합(#8)에서 교차 근력 적립으로 매 턴 근력이 쌓임. 4턴 후 ATK 120 × 2마리(근력 4 = 실질 160+) 위협.
- **밸런스 메모**: HP 300이라 빠른 처리 가능. 단 다른 적이 있어 처리가 미뤄지면 근력 폭발.

---

### 6. 청룡 호법 (azure_guardian)

- **enemy_name**: `enemy.daoist.azure_guardian` / **HP**: 520
- **인텐트 시퀀스** (4턴 순환):
  ① BUFF 근력 1 → ② BUFF 방어 40 → ③ ATK 100 [RANDOM] (slash) → ④ ATK 120 [RANDOM] (slash)
- **핵심 메카닉**: 근력+방어 선행 후 2연타. HP 520으로 일반 적 최고 내구도. 사실상 소형 엘리트 역할.
- **시너지**: 단독 등장(#9)만 있어 집중 제거 가능. 2사이클 버티면 근력 2 + 방어 40 상태로 ATK 120~140 수준.
- **밸런스 메모**: 방어까지 갖추므로 빠른 처리가 어려움. 긴 전투를 유도해 아군 자원 소모.

---

### 인카운터 풀 (11종)

| # | 조합 | 총 적 수 | 합산 HP (Act 1) |
|---|---|---|---|
| 1 | hermit_ghost | 1 | 340 |
| 2 | hermit_ghost × 2 | 2 | 680 |
| 3 | child_immortal × 2 | 2 | 560 |
| 4 | hermit_ghost + child_immortal | 2 | 620 |
| 5 | celestial_soldier | 1 | 450 |
| 6 | celestial_soldier + hermit_ghost | 2 | 790 |
| 7 | mountain_spirit × 2 | 2 | 760 |
| 8 | dao_disciple × 2 | 2 | 600 |
| 9 | azure_guardian | 1 | 520 |
| 10 | mountain_spirit + hermit_ghost | 2 | 720 |
| 11 | dao_disciple + celestial_soldier | 2 | 750 |

> 하위 Tier (#1~3): 340~560 / 중위 Tier (#4~9): 450~790 / 상위 Tier (#10~11): 720~790

---

## Act 1 — 엘리트 + 보스

### 엘리트 풀 (3종, 랜덤 1마리 선택)

#### 금단도사 (golden_elixir)

- **enemy_name**: `enemy.daoist.golden_elixir` / **HP**: 1,600 / **charm_resistance**: 20
- **인텐트 시퀀스** (6턴 순환):
  ① BUFF 방어 40 → ② BUFF 근력 1 → ③ DEBUFF 취약 2 [ALL] → ④ ATK 160 [RANDOM] (divine) → ⑤ ATK 130 [ALL] (divine) → ⑥ DEBUFF 취약 2 [ALL]
- **핵심 메카닉**: 방어+근력 선행 후 전체 취약 × 2회, divine 단독·전체 공격. 취약 상태에서 divine 전체 공격 타이밍 주의.
- **밸런스 메모**: 6턴 사이클이 길어 초반 2턴을 빠르게 활용하면 선제 처리 가능. 취약 전파가 이른 #3 턴에 시작되므로 3턴 내 처리 권장.

---

#### 은단도사 (silver_elixir)

- **enemy_name**: `enemy.daoist.silver_elixir` / **HP**: 1,700 / **charm_resistance**: 20
- **인텐트 시퀀스** (4턴 순환):
  ① DEBUFF 약화 2 [ALL] → ② BUFF 근력 2 → ③ ATK 140 [RANDOM] (divine) → ④ ATK 170 [RANDOM] (divine)
- **핵심 메카닉**: 전체 약화 선행 후 근력 2, 2연타. 약화 상태에서 아군 공격이 약해지면 빠른 처리가 더 어려워짐.
- **밸런스 메모**: 약화+근력 조합으로 영웅 딜이 줄고 적 딜이 증가하는 이중 압박. Act 1 엘리트 중 가장 효율적인 딜.

---

#### 흑풍선 (black_wind_immortal)

- **enemy_name**: `enemy.daoist.black_wind_immortal` / **HP**: 1,800 / **charm_resistance**: 20
- **인텐트 시퀀스** (5턴 순환):
  ① DEBUFF 취약 2 [RANDOM] → ② ATK 120 [RANDOM] (curse) → ③ ATK 150 [ALL] (curse) → ④ BUFF 근력 2 → ⑤ DEBUFF 취약 1 [ALL]
- **핵심 메카닉**: 취약→단독 curse→전체 curse→근력 2→전체 취약. 5턴 내 curse 2타 + 취약 3회 부여. Act 1 엘리트 최고 HP.
- **밸런스 메모**: curse 속성 전체 공격 + 취약으로 방어 덱에 특히 불리. 근력 2 이후 사이클부터 피해 급증.

---

### 보스 — 동왕공 (eastern_king)

- **enemy_name**: `enemy.daoist.eastern_king` / **HP**: 4,500 / **charm_resistance**: 20 / **phase_thresholds**: [0.66, 0.33]
- **grade**: BOSS

**Phase 0 — 청동 창** (HP 100%~67%)
① ATK 160 [RANDOM] (blunt) → ② BUFF 근력 1 → ③ ATK 130 [ALL] (blunt) → ④ BUFF 근력 1

**Phase 1 — 혈철 도끼** (HP 66%~34%)
① ATK 200 [RANDOM] (blunt) → ② ATK 160 [ALL] (blunt) → ③ DEBUFF 취약 2 [RANDOM] → ④ ATK 180 [RANDOM] (blunt) → ⑤ BUFF 근력 2

**Phase 2 — 천계 혈창** (HP 33%~0%)
① ATK 240 [RANDOM] (blunt) → ② DEBUFF 취약 3 [ALL] → ③ ATK 200 [ALL] (blunt) → ④ BUFF 근력 3

**핵심 메카닉**: Phase 0는 근력 누적 + 평타. Phase 1에서 전체 공격 + 취약 추가. Phase 2에서 전체 취약 3 + 근력 3으로 즉각 폭발. blunt 단일 속성이라 blunt 저항 빌드로 대응 가능하나 근력 누적 속도가 위협적.

---

## Act 2 — 엘리트 + 보스

### 엘리트 풀 (3종, 랜덤 1마리 선택)

#### 적양선 (crimson_immortal)

- **enemy_name**: `enemy.daoist.crimson_immortal` / **HP**: 1,800 / **charm_resistance**: 20
- **인텐트 시퀀스** (3턴 순환):
  ① BUFF 근력 1 → ② ATK 150 [RANDOM] (fire) → ③ ATK 170 [ALL] (fire)
- **핵심 메카닉**: 근력 1 선행 후 단독→전체 fire. 3턴 최단 사이클. 2사이클에 근력 2 상태로 fire 전체 204.
- **밸런스 메모**: 짧은 사이클로 근력이 빠르게 쌓임. fire 속성 전체 공격이 Act 2 엘리트 중 가장 빠른 딜 출력.

---

#### 구룡선존 (nine_dragon_lord)

- **enemy_name**: `enemy.daoist.nine_dragon` / **HP**: 1,900 / **charm_resistance**: 20
- **인텐트 시퀀스** (5턴 순환):
  ① BUFF 근력 2 → ② BUFF 방어 30 → ③ ATK 160 [RANDOM] (divine) → ④ BUFF 근력 2 → ⑤ ATK 220 [RANDOM] (divine)
- **핵심 메카닉**: 근력 2×2 = 사이클당 근력 4 누적. 방어도 갖춰 내구도 유지. 5턴 후 ATK 220 기준 실질 피해 매우 높음.
- **밸런스 메모**: 근력 누적 속도가 가장 빠른 엘리트. 2사이클 이상 허용 시 치명적.

---

#### 쌍검선인 (twin_immortals)

- **enemy_name**: `enemy.daoist.twin_immortals` / **HP**: 1,700 / **charm_resistance**: 20
- **인텐트 시퀀스** (6턴 순환):
  ① ATK 130 [RANDOM] (slash) → ② ATK 130 [RANDOM] (slash) → ③ DEBUFF 취약 2 [RANDOM] → ④ DEBUFF 취약 1 [RANDOM] → ⑤ ATK 160 [LOWEST_HP] (slash) → ⑥ DEBUFF 약화 2 [RANDOM]
- **핵심 메카닉**: 2연타→취약 누적→처형 집중→약화. 처형 + 약화 조합으로 HP 낮은 영웅을 지속 압박.
- **밸런스 메모**: HP 1,700으로 비교적 낮아 처리 가능. 단 처형 + 디버프 조합이 빠른 처리를 강제.

---

### 보스 — 진무대제 (xuanwu)

- **enemy_name**: `enemy.daoist.xuanwu` / **HP**: 4,800 / **charm_resistance**: 20 / **phase_thresholds**: [0.66, 0.33]
- **grade**: BOSS

**Phase 0 — 지휘** (HP 100%~67%)
① BUFF 근력 1 → ② BUFF 방어 40 → ③ ATK 170 [RANDOM] (divine) → ④ ATK 140 [ALL] (divine)

**Phase 1 — 삼안 개안** (HP 66%~34%)
① ATK 200 [RANDOM] (divine) → ② ATK 160 [ALL] (divine) → ③ DEBUFF 취약 2 [RANDOM] → ④ ATK 180 [LOWEST_HP] (divine) → ⑤ BUFF 근력 2

**Phase 2 — 천군 강림** (HP 33%~0%)
① ATK 180 [RANDOM] (divine) → ② ATK 180 [RANDOM] (divine) → ③ ATK 220 [ALL] (divine) → ④ DEBUFF 취약 2 [ALL] → ⑤ BUFF 근력 3

**핵심 메카닉**: Phase 0는 방어+딜 조합. Phase 1에서 처형 추가. Phase 2에서 double 단독 + 전체 ATK 220 + 전체 취약 + 근력 3으로 마무리 딜 폭발. divine 통일 속성.

---

## Act 3 — 엘리트 + 보스

### 엘리트 풀 (3종, 랜덤 1마리 선택)

#### 백호선군 (white_tiger_lord)

- **enemy_name**: `enemy.daoist.white_tiger` / **HP**: 1,900 / **charm_resistance**: 20
- **인텐트 시퀀스** (4턴 순환):
  ① BUFF 근력 3 → ② ATK 180 [RANDOM] (slash) → ③ ATK 160 [RANDOM] (slash) → ④ BUFF 근력 1
- **핵심 메카닉**: 근력 3 선행 후 2연타, 추가 근력 1. 사이클당 근력 4 누적. 첫 공격부터 근력 3이 반영돼 ATK 180+3 = 실질 183.
- **밸런스 메모**: Act 3 엘리트 중 근력 적립이 가장 빠름. 첫 사이클 내 처리가 이상적.

---

#### 주작선군 (vermilion_bird_lord)

- **enemy_name**: `enemy.daoist.vermilion_bird` / **HP**: 2,000 / **charm_resistance**: 20
- **인텐트 시퀀스** (4턴 순환):
  ① DEBUFF 취약 2 [ALL] → ② ATK 180 [ALL] (fire) → ③ ATK 200 [RANDOM] (fire) → ④ BUFF 근력 2
- **핵심 메카닉**: 전체 취약→전체 fire→단독 fire(취약 상태)→근력 2. 취약 상태에서 fire 2타를 맞으면 Act 3 실질 피해가 매우 높음.
- **밸런스 메모**: HP 2,000으로 Act 3 엘리트 최고 내구도. fire+취약+근력 조합이 방어 덱을 빠르게 돌파.

---

#### 현무선군 (black_tortoise_lord)

- **enemy_name**: `enemy.daoist.black_tortoise` / **HP**: 1,800 / **charm_resistance**: 20
- **인텐트 시퀀스** (5턴 순환):
  ① BUFF 방어 70 → ② DEBUFF 약화 3 [ALL] → ③ BUFF 방어 50 → ④ BUFF 근력 2 → ⑤ ATK 210 [RANDOM] (blunt)
- **핵심 메카닉**: 방어 120 + 약화 3(전체) + 근력 2 적립 후 ATK 210. 5턴 중 공격이 1번뿐이나 그 전에 방어를 120 쌓아 사실상 처리 불가 수준의 방어력.
- **밸런스 메모**: 방어 120이 풀 적립되면 단턴에 소모 불가. 약화 3(전체)으로 아군 딜도 감소. 방어 관통 카드나 유물 필수.

---

### 보스 — 옥황상제 (jade_emperor) ⚠ 카드 카운터 포함

- **enemy_name**: `enemy.daoist.jade_emperor` / **HP**: 4,800 / **charm_resistance**: 20 / **phase_thresholds**: [0.66, 0.33]
- **grade**: BOSS
- **card_count_trigger**: POWER 카드 사용마다 → DEBUFF 약화 2 [ALL] 즉시 발동 (반복)

**Phase 0 — 혼돈** (HP 100%~67%)
① BUFF 방어 50 → ② BUFF 근력 1 → ③ ATK 190 [RANDOM] (divine) → ④ ATK 160 [ALL] (divine) → ⑤ DEBUFF 취약 2 [RANDOM]

**Phase 1 — 천지개벽** (HP 66%~34%)
① ATK 220 [RANDOM] (divine) → ② DEBUFF 취약 2 [ALL] → ③ ATK 190 [ALL] (divine) → ④ ATK 200 [LOWEST_HP] (divine) → ⑤ DEBUFF 약화 3 [ALL] → ⑥ BUFF 근력 2

**Phase 2 — 만물 창조** (HP 33%~0%)
① ATK 160 [RANDOM] (divine) → ② ATK 160 [RANDOM] (divine) → ③ ATK 160 [RANDOM] (divine) → ④ ATK 160 [RANDOM] (divine) → ⑤ ATK 220 [ALL] (divine) → ⑥ DEBUFF 취약 3 [ALL] → ⑦ BUFF 근력 3

**핵심 메카닉**: Phase 2의 4연타 + 전체 공격은 블록 분산을 강제. POWER 카드를 쓸 때마다 전체 약화 2가 발동되어 권능(POWER) 빌드의 딜을 지속 약화. Phase 1의 약화 3(전체) + Phase 2 근력 3이 겹치면 반격이 극도로 어려워짐. POWER 카운터 때문에 나폴레옹·클레오파트라의 권능 빌드가 하드카운터됨.

---

## 시너지 포인트

- **이순신 빌드 (방어형)**: black_tortoise_lord 방어 120 + black_wind_immortal 취약 → 방어 침투 카드 필수. 방어 쌓기 덱이 취약 2~3으로 역으로 불리.
- **나폴레옹 빌드 (군단 딜)**: eastern_king·xuanwu·jade_emperor 근력 누적과 경쟁. jade_emperor의 POWER 카운터가 직접 견제.
- **클레오파트라 빌드 (권능)**: jade_emperor Phase 2의 POWER 카운터 약화 2로 권능 사용 자체가 불리. SKILL 기반 접근 필요.
- **취약 압박 빌드 대응**: mountain_spirit(일반)→golden_elixir/black_wind(엘리트)→보스 모두 취약 전파. 취약 해제 유물·카드 없으면 Act 누적이 심각.
- **fire + divine 이중 속성**: crimson_immortal(fire)와 나머지 divine이 혼재. 단일 속성 저항 빌드로 완전 대응 불가.

---

## 검증

| 문서 키 | 코드 원본 키 | 유형 | HP |
|---|---|---|---|
| enemy.daoist.hermit_ghost | enemy.chinese.yaksha | normal | 340 |
| enemy.daoist.child_immortal | enemy.chinese.nezha_soldier | normal | 280 |
| enemy.daoist.celestial_soldier | enemy.chinese.heavenly_king_soldier | normal | 450 |
| enemy.daoist.mountain_spirit | enemy.chinese.shanhaijing_beast | normal | 380 |
| enemy.daoist.dao_disciple | enemy.chinese.immortal_trainee | normal | 300 |
| enemy.daoist.azure_guardian | enemy.chinese.azure_dragon_guard | normal | 520 |
| enemy.daoist.golden_elixir | enemy.chinese.golden_horn_king | elite (act1) | 1,600 |
| enemy.daoist.silver_elixir | enemy.chinese.silver_horn_king | elite (act1) | 1,700 |
| enemy.daoist.black_wind_immortal | enemy.chinese.black_wind_demon | elite (act1) | 1,800 |
| enemy.daoist.eastern_king | enemy.chinese.chiyou | boss (act1) | 4,500 |
| enemy.daoist.crimson_immortal | enemy.chinese.red_boy | elite (act2) | 1,800 |
| enemy.daoist.nine_dragon | enemy.chinese.nine_dragon_general | elite (act2) | 1,900 |
| enemy.daoist.twin_immortals | enemy.chinese.heavenly_hound_brothers | elite (act2) | 1,700 |
| enemy.daoist.xuanwu | enemy.chinese.erlang_shen | boss (act2) | 4,800 |
| enemy.daoist.white_tiger | enemy.chinese.white_tiger_general | elite (act3) | 1,900 |
| enemy.daoist.vermilion_bird | enemy.chinese.vermilion_bird_general | elite (act3) | 2,000 |
| enemy.daoist.black_tortoise | enemy.chinese.black_tortoise_general | elite (act3) | 1,800 |
| enemy.daoist.jade_emperor | enemy.chinese.pangu | boss (act3) | 4,800 |

- intent_pattern·phase_patterns·card_count_trigger: 코드 원본(chinese_*.gd)과 동일 (메카닉 재활용)
- jade_emperor POWER 카운터 = pangu POWER 카운터 그대로 (threshold 1, repeat true, tooltip_key만 교체)
- Phase B 코드 작성 시 이 표를 SoT로 사용할 것
