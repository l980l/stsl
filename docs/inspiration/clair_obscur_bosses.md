# Clair Obscur: Expedition 33 — 메인 보스 정리

> **⚠ 스포일러 주의** — 본 문서는 게임 메인 스토리 보스의 패턴·메커닉을 다룹니다.
> **출처**: Fextralife Wiki, Game8, Gameranx, ScreenRant, Neoseeker (문서 끝 참조).
> **마지막 갱신**: 2026-05-19
> **개발사**: Sandfall Interactive (2025년 4월 출시)
> **본 문서의 목적**: stsl 카드게임 보스 디자인 (시그니처 / 페이즈 전환 / 카드 카운터 트리거) 참고 자료.

---

## 진행 단계 개요

게임은 Act 1 ~ Act 3 + 엔딩 분기 구조. 메인 스토리 진행에 필수 보스 약 12종 (도입부 Eveque 포함하면 13종). 옵션/시크릿 보스는 별도.

| 챕터 | 메인 보스 |
|---|---|
| 도입부 | Eveque |
| Act 1 | Goblu / Ultimate Sakapatate / Francois / Lampmaster / Dualliste |
| Act 2 | Stalact / Visages (Mask Keeper) / Glissando / Sirene / Renoir (1차) / The Paintress |
| Act 3 / 엔딩 | Renoir (Final) → 엔딩 분기 (Maelle / Verso) |

---

## 보스 상세

### 1. Eveque
- **위치**: 도입부 (Gustave 와 Indigo Tree 가는 길)
- **타입**: 튜토리얼 보스
- **약점**: 얼음 (Ice)
- **핵심 메커닉**:
  - 작은 무브셋 — 전투 기본 학습용
  - **약점 부위 (가슴 중앙 발광점)** — Free Aim 으로 명중 시 추가 피해
  - 졸개 (minions) 소환
- **stsl 참고 포인트**:
  - 약점 부위 시스템 — 특정 위치 타격 시 보너스. stsl 의 weak_spot 추가 메커닉 영감.

---

### 2. Goblu
- **위치**: Flying Waters 끝
- **파티**: Gustave / Lune / Maelle
- **약점**: 번개 (Lightning)
- **핵심 메커닉**:
  - **2 쉴드** 로 전투 시작
  - **꽃 (Flowers)** 을 주위에 키움 → 전투 중 재생
  - 꽃 **섭취**: HP 회복 + 공격 강화
- **stsl 참고 포인트**:
  - 자가 생성 리소스 (꽃) → 적이 소비/회복 사이클. stsl 의 enemy_summon + heal_trigger 결합 패턴.

---

### 3. Ultimate Sakapatate
- **위치**: Act 1 후반
- **타입**: 메인 스토리 보스
- (상세 패턴은 추가 자료 부족 — 위키 참조)

---

### 4. Francois
- **위치**: Act 1 (Esquie 부근 호수)
- **약점**: 어둠 (Dark) / 화염 (Fire) 저항
- **핵심 메커닉**:
  - 위치 고정 — 거대 거북이형 (등껍질의 푸른 버섯)
  - **다중 쉴드 빌드업** — 약한 공격으로 쉴드 깎고 본체 타격
  - **얼음 빔 즉사 공격** — 패리/회피 실패 시 파티원 1명 즉사
  - 작은 무브셋이지만 즉사 한 방으로 위협
- **stsl 참고 포인트**:
  - 다단계 쉴드 → "쉴드 부수기" 게임플레이. stsl 의 block 다층화 + 강제 부수기 카드.
  - 즉사 패턴 → CHARGE_UP 패턴 (charge_turns 후 거대 데미지)와 매핑.

---

### 5. Lampmaster
- **위치**: Act 1 중후반 (Esquie 도전 지역)
- **타입**: 메인 스토리 보스
- (상세 패턴은 추가 자료 부족)

---

