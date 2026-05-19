# STSL — Production Roadmap

> 작성일: 2026-04-17 (최종 동기화: 2026-05-20 v24)
> 기준: 챕터 1·2 완성 + 영웅 6인 카드 풀 재설계 v3 + balance_check SKIP 0 + 번역 인프라 + 덱뷰어 + 오디오 시스템 완성 + 인카운터 v2(중복 0·floor 가중치) + 몬스터 메커니즘 레이어 v1(6 신화 시그니처·IntentRes 7종·~115/120 monsters tier) + 이벤트·렐릭 v2(신규 EffectType 3종·다양화 22개·렐릭 차별화 5종·신규 이벤트 5종·PASSIVE 버그 수정) + **이벤트 UX 마무리(NONE 옵션 재설계·태그 시스템·카드 제거 UI 통합·autoload 버그 수정, PR #108~#110)** + **VFX 시스템 v1(공격·상태·버프 VFX 20종 GDScript 포팅·divine→holy 일괄 이주·임팩트 시점 동기화·GameSettings autoload·SFX 매핑·다수 시각 버그 수정, PR #111~#113)** + **설정 graphics/gameplay 탭 + GameSettings save/load (PR #114)** + **전투 UX 폴리싱 v2(VFX impact 시점 정확 동기화·글로벌 툴팁 시스템·popup 글로우/색상/Cinzel-Bold·카드 입력 스무스·사망 예측 차단·HP 블룸 임계치·파티클 4단계, PR #115)** 기준
> 범례: ✅ 완료 / 🔲 미완료 / 🔶 부분 완료

---

## 현재 상태 요약

**챕터 1** (그리스·이집트·북유럽 랜덤 배정) 완성. **챕터 2** (한국·중국·일본 랜덤 배정) 완성 (PR #50, #51, #58, #59, #60).
영웅 6인(나폴레옹·이순신·클레오파트라·잔 다르크·칭기즈칸·미야모토 무사시), **영웅당 카드 풀 30장(아키타입 3개, v3 전면 재설계 완료)**.
**카드 다양성 엔진 확장**: EffectType 3종 신규(MULTI_HIT_RANDOM·DAMAGE_PER_STATUS_TYPE·DRAW_PER_ENTHRALL) + Power 훅 16종 추가.
**balance_check 전면 공식화**: SKIP 34개 → 0, X코 카드(spend_all_energy) 유효코스트 처리 추가. 최종 결과 OK 240 | NG 0 | SKIP 0 | DUP 0.
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
**전투 UX 개선** (PR #79, #80, #81): 핸드 부채꼴 레이아웃 + 호버 확대(PR #79), 드래그 화살표 베지어 곡선·유효성 색상·흐름 애니메이션(PR #80), 슬롯 위치 Marker2D 기반(에디터 드래그로 조정)·소환 영역 6개 단일 열·더미 몬스터/소환수 디버그 키 Shift+O·S(PR #81). 1080 테스트 통과.
**상태이상·시너지·렐릭 아이콘 UI** (PR #85): 전투 HUD 좌측에 아이콘 패널 신설 — SVG 아이콘 기반 상태이상·시너지·렐릭 툴팁 표시.
**Sacred UI 디자인 시스템** (PR #86~#88): `SacredPalette`(색상 팔레트) + `SacredTheme`(헬퍼·폰트·버튼 애니메이션) 오토로드 신설. TitleLabel·SubLabel·EyebrowLabel·AccentLabel·PrimaryButton·VowButton·ChapterButton·IconButton 테마 변형 8종. Cinzel·IMFell English·Inter·SpaceMono 커스텀 폰트. 4방향 별 커서 SVG. 엘립스 블룸 셰이더·격자(crosshatch) 오버레이 셰이더. 메인메뉴·챕터선택·영웅선택·맵·휴식·상점·이벤트·카드픽 8개 씬 전면 적용.
**맵 아이콘·알고리즘** (PR #88): Slay-the-Spire 방식 맵 생성 알고리즘 + 15×7 좌표계 + 룸 아이콘 7종 SVG(`IconUtils.get_room_icon()`).
**전투 UI 보완** (PR #89~#91): Enthrall 상태이상 아이콘·번역 추가, 카운터 아이콘 시계 SVG + 발동 순서 고정, HP바 8px halo bloom, 팝업 트윈 개선, 설정 오버레이 커서 크기 세그먼트 컨트롤(S/M/L/XL)·취소/적용/초기화 버튼 추가.
**이벤트 씬 i18n·격자 패턴** (PR #92): 이벤트 선택지 하드코딩 한국어 → tr() 교체(10개 번역 키 신설, 8언어), 8개 씬 격자 배경 오버레이 셰이더 적용.
**오디오 시스템 V2** (PR #94): `AudioManager` autoload (SFX 풀 16ch·BGM 크로스페이드·버스 볼륨 저장), `UISound` autoload (전역 버튼 호버·클릭 SFX, no_ui_sound 메타 opt-out), SFX 24종(-14 LUFS) + BGM 70종(-18 LUFS) 생성·정규화, 신화별 전투 BGM·보스 페이즈별 BGM 동적 선택, BGM 트랙 종료 자동 반복, 설정창 사운드 탭(볼륨 슬라이더 4개), `assets/audio/` .gitignore 처리. BurstParticleGroup2D weakref 람다 크래시 수정. 맵 룸 아이콘 툴팁 0.4s 지연 구현. `has_debuffs_N` 카드 조건 설명 동적 파싱.
**인카운터 v2** (PR #95): 6 신화 일반 몬스터 풀 전면 재설계. 신화당 20종 × 10 인카운터 (난이도 1~10 오름차순), **각 몬스터 종이 정확히 1개 인카운터에만 등장**(중복 0). 84종 신규 몬스터 + 한국어/영어 번역. **Floor 가중치 선택 알고리즘**(`_pick_weighted_encounter`): 진행도 기반 ±3 윈도우 삼각 분포로 floor 진행에 따라 평균 난이도 상승, 같은 floor 내 변동성 보존. `test_encounter_weighting.gd` + `test_enemies.gd` 검증 3종.
**이벤트·렐릭 v2** (PR #104~#107): `EventChoiceResource`에 신규 EffectType 3종(TRIGGER_BATTLE/MULTI/ADD_CARD) + 신규 필드(secondary/alt/reward/required_hero_id/encounter_tier/card_id), 22개 중복 이벤트를 새 메커니즘(전투-보상/확률/MULTI/조건부)으로 다양화, 5개 렐릭 차별화(scarab→APPLY_STATUS_ENEMY, ankh→ON_HERO_DAMAGED+condition_value, idun→PLAYER_TURN_END, dharma→PASSIVE MAX_HP, tengu→BATTLE_WIN), 5개 신규 이벤트 추가(sphinx_gate/ymir_blood/bodhi_tree/eight_immortals/kitsune_kit). **PASSIVE 트리거 적용 버그 수정**(_ancient_artifact/_dharma_seal/_cursed_crown MAX_HP 보너스 회복 — `add_relic` 시 즉시 적용). `condition_value` 처리를 HEAL/BLOCK까지 확장. `relic.status_type` 무시 버그 수정(_orochi_scale weak 회복). 카탈로그 스크립트 새 EffectType 인식, 사전 fail 37개 정리(i18n 키 마이그레이션·맵 노드·카드 풀 카운트), 통합 테스트 +14. **1365 테스트 통과 / 0 fail**.
**개체별 ATB 차례 시스템** (PR #121~#125): 라운드 기반 → 33옵스퀴르 식 **영구 ATB 큐** (영웅 1명/적 1마리씩 speed 순). DeckManager 영웅별 분리 (각 영웅 덱·핸드·에너지·`owner_id` 자동 분배), 카드 효과 9개·Power 6개·Relic 44개 본인 차례 단위로 재정의. 영웅 차례 카메라 줌인 1.3x, 사이드바 (화면 밖 적 UI 만 우측 2x3 grid 트윈), turn queue 미리보기 위젯, 덱 보기 영웅별 탭, 차례 전환 인터벌 통합. **1465 테스트 통과 / 0 failed**. M5 영웅 6명 speed 50~60 (편차 줄임), 적 grade 폴백 NORMAL 45 / ELITE 53 / BOSS 65 (보스 > 영웅).
**전투 UX 폴리싱 v3** (PR #126): 차례 인터벌 fine-tune (영웅→영웅 1x, 영웅↔적 2x, 적→적 3x), 적 인텐트 hover tooltip (모든 action_type + SPECIAL, 9 언어, base/사이드바 모두 작동), 상태이상 UI 시그니처 6 + 활성 파워 15 SVG 아이콘 추가 (이모지 폴백 제거), 파워 tooltip = 시전자 영웅 이름 (옆 라벨의 효과 설명과 역할 분리). GDScript 워닝/런타임 에러 일괄 정리 — Shift+T 번역 키 디버그 모드 크래시 해결 (`_format_intent_tooltip` `tr() %` → `_trf`), `ui_sound` meta flag 로 중복 connect 차단, `card_scene._build_desc` 절대 경로 get_node → autoload 직접 참조.
**영웅 별명 + i18n 통일** (PR #128): 스토리 설정 (영웅들이 현생 기억 X → 본명 모름) — 영웅 6명 `.name` 을 영웅적 칭호로 (아우스터리츠의 태양 / 마지막 파라오 / 불패의 통제사 / 오를레앙의 성녀 / 초원의 정복자 / 두 자루의 검객). 메커니즘 desc·시너지 의 본명 → 짧은 직함 일괄 치환 (488 셀, 4 csv, 9 언어, 그리스어 격변화/정관사 후처리). 1인칭 유물 4종 (난중일기·오를레앙 깃발·니텐이치류·오륜서) 추상화. 누락 번역키 일괄 채움 — battle.intent.tooltip ja/el/zh 26 키, joan archetype 12, 시그너처 toast 6, status name 8, 유물/카드 effect 텍스트 등 ~150 셀. turn queue 슬롯 가로 96 (별명 길이 대응).
**speed 시스템** (PR #129): 영웅·적 `speed` 스탯에 동적 buff/debuff 시스템. status `speed_bonus`/`speed_penalty` + `_dur` (poison 패턴 일정 효과), power `power.speed_buff` (전투 끝까지). 카드 6 종 (영웅별 1: 전격 진군/유혹의 정체/거북선 점호/성령의 가호/기마 돌격/신속의 검) + 유물 2 종 (신속의 인장 BATTLE_START 모든 영웅 +3, 시간의 모래시계 영웅 차례 5회마다 +1 누적). speed 변경 시 `_adjust_turn_queue_for_speed_change` 가 `_turn_queue_at` 비율 보정 + `turn_queue_changed` emit → UI 즉시 갱신. APPLY_STATUS target 에 ALL_ALLIES/ALLY 추가. CP 테이블 `SPEED_PER_TURN_V`/`SPEED_POWER_V` + 배수 추가, balance_check 전체 통과 (246 OK + 50 upgrade + 중복 0). 9 언어 i18n 21 키. **1448 passed / 0 failed**.

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
- ✅ 5개 렐릭 차별화 (M6.6, PR #104·#107) — scarab/ankh/idun/dharma/tengu 각각 trigger·effect_type·condition_value로 정체성 부여

### 1-4. 이벤트 확장
- ✅ 기본 이벤트 5종 (황금 상자, 상처 입은 전사, 고대 도서관, 저주받은 제단, 동료 만남)
- ✅ 그리스 신화 테마 이벤트 5종 추가 (총 10종)
  - 프로메테우스의 불 (DRAW_UP +1, HP -20), 헤라클레스의 시련 (GOLD +60, HP -25)
  - 키르케의 마법 (HEAL +25, GOLD -50), 하데스의 계약 (ADD_RELIC, HP -30)
  - 헤르메스의 도박 (GOLD +50 OR 카드 1장 제거 — 플레이어가 선택)
- ✅ **이벤트 메커니즘 v2** (M6.6, PR #104) — 22개 중복 다양화 (TRIGGER_BATTLE/MULTI/확률/조건부) + 신규 5개 (sphinx_gate/ymir_blood/bodhi_tree/eight_immortals/kitsune_kit). 신규 EffectType: TRIGGER_BATTLE / MULTI / ADD_CARD

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

### 1-10. 카드 밸런스 검증 도구 ✅

- ✅ `tools/balance_check.gd` — 헤드리스 CP 검증기
  - 전 EffectType(0~39) CP 공식 커버 (SKIP 34→0)
  - X코 카드(spend_all_energy) 유효코스트 자동 감지 처리
  - DUP 중복 효과 시그니처 검사
  - 업그레이드 CP 증가율(±15%/레벨) 검증
  - 최종 결과: OK 240 | NG 0 | SKIP 0 | DUP 0

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
  - ✅ Space+L(레이블 렉트 표시 토글) / Space+B(버튼 렉트 표시 토글) — 위치 디버그 PR #88~#89
  - ✅ Space+P(프레임 스파이크 프로파일러 토글) — dt·fps·draw·nodes·mem 로그 기록 PR #89
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
  - 챕터 2: `["buddhist", "daoist", "japanese"]`

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

> 챕터 2 = 불교·도교·일본 신화 랜덤 배정. 챕터 1과 동일한 3신화 × 3Act 구조.
> 각 신화당: 일반 적 6종 + Act별 엘리트 3종·보스 1종(3개 모듈) + 이벤트 10종 + 전용 렐릭 3종.
> *(한국·중국 신화는 Phase E에서 불교·도교로 교체됨 — 메커니즘 재활용, 테마·키 교체)*

### 불교 신화 (buddhist) ✅ 완료 (Phase B–E)
- ✅ 기획 문서 작성 완료 (`docs/game_design/enemies_buddhist.md`)
  - 테마: "업보·분노존" (LOWEST_HP 타겟 + 디버프 누적, 고방어 호법신)
- ✅ 일반 적 6종: 야차·사천왕·아수라·가루다·마라·금강역사
- ✅ Act 1 엘리트 3종(사대천왕·인왕역사·호법신중) + 보스 대일여래 (3페이즈, HP 4500)
- ✅ Act 2 엘리트 3종(아수라왕·나가왕·화신여래) + 보스 천수관음 (3페이즈, HP 4800)
- ✅ Act 3 엘리트 3종(염라대왕·지장보살·비로자나불) + 보스 부동명왕 (3페이즈, HP 4800)
  - 염라대왕: ATTACK 카드 4장마다 HP 직격 트리거
- ✅ 이벤트 10종 구현 (`events_buddhist.gd`) + `_build_event_pool()` 신화 기반 분기
- ✅ 전용 렐릭 3종: 법인·법고·염주

### 도교 신화 (daoist) ✅ 완료 (Phase B–E)
- ✅ 기획 문서 작성 완료 (`docs/game_design/enemies_daoist.md`)
  - 테마: "천계·변신" (페이즈 전환 시 인텐트 세트 교체, 계급 스케일링)
- ✅ 일반 적 6종: 시해선·동자선·천병·산신·도사 수련생·청룡 호법
- ✅ Act 1 엘리트 3종(금단도사·은단도사·흑풍선) + 보스 동왕공 (3페이즈, HP 4500)
- ✅ Act 2 엘리트 3종(적양선·구룡선존·이랑신 형제) + 보스 진무대제 (3페이즈, HP 4800)
- ✅ Act 3 엘리트 3종(백호선군·주작선군·현무선군) + 보스 옥황상제 (3페이즈, HP 4800)
  - 옥황상제: POWER 카드 1장마다 Weak 부여 트리거
- ✅ 이벤트 10종 구현 (`events_daoist.gd`) + `_build_event_pool()` 신화 기반 분기
- ✅ 전용 렐릭 3종: 음양경·오행 옥·선학 깃털

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
- ✅ 챕터 2 신화 랜덤화 완성 (`act_mythologies = ["buddhist", "daoist", "japanese"].shuffle()`)
- 🔲 챕터 2 전용 난이도 스케일 (챕터 1 대비 추가 스케일링 검토)

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
- ✅ **v3 전면 재설계 완료** (영웅당 30장, 아키타입 역할 분류 완성)
  - 엔진 확장: MULTI_HIT_RANDOM(36) / DAMAGE_PER_STATUS_TYPE(37) / DRAW_PER_ENTHRALL(38) 신규 EffectType
  - Power 훅 16종 추가: charm_double_apply / on_enthrall_strength / sacrifice_bank / echo_next_attack / spend_all_energy_poison_double 등
  - 무사시 30장 (이도류10/결투10/무심10), 클레오파트라 30장 (독살12/저주10/조종8), 잔다르크 30장, 이순신 30장, 칭기즈칸 30장, 나폴레옹 30장
  - balance_check SKIP 34→0 전면 공식화, X코 카드 유효코스트 처리
  - 최종 결과: OK 240 | NG 0 | SKIP 0 | DUP 0
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

## Milestone 6.5 — 적 시스템 v2 (인카운터 + 메커니즘 레이어)

### 6.5-1. 인카운터 v2 ✅ (PR #95)
- ✅ 6 신화 normals 풀 전면 재작성: 신화당 20종 × 10 인카운터, 중복 0
- ✅ 인카운터 인덱스 0~9 = 난이도 1~10 (매우 약함 → 매우 강함) 오름차순
- ✅ Floor 가중치 선택 (`_pick_weighted_encounter`): ±3 윈도우 삼각 분포, floor 0~9 진행도와 매칭
- ✅ 84종 신규 몬스터 정의 + 한국어/영어 번역 (`strings_enemy.csv` 84행)
- ✅ 검증 테스트 3종 (`test_enemies.gd`): 신화당 인카운터 정확히 10개 / 몬스터 정확히 20종 / 키 중복 0
- ✅ Floor 분포 검증 (`test_encounter_weighting.gd`): floor 0/5/9 각 1000회 샘플링
- ✅ 결과 요약 CSV (`docs/balance/normal_monsters.csv`, `normal_encounters.csv`)

### 6.5-2. 몬스터 메커니즘 레이어 ✅ (PR #97)
**달성**: 일반 몬스터 패턴 다양화 — 6 신화 시그니처 자동 + 4 티어 (시퀀스 / HP 트리거 / 적간 상호작용 / 신규 액션) + 인카운터 #8~10 테마 시너지. ~115/120 monsters (96%) 명시적 tier 적용.

**구현 결과**
- 신규 인프라: `EnemyInteractionSystem` / `EnemySignatureSystem` autoload, `EnemyResource` 3 필드(phase_buffs / signatures_enabled / death_trigger), `battle_manager` 시그니처 hook 4종 + invuln/marker/counter/SUMMON 처리
- 신규 IntentResource ActionType **7종**: HEAL_ALLY / BUFF_ALLY / COUNTER_PREPARE / MARK_TARGET / SACRIFICE / WARD / SUMMON
- 6 신화 시그니처 자동 적용: 휴브리스(그리스) / 라그나로크(북유럽) / 저주누적(이집트) / 인과응보(불교) / 음양(도교) / 결계(일본)
- 인카운터 #1~3 (9종) `signatures_enabled=false` 게이트
- 인카운터 #10 보스급에 T3 적용 (COUNTER/MARK/SACRIFICE/WARD/SUMMON 시범)
- `tests/test_enemy_mechanics.gd` 25 함수 / 60+ assertion 신규

**Phase 분할 (실제 11 commit, 약 5 시간 압축)**

| Phase | 내용 | 결과 |
|---|---|---|
| 1 ✅ | phase_buffs 필드 + SPECIAL 일반화 + 그리스 7종 tier | 1057aeb — TriggerSystem 별도 신설은 phase_buffs로 대체 (실용적 축약) |
| 2 ✅ | EnemyInteractionSystem + 북유럽·이집트 13종 + DEATH-RATTLE | c4f164b, f5b9510 |
| 3 ✅ | 6 신화 시그니처 + 챕터 2 + T3 액션 5종 | 2fbb8f1, edcbda0, 06264ec, 6e4be13, 9a4cbc3 |
| 4 ✅ | #8~10 테마 시너지 + 챕터 1·2 잔여 34종 (완벽 대칭) | 484ea82, c621dbc |

**스펙 대비 조정 사항**
- EnemyTriggerSystem 별도 autoload 미신설 — 기존 `phase_thresholds` + 신규 `phase_buffs`로 HP 트리거 처리, 시그니처용 받음/사망/N턴 트리거는 `EnemySignatureSystem`에 직접 hook
- T3-MIMIC, T3-STANCE 미구현 — 도교 음양 시그니처가 STANCE 효과를 자동으로 제공
- 미적용 5 monsters (cursed_monk SPECIAL, snake, cyclops, sand_scout, sand_ifrit)는 자체 특수 패턴 보유로 의도적 단순 유지

**디자인 스펙**: `docs/game_design/monster_mechanics_v1.md`

---

## Milestone 6.6 — 이벤트·렐릭 다양화 v2 ✅ (PR #104~#107)

### 6.6-1. 신규 EffectType 인프라 ✅ (PR #104)
- ✅ `EventChoiceResource` 신규 enum 3종: `TRIGGER_BATTLE`, `MULTI`, `ADD_CARD`
- ✅ 신규 필드: `secondary_effect_type/value` (MULTI), `success_chance` + `alt_effect_type/value` (확률), `reward_effect_type/value` + `encounter_tier` (TRIGGER_BATTLE), `card_id` (ADD_CARD), `required_hero_id` (조건부)
- ✅ `event_scene.gd` 핸들러 확장: 다중 효과·확률·조건부 비활성화 처리
- ✅ `game_manager.gd:start_event_battle()` + `_apply_event_battle_reward()` — 이벤트→전투→보상 흐름
- ✅ i18n 키 7종 추가 (battle / battle_elite / chance / add_card / add_card_named / requires_hero)

### 6.6-2. 22개 중복 이벤트 다양화 ✅ (PR #104)
단순 양자택일 → TRIGGER_BATTLE / MULTI / 확률 / 조건부:
- act1(2): prometheus_fire(확률), circe_magic(MULTI)
- act2(4): book_of_the_dead(TRIGGER_BATTLE), anubis_judgment(MULTI), nile_flood(MULTI), mummy_curse(엘리트 전투)
- act3(5): odin_ravens(확률), ragnarok_prophecy(MULTI), mimirs_well(MULTI), dragon_gold(엘리트 전투), frost_giant_corpse(확률)
- buddhist(4): mara_illusion(확률), monk_blessing(MULTI), temple_trial(전투), nirvana_gate(MULTI)
- daoist(4): immortal_duel(전투), dao_purification(MULTI), cosmic_remnant(MULTI), vermilion_rebirth(확률)
- japanese(3): oni_shogi(전투), kappa_river_crossing(MULTI), tengu_training(musashi 조건부)

### 6.6-3. 신규 이벤트 5종 ✅ (PR #104)
- act2: `sphinx_gate` (확률+MULTI: 70% 카드 제거 + 골드)
- act3: `ymir_blood` (TRIGGER_BATTLE 엘리트 → 렐릭)
- buddhist: `bodhi_tree` (HEAL +40 + 영구 드로우 +1 MULTI)
- daoist: `eight_immortals` (50% 렐릭+골드, 50% HEAL)
- japanese: `kitsune_kit` (60% 렐릭, 40% HEAL — 다중 분기)

### 6.6-4. 5개 렐릭 차별화 + condition_value 확장 ✅ (PR #104)
중복 패턴(BATTLE_START→BLOCK/ENERGY/DRAW, BATTLE_WIN→HEAL) 차별화:
- `_scarab_talisman` BLOCK 8 → APPLY_STATUS_ENEMY poison 4
- `_ankh_of_life` BATTLE_WIN HEAL → ON_HERO_DAMAGED + condition_value 10 (10+ 피해 시 HEAL 5)
- `_idun_apple` BATTLE_WIN HEAL → PLAYER_TURN_END HEAL 3 (지속)
- `_dharma_seal` BATTLE_START ENERGY (iron_will과 동일) → PASSIVE MAX_HP +20
- `_tengu_feather` BATTLE_START DRAW (tacticians_map과 동일) → BATTLE_WIN DRAW +2
- ✅ `condition_value` 처리를 HEAL/BLOCK까지 확장 (game_manager._apply_relic_effect)

### 6.6-5. 카탈로그 스크립트 확장 ✅ (PR #105)
- ✅ `_choice_effect_name`에 TRIGGER_BATTLE/ADD_CARD/MULTI 추가
- ✅ `_choice_summary` 신규: 비용·주효과·보조·확률·전투·조건 통합 표시
- ✅ events.csv 9 → 19 컬럼 확장 (보조효과/확률/실패/전투티어/보상/카드ID/필요영웅)
- ✅ relics.csv: condition_value > 0 시 "값 (피해 ≥N)" inline 표시 (ankh_of_life, blood_stone)

### 6.6-6. 사전 작업 fail 37개 정리 ✅ (PR #106)
- ✅ `relic.status_type` 무시 버그 수정 (`_orochi_scale` weak 부여 회복; fallback poison 유지로 기존 5종 무회귀)
- ✅ 영웅 weak/vulnerable 감소 테스트 수정 (영웅 status는 `end_player_turn` 시 감소 — 적과 대칭)
- ✅ FLOORS=15 확장 반영 (test_map_generator/test_game_manager 노드 카운트·보스 ID·floor 검증을 가변 범위로)
- ✅ i18n 키 마이그레이션 (적 7개·이벤트 4개·렐릭 7개 한국어 → i18n 키)
- ✅ 카드 풀 카운트 동기화 (나폴레옹 5/9, 잔다르크 부활 4) + LOCALES 8 → 9 (zh_TW)

### 6.6-7. PASSIVE 트리거 버그 수정 + 통합 테스트 ✅ (PR #107)
- ✅ **PASSIVE 트리거 미적용 버그 수정**: `add_relic`에서 PASSIVE 렐릭 즉시 `_apply_relic_effect` 호출 (방금 추가한 relic만 — `trigger_relics` 전체 호출은 중복 부여 위험). `_dharma_seal` / `_ancient_artifact` / `_cursed_crown` MAX_HP 보너스 실효 회복.
- ✅ 테스트 인프라: GM에 `_test_tm/dm/bm_override` 의존성 주입 hook (production 영향 0). `_apply_relic_effect`의 over-defensive `is_inside_tree()` 가드 제거.
- ✅ `tests/test_event_integration.gd` 신규 +8: TRIGGER_BATTLE 보상 흐름, pending_event_battle_reward 수명주기, required_hero_id + cost_gold 조건부
- ✅ `tests/test_relics.gd` +6: 신규 렐릭 5종 동작 + PASSIVE 적용 검증

**최종 상태**: **1365 테스트 통과 / 0 fail** (이전 1312 passed, 37 failed → 누적 +53 PASS / -37 fail)

**수동 검증 필요** (헤드리스 불가):
- 이벤트 → 전투 진입 시 씬 전환 + BGM 변경
- 조건부 선택지 회색 비활성화 시각 표시
- 새 태그(전투/카드추가/확률) 표시

---

## Milestone 6.7 — 이벤트 UX 마무리 ✅ (PR #108~#110)

### 6.7-1. 무의미 NONE 옵션 일괄 재설계 ✅ (PR #108)
- ✅ 모든 이벤트 선택지에 의미 있는 trade-off 부여 — "효과 없음" NONE 선택지 제거 또는 새 메커니즘으로 대체
- ✅ 일관된 비용/보상 구조 정립

### 6.7-2. 이벤트 choice 라벨 i18n 갱신 ✅ (PR #109)
- ✅ 약 45개 이벤트 choice 라벨 다국어 갱신 (새 효과 반영)
- ✅ 선택지 텍스트가 행동 이름만 명시, 효과는 태그가 전담

### 6.7-3. 시스템 대규모 개선 + 버그 수정 ✅ (PR #110)
- ✅ **autoload 버그 수정**: `Engine.get_singleton(autoload)` → `get_node("/root/...")` (autoload 는 노드, singleton 아님). 전투 렐릭·세이브 무력화 회복
- ✅ i18n: 손상된 이벤트 번역키 복구, choice 레이블 정리, 행동 이름↔효과 불일치 7건 수정
- ✅ 렐릭: 성스러운 두루마리 1/2/3턴 드로우+2 3종으로 재설계 (PERM_DRAW 폐기)
- ✅ 이벤트 효과 태그 시스템 재작성 — 확률 분기 "N% → 효과" 묶음, 보상/페널티 색상 구분, NONE 에 "효과 없음" 태그
- ✅ **카드 제거 UI 통합** — `card_removal_overlay` 공용 컴포넌트로 추출 (상점·이벤트 공유)
- ✅ 미라의 저주 무의미 선택지 → 카드 봉인(제거)
- ✅ UI: 맵 씬 골드 표시, 비활성 버튼 호버 사운드 제거
- ✅ 통합 테스트: 두루마리·확률 분기·카드 제거

---

## Milestone 6.8 — VFX 시스템 v1 ✅ (PR #111~#113)

> HTML 데모(`ui_sample/vfx/`) 기반 VFX 20종 GDScript 포팅 + 임팩트 시점 동기화 + 게임 속도 옵션 hook.
> M7-5 애니메이션/이펙트 의 핵심 항목 완료.

### 6.8-1. 공격·상태·버프 VFX 20종 GDScript 포팅 ✅ (PR #111)
- ✅ **공격 VFX (12종)**: lightning_beam, ice_shards, fire_blast, poison_splash, arrow_shot, explosion_blast, blunt_smash, bullet_shot, holy_strike, holy_slash, holy_arrow, holy_fire, holy_blunt, charm_kiss, blood_spray
- ✅ **상태/지원 VFX (4종)**: stun_stars, death_dissolve, revive_blessing, heal_blessing
- ✅ **버프 VFX (3종)**: holy_buff (Joan POWER 황금), warrior_buff (그 외 영웅 POWER 분노 주황), defense_buff (BLOCK 6각 dome + barrier + 룬링)
- ✅ **반함 VFX (1종)**: infatuation (charm 임계치 도달 시 charm_kiss 대신 발동, 붉은 계통)
- ✅ 모든 VFX 가 `signal screen_effect` + 2-layer blend (`_smoke_layer` 일반 + `_glow_layer` 가산) 패턴
- ✅ Joan damage_type 분리: divine 11장 → holy_strike / holy_blunt / holy_fire / holy_bolt 4가지
- ✅ Napoleon salvo: projectile → bullet (bullet_shot 별도 VFX)
- ✅ `vfx_preview.tscn` 디버그 씬 (F6 로 모든 VFX 미리보기)
- ✅ 단위 테스트 11종 (정적 도형 함수 검증)

### 6.8-2. divine damage_type → holy 계열 일괄 이주 ✅ (PR #112)
- ✅ Musashi 카드 3장 (void_sword/mushin_blade/clear_wind) → holy_slash
- ✅ 적 인텐트 108개 — target+신화 기반 자동 매핑:
  - ALL → holy_fire (30개), LOWEST_HP → holy_arrow (21개)
  - Buddhist/Egyptian/Greek RANDOM → holy_strike (29개)
  - Daoist/Japanese RANDOM → holy_slash (24개)
  - Norse RANDOM → holy_blunt (4개)
- ✅ 잔여 divine 0건. 신화 5개 모두 (Buddhist 40 + Daoist 35 + Egyptian 17 + Greek 7 + Japanese 2 + Norse 7)

### 6.8-3. 임팩트 시점 동기화 + 게임 속도 옵션 hook ✅ (PR #113)
**핵심 설계**:
- ✅ 각 VFX 스크립트에 `const IMPACT_DELAY` 상수 노출 (차지+비행 합 = `screen_effect` emit 시점). 단일 진실
- ✅ `battle_manager` 신규 시그널: `intent_vfx_charge_start(enemy_index, intent, target_hero_id)`, `card_vfx_charge_start(card, target_enemy_index, target_hero_id)`, `poison_tick_applied(target, amount)`
- ✅ `_execute_intent` / `_apply_card_effects` async 변환 — 시그널 emit → `await IMPACT_DELAY` → 데미지/상태 적용
- ✅ `_card_busy` 플래그 + `_start_card_effects` wrapper — 영웅 카드 빠른 입력 시 두 번째 카드 차단 (play_card 동기 유지, test 호환)
- ✅ battle_scene 신규 핸들러 (`_on_intent_vfx_start` / `_on_card_vfx_start` / `_on_poison_tick`) — VFX 차지 시작 책임 일원화. 기존 데미지 핸들러는 SFX·flash·shake·tint·hurt 애니만
- ✅ 적 단일 타겟 인텐트 — battle_manager 가 시그널 emit 전에 RANDOM/LOWEST_HP 타겟 미리 결정 → 정확한 영웅에 VFX (셋 중 가운데/둘 중 왼쪽 잘못 표시 버그 수정)

**GameSettings autoload (신규)**:
- ✅ `vfx_speed_multiplier` (default 1.0=보통)
- ✅ `monster_interval_multiplier` (default 1.0=빠르게=현재 turn_interval)
- ✅ `anim_speed_multiplier` (default 1.0=빠르게, `AnimationPlayer.speed_scale`)
- ✅ `particle_quality` (default 2=상)
- ✅ save/load + UI(graphics/gameplay 탭)는 별도 PR 예정. battle_manager 가 `get_node_or_null("/root/GameSettings")` 안전 접근 (CLI test 호환)

**시각/SFX 매핑·통일**:
- ✅ curse damage_type 시각이펙트 → debuff_hex 빔 통일 (impact-only `_VFX_SCENES["curse"]` 제거)
- ✅ holy_* / debuff / charm SFX 매핑 helper — 자원 없는 키를 기본 계열로 재활용 (holy_slash→impact_slash, holy_blunt→impact_blunt, holy_arrow→impact_projectile, holy_fire→impact_fire, weak/vulnerable→impact_curse, charm/enthrall→impact_divine)
- ✅ buff/heal/defense SFX — `_spawn_holy_buff`/`_spawn_warrior_buff`/`_spawn_defense_buff`/`_spawn_heal_blessing` 의 `screen_effect` 콜백에 직접 SFX 연결 (이중 호출 방지)

**버그 수정**:
- ✅ 무심검(CONDITIONAL_DMG holy_slash) 등 DAMAGE 변종 VFX 누락 — `effect.damage_type != ""` 체크로 모든 DAMAGE-like effect 처리 (CONDITIONAL_DMG, DAMAGE_PER_*, SACRIFICE_PAYOFF, ENERGY_TO_DAMAGE 등)
- ✅ 사망한 적/영웅에 ALL 효과(BLOCK_ALL/HEAL_ALL/VFX) 적용 차단
- ✅ 모래폭풍(DAMAGE ALL curse + WEAK ALL) — 적당 debuff_hex 빔 2개씩 표시 → did_attack/did_debuff 플래그로 중복 방지
- ✅ 매혹 카드 `EffectType.CHARM` 분기 누락 — VFX 안 나오던 버그 수정
- ✅ 매혹 → enthrall(반함) 임계치 도달 시 infatuation VFX 자동 분기 (`will_enthrall_enemy` helper)
- ✅ character_placeholder flash shader `COLOR.a = 1.0` 강제 제거 — weak/vulnerable status 적용 시 캐릭터 영역에 불투명 주황 사각형이 표시되던 버그 (vfx_preview 엔 placeholder 가 없어 재현 안 됨)
- ✅ 신화 시그니처 발동 시 적 panel 위 140→364px ColorRect 사각형(`_burst_signature_at_enemy`) 비활성 — 토스트 라벨이 이미 표시
- ✅ 화면 플래시(`_play_screen_flash`) 비활성 — 매 스킬마다 전체 화면 번쩍이 너무 강함
- ✅ 카드 드래그 중(MOUSE_HIDDEN) 전투 종료 시 마우스 잔존 — `_on_battle_won`/`_on_battle_lost` 에서 드래그 정리 + `Input.mouse_mode = VISIBLE`

**차지 시간 절반 (피드백 반영)**:
- ✅ poison(0.6→0.3), debuff_hex(0.65→0.32), fire/ice/holy_strike/holy_fire(0.65→0.32), holy_arrow(0.30→0.15), holy_slash(0.38→0.19), holy_blunt windup(0.35→0.18), charm_kiss(0.7→0.35)

**poison_tick 신규**:
- ✅ `scenes/vfx/poison_tick.gd` — poison_splash 의 잔류 가스 + 보글 거품 + 발 아래 초록 웅덩이 추출. 차지/비행 없이 1.2s 즉발. impact_poison SFX
- ✅ `BattleManager.poison_tick_applied` 시그널 emit (`_tick_hero_poison` / `_tick_enemy_poison` 끝)
- ✅ poison_splash POISON_TIME 3.0 → 1.5

**vfx_preview 디버그**:
- ✅ screen_effect 시점에 화면 중앙 "💥 IMPACT" 라벨 (1초 페이드)
- ✅ info 라벨에 IMPACT_DELAY 자동 표시

**Phase 2 ✅ (PR #114)**:
- ✅ `settings_overlay` graphics 탭 — 파티클 갯수 옵션 (4단계: minimal/low/medium/high — `0.1/0.25/0.5/1.0`. 저사양 대응 minimal 추가는 PR #115 후속)
- ✅ 신규 gameplay 탭 (vfx_speed/anim_speed/monster_interval 4단계 segment)
- ✅ ConfigFile 기반 `GameSettings.save_settings() / load_settings()` (`user://game_settings.cfg`)

---

## Milestone 6.10 — 전투 시스템 v3: 개체별 ATB + 카메라 줌 ✅ (PR #121~#125)

> 라운드 기반 (플레이어 턴 ↔ 적 턴) → **33옵스퀴르 식 영구 ATB 큐** (영웅 1명·적 1마리씩 speed 순). 카메라가 본인 차례 영웅 줌인. 영웅별 덱·핸드·에너지 완전 분리.

### 6.10-1. 영구 큐 (ATB) 차례 시스템 — PR #121
- ✅ `HeroResource.speed` / `EnemyResource.speed` (영웅 50~60, 적 grade 폴백 NORMAL 45 / ELITE 53 / BOSS 65)
- ✅ `BattleManager._turn_queue_at[actor_id]` — 가장 작은 값이 다음 차례, 동률은 영웅 우선
- ✅ 차례 종료 시 `1000/speed` 충전. 사망/소환/부활 시 큐 자동 동기화
- ✅ 시그널: `turn_started`/`turn_ended`/`turn_queue_changed`
- ✅ 라운드 개념 제거 — Power/Relic/카드 효과 모두 본인 차례 단위로 재정의

### 6.10-2. DeckManager 영웅별 분리 (v3 직렬화)
- ✅ `Dictionary[hero_id → {draw, hand, discard, exhaust, energy, pending_*, cards_played, draws}]`
- ✅ 새 API: `setup_for_battle`, `start_hero_turn`, `end_hero_turn`, `draw_cards_h`, `play_card_hero`, `get_hand(hid)`, `get_energy(hid)` 등
- ✅ Legacy property (`hand`, `current_energy`, ...) read-only 합산 + 첫 영웅 ref (in-place 수정 호환)
- ✅ to_dict/from_dict **v3** 포맷, 카드 `owner_id` 자동 분배

### 6.10-3. 카드 효과·Power·Relic 본인 차례 단위 재정의
- ✅ 카드 효과 9개 (COST_NEXT / COST_ZERO_TURN / BLOCK_PER_CARDS_PLAYED / ON_KILL_DRAW / DRAW_PER_ENTHRALL / PER_DRAW_DMG / DOUBLE_NEXT_DAMAGE / DAMAGE_PER_HAND_SIZE / ENERGY_TO_DAMAGE) — `owner_id` 영웅 단위
- ✅ Power 6개 — `ctx.hero_id != owner_id` skip, 본인 영웅 차례에만 발동
- ✅ Relic 44개 — owner_hero_id 본인 차례만, HEAL/ENERGY/DRAW/BLOCK 효과 본인 영웅 단위

### 6.10-4. UI — 카드 핸드·turn queue·인트로 — PR #121·#122
- ✅ 본인 차례 영웅 핸드만 표시 (`get_hand(hid)`) + 본인 에너지 표시
- ✅ 차례 라벨에 현재 영웅/적 이름
- ✅ 좌상단 turn queue 미리보기 위젯 (다음 5차례) — `get_turn_queue_preview(count)`
- ✅ 배틀 인트로 — 1초 줌아웃 + "전투!" 타이틀 (`battle.msg_intro` 9 언어)
- ✅ 모든 차례 전환에 동일 인터벌 — `GameSettings.turn_interval_multiplier` (이전 monster_interval rename)

### 6.10-5. 테스트 마이그레이션 — PR #123
- ✅ **1465 passed / 0 failed** (이전 77 failed)
- ✅ test_deck_manager 전면 재작성 (영웅별 API), test_battle_manager `_execute_enemy_turn` 직접 호출, test_relics ctx.hero_id 전달 등 (11 파일)

### 6.10-6. 차례 카메라 줌 + 덱 보기 + 설정 — PR #124
- ✅ `CamState` 머신 (IDLE_FAR / HERO_FOCUS / DRAGGING / VFX_PLAYING)
- ✅ 영웅 차례 줌인 1.3x, 적 차례·드래그·VFX 줌아웃. VFX 종료 = 노드 free 시점 (임팩트 X)
- ✅ UI/카드/드래그 화살표 `_ui_layer` (CanvasLayer layer=5) 분리 — 카메라 zoom 영향 제거
- ✅ 덱 보기 영웅별 탭 (TabContainer), 현재/마지막 차례 영웅 기본 활성, AccentLabel 색·BRASS 라인 통일
- ✅ 설정 — 영웅 줌인 on/off, 카메라 줌 속도 3단 (slow/normal/fast), background 옵션 제거
- ✅ i18n — 덱 보기 라벨 (현재 덱/사용한 덱/이용불가, 9 언어), `ui.settings.hero_zoom`/`cam_zoom_speed`, `ui.settings.kill_cam` 단축

### 6.10-7. 적 패널 사이드바 트윈 — PR #125
- ✅ 영웅 줌인 시 화면 밖으로 잘리는 적의 UI (name/hp/intent/status/sig) 만 화면 우측 2x3 grid 사이드바로 트윈
- ✅ 화면 안 fully visible 적은 base 위치 그대로
- ✅ 노드 reparent 없이 매 frame lerp (z_index / layer 변경 X)
- ✅ 사이드바 빈칸 없이 sequential 채움 (우 위→우 아래→중 위→중 아래→좌 위→좌 아래)
- ✅ 사이드바 활성 시 적 base panel/btn `mouse_filter = IGNORE` (cam zoom 차단 회피)
- ✅ `_relic_container` 폭 화면 좌측 1/3 축소 + `mouse_filter = PASS` (sig_icon hover 차단 해결)
- ✅ Shift+M 디버그 — 몬스터 다중 선택 전투 (장바구니식)

### 6.10-8. 밸런스 (speed)
- ✅ 영웅 6 명 speed 50~60 (편차 줄임). 적 grade 폴백 NORMAL 45 / ELITE 53 / BOSS 65 — 보스가 영웅보다 빠름

### 후속 (이 마일스톤 후 별도 PR)
- 🔲 Power/Relic 본인 영웅 차례 발동이 N×될 가능성 — 영웅 HP/렐릭 밸런스 튜닝 (실제 플레이 피드백)
- 🔲 DISCARD_PICK_DRAW 등 일부 디테일 본인 영웅 단위 정리 (`_apply_discard_pick_reward`, `on_kill_energy` power 등 첫 영웅 fallback 잔존)

---

## Milestone 6.11 — 전투 UX 폴리싱 v3 ✅ (PR #126)

> M6.10 실전 사용 피드백 — 차례 인터벌 미세 조정, 인텐트 정보 가독성, 상태이상 UI 시각 일관성, 디버그 도구 안정성.

### 6.11-1. 차례 인터벌 fine-tuning
- ✅ 영웅→영웅 1x (빠른 패스), 영웅→적 / 적→영웅 2x, 적→적 3x
- ✅ 적 차례 시작 + 독 tick 인터벌 강화 (이전: 공격과 독 tick 거의 동시 발화)
- ✅ 영웅 종료 후 인터벌 제거 — 영웅 간 전환에서 사용자 입력 지연 최소화

### 6.11-2. 적 인텐트 hover tooltip
- ✅ 모든 action_type (ATTACK/BUFF/DEBUFF/PREPARE/HEAL_ALLY/BUFF_ALLY/COUNTER_PREPARE/MARK_TARGET/SACRIFICE/WARD/SUMMON/MIMIC/SPECIAL 등) 에 자세한 tooltip
- ✅ SPECIAL 의 status_type 별 분기 (remove_card/summon/generic/unknown)
- ✅ `battle.intent.tooltip.*` 25 신규 i18n 키 (9 언어 — 한국어/영어 정확, 나머지 영어 fallback)
- ✅ intent_lbl `z_index 1230` + btn 에도 동일 tooltip 부착 — base 시 btn(SLOT 전체 영역) 위 hover, 사이드바 시 intent_lbl 직접 hover 모두 작동

### 6.11-3. 상태이상 UI svg 아이콘 21 종
- ✅ 시그니처 6: sig_greek (휴브리스), sig_norse (라그나로크), sig_egyptian (호루스의 눈), sig_buddhist (법륜), sig_daoist (음양), sig_japanese (도리이+결계)
- ✅ 활성 파워 15: power_bonus_per_hit, power_charm_double_apply/threshold_minus, power_debuff_amplify, power_double_next_damage, power_echo_next_attack, power_every_nth_attack_bonus, power_morale_per_turn, power_on_enthrall_strength, power_on_kill_energy, power_poison_double_application, power_sacrifice_bank, power_strength_player, power_summon_per_turn, power_token_bonus_dmg
- ✅ 모두 신성 테마 (256×256, 외곽 황금 링 #c9a84c + 신화별 색상 또는 보라 power 톤)
- ✅ `.gitignore` 화이트리스트 추가, `_preview.html` 신규 탭 (시그니처/파워) + status 누락 4종 보강

### 6.11-4. 파워 tooltip — 시전자 영웅 이름
- ✅ 기존 `tr(base_key + ".desc")` 중복 표시 제거 (옆 라벨이 이미 효과 설명)
- ✅ tooltip = `tr(hero.hero_name)` — `__global__` owner 는 부착 X
- ✅ Shift+T 디버그 시 영웅 이름 i18n 키 검사 가능

### 6.11-5. GDScript 워닝/런타임 에러 정리
- ✅ `_format_intent_tooltip` `tr() %` → `_trf` 교체 — Shift+T 번역 제거 모드에서 specifier 없는 키 string 에 args 적용 시 크래시 해결
- ✅ `_enemy_sidebar_t` 미사용 변수 + 트윈 line 제거, `sb_idx / 2` `@warning_ignore("integer_division")`
- ✅ VFX 3 종 (blood_spray / death_dissolve / revive_blessing) 의 인터페이스 통일용 signal 에 `@warning_ignore("unused_signal")`
- ✅ `ui_sound._on_node_added` — meta flag `_ui_sound_connected` 로 중복 connect 차단 (reparent 시 'already connected' 에러)
- ✅ `card_scene._build_desc` — `get_node("/root/BattleManager")` 절대 경로 → autoload 직접 참조 (tree 진입 전 호출 에러 해결)

---

## Milestone 6.12 — 영웅 별명 + i18n 통일 ✅ (PR #128)

> 스토리 설정: **영웅들이 현생 기억을 잃어 자신의 이름을 모름**. 본명 대신 영웅적 칭호(별명) 사용. 4 csv 488 셀 일괄 치환 + 누락 번역키 ~150 셀 채움.

### 6.12-1. 영웅 .name 별명화 (9 언어)
- ✅ 나폴레옹 → 아우스터리츠의 태양 / Sun of Austerlitz
- ✅ 클레오파트라 → 마지막 파라오 / The Last Pharaoh
- ✅ 이순신 → 불패의 통제사 / The Undefeated Admiral
- ✅ 잔다르크 → 오를레앙의 성녀 / The Maid of Orléans
- ✅ 칭기즈칸 → 초원의 정복자 / Lord of the Steppe
- ✅ 무사시 → 두 자루의 검객 / The Twin-Blade Swordsman
- ✅ `.figure` 키 (본명) 는 코드 미사용 — 메타 정보로 유지

### 6.12-2. 메커니즘/시너지 desc 본명 → 직함 일괄 치환
- ✅ 황제/파라오/통제사/성녀/정복자/검객 (각 9 언어 매핑)
- ✅ 단축형 (Napo / Joan / Cleo / Yi / Jeanne / Giovanna / Juana / Gengis / Cléo) word-boundary regex 치환
- ✅ 그리스어 격변화 (Ναπολέοντα, Ιωάννας 등) + 더블 정관사 (`ο ο` → `ο`) 후처리
- ✅ 488 셀 치환 (relic 117, synergy 328, card 34, event 9)

### 6.12-3. 1인칭 유물 4종 .name 추상화
- ✅ 난중일기 → 통제사의 일지 / Admiral's Journal
- ✅ 오를레앙 깃발 → 백합의 깃발 / Banner of the Lily
- ✅ 니텐이치류 → 이도류 비전 / Twin-Blade Doctrine
- ✅ 오륜서 → 검리의 서 / Treatise of the Blade
- ✅ 신화 유물 (mjolnir/ankh/eye_of_horus 등 인류 공동 자산) 은 유지

### 6.12-4. 누락 번역키 일괄 채움 (~150 셀)
- ✅ battle.intent.tooltip.* 26 키 (ja/el/zh/zh_TW 영어 그대로 → 정확 번역)
- ✅ joan_of_arc archetype 12 키 (축복/성전/정화/깃발 4 분류)
- ✅ 시그너처 toast 6 종 (hubris/ragnarok/egyptian_curse/karma/yin_yang/kekkai)
- ✅ status 누락 (poison.desc + 7 .name) + power 누락 (double_next_damage/heal_per_turn/on_enthrall_strength/on_kill_energy)
- ✅ effect.*.text 12 (damage/apply_status/heal_per_dead_ally/purge_status/status_double 등) + 카드 4 typo
- ✅ turtle_power.name fr/it/es/el, ui.vol_master fr/it/es/el

### 6.12-5. UI 보정
- ✅ turn queue 슬롯 가로 80 → 96 (별명 길이 증가 대응)

---

## Milestone 6.13 — speed 시스템 ✅ (PR #129)

> 영웅·적 `speed` 스탯에 동적 buff/debuff 시스템 추가. 카드 6 (영웅별 1) + 유물 2 (보편) + turn queue 즉시 재연산.

### 6.13-1. 백엔드 — speed 동적 합산
- ✅ `_hero_effective_speed` / `_enemy_effective_speed` = base + `status.speed_bonus` − `speed_penalty` + `power.speed_buff`
- ✅ status: `speed_bonus` + `speed_bonus_dur`, `speed_penalty` + `speed_penalty_dur` (poison_dmg/poison_dur 패턴, 매 턴 dur 만 −1, 0 도달 시 value 도 0 — 일정 효과)
- ✅ APPLY_STATUS target 에 `ALL_ALLIES` / `ALLY` 추가 (파티원 buff)
- ✅ 신규 EffectType `BUFF_SPEED` / `DEBUFF_SPEED` (value=강도, bonus_value=duration)

### 6.13-2. turn queue 즉시 재연산
- ✅ `_adjust_turn_queue_for_speed_change(actor_id, old_speed)` — speed 변경 후 `_turn_queue_at[actor_id] = 기존 × (old_speed / new_speed)` 비율 보정
- ✅ `turn_queue_changed.emit(get_turn_queue_preview())` → UI 즉시 갱신
- ✅ BUFF/DEBUFF_SPEED 효과 처리 직후 + `power.speed_buff` 등록 후 호출

### 6.13-3. 카드 6 종 (영웅별 1)
- ✅ 나폴레옹 전격 진군 — 본인 +5 (3턴), 1코 U
- ✅ 클레오파트라 유혹의 정체 — 적 1 −5 (3턴), 1코 U
- ✅ 이순신 거북선 점호 — 파티 전원 +4 (4턴), 2코 R
- ✅ 잔다르크 성령의 가호 — 파티원 1 +4 (3턴), 1코 U
- ✅ 칭기즈칸 기마 돌격 — 본인 +6 (3턴), 1코 R
- ✅ 무사시 신속의 검 — 본인 power.speed_buff +6 (전투 끝), 2코 R POWER

### 6.13-4. 유물 2 종 (보편)
- ✅ 신속의 인장 — BATTLE_START 시 모든 영웅 power.speed_buff +3 (전투 끝까지)
- ✅ 시간의 모래시계 — 영웅 차례 5회마다 모든 영웅 power.speed_buff +1 누적
- ✅ RelicResource.EffectType 에 BUFF_SPEED_TEAM, TIME_HOURGLASS 추가
- ✅ BattleManager._hourglass_counter (전투 시작 시 0 리셋)

### 6.13-5. CP 테이블 + balance_check
- ✅ `SPEED_PER_TURN_V = 0.08`, `SPEED_POWER_V = 0.40`
- ✅ ALLY 배수 1.1, ALL_ALLIES 1.8, ALL_ENEMY 1.5
- ✅ balance_check EffectType 40/41 + `power.speed_buff` 분기 추가
- ✅ card_value_table.md 갱신
- ✅ balance_check 전체 통과 (CP 246 OK + upgrade 50 OK + 중복 0)

### 6.13-6. i18n 21 키 × 9 언어
- ✅ 카드 .name 6, 유물 .name+.desc 4, effect.buff/debuff_speed.* 5, status.speed_bonus/penalty.{name,desc} 4, power.speed_buff.{label,desc} 2

### 6.13-7. 테스트
- ✅ 1448 passed / 0 failed
- ✅ 영웅별 카드 풀 31장 + archetype/rarity 카운트 갱신
- ✅ 유물 풀 42 종

---

## Milestone 6.9 — 전투 UX 폴리싱 v2 ✅ (PR #115)

> M6.8 후 실전 사용 피드백 기반 — VFX 동기화 정확도, popup 시각효과, 카드 입력 흐름, 툴팁 통일.

### 6.9-1. VFX impact 시점 정확 동기화 v2
- ✅ `BattleManager.vfx_impact_resolved` 신호 + `_await_vfx_impact(fallback)` helper
- ✅ battle_scene 의 모든 `fx.screen_effect.connect` 9곳에서 시그널 emit (CONNECT_ONE_SHOT)
- ✅ 기존 timer 보정값(+0.08s) 이 부정확하던 문제 해결 — popup·SFX·flash 가 **동일 frame** 표시
- ✅ fallback timer (`_delay + 0.5s`) — fx 가 emit 안 하는 비정상 케이스 방어

### 6.9-2. 글로벌 툴팁 시스템
- ✅ `SacredTheme.attach_tooltip(ctrl, text)` 글로벌 헬퍼 — 단일 CanvasLayer (layer 100) + Panel + Label
- ✅ 짙은 검정+보라 `Color(0.04, 0.025, 0.08, 0.8)` + BRASS 테두리. 자연 너비, 360px 초과 시만 wrap
- ✅ 모든 `tooltip_text = X` 사용처 17곳 일괄 교체 (battle 12 + map 4 + 시그니처 1)
- ✅ map_scene 의 자체 `_build_room_tooltip` 시스템 제거 → 글로벌 통일
- ✅ Godot 기본 PopupPanel tooltip 의 viewport alpha 합성 문제 회피

### 6.9-3. 신화 시그니처 아이콘
- ✅ 적 panel 우측 상단 — 6 신화별 emoji 아이콘 + 호버 툴팁으로 효과 설명
- ✅ `strings_battle.csv` `signature.{myth}.desc` 키 6종 × 9 언어 등록
- ✅ btn 가림 회피: Label 을 self(battle_scene) 자식 + late add + z_index 100

### 6.9-4. popup 시각효과 (데미지/힐/Block/상태이상)
- ✅ Cinzel-Bold 36px (이전 Inter-SemiBold 28) — Sacred 테마와 일관성
- ✅ 6 레이어 halo outline (alpha 0.05~0.40, outline 6~48px) — 은은한 fuzzy 글로우
- ✅ 메인 Label 흰 톤 (color × 0.15 + white) + 검정 outline 없음 + 그림자 없음
- ✅ VFX HTML 기반 톤다운 색상 — 살구/라임/라벤더/코랄/로즈/골드 (촌스러운 원색 회피)
- ✅ 등장 효과: scale 0→1.3→1.0 punch + modulate 1.4× → 1× 페이드

### 6.9-5. 카드 입력 흐름 + 사망 예측 차단
- ✅ `_card_busy` 제거 → 카드 사용 즉시 다음 카드 입력 가능 (스무스)
- ✅ `_pending_dmg_to_enemy` 추적 — 차지 중 카드의 예측 누적 데미지 (DAMAGE effect, weak/strength/vulnerable)
- ✅ `is_enemy_doomed(idx)`: `effective_hp = current_hp - pending` 0 이하면 사망 예정
- ✅ `play_card` 거부: 사망 예정 적에 단일 타겟 ATTACK 카드 입력 시 즉시 false
- ✅ UI: `pending_damage_changed` → `_update_enemy_ui` → panel modulate 0.5 dim, btn disable, HP 라벨 `13/50 (-15)` 표시

### 6.9-6. HP 블룸 임계치 + 파티클 0.1 + vfx_preview 4-way
- ✅ HP 바 블룸: ratio > 0.40 (정상) intensity 0.0 (이전 0.35 고정 켜짐 버그). 임계치 미만에서만 브리딩
- ✅ `GameSettings.PARTICLE` 4단계 [minimal=0.1, low=0.25, medium=0.5, high=1.0]
- ✅ vfx_preview UI 압축 — 시전자(y=540) 안 가리게: panel y 24→8, grid columns 5→9, button 150→105
- ✅ 비교 모드 3-way → 4-way (x0.1 추가)

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
- ✅ 전투 인터랙션 폴리싱: 부채꼴 핸드(PR #79), 드래그 화살표 베지어(PR #80), 슬롯 Marker2D(PR #81) 완료
- ✅ 상태이상·시너지·렐릭 아이콘 UI (PR #85): 전투 HUD SVG 아이콘 기반 패널 + 툴팁
- ✅ **Sacred UI 디자인 시스템** (PR #86~#88):
  - `autoload/sacred_theme.gd` — 팔레트·테마·셰이더·커서·폰트 통합 관리
  - Theme variation 8종: TitleLabel / SubLabel / EyebrowLabel / AccentLabel / PrimaryButton / VowButton / ChapterButton / IconButton
  - 커스텀 폰트: Cinzel(타이틀) / IMFell English(플레이버) / Inter(UI 본문) / SpaceMono(고정폭)
  - 4방향 별 커서 SVG (64px), 커서 크기 S/M/L/XL 실시간 변경
  - `make_top_ellipse_bloom()` — 상단 골든 그라데이션 블룸 셰이더
  - `make_crosshatch_overlay()` — ±45° 황동색 격자 셰이더 (UV 기반, 해상도 독립)
  - 적용 씬 8개: main_menu / chapter_select / hero_select / map / rest / shop / event / card_pick
- ✅ 맵 화면 룸 아이콘 (PR #88): 7종 SVG + `IconUtils.get_room_icon()` + 15×7 좌표계
- ✅ 카드 픽 / 상점 / 휴식 / 이벤트 화면 배경 (Sacred UI 적용 완료)
- ✅ HP바 bloom halo (PR #90): fill 자식 이동 + 8px halo 공식
- 🔲 전투 화면: 에너지·인텐트 실제 그래픽 아이콘 (현재 텍스트 폴백)
- 🔲 맵 화면: 경로선·배경 그래픽
- 🔲 게임 오버 / 클리어 화면 연출
- ✅ 상태이상 아이콘 (PR #85): SVG 아이콘 기반 HUD 표시 완료

### 7-7. 카드 폴리싱 — 미구현 효과
- 🔲 치명타(Critical Hit) 시스템: 특정 카드/렐릭이 일정 확률로 피해 ×1.5~2.0, HP 바 crit 비주얼 트리거
- 🔲 도발(Taunt) UI 강화: 도발 대상에 아이콘 강조 표시, 인텐트 화살표 변경
- 🔲 크리티컬 HP 상태(15% 이하) 전투 연출: hp_lbl 색상 BLOOD_300, 화면 가장자리 비네트

### 7-5. 애니메이션 / 이펙트
- ✅ **카드 사용 시 이펙트 (공격 임팩트·독 스플래시·방어막) — VFX 시스템 v1 (M6.8, PR #111~#113)**: 20종 GDScript 포팅, 임팩트 시점 동기화, GameSettings autoload hook
- 🔲 히트 스톱 (공격 시 0.1초 정지)
- ✅ 씬 전환 페이드 인/아웃 (`autoload/scene_transition.gd` + CanvasLayer 검정 오버레이)
- 🔲 페이즈 전환 연출 (보스 분노 이펙트)

### 7-6. 오디오 ✅ 기반 완료 (PR #94)
- ✅ 사운드 에셋 요구사항 문서 (`docs/sound_assets_required.md`)
- ✅ `AudioManager` autoload — SFX 풀(16ch) + BGM 크로스페이드 페어 + 버스 볼륨 저장(`user://audio_settings.json`)
- ✅ `UISound` autoload — 전역 BaseButton 호버·클릭 SFX 자동 연결, `no_ui_sound` 메타 opt-out
- ✅ SFX 24종 생성 (-14 LUFS): impact 11종·card 3종·heal/block·ui 2종·death 2종 등
- ✅ BGM 70종 생성 (-18 LUFS): 메뉴×3·신화별 전투×18·보스×36+·이벤트/상점/휴식 (로컬 전용, .gitignore)
- ✅ 신화별 전투 BGM 동적 선택 (`play_bgm_dynamic("battle", myth)`)
- ✅ 보스 페이즈별 BGM 전환 (`boss_phase_changed` 시그널 → `play_bgm_dynamic("boss", id, phase)`)
- ✅ BGM 트랙 종료 후 자동 반복 (동일 카테고리 랜덤 재선택)
- ✅ 동일 카테고리 BGM 재시작 방지 (`_bgm_base_key` 추적)
- ✅ 설정창 사운드 탭 — 마스터·음악·효과음·UI 볼륨 슬라이더 4개
- ✅ 카드 사용·공격 임팩트·방어·피격·적 사망·카드 드로우·호버 SFX 이벤트 연결
- ✅ 라우드니스 정규화 (SFX -14 LUFS / BGM -18 LUFS, ffmpeg loudnorm)
- 🔲 이벤트 BGM 나머지 (dark×3·encounter×2·fortune×2 일부 미생성)
- 🔲 보이스 (캐릭터 전용 보이스 라인 — 선택 사항)

---

## Milestone 7.5 — 배경 시스템 v1 (HD-2D 유사 깊이감)

> 목표: 일러스트 단일 배경 → **2D 다중 레이어 + parallax + DOF 셰이더 + Light2D + SVG 식생/오브젝트** 로
> 옥토퍼스 트래블러 류 깊이감 흉내. 진짜 3D 카메라(SubViewport+Sprite3D) 까지 가지 않고 작업량 1/5 로 80% 시각 효과.
> 톤은 픽셀 아트가 아닌 **SVG flat + 라이팅** — Tunic / Hades 스타일에 가까움.

### 7.5-1. parallax 다중 레이어 시스템
- 🔲 `scenes/components/scene_background.tscn` — `ParallaxBackground` + 5~7 레이어 슬롯
- 🔲 레이어 motion_scale: sky(0.05) / far(0.15) / mid(0.4) / near(0.7) / fg(1.0)
- 🔲 카메라 micro-sway (battle_scene 카메라 좌우 ±20px 자동 흔들림 — 고정 화면도 깊이감)
- 🔲 신화별 팔레트 적용 (greek=청·황금 / norse=회·푸른 / egyptian=황·주황 / buddhist=주황·녹 / daoist=흑·금 / japanese=홍·먹)

### 7.5-2. DOF (depth-of-field) 셰이더
- 🔲 `assets/shaders/scene_dof.gdshader` — 가우시안 블러, near/far 분리 가능
- 🔲 배경 레이어(sky/far/mid)는 blur 강함, 캐릭터(near) 선명
- 🔲 fg 레이어(앞 바위·식생)는 살짝 blur — bokeh 느낌
- 🔲 GameSettings.particle_quality 와 연동 — minimal 시 DOF off (성능)

### 7.5-3. Light2D 라이팅
- 🔲 신화별 메인 라이트 (점광원 또는 directional) — 색·위치·세기
- 🔲 캐릭터 발 아래 ground shadow (어두운 ellipse 텍스처)
- 🔲 보스/엘리트 spotlight (등장 시 라이트 fade-in + breathing)
- 🔲 배경 ambient 라이트 — 신화별 색조 (egyptian=warm orange, norse=cool blue 등)

### 7.5-4. SVG 식생/오브젝트 라이브러리
- 🔲 `assets/art/scenery/` 디렉토리 — 신화별 서브폴더 (greek/, norse/, egyptian/, buddhist/, daoist/, japanese/)
- 🔲 각 신화당 식생 6~10종 (나무·풀·꽃·바위·기둥·등불·기치 등)
- 🔲 Inkscape 또는 Figma 로 SVG 제작 (외부 작업 — 일러스트 의존도 낮은 도형 위주)
- 🔲 Godot SVG import — `scale = 1.0` 기준 + `texture_filter = NEAREST` 선택 (sharp edge)
- 🔲 BatlleScene 의 _background_for_myth() 가 신화별 SVG 무작위 배치 (각 레이어에 N개 spawn)

### 7.5-5. 통합 + 적용
- 🔲 battle_scene — 일러스트 ColorRect(`bg_tex`) 제거 → ParallaxBackground 로 교체
- 🔲 map_scene — 챕터별 배경 (현재 단일 일러스트) → parallax + 식생
- 🔲 event_scene / shop / rest — 단순 (1~2 레이어) 적용
- 🔲 main_menu / chapter_select — 강화 (5+ 레이어, 라이팅 강조)
- 🔲 vfx_preview 에 배경 파티클(먼지/잎사귀) 토글 디버그 옵션

### 7.5-6. 성능 / 옵션
- 🔲 GameSettings.background_quality (0=off / 1=basic / 2=full DOF + 라이팅)
- 🔲 minimal 파티클 quality 시 자동 background_quality=1
- 🔲 ParallaxBackground 의 enabled toggle (모바일 저사양 fallback)

### 7.5-7. 검증
- 🔲 60fps 유지 (PC 기준 6 레이어 + DOF + 라이트 3개)
- 🔲 모바일 30fps 이상 (background_quality=1 모드)
- 🔲 신화별 톤 일관성 — Sacred 팔레트와 충돌 없음

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

### 8-4-1. 런 중간 저장 & 이어하기
- 🔲 런 진행 중 앱 종료 시 현재 상태 자동 저장 (맵 위치·덱·HP·골드·렐릭 등)
  - `SaveManager.save()` 호출 시점 확장: 씬 전환마다 자동 저장
  - 저장 데이터: `current_node_id`, `current_floor`, `deck`, `heroes HP`, `gold`, `relics`, `run_map`
- 🔲 메인 메뉴에 **이어하기** 버튼 추가
  - 저장된 런이 존재할 때만 활성화
  - 이어하기 클릭 시 해당 씬(맵/전투/이벤트 등)으로 복귀
- 🔲 런 클리어·게임오버 시 세이브 파일 삭제

### 8-5. 성능 최적화
- 🔲 60fps 유지 (저사양 기기 기준)
- 🔲 메모리 사용량 측정 및 최적화
- 🔲 텍스처 아틀라스 적용

### 8-6. 빌드/배포 파이프라인 (현재 미구축)
- 🔲 `export_presets.cfg` 작성 (Windows / Linux / macOS / Android / iOS)
- 🔲 Android 서명 키 생성 + AAB/APK 빌드 스크립트
- 🔲 iOS Apple Developer 인증서·provisioning profile (Mac + Xcode 필요)
- 🔲 GitHub Actions CI — 헤드리스 테스트 자동 실행 (현재 `.github/workflows/` 없음)
- 🔲 릴리스 태그 기반 자동 빌드 배포
- 🔲 **Script Encryption 적용** (PCK AES-256, casual reverse engineering 차단)
  - 32바이트 AES-256 키 생성 + 영구 보관 (분실 시 기존 빌드 패치 불가)
  - Godot 엔진 소스 git clone → `SCRIPT_AES256_ENCRYPTION_KEY=...` 환경변수 + SCons 로 커스텀 export template 빌드 (플랫폼별 각각)
  - `export_presets.cfg` 에 동일 키 등록
  - CI secret 에 키 저장 (GitHub Actions encrypted secret)
  - **개발 영향 없음** — 평소 에디터/F5 그대로. export 시점에만 적용
  - 빌드 파이프라인 셋업과 동시에 1회 작업 권장 (지금 별도 적용 X)

### 8-7. 크래시 리포트·원격 로그
- 🔲 Godot 로그 수집 또는 Sentry SDK 통합
- 🔲 사용자 옵트인 UI (개인정보 동의)

### 8-8. 플랫폼 SDK 통합 (Steam + Google Play Games Services)

> **원칙:** 단일 프로젝트에 PC/모바일 SDK 둘 다 설치. 브랜치 분리 X (머지 지옥). Godot 의 export preset 이 플랫폼별로 필요한 네이티브 라이브러리만 자동 포함하므로 런타임 충돌 0.

**플랫폼 추상화 레이어**
- 🔲 `autoload/platform_services.gd` 신규 — 업적·클라우드 세이브·리더보드 추상화 (호출부는 platform-agnostic)
  - `unlock_achievement(id)` / `submit_score(id, value)` / `save_to_cloud()` / `load_from_cloud()`
  - 내부 분기: `OS.get_name()` → `Steam.*` 또는 `PlayGamesServices.*` 호출
  - `Engine.has_singleton(...)` 가드로 SDK 미설치 환경 (개발 빌드) 안전 fallback

**Steam (Windows / Linux / macOS)**
- 🔲 [GodotSteam](https://github.com/GodotSteam/GodotSteam) addon 설치 (`addons/GodotSteam/`)
- 🔲 Steamworks SDK 다운로드 + Steamworks 파트너 계정 등록 ($100 Steam Direct)
- 🔲 `steam_appid.txt` 추가 (gitignore 등록 — App ID 노출 방지는 아니지만 환경별 분리)
- 🔲 업적 정의 (예: `first_win` / `chapter_1_clear` / `all_heroes_unlock` / `no_relic_run` 등 10~20종)
- 🔲 Steam Cloud 세이브 동기화 (`SaveManager` 의 `user://progress.json` 자동 동기화)
- 🔲 `steamcmd` CLI — CI 자동 빌드 업로드 (GitHub Actions 에서 SteamPipe)

**Google Play Games Services (Android)**
- 🔲 [godot-play-games-services](https://github.com/Iakobs/godot-play-games-services) (또는 동등 플러그인) `.aar` 통합
- 🔲 Google Play Console 에서 Games Services 프로젝트 생성
- 🔲 OAuth2 client 등록 + SHA-1 fingerprint 등록 (debug + release keystore 각각)
- 🔲 업적 정의 동기화 (Steam 과 같은 ID·이름·설명 — 유저가 양 플랫폼 같은 게임으로 인식)
- 🔲 Google Play 클라우드 세이브 (snapshots API)

**iOS (M8-3 진행 시)**
- 🔲 GameKit (Apple Game Center) — 업적·리더보드
- 🔲 iCloud Key-Value Storage — 세이브 동기화
- 🔲 `platform_services.gd` 분기에 iOS 추가

**비목표 (M8-8 범위 밖)**
- 결제 SDK (Steam Wallet / Google Play Billing / Apple IAP) — STSL 은 유료 게임 단판 판매 모델, IAP 없음
- 광고 SDK (AdMob 등) — 광고 X
- 멀티플레이·매치메이킹 — 싱글플레이 게임

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
- ✅ UI 레이블 `tr()` 래핑 (battle_scene·card_scene·shop·map·menu·event·card_pick·rest·hero_select·chapter_select 완료 PR #86~#92)
- ✅ 설정 화면 언어 선택 UI + 커서 크기 세그먼트 컨트롤 + 취소/적용/초기화 버튼 (PR #91)
- ✅ `strings_ui.csv` 이벤트 선택지 키 10종 추가 (PR #92): `ui.event.choose_header`, `ui.event.tag.*` 8개

### 8.5-2. 지원 언어 번역 작업 ✅ (PR #142~#144)
**13 언어 모두 9 csv 전부 번역 완료 — 22,113 셀 빈 셀 0.**
- ✅ 한국어 (ko)
- ✅ 영어 (en)
- ✅ 일본어 (ja)
- ✅ 중국어 간체 (zh)
- ✅ 중국어 번체 (zh_TW)
- ✅ 프랑스어 (fr)
- ✅ 스페인어 (es)
- ✅ 이탈리아어 (it)
- ✅ 그리스어 (el)
- ✅ 러시아어 (ru) — PR #142+#143+#144 (디자인 폰트 매핑 포함)
- ✅ 포르투갈어 (pt)
- ✅ 폴란드어 (pl)
- ✅ 독일어 (de)
- 🔲 베트남어 (vi) — 미지원 (M8.5 범위 밖)

### 8.5-3. i18n 4 언어 시스템 인프라 ✅ (PR #142)
- LocaleManager LOCALES + DISPLAY_NAMES 13개로 확장
- project.godot `locale/translations` 117 entry (9 csv × 13 언어)
- test_locale_manager 13개로 갱신
- 7/9 csv 직접 번역 (hero/synergy/status/relic/battle/ui/enemy = 671행 × 4 언어)

### 8.5-4. card·event 진짜 번역 ✅ (PR #143)
- event 279행 + card 754행 × 4 언어 (ru/pt/pl/de) = 4132 셀
- archetype 일관 매핑 (Assault/Legion/Turtle Ship/Crane Wing 등)
- card 분할 처리 (5 chunk × 134~188 entries)

### 8.5-5. fallback en + ru 디자인 폰트 ✅ (PR #144)
- `locale/fallback` "ko" → "en"
- `SacredTheme._LOCALE_FONTS["ru"]` 추가 — CormorantGaramond/JetBrainsMono/EBGaramond-Italic (el/ path 재사용, 키릴 글리프 포함)
- pt/pl/de — `_LATIN_FONTS` 자동 fallback (라틴 Ext 검증 완료)

---

## Milestone 8.6 — 접근성

- 🔲 색맹 대응: 색만으로 정보 전달 금지 (상태이상·카드 타입에 아이콘·패턴 병행)
- 🔲 자막 토글 (보이스·효과음 자막)
- 🔲 폰트 크기 옵션 (작게 / 보통 / 크게)
- 🔲 키 리바인딩 (선택)
- ✅ 마우스 커서 확대 옵션 — 설정 오버레이에서 S/M/L/XL 4단계 실시간 변경 (PR #91)

> **배경:** 스팀은 접근성 옵션을 권장 태그로 노출. 모바일 스토어는 점차 의무화 추세. 출시 전 최소한의 옵션 확보 필요.

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

### 9-5. 법무·라이선스
- 🔲 개인정보처리방침 (웹 URL 필수 — 모바일 스토어 등재 조건)
- 🔲 EULA (선택, 권장)
- 🔲 라이선스 고지 화면 (Godot MIT / NotoSansCJK OFL / 사용 에셋)
- 🔲 크레딧 스크린

### 9-6. 마케팅·커뮤니티
- 🔲 프레스 킷 (Press Kit) — 로고·스크린샷·설명·연락처
- 🔲 소셜 계정 (Twitter/X, Discord, Reddit 등)
- 🔲 게임 페이지 조기 공개 (itch.io 등)
- 🔲 클로즈드 베타 테스터 모집 + 피드백 파이프라인

---

## Milestone 10 — 스토어 출시

### 10-1. Steam
- 🔲 Steamworks 계정 등록 ($100 앱 ID 1회)
- 🔲 스토어 페이지: 로고·캡슐(헤더·라이브러리·작은)·스크린샷 5~10장·트레일러·태그·설명 다국어
- 🔲 Steamworks SDK 통합: Achievements + Steam Cloud 세이브
- 🔲 Wishlist 페이지 조기 공개 (출시 6개월 전 권장)
- 🔲 지역별 가격·출시일 설정
- 🔲 거래 카드·이모티콘·배경 (선택)

### 10-2. Google Play (Android)
- 🔲 Play Console 개발자 계정 ($25 1회)
- 🔲 Play App Signing 키 생성
- 🔲 스토어 리스팅 + ASO 최적화
- 🔲 데이터 안전 선언 (Data Safety)
- 🔲 테스트 트랙: Internal → Closed → Open → Production
- 🔲 AAB 빌드·업로드

### 10-3. Apple App Store (iOS)
- 🔲 Apple Developer Program ($99/년)
- 🔲 App Store Connect 등록
- 🔲 IDFA·ATT(App Tracking Transparency) 처리
- 🔲 TestFlight 베타 배포
- 🔲 스크린샷(각 기기 크기별)·앱 프리뷰 영상
- 🔲 앱 심사 가이드라인 준수 확인

---

## Milestone 11 — 포스트런치 엔드게임 (출시 후)

> **배경:** MVP 출시 이후 숙련 플레이어의 장기 리플레이어빌리티 확보. Slay the Spire의 Ascension 시스템 같은 다회차 난이도 단계가 표준 해법.
> 출시 차단 요소는 아니지만, 출시 후 첫 메이저 업데이트의 핵심 컨텐츠 후보.

### 11-1. Ascension(승천) 시스템

**핵심 설계 (사전 조사 2026-04-28):**
- **진척도 단위:** 챕터별 (`chapter_ascension_max[chapter] = int`). 영웅별 진척도는 stsl 챕터 분리 구조에 맞지 않아 채택 안 함.
- **단계 수:** 10단계 (A1~A10). 슬더스 20단계는 stsl 컨텐츠 풀(2챕터·6영웅)에 과함.
- **모디파이어 누적 방식:** A_N 클리어 → A_(N+1) 해금. 단계마다 모디파이어 1개씩 추가.
- **모디파이어 카테고리 후보:** 적 HP/공격력 단계 증가, 휴식 회복량 차감, 카드 보상 풀 축소, 시작 HP 차감, 시작 덱 저주 카드 추가, Act 1 엘리트 +1, 보스 HP +20% 등.

**통합 후크 지점 (실제 구현 시):**
- `autoload/progress_manager.gd` — `chapter_ascension_max` 필드 + JSON v2 마이그레이션
- `autoload/game_manager.gd:start_run()` — `ascension: int` 인자 추가
- `autoload/game_manager.gd:_apply_act_difficulty()` — 기존 Act 배율과 ASC 곱셈자 합성
- `autoload/game_manager.gd:_end_run_won()` — ASC 클리어 기록·다음 단계 해금
- `autoload/ascension_modifiers.gd` — 신규 정적 모디파이어 모음
- `scenes/chapter_select/` — 챕터 카드에 ASC 선택 위젯
- `scenes/chapter_clear/` — ASC 클리어 통계 행 + "다음 ASC 도전" 버튼
- `scenes/ui/ascension_unlock_toast.tscn` — `hero_unlock_toast` 패턴 복제
- `resources/translations/strings_ui.csv` — `ui.ascension.*` 키 9언어

**작업 항목:**
- 🔲 11-1-1. ProgressManager 확장 + JSON v2 마이그레이션
- 🔲 11-1-2. AscensionModifiers 정적 모듈 + 모디파이어 10종 정의
- 🔲 11-1-3. start_run / _apply_act_difficulty / 보상 함수 4곳 후크
- 🔲 11-1-4. 챕터 선택·클리어 화면 UI
- 🔲 11-1-5. ASC 해금 토스트
- 🔲 11-1-6. 번역 키 9언어 (모디파이어 설명 10종)
- 🔲 11-1-7. 단위 테스트 (모디파이어 함수 + 진척도 갱신)

### 11-2. (TBD) 데일리 챌린지 / 시드 공유 등 추가 엔드게임 컨텐츠

후보 — 미정.

---

## Milestone 12 — 비주얼 업그레이드 검토: HD-2D 전환 (대규모, 향후 결정)

> 옥토패스 트래블러 / 라이브 어 라이브 리메이크 / 드퀘3 HD-2D 류 — **2D 픽셀 sprite 캐릭터를 3D 환경에 배치 + perspective 카메라**.
> 카메라 dolly/줌 효과의 진짜 원근감이 핵심 ROI. 단순 2D 카메라 zoom 은 균일 확대라 평면 느낌.
>
> **현재 보류 사유:** 작업량 3~5주 (혼자 풀타임). 카드 게임 (Slay the Spire 류) 컨벤션상 균일 줌으로도 충분. 출시 전 또는 후 메이저 업데이트 후보.

### 12-1. Prototype 결과 (PR `feat/hd2d-prototype` 브랜치, 커밋 `0bd136f`, 미머지)
- ✅ `scenes/debug/hd2d_demo.tscn` — Camera3D(fov 28°) + Plane3D ground + Sprite3D billboard 9 캐릭터(영웅3+적6, battle_scene 슬롯 좌표 매핑) + greek 배경
- ✅ 마우스 클릭 ground 점으로 카메라 dolly in/out — 진짜 perspective 변형 동작
- ✅ `scenes/vfx/defense_buff_3d.gd` — defense_buff 의 B안 3D 포팅 (룬링 ground / orb / dome / barrier). ImmediateMesh + Sprite3D billboard + 두꺼운 라인 quad strip + 인접 segment 평균 perpendicular 로 vertex 공유 (틈 방지) + alpha_cut OPAQUE_PREPASS 로 z-buffer 자동 정렬
- ✅ Felt 확인: HD-2D 시각이 평면 2D 보다 명확히 좋음. 다만 풀 전환 작업량 큼

### 12-2. 풀 전환 작업 항목 (착수 시)
- 🔲 **VFX 26개 → 3D 포팅** (가장 큰 병목, 5 PR 단계별 — `scenes/vfx/*_3d.gd` 패턴)
  - PR 1: preview UI + 단순 vfx 3개 (arrow / bullet / stun)
  - PR 2: 블래스트 (fire / ice / lightning / blunt / explosion)
  - PR 3: holy (strike / slash / arrow / fire / blunt)
  - PR 4: 디버프 (debuff_hex / charm / infatuation / poison / poison_tick)
  - PR 5: 버프/사망 (heal / blood / holy_buff / warrior_buff / death / revive)
- 🔲 **battle_scene.tscn 3D 전환** — Camera2D → Camera3D, Marker2D → Marker3D, 캐릭터 → Sprite3D billboard
- 🔲 **캐릭터 위 UI 라벨** (이름/HP/intent) — CanvasLayer 안 Control 을 `camera.unproject_position(char3d.global_position)` 으로 매 프레임 추적
- 🔲 **카드 드래그 타겟팅** — 마우스 → 3D ray (`Camera3D.project_ray_origin/normal`) 로 적 노드 교차
- 🔲 **배경/조명** — Plane3D ground + DirectionalLight3D + 신화별 ambient
- 🔲 **다른 씬 (map / event / shop / rest / menu)** — 2D 유지 (전환 범위 한정)

### 12-3. 핵심 결정 사항 (착수 전)
- VFX A안 (CanvasLayer + unproject 추적, 평면 한계) vs B안 (3D 포팅, 완전 변환) — Prototype 에서 B안이 명확히 좋음 확인
- 작업 분할 — 5 PR 권장 (각 1주, felt 검증 단계별)
- 다른 씬 전환 여부 — battle_scene 만 권장 (map/event 등은 2D 유지)
- 모바일 성능 — 3D 가 2D 보다 fillrate 부담. 그림자 fake (ground decal) 권장

---

## 우선순위 요약

> 최종 갱신: 2026-05-20 v24. PR #180·#181·#182·#183 + 후속 SFX/UI fix 반영 — 카운터 시스템 + VFX 3종 (dispel/form_change/counter, 흑백 postprocess shader + 시간 감속 + Bezier 곡선 streak) + CC UI 대규모 개편 + SFX 신규 12키 + 적 stun 실제 처리 + 패배 우선 처리 + 다수 버그 fix (M6.21).

| 우선순위 | 항목 | 이유 |
|---|---|---|
| ✅ 완료 | 추가 영웅 3명 (M5: 잔 다르크·칭기즈칸·미야모토 무사시) | PR #54~#56 완료. 크로스 시너지 6쌍 |
| ✅ 완료 | 영웅 해금 시스템 (M4-3/4-4) | PR #53 완료. ProgressManager + hero_registry + 토스트 |
| ✅ 완료 | 챕터 2 중·일 신화 (M4-2) | PR #58~#60 완료. 렐릭 풀 40종, 919 테스트 통과 |
| ✅ 완료 | 카드 v2 확장 (영웅당 40장, M5) | PR #63~#66 완료. 978 테스트 통과 |
| ✅ 완료 | 병사 토큰 시스템 (M6-1) | PR #38~#42 + #133 동적 모션 (영구 그리드 폐기·영웅→슬롯 tween·발사 후 복귀) + #136 소환 VFX |
| ✅ 완료 | 권능(POWER) 카드 시스템 정립 (M6-5a) | 명칭·동작·UI·신규 3장 추가 (Plan 26). 245장, 1090 테스트 통과 |
| ✅ 완료 | 적 카드 타입 카운터 메카닉 (M6-5b) | 크로노스·저승 판관·반고. repeat 재발동 버그 수정, 툴팁 번역키화, 상태 아이콘 통합. 1145 테스트 통과 (PR #73) |
| ✅ 완료 | 카드 효과 타입 참조 (M6-5c) | DAMAGE_PER_BLOCK · MULTI_HIT_RANDOM · DAMAGE_PER_STATUS_TYPE 신규 EffectType 구현 (effect_resource.gd) |
| ✅ 완료 | 시스템 완성 M6 (덱뷰어·부활·도발·비밀룸 4종 엔진 구현) | Plan 28, PR #73 완료. 게임 루프 깊이 |
| ✅ 완료 | 번역 인프라 구축 (M8.5-1) | PR #73. CSV 9종·locale_manager·폰트 fallback |
| ✅ 완료 | 전투 UX 기반 폴리싱 (M7 전 단계) | PR #79~#81. 핸드 부채꼴·드래그 화살표·슬롯 Marker2D화 |
| ✅ 완료 | 상태이상·시너지·렐릭 아이콘 UI (M7-4) | PR #85. 전투 HUD SVG 아이콘 패널 + 툴팁 |
| ✅ 완료 | Sacred UI 디자인 시스템 (M7-4) | PR #86~#88. SacredPalette·SacredTheme·폰트·셰이더·커서. 8개 씬 전면 적용 |
| ✅ 완료 | 맵 룸 아이콘·알고리즘 (M7-4) | PR #88. STS 알고리즘·15×7 좌표계·룸 아이콘 7종 SVG |
| ✅ 완료 | 전투 UI 보완 + HP bar bloom (M7-4) | PR #89~#91. Enthrall 아이콘·카운터 아이콘·HP halo·커서 설정 |
| ✅ 완료 | 씬 전환 페이드 인/아웃 (M7-5) | SceneTransition 오토로드 (PR #86) |
| ✅ 완료 | 설정 UI + 커서 크기 옵션 (M8.5·M8.6) | PR #91. 세그먼트 S/M/L/XL·취소/적용/초기화·언어 선택 UI |
| ✅ 완료 | 이벤트 선택지 i18n (M8.5) | PR #92. 하드코딩 한국어 → tr() 10개 키 신설, 8언어 |
| ✅ 완료 | 오디오 시스템 V2 (M7-6) | PR #94. AudioManager·UISound·SFX 24종·BGM 70종·동적 선택·루프·정규화 |
| ✅ 완료 | 인카운터 v2 (M6.5-1) | PR #95. 6 신화 × 20 몬스터 × 10 인카운터 (중복 0), floor 가중치 선택, 검증 3종 |
| ✅ 완료 | 몬스터 메커니즘 레이어 (M6.5-2) | PR #97. 6 신화 시그니처 자동 + IntentRes ActionType 7종 신규 + ~115/120 monsters tier 적용. 25 테스트 함수, 1269 통과 |
| ✅ 완료 | 이벤트·렐릭 v2 (M6.6) | PR #104~#107. 신규 EffectType 3종(TRIGGER_BATTLE/MULTI/ADD_CARD) + 22개 다양화 + 5개 렐릭 차별화 + 5개 신규 이벤트 + PASSIVE/status_type 버그 수정 + 통합 테스트 +14. **1365 통과 / 0 fail** |
| ✅ 완료 | 이벤트 UX 마무리 (M6.7) | PR #108~#110. 무의미 NONE 옵션 일괄 재설계 + choice 라벨 i18n 갱신 + autoload 버그 수정(전투 렐릭·세이브 회복) + 카드 제거 UI 통합(card_removal_overlay) |
| ✅ 완료 | VFX 시스템 v1 (M6.8) | PR #111~#113. 공격·상태·버프 VFX 20종 GDScript 포팅 + divine→holy 일괄 이주 + 임팩트 시점 동기화(`IMPACT_DELAY` + async `_execute_intent`) + GameSettings autoload hook + curse→debuff_hex 통일 + SFX 매핑 + 다수 시각 버그 수정(flash shader/시그니처 burst/screen_flash 비활성) + poison_tick 신규 + vfx_preview 디버그. **1470 통과 / 0 fail** |
| ✅ 완료 | VFX 옵션 UI (M6.8 Phase 2) | PR #114. graphics/gameplay 탭 + 4단계 segment + ConfigFile save/load |
| ✅ 완료 | 전투 UX 폴리싱 v2 (M6.9) | PR #115. fx.screen_effect 직접 await 동기화 + 글로벌 툴팁 시스템 + popup 글로우(Cinzel-Bold/halo)/색상(VFX HTML 톤) + 카드 입력 스무스(_card_busy 제거) + 사망 예측 차단 + HP 블룸 임계치 수정 + 파티클 4단계 + vfx_preview 4-way. **1470 통과 / 0 fail** |
| ✅ 완료 | 개체별 ATB 차례 시스템 (M6.10) | PR #121~#125. 라운드 → 33옵스퀴르 식 영구 ATB 큐, DeckManager 영웅별 분리, 카메라 줌인 + 사이드바, turn queue 미리보기, 차례 전환 인터벌 통합. **1465 통과 / 0 fail** |
| ✅ 완료 | 전투 UX 폴리싱 v3 + 별명·i18n + speed 시스템 (M6.11) | PR #126·#128·#129. 차례 인터벌 fine-tune + intent hover 툴팁 모든 타입 + 시그너처/파워 SVG 21개·이모지 폴백 제거 + 영웅 별명 (488 셀 4 csv 9 언어) + speed buff/debuff 시스템·카드 6 + 유물 2 + CP 테이블. **1448 통과 / 0 fail** |
| ✅ 완료 | 적 intent speed + 토큰 동적 모션 + 휴식 일러스트 (M6.12) | PR #131·#132·#133·#134. 적 intent BUFF speed_bonus·DEBUFF speed_penalty 5종 + 나폴레옹 병사 토큰 bullet VFX + 토큰 영구 그리드 폐기 (영웅→그리드 tween → 발사 → 영웅 복귀 → free) + 휴식 신화별 일러스트 9종 + tokens svg + status_box 아이콘 + i18n |
| ✅ 완료 | passive BUFF VFX + 카드 순차 VFX + speed 다중 인스턴스 + 병사 소환 VFX (M6.13) | PR #135·#136. phase_buffs/signature 자동 BUFF VFX + 카드 효과 순차 spawn (0.25s 간격) + status_applied 다중 BUFF 동기 + speed_bonus·penalty Array of {value, dur} 누적·툴팁 + nile_mist poison VFX 누락 수정 + BUFF_SPEED/DEBUFF_SPEED 드래그 화살표 + Shift+A 카드 추가 hand 직접 반영 + 병사 소환 VFX (HTML callRing + spawnPillar + 병사 등장 모션) |
| ✅ 완료 | 적 intent·카드 effect 전반 신규 VFX 13종 + CHARGE_UP·stun (M6.14) | PR #137. power_up·summon_circle·speed_buff·slow_debuff·target_marking·mimic·sacrifice·counter_prepare·steal_card·purge_status·morale_boost·prepare·boss_phase_changed (cinematic letterbox + PHASE 타이틀 + inflow + 6겹 shockwave) + CHARGE_UP IntentResource (charge_turns·payoff_intents·한 턴 다중 intent 가로 표시) + stun status (hero_turn_skipped + stun.svg) + 적 6마리 (kronos·surtr·yamata·hannya·medusa·troll_warrior) + intent UI 이모지만 + STATUS_POPUP 4종 추가. **1462 통과 / 0 fail** |
| ✅ 완료 | 영웅 해금 조건 버그 수정 (M5 fix) | PR #138. 칭기즈칸 `flag:kill_boss:oshiris` → `enemy.egyptian.osiris` (오타 + full key) / 무사시 `elite_solo_kills>=5` → `elite_kills_total>=10` (1:1 조건 무의미·완화) + `_last_elite_solo` dead code 정리 |
| ✅ 완료 | 신화 시그너처 cinematic VFX 6종 + card_exhaust + boss_death (M6.15) | PR #140. 6 신화 시그너처 VFX (휴브리스 황금 halo+zigzag 번개 / 라그나로크 발밑 원기둥+ember area broadcast / 인과응보 시체→영웅 다중 빔+연꽃 / 음양 태극 90도 snap+후광+scale fade / 저주 호루스 눈 0.1s 3 stamp+상형문자 / 결계 4 ofuda+6각 hex+結 kanji) + card_exhaust (ember sweep + 잿불 + 재, `_on_card_played` 의 `is_exhaust` hook) + boss_death (5단계 cinematic — cracks/inhale/explosion/debris/pillar/shock/왕관 추락/Fallen burgundy slate, `_on_enemy_died` boss 분기) + vfx_preview 등록 (실제 CardScene 더미 + 버튼 columns 15). **1451 통과 / 0 fail** |
| ✅ 완료 | 카드 풀 검토 도구 + ELITE/BOSS dump + 강화 1강 통일 (M6.16) | PR #147. `tools/composition_check.gd` 신규 (8 영역: cost curve / card type / EffectType 커버리지 / damage·status type / archetype 차별성 / 태그 / starter deck) + `dump_normal_enemies.gd` + `dump_act_enemies.gd` (ELITE 55+BOSS 18) + balance csv 도구 UTF-8 BOM. **강화 시스템 단순화**: LEGENDARY·DIVINE 2강 → 모든 등급 1강 통일 (단계별 unique 효과 미구현 상태였음, COMMON 8% / UNCOMMON 10% / RARE 12% / LEGENDARY 14% / DIVINE 16% rate). **1476 통과 / 0 fail** |
| ✅ 완료 | 다중 archetype 지원 + 23 카드 하이브리드 (M6.17) | PR #148. `CardResource.archetype` String → Array[String] (다중 archetype 데이터 모델). 216 카드 일괄 변환 + 효과상 명백한 23 카드에 부 archetype 추가 (cleopatra 4 / napoleon 10 — '사기' 1→11 확장 / yi_sun_sin 1 / joan_of_arc 7 / genghis_khan 1). catalog 에 `아키타입` 컬럼 추가 (다중 시 "X, Y" join). 새 분포: cleopatra 독살13/저주12/조종9, napoleon 군단12/돌격11/사기9/지휘7 등. **1474 통과 / 0 fail** |
| ✅ 완료 | 도발 시스템 재설계 + Attention! VFX (M6.18) | PR #149. 어그로 모델 → **타겟 lock 통일** (양방향 대칭). 영웅→적 도발 (knights_oath SELF→SINGLE, 그 적 ATTACK·DEBUFF가 시전 영웅 강제 타겟) + 적→영웅 도발 (fenrir_cub 신규, 영웅 SINGLE 카드 lock). `_apply_taunt_to_enemy/hero` 누적·덮어쓰기 룰 (같은 시전자 +, 다른 시전자 덮어쓰기). 매혹/반함이 도발 이김 (charm/enthrall 보유 시 우회 비활성). decay 위치 turn 시작 → 종료. VFX taunt.gd 신규 (chest impact + shockwave 3중 + 타겟→시전자 점선 성장 + "Attention!" 3 인스턴스 랜덤). i18n 13 언어 desc 통일. 영웅 poison tick popup 누락 fix. **1478 통과 / 0 fail** |
| ✅ 완료 | 영입 시스템 재설계 — Act1 안에서 3인 (M6.19) | PR #151. 기존: 1인 시작 → Act1 보스 영입 → Act2 보스 영입 (3인 모이려면 Act2 끝까지) → 변경: **Act1 안에서 3인 모두 모음**. 1인 시작 → Act1 첫 ELITE 클리어 + 카드 픽 후 영입 (`first_elite_recruit_pending/done` flag, run 내 1회) → Act1 보스 클리어 후 영입 (Act1 한정 — `current_act == 1` 가드). Act2·Act3 보스 영입 X. 동료 영입 이벤트 6 종 모두 제거 (companion_encounter / ra_sunboat / valhalla_invitation / arhat_joins / cosmic_remnant / shuten_doji_feast). 신규 4 시나리오 테스트 (`test_recruit_system.gd`). **1473 통과 / 0 fail** |
| ✅ 완료 | 카운터 시스템 + VFX 3종 + CC UI + SFX 확장 (M6.21) | PR #180·#181·#182·#183 + 후속. **status 전수조사** (i18n 14언어 + svg + STATUS_INTERNAL_KEYS — counter_pending/double_action/heal_block/silence) + **card_exhaust transform sync** (부채꼴 회전 + hover 확대 반영) + **SFX 신규 12키** (revive/arrow_shot/summon/charge_up/card_exhaust/speed_bonus/speed_penalty/card_steal/form_change/boss_phase/boss_phase_build/stun/warrior_buff/battle_lost). **신규 VFX 3종** — `dispel.gd` (빨간 hook 3가닥 + buff orb shatter) / `form_change.gd` (charge halo → pillar 발치→위 → crack → shatter → reveal, ground/glow 2 레이어) / `counter.gd` (parry flash + streak + hit burst; **major 변형**: `Engine.time_scale = 0.35` 0.6s + **흑백 postprocess shader** `assets/shaders/desaturate.gdshader` + `hint_screen_texture` uniform + **Bezier 곡선 streak 3가닥** dispel 스타일). **카운터 카드 시스템 개편** — `BattleManager.is_counter_window_active(idx)` 헬퍼 (counter_window_intent.enabled + charge_remaining > 0 OR 현재 의도 CHARGE_UP), COUNTER_REFLECT 자동 타겟 + 패턴 사이클 reset (intent_index = 0) 후속 공격 캔슬, counter_pending 중첩 X (binary), 카드 glow 황금↔파랑 sine 펄스, `_apply_card_state` add_child 후 호출 버그 fix (`_glow_mat` null silently fail), glow shader 둥근 모서리 (rounded box SDF) + smoothstep + 1.6배 강도. **CC UI** — 적 intent CC 라벨 우선 (stun > charm > enthrall > silence, `battle.cc.*` 14언어 텍스트만), 강력 CC popup (charm/enthrall/taunt/silence/heal_block, stacks 증가 시만), STUN! 큰 폰트 (STATUS_POPUP_INFO font_size override 64), counter window 활성 보스 intent ⚠️ 양옆 통일 + `counter_warning` tooltip, counter_pending UI 수치 표시 X, 매혹 저항 tooltip 동적 임계값 (`%d 초과 시 반함`). **적 메커니즘** — 적 stun 실제 처리 (turn skip + decrement + intent advance 차단), counter_triggered signal, `_check_win_condition` 패배 우선 (적+영웅 동시 사망), 보스 사망 VFX 전체 시퀀스 대기 (4.5s). **stun_stars 개편** — persistent 모드 (set_target_node/stop, stun 해제까지 머리 위 별 지속) + 타원 궤도. **버그 fix** — `set_enemy_hp` / `phase_heal_ratios` 의 `enemy_damaged.emit` → `pending_damage_changed` (페이즈 전환 시 "Block" popup 버그), ⚠️ U+FE0F 추가 (emoji-style 강제), popup spawn 조건 `stacks > 0`, 적 stun skip 시 popup 페이드 대기 (0.9s). **디버그** — `_make_checkbox_dialog` 검색 LineEdit (Shift+A/M/R/U/P/L/X 자동 적용). vfx_preview 4종 등록 (dispel/form_change/counter/counter_major). 카드 effect 텍스트 번역키 (`effect.counter_reflect.text` 14언어 = "카운터 효과를 얻습니다.") |
| ✅ 완료 | 타겟 마킹 → 치명타 시스템 재설계 + VFX 정리 (M6.20) | PR #152. 기존 +50% boost 제거 → **모든 영웅/적 공격에 치명타 확률 +30%** (base 5%, 치명타 시 ×2). 신규 `MARK_ENEMY` effect + VFX hook (target_marking 재활용) + signal 에 `is_crit` 인자 → CRIT popup. 카드 변경 (신규 X — 기존 1장씩 교체): 칭기즈칸 **노획** = MARK+DRAW1, 나폴레옹 **정찰** = MARK+MORALE1. i18n 13 언어 (`effect.mark_enemy.text` + `status.marked_by.desc.on_hero/on_enemy`). **VFX 발바닥 anchor 일괄 정리**: holy_buff/warrior_buff 빛기둥 + boss_death pillar + 영웅/적 사망 시 발 그림자 fade out (`set_meta("ground_shadow")`). **vfx_preview 인게임 환경 동일화**: 시전자/타겟 1:2 사각형 sprite 영역 (96×192) + 발 십자가 + `set_ground_anchor` 자동 적용. 버그 fix: 렐릭 strength_player power 에 `owner_id` 누락 (game_manager) → tooltip 미표시. **1494 통과 / 0 fail** |
| ✅ 완료 | 배경 시스템 v1 (M7.5) | PR #117·#119. SceneBackground 컴포넌트 (parallax 5 레이어 sky/far/mid/near/fg) + 6 신화 × 3 Act = 18 환경 팔레트 + EnvSpec (time_of_day × weather) + 6 신화 SVG 오브젝트 풀 (large/medium/small/pillars) + SceneCritters (새) + weather_particles (비·눈) — battle 씬 적용 |
| 🟢 장기 | 배경 시스템 v2 — 잔여 (M7.5+) | DOF 셰이더 (거리 기반 blur, filmic 깊이감) + Light2D (어두운 배경 광원·그림자). 현 시점 분위기 충분 — "한 단계 더" 영역. event/rest/shop 은 별도 이미지로 이미 세팅·map 은 의도적으로 배경 없음 |
| 🟡 중기 | 번역 내용 채우기 (M8.5-2) | 한국어 나머지 + 영어 전체 → 플레이어블 2개 언어 목표 |
| ✅ 완료 | i18n 4 언어 인프라 + 7 csv 번역 (M8.5-3) | PR #142. ru/pt/pl/de 추가 (9→13 언어). LocaleManager LOCALES + DISPLAY_NAMES + project.godot 117 entry + test 13개로 갱신. 7/9 csv 직접 번역 (hero 15·synergy 30·status 45·relic 90·battle 137·ui 159·enemy 195 = 671행 × 4 언어). card 755·event 280 은 영어 fallback 으로 import 정상화 — 별도 PR 에서 진짜 번역. **1462 통과 / 0 fail** |
| ✅ 완료 | i18n card·event 진짜 번역 (M8.5-4) | PR #143. event 279행 + card 754행 모두 ru/pt/pl/de 직접 번역 (총 1033행 × 4 언어 = 4132 셀). archetype 일관 매핑 (Assault/Legion/Command/Poisoning/Curse/Control/Turtle Ship/Crane Wing/Death or Glory/Divine Attack/Blessing/Martyrdom/Resurrection/Mobility/Mongol Cavalry/Plunder/Dual Wield/Duel/Mushin). card 분할 처리 (5 chunk × 134~188 entries). **1467 통과 / 0 fail** |
| ✅ 완료 | i18n fallback en + ru 디자인 폰트 (M8.5-5) | PR #144. `locale/fallback` "ko" → "en" 으로 변경 (미번역 셀 영어 fallback). `SacredTheme._LOCALE_FONTS` 에 ru 항목 추가 (CormorantGaramond/JetBrainsMono/EBGaramond-Italic, el/ path 재사용 — 키릴 글리프 포함). pt/pl/de 는 `_LATIN_FONTS` (Cinzel/Inter/IMFellEnglish/SpaceMono) 가 라틴 Ext 모두 지원 → 자동 fallback. **9 csv × 13 언어 = 22,113 셀 모두 채워짐 (빈 셀 0)** |
| ✅ 완료 | 이벤트 BGM (M7-6) | 6 카테고리 모두 재생 가능. dark_3 → dark_1 rename + AudioManager variant 탐색 gap 허용으로 수정 (1~9 중 존재하는 것만 모음) |
| 🟢 장기 | 비주얼 (M7-1~7-5) 캐릭터·카드 아트, 이펙트 | 몰입감 |
| 🟢 장기 | 모바일 최적화 (M8-1~8-5) | 해상도·세이브·성능 |
| 🟢 장기 | 접근성 (M8.6) | 색맹·자막·폰트 크기. 스팀 권장, 모바일 의무화 추세 |
| 🔵 출시 직전 | 밸런싱 / 튜토리얼 / 업적 / QA (M9-1~9-4) | 품질 보증 |
| 🔵 출시 직전 | 빌드 파이프라인 (M8-6) | export_presets·서명·CI + **Script Encryption** (커스텀 export template + AES-256 키). 현재 미구축, 스토어 제출 전 필수. 개발 워크플로우 영향 X |
| 🔵 출시 직전 | 플랫폼 SDK 통합 (M8-8) | Steam (GodotSteam) + Google Play Games Services 단일 프로젝트 통합. `platform_services.gd` autoload 로 업적·클라우드 세이브 추상화 — 호출부 platform-agnostic. 브랜치 분리 X (export preset 단위로 플랫폼별 라이브러리 자동 포함). IAP·광고 미사용 |
| 🔵 출시 직전 | 법무 문서 (M9-5) | 개인정보처리방침·라이선스 고지. 모바일 스토어 등재 조건 |
| 🔵 출시 직전 | 마케팅·커뮤니티 (M9-6) | 프레스 킷·소셜·베타 테스터 |
| 🔵 출시 | 스토어 출시 (M10) | Steam·Google Play·App Store 각 플랫폼 제출 |
| 🟣 위시리스트 | HD-2D 전환 검토 (M12) | 옥토패스류 perspective 카메라 + 3D ground + sprite billboard. Prototype 완료 (브랜치 `feat/hd2d-prototype` 미머지). 풀 전환 3~5주 (VFX 26 포팅이 병목). 출시 전 또는 후 메이저 업데이트 후보 |

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
