# 튜토리얼 시스템 설계

> 상태: 설계 승인 대기
> 날짜: 2026-06-30
> 게임: Of Myth and Memory (Godot 4.6.2, 덱빌딩 + 팀빌딩 로그라이크)

## Context (왜)

게임에는 카드 효과 52종(`EffectType`), 상태이상 23종, 적 인텐트 18종(`ActionType`),
치명타·마킹·독·카운터·차지업·신화 시그니처·팀빌딩(다중 영웅/행동순서) 등 학습 곡선이 가파른
시스템이 많다. 현재 신규 플레이어에게 이를 설명하는 장치가 전혀 없다(코드에 tutorial/onboarding 흔적 0).

목표: **보편 전투 문법을 강제 시연으로 가르치고**, 개별 카드·몬스터·렐릭 디테일은 **이미 만든 도감 +
전투 중 툴팁**으로 위임한다. "모든 효과를 인터랙티브로 시연"은 분량상 비현실적이므로 의도적으로 범위를
보편 메커니즘으로 한정한다.

## 확정된 결정 (브레인스토밍)

- **범위**: 보편 문법 시연 + 도감 위임 (개별 카드/몬스터/렐릭은 시연하지 않음)
- **진입**: 메인메뉴에서 선택 진입 (강제 없음, 재시청 가능)
- **구조**: 챕터형 레슨 선택 (L1~L4 전투 레슨)
- **메타 시스템(맵/상점/렐릭/휴식/이벤트)**: 튜토리얼 안에서 재현하지 않고, **실게임 첫 진입 시 1회 힌트**로 가볍게
- **방어도**: 코드 현황(턴 무관 **누적·유지**)이 **의도**임을 확정. 튜토리얼은 "방어도는 소모되기 전까지
  누적·유지된다"로 설명한다. (최초 브리프의 "한 턴만 지속"은 폐기 — 실제 동작과 다름)
- **카드 빛(glow)**: 모던 프레임(`card_scene_v2`)의 no-op glow를 **실제 구현**하여 클래식/모던 일관 처리

## 레슨 구성 (전투 = 강제 시연)

각 레슨은 짧은 스크립트 전투(코드 생성 적/덱). 스텝마다 지시문 + 스포트라이트 + 입력 게이팅,
"설명 → 직접 해보기(do-it)" 패턴.

### L1 — 기초 전투 (영웅 1명, 고정 덱)
- 손패/에너지/턴 종료 개념
- 카드 3종류: 공격(적에게 드래그) / 스킬 / 파워(지속)
- **카드 사용·취소**: 끌어서 사용, 빈 곳/취소로 되돌리기
- 타게팅(단일 적)
- 적 인텐트 읽기 + **색 의미**(공격=빨강 / 버프=파랑 / 디버프=보라)
- **방어도**: 사용 → 적 공격 흡수 → "소모 전까지 누적·유지" 강조
- **치명타**: 일반 공격 → `tutorial_force_crit`로 1회 강제 발동 → "기본 5%, 발동 시 ×2(200%)" 설명
- **커서 의미**: 드래그 가능/불가, 호버 툴팁

### L2 — 카운터 & 차지업 (카운터 카드 포함 덱)
- 적 일반 공격 예고 → **카운터 카드**로 반감(50%) + 반사(100%)
- 적 **CHARGE_UP**(숨고르기 N턴) 강공 예고 → **카운터 카드가 빛남**(금↔청 펄스) → 차지 **무효 + 기절**
- 핵심 메시지: **"카드가 빛나면 지금이 카운터 타이밍"**
- (구성) `EnemyResource.counter_window_intent`로 차지 윈도우 구성

### L3 — 상태이상 & 독
- 약화(적 공격↓) / 취약(받는 피해↑) / 힘(공격↑) 부여 시연
- **마킹(mark)**: 적 마킹 → 모든 영웅 치명타 확률 +30% (총 35%)
- **독**: 3스택 부여 → 매 턴 시작 시 현재 수치 그대로 피해 / **3턴 지속** / 재부여 시 3턴 갱신 /
  스택은 시간에 따라 줄지 않음
