# 한국 신화 적 디자인

## 시스템 정보

- **챕터**: 2 (Chapter 2 풀: 한국 / 일본 / 중국)
- **Act 배정**: 챕터 진입 시 3신화를 셔플 → Act 1/2/3에 1:1 무작위 배정. 한 액트는 1신화로만 진행
- **Act 난이도 배율**: HP × {Act1: 1.0 / Act2: 1.3 / Act3: 1.6}, ATK × {Act1: 1.0 / Act2: 1.2 / Act3: 1.4}
- **코드 위치**: `resources/enemies/korean/korean_{normals,act1,act2,act3}.gd`
- **구현 출처**: `autoload/game_manager.gd:555-664`

---

## 테마 시그니처

**주 테마 — "저승과 신격의 심판"**
한국 무속 신화의 생사관. 저승사자·삼신·구삼승할망 등 삶과 죽음을 다스리는 신들. 영웅을 무력화하거나 체력 낮은 자를 집중 처형하는 패턴이 핵심.

**부 테마 — "LOWEST_HP 처형 + 독 누적"**
death_reaper·jangseung·underworld_judge·gusamseung_halmang 등 LOWEST_HP 타겟이 많음. Act 2 이후 독(poison) 누적과 조합하면 특정 영웅이 무너지는 스노볼 구조.

**차별 포인트 (일본·중국 대비)**: 일본은 번개·얼음 속성 다양성 중심, 중국은 신성(divine) + 근력 증폭 중심. 한국은 저주(curse) 데미지 + LOWEST_HP 타겟팅 + 독 축적 조합으로 "가장 약한 영웅부터 쓰러뜨리는" 압박 구조.

---

## 일반 적 풀 (모든 Act 공통)

> Act 난이도 배율 적용 기준값 = Act 1 (코드 원본 값)

---

### 1. 저승사자 (death_reaper)

- **enemy_name**: `enemy.korean.death_reaper` / **HP**: 320
- **인텐트 시퀀스** (3턴 순환):
  ① ATK 70 [LOWEST_HP] (slash) → ② DEBUFF 약화 2 [RANDOM] → ③ ATK 90 [LOWEST_HP] (slash)
- **핵심 메카닉**: 모든 공격이 LOWEST_HP 타겟. 약화 디버프 삽입 후 강화된 공격.
- **시너지**: 파티 HP 균등 유지가 핵심 대응. 약화 뒤 90 딜은 단일 영웅에 집중.
- **밸런스 메모**: HP 320으로 낮지만 2마리 조합 시 집중 처형 위협이 배가됨.

---

### 2. 처용 (cheoyong)

- **enemy_name**: `enemy.korean.cheoyong` / **HP**: 450
- **인텐트 시퀀스** (4턴 순환):
  ① BUFF 방어 40 → ② ATK 100 [RANDOM] (divine) → ③ ATK 120 [RANDOM] (divine) → ④ BUFF 방어 20
- **핵심 메카닉**: 자기 방어를 쌓은 뒤 신성 데미지 2타. 방어 60 축적 후 연속 공격.
- **시너지**: 방어 누적을 고려한 관통·약화 카드 활용 권장.
- **밸런스 메모**: HP 450에 방어 60을 쌓으면 실질 내구도가 높아짐. 빠른 처리 우선.

---

### 3. 도깨비 (dokkaebi)

- **enemy_name**: `enemy.korean.dokkaebi` / **HP**: 380
- **인텐트 시퀀스** (3턴 순환):
  ① BUFF 근력 1 → ② DEBUFF 취약 2 [RANDOM] → ③ ATK 90 [RANDOM] (blunt)
