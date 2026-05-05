# 그리스 신화 적 디자인

## 시스템 정보

- **챕터**: 1 (Chapter 1 풀: 그리스 / 이집트 / 북유럽)
- **Act 배정**: 챕터 진입 시 3신화를 셔플 → Act 1/2/3에 1:1 무작위 배정. 한 액트는 1신화로만 진행
- **Act 난이도 배율**: HP × {Act1: 1.0 / Act2: 1.3 / Act3: 1.6}, ATK × {Act1: 1.0 / Act2: 1.2 / Act3: 1.4}
- **코드 위치**: `resources/enemies/greek/greek_{normals,act1,act2,act3}.gd`
- **구현 출처**: `autoload/game_manager.gd:555-664`

---

## 테마 시그니처

**주 테마 — "영웅의 도전"**
그리스 신화의 고전적 몬스터들. 학습 곡선이 낮고 메카닉이 직관적. 초반(Chapter 1)의 기준점 신화.

**부 테마 — "광역 강타 + 디버프 누적"**
사이클롭스 준비→강타, 케르베로스 5타+광역, 메두사 weak+vulnerable 순차 부여 등 예고형·누적형 패턴으로 블록 타이밍 학습을 유도한다. Act 3으로 갈수록 strength 폭발·전체 광역 비중이 높아짐.

**차별 포인트 (이집트·북유럽 대비)**: 독(poison) 빌드는 히드라·스킬라에서만 의미 있음. 전반적으로 단순한 패턴→이집트처럼 누적 debuff 전문화 없음→북유럽처럼 strength 폭발 전문화 없음. 복합 빌드 필요성이 가장 낮은 신화.

---

## 일반 적 풀 (모든 Act 공통)

> Act 난이도 배율 적용 기준값 = Act 1 (코드 원본 값)

---

### 1. 사티로스 (satyr)

- **enemy_name**: `enemy.greek.satyr` / **HP**: 350
- **인텐트 시퀀스** (2턴 순환):
  - ATK 80 [RANDOM] → ATK 80 [RANDOM]
- **핵심 메카닉**: 단순 무한 반복. 변수 없음. 튜토리얼 역할.
- **시너지**: 매혹(CHARM) 적용 시 동료 사티로스를 공격 → 2마리 인카운터에서 CHARM 가치 즉각 확인 가능.
- **밸런스 메모**: 가장 단순. 영웅 기본 공격 1~2방에 처치 가능 수준.

---

### 2. 하르피아 (harpy)

- **enemy_name**: `enemy.greek.harpy` / **HP**: 280
- **인텐트 시퀀스** (5턴 순환):
  - ATK 45 [RANDOM] → ATK 45 [RANDOM] → ATK 45 [RANDOM] → ATK 45 [RANDOM] → SPECIAL
- **핵심 메카닉**: 연속 4타(각 45) 후 5턴째 SPECIAL(아군 랜덤 1명 손패 1장 버리기). 다중 히트로 블록 분산 소모.
- **시너지**: 매혹 상태 시 SPECIAL 취소 → 클레오파트라 CHARM 시너지 가치 직관적 확인.
- **밸런스 메모**: HP 낮지만 다중 히트로 블록 관통 가능. 핸드 방해는 덱 의존도 높을 때 치명적. 우선 처치 대상.

---

### 3. 사이클롭스 (cyclops)

- **enemy_name**: `enemy.greek.cyclops` / **HP**: 700
- **인텐트 시퀀스** (2턴 순환):
  - PREPARE [준비] → ATK 200 [RANDOM]
- **핵심 메카닉**: 홀수 턴 PREPARE(예고), 짝수 턴 강타 200. 예고 인텐트 학습·블록 타이밍 맞추기 기초 훈련.
- **시너지**: 강타 전 턴에 블록 집중 가능 → 이순신 COUNTER_BLOCK·거북선 빌드 학습 유도.
- **밸런스 메모**: HP 700 = 장기전 강제. 200 단타는 무방비 영웅 즉사권. 준비 턴 읽기가 핵심.

---

### 4. 메두사의 뱀 (snake)

- **enemy_name**: `enemy.greek.snake` / **HP**: 300
- **인텐트 시퀀스** (2턴 순환):
  - ATK 60 [RANDOM] → DEBUFF vulnerable 2 [RANDOM]
- **핵심 메카닉**: 취약(vulnerable) 2스택 주기적 부여. 받는 피해 50% 증가.
- **시너지**: 사이클롭스+뱀 혼합 시 200×1.5=300 강타 위협 → 의도된 시너지 조합.
- **밸런스 메모**: HP 낮아 빠른 처치 가능. 방치하면 후속 강타 피해 폭증. 취약 제거 수단 없으면 장기전 위험.

