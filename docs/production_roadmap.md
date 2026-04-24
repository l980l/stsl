# STSL — Production Roadmap

> 작성일: 2026-04-17 (최종 동기화: 2026-04-25 v5)
> 기준: 챕터 1·2 완성 + 영웅 6인 + 번역 인프라 + 덱뷰어 완성 기준
> 범례: ✅ 완료 / 🔲 미완료 / 🔶 부분 완료

---

## 현재 상태 요약

**챕터 1** (그리스·이집트·북유럽 랜덤 배정) 완성. **챕터 2** (한국·중국·일본 랜덤 배정) 완성 (PR #50, #51, #58, #59, #60).
영웅 6인(나폴레옹·이순신·클레오파트라·잔 다르크·칭기즈칸·미야모토 무사시), 영웅당 카드 40장(아키타입 3개).
**챕터 1 Act 1 (그리스)**: 적 10종(일반 6·엘리트 4·보스 히드라), 이벤트 10종, 렐릭 19종.
**챕터 1 Act 2 (이집트)**: 적 10종(일반 6·엘리트 3·보스 오시리스 2페이즈), 이벤트 10종, 전용 렐릭 3종, 난이도 스케일(HP ×1.3, 공격 ×1.2).
**챕터 1 Act 3 (북유럽)**: 적 10종(일반 6·엘리트 3·보스 요르문간드르 3페이즈), 이벤트 10종, 전용 렐릭 3종(총 풀 25종).
**신화 랜덤화**: 매 런마다 Act 1·2·3 신화 배정 셔플 (3! = 6가지). 전 신화 × 전 Act 엘리트 3 + 보스 1 풀 채움(9개 모듈).
**챕터 2 한국 신화**: 일반 적 6종·Act별 엘리트 9·보스 3(단군/삼신할미/구삼승할망)·이벤트 10종·렐릭 3종(풀 28종).
**챕터 2 중국 신화**: 일반 적 6종·Act별 엘리트 9·보스 3(치우/이랑신/반고)·이벤트 10종·렐릭 3종(풀 37종). PR #58, #60.
**챕터 2 일본 신화**: 일반 적 6종·Act별 엘리트 9·보스 3(라이덴/슈텐도지/야마타노오로치)·이벤트 10종·렐릭 3종(풀 40종). PR #59.
**챕터 2 랜덤화**: 한·중·일 3신화 Act 배정 셔플 활성화 (PR #59). 919개 테스트 통과.
**챕터 시스템 인프라**: `ProgressManager` 싱글턴 (`user://progress.json`), 챕터 선택 씬, `current_chapter`/`MAX_CHAPTERS=2` (PR #49).
**병사 토큰 시스템**: SUMMON_TOKEN 효과·병사 6×2 그리드·턴 구조 Pre/Main/Post 3페이즈 (PR #38~#42).
크로스 시너지 6쌍(영웅 6인 기준), Morale/Formation/Charm 시스템 완료. HP 1000 스케일(PR #30).
기획자 도감 자동 생성기(PR #32), 전역 디버그 단축키 11종(PR #34~#35, #61).
영웅 선택 창 리디자인: 컴팩트 카드(290×340)·세로 스크롤·설명 툴팁·일러스트 플레이스홀더 (PR #61).
사운드 에셋 요구사항 문서화 완료 (`docs/sound_assets_required.md`, 131개 파일 정의).
**번역 인프라 구축 완료** (PR #73): CSV 기반 다국어 번역 파일 9종(`strings_battle/card/ui/enemy/status/relic/synergy/event/hero.csv`), Godot 번역 등록 + `autoload/locale_manager.gd` 싱글턴, NotoSansCJK·NotoNaskhArabic 폰트 fallback 체인. 한국어·영어(전투/인텐트) 완료.
**덱 뷰어 완성** (PR #73): 덱·버린카드 2열 그리드, 카드 호버 확대 툴팁, 툴팁 깜빡임 완전 수정(mouse_filter 재귀 IGNORE). 버튼 위치 턴 종료 아래로 이동.
**적 카드 카운터 개선** (PR #73): 발동 후 count 리셋, repeat 재발동 버그 수정, 툴팁 번역키화, UI를 상태 아이콘 영역으로 통합. 1145 테스트 통과.
**전투 UX 개선** (PR #79, #80, #81): 핸드 부채꼴 레이아웃 + 호버 확대(PR #79), 드래그 화살표 베지어 곡선·유효성 색상·흐름 애니메이션(PR #80), 슬롯 위치 Marker2D 기반(에디터 드래그로 조정)·소환 영역 6개 단일 열·더미 몬스터/소환수 디버그 키 Shift+O·S(PR #81). 1080 테스트 통과 (tr() 기반 이름 조회 회귀 39건 별도 추적 중).

---

## Milestone 1 — Act 1 콘텐츠 완성 (현재 단계)

### 1-1. 카드 풀 확장
각 영웅별 40장 고유 카드, 아키타입 3개 (v2 기준, PR #30).

**나폴레옹** (아키타입: 돌격 / 군단 / 지휘)
- ✅ 돌격 아키타입 카드 (저비용 연속 공격, 사기 소모 폭발기)
- ✅ 군단 아키타입 카드 (SUMMON_TOKEN 중심)
- ✅ 지휘 아키타입 카드 (팀 버프·드로우)
- ✅ 사기(Morale) 시스템 구현 (GAIN_MORALE / CONSUME_MORALE / morale_changed 시그널)

**이순신** (아키타입: 거북선 / 학익진 / 필사즉생)
- ✅ 거북선 아키타입 카드 (BLOCK·COUNTER_BLOCK 탱커)
- ✅ 학익진 아키타입 카드 (FORMATION_BLOCK·팀 버프)
- ✅ 필사즉생 아키타입 카드 (HP 소모 → 폭발 피해)
- ✅ 진형(Formation) 시스템 구현 (생존 팀원 수 × 방어도)

**클레오파트라** (아키타입: 독살 / 조종 / 저주)
- ✅ 독살 아키타입 카드 (POISON 누적 + POISON_BURST)
- ✅ 조종 아키타입 카드 (CHARM 부여·활용)
- ✅ 저주 아키타입 카드 (WEAK·VULNERABLE 디버프 누적)
- ✅ 매혹(Charm) 시스템 구현 (CHARM 스택 3 → 적이 다른 적 공격)

### 1-2. 적 추가 (Act 1 — 그리스 신화)

**일반 적** (6종 완료)
- ✅ 사티로스 (80×2, RANDOM)
- ✅ 메두사의 뱀 (ATTACK + DEBUFF vulnerable, HP 300)
- ✅ 사이클롭스 (BUFF 준비 → ATK 200, HP 700)
- ✅ 하르피아 (ATK 45×4 + SPECIAL 카드 버리기, HP 280)
- ✅ 케르베로스 (ATK 70×3 + ATK 90 ALL, HP 900)
- ✅ 미르미돈 병사 (ATK → BUFF strength → ATK → ATK, HP 250)

**엘리트 적** (4종 완료)
- ✅ 미노타우로스 (ATK×2 + ATK ALL, HP 2000)
- ✅ 스킬라 (2페이즈, HP 1900 — 머리 2개→1개, 독 특화)
- ✅ 고르곤 (2페이즈, HP 1800 — 매 턴 취약 부여)
- ✅ 메두사 (ATK + DEBUFF×2 + ATK, HP 1700)

**보스** (목표: 1종 — 히드라)
- ✅ 히드라 (3페이즈, phase_thresholds 구현, HP 4500)
- 🔲 히드라 실제 비주얼 및 페이즈별 연출

### 1-3. 렐릭 확장
- ✅ 공용 렐릭 ~10종
- ✅ 나폴레옹 전용 렐릭 2종 (황제의 인장, 포병 나팔)
- ✅ 이순신 전용 렐릭 2종 (거북선 모형, 난중일기)
- ✅ 클레오파트라 전용 렐릭 2종 (독사의 팔찌, 파라오의 인장)
- ✅ 저주 렐릭 3종 (악마의 계약, 저주받은 왕관, 피의 서약)
- ✅ 캐릭터 생존 조건부 강화 효과 구현 (owner_hero_id + is_alive 체크)

### 1-4. 이벤트 확장
- ✅ 기본 이벤트 5종 (황금 상자, 상처 입은 전사, 고대 도서관, 저주받은 제단, 동료 만남)
- ✅ 그리스 신화 테마 이벤트 5종 추가 (총 10종)
  - 프로메테우스의 불 (DRAW_UP +1, HP -20), 헤라클레스의 시련 (GOLD +60, HP -25)
  - 키르케의 마법 (HEAL +25, GOLD -50), 하데스의 계약 (ADD_RELIC, HP -30)
  - 헤르메스의 도박 (GOLD +50 OR 카드 1장 제거 — 플레이어가 선택)

### 1-5. 상점 보완
- ✅ 상점 카드 목록을 현재 영웅 덱 기반 풀에서 추출
- ✅ 카드 제거 기능 (골드 소모)
- ✅ 렐릭 구매 기능 구현 확인

### 1-6. 크로스 시너지 구현

#### 설계 원칙

**발동 방식:** 팀에 특정 영웅이 살아있으면 카드 효과가 자동으로 변화 (passive, 별도 활성화 불필요).
카드 자체에 "파트너 조건"을 기술. 조건이 충족되면 효과가 변형·강화됨.

**아키타입 연동 원칙:** 각 영웅은 2~3개 아키타입을 보유. 어떤 파트너와 조합하느냐에 따라
서로 다른 아키타입이 활성화됨. 예: 나폴레옹은 이순신과 함께면 '지휘' 아키타입, 클레오파트라와 함께면 '돌격' 아키타입이 더 강해짐.

**목표 커버리지:** 영웅 7명 기준 21조합. 모든 영웅끼리 최소 1개 시너지. (Hades 게임 방식 참고: 8영웅 28조합 중 20조합 이상 지원)

**영웅 영입 방식:** Act 보스 처치 후 랜덤 영웅 3명 중 1명을 선택해 팀에 합류.
→ 매 런마다 다른 시너지 조합이 활성화되어 리플레이어빌리티 보장.

#### UI / 표현

- **HUD 아이콘 + 호버 툴팁:** 현재 활성 시너지 목록을 전투 HUD에 아이콘으로 표시. 마우스 호버 시 시너지 이름·효과 툴팁 표시.
- **마젠타 카드명:** 시너지로 인해 효과가 강화된 카드는 핸드에서 카드명이 마젠타 색으로 강조. 플레이어가 어떤 카드가 버프됐는지 즉시 파악 가능.

#### MVP 3쌍 시너지 (우선 구현 대상)

| 조합 | 시너지 이름 | 효과 |
|---|---|---|
| 나폴레옹 × 이순신 | 철벽 진군 | 나폴레옹의 사기(Morale) 축적이 이순신 진형 발동 조건 충족 시 추가 방어도 부여 |
| 클레오파트라 × 이순신 | 독침 반격 | 클레오파트라의 독(Poison) 스택이 쌓인 적을 이순신이 공격할 때 추가 피해 |
| 나폴레옹 × 클레오파트라 | 혼란의 돌격 | 나폴레옹 사기 소모 카드 사용 시 클레오파트라의 매혹 스택 +1 부여 |

- ✅ 나폴레옹 × 이순신 시너지 구현 (Plan 23)
- ✅ 클레오파트라 × 이순신 시너지 구현 (Plan 23)
- ✅ 나폴레옹 × 클레오파트라 시너지 구현 (Plan 23)
- ✅ 시너지 활성 감지 시스템 (BattleManager.has_synergy_bonus / get_active_synergies)
- ✅ HUD 시너지 텍스트 표시 (아이콘/이미지는 Milestone 7-4에서)
- ✅ 카드 마젠타 강조 (카드명 색상 변경 조건부 적용)

### 1-7. 카드 / 몬스터 세부사항 재기획 + 구현

> **메모 (2026-04-20):** 1-1 카드 풀 확장과 1-2 적 추가는 개별로 조금씩 구현하지 않고, 한 번에 묶어서 기획한 뒤 구현한다.
> 이유: 각 카드의 강화 효과, 아키타입 정체성, 몬스터 특색, 인카운터 구성(단일/다수 등)이 서로 얽혀 있어 조각내어 구현하면 나중에 전면 수정이 불가피하기 때문.

**확정된 설계 변경 사항 (v1):**
- 카드 **5등급 체계** 도입: COMMON(0강) / UNCOMMON(1강) / RARE(1강) / LEGENDARY(2강) / DIVINE(2강)
- 강화 수치: 수치 효과는 **비율 방식** (UNCOMMON 10% / RARE 12% / LEGENDARY 14% / DIVINE 16%, 총합 누적)
- 정수 효과(DRAW/ENERGY/상태이상 스택/지속시간)는 **1강당 +1 고정**
- 전체 수치 스케일: **영웅 HP 1000** 기준 (기존 HP 60 → 전면 재설정)
- 공격 베이스 100~150 / 방어 베이스 80~130 / 적 공격 80~300

**확정된 설계 변경 사항 (v2 추가):**
- **영웅당 카드 풀 40장**으로 확장 (15장은 최소 테스트용)
- 1-1 카드 풀 목표: 각 영웅 **아키타입 3개 × 13~14장** 완성
- 등급 분포(40장): COMMON 10 / UNCOMMON 12 / RARE 12 / LEGENDARY 4 / DIVINE 2

**진행 순서:**
- ✅ 카드 프레임워크 기획 (`docs/game_design/cards_framework_v1.md`) + 40장 기준 업데이트
- ✅ 영웅별 카드 15장 기획 v1 (`docs/game_design/cards_{hero}_v1.md`)
- ✅ 몬스터 10종 + 인카운터 기획 (`docs/game_design/enemies_act1_v1.md`)
- ✅ **영웅별 카드 40장 기획 v2** (`docs/game_design/cards_{hero}_v2.md`) — 각 아키타입 12~14장
- ✅ 기획 확정 후 구현 플랜 생성 (`docs/superpowers/plans/2026-04-20-card-system-v2-implementation.md`)
- ✅ **카드 시스템 v2 구현 완료** (PR #30, 2026-04-20)
  - CardResource: Rarity enum, upgrade_level, can_upgrade() / upgraded 제거
  - EffectResource: base_value, base_bonus_value 추가
  - upgrade_card(): 등급별 비율 강화 (UNCOMMON 10% / RARE 12% / LEGENDARY 14% / DIVINE 16%)
  - 영웅 HP 1000 재설정 (전원)
  - 나폴레옹 40장 / 클레오파트라 40장 / 이순신 40장 전면 재작성
  - 적 10종 HP 300~4500 스케일 재작성

### 1-8. 알려진 버그 수정
- ✅ TargetType.ALL 전체 영웅 공격 (이미 구현됨 — 테스트 통과 확인)
- ✅ 블록 완전 흡수 시 amount=0 시그널 발화 (Plan 24)
- ✅ BUFF intent 처리 — status_type 기반 분기 (strength vs 방어도), 적 strength 공격력 반영 (PR #35)
- ✅ poison_per_turn 지속 시간 누적 수정 (2 고정 → 기존값+2, PR #35)
- ✅ IntentResource PREPARE 타입 추가 — 사이클롭스 준비 턴 방어도 0 표시 버그 수정 (PR #35)

### 1-9. 개발·기획 지원 도구 ✅

- ✅ 기획자용 종합 도감 자동 생성기 (PR #32)
  - `tools/generate_catalog.gd` — 카드/적/렐릭/이벤트 CSV·MD 덤프
  - 밸런싱 시 스프레드시트로 일괄 검토 가능
- ✅ 전역 디버그 단축키 18종 (PR #34~#35, #61, #73, #81)
  - 전투 전용: Shift+Q(즉시 승리) / Shift+I(무적) / Shift+E(무한 코스트) / Shift+D(드로우) / Shift+H(적 HP 설정) / Shift+G(그리드)
  - 전 씬 공통: Shift+A(카드 추가) / Shift+R(덱 편집) / Shift+U(카드 강화) / Shift+C(툴팁 고정)
  - Shift+N(영웅 즉시 해금) / Shift+L(렐릭 추가) / Shift+X(렐릭 제거) / Shift+V(이벤트 씬 입장) PR #61
  - ✅ Shift+M(몬스터 선택 전투) / Shift+B(영웅 HP 조정 다이얼로그) / Shift+T(번역 키 표시 토글) PR #73
  - ✅ Shift+O(더미 몬스터 추가) / Shift+S(더미 소환수 토큰, 영웅 순환) PR #81 — 전투 씬 레이아웃 테스트용
  - `OS.is_debug_build()` 게이트 → 릴리스 빌드 영향 0
  - `autoload/debug_manager.gd` 싱글턴 (CanvasLayer로 전 씬 오버레이)

---

## Milestone 2 — Act 2 (이집트 신화)

### 2-1. Act 2 맵
- ✅ Act 2 전용 맵 생성 로직 (act 파라미터화 — 레이아웃은 Phase B에서)
- ✅ Acts 간 전환 흐름: 보스 처치 → 영웅 영입 → Act 2 맵 진입
- ✅ Act 2 난이도 조정 (적 HP ×1.3, 공격 ×1.2)

### 2-1.5. 콘텐츠 데이터 외부화 (Act 2 콘텐츠 구현 전 선행) ✅

> **배경:** 카드·적·렐릭·이벤트 데이터가 `game_manager.gd` 코드에 하드코딩돼 있어 파일이 1415+ 줄로 비대했음. GDScript 데이터 파일(`resources/data/`) 방식으로 분리 완료.

**방식:** `resources/data/` 디렉토리에 카테고리별 GDScript 파일. `static func`으로 Resource 배열 반환. `game_manager.gd`는 `preload`로 위임.

- ✅ 기존 카드 데이터 외부화 (`resources/data/cards_napoleon.gd`, `cards_cleopatra.gd`, `cards_yi_sun_sin.gd`)
- ✅ 기존 Act 1 적 데이터 외부화 (`resources/data/enemies_act1.gd`)
- ✅ 기존 렐릭 데이터 외부화 (`resources/data/relics.gd`)
- ✅ 기존 이벤트 데이터 외부화 (`resources/data/events_act1.gd`)
- ✅ `game_manager.gd` 콘텐츠 코드 제거 (1415줄 → 657줄)
- ✅ Act 2 콘텐츠 외부화 완료 (`enemies_act2.gd`, `events_act2.gd` — PR #31)

### 2-2. Act 2 적 (이집트 신화)
- ✅ 일반 적 6종: 사막 척후병, 사막 전갈, 미라 전사, 스핑크스 새끼, 모래 이프리트, 카 영혼 (HP 320~600)
- ✅ 엘리트 적 3종: 아펩 뱀 (독 특화), 세트의 사냥개 (strength 축적), 바 새 (SPECIAL 카드 영구 제거)
- ✅ 보스: 오시리스 (2페이즈, HP 3000, 50% 시 HP 60% 회복 + 패턴 강화)
- 🔲 오시리스 페이즈 전환 비주얼 연출 (Milestone 7-5에서)

### 2-3. Act 2 이벤트 (이집트 테마 10종)
- ✅ 이집트 테마 이벤트 10종: 사자의 서, 아누비스의 심판, 스카라베 풍뎅이, 파라오의 무덤, 나일강 범람, 토트의 지혜, 바스테트 고양이, 오아시스 상인, 미라의 저주, 라의 태양선

### 2-4. Act 2 전용 렐릭 3종
- ✅ 이집트 신화 테마 공용 렐릭 3종: 앙크의 생명, 호루스의 눈, 스카라베 부적

---

## Milestone 3 — Act 3 (북유럽 신화) ✅

### 3-1. Act 3 적 (북유럽 신화) ✅
- ✅ 일반 적 6종: 드라우그르, 우르드의 거미, 요툰 병사, 볼바 마녀, 흐림팍시 기수, 갸르라르 뱀 (PR #44)
- ✅ 엘리트 적 3종: 펜리르 새끼 (2페이즈·strength 누적), 발키리 (5턴 패턴·자가회복 SPECIAL), 요르문간드르 분신 (2페이즈·전체 독) (PR #44)
- ✅ 보스: 요르문간드르 (3페이즈, HP 5000, 전체 독 + 페이즈별 강화, charm_resistance=2) (PR #44)

### 3-2. Act 3 이벤트 10종, 전용 렐릭 3종 ✅
- ✅ 북유럽 이벤트 10종: 오딘의 까마귀, 유그드라실의 열매, 라그나로크의 예언, 발할라 초대장, 미미르의 샘, 드래곤의 금화, 룬 스톤, 토르의 망치 자국, 얼음 거인의 시체, 프레이야의 눈물 (PR #45)
- ✅ 북유럽 전용 렐릭 3종: 운명의 룬(BATTLE_START DRAW +2), 묠니르의 파편(BATTLE_START BLOCK +10), 이둔의 사과(BATTLE_WIN HEAL +15). 풀 22→25 (PR #46)

### 3-3. 전 신화 × Act 엘리트·보스 + 신화 랜덤화 ✅

> **배경:** 신화 랜덤화 활성화를 위해 전 신화(그리스·이집트·북유럽) × 전 Act(1·2·3) 9개 엘리트·보스 슬롯을 채움.

- ✅ `greek_act2.gd` 완성: 케르베로스·카론·에리니에스 + 보스 하데스 (3페이즈, HP 4800) (PR #47)
- ✅ `egyptian_act1.gd` 완성: 자칼 전사·스카라베 여왕·오벨리스크 수호자 + 보스 세크메트 (3페이즈, HP 4500) (PR #47)
- ✅ `norse_act1.gd` 완성: 니드호그 유충·스콜 늑대·서리 거인 척후 + 보스 피요르기닌 (3페이즈, HP 4500) (PR #47)
- ✅ `norse_act2.gd` 완성: 트롤 전사·노른·바나헤임 엘프 + 보스 수르트 (3페이즈, HP 4800) (PR #47)
- ✅ `greek_act3.gd` 신규: 아레스 사냥개·포세이돈 사도·헤파이스토스 자동인형 + 보스 크로노스 (3페이즈, HP 5200) (PR #48)
- ✅ `egyptian_act3.gd` 신규: 아포피스 거대뱀·세트 폭풍·이시스 환영 + 보스 라-호라크티 (3페이즈, HP 5000) (PR #48)
- ✅ 신화 랜덤화 활성화: `reset()`에서 `act_mythologies.shuffle()` — 매 런 6가지 신화 배정 조합 (PR #48)
- ✅ 테스트 664개 전부 통과

---

## Milestone 4 — 챕터 시스템 + 영웅 해금 (메타 진행)

> **설계 변경 (2026-04-21):** 기존 단일 런(Act 1~3) 구조에서 **챕터 기반 구조**로 전환.
> - **챕터 1**: Act 1·2·3 (그리스·이집트·북유럽 랜덤 배정) — 현재 구현
> - **챕터 2**: Act 1·2·3 (한국·중국·일본 랜덤 배정) — 챕터 1 클리어 시 해금
> - 각 챕터는 **완전히 새 런** (덱·렐릭·골드 초기화). 메타 진행(해금 상태)만 런 간 유지.
> - **영웅 해금 시스템**: 특정 조건(몬스터 처치·이벤트·챕터/Act 클리어) 달성 시 영웅 영구 해금.
>   시작 영웅 = 해금된 영웅 중 선택. 영입 = 랜덤 3명 제시 → 1명 선택(기존 동일, 풀은 전체 해금 영웅).

### 4-1. 메타 진행 저장 시스템

- ✅ `user://progress.json` 신설 — 저장 항목:
  - `chapters_cleared: Array[int]` (클리어한 챕터 번호 목록)
  - `unlocked_heroes: Array[String]` (해금된 hero_id 목록, 기본값 ["napoleon", "cleopatra", "yi_sun_sin"])
  - `unlock_flags: Dictionary` (해금 조건 트래킹 — 예: `"killed_hydra": true`)
- ✅ `autoload/progress_manager.gd` 싱글턴 신설 — `save_progress()`/`load_progress()`/`unlock_hero()`/`is_hero_unlocked()` 포함. 런 간 메타 진행 전담 (`save_manager.gd`는 런 내 상태 전담으로 역할 분리)

### 4-2. 챕터 진행 흐름

- ✅ `game_manager.gd`에 `current_chapter: int`, `MAX_CHAPTERS: int = 2` 추가
- ✅ `_end_run_won()` 수정 — `progress_manager.mark_chapter_cleared(current_chapter)` 호출
  - 🔲 챕터 클리어 결과 화면 별도 씬 (현재 GameOver 씬 재사용)
- ✅ 메인 메뉴에 챕터 선택 UI 추가 (`chapter_select_scene`) — 챕터 2는 챕터 1 클리어 전 잠금 표시
- ✅ `start_run(hero_id, chapter)` — 챕터별 신화 풀 분기:
  - 챕터 1: `["greek", "egyptian", "norse"]`
  - 챕터 2: `["korean", "chinese", "japanese"]`

### 4-3. 영웅 해금 시스템 ✅ 완료 (PR #53)

- ✅ `hero_resource.gd`에 해금 조건 필드 추가: `unlock_condition` / `unlock_description`
- ✅ `resources/heroes/hero_registry.gd` 신설 — 영웅 중앙 레지스트리 (기본 3명). M5 영웅 구현 시 이 파일에만 분기 추가
- ✅ `progress_manager.gd`에 `check_unlock_conditions()` + `increment_flag()` + `hero_unlocked` 시그널
  - 조건 DSL: `default` / `clear_chapter_N` / `flag:<key>` / `<counter>>=<n>`
  - 훅: BOSS 처치(`kill_boss:<enemy_id>`) / ELITE 처치(`elite_kills_total`, `elite_solo_kills`) / 챕터 클리어
- ✅ `hero_select_scene.gd` — 레지스트리 기반 동적 생성 + 해금 필터링 (잠금 영웅 비활성 + unlock_description 표시)
- ✅ `_recruit_hero_pool()` — 해금 풀 전체에서 추출 (하드코딩 제거)
- ✅ 해금 알림 토스트 (`scenes/ui/hero_unlock_toast.tscn`) — 승리 화면에서 인스턴스화, hero_unlocked 시그널 구독 후 3초 표시
- 🔲 M5 영웅 코드 구현 시 `HeroRegistry.make_hero()`에 분기 추가 + `unlock_condition` 설정:
  - 잔다르크: `"clear_chapter_1"`, 칭기즈칸: `"flag:kill_boss:oshiris"`, 무사시: `"elite_solo_kills>=5"`

### 4-4. 기본 해금 조건 정의 (초기 3인 + 향후 확장)

| 영웅 | 해금 조건 |
|------|---------|
| 나폴레옹 | 기본 해금 (게임 시작부터) |
| 이순신 | 기본 해금 |
| 클레오파트라 | 기본 해금 |
| 잔 다르크 (M5) | 챕터 1 클리어 |
| 칭기즈칸 (M5) | Act 2 보스(챕터 무관) 첫 처치 |
| 미야모토 무사시 (M5) | 엘리트 5회 1:1(단일 적) 처치 |
| *(중국·추후 영웅)* | M5 미배정. 7·8번째 영웅 확장 시 후보 |
| *(챕터 2 영웅 후보)* | 챕터 2 특정 Act 클리어 등 |

---

## Milestone 4-2 — 챕터 2 콘텐츠 (동아시아 신화)

> 챕터 2 = 한국·중국·일본 신화 랜덤 배정. 챕터 1과 동일한 3신화 × 3Act 구조.
> 각 신화당: 일반 적 6종 + Act별 엘리트 3종·보스 1종(3개 모듈) + 이벤트 10종 + 전용 렐릭 3종.

### 한국 신화 (korean) ✅ 완료 (PR #50, #51)
- ✅ 기획 문서 작성 완료 (`docs/game_design/enemies_korean_v1.md`, `events_korean_v1.md`, `relics_korean_v1.md`)
  - 테마: "저승계의 압박" (LOWEST_HP 타겟 + 디버프 장기 누적) + "견고한 수호" (고방어도)
- ✅ 일반 적 6종 구현: 저승사자·처용·도깨비·삼족오·구미호·불가사리
- ✅ Act 1 엘리트 3종(해치·장승·해모수) + 보스 단군 (3페이즈, HP 4500)
- ✅ Act 2 엘리트 3종(도깨비 대장·용왕의 장군·동명성왕) + 보스 삼신할미 (3페이즈, HP 4800)
- ✅ Act 3 엘리트 3종(저승 판관·갓신·처용신) + 보스 구삼승할망 (3페이즈, HP 4800)
- ✅ 이벤트 10종 구현 (`events_korean.gd`) + `_build_event_pool()` 신화 기반 분기
- ✅ 전용 렐릭 3종 구현: 저승 부적·도깨비 방망이 파편·삼태극 부적 (렐릭 풀 25→28)

### 중국 신화 (chinese) ✅ 완료 (PR #58, #60)
- ✅ 기획 문서 작성 완료 (`docs/game_design/enemies_chinese_v1.md`, `events_chinese_v1.md`, `relics_chinese_v1.md`)
  - 테마: "천계·변신" (페이즈 전환 시 인텐트 세트 교체, 계급 스케일링)
- ✅ 일반 적 6종: 야차·나타 병사·사대천왕 병사·산해경 괴수·하급 선관·청룡 수호병
- ✅ Act 1 엘리트 3종(금각·은각 대왕·흑풍괴·소 마왕) + 보스 치우 (3페이즈, HP 4500)
- ✅ Act 2 엘리트 3종(홍해아·구룡 차장·천구 형제) + 보스 이랑신 (3페이즈, HP 4800)
- ✅ Act 3 엘리트 3종(백호·주작·현무 신장) + 보스 반고 (3페이즈, HP 4800, 혼돈→천지개벽→만물 창조. 기존 옥황상제 → PR #60 교체)
- ✅ 이벤트 10종 구현 (`events_chinese.gd`) + `_build_event_pool()` 신화 기반 분기
- ✅ 전용 렐릭 3종: 용의 비늘·팔선의 부적·서왕모의 복숭아 (렐릭 풀 28→37)

### 일본 신화 (japanese) ✅ 완료 (PR #59)
- ✅ 기획 문서 작성 완료 (`docs/game_design/enemies_japanese_v1.md`, `events_japanese_v1.md`, `relics_japanese_v1.md`)
  - 테마: "요괴·정밀 타격" (단일 고피해 + 상태이상 다중 부여)
- ✅ 일반 적 6종: 오니·텐구·유키온나·갓파·슈텐도지 졸개·로닌 망령
- ✅ Act 1 엘리트 3종(오니 장군·야마우바·자포자기 로닌) + 보스 라이덴 (3페이즈, HP 4500)
- ✅ Act 2 엘리트 3종(혼돈의 텐구·야샤·누레리온) + 보스 슈텐도지 (3페이즈, HP 4800)
- ✅ Act 3 엘리트 3종(아마노이와토 수문장·스사노오의 검·유키온나의 여왕) + 보스 야마타노오로치 (3페이즈, HP 4800)
- ✅ 이벤트 10종 구현 (`events_japanese.gd`) + `_build_event_pool()` 분기
- ✅ 전용 렐릭 3종: 귀신 부적·텐구의 깃털·오로치의 비늘 (렐릭 풀 37→40)
- ✅ `relic_resource.gd`에 `status_type` 필드 추가 (APPLY_STATUS_ENEMY 렐릭 상태이상 구분)

### 챕터 2 공통
- ✅ 빈 스텁 자동 필터 구현 완료 — 미구현 신화 자동 제외
- ✅ 챕터 2 신화 랜덤화 완성 (`act_mythologies = ["korean", "chinese", "japanese"].shuffle()`) PR #59
- 🔲 챕터 2 전용 난이도 스케일 (챕터 1 대비 추가 스케일링 검토)
- 🔲 챕터 2 최종 보스 (3신화 혼합 or 별도 최종 신격, 4페이즈 구조)

---

## Milestone 5 — 추가 영웅

GDD 기준 MVP 3인 이후 확장 영웅.

- ✅ 영웅 4: 잔 다르크 — 신성(HEAL_ALL·정화)/부활(REVIVE)/순교(HP소모→팀이득) `docs/game_design/cards_joan_of_arc_v1.md`
- ✅ 영웅 5: 칭기즈칸 — 기동(Rush·다수 저코스트)/몽골 기병(DMG ALL)/약탈(처치 보상) `docs/game_design/cards_genghis_khan_v1.md`
- ✅ 영웅 6: 미야모토 무사시 — 이도류(DMG×2)/결투(enemy_count==1)/무심(hand_size==0) `docs/game_design/cards_musashi_v1.md`
  - *중국 대표 영웅은 M5 미배정. 향후 7·8번째 영웅 확장 시 후보.*
- ✅ 영웅당 카드 15장(v1), 전용 렐릭 2종 개요, 크로스 시너지 MVP 3쌍 정의
- ✅ 코드 구현 완료 (PR #54 잔다르크, PR #55 칭기즈칸, PR #56 무사시)
  - REVIVE / SACRIFICE_HP / COST_ZERO_TURN / BLOCK_PER_CARDS_PLAYED / hit_count 다중 히트
  - CONDITIONAL_DMG 조건키: enemy_count_1 / hand_size_0
  - 크로스 시너지 6쌍 (철벽 진군·독침 반격·혼란의 돌격·성전·약탈과 독·검사의 약속)
  - 전용 렐릭 6종 (영웅당 2종), 841 테스트 통과
- ✅ v1 → v2 확장 완료 (영웅당 40장, PR #63~#66)
  - ON_KILL_DRAW / PURGE_STATUS / PER_DRAW_DMG 신규 EffectType 추가
  - EffectResource.condition 필드 — 효과별 조건부 실행
  - CONDITIONAL_DMG 조건키 확장: enemy_hp_below_30/50 / dead_ally_any / dead_ally_count / team_hp_below_30
  - 잔 다르크 38장 (신성/부활/순교), 칭기즈칸 38장 (기동/몽골 기병/약탈), 무사시 38장 (이도류/결투/무심)
  - 978 테스트 통과
- 🔲 영웅 선택 화면·스프라이트·사운드 (Milestone 7 UI 폴리시 단계)

---

## Milestone 6 — 시스템 완성 ✅

### 6-1. 병사 토큰 시스템
- ✅ 소환된 토큰 유닛 구현 — 병사 6×2 그리드 필드, 턴 구조 Pre/Main/Post 3페이즈 분리 (PR #38~#42)
- ✅ 나폴레옹 군단 아키타입 카드와 연동 (SUMMON_TOKEN 효과)

### 6-2. 비밀 룸 / 저주 경로 ✅ (Plan 28)
- ✅ MapGenerator에 SECRET / CURSED_PATH 룸 타입 추가 (4종 엔진 구현)
- ✅ 비밀 룸: 고유 렐릭 보상 (렐릭 풀에서 미획득 렐릭 우선 선택)
- ✅ 저주 경로: 강적 + 강렐릭 (부정적 효과)

### 6-3. 팀원 부활 ✅ (Plan 28)
- ✅ 특정 이벤트에서 사망 팀원 부활 옵션 (ReviveEvent 구현)
- ✅ 부활 비용 (골드 or 카드 제거) 선택식 구현

### 6-4. 도발(Taunt) 시스템 ✅ (Plan 28)
- ✅ 카드 사용 시 해당 팀원에게 모든 적 어그로 집중 (TAUNT 효과)
- ✅ BattleManager 어그로 로직 추가 (target_override)

### 6-5. 카드 타입 시스템
- ✅ ATTACK / SKILL / POWER 구분 구현 (Plan 26 완료)
- ✅ POWER 카드: 즉시 사용, 런 내 지속 효과, 덱에서 소진

### 6-6. 덱 뷰어 ✅ (Plan 28, PR #72/#73)
- ✅ 전투 중 덱 전체 열람 (DeckViewerScene 구현)
- ✅ 남은 덱, 버린 카드, 강화 상태 표시
- ✅ 덱·버린카드 2열 나란히 표시, 카드 5열 그리드
- ✅ 카드 호버 확대 툴팁 (2.5× 스케일) + 깜빡임 완전 수정 (mouse_filter 재귀 IGNORE)
- ✅ 버튼 위치: 턴 종료 버튼 아래 배치

---

## Milestone 7 — 비주얼 / 오디오

### 7-1. 캐릭터 아트
- 🔲 나폴레옹 스프라이트 (아이들 / 공격 / 피격 / 사망)
- 🔲 클레오파트라 스프라이트
- 🔲 이순신 스프라이트
- 🔲 사망 상태 연출 (반투명 or 그레이스케일)

### 7-2. 적 아트
- 🔲 Act 1 적 전체 스프라이트 (일반 6 + 엘리트 3 + 히드라)
- 🔲 히드라 페이즈별 스프라이트 변화 (머리 수 감소)
- 🔲 Acts 2~4 순차 추가

### 7-3. 카드 아트
- 🔲 카드별 일러스트 (우선순위: 스타터 카드 → 주요 아키타입 카드)
- 🔲 카드 프레임 디자인 (일반 / 강화)

### 7-4. UI 폴리싱
- 🔶 전투 인터랙션 폴리싱: 부채꼴 핸드(PR #79), 드래그 화살표 베지어(PR #80), 슬롯 Marker2D(PR #81) 완료 — 그래픽 에셋 연결 전 UX 기반 마련
- 🔲 전투 화면: HP바, 에너지, 인텐트 아이콘 실제 그래픽 적용
- 🔲 맵 화면: 노드 아이콘, 경로선, 배경
- 🔲 카드 픽 / 상점 / 휴식 / 이벤트 화면 배경
- 🔲 게임 오버 / 클리어 화면 연출
- 🔲 상태이상 아이콘 실제 이미지 (현재 이모지 텍스트)

### 7-5. 애니메이션 / 이펙트
- 🔲 카드 사용 시 이펙트 (공격 임팩트, 독 스플래시, 방어막)
- 🔲 히트 스톱 (공격 시 0.1초 정지)
- 🔲 씬 전환 페이드 인/아웃
- 🔲 페이즈 전환 연출 (보스 분노 이펙트)

### 7-6. 오디오
- ✅ 사운드 에셋 요구사항 문서 (`docs/sound_assets_required.md`) — BGM 16·UI SFX 23·Battle SFX 37·Enemy SFX 29·이벤트 7·Ambient 8·VO 11, 총 131개 파일 정의 + Godot 4 폴더 구조 포함
- 🔲 BGM 임포트 및 AudioStreamPlayer 연동 (Act별·보스별 전환)
- 🔲 SFX 임포트 및 AudioManager 싱글턴 구축 (`play_sfx(key)` 인터페이스)
- 🔲 카드 사용·공격 임팩트·방어·피격·적 사망 SFX 이벤트 연결
- 🔲 UI SFX: 버튼 클릭, 씬 전환
- 🔲 보이스: 선택 사항 (캐릭터 전용 보이스 라인)

---

## Milestone 8 — 플랫폼 완성 (모바일)

### 8-1. 모바일 UI 최적화
- 🔲 해상도 대응 (16:9, 18:9, 19.5:9)
- 🔲 안전 영역(Safe Area) 처리 (노치, 펀치홀)
- 🔲 터치 타겟 크기 최소 44dp 보장
- 🔲 카드 드래그 앤 드롭 모바일 터치 최적화

### 8-2. Android 빌드
- 🔲 Godot Android Export 설정
- 🔲 APK / AAB 빌드 테스트
- 🔲 Google Play 스토어 등록 준비

### 8-3. iOS 빌드
- 🔲 Godot iOS Export 설정
- 🔲 App Store 등록 준비

### 8-4. 저장/로드 안정화
- 🔲 모바일 경로 기반 세이브 파일 처리
- 🔲 비정상 종료 후 세이브 복구 테스트

### 8-5. 성능 최적화
- 🔲 60fps 유지 (저사양 기기 기준)
- 🔲 메모리 사용량 측정 및 최적화
- 🔲 텍스처 아틀라스 적용

---

## Milestone 8.5 — 다국어 지원 (현지화)

> **설계 메모:** 게임 내 모든 문자열(카드명, 카드 설명, 적 이름, 이벤트 텍스트, 렐릭 설명, UI 레이블 등)은 번역 키로 관리한다.
> - **데이터 파일** (`resources/data/*.gd`): 문자열 대신 번역 키 저장 (예: `"CARD_NAPOLEON_CHARGE_NAME"`)
> - **번역 파일** (`translations/strings.csv`): 키 → 언어별 실제 텍스트 매핑
> - **런타임**: Godot 내장 `tr("KEY")` 함수가 현재 로케일에 맞는 문자열 반환
> - **언어 전환**: 설정 화면에서 `TranslationServer.set_locale("en")` 호출만으로 전환
>
> 2-1.5 데이터 외부화 완료 (2026-04-19, PR #31). 이제 문자열 → 번역 키 교체 작업만 수행하면 됨.

### 8.5-1. 번역 인프라 구축 ✅ (PR #73)
- ✅ CSV 기반 번역 파일 9종 생성 (`strings_battle/card/ui/enemy/status/relic/synergy/event/hero.csv`) — 키/언어 컬럼 구조 확정
- ✅ Godot 프로젝트에 번역 파일 등록 (`.translation` 바이너리 자동 생성)
- ✅ `autoload/locale_manager.gd` 싱글턴 — 언어 전환 인터페이스 (`set_locale()`)
- ✅ NotoSansCJK-Regular.ttc / NotoNaskhArabic-Regular.ttf 폰트 fallback 체인 (한·중·일·아랍 지원)
- 🔶 `resources/data/*.gd` 문자열 → 번역 키로 교체 (전투·카드·상태이상 완료, 이벤트·이름 일부 미완)
- 🔶 UI 레이블 `tr()` 래핑 (battle_scene·card_scene 완료, shop/map/menu 미완)
- 🔲 설정 화면에 언어 선택 UI 추가 (locale_manager 구현됨, UI 연결 미완)

### 8.5-2. 지원 언어 번역 작업
- 🔶 한국어 — 전투·카드·상태이상·인텐트 완료. 이벤트·렐릭·영웅 설명 미완
- 🔶 영어 — 전투·인텐트 관련 완료. 나머지 미완
- 🔲 일본어 (ja)
- 🔲 중국어 간체 (zh) — 일부 키 존재, 번역 내용 미입력
- 🔲 프랑스어 (fr) — 일부 키 존재, 번역 내용 미입력
- 🔲 스페인어 (es) — 일부 키 존재, 번역 내용 미입력
- 🔲 이탈리아어 (it) — 일부 키 존재, 번역 내용 미입력
- 🔲 그리스어 (el) — 일부 키 존재, 번역 내용 미입력
- 🔲 베트남어 (vi)

---

## Milestone 9 — 런치 전 마무리

### 9-1. 밸런싱
- 🔲 카드 수치 전수 검토 (피해, 방어, 비용)
- 🔲 적 HP/공격력 Act별 스케일 조정
- 🔲 렐릭 효과 OP 여부 점검
- 🔲 플레이테스트 10회 이상 + 클리어율 측정

### 9-2. 튜토리얼
- 🔲 첫 런 시작 시 기초 튜토리얼 (카드 사용, 드래그, 타겟 선택)
- 🔲 상태이상 툴팁 첫 등장 시 설명 팝업

### 9-3. 업적 시스템
- 🔲 기본 업적 10종 (첫 클리어, 전원 생존 클리어, 특정 조합 달성 등)
- 🔲 런 통계 기록 (총 런 수, 최고 층, 영웅별 승률)

### 9-4. QA / 버그 픽스
- 🔲 전체 씬 플로우 엔드-투-엔드 테스트
- 🔲 엣지 케이스 (팀원 전원 사망, 덱 0장, 골드 음수 등) 검증
- 🔲 크래시 리포트 수집 도구 연동 (선택)

---

## 우선순위 요약

> 최종 갱신: 2026-04-25 v7. PR #79 부채꼴 핸드 / PR #80 드래그 화살표 / PR #81 슬롯 Marker2D·디버그 키 반영. 1080 테스트 통과 (이름 조회 회귀 39건 추적 중).

| 우선순위 | 항목 | 이유 |
|---|---|---|
| ✅ 완료 | 추가 영웅 3명 (M5: 잔 다르크·칭기즈칸·미야모토 무사시) | PR #54~#56 완료. 크로스 시너지 6쌍 |
| ✅ 완료 | 영웅 해금 시스템 (M4-3/4-4) | PR #53 완료. ProgressManager + hero_registry + 토스트 |
| ✅ 완료 | 챕터 2 중·일 신화 (M4-2) | PR #58~#60 완료. 렐릭 풀 40종, 919 테스트 통과 |
| ✅ 완료 | 카드 v2 확장 (영웅당 40장, M5) | PR #63~#66 완료. 978 테스트 통과 |
| 🟡 중기 | 병사 토큰 시스템 (M6-1) | 나폴레옹 군단 아키타입 완성 |
| ✅ 완료 | 권능(POWER) 카드 시스템 정립 (M6-5a) | 명칭·동작·UI·신규 3장 추가 (Plan 26). 245장, 1090 테스트 통과 |
| ✅ 완료 | 적 카드 타입 카운터 메카닉 (M6-5b) | 크로노스·저승 판관·반고. repeat 재발동 버그 수정, 툴팁 번역키화, 상태 아이콘 통합. 1145 테스트 통과 (PR #73) |
| 🟡 중기 | 카드 효과 타입 참조 (M6-5c) | DAMAGE_PER_ATTACK 등 신규 EffectType + 카드 5~10장 |
| ✅ 완료 | 시스템 완성 M6 (덱뷰어·부활·도발·비밀룸 4종 엔진 구현) | Plan 28, PR #73 완료. 게임 루프 깊이 |
| ✅ 완료 | 번역 인프라 구축 (M8.5-1) | PR #73. CSV 9종·locale_manager·폰트 fallback |
| ✅ 완료 | 전투 UX 기반 폴리싱 (M7 전 단계) | PR #79~#81. 핸드 부채꼴·드래그 화살표·슬롯 Marker2D화 |
| 🟡 중기 | 번역 내용 채우기 (M8.5-2) | 한국어 나머지 + 영어 전체 → 플레이어블 2개 언어 목표 |
| 🟢 장기 | 비주얼 (M7-1~7-5) 캐릭터·카드 아트, 이펙트 | 몰입감 |
| 🟢 장기 | 오디오 임포트 및 AudioManager (M7-6) | 몰입감 |
| 🟢 장기 | 모바일 최적화 (M8) | 출시 요건 |
| 🔵 출시 직전 | 밸런싱 / 튜토리얼 / 업적 / QA (M9) | 품질 보증 |

---

## Bonus — 부채꼴 카드 핸드 Godot 에셋 오픈소스 배포

> **배경:** STSL 전투 핸드에 구현된 부채꼴 레이아웃 + 호버 확대 시스템을 게임 로직과 분리해,  
> Godot 4를 사용하는 모든 카드게임 개발자가 재사용할 수 있는 독립 에셋으로 배포한다.  
> 우선순위 낮음 — 게임 본체 완성(M9) 이후 진행.
>
> **구현 완료 시점:** PR #79 (2026-04-24) — STSL 전투 씬에 반영됨. 분리 배포는 본체 완성 후.

### 현재 구현 위치

- **핵심 파일:** `scenes/battle/battle_scene.gd`
- **관련 상수 (line 19~23):**
  ```gdscript
  const BASE_CARD_SCALE := 1.4        # 카드 기본 시각 크기 배율
  const FAN_PIVOT_Y_OFFSET := 1200.0  # 화면 아래 가상 회전축까지 거리 (px)
  const FAN_ANGLE_PER_CARD := 0.10    # 카드 1장당 회전 간격 (rad ≈ 5.7°)
  const FAN_MAX_TOTAL_ANGLE := 0.9    # 전체 부채각 상한 (rad ≈ 51°)
  const HAND_BASE_Y := 960            # 부채 중심 카드의 월드 y 좌표
  ```
- **핵심 함수:**
  - `_refresh_hand()` — 부채꼴 좌표·회전 계산 + CardScene 인스턴스화
  - `_on_card_hovered()` — 호버 카드 1.4× 확대·상승 + 인접 카드 spread Tween
  - `_on_card_unhovered()` / `_reset_hand_fan()` — 원위치 복귀 Tween
- **동적 lift 계산 (클리핑 방지, `_on_card_hovered` 내부):**
  ```gdscript
  var hover_scale := BASE_CARD_SCALE * 1.4
  var card_bottom := base_pos.y + hover_scale * 100.0 + 100.0
  var lift := maxf(60.0, card_bottom - (WINDOW_H - 20.0))
  ```
- **카드별 메타 저장 패턴:** `set_meta("_fan_pos")` / `set_meta("_fan_rot")` / `set_meta("_fan_idx")`  
  → `_refresh_hand()` 시 저장, 호버 함수에서 읽어 기준점으로 사용

### 부채꼴 수학 요약

```
fan_pivot = Vector2(WINDOW_W / 2, HAND_BASE_Y + FAN_PIVOT_Y_OFFSET)
step = min(FAN_ANGLE_PER_CARD, FAN_MAX_TOTAL_ANGLE / (n_cards - 1))
angle[i] = (i - (n_cards - 1) / 2.0) * step          # 가운데 카드 = 0 rad
arc_pos[i] = fan_pivot + Vector2(sin(angle), -cos(angle)) * FAN_PIVOT_Y_OFFSET
node.position = arc_pos[i] - Vector2(70, 100) * BASE_CARD_SCALE  # 카드 중심 보정
node.rotation = angle[i]
node.pivot_offset = Vector2(70, 100)   # CardScene 내부 카드 중심점 (local space)
```

### 에셋화 작업 목록 (~3~4일)

| 항목 | 내용 |
|---|---|
| `FanHandContainer.gd` 분리 | `DeckManager` 의존 제거 → `add_card(node)` / `remove_card(node)` API |
| `@export` 파라미터 노출 | 상수 전부 인스펙터에서 조정 가능하게 |
| 범용 카드 인터페이스 | `IFanCard` — `pivot_offset`, `card_hovered` 시그널만 요구 |
| 데모 씬 | 임의 Control 노드를 카드처럼 사용하는 예제 |
| README + AssetLib 설명 | 설치 방법, 파라미터 설명, 스크린샷 |

### AssetLib 배포 체크리스트

- [ ] Godot 4.x 플러그인 구조 (`addons/fan_hand/`) 로 패키징
- [ ] MIT 라이선스 명시
- [ ] `plugin.cfg` 작성
- [ ] AssetLib 제출 (에셋 카테고리: 2D / UI)
