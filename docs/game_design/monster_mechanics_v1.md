# 몬스터 메커니즘 레이어 v1 — 디자인 스펙

> 작성일: 2026-05-08
> 대상: M6.5-2 (production_roadmap.md)
> 선행 작업: 인카운터 v2 (PR #95) — 6 신화 × 20 몬스터 × 10 인카운터, 중복 0
> 진행 브랜치: `monster-refactor` (Phase 1~4 통합 후 단일 PR)

---

## 1. 배경 / 목표

**현재 한계** — 인카운터 v2로 구조는 정리됐지만, 패턴이 ATTACK/BUFF/DEBUFF/PREPARE 시퀀스 반복이라 단조로움. 흥미로운 적은 거의 모두 *조건*(HP·죽음·받은 데미지)과 *적간 상호작용*을 가진다.

**목표**
- 모든 일반 몬스터에 1개 이상의 시그니처 메커니즘 부여 (쉬운 인카운터 #1~3 제외)
- 신화별 정체성 강화 — 자동 적용되는 옅은 신화 시그니처
- 인카운터 #8~10에 시너지 테마 부여 — 단순 합 이상의 구조
- 기존 인프라 최대 재사용 (`phase_thresholds`, `card_count_trigger`)

**비목표**
- 엘리트·보스 패턴 변경 (이번 작업 범위 외)
- 카드 시스템 변경
- UI/비주얼 작업 (Phase 4 후 Milestone 7에서 폴리싱)

---

## 2. 디자인 합의 (브레인스토밍 결과)

| 항목 | 결정 |
|---|---|
| 코드 추가 스코프 | 티어 0~3 풀스펙 |
| 디자인 단위 | B + A 하이브리드 — 개별 시그니처 + 옅은 신화 시그니처 + 인카운터 #8~10 테마 |
| 템플릿 규모 | 60+ (신화당 ~10 고유) |
| 신화 시그니처 적용 | 모든 일반 몬스터 자동 |
| 구현 순서 | Phase 1 → 2 → 3 → 4 순차 |
| 브랜치 전략 | 단일 `monster-refactor` 브랜치, 통합 PR |

---

## 3. 난이도-복잡도 곡선

| 인카운터 | 적용 메커니즘 수 | 적용 티어 |
|---|---|---|
| #1~3 (매우 약함~약함) | 0개 — 순수 ATTACK/BUFF/DEBUFF | — |
| #4~5 (보통) | 1개 | 티어 0 (시퀀스 변형) |
| #6~7 (다소 강함) | 1개 | 티어 1 (HP 트리거) |
| #8~9 (강함) | 2개 — 개별 + 인카운터 테마 | 티어 2 (적간 상호작용) |
| #10 (매우 강함) | 2~3개 | 티어 3 (신규 액션) + 테마 |

신화 시그니처는 #4 이후 모든 몬스터에 자동 적용 (옅은 색깔).

---

## 4. 메커니즘 템플릿 라이브러리 — 4 티어

### 티어 0 — 시퀀스 변형 (기존 시스템)

신규 코드 0줄. `intent_pattern` 배열 구성만 다르게.

| ID | 이름 | 설명 |
|---|---|---|
| T0-RAMP | 램프 어태커 | 매 턴 BUFF strength+1 → ATTACK 시 누적 |
| T0-CHARGE | 차지-언리쉬 | PREPARE 2턴 → ATTACK 큰 한 방 |
| T0-DEBUFF | 디버프 누적자 | 매 턴 DEBUFF weak/vul +1 ALL |
| T0-ROULETTE | 무작위 의도 | 매 턴 4개 액션 풀 중 무작위 (의도 표시 후 고정) |

### 티어 1 — HP 트리거 (기존 phase_thresholds 활용)

`phase_thresholds`/`phase_patterns`/`phase_heal_ratios` 재사용. 신규 코드 최소.

| ID | 이름 | 설명 |
|---|---|---|
| T1-BERSERK | 광폭화 | HP 50% 미만 도달 시 phase 전환, 새 phase는 strength +5 시작 |
| T1-SPLIT | 분열 | HP 50% 미만 시 사망 → 미니 형태 2마리 spawn (신규 SUMMON 필요, 티어 3과 연계) |
| T1-PHASE | 변신 | HP 트리거에서 패턴 풀 완전 교체 (기존 phase_patterns) |
| T1-PHOENIX | 페닉스 | HP 0 도달 시 1회 50% HP로 부활 (`phase_heal_ratios=[0.5]` + 두 번째 phase 진입 후 사망 차단 플래그) |
| T1-DESPERATE | 디스트레스 | HP 30% 미만에서 모든 디버프 자동 제거 + 다음 턴 큰 한 방 |

### 티어 2 — 적간 상호작용 (신규 EnemyInteractionSystem)

| ID | 이름 | 설명 |
|---|---|---|
| T2-BUFFER | 버퍼 | 매 턴 자기 외 동료에게 BUFF strength +1 (자기 공격 안 함) |
| T2-HEALER | 힐러 | 매 턴 LOWEST_HP 동료 HP +20 회복 |
| T2-GUARD | 가드 | 다른 적 살아있는 동안 자기에게 +block 매 턴 (제거 우선순위 강제) |
| T2-DEATH-RATTLE | 데스 트리거 | 죽을 때 동료 strength +3 또는 ALL 폭발 데미지 |
| T2-COMBO-INSTIGATOR | 콤보 인스티게이터 | 같은 타겟을 동료가 공격하면 추가 데미지 (체인) |

### 티어 3 — 신규 액션 타입

5개 신규 IntentResource ActionType + 5개 신규 시스템 (§6 참조).

| ID | 이름 | 설명 | 신규 ActionType |
|---|---|---|---|
| T3-COUNTER | 카운터 | 받은 데미지의 30%를 다음 ATTACK에 가산 | COUNTER_PREPARE |
| T3-MARK | 헌터 마커 | 한 타겟 마킹 → 마킹 동안 +50% 데미지 | MARK_TARGET |
| T3-SACRIFICE | 자해 희생 | 자기 HP -20 → strength +5 | (기존 BUFF + 자해 처리) |
| T3-STANCE | 자세 전환 | 매 턴 공격형 ↔ 방어형 자세 교대, 자세별 패턴 풀 다름 | STANCE_SWITCH |
| T3-WARD | 무적 결계 | 매 N턴마다 1턴 무적 + ALL 약공격 | (status 효과 "invuln") |
| T3-MIMIC | 모방 | 이전 턴 플레이어 카드 데미지의 50% 반사 | (이전 플레이어 카드 추적 필요) |
| T3-SUMMON | 소환 | 미니언 1마리 spawn | SUMMON |
| T3-HEAL-ALLY | 적 힐 | T2-HEALER의 코드 백엔드 | HEAL_ALLY |
| T3-BUFF-ALLY | 적 버프 | T2-BUFFER의 코드 백엔드 | BUFF_ALLY |

---

## 5. 신화 시그니처 (모든 일반 몬스터 자동 적용)

코드에서 `enemy.mythology` 값에 따라 시그니처 효과 자동 등록. 각 시그니처는 1회성 또는 매 턴 미세 효과로 강도 조절.

| 신화 | 시그니처 | 발동 조건 | 효과 | 1회성 |
|---|---|---|---|---|
| greek | 휴브리스 | 한 턴 25+ 피해 받음 | 다음 턴 strength +2 | 아니오 (매번) |
| norse | 라그나로크 | HP 30% 미만 도달 | 모든 적 strength +1 | 예 (전투당 1회) |
| egyptian | 저주 누적 | 자기 ATTACK 발동 시 | 타겟에 vulnerable +1 자동 부여 | 아니오 |
| buddhist | 인과응보 | HP 0 도달 시 | ALL에 받은 누적 데미지 25% 반환 | 예 |
| daoist | 음양 자세 | 매 턴 시작 | 공격형/방어형 자세 자동 교대 (BUFF block ↔ BUFF strength) | 아니오 |
| japanese | 결계 | 매 5턴마다 | 자기에 block +20 자동 부여 | 아니오 |

**활성화 게이트**: 인카운터 #4 이상 몬스터에만 발동. `EnemyResource.signatures_enabled: bool` 플래그 신규 추가 — 인카운터 #1~3 풀에선 false, #4 이상 풀에선 true.

**구현 위치**: `autoload/enemy_signature_system.gd` (신규) — `mythology` 키 기반 시그니처 등록·발동, `signatures_enabled` 체크.

---

## 6. 코드 인프라 — 5개 신규 시스템

### 6.1 EnemyTriggerSystem (Phase 1)
- 등록: HP 트리거 (HP%) / 받음 트리거 (피해 양·횟수) / N턴 트리거 / 데스 트리거
- 인터페이스: `register_trigger(enemy_index, type, condition, effect_callable)` / `fire_trigger(enemy_index, event_name, ctx)`
- HP 트리거는 기존 `phase_thresholds`와 통합 — phase 전환 시점에 trigger 자동 실행

### 6.2 EnemyInteractionSystem (Phase 2)
- 적→적 효과: 버프, 힐, 데스 시너지
- 인터페이스: `buff_ally(source_idx, target_idx, status, value)` / `heal_ally(source_idx, target_idx, value)` / `on_enemy_death(idx) → emit`
- 타겟 선택 도우미: `pick_lowest_hp_ally(source_idx)` / `pick_random_ally(source_idx)`

### 6.3 EnemyMarkerSystem (Phase 3)
- 영웅에게 마커 부착 (헌터 시그니처용)
- 자세(stance) 상태 추적
- 인터페이스: `apply_marker(hero_id, source_idx, ttl)` / `has_marker(hero_id, source_idx)` / `set_stance(enemy_idx, stance)`

### 6.4 EnemyCounterSystem (Phase 3)
- 받은 누적 데미지 추적 → 다음 ATTACK에 가산
- 인터페이스: `arm_counter(enemy_idx, ratio)` / `consume_counter(enemy_idx) → int`
- BattleManager의 `_deal_damage_to_enemy`에 훅

### 6.5 EnemySignatureSystem (Phase 3)
- mythology 키 기반 시그니처 등록·자동 발동
- 인터페이스: `register_signatures()` (전투 시작 시 호출) / `on_enemy_event(idx, event, ctx)`

### IntentResource 신규 ActionType (Phase 2~3)
```gdscript
enum ActionType {
    ATTACK, BUFF, DEBUFF, SPECIAL, PREPARE,
    HEAL_ALLY,        # Phase 2
    BUFF_ALLY,        # Phase 2
    MARK_TARGET,      # Phase 3
    COUNTER_PREPARE,  # Phase 3
    STANCE_SWITCH,    # Phase 3
    SUMMON,           # Phase 3 (T1-SPLIT, T3-SUMMON 공용)
}
```

### `_execute_intent` 확장
`autoload/battle_manager.gd:1045` 에 새 case 추가. 각 case는 위 시스템 호출 위임.

### SPECIAL 일반화 (Phase 1 정리 작업)
현재 SPECIAL은 "카드 영구 제거" 하드코딩 (battle_manager.gd:1079). `intent.status_type` 필드로 변종 구분:
- `status_type = "remove_card"` → 기존 동작
- 신규 변종 추가 시 case 분기

---

## 7. 인카운터 #8~10 테마 시너지 (~6개)

각 신화 #8/#9/#10 = 3 슬롯 × 6 신화 = 18 슬롯. 6 테마 템플릿 × 3회 reflavor.

| 테마 ID | 이름 | 구성 요건 | 시너지 효과 |
|---|---|---|---|
| TH-TANK-HEAL-DPS | 탱-힐-딜 | T2-GUARD + T2-HEALER + 일반 딜러 | 힐러가 살아있으면 모두 +block |
| TH-COMBO-TRI | 콤보 트라이앵글 | 3 마리 동일 타겟 공격 가능 | 같은 타겟 3중 공격 → 추가 ALL 데미지 |
| TH-DEATH-CHAIN | 데스 체인 | T2-DEATH-RATTLE 2~3 마리 | 한 마리 죽을 때마다 나머지 strength +2 누적 |
| TH-SUMMON-BOSS | 서몬 보스 | 보스급 1 + T3-SUMMON | 매 3턴마다 미니언 추가 |
| TH-SPLIT-MERGE | 분열-재결합 | T1-SPLIT 1 + 일반 1 | 분열 후 일반과 재결합 시 strength 폭증 |
| TH-WARD-ROTATE | 무적 로테이션 | T3-WARD 2~3 마리 | 매 턴 한 마리만 무적 (로테이션) |

---

## 8. Phase 분할

각 phase 내부에서는 서브 commit으로 진행. Phase 끝 commit에서 테스트 통과 보장.

### Phase 1 — TriggerSystem + 티어 0~1
- 신규: `autoload/enemy_trigger_system.gd`
- SPECIAL 일반화 (`status_type` 분기)
- 티어 0/1 템플릿 적용: 그리스 신화 20 몬스터 풀스펙 (시그니처 제외)
- 검증: 그리스 인카운터 시뮬레이션 5종 + 트리거 발동 단위 테스트

### Phase 2 — EnemyInteractionSystem + 티어 2 + IntentRes 확장
- 신규: `autoload/enemy_interaction_system.gd`
- IntentRes ActionType 추가: HEAL_ALLY, BUFF_ALLY
- `_execute_intent` 확장
- 티어 2 적용: 북유럽·이집트 40 몬스터
- 검증: 적간 시너지 단위 테스트 4종

### Phase 3 — MarkerSystem + CounterSystem + SignatureSystem + 티어 3
- 신규: `autoload/enemy_marker_system.gd`, `enemy_counter_system.gd`, `enemy_signature_system.gd`
- IntentRes ActionType 추가: MARK_TARGET, COUNTER_PREPARE, STANCE_SWITCH, SUMMON
- 티어 3 템플릿 적용 + 6 신화 시그니처 자동 등록
- 챕터 2 신화 60 몬스터 풀스펙 작성 (불교·도교·일본) — Phase 1·2 완료된 챕터 1과 합산해 **120 몬스터 모두 시그니처+티어 0~3 적용 완료 상태**
- 검증: 시그니처 발동 6종 + 티어 3 액션 단위 테스트

### Phase 4 — 인카운터 #8~10 테마 시너지
- 6 테마 템플릿 구현 (대부분 기존 시스템 조합, 신규 코드 최소)
- 18 인카운터 슬롯(6 신화 × 3) 에 테마 reflavor 적용
- 검증: 테마별 인카운터 시뮬레이션 6종

### 추정 규모
| Phase | GDScript 추가 | 몬스터 명세 | 테스트 | 기간 |
|---|---|---|---|---|
| 1 | ~300줄 | 그리스 20 | 5 | 3일 |
| 2 | ~400줄 | 북유럽·이집트 40 | 4 | 5일 |
| 3 | ~500줄 | 불교·도교·일본 60 + 시그니처 6 | 8 | 7일 |
| 4 | ~200줄 | 18 테마 | 6 | 4일 |
| **합** | **~1400줄** | **120 몬스터** | **23** | **~3주** |

---

## 9. 검증 전략

**단위 테스트** (`tests/test_enemy_mechanics.gd` 신규)
- 각 시스템(Trigger/Interaction/Marker/Counter/Signature) 인터페이스
- 6 신화 시그니처 발동 조건·효과
- 티어 3 신규 ActionType 처리

**통합 테스트** (`tests/test_enemy_encounter_sim.gd` 신규)
- 인카운터 자동 시뮬레이션 (3턴 가상 전투)
- 예상 행동 시퀀스 검증

**수동 플레이 검증** (각 phase 후)
- 디버그 메뉴 → 챕터 1·2 진입
- 인카운터 #5/#7/#10 직접 플레이 → 패턴 다양성 체감

**balance_check** (영향 없음 예상 — 카드 전용)

---

## 10. 위험 / 롤백

| 위험 | 심각도 | 대응 |
|---|---|---|
| 신규 60 메커니즘이 너무 많아 일관성 깨짐 | 중 | Phase 1에서 그리스만 풀스펙 → 패턴 검증 후 다른 신화로 확산 |
| 시그니처 자동 적용이 디자인 의도와 충돌 (예: 1번 인카운터에도 휴브리스 발동) | 중 | mythology 시그니처는 인카운터 #4 이상에만 활성화 — `EnemyResource.signatures_enabled` 플래그 추가 |
| 적→적 효과로 의도 표시(intent display)가 모호 | 중 | 의도 텍스트 i18n 키에 "동료에게 +1 strength" 형식 명시 |
| 테마 시너지가 너무 강해 인카운터 #10 클리어 불가 | 낮 | Phase 4 후 수동 플레이 검증 — 필요 시 효과 강도 조정 |
| 3주 단일 PR 리뷰 부담 | 낮 | Phase 단위 commit 깔끔 유지 + 매 Phase 끝 main rebase |

---

## 11. 다음 작업

이 스펙 검토·승인 → Phase 1 작업 시작.

Phase 1 첫 단계:
1. `autoload/enemy_trigger_system.gd` 작성
2. SPECIAL 액션 일반화 (status_type 분기)
3. 그리스 신화 normals 20개 — 티어 0/1 템플릿 적용
4. 단위 테스트 5종
