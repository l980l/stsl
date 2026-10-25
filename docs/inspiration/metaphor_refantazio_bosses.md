# Metaphor: ReFantazio — 메인 보스 정리

> **⚠ 스포일러 주의** — 본 문서는 게임 메인 스토리 보스의 패턴·메커닉을 다룹니다.
> **출처**: Game8, GamerGuides, Neoseeker, ScreenRant, GameLeap, FandomWire (문서 끝 참조).
> **마지막 갱신**: 2026-05-19
> **개발사**: Atlus (Studio Zero, 2024년 10월 출시)
> **본 문서의 목적**: stsl 카드게임 보스 디자인 (Archetype/약점/Turn Icon 시스템) 참고 자료.

---

## 게임 시스템 핵심 (보스 이해 전제)

### Squad Turn / Turn Icon
- 파티 4명 = **4 Turn Icon** 으로 시작
- 약점 타격 / 크리티컬 시 → **Turn Icon 절반 소비** (추가 행동)
- 빗나감 / 흡수 / 무효 → **Turn Icon 2~4 소비** (행동 손실)
- 보스는 **Soul Cry / Soul Scream** 으로 자기 Turn Icon 추가 가능

### Archetype (직업) 시스템
- 14개+ Archetype — 시간 흐름에 따라 해금
- Archetype 별 약점 / 저항 다름 → 파티 빌드 자유

### Synthesis (합체기)
- Archetype 조합으로 강력한 합체기 발동

---

## 메인 보스 list

총 **14 메인 스토리 보스** (정확한 14개 list 자료별 차이). 핵심:

| 챕터 / 던전 | 보스 | 비고 |
|---|---|---|
| Grand Trad (초반) | **Zorba** | Louis 의 부관, 첫 본격 보스 |
| 중반 던전 | Catacombs/Necropolis 보스 (Dragon 등) | 각 던전 거대 보스 |
| Dragon Temple | Homo Flaemo / 기타 | Akademia 시험 |
| Skybound Avatar | **Voidblack Homo Orelon** | Dungeon 보스 (전기 약점) |
| 종반 | **Melancholia Zorba** | Louis 직전 마지막 큰 관문 |
| Finale | **Louis Guiabern** (3 페이즈) | 메인 final |
| 시크릿 | Louis 의 비밀 형태 | 시크릿 엔딩 final |

---

## 보스 상세

### Zorba (첫 본격 보스)
- **위치**: Grand Trad
- **소속**: Louis 의 부관 — 게임 내내 등장
- **핵심 메커닉**:
  - 약점 / 저항 조합으로 학습용 패턴
- **stsl 참고**:
  - 빌런 부관 등장 → 게임 내내 재대결 패턴. stsl 의 mythology 별 부관/보스 분리.

---

### Voidblack Homo Orelon (Skybound Avatar 보스)
- **약점**: 전기 (Electric)
- **위치**: Skybound Avatar dungeon (Louis 의 Conquest)
- **외형**: 거대한 부유 생명체 — "True Body"
- **stsl 참고**:
  - **dungeon 보스 단일 약점 명확** — stsl 의 보스 별 약점 damage_type 명시 (이미 부분 구현).

---

### Melancholia Zorba (Louis 직전 보스)
- **2 Form 전환** — Offense / Defense 사이클
- **소속**: 부관 Zorba 가 melancholia 의 힘 흡수해 변신

#### Offense Form (시작)
- 약점 / 저항 **없음** — 일반 공격 가능
- **Soul Scream** 발동 시 → **4 추가 Turn Icon** 획득 → 한 턴에 다중 공격
- 사용 스킬:
  - **Gakandeon** — 강한 전기 광역
  - **Mamudodyne** — 강한 어둠 광역
  - **Sorrow Curse** — Anxiety 상태이상
  - **Bondage Curse** — Paralyze
  - **Madness Curse** — Rage
  - **Giant Scythe** — 강한 Slash 단일

#### Defense Form
- **모든 속성 + 물리 저항** — 일반 공격 무효
- **Almighty 속성** 만 통함
- 자기 **Heat Riser** (3종 버프 동시) 발동
- 파티 버프 제거 (**Dekaja**)

