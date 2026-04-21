# 챕터 2 일본 신화 적 기획 v1

## 테마 시그니처

**주 테마 — "요괴·정밀 타격"**
적들이 단일 타겟 고피해(SINGLE_TARGET HIGH_DMG)에 집중하며, 공격·방어 교차 리듬으로 플레이어에게 타이밍을 강요한다.
기존 신화와 차별점: 한국=LOWEST_HP+장기 약화 / 중국=페이즈 전환+소환
→ 일본=**단일 타겟 집중 강타 + 공격-방어 리듬 + 다중 상태이상 동시 부여**. 무사시 결투(enemy_count_1) 빌드와 긴장감 유발.

**부 테마 — "다중 상태이상"**
WEAK + VULNERABLE을 동시에 부여하거나 연속 턴에 걸쳐 쌓아 아군의 공격 효율과 방어를 동시에 약화. 한국이 순차 누적이라면 일본은 동시 부여가 특색.

> **구현 주의**: 일본 적의 "반격(counter-attack)" 인텐트는 별도 시스템 없이 BUFF "block +" + 다음 턴 강타로 표현. 실제 반격 시스템은 이순신 COUNTER_BLOCK 카드 효과를 역이용한 것과 구별됨.

---

## 스케일 기준

(Act 1 기준 수치. `_apply_act_difficulty()`가 Act 2 × HP 1.3·ATK 1.2, Act 3 × HP 1.6·ATK 1.4 자동 적용)

| 구분 | HP | 단타 | 광역 |
|---|---|---|---|
| 일반 | 300 ~ 450 | 65 ~ 130 | 40 ~ 65 |
| 엘리트 | 1600 ~ 1900 | 140 ~ 200 | 110 ~ 160 |
| 보스 (3페이즈) | 4500 ~ 4800 | 160 ~ 260 | 130 ~ 190 |

---

## 일반 적 (6종)

---

### 1. 오니(鬼)

- **HP**: 420 / **분류**: 일반 / `mythology = "japanese"`
- **핵심 메카닉**: 일본 요괴의 대표. 강인한 단일 강타 + strength 누적. 방치하면 공격이 폭발적으로 강해짐.
- **인텐트 패턴** (3턴 순환):
  - 1턴: BUFF "strength +2" (자신)
  - 2턴: ATTACK 100 (RANDOM)
  - 3턴: ATTACK 120 (RANDOM) *(strength 적용)*
- **인카운터 구성**: 단일 / 오니 × 2 / 오니 + 슈텐도지 졸개
- **시너지 포인트**: strength 누적 → 처치 딜레이 시 강타가 위험. 무사시 결투 빌드(적 1마리)에서 오니 단독 조합 시 조건부 강화 카드 최대 효율.
- **밸런스 메모**: 3턴 120 × (1 + 0.4) = 168. 2마리 동시 strength = 4 누적 시 336/턴. 우선 처치 강요.

---

### 2. 텐구(天狗)

- **HP**: 320 / **분류**: 일반
- **핵심 메카닉**: 날개 달린 산의 요괴. 빠른 이중 타격으로 방어도를 두 히트에 분산 소모. 중국 나타 병사와 유사하나 vulnerable 추가로 차별화.
- **인텐트 패턴** (2턴 순환):
  - 1턴: ATTACK 55 (RANDOM) → ATTACK 55 (RANDOM) *(이중 타격)*
  - 2턴: DEBUFF "vulnerable" 1스택 (RANDOM)
- **인카운터 구성**: 텐구 × 2 / 텐구 + 오니
- **시너지 포인트**: vulnerable 부여 후 다음 턴 오니 강타 = 콤보. 이중 타격 → 이순신 COUNTER_BLOCK 다중 발동.
- **밸런스 메모**: 단타 55는 낮지만 이중 110/턴. vulnerable 적용 시 다음 피해 ×1.5. 방어도 없으면 연속 피해로 소모 빠름.

---

