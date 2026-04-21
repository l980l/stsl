# 챕터 2 한국 신화 적 기획 v1

## 테마 시그니처

**주 테마 — "저승계의 압박"**
적들이 아군 최저 HP 영웅을 집중 타겟하거나 지속 약화(weak/vulnerable)를 쌓아 장기전을 유도한다.
기존 신화와 차별점: 그리스=strength 광역 / 이집트=poison·카드 제거 / 북유럽=strength 누적 대피해
→ 한국=**최저 HP 타겟 + 지속 약화 + 고방어도** 조합. 이순신 필사즉생 빌드와 긴장감 유발.

**부 테마 — "견고한 수호"**
처용·해치·갓신 등 수호 신격이 높은 방어도(block)를 쌓아 돌파를 강요한다.
나폴레옹 사기 소모 고화력 빌드 유도.

> **구현 주의**: `최저 HP 아군` 타겟은 IntentResource.TargetType.LOWEST_HP. 현재 시스템에 이미 있는 타입인지 확인 필요.
> HP 회복 SPECIAL은 보스 `phase_heal_ratios` 방식으로만 안정 구현됨. 일반/엘리트 HP 회복은 별도 지원 필요 시 구현 PR에서 결정.

---

## 스케일 기준

(Act 1 기준 수치. `_apply_act_difficulty()`가 Act 2 × HP 1.3·ATK 1.2, Act 3 × HP 1.6·ATK 1.4 자동 적용)

| 구분 | HP | 단타 | 광역 |
|---|---|---|---|
| 일반 | 280 ~ 900 | 60 ~ 130 | 40 ~ 70 |
| 엘리트 | 1600 ~ 2000 | 130 ~ 200 | 110 ~ 160 |
| 보스 (3페이즈) | 4500 ~ 4800 | 160 ~ 270 | 130 ~ 200 |

---

## 일반 적 (6종)

---

### 1. 저승사자

- **HP**: 320 / **분류**: 일반 / `mythology = "korean"`
- **핵심 메카닉**: 아군 최저 HP 타겟 집중 공격 + 주기적 weak 부여. 죽어가는 영웅을 집요하게 노림.
- **인텐트 패턴** (3턴 순환):
  - 1턴: ATTACK 70 (LOWEST_HP 아군)
  - 2턴: DEBUFF "weak" 2스택 (RANDOM 아군)
  - 3턴: ATTACK 90 (LOWEST_HP 아군)
- **인카운터 구성**: 단일 / 2마리
- **시너지 포인트**: 이순신 필사즉생 빌드(저HP 강화) 시 저승사자의 타겟이 이순신에게 집중 → 역이용 가능.
- **밸런스 메모**: HP 낮아 빠른 처치 가능. 2마리 조합에서 최저 HP 집중 × 2회로 위협 급등. 약화 해제 수단 없으면 weak 누적이 장기전 딜 감소 유발.

---

### 2. 처용

- **HP**: 450 / **분류**: 일반
- **핵심 메카닉**: 자기 방어도 적극 쌓기 + 방어도 유지 중 강타. 귀신 쫓는 무도 특유의 견고함.
- **인텐트 패턴** (3턴 순환):
  - 1턴: BUFF "block +40" (자신)
  - 2턴: ATTACK 100 (RANDOM)
  - 3턴: ATTACK 120 (RANDOM) + BUFF "block +20" (자신)
- **인카운터 구성**: 단일 / 저승사자 + 처용
- **시너지 포인트**: 방어도 돌파 필요 → 나폴레옹 고화력 카드 우선도 증가. 클레오파트라 POISON은 방어도 무시.
- **밸런스 메모**: HP 450은 1~2방으로 처치 불가. 방어도 40~60을 넘는 공격 집중 or POISON 관통이 효율적. 저승사자+처용 조합: 최저 HP 집중 + 방어도 아군의 이중 압박.

---

### 3. 도깨비

- **HP**: 380 / **분류**: 일반
- **핵심 메카닉**: 자기 strength 누적 + vulnerable 부여. 도깨비 횃불로 아군을 취약하게 만든 뒤 강타.
- **인텐트 패턴** (3턴 순환):
  - 1턴: BUFF "strength +1" (자신)
  - 2턴: DEBUFF "vulnerable" 2스택 (RANDOM)
  - 3턴: ATTACK 90 (RANDOM) *(strength 적용)*