---

### 5. 케르베로스 (cerberus)

- **enemy_name**: `enemy.greek.cerberus` / **HP**: 900
- **인텐트 시퀀스** (6턴 순환):
  - ATK 70 [RANDOM] → ATK 70 [RANDOM] → ATK 70 [RANDOM] → ATK 70 [RANDOM] → ATK 70 [RANDOM] → ATK 90 [ALL]
- **핵심 메카닉**: 5타 단일 후 6번째 전체 광역 90. 합산 피해 최대 440(단일) + 90(광역).
- **시너지**: ALL 타입 카드로 전체 다중 딜 가능. 나폴레옹 포격·이순신 한산대첩 최적 연습.
- **밸런스 메모**: HP 900으로 일반 적 중 최고. 광역 턴 전 이순신 BLOCK_ALL 타이밍이 핵심.

---

### 6. 미르미돈 병사 (myrmidon)

- **enemy_name**: `enemy.greek.myrmidon` / **HP**: 250
- **인텐트 시퀀스** (4턴 순환):
  - ATK 60 [RANDOM] → BUFF strength +1 → ATK 60 [RANDOM] → ATK 90 [RANDOM]
- **핵심 메카닉**: 2턴째 strength 자가 강화. 4턴째에 strength 적용 강타(90+α). 방치하면 점점 세짐.
- **시너지**: 3마리 조합에서 CHARM 적용 시 아군 피해 → 미르미돈 매혹 시너지 데모.
- **밸런스 메모**: HP 250 = 집중 공격 1방 처치 가능. 3마리 조합 시 합산 피해 수백. strength 강화 전 처치 우선.

---

### 인카운터 풀 (encounters() 기준, Act 1 합산 HP)

| # | 조합 | 적 수 | 합산 HP |
|---|---|---|---|
| 1  | satyr × 2                            | 2 | 700   |
| 2  | harpy × 3                            | 3 | 840   |
| 3  | myrmidon × 3                         | 3 | 750   |
| 4  | snake × 2                            | 2 | 600   |
| 5  | harpy + myrmidon                     | 2 | 530   |
| 6  | satyr + snake                        | 2 | 650   |
| 7  | cyclops                              | 1 | 700   |
| 8  | cerberus                             | 1 | 900   |
| 9  | myrmidon + snake + harpy             | 3 | 830   |
| 10 | satyr + myrmidon                     | 2 | 600   |

---

## Act 1 — 엘리트 + 보스

> 코드: `greek_act1.gd` / elites() = ["minotaur", "scylla", "gorgon", "medusa"] / boss() = "hydra"

### 엘리트 풀 (4종, 랜덤 1마리 선택)

---

#### 미노타우로스 (minotaur)

- **HP**: 2000 / **매혹 저항**: 20
- **인텐트 시퀀스** (3턴 순환):
  - ATK 150 [RANDOM] → ATK 150 [RANDOM] → ATK 260 [ALL]
- **핵심 메카닉**: 3턴째 전체 강타 260. 광역 대비 BLOCK_ALL 타이밍 필수.
- **밸런스 메모**: HP 2000 = 강화 빌드 7~8방. 전체 공격 260은 이순신 없으면 팀 1/4 손실. 나폴레옹+이순신 조합 학습.

---

#### 스킬라 (scylla)

- **HP**: 1900 / **매혹 저항**: 20 / **페이즈**: HP ≤ 50%에서 전환
- **Phase 0** (HP > 50%, 7인텐트 순환):
  - ATK 100 [RANDOM] → ATK 100 [RANDOM] → DEBUFF poison 3 [RANDOM] → ATK 80 [RANDOM] → ATK 100 [RANDOM] → ATK 100 [RANDOM] → ATK 120 [ALL]
- **Phase 1** (HP ≤ 50%, 3인텐트 순환):
  - ATK 160 [RANDOM] → DEBUFF poison 5 [ALL] → ATK 160 [RANDOM]
- **핵심 메카닉**: 전환 전 poison 3스택 단일 부여. 전환 후 poison 5스택 전체 부여 + 고화력.
- **시너지**: 클레오파트라 POISON 빌드가 스킬라 poison과 시너지. 독 누적 후 POISON_BURST 최적 타이밍.
- **밸런스 메모**: 페이즈 전환 후 poison ALL이 전투 판도를 바꿈. 전환 전 빠른 처치 vs. 독 시너지 활용 판단 요구.

---

#### 고르곤 (gorgon)

