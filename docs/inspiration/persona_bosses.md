# Persona 4 / Persona 5 — 메인 보스 정리

> **⚠ 스포일러 주의** — 본 문서는 두 게임 메인 스토리 보스의 패턴·메커닉을 다룹니다.
> **출처**: Megami Tensei Wiki (Fandom), Samurai Gamers, GameRant, TheGamer, PersonaFans, GameFAQs, Steam Guide (문서 끝 참조).
> **마지막 갱신**: 2026-05-19
> **개발사**: Atlus (P4 2008 / P4G 2012 / P5 2016 / P5R 2019)
> **본 문서의 목적**: stsl 카드게임 보스 디자인 (시그니처 / 페이즈 / 카드 트리거 / 약점 시스템) 참고 자료.

---

# Part 1. Persona 4 Golden

JRPG 클래식 — 약점 타격 시 추가 턴 (1 More) + All-out Attack 콤보. **요일 기반 진행** + **던전별 Shadow 보스**.

## 메인 보스 list

| 던전 / 챕터 | 보스 | 약점 |
|---|---|---|
| Shopping District (튜토리얼) | Shadow Yosuke | - |
| Yukiko's Castle | Shadow Chie (미니) → **Shadow Yukiko** | 얼음 |
| Steamy Bathhouse | **Shadow Kanji** | (없음, 전기 흡수) |
| Marukyu Striptease | **Shadow Rise** (페이즈 1, 전 속성 무효) → **Shadow Teddie** (페이즈 2) | 변동 |
| Void Quest | Killing Hand (F7 미니) → **Shadow Mitsuo** (F10) | 전기 |
| Secret Laboratory | **Shadow Naoto** | 전기 (P4) / 약점 없음 (P4G) |
| Heaven | **Kunino-sagiri** (Namatame) | 가변 (Quad-Converge) |
| Magatsu Inaba | **Ameno-sagiri** (안개 정 final) | - |
| Hollow Forest (Golden 추가) | **Marie** | - |
| Yomotsu Hirasaka (True ending) | **Izanami** (페이즈 1 + 2) | - |

---

## 보스 상세

### Shadow Yukiko
- **약점**: 얼음 (불 흡수)
- **핵심 메커닉**:
  - **Charming Prince 졸개 소환** — 회복 위주, 약점 얼음
  - **Burn to Ashes**: 광역 화염
- **stsl 참고**: 졸개 소환 + 졸개가 회복 담당 → "본체 직접 타격 어렵게" 메커닉. summon + heal_other 패턴.

### Shadow Kanji
- **약점 없음** + **전기 흡수**
- **핵심 메커닉**:
  - **Tough Guy + Nice Guy 졸개** 동시 등장
    - Nice Guy 약점: 얼음
    - Tough Guy 약점: 불
  - 본체 약점 없음 — 졸개 약점으로 1 More 확보
- **stsl 참고**: 본체는 무약점, 졸개에 약점 분리. 졸개 처치가 우선 전술. 영웅 다수 약점 카드로 졸개 처리 → 본체 일반 공격 사이클.

### Shadow Rise (페이즈 1) → Shadow Teddie (페이즈 2)
- **페이즈 1 (Shadow Rise)**: 모든 속성 무효 — 직접 공격만
- **페이즈 2 (Shadow Teddie)**: Rise 분석 후 본격 전투
- **stsl 참고**: **속성 면역 페이즈** — 영웅이 모든 카드 무효 시 어떻게 진행할지 (피지컬 공격만 통하게). 무력화 메커닉으로 활용.

### Shadow Naoto
- **약점**: 전기 (P4) / 없음 (P4G 강화판)
- **저항**: 물리, 불, 얼음
- **핵심 메커닉**:
  - **각 속성 강화 ver** 보유 (Maziodyne 등 -dyne 계열)
  - **반사 배리어** (물리 또는 원소 한 번 반사)
  - **버프/디버프 제거** (Dekaja, Dekunda)
  - **HP/SP 동시 감소 + 상태이상**
- **stsl 참고**:
  - 반사 배리어 1회 → "다음 공격 반사" 디버프. 영웅이 1턴 강한 공격 보류 필요.
  - 버프/디버프 동시 제거 → 영웅 전략 무효화. 영웅이 buff 쌓고 immediate 공격 빌드 안정성 강제.

