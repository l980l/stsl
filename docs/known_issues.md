# Known Issues & 기술 부채

최종 수정: 2026-04-16 (Plan 17 기준)

---

## 미해결

### [Plan 01] RelicResource 타입 우회

**파일:** `resources/relic_resource.gd:10-11`

`base_effect`, `bonus_effect` 필드가 `EffectResource`가 아닌 `Resource`로 선언됨.

- **원인:** 헤드리스 테스트 환경에서 preload 체인 로딩 순서 문제로 타입을 scope에서 찾지 못하는 컴파일 에러 발생
- **영향:** 잘못된 타입을 할당해도 런타임 에러 없음
- **해결 방향:** 릴릭 효과 처리 코드에서 `is EffectResource` 체크를 명시적으로 추가할 것

---

### [Plan 01] 적 공격 방향

**파일:** `characters/character_placeholder.gd:38`

attack 애니메이션이 `Vector2(60, 0)` — 항상 오른쪽 돌진.

- **원인:** 영웅/적이 공통 스크립트 사용. 방향 구분 없음
- **영향:** 전투 씬에서 적 캐릭터가 반대 방향으로 튀는 것처럼 보임
- **우선순위:** 낮음 (Blender 스프라이트 교체 시 스크립트 자체 제거 예정)

---

### [Plan 01] TeamManager/DeckManager ObjectDB 경고

테스트 종료 시 `ObjectDB instances leaked` 경고 출력.

- **원인:** `Node`를 상속하지만 SceneTree 없이 인스턴싱
- **영향:** 기능 동작에는 문제없음. 경고만 출력
- **해결 방향:** 테스트 러너에서 `add_child()`로 트리에 추가하거나 테스트 전용 RefCounted 방식 전환

---

### [Plan 04] MapGenerator.generate() 반환 타입 타입 힌트 누락

**파일:** `autoload/map_generator.gd`

`static func generate() -> Array:` — `Array[MapNodeResource]`로 선언 불가.

- **원인:** GDScript 4 헤드리스 모드에서 `class_name` 기반 제네릭 배열 타입이 파싱 오류 발생
- **해결 방향:** Godot 헤드리스 파싱 이슈 해결 후 `-> Array[MapNodeResource]`로 복원

---

## 해결됨

| 이슈 | Plan | 내용 |
|---|---|---|
| `TargetType.ALL` 단일 대상만 공격 | Plan 05 | `_execute_intent()` 내 ALL 루프 처리 추가 |
| `hero_damaged` amount=0 발화 | Plan 02 | `if amount > 0` 조건 추가 |
| `enemy_damaged` amount=0 발화 | Plan 02 | `if amount > 0` 조건 추가 |
| 하르피아 SPECIAL 실효 없음 | Plan 13 | 손패 대신 전체 덱에서 영구 제거로 변경 |
| 카드픽 수량 항상 1장 | Plan 13 | `card_rewards_pick_count` 도입, 엘리트/보스 2장 |
| `test_relic_resource_defaults` 크래시 | Plan 14 | `owner_id` → `owner_hero_id` 수정 |
| RestScene 정적 노드 중복 UI | Plan 15 | `rest_scene.tscn` 정적 노드 제거 |
| 사망 영웅 카드 효과 적용 | Plan 17 | `_apply_card_effects()` 사망 체크 추가 |
| 강화 카드 저장/복원 누락 | Plan 17 | `deck_manager.to_dict/from_dict`에 `upgraded` 추가 |
| 이벤트 씬 private 메서드 직접 호출 | Plan 17 | `recruit_random_hero()`, `complete_event()` 공개화 |
