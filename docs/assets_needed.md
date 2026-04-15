# STSL 필요 애셋 목록

**작성일:** 2026-04-15  
**최종 수정:** 2026-04-15 (Plan 05 반영)  
**해상도 기준:** 1920×1080 (모바일 렌더러)  
**현재 상태:** 모든 캐릭터/카드/UI는 플레이스홀더(ColorRect)로 구현됨

---

## 1. 캐릭터 스프라이트

### 영웅 (Heroes)

| 캐릭터 | 경로 | 크기 | 상태 | 필요 애니메이션 |
|--------|------|------|------|----------------|
| 나폴레옹 | `characters/heroes/napoleon/` | 80×80px | 플레이스홀더 | idle, attack, hurt, death |
| 클레오파트라 | `characters/heroes/cleopatra/` | 80×80px | 플레이스홀더 | idle, attack, hurt, death |
| 이순신 | `characters/heroes/yi_sun_sin/` | 80×80px | 플레이스홀더 | idle, attack, hurt, death |

**애니메이션 스펙:**
- `idle`: 2~4프레임 루프, 0.6초/사이클
- `attack`: 4~6프레임, 돌진 후 복귀 (x축 +60 이동), 0.3초
- `hurt`: 2프레임, x축 -10 떨림, 0.2초
- `death`: 3~4프레임, 투명도 0으로 페이드, 0.5초

---

### 적 (Enemies)

#### 일반 적 (Normal)

| 캐릭터 | 경로 | 크기 | 상태 | 필요 애니메이션 |
|--------|------|------|------|----------------|
| 사티로스 | `characters/enemies/satyr/` | 80×80px | 플레이스홀더 | idle, attack, hurt, death |
| 하르피아 | `characters/enemies/harpy/` | 80×80px | 플레이스홀더 | idle, attack, hurt, death |
| 사이클롭스 | `characters/enemies/cyclops/` | 100×100px | 플레이스홀더 | idle, charge(준비), attack, hurt, death |
| 메두사의 뱀 | `characters/enemies/snake/` | 60×60px | 플레이스홀더 | idle, attack, hurt, death |

> **사이클롭스 특이사항:** 준비(charge) 애니메이션 1턴 후 강타(18) 패턴. charge 애니메이션 별도 필요.

#### 엘리트 적 (Elite)

| 캐릭터 | 경로 | 크기 | 상태 | 필요 애니메이션 |
|--------|------|------|------|----------------|
| 미노타우로스 | `characters/enemies/minotaur/` | 120×120px | 플레이스홀더 | idle, attack, heavy_attack(3번째 전체공격), hurt, death |
| 메두사 | `characters/enemies/medusa/` | 100×100px | 플레이스홀더 | idle, attack, gaze(석화 시선), hurt, death |

> **미노타우로스:** 3번째 공격(ALL 20)은 heavy_attack 애니메이션으로 구분 권장.  
> **메두사:** gaze 애니메이션은 DEBUFF(weak/vulnerable) 인텐트 시 재생.

#### 보스 (Boss)

| 캐릭터 | 경로 | 크기 | 상태 | 필요 애니메이션 / 비고 |
|--------|------|------|------|----------------------|
| 히드라 | `characters/enemies/hydra/` | 160×160px | 플레이스홀더 | idle, attack, hurt, death + **페이즈별 시각 변화** |

**히드라 페이즈 시각 변화 (3단계):**
| 페이즈 | HP 범위 | 권장 표현 |
|--------|---------|-----------|
| 페이즈 0 | 100%~60% | 기본 형태 (머리 2개) |
| 페이즈 1 | 60%~30% | 머리 3개, 크기 1.2× |
| 페이즈 2 | 30%~0% | 머리 재생 이펙트, 붉은 색조 |

> **현재 구현:** 모든 적이 `satyr.tscn`을 공유하는 플레이스홀더. 각 씬 분리는 애셋 제작 후 진행.

---

## 2. 카드 아트

카드 크기: `110×160px` (BattleScene 기준)  
경로 규칙: `resources/cards/art/<카드이름>.png`

