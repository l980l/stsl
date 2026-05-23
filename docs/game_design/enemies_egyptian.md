# 이집트 신화 적 디자인

## 시스템 정보

- **챕터**: 1 (Chapter 1 풀: 그리스 / 이집트 / 북유럽)
- **Act 배정**: 챕터 진입 시 3신화를 셔플 → Act 1/2/3에 1:1 무작위 배정. 한 액트는 1신화로만 진행
- **Act 난이도 배율**: HP × {Act1: 1.0 / Act2: 1.3 / Act3: 1.6}, ATK × {Act1: 1.0 / Act2: 1.2 / Act3: 1.4}
- **코드 위치**: `resources/enemies/egyptian/egyptian_{normals,act1,act2,act3}.gd`

---

## 테마 시그니처

**주 테마 — "독(poison) + 디버프 축적"**
전갈·뱀·스카라브 등 독 속성 적이 poison 스택을 빠르게 쌓고, 모래 이프리트·오벨리스크 수호자 등은 강력한 전체 공격으로 위협. 클레오파트라 POISON 빌드와 시너지가 가장 높은 신화.

**부 테마 — "자가 블록 + 타이밍 압박"**
스카라브 여왕·오벨리스크 수호자·세트 폭풍 등이 자가 블록으로 딜 차단 후 강타. POISON으로 블록 우회하거나 누적 공격으로 돌파.

**차별 포인트 (그리스·북유럽 대비)**: poison이 가장 풍부한 신화. 클레오파트라 poison 빌드가 가장 효율적으로 작동. 오시리스(Act 2 보스)는 게임 전체 유일한 HP 회복 보스 — 특수 메카닉.

---

## 일반 적 풀 (모든 Act 공통)

> Act 난이도 배율 적용 기준값 = Act 1 (코드 원본 값)

---

### 1. 모래 척후병 (sand_scout)

- **enemy_name**: `enemy.egyptian.sand_scout` / **HP**: 380
- **인텐트 시퀀스** (3턴 순환):
  - ATK 90 [RANDOM] → BUFF strength +1 → ATK 90 [RANDOM]
- **핵심 메카닉**: 매 3턴마다 strength +1 자가 강화. 방치하면 공격력 폭증.
- **밸런스 메모**: HP 380으로 중간 수준. 2마리 조합에서 strength 동시 강화 → 빠른 처치 권장.

---

### 2. 사막 전갈 (desert_scorpion)

- **enemy_name**: `enemy.egyptian.desert_scorpion` / **HP**: 420
- **인텐트 시퀀스** (3인텐트 순환):
  - ATK 70 [RANDOM] → DEBUFF poison 4 [RANDOM] → ATK 70 [RANDOM]
- **핵심 메카닉**: 매 3턴째 poison 4스택 단일 부여. 주기적 독 누적.
- **시너지**: 클레오파트라 POISON_BURST 타이밍 — 전갈이 쌓은 독을 활용.
- **밸런스 메모**: poison 4는 일반 적 중 최고 스택. 2마리 조합에서 매 턴 독 부여로 빠른 누적.

---

### 3. 미라 전사 (mummy_warrior)

- **enemy_name**: `enemy.egyptian.mummy_warrior` / **HP**: 600
- **인텐트 시퀀스** (3턴 순환):
  - ATK 110 [RANDOM] → DEBUFF weak 2 [RANDOM] → ATK 140 [RANDOM]
- **핵심 메카닉**: 약화(weak) 2스택 단일 부여 후 강타 140. 약화 중 아군 피해 감소.
- **밸런스 메모**: HP 600 = 일반 적 중 고HP. 전갈+미라 조합에서 poison+weak 동시 압박.

---

### 4. 스핑크스 새끼 (sphinx_cub)

- **enemy_name**: `enemy.egyptian.sphinx_cub` / **HP**: 350
- **인텐트 시퀀스** (5턴 순환):
  - ATK 80 [RANDOM] → ATK 80 [RANDOM] → ATK 80 [RANDOM] → ATK 80 [RANDOM] → SPECIAL value=1
- **핵심 메카닉**: 4연타(각 80) 후 5번째 SPECIAL(카드 1장 버리기). 다중 히트 블록 소모 + 핸드 방해.
- **밸런스 메모**: 그리스 하르피아와 유사 패턴. HP 낮아 빠른 처치 가능하나 방치 시 핸드 유실.