### 6. Dualliste
- **위치**: Forgotten Battlefield 끝
- **약점**: 빛 (Light) / 화염 (Fire) 저항
- **외형**: 풀-아머 기사, **2 쌍 (4개)** 의 팔, 첫 등장 시 장검 1개로 시작 + 내부 발화
- **핵심 메커닉**:
  - **2 페이즈** — 1차 HP 0 시 페이즈 전환
  - 페이즈 1: 4가지 무브 중 **5히트 콤보** (수평 횡베기 → 회전 후 횡베기 → 우측 2연속 + 머리 위 종베기)
  - **블레이드 발광점** — Light 샷 명중 시 자세 무너짐 (stance break)
  - **Fleuret Fury (Maelle)** 로 자세 강제 무너뜨림 가능
  - 페이즈 2 후반: 파티 전체에 **Inverted 디버프** 적용 → 회복 차단
- **stsl 참고 포인트**:
  - 자세 무너뜨리기 (stance break) — stsl 의 weakpoint 시스템 강화 아이디어.
  - **회복 차단 디버프** — 후반부 안티-힐 메커닉. stsl 도 heal_block 디버프 추가 가능.
  - **2 페이즈 + 디버프 페이즈 후반** — stsl phase_thresholds 0.5 일 때 추가 디버프 발생 패턴 매핑.

---

### 7. Stalact
- **위치**: Act 2
- **타입**: 메인 스토리 보스
- (상세 패턴은 추가 자료 부족)

---

### 8. Visages (Mask Keeper)
- **위치**: 가면 떠도는 영역 — Painter 진입 위해 Axon 2개 처치 후 도달
- **타입**: 메인 스토리 보스
- (상세 패턴은 추가 자료 부족)

---

### 9. Glissando
- **위치**: Act 2
- **타입**: 메인 스토리 보스
- (상세 패턴은 추가 자료 부족)

---

### 10. Sirene
- **위치**: Act 2
- **약점**: 어둠 (Dark)
- **핵심 메커닉**:
  - 자신의 영역 안의 **다양한 생명체를 소환** 해서 파티 공격
- **stsl 참고 포인트**:
  - 적 소환 트리거 — 보스가 매 턴 새 적 생성. stsl 의 SUMMON action_type 활용 보스 패턴.

---

### 11. The Paintress (Aline Dessendre)
- **위치**: Act 2 막바지
- **정체**: 본명 Aline Dessendre — Verso/Clea/Aline 의 어머니
- **3 페이즈 구조** (각 페이즈 별도 무브셋):

#### 페이즈 1 (체력 1바)
- 원거리 공격 위주, 근접 1종
- **Void Meteors**: 머리 위 아치 형태로 7개 가시 소환 → 전부 소환 후 파티에 발사
- **Chroma Waves**: 팔레트 휘둘러 4개 충격파를 파티 전체에 발산
- **Monolith Rocks**: 3개 돌을 던짐 — 카메라 줌아웃/줌인 직전 던지기 신호

#### 페이즈 2 (거대화 + 이중 보스)
- 컷씬: Monolith 앞의 거대 Paintress 소환
- Esquie 위에 올라타고 **두 Paintress 동시 전투**
- 팔레트에서 **거대 붓 (giant brush)** 무기 소환 → 근접 공격

#### 페이즈 3 (체력 20%, 무력화)
- 바닥에 누워있음
- **공격 X** — 회복/실드 부여 행동만 (파티원 1명에게)
- **상징적 컷씬 페이즈** — "어머니를 차마 죽이지 못함" 모티프 (게임의 가장 인상적 순간)
- **stsl 참고 포인트**:
  - **3 페이즈 + 마지막 페이즈는 비전투 / 상징적** — stsl phase_patterns 의 마지막 페이즈가 단순 회복/방어만 하는 "스토리 페이즈" 가능.
  - 이중 보스 — 거대 + 본체 동시. stsl 의 SUMMON 으로 본체 옆에 새 적 추가 패턴.