### Kunino-sagiri (Heaven 보스)
- **핵심 메커닉**:
  - **Control** — 파티원 1명을 **세뇌해서 Yu 공격**
  - **Quad-Converge** — 4개 속성 중 3개 면역 + 1개 약점 (랜덤)
- **stsl 참고**:
  - **세뇌 (mind control)** — 영웅 1명이 파티원 공격. 신규 status_type `controlled` 추가 가능 (1턴 동안 적 편).
  - **속성 면역 로테이션** — 매 턴 1개만 통함. 영웅이 매번 속성 변경 강제 → 덱 다양성 강제.

### Ameno-sagiri (안개의 화신, P4 standard 엔딩 final)
- **핵심 메커닉**:
  - **Foolish Whisper**: 파티 전체 침묵 (스킬 사용 불가)
  - **Zio/Agi/Garu**: 각 속성 강타 → 약점 시 knockdown
  - 후반 (HP 50% 이하):
    - **Bewildering Fog** — 2턴간 완전 무적
    - 이 동안 자기 **Mind Charge + 버프** 발동
    - 후속: **Agneyastra** (1~3회 강타) / **Nebula Occulus** (광역 강타)
- **stsl 참고**:
  - **임시 무적 + 자기 차지 페이즈** — 영웅이 회복/방어 강제. CHARGE_UP 동안 자기 무적 + 후속 강타 패턴.
  - **광역 침묵 (스킬 봉인)** — silence 상태이상. stsl 의 카드 봉인 메커닉으로 매핑.

### Izanami (True Ending final)
- **2 페이즈**
- **페이즈 2**: **턴당 2회 행동** + 강력한 속성 강타
- **즉사 공격**: **상태이상 걸린 캐릭터 즉사**
- **stsl 참고**:
  - 페이즈 2 double_action — Renoir Enrage 와 동일 메커닉 (이미 [clair_obscur_bosses.md](clair_obscur_bosses.md) 에 매핑).
  - **상태이상 + 즉사 콤보** — 영웅이 디버프 즉시 정화 강제. stsl 의 cleanse 카드 필수성 강화.

---

# Part 2. Persona 5 Royal

**Palace 침투형** — 각 챕터 보스 = 'Shadow 통치자'. 모티프 = 7대 죄악 (Lust/Vanity/Gluttony/Wrath/Greed/Envy/Pride).

## 메인 보스 list

| Palace / 챕터 | 모티프 | Shadow 보스 | Persona |
|---|---|---|---|
| Castle of Lust | 욕정 | **Kamoshida** | Asmodeus |
| Museum of Vanity | 허영 | **Madarame** | Azazel |
| Bank of Gluttony | 탐욕 | **Kaneshiro** | Bael |
| Pyramid of Wrath | 분노 | **Wakaba's Cognition** (Futaba's mother as Sphinx/Bird) | - |
| Spaceport of Greed | 야망 | **Okumura** | Mammon |
| Casino of Envy | 시기 | **Sae Niijima** | Leviathan |
| Cruiser of Pride | 자만 | **Shido** | Samael |
| Mementos Depths | 통제 | **Yaldabaoth** (Holy Grail) | - |
| Maruki's Palace (Royal 추가) | 구원 | **Maruki** | Adam Kadmon |

---

## 보스 상세

### Kamoshida (Asmodeus, 첫 Palace)
- **튜토리얼 보스** — 약점/콤보 시스템 학습
- 무기를 빼앗긴 후 졸개에게 컵 던지기 등 단순 무브.

### Madarame (Azazel, 두 번째)
- **핵심 메커닉**:
  - 자신을 **여러 얼굴 (눈/코/입)** 로 분리
  - 각 얼굴이 **다른 속성 데미지 시 회복**
  - 잘못된 속성 공격 시 적이 회복됨
- **stsl 참고**:
  - **부분 부위 약점 시스템** — 적이 여러 부위로 분리, 각 부위에 다른 약점.
  - 잘못된 속성 = **힐** → 영웅이 정확한 속성 카드 선택 강제. 정보 가시화 (intent 또는 weak_spot 표시) 중요.