---

### 5. 모래 이프리트 (sand_ifrit)

- **enemy_name**: `enemy.egyptian.sand_ifrit` / **HP**: 450
- **인텐트 시퀀스** (2턴 순환):
  - BUFF strength +2 [준비] → ATK 230 [ALL]
- **핵심 메카닉**: 홀수 턴 BUFF+준비, 짝수 턴 전체 230 강타. 사이클롭스 패턴의 광역 버전. 준비 턴에 BLOCK_ALL 필수.
- **밸런스 메모**: 전체 230은 Act 1 일반 적 중 최고 광역. strength +2 적용 후 최대 240+ 전체 피해. 이순신 BLOCK_ALL 학습 유도.

---

### 6. 카 영혼 (ka_spirit)

- **enemy_name**: `enemy.egyptian.ka_spirit` / **HP**: 320
- **인텐트 시퀀스** (4턴 순환):
  - ATK 55 [RANDOM] → DEBUFF vulnerable 2 [RANDOM] → ATK 55 [RANDOM] → DEBUFF weak 2 [RANDOM]
- **핵심 메카닉**: 취약(vulnerable) + 약화(weak) 교대 부여. 3마리 조합에서 동시 중첩 시 복합 soft-lock.
- **밸런스 메모**: 단독 위협 낮지만 3마리 조합에서 매 턴 디버프 부여 → 장기전 급격히 불리해짐.

---

### 인카운터 풀 (encounters() 기준, Act 1 합산 HP)

| # | 조합 | 적 수 | 합산 HP |
|---|---|---|---|
| 1  | sand_scout × 2                               | 2 | 760   |
| 2  | desert_scorpion × 2                          | 2 | 840   |
| 3  | ka_spirit × 3                                | 3 | 960   |
| 4  | sand_scout + desert_scorpion                 | 2 | 800   |
| 5  | mummy_warrior + ka_spirit                    | 2 | 920   |
| 6  | sand_scout + ka_spirit × 2                   | 3 | 1020  |
| 7  | sphinx_cub                                   | 1 | 350   |
| 8  | sand_ifrit                                   | 1 | 450   |
| 9  | mummy_warrior + desert_scorpion              | 2 | 1020  |
| 10 | desert_scorpion + ka_spirit                  | 2 | 740   |

---

## Act 1 — 엘리트 + 보스

> 코드: `egyptian_act1.gd` / elites() = ["jackal_warrior", "scarab_queen", "obelisk_guardian"] / boss() = "sekhmet"

### 엘리트 풀 (3종, 랜덤 1마리 선택)

---

#### 자칼 전사 (jackal_warrior)

- **HP**: 1700
- **인텐트 시퀀스** (4턴 순환):
  - ATK 130 [RANDOM] → ATK 130 [RANDOM] → BUFF strength +4 → ATK 170 [LOWEST_HP]
- **핵심 메카닉**: 3턴째 strength +4 즉발 후 4턴째 LOWEST_HP 집중 강타. 취약 영웅 우선 사냥.
- **시너지**: 이순신 필사즉생(저HP 강화) 빌드는 자칼의 LOWEST_HP 집중 위험 → 보호 필요.
- **밸런스 메모**: strength 4 적용 후 최대 174 LOWEST_HP. 카드로 취약 영웅 보호 or 빠른 처치 선택.

---

#### 스카라브 여왕 (scarab_queen)

- **HP**: 1600
- **인텐트 시퀀스** (4턴 순환):
  - DEBUFF poison 4 [ALL] → ATK 100 [RANDOM] → BUFF block +40 → ATK 140 [RANDOM]
- **핵심 메카닉**: 1턴째 전체 poison 4 부여, 3턴째 자가 블록 40. poison은 블록 무시 → 자가 블록이 있어도 독 피해는 누적.
- **시너지**: 클레오파트라 POISON_BURST가 스카라브 여왕 poison 4 ALL과 직접 시너지 — 2~3사이클 방치 후 폭발 가능.
- **밸런스 메모**: 블록 40은 나폴레옹 강타나 클레오파트라 poison으로 우회. 독 빌드 없으면 장기전 시 독 누적으로 불리.

---

#### 오벨리스크 수호자 (obelisk_guardian)

