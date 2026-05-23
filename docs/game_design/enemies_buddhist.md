# 불교 적 디자인

## 시스템 정보

- **챕터**: 2 (Chapter 2 풀: 일본 / 불교 / 도교)
- **Act 배정**: 챕터 진입 시 3신화를 셔플 → Act 1/2/3에 1:1 무작위 배정. 한 액트는 1신화로만 진행
- **Act 난이도 배율**: HP × {Act1: 1.0 / Act2: 1.3 / Act3: 1.6}, ATK × {Act1: 1.0 / Act2: 1.2 / Act3: 1.4}
- **코드 위치**: `resources/enemies/buddhist/buddhist_{normals,act1,act2,act3}.gd`
- **구현 출처**: `autoload/game_manager.gd:555-664`

---

## 테마 시그니처

**주 테마 — "업(業)과 분노의 신중"**
불교 우주론의 수호신·수라·명계 존재들. LOWEST_HP 집중 처형 + 전체 독/약화가 중심 메카닉으로, 약한 영웅을 먼저 끊는 압박이 강렬함.

**부 테마 — "신성(divine) + 저주(curse) 이중 속성"**
신성 공격(천계 존재)과 저주 공격(명계 존재)이 혼재. divine 저항 덱으로는 명계 엘리트를 막을 수 없고, curse 저항 덱으로는 천계 보스가 뚫음.

**차별 포인트 (일본·도교 대비)**: 일본은 속성 분산(번개·얼음·저주·독·화염), 도교는 divine+근력 누적. 불교는 **처형(LOWEST_HP) 패턴 + 독 누적 + 점층적 전체 디버프**로 차별화. Act 3 보스 부동명왕은 독 집중 투하로 지연전 자체를 불리하게 만듦.

---

## 일반 적 풀 (모든 Act 공통)

> Act 난이도 배율 적용 기준값 = Act 1 (코드 원본 값)

---

### 1. 야차 (yaksha)

- **enemy_name**: `enemy.buddhist.yaksha` / **HP**: 320
- **인텐트 시퀀스** (3턴 순환):
  ① ATK 70 [LOWEST_HP] (slash) → ② DEBUFF 약화 2 [RANDOM] → ③ ATK 90 [LOWEST_HP] (slash)