---

### 12. Renoir (Act 2 1차전)
- **타입**: 1차 조우 (이후 Act 3 에서 재대결)
- **약점/저항**: 무 (전부 동등)
- **핵심 패턴**:
  - **5히트 콤보**: 처음 3타 연속 → 검 회전 페이크 → 도약 찌르기 + 점프 베기
  - **원거리 공격**: 단일 타겟에 3 빔 → 도약 후 지팡이 내리찍기 폭발
  - **마스크 소환**: 거대 마스크 3개를 좌→우 순서로 Chroma Wave 발사
- **stsl 참고 포인트**:
  - 콤보 페이크 (회전 후 후속타) — stsl 의 CHARGE_UP 후속 intent 시각화에 영감.

---

### 13. Renoir (Act 3 최종 보스)
- **타입**: 라스트 보스, **2 페이즈**
- **약점/저항**: 무
- **추가 아스널** (Act 2 패턴 + 추가):
  - **Black Hole** 공격
  - **Void Cross** 공격
  - **Void Meteors**
  - **Sirene / Visages 의 힘 흡수** — 방어 강화
  - **Dessendre Canvas 소환** → 강력한 2 페이즈 발동

#### 페이즈 1
- **5히트 콤보**: 대각 위 베기 2회 + 대각 아래 베기 + 점프 베기 + 도약 회전 베기
- **점프 슬램** → Chroma 파동 (파티 침묵 silenced) → **Jump Counter 필수**

#### 페이즈 2 (체력 ~50%)
- **Dark Creature 합류** → Renoir 완전 회복 + **Enrage** (턴당 2회 행동)
- Dark Creature 3히트 콤보 (발톱 2회 + 박치기)
- **"Vanish" 스킬**: 파티원 1명을 전투에서 **삭제 시도** → **Gradient Counter** 로 막아야 함

#### 엔딩 분기 (Renoir 후)
- Verso 가 Void (캔버스 vs 현실 사이) 진입
- Maelle 와 Verso 대면 → 플레이어가 둘 중 1명 선택해 다른 1명을 처치
- **"A Life to Paint"** (Maelle 선택) vs **"A Life to Love"** (Verso 선택) — 엔딩 분기

- **stsl 참고 포인트**:
  - **페이즈 2 = 완전 회복 + Enrage (턴당 2회)** — stsl phase_thresholds 0.5 시 자신 회복 + double_action 패턴.
  - **"Vanish" — 파티원 삭제 시도 + 카운터 필수** — stsl 에 "삭제/제외" 메커닉 추가 시 영감 (단, 너무 강력 → 카운터 카드 명시).
  - **최종 보스에 다중 약점/저항 시스템 없음** — 패턴 자체로 승부 (stsl 도 라스트 보스의 패턴 다양성 우선).
  - **분기 엔딩** — 보스 처치 후 플레이어 선택. stsl 의 act3 보스 후 운명 분기 가능성.

---

## stsl 디자인 매핑 요약

| Expedition 33 메커닉 | stsl 대응 시스템 | 비고 |
|---|---|---|
| 페이즈 전환 (HP %) | `phase_thresholds` + `phase_patterns` | 이미 구현 |
| 자기 회복 + 강화 (페이즈 전환 시) | phase 전환 시 buff intent 추가 | kronos 페이즈 2 에 적용됨 |
| Charge → 즉사 공격 | `CHARGE_UP` + `payoff_intents` | medusa 석화에 적용됨 |
| 카드 타입 카운터 | `card_count_trigger` | 이미 구현 (kronos / yama / jade_emperor) |
| 적 소환 (꽃, 마스크, 생명체) | SUMMON action_type | stsl 에 추가 가능 |
| 다단계 쉴드 | block 강화 | 이미 구현 |
| 회복 차단 디버프 | `heal_block` 상태이상 | **신규 추가 검토** |
| 파티원 삭제/제외 | "exile_hero" 패턴 | **신규 추가 검토** (카운터 카드 필수) |
| Enrage (페이즈 시 turn 2회) | `double_action` 페이즈 효과 | **신규 추가 검토** |
| 약점 부위 (Free Aim) | weak_spot 시스템 | 카드게임 특성상 다른 형태로 |

