# 북유럽 신화 적 디자인

## 시스템 정보

- **챕터**: 1 (Chapter 1 풀: 그리스 / 이집트 / 북유럽)
- **Act 배정**: 챕터 진입 시 3신화를 셔플 → Act 1/2/3에 1:1 무작위 배정. 한 액트는 1신화로만 진행
- **Act 난이도 배율**: HP × {Act1: 1.0 / Act2: 1.3 / Act3: 1.6}, ATK × {Act1: 1.0 / Act2: 1.2 / Act3: 1.4}
- **코드 위치**: `resources/enemies/norse/norse_{normals,act1,act2,act3}.gd`

---

## 테마 시그니처

**주 테마 — "strength 폭발 + 대광역 강타"**
드라우그르·요툰·트롤 등 북유럽 거인족이 strength를 빠르게 누적하여 전체 광역 폭발로 팀 전체를 위협. Act가 올라갈수록 strength 누적 속도와 광역 규모가 급증.

**부 테마 — "방어와 돌파"**
요툰 병사·트롤 전사가 자가 블록 60~80으로 딜 차단. POISON이나 집중 고화력으로 돌파 필요. 발키리는 자가 블록 60 + LOWEST_HP 집중까지 추가.

**차별 포인트 (그리스·이집트 대비)**: strength 누적 규모가 가장 큼. 장기전 금지 신화. 요르문간드르(Act 3 보스)는 poison 10스택 ALL 즉발 + strength 15 + 전체 250으로 단일 보스 중 독+광역 복합 위협이 가장 큰 보스.

---

## 일반 적 풀 (모든 Act 공통)

> Act 난이도 배율 적용 기준값 = Act 1 (코드 원본 값)

---

### 1. 드라우그르 (draugr)

- **enemy_name**: `enemy.norse.draugr` / **HP**: 420
- **인텐트 시퀀스** (3턴 순환):
  - ATK 90 [RANDOM] → ATK 90 [RANDOM] → BUFF strength +10
- **핵심 메카닉**: 3턴마다 strength +10 자가 강화. 방치하면 다음 사이클 공격이 100+씩 증가.
- **밸런스 메모**: strength +10은 일반 적 중 최고. 3턴 이내 처치가 이상적. 2마리 조합에서 동시 강화 시 즉시 위협적.

---

### 2. 우르다의 거미 (urdr_spider)

- **enemy_name**: `enemy.norse.urdr_spider` / **HP**: 300
- **인텐트 시퀀스** (5인텐트 순환):
  - ATK 60 [RANDOM] → DEBUFF poison 3 [RANDOM] → ATK 60 [RANDOM] → ATK 60 [RANDOM] → DEBUFF poison 3 [RANDOM]
- **핵심 메카닉**: 2턴마다 단일 poison 3. 3마리 조합에서 매 턴 poison 누적.
- **시너지**: 3마리 조합 시 poison 6~9/턴 누적 → 클레오파트라 POISON_BURST 연료.
- **밸런스 메모**: HP 300 = 집중 공격 1방 처치. 3마리 조합에서 독 누적 빠름. 처치 우선 아니라면 독 시너지 활용.

---

### 3. 요툰 병사 (jotun_soldier)

- **enemy_name**: `enemy.norse.jotun_soldier` / **HP**: 600
- **인텐트 시퀀스** (3턴 순환):
  - BUFF block +80 → ATK 180 [RANDOM] → ATK 120 [ALL]
- **핵심 메카닉**: 매 사이클 첫 턴 block 80 자가 강화. 2턴 단일 180, 3턴 전체 120. 블록 우회가 핵심.
- **시너지**: POISON으로 블록 무시 or 나폴레옹 강타로 블록 소모 후 공격.
- **밸런스 메모**: HP 600 + 블록 80 = 실질 HP 680. 전체 120은 팀 전체 피해. 요툰 단독 조합이 가장 위협적.

---

### 4. 볼바 마녀 (volva_witch)

- **enemy_name**: `enemy.norse.volva_witch` / **HP**: 320
- **인텐트 시퀀스** (3턴 순환):
  - DEBUFF weak 2 [RANDOM] → DEBUFF vulnerable 2 [RANDOM] → ATK 110 [RANDOM]
