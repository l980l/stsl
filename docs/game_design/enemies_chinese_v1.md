# 챕터 2 중국 신화 적 기획 v1

## 테마 시그니처

**주 테마 — "천계·변신"**
적들이 페이즈 전환 또는 특정 조건에서 인텐트 패턴을 전면 교체한다. 엘리트·보스는 하위 병사를 소환하며 계급 구조로 위협이 쌓인다.
기존 신화와 차별점: 그리스=strength 광역 / 이집트=poison·카드 제거 / 북유럽=strength 누적 / 한국=LOWEST_HP 타겟+고방어
→ 중국=**페이즈 전환 패턴 교체 + 계급 소환 구조**. 칭기즈칸의 전진 명령·대칸의 명령 카드와 연계 긴장감 유발.

**부 테마 — "계급 스케일링"**
소환된 하급 천병(天兵)·졸개는 HP가 낮지만 연속 공격 다수. 엘리트·보스 소환 패턴을 포함한 Act 보스 3종에 반영.

> **구현 주의**: 중국 엘리트·보스 "소환" 메커니즘은 intent_pattern의 SUMMON 타입 or 특수 인텐트로 표현하되, 현재 SUMMON은 아군용(SUMMON_TOKEN). 적 소환은 보스 페이즈 전환 인텐트에서 "고화력 연속 공격"으로 소환 연출을 대체하고 구현 PR에서 확인.

---

## 스케일 기준

(Act 1 기준 수치. `_apply_act_difficulty()`가 Act 2 × HP 1.3·ATK 1.2, Act 3 × HP 1.6·ATK 1.4 자동 적용)

| 구분 | HP | 단타 | 광역 |
|---|---|---|---|
| 일반 | 280 ~ 500 | 60 ~ 120 | 40 ~ 70 |
| 엘리트 | 1600 ~ 1900 | 140 ~ 200 | 110 ~ 160 |
| 보스 (3페이즈) | 4500 ~ 4800 | 160 ~ 270 | 130 ~ 200 |

---

## 일반 적 (6종)

---

### 1. 야차(夜叉)

- **HP**: 340 / **분류**: 일반 / `mythology = "chinese"`
- **핵심 메카닉**: 하늘의 수문 수호병. 빠른 단일 공격 위주. 처치가 쉽지만 2마리 조합 시 다중 타격으로 방어도 분산 소모.
- **인텐트 패턴** (3턴 순환):
  - 1턴: ATTACK 70 (RANDOM)
  - 2턴: BUFF "strength +1" (자신)
  - 3턴: ATTACK 90 (RANDOM) *(strength 적용)*
- **인카운터 구성**: 단일 / 야차 × 2 / 야차 + 나타 병사
- **시너지 포인트**: strength 누적 → 처치 딜레이 시 위험. 나폴레옹 사기 고화력으로 선처치 유도.
- **밸런스 메모**: HP 340은 빠른 처치 가능. strength 1 적용 시 90 × 1.2 = 108. 2마리 조합에서 216 피해/턴 가능.

---

### 2. 나타 병사(哪吒兵)

- **HP**: 280 / **분류**: 일반
- **핵심 메카닉**: 나타의 분신술 병사. 매 턴 같은 적에게 이중 타격. 낮은 단타지만 방어도를 두 히트로 분산 소모.
- **인텐트 패턴** (2턴 순환):
  - 1턴: ATTACK 50 (RANDOM) → ATTACK 50 (RANDOM) *(동일 또는 다른 대상, 구현 시 확인)*
  - 2턴: BUFF "strength +1" (자신)
- **인카운터 구성**: 나타 병사 × 2 / 야차 + 나타 병사
- **시너지 포인트**: 이중 타격 → 이순신 COUNTER_BLOCK 발동 횟수 증가. 무사시 히트 카운트 빌드와 대칭적.
- **밸런스 메모**: HP 최저급. 집중 공격으로 즉시 처치 가능. 2마리 시 4히트/턴 → BLOCK 분산 소모 주의.

---

### 3. 사대천왕 병사(四大天王兵)

- **HP**: 450 / **분류**: 일반
- **핵심 메카닉**: 사대천왕 수하의 중무장 병사. 높은 방어도 + 중타격. 한국 처용과 유사하나 더 공격적인 교체 패턴.
- **인텐트 패턴** (3턴 순환):
  - 1턴: BUFF "block +50" (자신)
  - 2턴: ATTACK 110 (RANDOM)
  - 3턴: ATTACK 90 (RANDOM) + BUFF "block +30" (자신)