- **인카운터 구성**: 2마리 / 구미호 + 도깨비
- **시너지 포인트**: vulnerable 부여 후 strength 강타 → 방어도 없는 영웅 집중 피해. 클레오파트라 DEBUFF 시너지와 겹침.
- **밸런스 메모**: 3턴 사이클. 단독 위협은 낮지만 2마리 조합 시 vulnerable 2회 부여(4스택) + 강타 2회로 위험. HP 낮아 우선 처치 가능.

---

### 4. 삼족오

- **HP**: 280 / **분류**: 일반
- **핵심 메카닉**: 매 2턴마다 전체 광역 공격. HP 낮으나 놔두면 전체 피해 누적. 태양의 화염.
- **인텐트 패턴** (2턴 순환):
  - 1턴: BUFF "strength +1" (자신)
  - 2턴: ATTACK 60 (ALL 아군) *(전체 광역)*
- **인카운터 구성**: 2마리 / 저승사자 + 삼족오
- **시너지 포인트**: 전체 광역 → 이순신 진형(Formation) 방어도 자동 발동 조건 충족. 학익진 빌드 유도.
- **밸런스 메모**: HP 280 = 집중 공격 1방으로 처치 가능. 삼족오 2마리 시 광역 120 + 120 = 240 전체 피해(strength 없을 때). 낮은 HP이지만 방치하면 팀 전체 출혈. 처치 우선도 판단 요구.

---

### 5. 구미호

- **HP**: 350 / **분류**: 일반
- **핵심 메카닉**: vulnerable + weak 동시 부여. 이집트 메두사 계열이지만 더 빠른 주기로 디버프 쌓기.
- **인텐트 패턴** (3턴 순환):
  - 1턴: DEBUFF "vulnerable" 1스택 (RANDOM)
  - 2턴: ATTACK 80 (RANDOM)
  - 3턴: DEBUFF "weak" 2스택 (RANDOM) + ATTACK 60 (RANDOM)
- **인카운터 구성**: 단일 / 구미호 + 도깨비
- **시너지 포인트**: 구미호 weak → 아군 공격력 감소 상태에서 도깨비 vulnerable → 받는 피해 증가 콤보. 클레오파트라 POISON이 방어도 우회해 구미호를 빠르게 처치 가능.
- **밸런스 메모**: HP 낮아 빠른 처치가 답. 처치 늦으면 weak+vulnerable 동시 중첩으로 아군 효율 급락. 이집트 메두사(고HP 장기형)와 달리 단기전 강요.

---

### 6. 불가사리

- **HP**: 900 / **분류**: 일반
- **핵심 메카닉**: 고HP 탱커 + strength 자가 누적. 금속을 먹고 커지는 전설 반영 — 버티면 버틸수록 강해짐.
- **인텐트 패턴** (3턴 순환):
  - 1턴: BUFF "strength +2" (자신)
  - 2턴: ATTACK 100 (RANDOM)
  - 3턴: ATTACK 130 (RANDOM) *(strength 적용 누적)*
- **인카운터 구성**: 단일
- **시너지 포인트**: 장기전 경고 — 빠른 처치 못 하면 strength 쌓여 공격력 급등. 나폴레옹 사기 폭발 고화력 or 클레오파트라 POISON 지속이 카운터.
- **밸런스 메모**: HP 900 = 일반 적 최고. strength 2 누적 시 공격 130+α. 첫 턴 BUFF만 본다면 선제 처치 2~3방이 최적. 처치 못 하면 후반 130+ 공격이 빠른 HP 소모 유발.

---

### 인카운터 조합 (encounters() 배열)

```
1. [저승사자]
2. [저승사자 × 2]
3. [처용]
4. [저승사자, 처용]
5. [도깨비 × 2]
6. [삼족오 × 2]
7. [구미호]
8. [구미호, 도깨비]
9. [불가사리]
10. [저승사자, 삼족오]
11. [도깨비 × 2, 삼족오]
```

---

## Act 1 엘리트 (3종) + 보스 (1종)

---

### 7. 해치