---

## 디자인 관찰

1. **모든 메인 보스에 명확한 약점/저항** — 게임플레이 깊이 + 학습 곡선. stsl 도 적 별 약점 damage_type 표시 가능.
2. **페이즈 전환 시 컷씬/연출** — 스펙터클 강화. stsl 의 boss_phase_changed VFX 활용.
3. **마지막 페이즈가 비전투/감정적** (Paintress) — 게임의 정서 절정. stsl 에는 적용 어려우나 act 3 보스 처치 직후 컷씬 가능.
4. **카운터 필수 공격 (Jump Counter, Gradient Counter)** — 실시간 반응. stsl 의 카드형 게임에는 매핑 어려움 (대신 "이 턴 무력화" 효과).
5. **분기 엔딩** — Maelle vs Verso 선택. stsl 의 act3 보스 후 분기 영웅 선택 가능성.

---

## 참조

- [Fextralife - Bosses](https://expedition33.wiki.fextralife.com/Bosses)
- [Fextralife - The Paintress](https://expedition33.wiki.fextralife.com/The+Paintress)
- [Fextralife - Dualliste](https://expedition33.wiki.fextralife.com/Dualliste)
- [Fextralife - Sirene Boss](https://expedition33.wiki.fextralife.com/Sirene+(Boss))
- [Game8 - List of Main Bosses](https://game8.co/games/Clair-Obscur-Expedition-33/archives/513923)
- [Game8 - Paintress Guide](https://game8.co/games/Clair-Obscur-Expedition-33/archives/517730)
- [Game8 - Renoir Final Boss](https://game8.co/games/Clair-Obscur-Expedition-33/archives/519235)
- [Game8 - Dualliste Guide](https://game8.co/games/Clair-Obscur-Expedition-33/archives/519298)
- [Gameranx - Paintress Guide](https://gameranx.com/features/id/537556/article/clair-obscur-expedition-33-the-paintress-boss-fight-guide/)
- [Gameranx - Francois Guide](https://gameranx.com/features/id/536941/article/clair-obscur-expedition-33-francois-boss-fight-guide/)
- [Gameranx - Goblu Guide](https://gameranx.com/features/id/536664/article/clair-obscur-expedition-33-goblu-boss-fight-guide/)
- [Gameranx - Renoir Act 2](https://gameranx.com/features/id/537335/article/clair-obscur-expedition-33-renoir-act-ii-boss-fight-guide/)
- [Gameranx - Renoir Act 3 Final](https://gameranx.com/features/id/537557/article/clair-obscur-expedition-33-how-to-beat-the-final-boss-renoir-act-iii-boss-fight-guide/)
- [ScreenRant - All Main Bosses](https://screenrant.com/clair-obscur-expedition-33-all-bosses-how-to-beat-list/)
- [Neoseeker - Paintress](https://www.neoseeker.com/clair-obscur-expedition-33/The_Paintress)
- [Neoseeker - Renoir](https://www.neoseeker.com/clair-obscur-expedition-33/Renoir)
- [Deltia's Gaming - Boss Chronological Order](https://deltiasgaming.com/clair-obscur-expedition-33-all-bosses-in-chronological-order/)
- [Game Checklists - All 149 Bosses](https://game-checklists.com/expedition33/all-bosses.html)

---

> **주의**: Lampmaster / Stalact / Visages / Glissando / Ultimate Sakapatate 등은 상세 패턴 자료가 부족해 간략히만 표기. 추가 정보 필요 시 Fextralife Wiki 의 개별 페이지 참조.