- **HP**: 1800 / **매혹 저항**: 20 / **페이즈**: HP ≤ 50%에서 전환
- **Phase 0** (HP > 50%, 6인텐트 순환):
  - ATK 140 [RANDOM] → DEBUFF vulnerable 1 [RANDOM] → BUFF strength +1 → DEBUFF vulnerable 1 [RANDOM] → ATK 140 [RANDOM] → DEBUFF vulnerable 1 [ALL]
- **Phase 1** (HP ≤ 50%, 3인텐트 순환):
  - ATK 160 [RANDOM] → DEBUFF vulnerable 2 [RANDOM] → ATK 160 [ALL]
- **핵심 메카닉**: 매 사이클 취약 1~2스택 부여 + strength 자가 강화. HP 절반 이하에서 가속.
- **밸런스 메모**: Phase 0에서 취약 누적을 허용하면 Phase 1 강타에서 피해 폭증. 빠른 처치가 이상적.

---

#### 메두사 (medusa)

- **HP**: 1700 / **매혹 저항**: 20
- **인텐트 시퀀스** (4턴 순환):
  - ATK 130 [RANDOM] → DEBUFF weak 2 [ALL] → DEBUFF vulnerable 2 [ALL] → ATK 180 [RANDOM]
- **핵심 메카닉**: 3턴째까지 전체 약화+취약 부여. 4턴째 180 강타는 weak+vulnerable 누적 상태에서 위협적.
- **밸런스 메모**: 핵심 위협은 아군 공격력 감소(weak)와 받는 피해 증폭(vulnerable) 복합. 디버프 없는 신화 중 가장 soft-control형.

---

### 보스: 히드라 (hydra)

- **HP**: 4500 / **매혹 저항**: 20 / **페이즈**: HP ≤ 66% → Phase 1, HP ≤ 33% → Phase 2

**Phase 0** (HP 4500~2970, 3인텐트 순환):
- ATK 180 [RANDOM] → ATK 180 [RANDOM] → ATK 140 [ALL]

**Phase 1** (HP 2970~1485, 4인텐트 순환):
- ATK 200 [RANDOM] → ATK 200 [RANDOM] → ATK 160 [ALL] → ATK 220 [LOWEST_HP]

**Phase 2** (HP 1485~0, 5인텐트 순환):
- ATK 240 [RANDOM] → ATK 240 [RANDOM] → ATK 200 [ALL] → ATK 260 [LOWEST_HP] → DEBUFF vulnerable 2 [ALL]

- **핵심 메카닉**: 페이즈마다 전체 공격 포함. Phase 2에서 LOWEST_HP 집중 + vulnerable 전체 부여 동시 위협.
- **시너지**: 독 빌드는 Phase 2 진입 전 독 스택 축적 → POISON_BURST 폭발 타이밍. 이순신 BLOCK_ALL로 Phase 1·2 전체 공격 대비.
- **밸런스 메모**: Phase 2 전체 200은 블록 없으면 팀 전체 출혈. LOWEST_HP 집중과 취약 부여 동시 처리 필요.

---

## Act 2 — 엘리트 + 보스

> 코드: `greek_act2.gd` / elites() = ["cerberus", "charon", "erinyes"] / boss() = "hades"
> Act 2 실제 HP = 코드값 × 1.3, ATK = 코드값 × 1.2

### 엘리트 풀 (3종, 랜덤 1마리 선택)

---

#### 케르베로스 (cerberus) — Act 2 하계 버전

- **HP**: 2000 (Act 2 실제: 2600) / **damage_type**: slash / fire
- **인텐트 시퀀스** (4턴 순환):
  - ATK 170 [RANDOM] → ATK 170 [RANDOM] → ATK 140 [ALL] → BUFF strength +5
- **핵심 메카닉**: 3턴 광역 + 4턴 strength +5 자가 강화. 5번째 사이클부터 ATK 기반 피해 폭증.
- **밸런스 메모**: 일반 케르베로스(normals)보다 HP 2배, strength 강화 추가. 장기전 금지.

---

#### 카론 (charon)

- **HP**: 1800 (Act 2 실제: 2340)
- **인텐트 시퀀스** (4턴 순환):
  - DEBUFF weak 2 [ALL] → ATK 160 [LOWEST_HP] → BUFF block +50 → ATK 200 [RANDOM]
- **핵심 메카닉**: 전체 약화 → 최저 HP 집중 공격 → 자가 블록 50 → 강타 200. 블록으로 딜 차단 + LOWEST_HP 집중.
- **시너지**: 이순신 필사즉생(저HP 강화) 빌드는 카론 LOWEST_HP 집중 → 위험. 반대로 HP를 의도적으로 낮추는 빌드는 주의 필요.
- **밸런스 메모**: 자가 블록 50은 poison으로 우회. 나폴레옹 고화력 + 클레오파트라 POISON 혼합 대응 최적.