### 3. 유키온나(雪女)

- **HP**: 300 / **분류**: 일반
- **핵심 메카닉**: 눈의 정령. WEAK + VULNERABLE을 동시에 부여하여 아군 공격 효율과 방어를 동시 약화. 일본 테마 "다중 상태이상"의 핵심 예시.
- **인텐트 패턴** (3턴 순환):
  - 1턴: DEBUFF "weak" 2스택 (RANDOM) + DEBUFF "vulnerable" 1스택 (RANDOM)
  - 2턴: ATTACK 75 (RANDOM) *(빙결 냉기)*
  - 3턴: DEBUFF "weak" 1스택 (ALL) + ATTACK 65 (RANDOM)
- **인카운터 구성**: 유키온나 × 2 / 유키온나 + 텐구
- **시너지 포인트**: weak+vulnerable 동시 = 아군 공격 -30% + 받는 피해 +50%. 클레오파트라 DEBUFF 빌드와 주제 유사. 방어 우선 전략 유도.
- **밸런스 메모**: HP 최저급이지만 스테이터스 부여가 강력. 2마리 시 매 턴 weak 4스택 + vulnerable 2스택 누적. 우선 처치 필수.

---

### 4. 갓파(河童)

- **HP**: 380 / **분류**: 일반
- **핵심 메카닉**: 강의 요괴. 공격·방어를 교대로 반복하는 리듬형 적. "공격-방어 교차 리듬" 테마의 기본형.
- **인텐트 패턴** (4턴 순환):
  - 1턴: BUFF "block +45" (자신)
  - 2턴: ATTACK 90 (RANDOM)
  - 3턴: BUFF "block +30" (자신) + DEBUFF "vulnerable" 1스택 (RANDOM)
  - 4턴: ATTACK 110 (RANDOM) *(강화 타격)*
- **인카운터 구성**: 갓파 × 2 / 갓파 + 오니
- **시너지 포인트**: 교차 리듬 → 공격 타이밍 예측 가능. 방어도 돌파 필요 → 나폴레옹 집중 화력.
- **밸런스 메모**: 방어도 45~75 누적. 4턴 강타 110 + vulnerable = 165. 주기적 공격 패턴이 예측 가능해 전략적 방어 배치 유도.

---

### 5. 슈텐도지 졸개(酒呑童子 手下)

- **HP**: 350 / **분류**: 일반
- **핵심 메카닉**: 마주(魔酒) 요괴의 수하. 아군에게 WEAK를 부여하고 취기를 타 강타. 슈텐도지 보스의 축소판.
- **인텐트 패턴** (3턴 순환):
  - 1턴: DEBUFF "weak" 2스택 (RANDOM)
  - 2턴: BUFF "strength +1" (자신)
  - 3턴: ATTACK 100 (RANDOM) *(취기 강타, strength 적용)*
- **인카운터 구성**: 슈텐도지 졸개 × 2 / 오니 + 슈텐도지 졸개
- **시너지 포인트**: weak 부여 → 아군 공격 30% 감소. 강타 100 × 1.2(strength) = 120. 2마리 시 weak 4스택 + 강타 2회.
- **밸런스 메모**: weak 부여로 딜 효율 저하가 주 위협. 처치 우선도 높음.

---

### 6. 로닌 망령(浪人 亡靈)

- **HP**: 450 / **분류**: 일반
- **핵심 메카닉**: 주군 없이 떠도는 무사의 망령. 높은 HP + 단일 강타. 일본 적 중 가장 직접적인 피해형.
- **인텐트 패턴** (3턴 순환):
  - 1턴: BUFF "strength +1" (자신) + BUFF "block +30"
  - 2턴: ATTACK 110 (RANDOM)
  - 3턴: ATTACK 130 (RANDOM) *(strength 적용)*
