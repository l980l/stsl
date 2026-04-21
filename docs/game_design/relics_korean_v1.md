# 챕터 2 한국 신화 렐릭 기획 v1

## 배분 방침

- 3종 모두 공용 렐릭 (`owner_hero_id` 없음) — 북유럽 렐릭 3종과 동일 방식
- 한국 신화 테마 "저승계의 압박"과 "수호" 시그니처 반영
- 향후 한국 영웅 추가(M5) 시 전용 렐릭 별도 설계

기존 렐릭 현황:
- 운명의 룬: BATTLE_START, DRAW +2
- 묠니르의 파편: BATTLE_START, BLOCK +10
- 이둔의 사과: BATTLE_WIN, HEAL +15

한국 렐릭은 위와 겹치지 않는 트리거·효과 조합으로 차별화.

---

## 렐릭 목록 (3종)

RelicResource 트리거: `PASSIVE, BATTLE_START, PLAYER_TURN_START, PLAYER_TURN_END, BATTLE_WIN, ON_HERO_DAMAGED`
RelicResource 효과: `HEAL, ENERGY, DRAW, APPLY_STATUS_ENEMY, MAX_HP, RECOVER_CARD, GAIN_MORALE, COST_REDUCTION, BLOCK, DAMAGE_HERO`

---

### 1. 저승 부적

> "저승길을 막아주는 부적. 전투가 시작될 때 온몸에 기운이 감돈다."

| 항목 | 값 |
|---|---|
| 트리거 | BATTLE_START |
| 효과 | ENERGY +1 |
| 수치 | value = 1 |
| owner_hero_id | 없음 (공용) |

**기획 의도**: 전투 시작 에너지 +1은 첫 턴 코스트 1짜리 카드 1장을 추가로 사용 가능하게 함. "저승에서 보호받아 더 빨리 행동" 테마. 운명의 룬(DRAW +2)과 달리 코스트 축으로 차별화.

**밸런스 메모**: 전투 시작 에너지 +1은 매 전투 영향. 고비용 카드 비율이 높은 빌드에서 가치 극대화. 나폴레옹 군단 아키타입(고비용 카드 다수)과 시너지.

---

### 2. 도깨비 방망이 파편

> "도깨비 방망이의 일부. 적을 처치할 때마다 신기한 기운이 쌓인다."

| 항목 | 값 |
|---|---|
| 트리거 | BATTLE_WIN |
| 효과 | GAIN_MORALE +3 |
| 수치 | value = 3 |
| owner_hero_id | 없음 (공용) |

**기획 의도**: 전투 승리 시 팀 사기(Morale) +3. 나폴레옹 사기 소모 빌드에서 매 전투 승리가 다음 전투의 자원이 됨. "도깨비 방망이로 두드리면 뚝딱 나온다" 테마.

**밸런스 메모**: Morale 3은 나폴레옹 빌드에서 1코스트 추가 사기 소모 카드를 바로 쓸 수 있는 양. 전투 연속 승리 시 효과 누적. 클레오파트라 CONSUME_MORALE 카드와의 상호작용 확인 필요 (있다면 추가 시너지).

---

### 3. 삼태극 부적

> "하늘·땅·인간의 조화를 새긴 부적. 동료가 피해를 입을 때마다 반응한다."

| 항목 | 값 |
|---|---|
| 트리거 | ON_HERO_DAMAGED |
| 효과 | BLOCK +10 |
| 수치 | value = 10 |
| owner_hero_id | 없음 (공용) |
| condition_value | 0 (조건 없음) |

**기획 의도**: 영웅이 피해를 받을 때마다 해당 영웅(또는 팀 최저 HP 영웅)에게 방어도 +10 자동 부여. "삼태극 — 음양의 순환, 피해를 받으면 방어가 생긴다" 테마.

**구현 메모**: `ON_HERO_DAMAGED` 트리거는 이미 `relic_resource.gd`에 존재. 방어도 부여 대상이 "피해 받은 영웅 본인"인지 "팀 전체"인지 구현 PR에서 확인. 피해 받은 본인에게만 적용 시 이순신 필사즉생(저HP 유지) 빌드와 강한 시너지.

**밸런스 메모**: 다중 적 + 다중 공격 조합에서 매 히트마다 10 방어도. 삼족오 광역(ALL 아군)이 3명 모두를 때리면 30 방어도 즉시 발동. 과도한 시너지 발생 시 트리거를 "턴당 1회"로 제한 검토.

---

## 구현 메모

- `relics.gd` `build_pool()` 배열에 3종 추가 후 기존 풀 크기 25 → 28로 `test_relics.gd` 업데이트 필요.
- 함수명 제안: `_underworld_talisman()`, `_dokkaebi_hammer_shard()`, `_samtaegeuk_charm()`
- `GAIN_MORALE` 효과가 `BattleManager`의 morale 시스템과 연결되는지 기존 코드 확인 (나폴레옹 GAIN_MORALE 카드 로직 참조).

## 챕터 2 운영 방식 메모

중국·일본 모듈이 빈 스텁인 상태에서 `act_mythologies = ["korean","chinese","japanese"].shuffle()` 실행 시 Act 2·3에서 빈 적 풀 오류 발생.

**구현 PR 권장 방식**:
```gdscript
func _get_chapter_mythology_pool(chapter: int) -> Array[String]:
    if chapter == 1:
        return ["greek", "egyptian", "norse"]
    # 챕터 2: 구현된 신화만 포함
    var implemented := []
    if _KoreanAct1.elites().size() > 0:
        implemented.append("korean")
    if _ChineseAct1.elites().size() > 0:
        implemented.append("chinese")
    if _JapaneseAct1.elites().size() > 0:
        implemented.append("japanese")
    # 한국만 구현된 경우 3 Act 모두 한국으로
    if implemented.size() == 1:
        return [implemented[0], implemented[0], implemented[0]]
    return implemented
```

중국·일본 구현 완료 시 자동으로 3신화 셔플 풀로 복귀.