#### 전환 사이클
- Offense → Defense → Offense ... 반복
- Defense 동안 영웅이 Almighty 만 사용 + dispel + 회복
- Offense 시 모든 공격 cooldown 푼 burst

- **stsl 참고**:
  - **Form 전환 보스** — 매 턴 또는 N턴마다 모드 변경. 영웅 전략 동적 변경 강제.
  - **모드별 면역 다름** — Defense 시 거의 모든 공격 무효 → **dispel + Almighty** 만 통하는 디자인. stsl 의 mode_switch 보스 패턴.
  - **모드 전환 시 Soul Scream + 자기 강화** — 모드 변환이 단순 면역 변경이 아닌 자기 강화 콤보. phase 전환 + 추가 행동 + 자기 buff 결합.

---

### Louis Guiabern (메인 final, 3 페이즈)
- **약점 / 저항**: **없음** — 패턴 자체로 승부
- **3 페이즈** — 각 페이즈 공격력 + 광역 빈도 증가

#### 페이즈 공통 메커닉
- **Soul Cry** (시작 시): **2 추가 Turn Icon**
- **Soul Scream** (HP 50% 이하): **4 추가 Turn Icon** 으로 강화
- **Treasure Sword: Unlock Affinity** — 자기 공격 속성을 4 기본 속성 (불/얼음/전기/바람) 중 선택
  - **Royal Slash** / **Spatial Slice** 가 변경된 속성 채택
- **Royal Coercion** — 단일 영웅 공격/방어 -2 단계 (3턴)

#### 방어 자세 시그널
- **"wings to the front"** 애니메이션 = Louis 의 방어 자세 + 특수기 차지 신호
- 영웅이 이 시점 **일시적 약점 부여** (one-time weakness inflict) 가능 → **자세 무너뜨림 + 특수기 무효**
- 일종의 **카운터 윈도우** — 영웅이 react 못 하면 강력한 특수기 맞음

#### Prince Archetype 강조
- 후반 페이즈에서 Louis 가 주인공 (Prince) 집중 타게팅
- Prince 의 물리 방어 빌드 필수

- **stsl 참고**:
  - **약점/저항 없음 + 패턴 다양성으로 난이도** — kronos 와 동일 철학.
  - **시그널 → 일시적 약점 부여 카운터** — 보스 자세 시그널 시 영웅이 1턴 안에 약점 부여 카드 사용해야 (성공 시 보스 강력기 무효). stsl 신규 메커닉:
    - 보스 intent 에 "charging_special" 표시
    - 영웅이 그 턴에 특정 카드 (예: 약점 부여) 사용 → 특수기 취소
    - 실패 시 다음 턴 보스 강력 특수기 발동
  - **속성 변경 가능 보스** — 자기 공격 속성 동적 변경. 영웅이 저항 빌드 무력화 가능. stsl 의 dynamic_damage_type 메커닉.
  - **3 페이즈** 동안 패턴 거의 동일 + 행동 빈도 / 데미지만 증가 — 단순한 difficulty ramp 디자인.

---

### Louis 비밀 final (시크릿 엔딩)
- 메인 final 이후 추가 조건 충족 시 — Louis 의 진정한 변형
- 더 강한 메커닉 + 더 긴 페이즈
- (상세 자료 부족, 신규 게임 콘텐츠)

---

# stsl 디자인 매핑 요약