- **인카운터 구성**: 단일 / 로닌 망령 + 갓파
- **시너지 포인트**: 높은 HP + 방어도 + 강타. 나폴레옹 사기 소모 폭발기 or 클레오파트라 POISON 지속딜 카운터.
- **밸런스 메모**: HP 450 + 방어도 30 = 480 내구도. strength 1 후 130 × 1.2 = 156 단일. 단독 등장 시 안정적이나 시간 소모.

---

### 인카운터 조합 (encounters() 배열)

```
1.  [오니]
2.  [오니 × 2]
3.  [텐구 × 2]
4.  [오니, 텐구]
5.  [유키온나 × 2]
6.  [유키온나, 텐구]
7.  [갓파 × 2]
8.  [갓파, 오니]
9.  [슈텐도지 졸개 × 2]
10. [로닌 망령]
11. [슈텐도지 졸개, 유키온나]
```

---

## Act 1 엘리트 (3종) + 보스 (1종)

---

### 7. 오니 장군(鬼 將軍)

- **HP**: 1600 / **분류**: 엘리트 / `charm_resistance = 1`
- **핵심 메카닉**: 오니 일반 적의 강화형. strength 급속 누적 + 단일 초강타. 처치 딜레이 시 위협 폭발.
- **인텐트 패턴** (3턴 순환):
  - 1턴: BUFF "strength +3" (자신) + BUFF "block +30"
  - 2턴: ATTACK 170 (RANDOM) *(strength 적용)*
  - 3턴: ATTACK 150 (RANDOM) + BUFF "strength +1"
- **밸런스 메모**: 첫 2턴에 strength 4 누적 후 170 × 1.8 = 306 단일. 2턴 내 방어도 돌파 + 처치 필요.

---

### 8. 야마우바(山姥)

- **HP**: 1700 / **분류**: 엘리트 / `charm_resistance = 1`
- **핵심 메카닉**: 산의 노파 요괴. WEAK 전체 부여 + 광역 공격 반복. "다중 상태이상" 테마의 엘리트 버전. 유키온나와 달리 광역 공격 강도가 높음.
- **인텐트 패턴** (4턴 순환):
  - 1턴: DEBUFF "weak" 3스택 (ALL) + DEBUFF "vulnerable" 2스택 (RANDOM)
  - 2턴: ATTACK 140 (ALL)
  - 3턴: DEBUFF "weak" 2스택 (ALL)
  - 4턴: ATTACK 170 (RANDOM) + DEBUFF "vulnerable" 2스택 (RANDOM)
- **밸런스 메모**: 1턴 weak ALL 3 → 2턴 140 ALL. 아군 공격 30% 감소 상태에서 팀 전체 피해. 카드 사용 우선순위 교란.

---

### 9. 로닌 무적(浪人 無敵)

- **HP**: 1800 / **분류**: 엘리트 / `charm_resistance = 1`
- **핵심 메카닉**: 전설의 로닌. vulnerable 선부여 + 집중 단일 초강타. 일본 "정밀 타격" 테마의 핵심. 클레오파트라 weak와 조합 시 역할 교차.
- **인텐트 패턴** (4턴 순환):
  - 1턴: DEBUFF "vulnerable" 2스택 (RANDOM)
  - 2턴: BUFF "strength +2" (자신)
  - 3턴: ATTACK 190 (RANDOM) *(vulnerable 대상 집중, strength 적용)*
  - 4턴: BUFF "block +40" + BUFF "strength +1"
- **밸런스 메모**: 1턴 vulnerable → 3턴 190 × 1.2(str) × 1.5(vuln) = 342 단일. vulnerable 대상 영웅 집중 처치 위험. 이순신 방어도 빌드로 취약 대상 보호.

---

### 보스: 라이덴(雷神) — 천둥의 신

- **HP**: 4500 / **페이즈**: 3 (Phase 0→1: 66% / Phase 1→2: 33%)
- **핵심 메카닉**: 일본 천둥신. 공격·방어 교차 리듬의 극단화. Phase마다 공격 방식이 정밀 타격 → 광역 폭풍으로 변화. "요괴·정밀 타격" + "다중 상태이상" 동시 구현.
- `charm_resistance = 2`, `phase_thresholds = [0.66, 0.33]`