---

#### 에리니에스 (erinyes)

- **HP**: 1900 (Act 2 실제: 2470) / **페이즈**: HP ≤ 50%에서 전환
- **Phase 0** (HP > 50%, 3인텐트 순환):
  - ATK 140 [RANDOM] → DEBUFF vulnerable 2 [RANDOM] → ATK 140 [RANDOM]
- **Phase 1** (HP ≤ 50%, 2인텐트 순환):
  - ATK 180 [RANDOM] → ATK 180 [RANDOM]
- **핵심 메카닉**: Phase 0은 취약 부여 + 단일 공격 혼합. Phase 1 전환 후 디버프 없이 순수 고화력 2연타.
- **밸런스 메모**: Phase 1 2연타 180×2=360(Act 2 기준 432)는 블록 없으면 단일 영웅 즉사권. 전환 전 처치 필수.

---

### 보스: 하데스 (hades)

- **HP**: 4800 (Act 2 실제: 6240) / **매혹 저항**: 20 / **페이즈**: HP ≤ 65% → Phase 1, HP ≤ 30% → Phase 2

**Phase 0** (HP 100%~65%, 3인텐트 순환):
- ATK 150 [RANDOM] → DEBUFF weak 2 [ALL] → ATK 150 [RANDOM]

**Phase 1** (HP 65%~30%, 3인텐트 순환):
- ATK 180 [RANDOM] → DEBUFF vulnerable 2 [ALL] → ATK 220 [LOWEST_HP]

**Phase 2** (HP 30%~0, 3인텐트 순환):
- BUFF strength +12 → ATK 90 [ALL] → ATK 260 [ALL]

- **핵심 메카닉**: Phase 0 weak 전체 → Phase 1 vulnerable 전체+LOWEST_HP 집중 → Phase 2 strength 12 즉발 후 전체 광역 2연속.
- **밸런스 메모**: Phase 2 strength 12면 90+90(strength)=180 전체, 260+260(strength)=520 전체. 디버프+고화력 최종 폭발. Phase 2 진입 전 처치가 최선.

---

## Act 3 — 엘리트 + 보스

> 코드: `greek_act3.gd` / elites() = ["ares_hound", "poseidon_apostle", "hephaestus_automaton"] / boss() = "kronos"
> Act 3 실제 HP = 코드값 × 1.6, ATK = 코드값 × 1.4

### 엘리트 풀 (3종, 랜덤 1마리 선택)

---

#### 아레스의 사냥개 (ares_hound)

- **HP**: 2100 (Act 3 실제: 3360)
- **인텐트 시퀀스** (4턴 순환):
  - ATK 180 [RANDOM] → ATK 180 [RANDOM] → BUFF strength +8 → ATK 220 [ALL]
- **핵심 메카닉**: 3턴째 strength 8 자가 강화 후 4턴째 전체 220+strength 폭발. 방치하면 팀 전체 즉사.
- **밸런스 메모**: Act 3 기준 전체 ATK = (220+8) × 1.4 ≒ 319. 이순신 BLOCK_ALL 타이밍 맞추기 필수.

---

#### 포세이돈의 사도 (poseidon_apostle)

- **HP**: 1950 (Act 3 실제: 3120)
- **인텐트 시퀀스** (4턴 순환):
  - DEBUFF weak 3 [ALL] → ATK 160 [RANDOM] → ATK 160 [RANDOM] → DEBUFF vulnerable 2 [ALL]
- **핵심 메카닉**: 전체 weak 3 + 전체 vulnerable 2 교대 부여. 완전한 soft-lock — 아군 피해 25% 감소 + 받는 피해 50% 증가 동시 중첩.
- **밸런스 메모**: 처치 안 하면 5~6턴 이후 아군 전투력 극도로 저하. 나폴레옹 고화력 선처치 우선.

---

#### 헤파이스토스의 자동기계 (hephaestus_automaton)

- **HP**: 2200 (Act 3 실제: 3520) / **페이즈**: HP ≤ 50%에서 전환
- **Phase 0** (HP > 50%, 3인텐트 순환):
  - BUFF block +80 → ATK 160 [RANDOM] → ATK 160 [RANDOM]
- **Phase 1** (HP ≤ 50%, 3인텐트 순환):
  - ATK 220 [ALL] → BUFF strength +10 → ATK 260 [RANDOM]