- **HP**: 1600 / **분류**: 엘리트 / `charm_resistance = 1`
- **핵심 메카닉**: 법의 신수. 매 턴 높은 방어도 적립 + 4턴째 모든 방어도를 소진하는 강타. 방어도 파괴가 핵심 도전.
- **인텐트 패턴** (4턴 순환):
  - 1턴: BUFF "block +60" (자신)
  - 2턴: DEBUFF "vulnerable" 2스택 (RANDOM)
  - 3턴: BUFF "block +60" (자신) + BUFF "strength +1"
  - 4턴: ATTACK 180 (RANDOM) *(방어도 소진 후 강타)*
- **밸런스 메모**: 4턴 사이클 → 3턴 내 최소 120 피해로 방어도 선제 파괴 or 4턴 공격 180 + vulnerable로 위험. strength 1 적용 시 180 + α. 이순신 COUNTER_BLOCK(방어도 피해 반사) 유효.

---

### 8. 장승

- **HP**: 1700 / **분류**: 엘리트 / `charm_resistance = 1`
- **핵심 메카닉**: 마을 수호 장승이 저주 기둥으로 변질. 전체 아군에 디버프를 지속 부여하며 최저 HP를 집중 강타.
- **인텐트 패턴** (3턴 순환):
  - 1턴: DEBUFF "vulnerable" 2스택 (ALL 아군)
  - 2턴: ATTACK 150 (LOWEST_HP 아군)
  - 3턴: DEBUFF "weak" 2스택 (ALL 아군) + ATTACK 120 (RANDOM)
- **밸런스 메모**: 1턴 vulnerable 전체 → 2턴 최저 HP 150 강타(vulnerable 적용 = 225). 이순신 저HP 전략과 충돌 — 필사즉생 의도적 저HP 유지가 위험해짐.

---

### 9. 삼신할머니

- **HP**: 1800 / **분류**: 엘리트 / `charm_resistance = 1`
- **핵심 메카닉**: 출산·운명의 신이 저주의 실을 부여. 지속 poison + 취약 상태로 팀 전체를 서서히 약화.
- **인텐트 패턴** (3턴 순환):
  - 1턴: DEBUFF "poison" 3스택 (RANDOM 아군)
  - 2턴: DEBUFF "poison" 3스택 (ALL 아군)
  - 3턴: ATTACK 160 (RANDOM) + DEBUFF "vulnerable" 2스택 (RANDOM)
- **밸런스 메모**: 이집트 엘리트의 이집트 poison 특화와 겹칠 수 있으나 한국은 poison이 보조 수단. 주 차별점은 ALL 대상 poison 2턴 연속. 클레오파트라 POISON_BURST가 아군 poison도 소모하는지 확인 필요(구현 이슈).

---

### 보스: 해모수 (태양신)

- **HP**: 4500 / **페이즈**: 3 (Phase 0→1: 66% / Phase 1→2: 33%)
- **핵심 메카닉**: 고구려 천제 해모수. 태양 에너지를 축적해 페이즈마다 strength가 쌓이는 누적형 보스. 빠른 처치가 관건.
- `charm_resistance = 2`, `phase_thresholds = [0.66, 0.33]`

---

**Phase 0** (HP 4500 → 2970 / 100%~66%)
패턴 2턴 순환:
- 1턴: ATTACK 160 (RANDOM) + BUFF "strength +1" (자신)
- 2턴: ATTACK 130 (ALL 아군)

---

**Phase 1** (HP 2970 → 1485 / 66%~33%)
페이즈 전환 시: BUFF "strength +2" (자신) 즉발
패턴 3턴 순환:
- 1턴: ATTACK 200 (RANDOM)
- 2턴: ATTACK 160 (ALL 아군)
- 3턴: ATTACK 180 (LOWEST_HP) + DEBUFF "vulnerable" 2스택 (RANDOM)

---

**Phase 2** (HP 1485 → 0 / 33%~0%)
페이즈 전환 시: BUFF "strength +3" (자신) 즉발
패턴 2턴 순환:
- 1턴: ATTACK 240 (LOWEST_HP) + DEBUFF "vulnerable" 2스택 (ALL)
- 2턴: ATTACK 200 (ALL 아군)

---

**밸런스 메모**: Phase 2 진입 시 strength 누적 총 6. ATTACK 240 × (1 + 0.2×6) = 240 × 2.2 = 528은 너무 강함. 구현 시 strength 곱셈 기준 재검토 필요. Phase 0에서 최대한 빠른 딜이 최선 전략.