---

**Phase 0 — 천둥 집결 (100%~66%)**
3턴 순환:
- 1턴: BUFF "strength +1" + BUFF "block +40"
- 2턴: ATTACK 160 (RANDOM) *(번개 집중 타격)*
- 3턴: DEBUFF "weak" 2스택 (ALL) + DEBUFF "vulnerable" 2스택 (RANDOM)

---

**Phase 1 — 폭풍 해방 (66%~33%)**
전환 시: BUFF "strength +2" 즉발 *(뇌운 개방)*
3턴 순환:
- 1턴: ATTACK 190 (RANDOM) + DEBUFF "vulnerable" 2스택 (RANDOM)
- 2턴: ATTACK 160 (ALL) *(번개 광역)*
- 3턴: DEBUFF "weak" 3스택 (ALL) + ATTACK 140 (LOWEST_HP)

---

**Phase 2 — 뇌제 강림 (33%~0%)**
전환 시: BUFF "strength +3" 즉발 *(뇌제 완전 각성)*
2턴 순환:
- 1턴: ATTACK 200 (RANDOM) + DEBUFF "weak" 2스택 (ALL) + DEBUFF "vulnerable" 2스택 (ALL)
- 2턴: ATTACK 180 (ALL) + BUFF "strength +2"

---

**밸런스 메모**: Phase 2 복합 피해: 단일 200(+디버프) → 다음 턴 ALL 180. weak+vulnerable ALL 동시 부여로 아군 효율 최악. 전략: Phase 1 전환 전 30% 돌파 속공. 칭기즈칸 DMG ALL + 무사시 정밀 타격 조합이 Phase 0 빠른 소모에 유효.

---

## Act 2 엘리트 (3종) + 보스 (1종)

*(Act 2 모든 수치는 Act 1 기준. `_apply_act_difficulty()`가 HP ×1.3, ATK ×1.2 자동 적용)*

---

### 10. 혼돈의 텐구(混沌 天狗)

- **HP**: 1800 / **분류**: 엘리트 / `charm_resistance = 1`
- **핵심 메카닉**: 텐구의 강화형. 빠른 이중 타격 + WEAK·VULNERABLE 동시 부여. 방어도와 공격력 동시 약화로 팀 전체를 위협.
- **인텐트 패턴** (3턴 순환):
  - 1턴: DEBUFF "weak" 2스택 (ALL) + DEBUFF "vulnerable" 2스택 (RANDOM)
  - 2턴: ATTACK 140 (RANDOM) → ATTACK 140 (RANDOM) *(이중 타격)*
  - 3턴: BUFF "strength +2" + ATTACK 160 (RANDOM)

---

### 11. 야샤(夜叉)

- **HP**: 1900 / **분류**: 엘리트 / `charm_resistance = 1`
- **핵심 메카닉**: 불교 호법 요괴. 반격·방어 리듬 전문. 3턴 방어도 쌓다가 4턴 초강타 + 자기 방어도 소진. "공격-방어 교차 리듬" 테마 엘리트.
- **인텐트 패턴** (4턴 순환):
  - 1턴: BUFF "block +60"
  - 2턴: BUFF "strength +2" + BUFF "block +40"
  - 3턴: DEBUFF "vulnerable" 2스택 (ALL)
  - 4턴: ATTACK 210 (RANDOM) *(방어도 소진 강타)*

---

### 12. 누레리온(ぬらりひょん)

- **HP**: 1700 / **분류**: 엘리트 / `charm_resistance = 1`
- **핵심 메카닉**: 요괴의 총수. WEAK 전체 + 강타. 팀 공격력 감소 후 집중 타격. 야마우바와 유사하지만 더 집중형.
- **인텐트 패턴** (3턴 순환):
  - 1턴: DEBUFF "weak" 3스택 (ALL)
  - 2턴: ATTACK 170 (LOWEST_HP)
  - 3턴: ATTACK 150 (RANDOM) + DEBUFF "vulnerable" 2스택 (LOWEST_HP)