### Kaneshiro (Bael, 세 번째)
- **거대 로봇 (Piggytron) + Kaneshiro 본체** 두 부분
- 본체 + 운반체 동시 처리
- **stsl 참고**: 보스 + 탑승체 메커닉. 별도 HP 바 두 개.

### Wakaba's Cognition (Futaba 의 어머니, Pyramid)
- **거대 새 (Sphinx)** 형태
- 광역 **물리 + 바람 강타**
- **방어 권장** — 시작 후 cutscene 전까지 무력화
- Futaba 가 전투 후반 합류 → 지원 페르소나 활성
- **stsl 참고**:
  - **시간 제한 방어 페이즈** — 처음 N턴 동안 영웅이 공격 무력화, 방어/회복만 → cutscene 후 본 전투. 페이즈 0 같은 prologue 패턴.
  - **추가 영웅 합류** — 전투 중 신규 캐릭터 등장. roster 동적 변경.

### Okumura (Mammon, 다섯 번째)
- **5 페이즈 — 점진적 거대 로봇 폭격**
- 매 페이즈 새 졸개 wave 소환
- 시간 제한 (몇 턴 안에 처리 못 하면 패배)
- **stsl 참고**:
  - **시간 제한 보스** — N턴 안에 격파 강제. 영웅 덱이 burst dmg 빌드 강제.

### Sae Niijima (Leviathan, 카지노 — 룰렛/카드 모티프)
- **카지노 룰렛 + 카드 모티프 패턴**
- **stsl 참고**: 카드 게임 모티프 — stsl 자체 컨셉과 직접 연관. random 효과 카드 (룰렛처럼) 보스 패턴.

### Shido (Samael, 7번째 — 4 페이즈)
- **페이즈 1: Beast of Human Sacrifice** — Shido 의 추종자 합체 cognition
  - 물리 + 총 반사
  - 마법 약점 없음 → magic spam
- **페이즈 2: Samael 등장**
  - 약점/저항 없음
  - **Heat Riser** — 자기 3종 버프 동시
  - **Dekaja** — 파티 버프 제거
  - **Tyrant's Fist**: Fear 부여
  - **Tyrant's Purge**: 강타 + 즉사 확률
- **페이즈 3 (HP 25%): 1대1 듀얼**
  - 다른 파티원 강제 퇴장 — **Joker 단독 vs Samael**
  - Samael 행동 1회/턴 → 강력한 속성 강타 (Inferno, Diamond Dust)
- **페이즈 4: True Samael**
  - 행동 2회/턴 부활
  - 모든 -dyne 광역 스킬
  - 파티원 knockdown 시 → **Debilitate** (전 디버프 한 번에)
- **stsl 참고**:
  - **4 페이즈 + 페이즈 3 = 1대1 듀얼** — 영웅 전원 중 1명만 남기는 메커닉. roster 강제 축소 → 솔로 빌드 가치.
  - **자기 3종 버프 + 파티 디버프 제거** — Renoir/Naoto 와 동일 패턴.
  - **knockdown 트리거 디버프** — 영웅이 행동불능 시 추가 디버프 폭격. stsl 의 stun trigger 강화 메커닉.

### Yaldabaoth (Holy Grail, P5 vanilla final)
- 1회/턴 행동 — but **최대 4개 팔 소환**, 각 팔이 별도 행동
  - 총 5회/턴 (본체 1 + 팔 4)
- **Arrow of Light**: 핵심 강타
- **Dekaja + Dekunda**: 버프/디버프 양방향 제거
- **Gun of Execution (팔)**:
  - **Distorted Lust** — 강타 + Lust (Fear 와 동일 — 턴 강제 무효)
  - **Distorted Avarice** — 강타 + Hunger
- **체력 1/3 시**: 4개 팔 전체 부활 → 2턴 후 **Divine Apex** → **Rays of Control** (광역 Almighty 극강타)
- **stsl 참고**:
  - **본체 + 부위 (팔) 다중 행동** — 부위 처치가 본체 행동 차감. 분리 약점 시스템.
  - **HP 임계 시 부위 전체 부활 + 카운트다운 후 즉사기** — phase_thresholds + delay_intent 결합. 영웅이 부활 후 2턴 안에 모든 팔 재처치 강제.