- **핵심 메카닉**: 근력을 쌓고 취약을 건 뒤 강타. 2마리 조합 시 취약 누적이 빠름.
- **시너지**: 도깨비 2마리(encounters #5)는 취약 4를 순식간에 쌓아 위험.
- **밸런스 메모**: 단독으로는 위협 낮지만 조합 시 취약 연쇄로 폭발적 딜 가능.

---

### 4. 삼족오 (three_legged_crow)

- **enemy_name**: `enemy.korean.three_legged_crow` / **HP**: 280
- **인텐트 시퀀스** (2턴 순환):
  ① BUFF 근력 1 → ② ATK 60 [ALL] (fire)
- **핵심 메카닉**: 매 2턴마다 근력을 쌓고 전체 공격. 장기전에서 근력이 누적될수록 광역 위협 증가.
- **시너지**: HP 280으로 낮아 초반에 빠르게 제거할 수 있으나, 방치 시 근력 폭발.
- **밸런스 메모**: 2마리 조합(encounters #6)은 매 턴 근력 누적 + 화염 광역으로 위협.

---

### 5. 구미호 (gumiho)

- **enemy_name**: `enemy.korean.gumiho` / **HP**: 350
- **인텐트 시퀀스** (4턴 순환):
  ① DEBUFF 취약 1 [RANDOM] → ② ATK 80 [RANDOM] (curse) → ③ DEBUFF 약화 2 [RANDOM] → ④ ATK 60 [RANDOM] (curse)
- **핵심 메카닉**: 취약→공격→약화→공격 순환. 취약+약화 이중 디버프로 영웅의 공격/방어 모두 약화.
- **시너지**: 도깨비와 조합(encounters #8) 시 취약 3+ 빠른 축적 가능.
- **밸런스 메모**: 저주(curse) 데미지는 차단 불가 유형. 방어를 쌓아도 피해 일부 통과.

---

### 6. 불가사리 (bulgasari)

- **enemy_name**: `enemy.korean.bulgasari` / **HP**: 900
- **인텐트 시퀀스** (3턴 순환):
  ① BUFF 근력 2 → ② ATK 100 [RANDOM] (blunt) → ③ ATK 130 [RANDOM] (blunt)
- **핵심 메카닉**: 일반 적 중 최고 HP(900). 근력 2 선행 후 강타 2연격. 단독 인카운터로 등장.
- **시너지**: 근력 2가 쌓이면 공격력이 크게 증폭. 근력 제거 효과 카드로 선제 대응 필요.
- **밸런스 메모**: 900HP로 여러 턴 버팀. 근력 폭발 전에 처치하거나 지속적 블록 필요.

---

### 인카운터 풀 (encounters() 반환값)

| # | 조합 | 적 수 | 합산 HP (Act 1 기준) |
|---|---|---|---|
| 1 | death_reaper | 1 | 320 |
| 2 | death_reaper × 2 | 2 | 640 |
| 3 | cheoyong | 1 | 450 |
| 4 | death_reaper + cheoyong | 2 | 770 |
| 5 | dokkaebi × 2 | 2 | 760 |
| 6 | three_legged_crow × 2 | 2 | 560 |
| 7 | gumiho | 1 | 350 |
| 8 | gumiho + dokkaebi | 2 | 730 |
| 9 | bulgasari | 1 | 900 |
| 10 | death_reaper + three_legged_crow | 2 | 600 |
| 11 | dokkaebi × 2 + three_legged_crow | 3 | 1,040 |

---

## Act 1 — 엘리트 + 보스

> 엘리트는 3종 중 1마리 랜덤 선택. HP 수치는 코드 원본값 (Act 1 배율 ×1.0).

### 엘리트 풀 (3종)

#### 1. 해치 (haechi)

- **enemy_name**: `enemy.korean.haechi` / **HP**: 1,600 / **charm_resistance**: 20
- **인텐트 시퀀스** (5턴 순환):
  ① BUFF 방어 60 → ② DEBUFF 취약 2 [RANDOM] → ③ BUFF 방어 60 → ④ BUFF 근력 1 → ⑤ ATK 180 [RANDOM] (divine)
- **핵심 메카닉**: 방어 120을 두 번에 나눠 쌓은 뒤 5턴째 강타. 취약 상태의 영웅에게 근력 보정 공격.
- **밸런스 메모**: 방어 누적형 엘리트. 취약 제거나 관통 카드가 없으면 공격 효율이 낮아짐.

---

#### 2. 장승 (jangseung)

- **enemy_name**: `enemy.korean.jangseung` / **HP**: 1,700 / **charm_resistance**: 20
- **인텐트 시퀀스** (4턴 순환):
  ① DEBUFF 취약 2 [ALL] → ② ATK 150 [LOWEST_HP] (blunt) → ③ DEBUFF 약화 2 [ALL] → ④ ATK 120 [RANDOM] (blunt)
- **핵심 메카닉**: 전체 취약→LOWEST_HP 강타→전체 약화→RANDOM 강타. 두 디버프를 전체에 걸어 집중 타격.
- **밸런스 메모**: 취약+약화 전 해소가 핵심. 체력 낮은 영웅이 있으면 150 blunt로 즉사 위협.

---

#### 3. 해모수 (haemosu)

- **enemy_name**: `enemy.korean.haemosu` / **HP**: 1,900 / **charm_resistance**: 20
- **인텐트 시퀀스** (5턴 순환):
  ① BUFF 근력 1 → ② BUFF 방어 40 → ③ ATK 150 [RANDOM] (divine) → ④ ATK 120 [ALL] (divine) → ⑤ ATK 180 [LOWEST_HP] (divine)
- **핵심 메카닉**: 근력+방어 선행 후 RANDOM→ALL→LOWEST_HP 3연속 신성 공격. 마지막 타가 최저 HP 집중.
- **밸런스 메모**: 엘리트 중 최고 HP(1,900). 공격 패턴 총 딜 450(근력 보정 전).

---

### 보스 — 단군 (dangun)

- **enemy_name**: `enemy.korean.dangun` / **HP**: 4,500 / **grade**: BOSS / **charm_resistance**: 20
- **페이즈 전환**: HP >66% → Phase 0 / 33~66% → Phase 1 / <33% → Phase 2
- **damage_type**: divine

**Phase 0 — 개벽의 빛 (HP >66%)**
① ATK 150 [RANDOM] → ② BUFF 근력 1 → ③ BUFF 방어 40 → ④ ATK 130 [ALL]

**Phase 1 — 건국 의지 (HP 33~66%)**
① ATK 180 [RANDOM] → ② DEBUFF 취약 2 [RANDOM] → ③ ATK 150 [ALL] → ④ ATK 200 [LOWEST_HP]

**Phase 2 — 시조의 분노 (HP <33%)**
① ATK 220 [RANDOM] → ② BUFF 근력 2 → ③ ATK 190 [ALL] → ④ ATK 240 [LOWEST_HP] → ⑤ DEBUFF 약화 2 [ALL]

**메카닉 포인트**: Phase 2 근력 2 선행 후 190 광역 + 240 LOWEST_HP 처형. 약화도 전체에 걸어 반격 효율 저하.

---

## Act 2 — 엘리트 + 보스

> Act 2 HP 배율 ×1.3, ATK 배율 ×1.2 (HP 수치는 코드 원본 기준)

### 엘리트 풀 (3종)

#### 1. 도깨비 대장 (dokkaebi_chief)

- **enemy_name**: `enemy.korean.dokkaebi_chief` / **HP**: 1,800 / **charm_resistance**: 20
- **인텐트 시퀀스** (4턴 순환):
  ① BUFF 근력 2 → ② BUFF 방어 30 → ③ ATK 170 [RANDOM] (blunt) → ④ ATK 150 [ALL] (blunt)
- **핵심 메카닉**: 근력 2+방어 30 선행 후 단일+전체 2타. 광역으로 파티 HP 균등화 방해.
- **밸런스 메모**: 근력 해제 or 빠른 처리가 핵심. Act 2 배율로 실질 공격 204/180+.

---

#### 2. 용왕의 장군 (sea_dragon_general)

- **enemy_name**: `enemy.korean.sea_dragon_general` / **HP**: 1,900 / **charm_resistance**: 20
- **인텐트 시퀀스** (4턴 순환):
  ① BUFF 근력 2 → ② ATK 160 [RANDOM] (divine) → ③ ATK 140 [ALL] (divine) → ④ BUFF 근력 1
- **핵심 메카닉**: 근력 선행 공격 후 추가 근력 적립으로 다음 사이클 강화. 누적형 위협.
- **밸런스 메모**: 근력 3+ 적립 전에 처치하지 않으면 광역 140+ 위협이 계속 증가.

---

#### 3. 동명성왕 (dongmyeong)

- **enemy_name**: `enemy.korean.dongmyeong` / **HP**: 1,900 / **charm_resistance**: 20
- **인텐트 시퀀스** (5턴 순환):
  ① ATK 90 [RANDOM] (divine) → ② ATK 90 [RANDOM] (divine) → ③ BUFF 근력 2 → ④ ATK 150 [ALL] (divine) → ⑤ DEBUFF 취약 2 [RANDOM]
- **핵심 메카닉**: 선제 2타 후 근력 적립 → 광역 150 → 취약 부여. 취약 상태에서 다음 사이클 공격 강화.
- **밸런스 메모**: 취약이 걸리면 다음 사이클 공격이 더 위협적. 취약 해제 우선.

---

### 보스 — 삼신할미 (samsin_grandma)

- **enemy_name**: `enemy.korean.samsin_grandma` / **HP**: 4,800 / **grade**: BOSS / **charm_resistance**: 20
- **페이즈 전환**: HP >66% → Phase 0 / 33~66% → Phase 1 / <33% → Phase 2
- **damage_type**: divine + poison

**Phase 0 — 점지의 손길 (HP >66%)**
① DEBUFF 약화 2 [ALL] → ② ATK 140 [LOWEST_HP] → ③ BUFF 방어 40 → ④ DEBUFF 독 3 [ALL]

**Phase 1 — 축복과 저주 (HP 33~66%)**
① DEBUFF 취약 2 [ALL] → ② ATK 180 [ALL] → ③ DEBUFF 독 4 [ALL] → ④ ATK 160 [RANDOM] → ⑤ BUFF 근력 1

**Phase 2 — 삼신의 분노 (HP <33%)**
① DEBUFF 취약 3 [ALL] → ② DEBUFF 약화 3 [ALL] → ③ ATK 230 [LOWEST_HP] → ④ DEBUFF 독 5 [RANDOM] → ⑤ ATK 200 [ALL] → ⑥ BUFF 근력 2

**메카닉 포인트**: 3개 페이즈 모두 독(poison)을 축적. Phase 2에서 취약 3+약화 3 전체 부여 후 230 LOWEST_HP 처형 + 독 5. 독 누적 해소 수단이 없으면 지속 피해가 쌓임.

---

## Act 3 — 엘리트 + 보스

> Act 3 HP 배율 ×1.6, ATK 배율 ×1.4 (HP 수치는 코드 원본 기준)

### 엘리트 풀 (3종)

#### 1. 저승 판관 (underworld_judge)

- **enemy_name**: `enemy.korean.underworld_judge` / **HP**: 1,900 / **charm_resistance**: 20
- **인텐트 시퀀스** (5턴 순환):
  ① DEBUFF 취약 2 [ALL] → ② ATK 140 [LOWEST_HP] (curse) → ③ ATK 180 [RANDOM] (curse) → ④ ATK 160 [ALL] (curse) → ⑤ DEBUFF 약화 2 [ALL]
- **카드 트리거**: `ATTACK` 카드 4장마다 → LOWEST_HP 영웅에게 저주 50 즉결 피해 (repeat: true)
- **핵심 메카닉**: 저주 데미지 3타 + 취약/약화 전체 부여. 공격 카드를 많이 쓸수록 즉결 피해가 반복 발동.
- **밸런스 메모**: 공격 위주 덱은 카드 트리거로 큰 추가 피해. 체력 낮은 영웅 관리 필수.

---

#### 2. 갓신 (gat_spirit)

- **enemy_name**: `enemy.korean.gat_spirit` / **HP**: 2,000 / **charm_resistance**: 20
- **인텐트 시퀀스** (4턴 순환):
  ① BUFF 근력 2 → ② BUFF 방어 40 → ③ ATK 180 [RANDOM] (curse) → ④ ATK 200 [LOWEST_HP] (curse)
- **핵심 메카닉**: 근력 2+방어 40 후 저주 2타. LOWEST_HP 타겟 최종 타가 처형용.
- **밸런스 메모**: Act 3 엘리트 중 최고 HP(2,000). 저주 200(근력 보정 전)은 Act 3 배율로 치명적.

---

#### 3. 처용신 (cheoyong_god)

- **enemy_name**: `enemy.korean.cheoyong_god` / **HP**: 1,800 / **charm_resistance**: 20
- **인텐트 시퀀스** (5턴 순환):
  ① BUFF 방어 50 → ② DEBUFF 약화 2 [RANDOM] → ③ DEBUFF 취약 2 [RANDOM] → ④ ATK 170 [RANDOM] (divine) → ⑤ ATK 190 [LOWEST_HP] (divine)
- **핵심 메카닉**: 방어 50 + 약화+취약 순차 부여 → RANDOM+LOWEST_HP 2타. 디버프 후 이중 타격.
- **밸런스 메모**: 일반 cheoyong의 강화판. 디버프 조합이 추가되어 신성 딜이 더욱 위협적.

---

### 보스 — 구삼승할망 (gusamseung_halmang)

- **enemy_name**: `enemy.korean.gusamseung_halmang` / **HP**: 4,800 / **grade**: BOSS / **charm_resistance**: 20
- **페이즈 전환**: HP >66% → Phase 0 / 33~66% → Phase 1 / <33% → Phase 2
- **damage_type**: divine + poison

**Phase 0 — 생명의 실 (HP >66%)**
① ATK 180 [LOWEST_HP] → ② DEBUFF 취약 2 [ALL] → ③ DEBUFF 약화 3 [ALL] → ④ ATK 160 [ALL] → ⑤ BUFF 근력 2 → ⑥ BUFF 방어 50

**Phase 1 — 운명의 저울 (HP 33~66%)**
① DEBUFF 취약 3 [ALL] → ② ATK 220 [LOWEST_HP] → ③ DEBUFF 약화 2 [RANDOM] → ④ ATK 190 [ALL] → ⑤ BUFF 근력 3

**Phase 2 — 저승 인도 (HP <33%)**
① ATK 260 [LOWEST_HP] → ② DEBUFF 취약 3 [ALL] → ③ ATK 210 [ALL] → ④ DEBUFF 약화 3 [ALL] → ⑤ ATK 190 [ALL] → ⑥ DEBUFF 독 5 [RANDOM]

**메카닉 포인트**: Phase 0부터 취약 2+약화 3 전체 부여 + 근력 2 선행. Phase 2에서 260 LOWEST_HP로 처형 시도 후 독 5 추가. 한국 보스 중 가장 복합적인 패턴.

---

## 영웅 빌드 시너지

| 한국 위협 | 약점 빌드 | 권장 대응 |
|---|---|---|
| LOWEST_HP 처형 (death_reaper, jangseung, dangun 등) | 단일 영웅 선봉 덱 | HP 균등 유지 / 아군 힐 |
| 독 누적 (samsin_grandma, gusamseung_halmang) | 독 해소 수단 없는 덱 | 독 제거 카드 확보 필수 |
| underworld_judge 카드 트리거 | 공격 카드 과다 덱 | ATTACK 카드 속도 조절 |
| 근력 폭발 (dokkaebi, bulgasari, sea_dragon_general) | 빠른 처치 불가 덱 | 근력 제거 or 차단 강화 |

---

## 키 집합 검증

| 코드 키 | 구분 |
|---|---|
| `enemy.korean.death_reaper` | 일반 |
| `enemy.korean.cheoyong` | 일반 |
| `enemy.korean.dokkaebi` | 일반 |
| `enemy.korean.three_legged_crow` | 일반 |
| `enemy.korean.gumiho` | 일반 |
| `enemy.korean.bulgasari` | 일반 |
| `enemy.korean.haechi` | Act 1 엘리트 |
| `enemy.korean.jangseung` | Act 1 엘리트 |
| `enemy.korean.haemosu` | Act 1 엘리트 |
| `enemy.korean.dangun` | Act 1 보스 |
| `enemy.korean.dokkaebi_chief` | Act 2 엘리트 |
| `enemy.korean.sea_dragon_general` | Act 2 엘리트 |
| `enemy.korean.dongmyeong` | Act 2 엘리트 |
| `enemy.korean.samsin_grandma` | Act 2 보스 |
| `enemy.korean.underworld_judge` | Act 3 엘리트 |
| `enemy.korean.gat_spirit` | Act 3 엘리트 |
| `enemy.korean.cheoyong_god` | Act 3 엘리트 |
| `enemy.korean.gusamseung_halmang` | Act 3 보스 |