---

### 보스: 슈텐도지(酒呑童子) — 요괴의 왕

- **HP**: 4800 / **페이즈**: 3 (Phase 0→1: 66% / Phase 1→2: 33%)
- **핵심 메카닉**: 일본 최강의 요괴. 마주(魔酒)로 점점 취기가 오를수록 강해지는 페이즈 전환형. Phase마다 공격 빈도와 강도 증가. 중국 보스(변신)와 달리 "취기 누적" 서사.
- `charm_resistance = 2`, `phase_thresholds = [0.66, 0.33]`

---

**Phase 0 — 소량 음주 (100%~66%)**
3턴 순환:
- 1턴: BUFF "strength +1" + DEBUFF "weak" 2스택 (RANDOM)
- 2턴: ATTACK 165 (RANDOM)
- 3턴: ATTACK 140 (ALL)

---

**Phase 1 — 만취 (66%~33%)**
전환 시: BUFF "strength +2" 즉발 *(깊은 취기)*
3턴 순환:
- 1턴: DEBUFF "weak" 2스택 (ALL) + DEBUFF "vulnerable" 2스택 (RANDOM)
- 2턴: ATTACK 200 (RANDOM)
- 3턴: ATTACK 175 (ALL) + BUFF "strength +1"

---

**Phase 2 — 요괴 본체 각성 (33%~0%)**
전환 시: BUFF "strength +3" 즉발 *(인간 형태 탈피)*
2턴 순환:
- 1턴: ATTACK 220 (RANDOM) + DEBUFF "vulnerable" 3스택 (ALL)
- 2턴: ATTACK 190 (ALL) + DEBUFF "weak" 3스택 (ALL)

---

**밸런스 메모**: Phase 2 weak 3 + vulnerable 3 = 아군 공격 -30% + 받는 피해 +50% 상태에서 ALL 190. 디버프 해제 수단 없으면 최악. 전략: Phase 1 만취 전환 전 우선 처치. 잔다르크 성수(정화) 카드로 디버프 대응.

---

## Act 3 엘리트 (3종) + 보스 (1종)

*(Act 3: HP ×1.6, ATK ×1.4 자동 적용)*

---

### 13. 아마노이와토 수문장(天岩戸 守門將)

- **HP**: 1900 / **분류**: 엘리트 / `charm_resistance = 1`
- **핵심 메카닉**: 해의 동굴 수문장. 최고 방어도 + LOWEST_HP 집중. 한국 해치와 유사하지만 최저 HP 집중이 추가.
- **인텐트 패턴** (4턴 순환):
  - 1턴: BUFF "block +70" (자신)
  - 2턴: DEBUFF "vulnerable" 2스택 (RANDOM)
  - 3턴: BUFF "block +50" + BUFF "strength +2"
  - 4턴: ATTACK 200 (LOWEST_HP) *(방어도 소진 집중)*

---

### 14. 스사노오의 검(スサノオの劍)

- **HP**: 2000 / **분류**: 엘리트 / `charm_resistance = 1`
- **핵심 메카닉**: 폭풍신 스사노오의 신검 의인화. strength + 이중 강타. 무사시 이도류(hit_count=2) 콘셉트의 적 버전.
- **인텐트 패턴** (3턴 순환):
  - 1턴: BUFF "strength +2"
  - 2턴: ATTACK 180 (RANDOM) → ATTACK 180 (RANDOM) *(이중 강타)*
  - 3턴: ATTACK 200 (LOWEST_HP) + BUFF "strength +1"

---

### 15. 유키온나의 여왕(雪女 女王)