- **핵심 메카닉**: LOWEST_HP 처형 특화. HP가 낮은 영웅에게 집중 공격, 약화 부여로 반격도 억제.
- **시너지**: 2마리 조합(#2, #4, #10)에서 LOWEST_HP 집중이 2회 연속으로 발생해 처형 압박 극대화.
- **밸런스 메모**: HP 320으로 처리가 쉬우나, 방치 시 HP 낮은 영웅에게 집중 피해 발생.

---

### 2. 사천왕—증장천 (virudhaka)

- **enemy_name**: `enemy.buddhist.virudhaka` / **HP**: 450
- **인텐트 시퀀스** (4턴 순환):
  ① BUFF 방어 40 → ② ATK 100 [RANDOM] (divine) → ③ ATK 120 [RANDOM] (divine) → ④ BUFF 방어 20
- **핵심 메카닉**: 방어 선행 후 divine 2타, 다시 방어 회복. 자기 생존력 + 꾸준한 딜.
- **시너지**: 야차와 조합(#4)에서 virudhaka가 방어를 쌓는 동안 yaksha가 LOWEST_HP 처형 유지.
- **밸런스 메모**: HP 450 + 방어 반복으로 실질 내구도가 높음. divine 피해를 반복 투사.

---

### 3. 아수라 (asura)

- **enemy_name**: `enemy.buddhist.asura` / **HP**: 380
- **인텐트 시퀀스** (3턴 순환):
  ① BUFF 근력 1 → ② DEBUFF 취약 2 [RANDOM] → ③ ATK 90 [RANDOM] (blunt)
- **핵심 메카닉**: 근력 적립 → 취약 부여 → 강화 blunt 공격. 매 사이클마다 근력이 누적됨.
- **시너지**: 2마리 조합(#5, #11)에서 근력 누적 + 취약 2중 부여로 3턴 후 공격력 폭발.
- **밸런스 메모**: 취약 + 근력 조합은 영웅 블록을 빠르게 돌파함.

---

### 4. 가루다 (garuda)

- **enemy_name**: `enemy.buddhist.garuda` / **HP**: 280
- **인텐트 시퀀스** (2턴 순환):
  ① BUFF 근력 1 → ② ATK 60 [ALL] (fire)
- **핵심 메카닉**: 최단 사이클(2턴) 전체 공격. 근력 누적 후 fire 전체 타격으로 누적 피해.
- **시너지**: 2마리 조합(#6)에서 근력 2 + 전체 120 딜(Act1). #11 아수라2+가루다 조합에서 전체+처치 혼합.
- **밸런스 메모**: HP 280으로 가장 허약. 단 2턴 순환 전체 공격은 블록 없으면 즉사 위협.

---

### 5. 마라의 병사 (pishacha)

- **enemy_name**: `enemy.buddhist.pishacha` / **HP**: 350
- **인텐트 시퀀스** (4턴 순환):
  ① DEBUFF 취약 1 [RANDOM] → ② ATK 80 [RANDOM] (curse) → ③ DEBUFF 약화 2 [RANDOM] → ④ ATK 60 [RANDOM] (curse)
- **핵심 메카닉**: 취약→공격→약화→공격. 디버프 교차 사이클로 영웅의 공방 모두 억제.
- **시너지**: 아수라와 조합(#8)에서 취약+약화+근력 누적이 겹쳐 방어+공격 동시 약화.
- **밸런스 메모**: curse 피해로 방어 효율이 낮음. 장기전 시 디버프 누적이 위험.

---

### 6. 금강역사 (vajrapani)

- **enemy_name**: `enemy.buddhist.vajrapani` / **HP**: 900
- **인텐트 시퀀스** (3턴 순환):
  ① BUFF 근력 2 → ② ATK 100 [RANDOM] (blunt) → ③ ATK 130 [RANDOM] (blunt)
- **핵심 메카닉**: 단독 등장 엘리트급 일반적. 근력 2 적립 후 2연타. 방치 시 근력 폭발.
- **시너지**: 단독 등장(#9)만 있어 콤보는 없음. 다른 조합과 섞이지 않아 집중 제거 가능.
- **밸런스 메모**: HP 900으로 압도적으로 높음. 사실상 소형 엘리트 역할. 빠른 처리 필수.

---

### 인카운터 풀 (11종)

| # | 조합 | 총 적 수 | 합산 HP (Act 1) |
|---|---|---|---|
| 1 | yaksha | 1 | 320 |
| 2 | yaksha × 2 | 2 | 640 |
| 3 | virudhaka | 1 | 450 |
| 4 | yaksha + virudhaka | 2 | 770 |
| 5 | asura × 2 | 2 | 760 |
| 6 | garuda × 2 | 2 | 560 |
| 7 | pishacha | 1 | 350 |
| 8 | pishacha + asura | 2 | 730 |
| 9 | vajrapani | 1 | 900 |
| 10 | yaksha + garuda | 2 | 600 |
| 11 | asura × 2 + garuda | 3 | 1,040 |

> 하위 Tier (#1~3): 320~450 / 중위 Tier (#4~8): 560~770 / 상위 Tier (#9~11): 730~1,040

---

## Act 1 — 엘리트 + 보스

### 엘리트 풀 (3종, 랜덤 1마리 선택)

#### 다문천 (vaisravana)

- **enemy_name**: `enemy.buddhist.vaisravana` / **HP**: 1,600 / **charm_resistance**: 20
- **인텐트 시퀀스** (5턴 순환):
  ① BUFF 방어 60 → ② DEBUFF 취약 2 [RANDOM] → ③ BUFF 방어 60 → ④ BUFF 근력 1 → ⑤ ATK 180 [RANDOM] (divine)
- **핵심 메카닉**: 방어 2회 적립 후 취약 부여, 마지막에 근력 + 강타. 자기 방어가 매우 두꺼워 초반 공략이 어려움.
- **밸런스 메모**: 방어 120 적립 후 공격 패턴이라 ATK 카드만으로는 방어 소모가 쫓아가기 어려움.

---

#### 인왕역사 (mahoraga)

- **enemy_name**: `enemy.buddhist.mahoraga` / **HP**: 1,700 / **charm_resistance**: 20
- **인텐트 시퀀스** (4턴 순환):
  ① DEBUFF 취약 2 [ALL] → ② ATK 150 [LOWEST_HP] (blunt) → ③ DEBUFF 약화 2 [ALL] → ④ ATK 120 [RANDOM] (blunt)
- **핵심 메카닉**: 전체 취약 → LOWEST_HP 처형 → 전체 약화 → 추가 타격. 디버프와 처형을 번갈아 적용.
- **밸런스 메모**: 취약+약화 전체 부여로 영웅 전체 공방 억제. 처형 대상 영웅 빠른 회복 필수.

---

#### 호법신중 (dharma_general)

- **enemy_name**: `enemy.buddhist.dharma_general` / **HP**: 1,900 / **charm_resistance**: 20
- **인텐트 시퀀스** (5턴 순환):
  ① BUFF 근력 1 → ② BUFF 방어 40 → ③ ATK 150 [RANDOM] (divine) → ④ ATK 120 [ALL] (divine) → ⑤ ATK 180 [LOWEST_HP] (divine)
- **핵심 메카닉**: 근력+방어 선행 후 3연속 divine 공격(단독→전체→처형). Act 1 엘리트 중 가장 HP 높고 위협적.
- **밸런스 메모**: 3타 모두 divine이라 일반 블록으로만 대응 시 1사이클에 큰 피해 누적.

---

### 보스 — 대일여래 분노존 (mahavairocana)

- **enemy_name**: `enemy.buddhist.mahavairocana` / **HP**: 4,500 / **charm_resistance**: 20 / **phase_thresholds**: [0.66, 0.33]
- **grade**: BOSS

**Phase 0 — 개벽의 빛** (HP 100%~67%)
① ATK 150 [RANDOM] (divine) → ② BUFF 근력 1 → ③ BUFF 방어 40 → ④ ATK 130 [ALL] (divine)

**Phase 1 — 건국 의지** (HP 66%~34%)
① ATK 180 [RANDOM] (divine) → ② DEBUFF 취약 2 [RANDOM] → ③ ATK 150 [ALL] (divine) → ④ ATK 200 [LOWEST_HP] (divine)

**Phase 2 — 시조의 분노** (HP 33%~0%)
① ATK 220 [RANDOM] (divine) → ② BUFF 근력 2 → ③ ATK 190 [ALL] (divine) → ④ ATK 240 [LOWEST_HP] (divine) → ⑤ DEBUFF 약화 2 [ALL]

**핵심 메카닉**: Phase 0는 딜+버프 조합, Phase 1에서 처형 추가, Phase 2에서 근력 2 + 전체 약화로 반격 억제하며 처형 강화. 전 페이즈 divine 단일 속성이라 divine 저항 집중 시 대응 가능하나 근력 누적 주의.

---

## Act 2 — 엘리트 + 보스

### 엘리트 풀 (3종, 랜덤 1마리 선택)

#### 아수라왕 (asura_king)

- **enemy_name**: `enemy.buddhist.asura_king` / **HP**: 1,800 / **charm_resistance**: 20
- **인텐트 시퀀스** (4턴 순환):
  ① BUFF 근력 2 → ② BUFF 방어 30 → ③ ATK 170 [RANDOM] (blunt) → ④ ATK 150 [ALL] (blunt)
- **핵심 메카닉**: 근력 2 선행 후 방어 채우고 단독+전체 2타. 빠른 근력 적립으로 2사이클 이상 지속 시 피해 폭발.
- **밸런스 메모**: 전체 공격이 있어 HP 낮은 영웅이 여럿 있으면 특히 위험.

---

#### 나가왕 (naga_king)

- **enemy_name**: `enemy.buddhist.naga_king` / **HP**: 1,900 / **charm_resistance**: 20
- **인텐트 시퀀스** (4턴 순환):
  ① BUFF 근력 2 → ② ATK 160 [RANDOM] (divine) → ③ ATK 140 [ALL] (divine) → ④ BUFF 근력 1
- **핵심 메카닉**: 근력 적립→단독→전체→추가 근력. 매 사이클 근력 3 누적. 장기전에서 치명적.
- **밸런스 메모**: 근력이 회당 3씩 쌓여 3사이클 후 ATK 150 기준 실질 피해가 심각하게 증가.

---

#### 화신여래 분노존 (agni_buddha)

- **enemy_name**: `enemy.buddhist.agni_buddha` / **HP**: 1,900 / **charm_resistance**: 20
- **인텐트 시퀀스** (5턴 순환):
  ① ATK 90 [RANDOM] (divine) → ② ATK 90 [RANDOM] (divine) → ③ BUFF 근력 2 → ④ ATK 150 [ALL] (divine) → ⑤ DEBUFF 취약 2 [RANDOM]
- **핵심 메카닉**: 2연타 선딜 후 근력 2, 전체 공격, 취약 부여. 5턴 사이클이 길어 초반 2타를 버티면 근력 뒤처리 가능.
- **밸런스 메모**: 5턴 사이클 전체를 버티면 취약이 마지막에 오므로 블록 타이밍 여유 있음.

---

### 보스 — 천수관음 분노존 (guanyin_wrath)

- **enemy_name**: `enemy.buddhist.guanyin` / **HP**: 4,800 / **charm_resistance**: 20 / **phase_thresholds**: [0.66, 0.33]
- **grade**: BOSS

**Phase 0 — 점지의 손길** (HP 100%~67%)
① DEBUFF 약화 2 [ALL] → ② ATK 140 [LOWEST_HP] (divine) → ③ BUFF 방어 40 → ④ DEBUFF 독 3 [ALL]

**Phase 1 — 축복과 저주** (HP 66%~34%)
① DEBUFF 취약 2 [ALL] → ② ATK 180 [ALL] (divine) → ③ DEBUFF 독 4 [ALL] → ④ ATK 160 [RANDOM] (divine) → ⑤ BUFF 근력 1

**Phase 2 — 천수의 분노** (HP 33%~0%)
① DEBUFF 취약 3 [ALL] → ② DEBUFF 약화 3 [ALL] → ③ ATK 230 [LOWEST_HP] (divine) → ④ DEBUFF 독 5 [RANDOM] → ⑤ ATK 200 [ALL] (divine) → ⑥ BUFF 근력 2

**핵심 메카닉**: 독 누적이 핵심 위협. Phase 0에서 독 3, Phase 1에서 독 4(전체), Phase 2에서 독 5(단독 집중) + 전체 약화·취약. 독을 제거하지 않으면 매 턴 HP가 녹음. 처형(LOWEST_HP) + 전체 공격 + 독 3중 압박.

---

## Act 3 — 엘리트 + 보스

### 엘리트 풀 (3종, 랜덤 1마리 선택)

#### 염라대왕 (yama_king) ⚠ 카드 카운터 포함

- **enemy_name**: `enemy.buddhist.yama` / **HP**: 1,900 / **charm_resistance**: 20
- **인텐트 시퀀스** (5턴 순환):
  ① DEBUFF 취약 2 [ALL] → ② ATK 140 [LOWEST_HP] (curse) → ③ ATK 180 [RANDOM] (curse) → ④ ATK 160 [ALL] (curse) → ⑤ DEBUFF 약화 2 [ALL]
- **card_count_trigger**: ATTACK 카드 4장마다 → ATK 50 [LOWEST_HP] (curse) 즉시 발동 (반복)
- **핵심 메카닉**: 공격 카드 사용 자체가 역공 트리거. 빠른 처리를 위해 공격 카드를 많이 쓰면 오히려 처형 피해 누적. SKILL 위주 덱이나 공격 카드 분산 사용이 유리.
- **밸런스 메모**: Act 3 엘리트 중 가장 독특한 카운터 메카닉. 공격 집중 빌드에 강한 하드카운터.

---

#### 지장보살 분노존 (ksitigarbha)

- **enemy_name**: `enemy.buddhist.ksitigarbha` / **HP**: 2,000 / **charm_resistance**: 20
- **인텐트 시퀀스** (4턴 순환):
  ① BUFF 근력 2 → ② BUFF 방어 40 → ③ ATK 180 [RANDOM] (curse) → ④ ATK 200 [LOWEST_HP] (curse)
- **핵심 메카닉**: 근력+방어 선행 후 2타 curse. Act 3 엘리트 중 HP 2,000으로 최고. 방어까지 갖춰 내구도+딜 겸비.
- **밸런스 메모**: curse 공격이라 방어 효율이 낮음. 처형 집중이 있어 HP 낮은 영웅 우선 보호 필요.

---

#### 비로자나불 화현 (vairocana_avatar)

- **enemy_name**: `enemy.buddhist.virupaksha` / **HP**: 1,800 / **charm_resistance**: 20
- **인텐트 시퀀스** (5턴 순환):
  ① BUFF 방어 50 → ② DEBUFF 약화 2 [RANDOM] → ③ DEBUFF 취약 2 [RANDOM] → ④ ATK 170 [RANDOM] (divine) → ⑤ ATK 190 [LOWEST_HP] (divine)
- **핵심 메카닉**: 방어 선행 후 약화+취약 2중 부여, 마지막 처형. 디버프로 반격을 억제하며 집중 처형.
- **밸런스 메모**: 약화+취약 동시 부여 후 공격 패턴으로 DEBUFF 해제가 없으면 딜링이 크게 감소.

---

### 보스 — 부동명왕 (acalanatha)

- **enemy_name**: `enemy.buddhist.acalanatha` / **HP**: 4,800 / **charm_resistance**: 20 / **phase_thresholds**: [0.66, 0.33]
- **grade**: BOSS

**Phase 0 — 생명의 실** (HP 100%~67%)
① ATK 180 [LOWEST_HP] (divine) → ② DEBUFF 취약 2 [ALL] → ③ DEBUFF 약화 3 [ALL] → ④ ATK 160 [ALL] (divine) → ⑤ BUFF 근력 2 → ⑥ BUFF 방어 50

**Phase 1 — 운명의 저울** (HP 66%~34%)
① DEBUFF 취약 3 [ALL] → ② ATK 220 [LOWEST_HP] (divine) → ③ DEBUFF 약화 2 [RANDOM] → ④ ATK 190 [ALL] (divine) → ⑤ BUFF 근력 3

**Phase 2 — 저승 인도** (HP 33%~0%)
① ATK 260 [LOWEST_HP] (divine) → ② DEBUFF 취약 3 [ALL] → ③ ATK 210 [ALL] (divine) → ④ DEBUFF 약화 3 [ALL] → ⑤ ATK 190 [ALL] (divine) → ⑥ DEBUFF 독 5 [RANDOM]

**핵심 메카닉**: Phase 0부터 취약+약화 전체 부여 + 처형이 공존. Phase 2에서 전체 공격이 3회로 증가하며 마지막에 독 5를 집중 투하. 방어 충분히 쌓지 않으면 Phase 2 첫 턴에 HP 낮은 영웅이 즉사 가능.

---

## 시너지 포인트

- **이순신 빌드 (방어형)**: virudhaka·vajrapani의 방어 쌓기 패턴에 대항해 방어 침투 필요. 거북선 블록 스택으로 Phase 2까지 버티는 전략 유효.
- **나폴레옹 빌드 (근력 누적)**: asura·naga_king의 근력 누적과 경쟁. 아군 근력을 빠르게 쌓아 처형 당하기 전에 먼저 제거.
- **LOWEST_HP 집중 압박**: 야차(일반)→mahoraga(엘리트)→yama(엘리트)→모든 보스의 처형 체인. 영웅 HP 균등 유지가 필수 생존 조건.
- **독 저항 빌드 대응**: guanyin_wrath Phase 2에서 독 5 집중. 독 해제 유물·카드 없으면 Act 2 보스가 가장 까다로운 보스.
- **공격 카드 카운터**: yama_king의 ATTACK×4 트리거는 SKILL 중심 빌드를 유도. 나폴레옹/클레오파트라의 공격 집중 덱을 견제.

---

## 검증

| 문서 키 | 코드 원본 키 | 유형 | HP |
|---|---|---|---|
| enemy.buddhist.yaksha | enemy.korean.death_reaper | normal | 320 |
| enemy.buddhist.virudhaka | enemy.korean.cheoyong | normal | 450 |
| enemy.buddhist.asura | enemy.korean.dokkaebi | normal | 380 |
| enemy.buddhist.garuda | enemy.korean.three_legged_crow | normal | 280 |
| enemy.buddhist.pishacha | enemy.korean.gumiho | normal | 350 |
| enemy.buddhist.vajrapani | enemy.korean.bulgasari | normal | 900 |
| enemy.buddhist.vaisravana | enemy.korean.haechi | elite (act1) | 1,600 |
| enemy.buddhist.mahoraga | enemy.korean.jangseung | elite (act1) | 1,700 |
| enemy.buddhist.dharma_general | enemy.korean.haemosu | elite (act1) | 1,900 |
| enemy.buddhist.mahavairocana | enemy.korean.dangun | boss (act1) | 4,500 |
| enemy.buddhist.asura_king | enemy.korean.dokkaebi_chief | elite (act2) | 1,800 |
| enemy.buddhist.naga_king | enemy.korean.sea_dragon_general | elite (act2) | 1,900 |
| enemy.buddhist.agni_buddha | enemy.korean.dongmyeong | elite (act2) | 1,900 |
| enemy.buddhist.guanyin | enemy.korean.samsin_grandma | boss (act2) | 4,800 |
| enemy.buddhist.yama | enemy.korean.underworld_judge | elite (act3) | 1,900 |
| enemy.buddhist.ksitigarbha | enemy.korean.gat_spirit | elite (act3) | 2,000 |
| enemy.buddhist.virupaksha | enemy.korean.cheoyong_god | elite (act3) | 1,800 |
| enemy.buddhist.acalanatha | enemy.korean.gusamseung_halmang | boss (act3) | 4,800 |

- intent_pattern·phase_patterns·card_count_trigger: 코드 원본(korean_*.gd)과 동일 (메카닉 재활용)
- Phase B 코드 작성 시 이 표를 SoT로 사용할 것