- **인카운터 구성**: 단일 / 사대천왕 병사 + 야차
- **시너지 포인트**: 고방어도 돌파 필요 → 클레오파트라 POISON 관통 or 나폴레옹 고화력 집중.
- **밸런스 메모**: 방어도 50~80 누적. 처치 지연 시 공격 누적. POISON이 방어도 무시하므로 클레오파트라 카운터.

---

### 4. 산해경 괴수(山海經 怪獸)

- **HP**: 380 / **분류**: 일반
- **핵심 메카닉**: 기이한 형태의 신화 생물. 아군에게 vulnerable을 지속 부여하며 광역 공격으로 취약한 팀을 강타.
- **인텐트 패턴** (3턴 순환):
  - 1턴: DEBUFF "vulnerable" 2스택 (RANDOM)
  - 2턴: ATTACK 80 (RANDOM)
  - 3턴: ATTACK 60 (ALL) + DEBUFF "vulnerable" 1스택 (ALL)
- **인카운터 구성**: 단일 / 구미호(한국 x) — 산해경 괴수 × 2
- **시너지 포인트**: vulnerable 전체 → 고공격 적과 조합 시 위험. 한국 도깨비(vulnerable + strength)와 유사 콤보 가능.
- **밸런스 메모**: 3턴에 vulnerable ALL + 광역 공격 조합. 방어 없이 맞으면 전체 60 × 1.5 = 90 피해.

---

### 5. 선인 수련생(仙人 修煉生)

- **HP**: 300 / **분류**: 일반
- **핵심 메카닉**: 수련 중 신선 후보. 3턴 동안 strength를 쌓다가 4턴째 폭발적 단일 강타. "변신" 테마의 소형 버전.
- **인텐트 패턴** (4턴 순환):
  - 1턴: BUFF "strength +1" (자신)
  - 2턴: BUFF "strength +1" (자신)
  - 3턴: BUFF "strength +2" (자신)
  - 4턴: ATTACK 120 (RANDOM) *(strength 4 누적 적용)*
- **인카운터 구성**: 선인 수련생 × 2 / 야차 + 선인 수련생
- **시너지 포인트**: 3턴 내 처치 강요. 처치 못하면 4턴 120 × (1 + 0.2×4) = 216 단일 피해.
- **밸런스 메모**: HP 낮아 빠른 처치 가능. 2마리 조합에서 4턴 432 단일 피해. 처치 우선순위 관리 핵심.

---

### 6. 청룡 수호병(靑龍 守護兵)

- **HP**: 520 / **분류**: 일반
- **핵심 메카닉**: 동방 청룡의 수하. 일반 적 최고 HP 탱커. 방어도 + 단일 강타.
- **인텐트 패턴** (3턴 순환):
  - 1턴: BUFF "strength +1" (자신) + BUFF "block +40"
  - 2턴: ATTACK 100 (RANDOM)
  - 3턴: ATTACK 120 (RANDOM) *(strength 적용)*
- **인카운터 구성**: 단일 / 사대천왕 병사 + 청룡 수호병
- **시너지 포인트**: 최고 HP + 방어도 → 장기전 강요. 나폴레옹 사기 소모 폭발기가 카운터.
- **밸런스 메모**: HP 520 + 방어도 40 = 사실상 560 내구도. 2턴마다 100~120 피해. 빠른 돌파가 핵심.

---

### 인카운터 조합 (encounters() 배열)

```
1.  [야차]
2.  [야차 × 2]
3.  [나타 병사 × 2]
4.  [야차, 나타 병사]
5.  [사대천왕 병사]
6.  [사대천왕 병사, 야차]
7.  [산해경 괴수 × 2]
8.  [선인 수련생 × 2]
9.  [청룡 수호병]
10. [산해경 괴수, 야차]
11. [선인 수련생, 사대천왕 병사]
```

---

## Act 1 엘리트 (3종) + 보스 (1종)

---

### 7. 금각 대왕(金角大王)

- **HP**: 1600 / **분류**: 엘리트 / `charm_resistance = 1`
- **핵심 메카닉**: 황금 항아리로 아군을 가두는 요마. 매 2턴마다 전체 vulnerable + 강타. 중국 테마 페이즈 전환 예고편 역할.
- **인텐트 패턴** (4턴 순환):
  - 1턴: BUFF "block +40" (자신) + BUFF "strength +1"
  - 2턴: DEBUFF "vulnerable" 2스택 (ALL)
  - 3턴: ATTACK 160 (RANDOM)
  - 4턴: ATTACK 130 (ALL) + DEBUFF "vulnerable" 2스택 (ALL)