- **핵심 메카닉**: Phase 0은 80 자가 블록으로 딜 차단. Phase 1 전환 후 전체 220 + strength 10 즉발 + 강타 260.
- **시너지**: Phase 0 블록 80은 poison으로 우회. Phase 1 전환 후 strength+전체 광역은 이순신 BLOCK_ALL 타이밍.
- **밸런스 메모**: Phase 0 돌파가 핵심. POISON으로 블록 무시 or 누적 공격으로 HP 절반 달성 후 빠른 처치.

---

### 보스: 크로노스 (kronos)

- **HP**: 5200 (Act 3 실제: 8320) / **매혹 저항**: 20 / **페이즈**: HP ≤ 65% → Phase 1, HP ≤ 30% → Phase 2
- **특수 능력**: 아군이 기술(SKILL) 카드를 5장 쓸 때마다 전체에 DEBUFF vulnerable 2 자동 부여 (반복)

**Phase 0** (HP 100%~65%, 4인텐트 순환):
- ATK 160 [RANDOM] → DEBUFF weak 2 [ALL] → ATK 160 [RANDOM] → ATK 140 [ALL]

**Phase 1** (HP 65%~30%, 4인텐트 순환):
- BUFF strength +8 → ATK 200 [ALL] → DEBUFF vulnerable 3 [ALL] → ATK 240 [LOWEST_HP]

**Phase 2** (HP 30%~0, 3인텐트 순환):
- BUFF strength +20 → ATK 280 [ALL] → ATK 320 [LOWEST_HP]

- **핵심 메카닉**: Phase 1 strength 8 즉발 + 전체 200 + 취약 3 전체 + 최저 HP 240. Phase 2 strength 20 즉발 후 전체 280 + 최저 HP 320. 기술 카드 5장 카운터는 빌드에 따라 취약 중첩 가속 위험.
- **시너지**: 기술 카드 중심 빌드(이순신 진형계)는 SKILL 5장 카운터 주의. 공격 카드 중심(나폴레옹 돌격) 빌드는 카운터 발동 느림.
- **밸런스 메모**: Act 3 기준 Phase 2 전체 ATK = 280 × 1.4 = 392, 최저 HP 320 × 1.4 = 448. 영웅 HP 1000 기준 즉사. Phase 1 진입 전 처치가 현실적 목표.

---

## 시너지 포인트 요약

| 영웅 | 그리스 적 상성 |
|---|---|
| 나폴레옹 | 강타(HIGH ATK) 카드로 사이클롭스 HP 700 빠른 처치, 미노타우로스 전체 공격 전 방어, 아레스 사냥개 처치 우선 |
| 이순신 | 케르베로스·미노타우로스·히드라·크로노스의 ALL 공격에 BLOCK_ALL 타이밍. 필사즉생 빌드는 카론 LOWEST_HP 주의 |
| 클레오파트라 | 스킬라 Phase 1 poison ALL 시너지. 카론 self-block을 poison으로 우회. 메두사 대응 없음 |
| 잔다르크 | 보호막+치유로 히드라·하데스 Phase 2 전체 광역 버티기. 기사단 빌드는 크로노스 SKILL 카운터 주의 |

---

## 키 셋 검증

| enemy_name 코드 키 | 등장 위치 | 문서 반영 |
|---|---|---|
| `enemy.greek.satyr`                  | normals      | ✓ |
| `enemy.greek.harpy`                  | normals      | ✓ |
| `enemy.greek.cyclops`                | normals      | ✓ |
| `enemy.greek.snake`                  | normals      | ✓ |
| `enemy.greek.cerberus`               | normals + act2 엘리트 | ✓ |
| `enemy.greek.myrmidon`               | normals      | ✓ |
| `enemy.greek.minotaur`               | act1 엘리트  | ✓ |
| `enemy.greek.medusa`                 | act1 엘리트  | ✓ |
| `enemy.greek.gorgon`                 | act1 엘리트  | ✓ |
| `enemy.greek.scylla`                 | act1 엘리트  | ✓ |
| `enemy.greek.hydra`                  | act1 보스    | ✓ |
| `enemy.greek.charon`                 | act2 엘리트  | ✓ |
| `enemy.greek.erinyes`                | act2 엘리트  | ✓ |
| `enemy.greek.hades`                  | act2 보스    | ✓ |
| `enemy.greek.ares_hound`             | act3 엘리트  | ✓ |
| `enemy.greek.poseidon_apostle`       | act3 엘리트  | ✓ |
| `enemy.greek.hephaestus_automaton`   | act3 엘리트  | ✓ |
| `enemy.greek.kronos`                 | act3 보스    | ✓ |