- **핵심 메카닉**: 약화+취약 교대 단일 부여 후 강타. 3사이클이면 weak 6+vulnerable 6 단일 집중.
- **밸런스 메모**: HP 낮아 처치 쉬움. 2마리 조합에서 서로 다른 대상에 weak+vulnerable 교차 부여. 처치 우선.

---

### 5. 흐림팍시 기수 (hrimfaxi_rider)

- **enemy_name**: `enemy.norse.hrimfaxi_rider` / **HP**: 380
- **인텐트 시퀀스** (3턴 순환):
  - ATK 70 [RANDOM] → ATK 70 [LOWEST_HP] → ATK 140 [RANDOM]
- **핵심 메카닉**: 2턴째 LOWEST_HP 집중 70, 3턴째 강타 140. 취약 영웅 집중 노림.
- **시너지**: 이순신 필사즉생 빌드는 LOWEST_HP 집중 주의. 거미와 조합 시 독+저HP 집중 복합 압박.
- **밸런스 메모**: LOWEST_HP 70은 낮지만 볼바 마녀와 조합 시 weak+vulnerable 중첩 영웅에게 집중.

---

### 6. 가를라르 뱀 (garlarr_snake)

- **enemy_name**: `enemy.norse.garlarr_snake` / **HP**: 340
- **인텐트 시퀀스** (3턴 순환):
  - SPECIAL value=1 → ATK 85 [RANDOM] → ATK 85 [RANDOM]
- **핵심 메카닉**: 매 사이클 첫 턴 SPECIAL(카드 1장 버리기). 지속적 핸드 방해 + 공격 병행.
- **밸런스 메모**: 하르피아(그리스)보다 핸드 방해 주기가 빠름(매 3턴마다). 요툰과 조합 시 핸드 줄어 블록 카드 부족 위험.

---

### 인카운터 풀 (encounters() 기준, Act 1 합산 HP)

| # | 조합 | 적 수 | 합산 HP |
|---|---|---|---|
| 1  | draugr × 2                                   | 2 | 840   |
| 2  | urdr_spider × 3                              | 3 | 900   |
| 3  | jotun_soldier                                | 1 | 600   |
| 4  | volva_witch + hrimfaxi_rider                 | 2 | 700   |
| 5  | garlarr_snake × 2                            | 2 | 680   |
| 6  | draugr + volva_witch                         | 2 | 740   |
| 7  | hrimfaxi_rider + urdr_spider × 2             | 3 | 980   |
| 8  | jotun_soldier + garlarr_snake                | 2 | 940   |
| 9  | draugr + urdr_spider                         | 2 | 720   |
| 10 | volva_witch × 2                              | 2 | 640   |

---

## Act 1 — 엘리트 + 보스

> 코드: `norse_act1.gd` / elites() = ["nidhogg_larva", "skoll", "hrimthurs_scout"] / boss() = "fjorgynn"

### 엘리트 풀 (3종, 랜덤 1마리 선택)

---

#### 니드호그 유충 (nidhogg_larva)

- **HP**: 1750
- **인텐트 시퀀스** (4턴 순환):
  - DEBUFF poison 3 [RANDOM] → ATK 120 [RANDOM] → ATK 120 [RANDOM] → DEBUFF poison 5 [ALL]
- **핵심 메카닉**: 1턴 단일 poison 3, 4턴 전체 poison 5. 1사이클에 poison 최대 8 전체 부여.
- **시너지**: 클레오파트라 독 빌드 연료. 2사이클 방치 시 poison 13+ 전체 누적 → POISON_BURST로 큰 피해.
- **밸런스 메모**: 공격력 120은 낮지만 독 누적이 핵심 위협. 독 빌드 없으면 장기전 독 출혈.

---

#### 스콜 (skoll)

- **HP**: 1900
- **인텐트 시퀀스** (4턴 순환):
  - ATK 140 [LOWEST_HP] → ATK 140 [LOWEST_HP] → BUFF strength +6 → ATK 180 [RANDOM]