- **밸런스 메모**: 2턴 vulnerable ALL → 3턴 160 강타 (vulnerable 적용 = 240). 방어도 쌓아 장기 유지. 클레오파트라 POISON 우선 처치 or 나폴레옹 4턴 전에 처치.

---

### 8. 은각 대왕(銀角大王)

- **HP**: 1700 / **분류**: 엘리트 / `charm_resistance = 1`
- **핵심 메카닉**: 금각의 쌍둥이. 보검으로 weak 전체 + strength 누적 강타. 공격력 감소 + 자신 강화의 이중 압박.
- **인텐트 패턴** (3턴 순환):
  - 1턴: DEBUFF "weak" 2스택 (ALL)
  - 2턴: BUFF "strength +2" (자신) + ATTACK 140 (RANDOM)
  - 3턴: ATTACK 170 (RANDOM) *(strength 적용)*
- **밸런스 메모**: weak ALL → 아군 공격력 30% 감소. strength 2 후 공격 170 × 1.4 = 238. 2~3턴 내 처치 강요.

---

### 9. 흑풍괴(黑風怪)

- **HP**: 1800 / **분류**: 엘리트 / `charm_resistance = 1`
- **핵심 메카닉**: 검은 바람을 다루는 마귀. vulnerable + 광역 폭풍. 팀 전체 피해를 반복적으로 쌓음.
- **인텐트 패턴** (3턴 순환):
  - 1턴: DEBUFF "vulnerable" 2스택 (RANDOM) + ATTACK 120 (RANDOM)
  - 2턴: ATTACK 150 (ALL) *(광역 폭풍)*
  - 3턴: BUFF "strength +2" (자신) + DEBUFF "vulnerable" 1스택 (ALL)
- **밸런스 메모**: 2턴 ALL 150 → strength 2 적용 후 150 × 1.4 = 210 광역. 이순신 진형 빌드 방어도 소진 위험.

---

### 보스: 치우(蚩尤) — 전쟁신

- **HP**: 4500 / **페이즈**: 3 (Phase 0→1: 66% / Phase 1→2: 33%)
- **핵심 메카닉**: 황제에 맞선 전쟁의 신. 81명의 형제를 거느린 전쟁의 왕. 페이즈마다 무기가 변형되어 인텐트 패턴 전면 교체(천계·변신 테마의 핵심 표현).
- `charm_resistance = 2`, `phase_thresholds = [0.66, 0.33]`

---

**Phase 0 — 청동 창 (100%~66%)**
2턴 순환:
- 1턴: ATTACK 160 (RANDOM) + BUFF "strength +1" (자신)
- 2턴: ATTACK 130 (ALL) *(창 휘두르기)*

---

**Phase 1 — 혈철 도끼 (66%~33%)**
전환 시: BUFF "strength +2" 즉발 *(무기 변신)*
3턴 순환:
- 1턴: ATTACK 200 (RANDOM)
- 2턴: ATTACK 160 (ALL) + DEBUFF "vulnerable" 2스택 (RANDOM)
- 3턴: ATTACK 180 (RANDOM) → ATTACK 180 (RANDOM) *(이중 도끼)*

---

**Phase 2 — 천계 혈창 (33%~0%)**
전환 시: BUFF "strength +3" 즉발 *(최종 변신·하늘의 병기)*
2턴 순환:
- 1턴: ATTACK 240 (RANDOM) + DEBUFF "vulnerable" 3스택 (ALL)
- 2턴: ATTACK 200 (ALL) + BUFF "strength +2"

---

**밸런스 메모**: Phase 2 strength 총 6. ATTACK 240 × 2.2 = 528 단일. 과도 시 strength 적용 배율 조정 필요. 전략: Phase 1 이중 도끼 전에 처치 목표. 클레오파트라 POISON + 칭기즈칸 DMG ALL 조합이 Phase 0 빠른 소모에 유효.

---

## Act 2 엘리트 (3종) + 보스 (1종)

*(Act 2 모든 수치는 Act 1 기준. `_apply_act_difficulty()`가 HP ×1.3, ATK ×1.2 자동 적용)*

---

### 10. 홍해아(紅孩兒)