### Maruki (Adam Kadmon, P5R 추가 final)
- **4 단계 전투**
- **페이즈 1**: 일반 전투
- **페이즈 2 (Adam Kadmon)**:
  - **사실상 무적** — 모든 공격 차단
  - **Full Force** 광역 강타 반복
  - **약점 발견 (Futaba 도움)**: Adam 이 공격 자세 진입 시 (주먹에 에너지 집중) 방어 하락
- 게임 메커니즘 + 스토리 종합 — "모든 전술 동원" 요구
- **stsl 참고**:
  - **자세 기반 무적 / 약점** — 보스가 평소 무적, 특정 행동 (공격 charge) 시점만 약점. **CHARGE_UP intent 의 charge 턴 = 적 자신의 약점 turn** 으로 매핑.
  - **분석가 (Futaba)** 시스템 — 영웅이 매 턴 보스 약점 정보 alert. stsl 도 act3 보스에 "이번 턴 약점" 표시 UI.

---

# stsl 디자인 매핑 요약 (P4/P5 통합)

| Persona 보스 메커닉 | stsl 대응 시스템 | 비고 |
|---|---|---|
| 약점 1 More (속성 시스템) | damage_type 약점 | 이미 구현 |
| 졸개 소환 (Shadow Yukiko/Kanji) | SUMMON action_type | 신규 추가 검토 |
| 졸개에 약점 분산 (Kanji) | summon_with_weakness | 신규 검토 |
| 모든 속성 무효 페이즈 (Rise) | `element_immunity` | 신규 검토 |
| 반사 배리어 (Naoto) | `reflect_buff` | 신규 검토 |
| 버프/디버프 제거 (Dekaja) | `dispel` intent | 신규 검토 |
| 세뇌 (Control — Kunino) | `controlled` status (1턴 적 편) | 신규 검토 |
| 회전 속성 면역 (Quad-Converge) | rotating immunity per turn | 신규 검토 |
| 무적 페이즈 + 자기 차지 (Ameno) | `invincible_charge` (이미 CHARGE_UP 매핑) | 변형 |
| 광역 침묵 (Foolish Whisper) | `silence` status (카드 봉인) | 신규 검토 |
| 상태이상 걸린 캐릭 즉사 (Izanami) | `instakill_on_status` 조건부 | 신규 검토 |
| 부위 분리 약점 (Madarame) | multi-part boss (별도 HP) | 신규 검토 |
| 보스 + 탑승체 (Kaneshiro) | mount + rider | 신규 검토 |
| 시간 제한 보스 (Okumura) | turn_limit_kill | 신규 검토 |
| 1대1 듀얼 페이즈 (Shido) | force_solo_phase | 신규 검토 |
| 본체 + 다중 부위 (Yaldabaoth) | sub_part_actions | 신규 검토 |
| 자세 기반 약점 (Maruki) | intent-tied weak_turn | 신규 검토 |
| 카지노 룰렛 모티프 (Sae) | random_effect intent | stsl 자체 컨셉과 직접 연관 |
| Futaba 분석가 시스템 | weakness_alert UI | 신규 검토 |

---

## 디자인 관찰 — Persona 시리즈 공통

1. **약점 = 1 More + All-out Attack** 시스템 — 약점 타격이 그냥 추가 데미지가 아닌 **콤보 빌드 자원**. stsl 의 약점 타격 보상 강화 검토 (예: 다음 카드 cost -1).

2. **속성 다양성 강제** — 보스마다 다른 약점 / 같은 속성 spam 못 함. stsl 도 act 마다 보스 약점 다양화 (이미 mythology damage_type 으로 부분 구현).

3. **페이즈마다 메커니즘 완전 변경** — 단순 HP 깎기가 아닌 페이즈별 전략 변경. stsl phase_patterns 가 이미 매핑 가능.

4. **졸개 / 부위 / 탑승체 등 본체 분리** — 영웅이 우선순위 판단. stsl 의 SUMMON action_type 강화 가치.

5. **버프/디버프 양방향 제거 + 자기 강화** — 영웅의 buff 쌓기 전략 무력화. stsl 보스에 `dispel` intent 추가 검토.

6. **무적 페이즈 / 시간 제한 / 1대1 듀얼** — 영웅 행동에 제약 부과 → 빌드 다양성 강제. stsl 의 후반 보스 차별화 영감.