- **HP**: 1800 / **분류**: 엘리트 / `charm_resistance = 1`
- **핵심 메카닉**: 유키온나 일반 적의 여왕형. weak + vulnerable 동시 전체 부여 + 단일 강타. "다중 상태이상" 극단화.
- **인텐트 패턴** (3턴 순환):
  - 1턴: DEBUFF "weak" 3스택 (ALL) + DEBUFF "vulnerable" 3스택 (ALL)
  - 2턴: ATTACK 180 (RANDOM) *(냉기 집중)*
  - 3턴: ATTACK 160 (ALL) + DEBUFF "weak" 2스택 (ALL)

---

### 보스: 야마타노오로치(八岐大蛇) — 여덟 머리 뱀

- **HP**: 4800 / **페이즈**: 3 (Phase 0→1: 66% / Phase 1→2: 33%)
- **핵심 메카닉**: 8개 머리를 가진 전설의 대뱀. Phase마다 머리 수가 줄면서 남은 머리의 공격이 집중·강화. 일본 신화의 최종 보스.
- `charm_resistance = 2`, `phase_thresholds = [0.66, 0.33]`

---

**Phase 0 — 8머리 (100%~66%)**
*(분산 공격 — 많은 머리로 여러 대상 동시 위협)*
3턴 순환:
- 1턴: ATTACK 70 (ALL) *(머리 8개 광역 공격)*
- 2턴: DEBUFF "weak" 2스택 (ALL) + DEBUFF "vulnerable" 2스택 (RANDOM)
- 3턴: BUFF "strength +1" + ATTACK 130 (RANDOM)

---

**Phase 1 — 4머리 (66%~33%)**
전환 시: BUFF "strength +2" 즉발 *(4머리 소멸 → 남은 머리 강화)*
3턴 순환:
- 1턴: ATTACK 160 (RANDOM) → ATTACK 160 (RANDOM) *(이중 집중)*
- 2턴: ATTACK 140 (ALL)
- 3턴: DEBUFF "vulnerable" 3스택 (ALL) + ATTACK 170 (LOWEST_HP)

---

**Phase 2 — 1머리 최종 (33%~0%)**
전환 시: BUFF "strength +4" 즉발 *(단 하나의 머리에 전력 집중)*
2턴 순환:
- 1턴: ATTACK 250 (RANDOM) + DEBUFF "weak" 3스택 (ALL) + DEBUFF "vulnerable" 3스택 (ALL)
- 2턴: ATTACK 200 (ALL) + BUFF "strength +2"

---

**밸런스 메모**: Phase 2 strength 총 7. ATTACK 250 × (1 + 1.4) = 600 과도. 구현 시 strength 스케일링 조정 필요. Phase 0의 8머리 ALL 70은 낮지만 weak+vulnerable 부여로 후반 위험 복선. 전략: Phase 0 → Phase 1 전환 전에 30% HP를 조기 소진하는 속공 빌드가 유효. 나폴레옹 대칸의 명령(COST_ZERO) 빌드가 Phase 0 초반 폭발력 최대화.

---

## 구현 메모

- **mythology 필드**: 모든 적에 `e.mythology = "japanese"` 설정.
- **이중 타격**: 텐구·스사노오의 검·야마타노오로치 Phase 1 이중 공격은 M5 `hit_count=2` 패턴 재사용. 구현 PR에서 IntentResource 처리 방식 확인.
- **함수명 제안** (japanese_normals.gd):
  - `oni()`, `tengu()`, `yuki_onna()`, `kappa()`, `shuten_doji_minion()`, `ronin_ghost()`
- **Act 보스 함수명**:
  - act1: `raiden()` / act2: `shuten_doji()` / act3: `yamata_no_orochi()`
- **엘리트 함수명**:
  - act1: `oni_general()`, `yamauba()`, `ronin_invincible()`
  - act2: `chaos_tengu()`, `yasha()`, `nurarihyon()`
  - act3: `amano_iwato_guard()`, `susanoo_blade()`, `yuki_onna_queen()`