- (선택) 매혹/도발 맛보기

### L4 — 팀빌딩 (영웅 2명)
- 다중 영웅 동시 운용, 카드별 소유 영웅
- **행동 순서(speed)** — 턴 큐 읽기
- 아군 대상 카드(드래그 방향)
- 영웅 고유자원 1개 예: 나폴레옹 **사기(morale)**
- 영웅 사망 → 부활 흐름

## 메타 = 실게임 첫 진입 1회 힌트

별도의 가벼운 "첫 진입 힌트" 시스템. 해당 씬 최초 진입 시 1회 팝업/하이라이트, `ProgressManager`
플래그로 1회만 표시.

- **맵**(`map_scene`): 노드 타입(전투/엘리트/보스/상점/휴식/이벤트/비밀), 분기 선택, 골드
- **상점**(`shop_scene`): 카드/렐릭 구매, 카드 제거
- **렐릭**: 유물 효과, 저주 렐릭
- **휴식**(`rest_scene`): 강화 / 제거
- **이벤트**(`event_scene`): 선택지 결과
- **환생/루프**: 로그라이크 사이클 (승리/패배 후)

## 아키텍처

### 진입 흐름
- `main_menu_scene.gd`: ledger에 **"튜토리얼"** 행 추가(`_add_ledger_row`) → `tutorial_select_scene`
- `tutorial_select_scene` (신규): 레슨 목록 + 완료 체크(✓) + 재시청. 선택 시 해당 레슨 부팅

### 레슨 구동 — 기존 battle_scene 재사용 + TutorialDriver
- **`TutorialDriver`** (신규, 오버레이 `CanvasLayer`): 레슨별 스텝 시퀀스를 소유·구동
  - 스텝 = `{ instruction: String(i18n key), spotlight: NodePath/Rect, allowed_input: Array, complete_signal: 감지조건 }`
  - 진행: 지시문 표시 → 입력 게이팅 → `BattleManager` 시그널로 완료 감지 → 다음 스텝
- **적/덱 코드 생성**: 기존 `battle_scene._start_test_battle()`(:1285) 패턴 재사용
  - `EnemyResource.intent_pattern` 고정으로 적 행동 결정화
  - `counter_window_intent`로 L2 차지 기믹
  - `CardResource.is_innate=true`로 필요한 카드가 첫 손패에 보장됨 → 드로우 RNG 회피
- **완료 감지 시그널**(기존): `card_played`, `enemy_damaged(is_crit)`, `counter_triggered`,
  `status_applied`, `poison_tick_applied`, `turn_started`, `player_turn_started`

### 결정성 최소 훅 (battle_manager)
기존 `debug_hero_invincible` 선례 방식의 플래그 추가:
- `tutorial_force_crit: bool` — `_roll_crit`(:51~53 인근)에서 true면 치명타 확정
- `tutorial_suppress_random: bool` — 랜덤 이벤트/시그니처 등 비결정 요소 억제(필요 범위만)

### 입력 게이팅
- `TutorialDriver`가 `battle_scene`에 "허용 카드/버튼 셋" 전달 → 그 외 카드 `set_disabled(true)` +
  화면 딤 + 허용 대상 스포트라이트(컷아웃)
- 기존 `_apply_card_state`/`node.set_disabled`(battle_scene:1839) 재사용

### 카드 빛 보강 (모던 프레임)
- `card_scene_v2.gd`의 no-op glow 6종(`show_glow`/`hide_glow`/`set_glow_color`/`start_glow_pulse`/
  `stop_glow_pulse`/`tween_glow`, :193~198)을 실제 구현
- 클래식(`card_scene.gd`)과 동일 시그니처 — battle_scene 호출부(:1842~1846, :2074~2075) 무변경