| Metaphor 메커닉 | stsl 대응 시스템 | 비고 |
|---|---|---|
| Press Turn 시스템 (약점 = 추가 행동) | damage_type 약점 + extra_turn 보너스 | 신규 검토 (현재 stsl 은 단순 데미지 약점만) |
| Soul Cry / Scream (자기 Turn Icon +N) | `extra_action_count` 자기 buff | 신규 검토 |
| Form 전환 (Offense/Defense) | mode_switch 보스 (모드별 면역) | 신규 검토 |
| Almighty 속성 (보편 데미지) | `almighty_damage_type` (모든 저항 무시) | 신규 검토 — 강력하지만 가치 |
| 자기 다중 buff (Heat Riser) | self_triple_buff intent | 변형 가능 |
| 파티 buff 제거 (Dekaja) | `dispel` intent | 이미 Persona 매핑과 동일 |
| 자세 시그널 → 카운터 윈도우 | intent_with_counter | **신규 메커닉 — 흥미로움** |
| 일시적 약점 부여 (Counter 시) | `inflict_weakness` 영웅 카드 | 신규 검토 |
| 속성 동적 변경 (Louis Unlock Affinity) | `change_damage_type` 보스 intent | 신규 검토 |
| 단일 영웅 공격/방어 -2 단계 (Royal Coercion) | 다단계 디버프 | 변형 가능 |
| Anxiety / Paralyze / Rage 상태이상 | weak/stun/charm 외 신규 status_type | 검토 |
| Archetype 시스템 (직업 자유 변경) | 영웅의 클래스/덱 변경 | stsl 컨셉과 다른 방향 — 참고만 |
| Synthesis (합체기) | 영웅 간 콤보 카드 | 신규 검토 (이미 SUMMON 영웅 부분 구현) |

---

## 디자인 관찰

1. **약점 = 추가 행동 (Press Turn)** — 단순 데미지 보너스가 아닌 **자원** 시스템. Persona 의 1 More 와 동일 사상.
   - stsl 도 약점 타격 시 추가 가치 (cost 환불 / 다음 카드 강화 / 추가 카드 뽑기 등) 검토 가치.

2. **보스도 약점/저항 없는 경우 多** — Melancholia Zorba (Offense), Louis 모두 약점 없음. 패턴 자체가 난이도.
   - 영웅이 약점 의존하지 않는 빌드 강제 → 다양한 빌드 가치.

3. **Form 전환 보스 (Melancholia Zorba)** — 매 모드별 영웅 전술 완전 변경.
   - stsl 의 phase_thresholds 와 다른 형태 — HP 가 아닌 N턴마다 모드 변경.

4. **자세 시그널 + 카운터 윈도우 (Louis)** — 보스 charge 턴 = 영웅 카운터 기회.
   - 가장 흥미로운 메커닉. stsl 에 도입 시 intent 표시 + counter 카드 명시 필요.
   - **stsl 대응 디자인 제안**:
     - 보스 intent 에 ⚠ 아이콘 + "이 턴 안에 약점 부여 시 무효"
     - 영웅 카드 중 "약점 부여" 종류 명확화 (예: `inflict_weakness_fire`)
     - 성공 시 보스 다음 턴 특수기 무효 + stun

5. **속성 동적 변경 (Unlock Affinity)** — 보스가 자기 속성 매 턴 변경.
   - 영웅의 저항 빌드 무력화. stsl 의 후반 보스에 도입 가치 (kronos 같은 final 한정).

6. **3 페이즈 모두 동일 패턴 + 강화 (Louis)** — 단순 difficulty ramp.
   - 페이즈마다 완전 다른 메커닉 (Paintress) vs 단순 강화 (Louis) — 디자인 선택.

---

## 다른 inspiration 문서 비교

- [clair_obscur_bosses.md](clair_obscur_bosses.md) — Expedition 33 (실시간 액션 RPG, 페이즈 + 컷씬 중심)
- [persona_bosses.md](persona_bosses.md) — P4G/P5R (Press Turn 모태 + Palace 별 모티프)
- **metaphor_refantazio_bosses.md** (본 문서) — Atlus 의 최신작, Press Turn 정련 + Archetype + Form 전환

### Atlus 시리즈 공통 디자인 철학 (P4/P5 + Metaphor)
1. 약점 시스템 = **추가 행동 자원**
2. 보스에 **Soul Cry / Heat Riser / Dekaja** 등 자기 강화 + 파티 버프 제거 표준 셋
3. **속성 다양성 강제** + Archetype/Persona 교체로 영웅 빌드 자유
4. **마지막 페이즈는 형식 변경** — 1대1 듀얼 (Shido) / 거대화 (Paintress 비교) / 자세 시그널 (Louis)

---

## 참조