---

## Act 2 엘리트 (3종) + 보스 (1종)

*(Act 2 모든 수치는 Act 1 기준. `_apply_act_difficulty()`가 HP ×1.3, ATK ×1.2 자동 적용)*

---

### 10. 도깨비 대장

- **HP**: 1800 / **분류**: 엘리트 / `charm_resistance = 1`
- **핵심 메카닉**: 도깨비 일반 적의 강화형. strength 급속 누적 + 광역 강타. 방어 위주 빌드에 큰 위협.
- **인텐트 패턴** (3턴 순환):
  - 1턴: BUFF "strength +2" (자신) + BUFF "block +30"
  - 2턴: ATTACK 170 (RANDOM)
  - 3턴: ATTACK 150 (ALL 아군) *(strength 적용 광역)*

---

### 11. 용왕의 장군

- **HP**: 1900 / **분류**: 엘리트 / `charm_resistance = 1`
- **핵심 메카닉**: 동해 용왕 수하. 매 턴 strength를 쌓으며 점점 강해지는 공격. 빠른 처치 강요.
- **인텐트 패턴** (3턴 순환):
  - 1턴: BUFF "strength +2" (자신)
  - 2턴: ATTACK 160 (RANDOM)
  - 3턴: ATTACK 140 (ALL 아군) + BUFF "strength +1"

---

### 12. 저승 포졸

- **HP**: 1700 / **분류**: 엘리트 / `charm_resistance = 1`
- **핵심 메카닉**: 저승사자 부하. weak 전체 부여 + 최저 HP 집중 공격. 한국 테마 시그니처 "최저 HP 타겟"을 엘리트급으로 강화.
- **인텐트 패턴** (4턴 순환):
  - 1턴: ATTACK 140 (LOWEST_HP)
  - 2턴: DEBUFF "weak" 3스택 (ALL 아군)
  - 3턴: ATTACK 140 (LOWEST_HP)
  - 4턴: ATTACK 170 (LOWEST_HP) + DEBUFF "vulnerable" 2스택 (RANDOM)

---

### 보스: 동명성왕 (고구려 시조)

- **HP**: 4800 / **페이즈**: 3 (Phase 0→1: 66% / Phase 1→2: 33%)
- **핵심 메카닉**: 해모수의 아들, 고구려 건국자. 활 사격 다중 공격 기반. 북유럽 strength형과 유사하지만 다중 타격 패턴이 특색.
- `charm_resistance = 2`, `phase_thresholds = [0.66, 0.33]`

---

**Phase 0** (100%~66%)
패턴 2턴 순환:
- 1턴: ATTACK 90 (RANDOM) → ATTACK 90 (RANDOM) *(활 2연사)*
- 2턴: BUFF "strength +1" + BUFF "block +40"

---

**Phase 1** (66%~33%)
전환 시: BUFF "strength +2" 즉발
패턴 3턴 순환:
- 1턴: ATTACK 140 (RANDOM) → ATTACK 140 (RANDOM)
- 2턴: ATTACK 160 (ALL 아군)
- 3턴: ATTACK 120 (LOWEST_HP) + DEBUFF "vulnerable" 2스택 (RANDOM)

---

**Phase 2** (33%~0%)
전환 시: BUFF "strength +3" 즉발 *(용마 소환 연출)*
패턴 2턴 순환:
- 1턴: ATTACK 200 (RANDOM) → ATTACK 200 (RANDOM)
- 2턴: ATTACK 180 (ALL 아군) + BUFF "strength +2"

---

**밸런스 메모**: 다중 타격 → BLOCK 분산 소모. 이순신 COUNTER_BLOCK 카드가 각 히트마다 반사한다면 강력. Phase 2 연타는 BLOCK 없으면 1턴 400 피해. 우선 방어 후 Phase 2 전환 전 처치 목표.

---

## Act 3 엘리트 (3종) + 보스 (1종)

*(Act 3: HP ×1.6, ATK ×1.4 자동 적용)*

---

### 13. 저승 판관