- **HP**: 2000 / **페이즈**: HP ≤ 50%에서 전환
- **Phase 0** (HP > 50%, 2인텐트 순환):
  - BUFF block +60 → ATK 150 [RANDOM]
- **Phase 1** (HP ≤ 50%, 2인텐트 순환):
  - ATK 180 [ALL] → ATK 220 [RANDOM]
- **핵심 메카닉**: Phase 0은 매 턴 블록 60 자가 강화 + 공격. Phase 1 전환 후 블록 없이 전체 180 + 강타 220.
- **밸런스 메모**: Phase 0 HP 1000 이상 구간에서 블록 축적 → 돌파 어려움. poison 또는 집중 딜로 HP 50% 달성 후 Phase 1 빠른 처치 필요.

---

### 보스: 세크메트 (sekhmet)

- **HP**: 4500 / **매혹 저항**: 20 / **페이즈**: HP ≤ 66% → Phase 1, HP ≤ 33% → Phase 2

**Phase 0** (HP 4500~2970, 3인텐트 순환):
- ATK 160 [RANDOM] → ATK 160 [RANDOM] → ATK 120 [ALL]

**Phase 1** (HP 2970~1485, 3인텐트 순환):
- ATK 180 [RANDOM] → DEBUFF weak 2 [ALL] → ATK 200 [ALL]

**Phase 2** (HP 1485~0, 3인텐트 순환):
- BUFF strength +10 → ATK 220 [ALL] → ATK 260 [LOWEST_HP]

- **핵심 메카닉**: Phase 1에서 전체 약화 부여 + 전체 200 연속. Phase 2 strength 10 즉발 후 전체 220+260 LOWEST_HP.
- **밸런스 메모**: Phase 2 strength 10 적용 후 전체 ATK = 220+100 = 320, LOWEST_HP = 260+100 = 360. 이순신 없으면 팀 전체 1/3 손실 + 영웅 즉사 가능.

---

## Act 2 — 엘리트 + 보스

> 코드: `egyptian_act2.gd` / elites() = ["serqet", "seth_hound", "ba_bird"] / boss() = "osiris"
> Act 2 실제 HP = 코드값 × 1.3, ATK = 코드값 × 1.2

### 엘리트 풀 (3종, 랜덤 1마리 선택)

---

#### 아펩 뱀 (serqet)

- **HP**: 1600 (Act 2 실제: 2080) / **매혹 저항**: 20
- **인텐트 시퀀스** (6인텐트 순환):
  - ATK 140 [RANDOM] → DEBUFF poison 5 [RANDOM] → ATK 140 [RANDOM] → DEBUFF poison 5 [RANDOM] → DEBUFF weak 3 [ALL] → ATK 200 [RANDOM]
- **핵심 메카닉**: 2턴마다 단일 poison 5 부여, 5번째 전체 weak 3, 6번째 강타 200. 독 누적 + 약화 복합.
- **밸런스 메모**: 6턴 1사이클 동안 poison 10스택 + weak 3 전체. 장기전 금지. 클레오파트라 독 해소 or 빠른 처치 선택.

---

#### 세트의 사냥개 (seth_hound)

- **HP**: 1800 (Act 2 실제: 2340) / **매혹 저항**: 20
- **인텐트 시퀀스** (4인텐트 순환):
  - ATK 150 [RANDOM] → BUFF strength +2 → ATK 150 [RANDOM] → ATK 280 [LOWEST_HP]
- **핵심 메카닉**: 2턴째 strength +2, 4턴째 LOWEST_HP 280 집중 강타. 사이클마다 strength 누적으로 LOWEST_HP 피해 폭증.
- **밸런스 메모**: 2사이클째부터 280+4 = 284, 3사이클째 288... 장기전 금지. 저HP 영웅 즉사 위험.

---

#### 바 새 (ba_bird)

- **HP**: 1500 (Act 2 실제: 1950) / **매혹 저항**: 20
- **인텐트 시퀀스** (5인텐트 순환):
  - ATK 110 [RANDOM] → ATK 110 [RANDOM] → ATK 110 [RANDOM] → ATK 110 [RANDOM] → SPECIAL value=2
- **핵심 메카닉**: 4연타(각 110) 후 5번째 SPECIAL(카드 2장 버리기). 그리스 하르피아의 강화판. 다중 히트 + 대량 핸드 방해.
- **밸런스 메모**: HP 낮아 4연타 누적 피해(440) 전에 처치 가능. 방치 시 핸드 2장 유실이 복구 불가 손해.

