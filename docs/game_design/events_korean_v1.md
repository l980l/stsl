# 챕터 2 한국 신화 이벤트 기획 v1

## 이벤트 풀링 구조 설계

### 현황 분석

현재 이벤트 파일은 Act 기반으로 구분됨:
- `resources/events/events_act1.gd` — 그리스 테마 11종 (Act 1 어느 신화에서든 사용)
- `resources/events/events_act2.gd` — 이집트 테마 10종
- `resources/events/events_act3.gd` — 북유럽 테마 10종

`_build_event_pool()`이 `current_act` 기준으로 파일 1개를 고름. 신화별 분기 없음.

→ 챕터 2(한국·중국·일본) 런에서 Act 1을 그리스 이벤트 풀로 실행하면 주제 일관성 파괴.

### 권장 설계 — 신화별 이벤트 파일 도입

**새 파일**: `resources/events/events_korean.gd` (이번 구현 PR에서 생성)

**`_build_event_pool()` 수정 방향**:
```gdscript
func _build_event_pool() -> Array:
    var myth: String = act_mythologies[current_act - 1]
    match myth:
        "korean":   return _EventsKorean.build_pool()
        "chinese":  return _EventsChinese.build_pool()
        "japanese": return _EventsJapanese.build_pool()
        _:
            match current_act:
                2: return _EventsAct2.build_pool()
                3: return _EventsAct3.build_pool()
            return _EventsAct1.build_pool()
```

기존 그리스·이집트·북유럽 이벤트 파일 수정 없음. 중국·일본 이벤트가 없는 동안은 `_` 분기에서 Act 기반 fallback 유지.

### 이벤트 배분

한국 이벤트 10종은 `events_korean.gd` 단일 파일에 통합. Act 무관하게 어느 Act에서든 한국 신화 런이면 이 풀 사용. 비율 = 3신화 × 1파일 각각 → `events_korean.gd`가 10종 전부 담당 (이전 Act 기반 11/10/10 분리와 달리 신화 기반 통합).

---

## 이벤트 목록 (10종)

사용 가능한 EventChoice.EffectType: `NONE, GOLD, HEAL, DRAW_UP, REMOVE_CARD, ADD_RELIC, ADD_HERO, ADD_RELIC_GAMBLE`

---

### 1. 저승사자의 방문

> 밤길을 걷다 검은 갓을 쓴 저승사자와 마주쳤다. 그는 명단을 꺼내 당신의 이름을 확인한 뒤, 조용히 말한다. "아직은 아니오. 대신, 무언가를 가져가겠소."

**선택지**:
| 레이블 | 효과 | 비용 |
|---|---|---|
| 받아들인다 | GOLD +70 | HP -40 |
| 거절한다 | 아무 일도 없다 | NONE |

**기획 의도**: 리스크/보상 판단. HP가 낮은 팀은 거절 선택. 골드 여유 있을 때 HP 소모보다 덜 아픈 것.

---

### 2. 도깨비 방망이

> 길가에 낡은 방망이가 떨어져 있다. 잡으면 이상한 기운이 느껴진다.

**선택지**:
| 레이블 | 효과 | 비용 |
|---|---|---|
| 금 나와라 뚝딱! | GOLD +80 | NONE |
| 쌀 나와라 뚝딱! | HEAL +35 | NONE |
| 가져간다 (도박) | ADD_RELIC_GAMBLE | NONE |

**기획 의도**: 안전한 두 옵션 + 도박 선택지. ADD_RELIC_GAMBLE은 저주 렐릭 가능성 있음. 한국 민담의 "도깨비 방망이" 직접 참조.

---

### 3. 구미호의 유혹

> 아름다운 여인이 당신의 앞을 막아선다. 그녀의 눈이 여우처럼 빛난다. "당신의 약점 하나를 제거해주죠. 대신, 힘을 하나 드릴게요."

**선택지**:
| 레이블 | 효과 | 비용 |
|---|---|---|
| 거래를 받아들인다 | ADD_RELIC (랜덤 일반 렐릭) | REMOVE_CARD (랜덤 카드 1장 제거) |
| 거절한다 | NONE | NONE |

**기획 의도**: 카드 제거(덱 정제) + 렐릭 획득의 복합 거래. 덱에 쓰레기 카드가 많을수록 매력적. 현재 EffectType 단일 선택지에 두 효과 중첩이 가능한지 구현 확인 필요. 불가 시: "REMOVE_CARD" 단일 효과로 처리 후 "렐릭 획득은 별도 보상" 메모.

---

### 4. 무당의 굿판

> 붉은 무복을 입은 무당이 굿을 올리고 있다. "팀원의 상처와 저주를 씻어드릴 수 있어요. 다만 신령님께 드릴 제물이 필요하답니다."

**선택지**:
| 레이블 | 효과 | 비용 |
|---|---|---|
| 굿을 부탁한다 | HEAL +30 | GOLD -50 |
| 구경만 한다 | NONE | NONE |

**기획 의도**: 골드 소비 치유. 상점 카드 제거(GOLD -75)보다 저렴한 팀 회복. HP 위기팀 전용.
> 구현 메모: "디버프 정화" 효과는 현재 EffectType에 없음. HEAL만으로 구현. 후속 버전에서 REMOVE_DEBUFF EffectType 추가 가능.

