# 데미지 모디파이어 버킷 재설계 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:subagent-driven-development. Steps use checkbox (`- [ ]`) syntax.

**Goal:** 데미지 모디파이어를 합/곱 버킷으로 재구성해 수치 폭증을 막고, 실제 데미지와 미리보기를 같은 파이프라인으로 통일하고, 툴팁만으로 합·곱을 알 수 있게 한다.

**Architecture:** `battle_manager.gd` 5곳에 흩어진 실제 데미지 계산 + 3개 미리보기 함수를 단일 `compute_damage()` 파이프라인으로 통합한다. 공격자 증폭(weak·strength·황제의 무도)을 하나의 합산 풀(out_pct)로 묶어 곱 연쇄를 끊는다.

**개정 이력:** Phase 1(리팩터)·Phase 2(재배정)는 분리 불가로 판명 — 파이프라인에 태우는 것이 곧 버킷 재배정이므로 **Phase A로 병합**. 미리보기 함수 통일도 범위에 포함. 표기는 Phase B 후속.

---

## 설계 결정 (확정)

### 새 데미지 공식 (`compute_damage`, Task A.1에서 구현 완료)

```
if invuln: 0
dealt = max(0, floor( (base + flat) × (1 + out_pct) × crit_mult × dnd_mult × (1 + in_pct) × Π mitigation ))
```
block 차감은 호출부 책임.

### 2단계 적용 (함수 시그니처 보존)

`_deal_damage_to_enemy`/`_deal_damage_to_hero`는 호출처가 많아 시그니처를 바꾸지 않는다. 대신 2단계:
1. **공격자 측** (`_apply_card_effects` / `_resolve_enemy_intent`): `base·flat·out_pct·crit_mult` 채워 `compute_damage` → `outgoing` 정수. 이걸 기존처럼 `_deal_damage_to_*`에 전달.
2. **받는 측** (`_deal_damage_to_enemy` / `_deal_damage_to_hero`): 전달받은 `outgoing`을 `ctx.base`로, `in_pct·mitigation·dnd_mult·invuln` 채워 `compute_damage` → `final`. 이후 block 차감.

→ `floor()`가 2회 (공격자/받는측). 기존 6회 대비 대폭 감소. ±1~2 절삭 오차는 허용.

### 버킷 배정

| 모디파이어 | 버킷 | 값 |
|-----------|------|-----|
| strength (영웅·적 통일) | flat (합) | `+strength` |
| counter_pool (적) | flat (합) | `+counter_pool` |
| weak | out_pct (합) | `−0.25` |
| 황제의 무도 (취약 적) | out_pct (합) | `+0.25` |
| FORM_SWITCH offense 모드 | out_pct (합) | `+0.5` |
| 치명타 | crit_mult (곱) | `2.0` |
| 초원의 결투사 | crit_mult (곱) | `3.0` |
| double_next_damage | dnd_mult (곱) | `2.0` |
| vulnerable | in_pct (합) | `+0.5` |
| FORM_SWITCH defense 모드 | mitigation (곱) | `0.5` |
| dynamic_resistance | mitigation (곱) | `0.2` |
| counter_pending | mitigation (곱) | `0.5` |
| invuln | invuln=true | 0 |
| block | 차감 (호출부) | `−min(block,dmg)` |
| marked_by | crit **확률** | 데미지 버킷 아님 |

### 밸런스 영향 (플레이테스트로 후속 조정)

- 적 strength: `×(1+0.1·str)` → flat `+str`. 적 strength 수치 재튜닝 필요.
- weak·황제가 곱→합산 풀로 이동 → 수치 변화. 계수는 구조 완성 후 플레이테스트로 조정.

---

## File Structure

- **수정** `autoload/battle_manager.gd` — `compute_damage`(완료)를 실제 데미지 5함수 + 미리보기 3함수가 호출.
- **수정** `tests/test_card_effects_engine.gd` · `test_battle_manager.gd` · `test_enemy_mechanics.gd` — 데미지 기대값 재계산.
- (Phase B) `resources/effect_resource.gd`, `resources/translations/strings_*.csv`, `scenes/battle/battle_scene.gd`.

---

## Phase A — 파이프라인 통합 + 버킷 재배정