---

### 보스: 오시리스 (osiris)

- **HP**: 3000 (Act 2 실제: 3900) / **매혹 저항**: 20 / **페이즈**: HP ≤ 50%에서 전환
- **⚠️ 특수**: `phase_heal_ratios = [0.6]` — **Phase 1 전환 시 최대 HP의 60% 회복**. 이 게임의 유일한 HP 회복 보스.

**Phase 0** (HP 100%~50%, 5인텐트 순환):
- ATK 180 [RANDOM] → ATK 180 [RANDOM] → BUFF strength +1 + DEBUFF vulnerable 2 [ALL] → ATK 220 [ALL]

**Phase 1** (HP 50% 이하 → 회복 후 재시작, 7인텐트 순환):
- BUFF strength +2 [부활] → ATK 220 [RANDOM] + DEBUFF poison 6 [RANDOM] → ATK 220 [ALL] → DEBUFF weak 3 [ALL] + DEBUFF vulnerable 3 [ALL] → ATK 300 [LOWEST_HP]

- **핵심 메카닉**: Phase 1 진입 시 HP 60% 즉각 회복 (3000 기준 1800 회복) 후 패턴 강화. 회복 전 HP를 0에 가깝게 만들지 않으면 Phase 1이 HP 회복 후 시작되어 매우 불리.
- **시너지**: poison 6 전체 부여 → 클레오파트라 POISON_BURST로 Phase 1 즉시 대피해 가능. 독 빌드가 이 보스에서 가장 효율적.
- **밸런스 메모**: Phase 1 weak 3 + vulnerable 3 전체 중첩 후 LOWEST_HP 300은 즉사권. 부활 직후 독 폭발 또는 집중 고화력으로 최대한 빠르게 처치.

---

## Act 3 — 엘리트 + 보스

> 코드: `egyptian_act3.gd` / elites() = ["apophis_serpent", "set_tempest", "isis_phantom"] / boss() = "ra_horakhty"
> Act 3 실제 HP = 코드값 × 1.6, ATK = 코드값 × 1.4

### 엘리트 풀 (3종, 랜덤 1마리 선택)

---

#### 아포피스 서펜트 (apophis_serpent)

- **HP**: 2000 (Act 3 실제: 3200)
- **인텐트 시퀀스** (4턴 순환):
  - DEBUFF poison 5 [ALL] → ATK 140 [RANDOM] → ATK 140 [RANDOM] → DEBUFF poison 3 [RANDOM]
- **핵심 메카닉**: 1턴째 전체 poison 5 즉발. 4사이클 후 poison 32 전체 누적. POISON_BURST 없으면 독 피해만으로 팀 전체 출혈.
- **밸런스 메모**: Act 3 기준 ATK = 140×1.4 = 196. 독+공격 복합으로 빠른 HP 소모. 최우선 처치 대상.

---

#### 세트 폭풍 (set_tempest)

- **HP**: 2100 (Act 3 실제: 3360)
- **인텐트 시퀀스** (4턴 순환):
  - ATK 190 [RANDOM] → ATK 190 [RANDOM] → BUFF strength +6 → ATK 160 [ALL]
- **핵심 메카닉**: 3턴째 strength 6 즉발 후 4턴째 전체 160+6 = 전체 166. 이후 사이클마다 strength 6씩 누적.
- **밸런스 메모**: Act 3 기준 단일 ATK = 190×1.4 = 266. 전체 ATK = 160×1.4 = 224(+strength). 아레스 사냥개와 같은 위협 패턴.

---

#### 이시스 환영 (isis_phantom)

- **HP**: 1950 (Act 3 실제: 3120) / **페이즈**: HP ≤ 50%에서 전환
- **Phase 0** (HP > 50%, 3인텐트 순환):
  - DEBUFF weak 2 [ALL] → DEBUFF vulnerable 2 [ALL] → ATK 150 [RANDOM]
- **Phase 1** (HP ≤ 50%, 3인텐트 순환):
  - ATK 200 [ALL] → DEBUFF vulnerable 3 [ALL] → ATK 240 [LOWEST_HP]