7. **분석가 시스템 (Futaba)** — 보스의 약점/intent 정보 부분 공개. stsl 의 intent 시스템 + 추가 "weakness_alert" 가능.

---

## 참조

### Persona 4
- [Megami Tensei Wiki - Bosses List](https://megamitensei.fandom.com/wiki/List_of_Persona_4_Bosses)
- [Megami Tensei Wiki - Ameno-sagiri](https://megamitensei.fandom.com/wiki/Ameno-sagiri)
- [Megami Tensei Wiki - Shadow Yukiko](https://megamitensei.fandom.com/wiki/Shadow_Yukiko)
- [Megami Tensei Wiki - Shadow Naoto](https://megamitensei.fandom.com/wiki/Shadow_Naoto)
- [PersonaFans - P4 Bosses Guide](https://personafans.com/enemies/persona-4-bosses-guide/)
- [Steam Guide - P4G Recommended Level / Affinities](https://steamcommunity.com/sharedfiles/filedetails/?id=2235735894)
- [TheGamer - P4G Every Boss Ranked](https://www.thegamer.com/persona-4-golden-every-boss-fight-ranked-difficulty-challenge/)
- [TheGamer - P4G Shadow Yukiko Guide](https://www.thegamer.com/persona-4-golden-p4g-shadow-yukiko-boss-battle-strategy-guide-tips/)
- [TheGamer - P4G Ameno-Sagiri Guide](https://www.thegamer.com/persona-4-golden-p4g-ameno-sagiri-boss-battle-guide/)
- [TheGamer - P4G Kunino-Sagiri Guide](https://www.thegamer.com/persona-4-golden-p4g-kunino-sagiri-namatame-heaven-boss-battle-guide/)
- [GameRant - Beat Ameno-Sagiri](https://gamerant.com/persona-4-golden-beat-ameno-sagiri-guide/)
- [HubPages - Heaven/Twisted Inaba/Yomotsu Boss Guide](https://discover.hubpages.com/games-hobbies/Persona-4-Boss-Guide-Walkthrough-Part-3-Heaven-Twisted-Inaba-Yomotsu-Hirasaka)

### Persona 5 (Royal)
- [Megami Tensei Wiki - Masayoshi Shido](https://megamitensei.fandom.com/wiki/Masayoshi_Shido)
- [Megami Tensei Wiki - Adam Kadmon](https://megamitensei.fandom.com/wiki/Adam_Kadmon)
- [Samurai Gamers - Kamoshida (Asmodeus)](https://samurai-gamers.com/persona-5/kamoshida-boss-guide/)
- [Samurai Gamers - Yaldabaoth](https://samurai-gamers.com/persona-5/final-boss-strategy-guide-yaldabaoth/)
- [Samurai Gamers - Shido (Samael)](https://samurai-gamers.com/persona-5/shidou-samael-masayoshi-boss-guide/)
- [Samurai Gamers - Adam Kadmon](https://samurai-gamers.com/persona-5/adam-kadmon-boss-guide/)
- [Samurai Gamers - All Boss Guides](https://samurai-gamers.com/persona-5/bosses-list-2/)
- [TheGamer - P5R Every Palace Boss Weakness](https://www.thegamer.com/persona-5-every-palace-boss-weakness/)
- [TheGamer - P5R Bosses Hardest to Easiest](https://www.thegamer.com/persona-5-royal-bosses-hardest-easiest/)
- [TheGamer - P5R Shido Strategy](https://www.thegamer.com/persona-5-royal-shadow-shido-boss-battle-strategy-guide/)
- [GameRant - Holy Grail (Yaldabaoth) Guide](https://gamerant.com/persona-5-royal-holy-grail-boss-guide/)
- [GameRant - Shido Guide](https://gamerant.com/persona-5-royal-shido-boss-guide/)
- [Gfinity Esports - P5R Palaces Overview](https://www.gfinityesports.com/article/persona-5-royal-palaces)
- [PersonaFans - P5 Palaces Guide](https://personafans.com/locations/persona-5-palaces-guide/)
- [TV Tropes - P5 Palace Rulers](https://tvtropes.org/pmwiki/pmwiki.php/Characters/Persona5PalaceRulers)
- [matthasanopinion - P5R Every Boss Ranked](https://matthasanopinion.com/2022/12/09/persona-5-royal-every-boss-ranked/)