| 카드 이름 | 타입 | 설명 | 우선순위 |
|-----------|------|------|---------|
| 스트라이크 | DAMAGE 6 | 기본 공격 카드 | 높음 |
| 디펜드 | BLOCK 5 | 기본 방어 카드 | 높음 |
| 헤비 스트라이크 | DAMAGE 9 | 강타 카드 | 중간 |
| 클리브 | DAMAGE 4 (전체) | 광역 공격 | 중간 |
| 아이언 웨이브 | DAMAGE 5 + BLOCK 5 | 공수 겸용 | 중간 |
| 아이언 디펜스 | BLOCK 8 | 강화 방어 | 중간 |
| 포이즌 스트라이크 | DAMAGE 3 + 독 2 | 상태이상 공격 | 낮음 |

**카드 레이아웃 구성 요소:**
- 카드 프레임 이미지 (`card_frame_attack.png`, `card_frame_defense.png`)
- 카드 아트 (중앙 일러스트)
- 비용 아이콘 (우상단)
- 효과 아이콘 (DAMAGE/BLOCK/POISON 별 아이콘)

---

## 3. UI 요소

### 전투 씬 (BattleScene)

| 요소 | 설명 | 크기 | 경로 |
|------|------|------|------|
| HP 바 프레임 | 영웅/적 공용 | 200×20px | `ui/hpbar_frame.png` |
| HP 바 채우기 | 빨간색 | 196×16px | `ui/hpbar_fill.png` |
| 블록 아이콘 | 방어 수치 표시 | 32×32px | `ui/icon_block.png` |
| 에너지 아이콘 | 에너지 표시 | 32×32px | `ui/icon_energy.png` |
| 턴 종료 버튼 | 버튼 배경 | 200×60px | `ui/btn_end_turn.png` |
| 카드 선택 하이라이트 | 카드 hover/select 테두리 | 110×160px | `ui/card_highlight.png` |

### 맵 씬 (MapScene)

| 요소 | 설명 | 크기 | 경로 |
|------|------|------|------|
| 배틀 노드 아이콘 | ⚔ 전투 룸 | 40×40px | `ui/map/node_battle.png` |
| 엘리트 노드 아이콘 | 💀 엘리트 룸 | 40×40px | `ui/map/node_elite.png` |
| 휴식 노드 아이콘 | 🔥 휴식 룸 | 40×40px | `ui/map/node_rest.png` |
| 상점 노드 아이콘 | 🏪 상점 룸 | 40×40px | `ui/map/node_shop.png` |
| 보스 노드 아이콘 | 👑 보스 룸 | 40×40px | `ui/map/node_boss.png` |
| 맵 연결선 | 노드 간 경로 | 벡터 | (코드로 Line2D 생성) |
| 맵 배경 | 어두운 톤 배경 | 1920×1080px | `ui/map/bg_map.png` |

### 카드 보상 씬 (CardPickScene)

| 요소 | 설명 | 크기 | 경로 |
|------|------|------|------|
| 배경 오버레이 | 반투명 어두운 배경 | 1920×1080px | `ui/card_pick/bg_overlay.png` |
| 건너뛰기 버튼 | 버튼 배경 | 160×50px | `ui/btn_skip.png` |

---

## 4. 배경 이미지

| 씬 | 설명 | 크기 | 경로 |
|----|------|------|------|
| 전투 배경 | 전투 씬 배경 (현재 컬러만) | 1920×1080px | `scenes/battle/bg_battle.png` |
| 맵 배경 | 맵 씬 배경 (현재 컬러만) | 1920×1080px | `scenes/map/bg_map.png` |

---

## 5. 오디오

### BGM (배경음악)

| 트랙 | 사용 씬 | 형식 | 경로 |
|------|---------|------|------|
| 메인 맵 테마 | MapScene | `.ogg` | `audio/bgm/map_theme.ogg` |
| 전투 테마 | BattleScene (일반) | `.ogg` | `audio/bgm/battle_normal.ogg` |
| 엘리트 전투 테마 | BattleScene (엘리트) | `.ogg` | `audio/bgm/battle_elite.ogg` |
| 보스 테마 | BattleScene (보스) | `.ogg` | `audio/bgm/battle_boss.ogg` |
| 승리 징글 | 전투 승리 시 | `.ogg` | `audio/bgm/victory.ogg` |
| 패배 징글 | 전투 패배 시 | `.ogg` | `audio/bgm/defeat.ogg` |