- [Game8 - All Bosses List](https://game8.co/games/Metaphor-ReFantazio/archives/477508)
- [Game8 - Louis Boss Guide](https://game8.co/games/Metaphor-ReFantazio/archives/480983)
- [Game8 - Melancholia Zorba Guide](https://game8.co/games/Metaphor-ReFantazio/archives/481110)
- [Game8 - Zorba Boss Guide](https://game8.co/games/Metaphor-ReFantazio/archives/478595)
- [Game8 - Destroyer Charadrius Final Boss](https://game8.co/games/Metaphor-ReFantazio/archives/481380)
- [Game8 - Skybound Avatar Walkthrough](https://game8.co/games/Metaphor-ReFantazio/archives/481952)
- [Game8 - 100% Walkthrough Guide](https://game8.co/games/Metaphor-ReFantazio/archives/478501)
- [GamerGuides - Louis Guiabern Boss Guide](https://www.gamerguides.com/metaphor-refantazio/guide/walkthrough/finale/louis-guiabern-9-24-boss-guide)
- [GamerGuides - Melancholia Zorba Boss Guide](https://www.gamerguides.com/metaphor-refantazio/guide/walkthrough/finale/melancholia-zorba-boss-guide)
- [GamerGuides - Zorba Boss Guide](https://www.gamerguides.com/metaphor-refantazio/guide/walkthrough/grand-trad/zorba-boss-guide)
- [GamerGuides - Skybound Avatar Royal Garden](https://www.gamerguides.com/metaphor-refantazio/guide/walkthrough/finale/skybound-avatar-royal-garden-walkthrough)
- [Neoseeker - Melancholia Zorba Guide](https://www.neoseeker.com/metaphor-refantazio/guides/Melancholia_Zorba)
- [Neoseeker - Skybound Avatar Walkthrough](https://www.neoseeker.com/metaphor-refantazio/guides/Skybound_Avatar)
- [ScreenRant - How to Beat the Final Boss](https://screenrant.com/metaphor-refantazio-beat-final-boss-tips-strategy/)
- [ScreenRant - Secret Final Boss](https://screenrant.com/how-to-unlock-beat-metaphor-refantazios-secret-final-boss/)
- [GameLeap - All Bosses & Weaknesses](https://www.gameleap.com/articles/metaphor-refantazio-all-bosses-weaknesses-listed)
- [GameLeap - Final Boss Guide](https://www.gameleap.com/articles/metaphor-refantazio-how-to-beat-the-final-boss)
- [FandomWire - Melancholia Zorba](https://fandomwire.com/metaphor-refantazio-how-to-beat-melancholia-zorba/)
- [Sportskeeda - Defeat Melancholia Zorba](https://www.sportskeeda.com/esports/how-defeat-melancholia-zorba-metaphor-refantazio)
- [TheGamer - Best Bosses](https://www.thegamer.com/metaphor-refantazio-best-bosses/)
- [TheGamer - Skybound Avatar Enemies](https://www.thegamer.com/metaphor-refantazio-skybound-avatar-enemy-item-treasurewalkthrough/)
- [GameRant - Bosses & Guides Hub](https://gamerant.com/metaphor-refantazio-guide-tips-bonds-quests-bosses-followers-walkthroughs/)
- [DualShockers - Every Operation Ranked](https://www.dualshockers.com/metaphor-refantazio-every-operation-ranked/)
- [Selphie1999gaming - List of All Bosses](https://selphie1999gaming.com/game-guides/metaphor-refantazio/metaphor-refantazio-list-of-all-bosses/)
- [Readomax - List of All Bosses](https://readomax.com/list-of-all-bosses-in-metaphor-refantazio-a-guide/)
- [EarlyGuides - Boss Guide Strategies](https://www.earlyguides.com/metaphor-refantazio/bosses)
- [GameFAQs - Skybound Avatar Conquest](https://gamefaqs.gamespot.com/xbox-series-x/409958-metaphor-refantazio/faqs/81526/operation-skybound-avatar-conquest)
- [TheBackdash - Secret Final Boss Guide](https://thebackdash.com/gaming/metaphor-refantazio-secret-final-boss-guide-how-beat-louis-secret-form/)

---

> **주의**: 14 메인 보스의 정확한 list 와 일부 중간 보스 상세 패턴은 자료별 차이가 있습니다. 추가 정보 필요 시 Game8 / GamerGuides 의 챕터별 walkthrough 참조 권장.