### 진행 저장 (ProgressManager)
- 기존 discovered_* 패턴(`to_dict`/`from_dict`/`reset`)에 추가:
  - `tutorial_completed: Dictionary` (레슨별 완료 플래그)
  - `meta_hint_shown: Dictionary` (맵/상점/렐릭/휴식/이벤트 1회 힌트 플래그)
- `user://progress.json` 영속화

### i18n
- **`strings_tutorial.csv`** 신설 (기존 14열: keys,ko,en,fr,it,es,ja,el,zh,zh_TW,ru,pt,pl,de)
- 레슨 지시문 + 메타 힌트 텍스트. 영어/한국어 우선, 나머지는 후속 채움 가능
- 상태이상/키워드 용어는 기존 status/effect 키 재사용 (영어 raw 삽입 금지 — i18n 용어 분리 규칙)

## 생성/수정 파일

**신규**
- `scenes/tutorial/tutorial_select_scene.tscn` + `.gd` — 레슨 목록
- `scenes/tutorial/tutorial_driver.gd` — 스텝 시퀀스 구동 오버레이
- `scenes/tutorial/lessons/` — L1~L4 레슨 정의(스텝 데이터 + 적/덱 빌더). GDScript 데이터 또는 함수
- `resources/translations/strings_tutorial.csv`
- (메타) `scenes/components/first_time_hint.gd` — 씬 첫 진입 1회 힌트 헬퍼

**수정**
- `scenes/main_menu/main_menu_scene.gd` — "튜토리얼" ledger 행
- `autoload/battle_manager.gd` — `tutorial_force_crit` / `tutorial_suppress_random` 훅
- `scenes/battle/battle_scene.gd` — TutorialDriver 연동(허용 입력 셋 수용), 스포트라이트 대상 노출
- `scenes/card/card_scene_v2.gd` — glow 6종 실제 구현
- `autoload/progress_manager.gd` — `tutorial_completed` / `meta_hint_shown` + 영속화
- `scenes/map/map_scene.gd`, `scenes/shop/shop_scene.gd`, `scenes/rest/rest_scene.gd`,
  `scenes/event/event_scene.gd` — 첫 진입 힌트 호출(1줄)

## 단계별 구현 순서 (분리 커밋/PR)

1. **인프라**: TutorialDriver + battle_manager 훅 + 메뉴 진입 + L1(기초 전투). glow 보강 포함.
2. **L2** 카운터 & 차지업
3. **L3** 상태이상 & 독
4. **L4** 팀빌딩
5. **메타 첫 진입 힌트** (맵/상점/렐릭/휴식/이벤트)

각 단계 헤드리스 부팅 검증 + 사용자 승인 후 다음.

## 검증

- **헤드리스 부팅**: 각 레슨 씬 `--headless --quit-after N`로 스크립트/파스 에러 0 확인
- **결정성**: `tutorial_force_crit` 시 치명타 확정, 고정 `intent_pattern`대로 적 행동, `is_innate`
  카드가 첫 손패에 등장하는지 임시 `-s` 스크립트로 확인
- **스텝 완료 감지**: 각 스텝의 완료 시그널이 실제로 발화하는지(카드 사용/카운터/독 tick/마킹) 확인
- **인게임 흐름**: L1 카드사용·취소·방어도·치명타 / L2 카운터·차지 빛 / L3 독 3턴·마킹 / L4 행동순서·부활
- **진행 저장**: 레슨 완료 후 재진입 시 ✓ 유지, 메타 힌트 1회만 표시
- **i18n**: ko/en 누락 키 0, 영어 raw 삽입 0
- `tests/test_runner.gd` 0 failed

## 비-목표

- 개별 카드/몬스터/렐릭 전수 시연 (도감 + 툴팁 위임)
- 밸런스/게임플레이 변경 (glow 구현·튜토리얼 훅 외)
- 신화 시그니처별 전용 레슨 (보편 문법 범위 밖)