- **핵심 메카닉**: 1~2턴 연속 LOWEST_HP 집중 140, 3턴 strength 6 즉발, 4턴 강타 180+strength. 저HP 영웅 연속 사냥.
- **시너지**: 이순신 필사즉생은 스콜 LOWEST_HP 집중과 충돌 — 저HP로 의도했지만 스콜이 더 빠르게 처치 시도.
- **밸런스 메모**: 2사이클째부터 strength 6 적용 → 4턴째 186. 저HP 영웅 즉사 위험. 우선 처치 대상.

---

#### 흐림투르스 척후병 (hrimthurs_scout)

- **HP**: 1800 / **페이즈**: HP ≤ 50%에서 전환
- **Phase 0** (HP > 50%, 2인텐트 순환):
  - BUFF block +50 → ATK 130 [RANDOM]
- **Phase 1** (HP ≤ 50%, 2인텐트 순환):
  - ATK 170 [ALL] → ATK 200 [RANDOM]
- **핵심 메카닉**: Phase 0 블록 50 방어 중 공격. Phase 1 전환 후 블록 없이 전체 170 + 강타 200.
- **밸런스 메모**: Phase 0에서 블록 우회(poison) or 집중 딜로 HP 50% 달성. Phase 1 전체 170은 이순신 없으면 팀 전체 피해.

---

### 보스: 피요르기닌 (fjorgynn)

- **HP**: 4500 / **매혹 저항**: 20 / **페이즈**: HP ≤ 66% → Phase 1, HP ≤ 33% → Phase 2

**Phase 0** (HP 4500~2970, 3인텐트 순환):
- ATK 150 [RANDOM] → BUFF block +40 → ATK 150 [RANDOM]

**Phase 1** (HP 2970~1485, 3인텐트 순환):
- ATK 180 [RANDOM] → DEBUFF weak 2 [ALL] → ATK 200 [ALL]

**Phase 2** (HP 1485~0, 3인텐트 순환):
- BUFF strength +10 → ATK 230 [ALL] → ATK 260 [LOWEST_HP]

- **핵심 메카닉**: Phase 0은 자가 블록 40 방어 중 공격. Phase 1 전체 약화 + 전체 200. Phase 2 strength 10 즉발 후 전체 230 + LOWEST_HP 260.
- **밸런스 메모**: Phase 2 기준 전체 = (230+10)×1 = 240, LOWEST_HP = (260+10) = 270. 이순신 BLOCK_ALL 타이밍 필수.

---

## Act 2 — 엘리트 + 보스

> 코드: `norse_act2.gd` / elites() = ["troll_warrior", "norn", "vanir_elf"] / boss() = "surtr"
> Act 2 실제 HP = 코드값 × 1.3, ATK = 코드값 × 1.2

### 엘리트 풀 (3종, 랜덤 1마리 선택)

---

#### 트롤 전사 (troll_warrior)

- **HP**: 2050 (Act 2 실제: 2665)
- **인텐트 시퀀스** (4턴 순환):
  - ATK 160 [RANDOM] → BUFF block +60 → ATK 160 [RANDOM] → ATK 140 [ALL]
- **핵심 메카닉**: 2턴째 블록 60 자가 강화, 4턴째 전체 140. 블록 우회 + 전체 공격 대비 필요.
- **밸런스 메모**: Act 2 기준 단일 = 192, 전체 = 168. 요툰 병사의 강화판. 블록 60 + 전체 공격 복합.

---

#### 노른 (norn)

- **HP**: 1900 (Act 2 실제: 2470)
- **인텐트 시퀀스** (4턴 순환):
  - DEBUFF weak 2 [ALL] → DEBUFF vulnerable 2 [ALL] → ATK 170 [RANDOM] → BUFF strength +6
- **핵심 메카닉**: 1~2턴 전체 weak+vulnerable 부여, 3턴 강타, 4턴 strength 6 자가 강화. 디버프 + 자가 강화 복합.
- **밸런스 메모**: 2사이클 방치 시 전체 weak 4+vulnerable 4. 3턴 강타가 취약 대상에게 집중되면 피해 폭증.

---

#### 바니르 엘프 (vanir_elf)

- **HP**: 1850 (Act 2 실제: 2405) / **페이즈**: HP ≤ 50%에서 전환
- **Phase 0** (HP > 50%, 3인텐트 순환):
  - ATK 130 [RANDOM] → ATK 130 [RANDOM] → DEBUFF poison 4 [ALL]
