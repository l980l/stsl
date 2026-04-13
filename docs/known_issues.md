# Known Issues & 기술 부채

Plan 01 완료 시점 기준. 미래 플랜 작업 시 참고하세요.

---

## [Plan 01] RelicResource 타입 우회

**파일:** `resources/relic_resource.gd:10-11`

`base_effect`, `bonus_effect` 필드가 `EffectResource`가 아닌 `Resource`로 선언됨.

- **원인:** 헤드리스 테스트 환경에서 preload 체인 로딩 순서 문제로 타입을 scope에서 찾지 못하는 컴파일 에러 발생
- **영향:** 잘못된 타입을 할당해도 런타임 에러 없음
- **해결 방향:** 릴릭 효과 처리 코드에서 `is EffectResource` 체크를 명시적으로 추가할 것

---

## [Plan 01] 적 공격 방향

**파일:** `characters/character_placeholder.gd:38`

attack 애니메이션이 `Vector2(60, 0)` — 항상 오른쪽 돌진.

- **원인:** 영웅/적이 공통 스크립트 사용. 방향 구분 없음
- **영향:** 전투 씬 구현 시 적 캐릭터가 반대 방향으로 튀는 것처럼 보임
- **해결 방향:** `@export var attack_direction: int = 1` 추가 후 적은 `-1` 사용. 단, Blender 스프라이트 교체 시 스크립트 자체를 제거하므로 우선순위 낮음

---

## [Plan 02] TargetType.ALL 단일 대상만 공격 (battle_manager.gd:244)

`_pick_hero_target()`에서 `TargetType.ALL`이 `living[0]`만 반환함.

- **원인:** `_pick_hero_target`이 단일 hero_id를 반환하는 설계라 ALL 타입과 맞지 않음
- **영향:** ALL 의도를 가진 적(히드라 보스 등)이 첫 번째 영웅만 공격함
- **해결 방향:** `_execute_intent()` 내 ATTACK 처리 시 `intent.target == TargetType.ALL`이면 `get_living_heroes()`를 루프로 전체 타격하는 별도 분기 추가

---

## [Plan 02] hero_damaged 시그널 — 블록 완전 흡수 시 amount=0 발화 (battle_manager.gd:153)

블록이 피해를 전부 흡수한 경우에도 `hero_damaged.emit(hero_id, 0)` 발화됨.

- **원인:** `_deal_damage_to_hero()`에서 amount 감소 후 조건 없이 emit
- **영향:** UI에서 0 피해 이펙트가 표시될 수 있음. `enemy_damaged`는 동일 패턴이므로 두 곳 모두 수정 필요
- **해결 방향:** `if amount > 0` 조건 추가 후 emit

---

## [Plan 01] TeamManager/DeckManager ObjectDB 경고

**파일:** `tests/test_team_manager.gd`, `tests/test_deck_manager.gd`

테스트 종료 시 `ObjectDB instances leaked` 경고 출력.

- **원인:** `Node`를 상속하지만 SceneTree 없이 인스턴싱
- **영향:** 기능 동작에는 문제없음. 경고만 출력
- **해결 방향:** 테스트 러너 개선 시 `add_child()`로 트리에 추가하거나, 테스트 전용 인스턴스는 `Node` 상속 없이 처리