- **핵심 메카닉**: Phase 0은 매 사이클 전체 weak+vulnerable 2 누적. Phase 1 전환 후 전체 200 + vulnerable 3 전체 + LOWEST_HP 240.
- **밸런스 메모**: Phase 0에서 3사이클 방치 시 weak 6+vulnerable 6 동시 누적. 이후 Phase 1 공격이 극도로 위협적. 조기 처치 최우선.

---

### 보스: 라-호라크티 (ra_horakhty)

- **HP**: 5000 (Act 3 실제: 8000) / **매혹 저항**: 20 / **페이즈**: HP ≤ 65% → Phase 1, HP ≤ 30% → Phase 2

**Phase 0** (HP 100%~65%, 4인텐트 순환):
- ATK 150 [RANDOM] → DEBUFF weak 2 [ALL] → ATK 150 [RANDOM] → ATK 130 [ALL]

**Phase 1** (HP 65%~30%, 4인텐트 순환):
- ATK 180 [RANDOM] → DEBUFF poison 6 [ALL] → ATK 200 [ALL] → ATK 220 [LOWEST_HP]

**Phase 2** (HP 30%~0, 4인텐트 순환):
- BUFF strength +15 → ATK 260 [ALL] → DEBUFF vulnerable 3 [ALL] → ATK 300 [LOWEST_HP]

- **핵심 메카닉**: Phase 0 약화 전체 → Phase 1 poison 6 전체 + 고화력 → Phase 2 strength 15 즉발 + 전체 + 취약 + LOWEST_HP.
- **시너지**: Phase 1 poison 6 ALL 시 클레오파트라 POISON_BURST 최적 타이밍. Phase 2 진입 전에 독 폭발이 이상적.
- **밸런스 메모**: Act 3 기준 Phase 2 strength 15 적용 후 전체 = (260+15)×1.4 = 385, LOWEST_HP = (300+15)×1.4 = 441. 영웅 즉사권.

---

## 시너지 포인트 요약

| 영웅 | 이집트 적 상성 |
|---|---|
| 클레오파트라 | **최적 신화**. 사막 전갈/스카라브 여왕/아펩 뱀의 poison이 POISON_BURST 연료. 오시리스 Phase 1 poison 6 ALL로 즉각 폭발 가능 |
| 나폴레옹 | 오벨리스크 수호자·자칼 전사 선처치. 세크메트·세트 폭풍 전체 공격 전 BLOCK 집중 |
| 이순신 | 자칼 전사·세트의 사냥개 LOWEST_HP 집중 → 필사즉생 빌드 주의. 진형 블록으로 이프리트·오벨리스크 전체 공격 대비 |
| 잔다르크 | 오시리스 Phase 1 회복 직후 버티기. 보호막으로 LOWEST_HP 집중 흡수 |

---

## 키 셋 검증

| enemy_name 코드 키 | 등장 위치 | 문서 반영 |
|---|---|---|
| `enemy.egyptian.sand_scout`       | normals       | ✓ |
| `enemy.egyptian.desert_scorpion`  | normals       | ✓ |
| `enemy.egyptian.mummy_warrior`    | normals       | ✓ |
| `enemy.egyptian.sphinx_cub`       | normals       | ✓ |
| `enemy.egyptian.sand_ifrit`       | normals       | ✓ |
| `enemy.egyptian.ka_spirit`        | normals       | ✓ |
| `enemy.egyptian.jackal_warrior`   | act1 엘리트   | ✓ |
| `enemy.egyptian.scarab_queen`     | act1 엘리트   | ✓ |
| `enemy.egyptian.obelisk_guardian` | act1 엘리트   | ✓ |
| `enemy.egyptian.sekhmet`          | act1 보스     | ✓ |
| `enemy.egyptian.serqet`       | act2 엘리트   | ✓ |
| `enemy.egyptian.seth_hound`       | act2 엘리트   | ✓ |
| `enemy.egyptian.ba_bird`          | act2 엘리트   | ✓ |
| `enemy.egyptian.osiris`           | act2 보스     | ✓ |
| `enemy.egyptian.apophis_serpent`  | act3 엘리트   | ✓ |
| `enemy.egyptian.set_tempest`      | act3 엘리트   | ✓ |
| `enemy.egyptian.isis_phantom`     | act3 엘리트   | ✓ |
| `enemy.egyptian.ra_horakhty`      | act3 보스     | ✓ |