- **Phase 1** (HP ≤ 50%, 2인텐트 순환):
  - ATK 190 [ALL] → ATK 220 [LOWEST_HP]
- **핵심 메카닉**: Phase 0은 3턴마다 전체 poison 4. Phase 1 전환 후 전체 190 + LOWEST_HP 220.
- **밸런스 메모**: Phase 0 poison 4 ALL 3회 = 12스택 전체. Phase 1 전환 후 고화력 2연타. 전환 전 독 누적 활용 or 빠른 처치 선택.

---

### 보스: 수르트 (surtr)

- **HP**: 4800 (Act 2 실제: 6240) / **매혹 저항**: 20 / **페이즈**: HP ≤ 65% → Phase 1, HP ≤ 30% → Phase 2

**Phase 0** (HP 100%~65%, 3인텐트 순환):
- ATK 170 [RANDOM] → ATK 170 [RANDOM] → ATK 140 [ALL]

**Phase 1** (HP 65%~30%, 3인텐트 순환):
- BUFF strength +5 → ATK 200 [ALL] → DEBUFF vulnerable 2 [ALL]

**Phase 2** (HP 30%~0, 3인텐트 순환):
- BUFF strength +15 → ATK 260 [ALL] → ATK 300 [LOWEST_HP]

- **핵심 메카닉**: Phase 1 strength 5 + 전체 200 + 취약 전체. Phase 2 strength 15 즉발 후 전체 260 + LOWEST_HP 300.
- **밸런스 메모**: Act 2 기준 Phase 2 전체 = (260+15)×1.2 = 330, LOWEST_HP = (300+15)×1.2 = 378. Phase 2 진입 전 처치 필수.

---

## Act 3 — 엘리트 + 보스

> 코드: `norse_act3.gd` / elites() = ["fenrir_cub", "valkyrie", "jormungandr_shard"] / boss() = "jormungandr"
> Act 3 실제 HP = 코드값 × 1.6, ATK = 코드값 × 1.4

### 엘리트 풀 (3종, 랜덤 1마리 선택)

---

#### 펜리르 새끼 (fenrir_cub)

- **HP**: 1900 (Act 3 실제: 3040) / **페이즈**: HP ≤ 50%에서 전환
- **Phase 0** (HP > 50%, 2인텐트 순환):
  - BUFF strength +8 → ATK 170 [RANDOM]
- **Phase 1** (HP ≤ 50%, 2인텐트 순환):
  - ATK 200 [RANDOM] → ATK 200 [RANDOM]
- **핵심 메카닉**: Phase 0 매 사이클 strength 8 누적 + 공격. 2사이클이면 strength 16 = ATK +16. Phase 1 전환 후 순수 2연타.
- **밸런스 메모**: Act 3 기준 Phase 0 4사이클 생존 시 strength 32 → ATK = (170+32)×1.4 ≒ 283. 빠른 처치 절대 필요.

---

#### 발키리 (valkyrie)

- **HP**: 1800 (Act 3 실제: 2880)
- **인텐트 시퀀스** (5턴 순환):
  - ATK 160 [RANDOM] → DEBUFF weak 2 [RANDOM] → BUFF block +60 → ATK 250 [LOWEST_HP] → SPECIAL value=2
- **핵심 메카닉**: 3턴째 block 60 자가 강화, 4턴째 LOWEST_HP 250 집중, 5번째 SPECIAL(자가 회복 연출).
- **밸런스 메모**: Act 3 기준 LOWEST_HP = 250×1.4 = 350. 저HP 영웅 즉사권. 블록 60은 poison 우회. 3번째 턴 전에 처치 또는 저HP 영웅 보호.

---

#### 요르문간드르 파편 (jormungandr_shard)

- **HP**: 2000 (Act 3 실제: 3200) / **페이즈**: HP ≤ 40%에서 전환
- **Phase 0** (HP > 40%, 3인텐트 순환):
  - ATK 140 [RANDOM] → DEBUFF poison 4 [ALL] → ATK 140 [RANDOM]
- **Phase 1** (HP ≤ 40%, 2인텐트 순환):
  - ATK 200 [ALL] → DEBUFF poison 6 [ALL]