### Task A.1 — DamageContext + compute_damage ✅ 완료 (커밋 dce10fc)

### Task A.2: 영웅 카드 공격 전환

**Files:** 수정 `autoload/battle_manager.gd` `_apply_card_effects` DAMAGE 분기 (L1041~1102)

- [ ] DAMAGE 분기에서 hit 루프마다 `DamageContext` 생성: `base=effect.value`, `flat=power.strength_player`, `out_pct = (weak?−0.25:0)+(황제의무도?+0.25:0)`, `crit_mult = _roll_crit_damage 결과(2.0/3.0) 또는 1.0`. `compute_damage(ctx)` → `outgoing`. 기존처럼 `_deal_damage_to_enemy(idx, outgoing, ...)` 호출.
- [ ] `_roll_crit_damage`는 crit 발동 여부·crit_mult만 반환하도록 정리 (데미지 곱은 compute_damage가 담당).
- [ ] `bonus_per_hit`·`every_nth_attack_bonus`는 기존대로 별도 데미지 인스턴스 유지 (합 효과).
- [ ] `tests/test_card_effects_engine.gd` 데미지 기대값을 새 공식으로 재계산·갱신.
- [ ] 테스트 러너 `0 failed` 확인. 커밋.

### Task A.3: 적 공격 전환

**Files:** 수정 `autoload/battle_manager.gd` `_resolve_enemy_intent` ATTACK 분기 (L2180~2218)

- [ ] `DamageContext`: `base=intent.value`, `flat = enemy strength + counter_pool`, `out_pct = (weak?−0.25:0)+(offense모드?+0.5:0)`, `crit_mult`. `compute_damage` → `outgoing`. `_deal_damage_to_hero(hid, outgoing, ...)` 호출.
- [ ] 적 strength를 flat로 통일 (`×(1+0.1·str)` 제거).
- [ ] `tests/test_enemy_mechanics.gd`·`test_enemy_patterns_v2.gd` 기대값 갱신. 커밋.

### Task A.4: 받는 쪽 모디파이어 전환

**Files:** 수정 `autoload/battle_manager.gd` `_deal_damage_to_enemy`(L1692~), `_deal_damage_to_hero`(L1742~)

- [ ] 각 함수 진입부에서 `DamageContext`: `base=전달받은 amount`, `in_pct=(vulnerable?+0.5:0)`, `mitigation` 배열(방어모드 0.5·dynamic_resistance 0.2·counter_pending 0.5 중 해당), `dnd_mult=(double_next?2.0:1.0)`, `invuln`. `compute_damage` → `final`. 이후 기존 block 차감 로직.
- [ ] 전체 테스트 러너 `0 failed`. 커밋.

### Task A.5: 미리보기 함수 통일

**Files:** 수정 `autoload/battle_manager.gd` `estimate_effect_damage`(L298~), `_estimate_card_damage`(L315~), `get_intent_display_damage`(L274~)

- [ ] 세 미리보기 함수가 실제 계산과 동일한 버킷 로직으로 `compute_damage`를 쓰도록 전환 → 미리보기 = 실제값 보장.
- [ ] 미리보기 관련 테스트가 있으면 기대값 갱신. 커밋.

---

## Phase B — 툴팁·텍스트 표기 (후속)

### Task B.1: display_text 곱연산 표기
- [ ] 곱연산 효과를 `최종 ×N` 형식으로, 합연산은 `+N%`. `effect_resource.gd` `display_text()` + 번역 키 14언어.

### Task B.2: 상태이상 툴팁 합·곱 명시
- [ ] vulnerable·weak 등 desc에 버킷 명시 (`strings_status.csv`).

### Task B.3: 곱연산 효과 강조 색
- [ ] `최종 ×` 표기 효과를 다른 색으로 렌더 (`battle_scene.gd`).

---

## 테스트 전략

- Phase A는 의도적 수치 변경 — 바뀐 공식대로 기대값 재계산. 각 Task 후 `godot --headless -s tests/test_runner.gd` → `0 failed`.
- Phase A 완료 후 F6 인게임 육안 검증 (수치 폭증 완화 체감).

## 비-목표

- 정확한 밸런스 계수 튜닝 — 구조 완성 후 별도 플레이테스트.
- 적 strength 데이터 재조정 — flat 전환 후 별도 작업.