- **HP**: 1800 / **분류**: 엘리트 / `charm_resistance = 1`
- **핵심 메카닉**: 우마왕의 아들. 화염 광역 특화. 매 3턴마다 삼매진화(三昧眞火) — 강력한 ALL 피해.
- **인텐트 패턴** (3턴 순환):
  - 1턴: BUFF "strength +1" (자신)
  - 2턴: ATTACK 150 (RANDOM)
  - 3턴: ATTACK 170 (ALL) *(삼매진화 광역)*

---

### 11. 구룡 차장(九龍 車將)

- **HP**: 1900 / **분류**: 엘리트 / `charm_resistance = 1`
- **핵심 메카닉**: 9마리 용이 끄는 수레 장군. strength 빠른 누적 + 단일 초강타. 빠른 처치 강요.
- **인텐트 패턴** (4턴 순환):
  - 1턴: BUFF "strength +2" (자신) + BUFF "block +30"
  - 2턴: ATTACK 160 (RANDOM)
  - 3턴: BUFF "strength +2" (자신)
  - 4턴: ATTACK 220 (RANDOM) *(strength 4 적용)*

---

### 12. 천구 형제(天狗 兄弟)

- **HP**: 1700 / **분류**: 엘리트 / `charm_resistance = 1`
- **핵심 메카닉**: 하늘의 개 형제(쌍둥이 연출). 빠른 이중 타격 + vulnerable 연속 부여. 나타 병사의 엘리트 버전.
- **인텐트 패턴** (3턴 순환):
  - 1턴: ATTACK 130 (RANDOM) → ATTACK 130 (RANDOM) *(이중 타격)*
  - 2턴: DEBUFF "vulnerable" 2스택 (RANDOM) + DEBUFF "vulnerable" 1스택 (RANDOM)
  - 3턴: ATTACK 160 (LOWEST_HP) + DEBUFF "weak" 2스택 (RANDOM)

---

### 보스: 이랑신(二郎神)

- **HP**: 4800 / **페이즈**: 3 (Phase 0→1: 66% / Phase 1→2: 33%)
- **핵심 메카닉**: 세 눈의 도교 신. 천군(天軍) 지휘관. Phase 2에서 천군 소환(고연속 공격으로 표현). 중국 테마 계급 소환 시스템의 대표 보스.
- `charm_resistance = 2`, `phase_thresholds = [0.66, 0.33]`

---

**Phase 0 — 지휘 (100%~66%)**
3턴 순환:
- 1턴: BUFF "strength +1" + BUFF "block +40"
- 2턴: ATTACK 170 (RANDOM)
- 3턴: ATTACK 140 (ALL)

---

**Phase 1 — 삼안 개안 (66%~33%)**
전환 시: BUFF "strength +2" 즉발 *(제3의 눈 개방)*
3턴 순환:
- 1턴: ATTACK 200 (RANDOM)
- 2턴: ATTACK 160 (ALL) + DEBUFF "vulnerable" 2스택 (RANDOM)
- 3턴: ATTACK 180 (LOWEST_HP) + BUFF "strength +1"

---

**Phase 2 — 천군 강림 (33%~0%)**
전환 시: BUFF "strength +3" 즉발 *(천군 소환 연출: 연속 고공격)*
2턴 순환:
- 1턴: ATTACK 180 (RANDOM) → ATTACK 180 (RANDOM) *(천군 이중 공격)*
- 2턴: ATTACK 220 (ALL) + DEBUFF "vulnerable" 2스택 (ALL)

---

**밸런스 메모**: Phase 2 이중 공격 + 광역 조합. 이중 공격 → BLOCK 분산 소모. Phase 1 전에 처치 목표. 잔다르크 HEAL_ALL + 이순신 BLOCK 빌드로 Phase 2 생존 가능.

---

## Act 3 엘리트 (3종) + 보스 (1종)

*(Act 3: HP ×1.6, ATK ×1.4 자동 적용)*

---

### 13. 백호 신장(白虎 神將)

- **HP**: 1900 / **분류**: 엘리트 / `charm_resistance = 1`
- **핵심 메카닉**: 서방 백호의 신장. strength 급속 누적 + 단일 초강타. 처치 딜레이 시 위험.
- **인텐트 패턴** (3턴 순환):
  - 1턴: BUFF "strength +3" (자신)
  - 2턴: ATTACK 180 (RANDOM) *(strength 적용)*
  - 3턴: ATTACK 160 (RANDOM) + BUFF "strength +1"

---

### 14. 주작 신장(朱雀 神將)