- **HP**: 1900 / **분류**: 엘리트 / `charm_resistance = 1`
- **핵심 메카닉**: 저승 심판. 매 턴 "죄의 판결" — vulnerable 전체 부여 + 최저 HP에 강타.
- **인텐트 패턴** (3턴 순환):
  - 1턴: DEBUFF "vulnerable" 2스택 (ALL) + ATTACK 140 (LOWEST_HP)
  - 2턴: ATTACK 180 (RANDOM)
  - 3턴: ATTACK 160 (ALL) + DEBUFF "weak" 2스택 (ALL)

---

### 14. 갓신

- **HP**: 2000 / **분류**: 엘리트 / `charm_resistance = 1`
- **핵심 메카닉**: 집안의 수호신이 강림. 최고 HP의 일반형 엘리트. 방어도 + strength 동시 누적.
- **인텐트 패턴** (3턴 순환):
  - 1턴: BUFF "strength +2" (자신) + BUFF "block +40"
  - 2턴: ATTACK 180 (RANDOM)
  - 3턴: ATTACK 200 (LOWEST_HP)

---

### 15. 처용신

- **HP**: 1800 / **분류**: 엘리트 / `charm_resistance = 1`
- **핵심 메카닉**: 처용의 신격화. 방어도 + 이중 디버프 → 4턴째 집중 강타. 처용 일반 적과 동일 방어 메카닉이지만 디버프 축 추가.
- **인텐트 패턴** (4턴 순환):
  - 1턴: BUFF "block +50"
  - 2턴: DEBUFF "weak" 2스택 (RANDOM) + DEBUFF "vulnerable" 2스택 (RANDOM)
  - 3턴: ATTACK 170 (RANDOM)
  - 4턴: ATTACK 190 (LOWEST_HP)

---

### 보스: 염라대왕 (저승왕)

- **HP**: 4800 / **페이즈**: 3 (Phase 0→1: 66% / Phase 1→2: 33%)
- **핵심 메카닉**: 저승의 최고 지배자. 판결과 심판 주제. 팀 전체 약화 후 최저 HP 집중 처형 → 한국 신화 테마의 정점.
- `charm_resistance = 2`, `phase_thresholds = [0.66, 0.33]`

---

**Phase 0** (100%~66%)
패턴 3턴 순환:
- 1턴: DEBUFF "vulnerable" 2스택 (ALL) + DEBUFF "weak" 2스택 (ALL)
- 2턴: ATTACK 200 (LOWEST_HP)
- 3턴: BUFF "strength +2" + ATTACK 160 (RANDOM)

---

**Phase 1** (66%~33%)
전환 시: BUFF "strength +3" 즉발
패턴 3턴 순환:
- 1턴: DEBUFF "vulnerable" 3스택 (ALL)
- 2턴: ATTACK 230 (LOWEST_HP) *(처형 판결)*
- 3턴: ATTACK 190 (ALL) + DEBUFF "weak" 2스택 (ALL)

---

**Phase 2** (33%~0%)
전환 시: BUFF "strength +3" 추가 즉발
패턴 2턴 순환:
- 1턴: ATTACK 270 (LOWEST_HP) + DEBUFF "vulnerable" 3스택 (ALL) *(최종 판결)*
- 2턴: ATTACK 210 (ALL)

---

**밸런스 메모**: Phase 2 ATTACK 270은 전체 strength 6 적용 시 과도. 실제 구현 시 strength 적용 배율 조정 필요. 전략: Phase 1 전환 전 30% 미만 체력 상태에서 속공이 최선. 최저 HP 타겟 집중 → 필사즉생 빌드 역이용이 유일한 카운터 전략.

---

## 구현 메모

- **LOWEST_HP 타겟**: IntentResource.TargetType.LOWEST_HP 존재 여부 구현 PR에서 확인. 없으면 추가 필요.
- **한국 신화 모듈 함수명 제안** (normals.gd):
  - `death_reaper()`, `cheoyong()`, `dokkaebi()`, `three_legged_crow()`, `gumiho()`, `bulgasari()`
- **Act 보스 함수명**:
  - act1: `haemosu()` / act2: `dongmyeong()` / act3: `yeomlra()` (혹은 `king_yama()`)
- **엘리트 함수명**:
  - act1: `haechi()`, `jangseung()`, `samsin_grandma()`
  - act2: `dokkaebi_chief()`, `sea_dragon_general()`, `underworld_constable()`
  - act3: `underworld_judge()`, `gat_spirit()`, `cheoyong_god()`