---

### 5. 삼신할머니의 축복

> 노파가 아기포대기를 안고 당신을 바라본다. "아이고, 이 사람들은 한이 많겠구만. 내가 하나 점지해줄게." 그녀가 손을 내밀자 따뜻한 빛이 퍼진다.

**선택지**:
| 레이블 | 효과 | 비용 |
|---|---|---|
| 감사히 받는다 | MAX_HP +30 (랜덤 영웅 1명) | NONE |
| 괜찮다고 한다 | NONE | NONE |

**기획 의도**: 무료 최대 HP 증가. "점지" 테마. 현재 살아있는 랜덤 영웅 1명에게 적용. MAX_HP EffectType 사용.

---

### 6. 단군의 예언

> 마니산 제단에서 하얀 빛이 내려온다. 고요한 목소리가 들린다. "너희의 길에는 두 갈래가 있다. 하나는 강인함, 하나는 지혜."

**선택지**:
| 레이블 | 효과 | 비용 |
|---|---|---|
| 강인함의 길 | ADD_RELIC (랜덤 렐릭) | NONE |
| 지혜의 길 | DRAW_UP +1 | NONE |

**기획 의도**: 두 가지 좋은 선택지. 렐릭 픽 덱 vs 카드 드로우 빌드 유도. 어느 쪽도 손해 없어 이벤트 참여 선택이 명확.

---

### 7. 산신령과의 내기

> 백발 노인이 바위 위에 앉아 바둑을 두고 있다. 그는 고개도 들지 않고 말한다. "나를 이기면 소원을 들어주겠네. 지면... 뭔가를 내놓아야 해."

**선택지**:
| 레이블 | 효과 | 비용 |
|---|---|---|
| 내기를 수락한다 | GOLD +90 OR HP -25 (50/50 랜덤) | NONE |
| 그냥 지나친다 | NONE | NONE |

**기획 의도**: ADD_RELIC_GAMBLE 방식으로 결과가 무작위인 선택지. 골드가 많이 필요하거나 여유있는 팀이 도박. GOLD와 HP 손실 중 랜덤이므로 `ADD_RELIC_GAMBLE` EffectType 응용 or 별도 구현 필요. 구현 불가 시: GOLD +50 / HP -20 두 선택지로 분리 가능.

---

### 8. 용왕의 시험

> 파도가 밀려오더니 물속에서 용의 발톱이 드러난다. "내 바다를 지나가려면 시험을 통과하여라."

**선택지**:
| 레이블 | 효과 | 비용 |
|---|---|---|
| 시험에 응한다 | GOLD +100 | HP -30 |
| 뇌물을 바친다 | HEAL +20 | GOLD -60 |
| 돌아간다 | NONE | NONE |

**기획 의도**: 3선택지 이벤트. 리스크 큰 고보상 / 안전한 자원 교환 / 포기. 팀 상태에 따라 최적 선택이 갈림.

---

### 9. 동료 영웅의 합류

> 전장을 헤매던 한 영웅이 당신의 팀을 발견했다. 지친 눈빛이지만 의지는 꺾이지 않았다.

**선택지**:
| 레이블 | 효과 | 비용 |
|---|---|---|
| 함께 싸우자 | ADD_HERO | NONE |
| 아직은 아니야 | NONE | NONE |

**기획 의도**: 표준 영웅 영입 이벤트. 팀 영웅 3명이면 `_get_random_event()`에서 이 이벤트 필터링됨 (기존 구현).

---

### 10. 저승의 거래

> 어둠 속에서 흰 도포를 입은 자가 나타난다. "내가 가진 것 중 하나를 드리겠소. 단, 당신의 것 중 하나도 나에게 주어야 하오."

**선택지**:
| 레이블 | 효과 | 비용 |
|---|---|---|
| 거래한다 | ADD_RELIC_GAMBLE | NONE |
| 거절한다 | NONE | NONE |

**기획 의도**: 저주 렐릭 가능성이 있는 위험한 렐릭 도박. 이미 저주 렐릭을 보유했거나 일반 렐릭 풀이 좋을 때 매력적. 이벤트 풀에 위험 요소로 포함.

---

## 구현 메모

- **EffectType 이슈**: "구미호의 유혹" REMOVE_CARD + ADD_RELIC 동시 효과는 단일 EventChoice로 처리 불가 시 `effect_type = REMOVE_CARD`, `bonus_effect = ADD_RELIC` 방식 혹은 두 선택지 분리.
- **랜덤 결과 이벤트** ("산신령과의 내기"): 코인 플립 결과가 필요. EventChoice에 `gamble_good_effect` / `gamble_bad_effect` 필드 추가 or 기존 ADD_RELIC_GAMBLE 로직 응용.
- **디버프 정화** ("무당의 굿"): 현재 미구현. HEAL만으로 대체.
- **`events_korean.gd` 함수명 제안**:
  - `_death_reaper_visit()`, `_dokkaebi_hammer()`, `_gumiho_temptation()`, `_shaman_gut()`, `_samsin_blessing()`, `_dangun_prophecy()`, `_mountain_god_bet()`, `_sea_king_test()`, `_hero_joins()`, `_underworld_deal()`