- **HP**: 2000 / **분류**: 엘리트 / `charm_resistance = 1`
- **핵심 메카닉**: 남방 주작의 신장. 화염 광역 + vulnerable 이중 압박. 흑풍괴의 Act 3 강화판.
- **인텐트 패턴** (3턴 순환):
  - 1턴: DEBUFF "vulnerable" 2스택 (ALL)
  - 2턴: ATTACK 180 (ALL) *(주작의 화염)*
  - 3턴: ATTACK 200 (RANDOM) + BUFF "strength +2"

---

### 15. 현무 신장(玄武 神將)

- **HP**: 1800 / **분류**: 엘리트 / `charm_resistance = 1`
- **핵심 메카닉**: 북방 현무의 신장. 방어도 최대 + 강타. 사대천왕 병사의 엘리트 완성형.
- **인텐트 패턴** (4턴 순환):
  - 1턴: BUFF "block +70"
  - 2턴: DEBUFF "weak" 3스택 (ALL)
  - 3턴: BUFF "block +50" + BUFF "strength +2"
  - 4턴: ATTACK 210 (RANDOM) *(방어도 소진 후 강타)*

---

### 보스: 옥황상제(玉皇上帝) — 하늘의 황제

- **HP**: 4800 / **페이즈**: 3 (Phase 0→1: 66% / Phase 1→2: 33%)
- **핵심 메카닉**: 도교 최고신. "계급" 테마의 정점. Phase 3에서 사신(四神) 전군 소환 인텐트(연속 다중 공격으로 표현). 중국 신화 최종 보스.
- `charm_resistance = 2`, `phase_thresholds = [0.66, 0.33]`

---

**Phase 0 — 천제 어좌 (100%~66%)**
3턴 순환:
- 1턴: BUFF "block +50" + BUFF "strength +1"
- 2턴: ATTACK 190 (RANDOM)
- 3턴: ATTACK 160 (ALL) + DEBUFF "vulnerable" 2스택 (RANDOM)

---

**Phase 1 — 옥황 분노 (66%~33%)**
전환 시: BUFF "strength +2" 즉발 + 방어도 완전 제거*(분노의 용포 개방)*
3턴 순환:
- 1턴: ATTACK 220 (RANDOM) + DEBUFF "vulnerable" 2스택 (ALL)
- 2턴: ATTACK 190 (ALL)
- 3턴: ATTACK 200 (LOWEST_HP) + DEBUFF "weak" 3스택 (ALL)

---

**Phase 2 — 사신 강림 (33%~0%)**
전환 시: BUFF "strength +3" 즉발 *(사신 전원 소환: 연속 사중 공격으로 표현)*
2턴 순환:
- 1턴: ATTACK 160 (RANDOM) → ATTACK 160 (RANDOM) → ATTACK 160 (RANDOM) → ATTACK 160 (RANDOM) *(사신 4회 연속)*
- 2턴: ATTACK 220 (ALL) + DEBUFF "vulnerable" 3스택 (ALL) + BUFF "strength +2"

---

**밸런스 메모**: Phase 2 사신 4회 연속 160 = 640 단일 총 피해(strength 적용 전). 분산 히트이므로 BLOCK이 4번 소모됨 주의. 구현 시 각 히트가 독립적 BLOCK 소모인지 확인. 전략: Phase 1 진입 전 속공 처치가 이상적.

---

## 구현 메모

- **mythology 필드**: 모든 적에 `e.mythology = "chinese"` 설정.
- **이중 타격**: 나타 병사·천구 형제·치우 Phase 1 이중 도끼는 기존 `hit_count` 패턴(M5 칭기즈칸)과 유사하게 IntentResource 2개 순차 or `hit_count=2` 활용. 구현 PR에서 확인.
- **함수명 제안** (chinese_normals.gd):
  - `yaksha()`, `nezha_soldier()`, `heavenly_king_soldier()`, `shanhaijing_beast()`, `immortal_trainee()`, `azure_dragon_guard()`
- **Act 보스 함수명**:
  - act1: `chiyou()` / act2: `erlang_shen()` / act3: `jade_emperor()`
- **엘리트 함수명**:
  - act1: `golden_horn_king()`, `silver_horn_king()`, `black_wind_demon()`
  - act2: `red_boy()`, `nine_dragon_general()`, `heavenly_hound_brothers()`
  - act3: `white_tiger_general()`, `vermilion_bird_general()`, `black_tortoise_general()`