### SFX (효과음)

| 효과음 | 트리거 | 형식 | 경로 |
|--------|--------|------|------|
| 카드 클릭 | 카드 선택 시 | `.wav` | `audio/sfx/card_click.wav` |
| 카드 사용 | 카드 플레이 시 | `.wav` | `audio/sfx/card_play.wav` |
| 공격 히트 | DAMAGE 적용 시 | `.wav` | `audio/sfx/hit.wav` |
| 블록 발동 | BLOCK 적용 시 | `.wav` | `audio/sfx/block.wav` |
| 독 데미지 | 독 틱 | `.wav` | `audio/sfx/poison.wav` |
| 캐릭터 사망 | HP = 0 | `.wav` | `audio/sfx/death.wav` |
| 전투 승리 | 적 전멸 | `.wav` | `audio/sfx/victory.wav` |
| 버튼 클릭 | UI 버튼 | `.wav` | `audio/sfx/ui_click.wav` |
| 맵 노드 선택 | 노드 클릭 | `.wav` | `audio/sfx/node_select.wav` |

---

## 6. 폰트

| 용도 | 폰트 | 경로 | 비고 |
|------|------|------|------|
| 카드 텍스트 | 한글 지원 폰트 | `fonts/main.ttf` | 현재 Godot 기본 폰트 사용 중 |
| UI 레이블 | 동일 | `fonts/main.ttf` | 한글 렌더링 확인 필요 |
| 숫자/HP | 굵은 폰트 | `fonts/bold.ttf` | 선택적 |

> **주의:** 현재 한글 텍스트를 Godot 기본 폰트로 렌더링 중. 실기기(모바일) 배포 시 한글 지원 폰트(예: Noto Sans KR) 필수.

---

## 7. 제작 우선순위

### Phase 1 — 프로토타입 플레이 가능 수준 (높음)

1. **나폴레옹 캐릭터 스프라이트** — idle + attack 애니메이션 최소
2. **사티로스 적 스프라이트** — idle + attack 최소
3. **스트라이크 / 디펜드 카드 아트** — 기본 덱 2종
4. **HP 바 UI** — 전투 가독성에 핵심

### Phase 2 — 게임 루프 완성 (중간)

5. **하르피아 / 사이클롭스 / 메두사의 뱀 스프라이트** — 일반 적 다양성
6. **미노타우로스 / 메두사 스프라이트** — 엘리트 전투 긴장감
7. **히드라 보스 스프라이트** (페이즈별 3형태)
8. 맵 노드 아이콘 5종
9. 카드 보상 UI 배경
10. 나머지 보상 카드 아트 (나폴레옹 14종)
11. 전투 SFX (히트, 블록, 카드 플레이)

### Phase 3 — 폴리시 (낮음)

12. 클레오파트라, 이순신 스프라이트 + 카드 아트 각 14종
13. BGM 전 트랙
14. 이벤트/휴식 씬 배경 이미지
15. 상점 씬 UI (MVP 외)

---

## 8. 현재 플레이스홀더 구현

코드에서 애셋 없이 동작하도록 아래와 같이 구현됨:

| 요소 | 플레이스홀더 방식 |
|------|----------------|
| 캐릭터 (영웅) | `ColorRect` (나폴레옹=파랑, 클레오파트라=황금, 이순신=청록) + `AnimationPlayer`(빈 트랙) |
| 캐릭터 (적) | 모든 적이 `satyr.tscn` 공유. `ColorRect` 빨강 단색. 이름만 다름 |
| 카드 | `Button` 텍스트로 이름/비용 표시 |
| HP 바 | `ProgressBar` 기본 스타일 |
| 맵 노드 | `Button` 텍스트로 룸 타입 표시 |
| 배경 | `ColorRect` 단색 |
| 오디오 | 없음 |