- **핵심 메카닉**: Phase 0은 전체 poison 4 주기적 부여. Phase 1 전환 후 전체 200 + poison 6 ALL.
- **밸런스 메모**: Act 3 기준 Phase 1 전체 = 200×1.4 = 280. 독 누적까지 동시 위협. 독 시너지 없으면 조기 처치 우선.

---

### 보스: 요르문간드르 (jormungandr)

- **HP**: 5000 (Act 3 실제: 8000) / **매혹 저항**: 20 / **페이즈**: HP ≤ 65% → Phase 1, HP ≤ 30% → Phase 2

**Phase 0** (HP 100%~65%, 3인텐트 순환):
- ATK 130 [RANDOM] → DEBUFF poison 5 [ALL] → ATK 130 [RANDOM]

**Phase 1** (HP 65%~30%, 3인텐트 순환):
- ATK 160 [RANDOM] → DEBUFF poison 6 [ALL] → ATK 200 [LOWEST_HP]

**Phase 2** (HP 30%~0, 4인텐트 순환):
- DEBUFF poison 10 [ALL] → ATK 80 [ALL] → BUFF strength +15 → ATK 250 [ALL]

- **핵심 메카닉**: Phase 0/1 매 사이클 전체 poison 5~6 부여. Phase 2 진입 즉시 poison 10 ALL + 전체 80 + strength 15 즉발 + 전체 250.
- **시너지**: 클레오파트라 POISON_BURST로 Phase 2 진입 직후 poison 10 ALL 활용이 최적 타이밍.
- **밸런스 메모**: Act 3 기준 Phase 2 전체 80×1.4 = 112, strength 15 적용 후 전체 250 = (250+15)×1.4 = 371. 동일 턴에 poison 10 ALL 피해(영웅당 10/턴)까지 동시. Chapter 1 최강 보스.

---

## 시너지 포인트 요약

| 영웅 | 북유럽 적 상성 |
|---|---|
| 나폴레옹 | 드라우그르·스콜·펜리르 strength 누적 전 빠른 처치. 트롤·요툰 블록 소모 후 광역 딜 |
| 이순신 | 스콜·흐림팍시·발키리 LOWEST_HP 집중 → 필사즉생 빌드 충돌. BLOCK_ALL로 수르트·요르문간드르 전체 광역 대비 |
| 클레오파트라 | 니드호그·바니르 엘프·요르문간드르 poison ALL을 POISON_BURST 연료로 활용. 북유럽에서 이집트 다음으로 독 빌드 효율 높음 |
| 잔다르크 | 요르문간드르 Phase 2 전체 폭발 버티기. 보호막으로 발키리 LOWEST_HP 집중 흡수 |

---

## 키 셋 검증

| enemy_name 코드 키 | 등장 위치 | 문서 반영 |
|---|---|---|
| `enemy.norse.draugr`              | normals       | ✓ |
| `enemy.norse.urdr_spider`         | normals       | ✓ |
| `enemy.norse.jotun_soldier`       | normals       | ✓ |
| `enemy.norse.volva_witch`         | normals       | ✓ |
| `enemy.norse.hrimfaxi_rider`      | normals       | ✓ |
| `enemy.norse.garlarr_snake`       | normals       | ✓ |
| `enemy.norse.nidhogg_larva`       | act1 엘리트   | ✓ |
| `enemy.norse.skoll`               | act1 엘리트   | ✓ |
| `enemy.norse.hrimthurs_scout`     | act1 엘리트   | ✓ |
| `enemy.norse.fjorgynn`            | act1 보스     | ✓ |
| `enemy.norse.troll_warrior`       | act2 엘리트   | ✓ |
| `enemy.norse.norn`                | act2 엘리트   | ✓ |
| `enemy.norse.vanir_elf`           | act2 엘리트   | ✓ |
| `enemy.norse.surtr`               | act2 보스     | ✓ |
| `enemy.norse.fenrir_cub`          | act3 엘리트   | ✓ |
| `enemy.norse.valkyrie`            | act3 엘리트   | ✓ |
| `enemy.norse.jormungandr_shard`   | act3 엘리트   | ✓ |
| `enemy.norse.jormungandr`         | act3 보스     | ✓ |
