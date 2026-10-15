# 카드 개편 v3 적용·검증 기록

2026-10-08. 사용자 “적용해” 승인에 따른 첫 실험안 구현.

## 적용 범위

- 6명 시작덱: 각 10장, 기본 공격 2·방어 2·고유 카드 5·카운터 1.
- 제안서의 핵심 보상 36개 항목, 시작덱 관련 카드와 기본 공격/방어의 명시적 1강.
- 카운터: 비용 2, 방어 40/80, 유지·소모. 차지 취소 또는 반사 준비.
- 방어·병사·사기·매혹·희생량의 지정 소비/상한, 본인 차례당 환급·드로우 제한, 유한한 비용 예약, 첫 타격 보너스, 천사의 날개 3회 후속 회복.
- 드로우·에너지·손패의 소유자, 일반 힘, 적 약화 만료 순서, 독 피해/사망 시그니처, 공유 인텐트 배율, 정예 55종의 등급 수정.
- 두 카드 디자인의 설명·실효 비용, 명상 선택/건너뛰기, 혈전의 적→아군 선택, 기존 도감 재생성.

카드 등록 ID·희귀도와 보상 풀 189개를 유지한다. 기존 피해 100·HP 1000·ATB·유물·시너지를 유지하며 몬스터 HP를 일괄 조정하지 않았다. 수정한 카드의 수치 표는 [개편안](cards_composition_proposal_v3.md)과 [생성된 카드 도감](../catalog/cards.md)에서 확인한다.

## 저장 호환

덱 직렬화 v4. 알려진 카드는 `owner_id|card_name`으로 최신 정의를 복원하고, 저장된 강화 수준을 실제 GameManager 강화 규칙으로 다시 적용한다. 목록의 장수·순서·소유자는 그대로 유지한다. 따라서 이전 11장 런을 자동으로 10장 덱으로 바꾸지 않으며, 새 런부터 새 시작덱을 사용한다. 알 수 없는 카드도 삭제하지 않고 직렬화된 효과와 속성을 복원한다. 카운터의 유지/소모, 파워 타입, 다단 타격 등이 로드 시 사라지던 문제도 방지한다.

## 평가 프로필과 검증 계약

루프: 영웅별 ATB 차례에서 에너지를 쓰고 고유 자원을 준비·소비하는 덱 전투.

| 가설 / 결정 | 고정 입력·측정 단위 | 통과 기준 / 후속 행동 |
|---|---|---|
| 제안이 실제 실행 규칙에 적용됨 | 버전 관리된 `test_card_revision_acceptance.gd`의 카드 ID·0/1강·HP1000/적HP5000·기본 차례 입력. 검사 하나당 결정적 참/거짓 | 선언값과 실제 피해·잔량·소유자·강화가 일치. 실패하면 수치 조정 전에 규칙 수정 |
| 재시전·다수 적·다른 영웅에서 자원 중복이 없음 | 1/2/3인 배치, 일반/조건 실패, 소비 상한, echo, 차례당 제한 | 소비는 한 번에 정산, 제한은 해당 영웅 차례 전체에서 공유 |
| 새 입력을 실제 화면에서 수행 가능 | classic/modern, 실제 battle_scene, 명상 선택/skip·할인 비용·아군 선택 | 선택·취소·비용 표시와 카드 사용 상태가 일치 |
| 튜토리얼을 계속 완료 가능 | 기존 세 레슨·두 카드 디자인·중도 종료/패배·저장 보호 | 기존 통합 시나리오 통과 |

이 검사는 확률 전투의 승률 표본이 아니다. 확률 치명타를 끄고 명시한 상태를 비교하며, 성공한 assertion 수를 독립 플레이 횟수나 재미 점수로 해석하지 않는다. 입력 정본은 테스트 스크립트에 있으며, UI 검사는 실제 노드를 사용한다. 시드가 결과를 바꾸지 않는 결정적 시나리오는 별도 표본으로 늘려 세지 않는다.

### 실행 환경과 결과

Godot 4.7.2 mono, macOS headless. 원본 사용자 저장과 분리된 `/tmp/STSL-tutorial-validation-v3-0NE0US` 프로젝트와 전용 user 디렉터리.

- 선행 오류 재현: 수정 전 8개 중 7개 실패 → 수정 후 8개 모두 통과.
- 전체 테스트: **1877 통과 / 0 실패**. 카드 개편 및 정예/강화 회귀 검사를 전체 runner에 포함했다.
- 카드 개편 전용 검사: **290 통과 / 0 실패**. 전체 검사와 중복되는 회귀 검사를 별도로 재실행한 결과다.
- 실제 튜토리얼 씬 통합: **321 통과 / 0 실패**.
- 새 카드 입력 UI: **16 통과 / 0 실패**.
- 위 실행 로그에 스크립트 오류·객체/리소스 누수 경고 없음. `git diff --check` 통과.
- 에디터 import는 완료됐으나 기존 미추적 BurstParticles2D 에셋 폴더의 중첩 `project.godot`을 무시한다는 경고 1건이 있다. 게임 실행 오류와 구별한다.

실행 로그는 `/tmp/stsl-v3-{full,tutorial,ui,revision}-tests.log`. 재검증은 [튜토리얼 검증 문서](../tutorial-validation.md)의 격리 프로젝트 구성 후 다음을 실행한다. 같은 user 디렉터리를 쓰는 저장 테스트는 순차 실행한다.

```sh
godot --headless --path /격리/프로젝트 -s res://tests/test_runner.gd
godot --headless --path /격리/프로젝트 -s res://tests/run_card_revision.gd
godot --headless --path /격리/프로젝트 -s res://tests/test_card_revision_ui.gd
godot --headless --path /격리/프로젝트 -s res://tests/test_tutorial_integration.gd
godot --headless --path /격리/프로젝트 -s res://tools/generate_catalog.gd -- --cards-only
```

### 소스 지문

기준 커밋 `afe1bee`, 구현 변경이 있는 작업 트리에서 검사. SHA-256 집계 `f52f724a084aec2da6968a73f1a4d544b72ac7610530d4b12cad35c78af3d69a`.

집계 입력과 방법:

```sh
shasum -a 256 autoload/battle_manager.gd autoload/deck_manager.gd autoload/game_manager.gd resources/card_resource.gd resources/effect_resource.gd resources/cards/card_revision_v3.gd resources/cards/cards_*.gd resources/enemies/*/*_act*.gd resources/translations/strings_card.csv resources/translations/strings_ui.csv scenes/battle/battle_scene.gd scenes/card/card_scene.gd scenes/card/card_scene_v2.gd | shasum -a 256
```

## 남은 밸런스 판단

2026-10-12 후속: 사용자 요청으로 성능 측정을 중단하고 기존 카드 기능 보완을 진행했다. 무효 강화 10개·독력/결투 실행·실제 수치를 반영하는 설명은 [카드 콘텐츠 완성도 정리](card_content_completion.md)에 기록한다. 아래 부분 개편·실전 검증 한계는 2026-10-08 당시의 기록이며, 이번 수정도 전체 카드의 최종 밸런스 완성을 의미하지 않는다.

제안서 밖 카드의 1강은 기존 규칙을 유지하는 부분 개편이다. 189개 전체의 명시 강화 전환이나 모든 무효 강화의 해결 완료를 뜻하지 않는다. 새 효과 설명은 한국어·영어를 작성했으며 다른 11개 언어의 새 설명은 영어로 제공한다.

다음 수치 판단은 동일한 수정 몬스터에 대해 현행 11장 대조군·10장 압축 대조군·새 시작덱을 비교하고, 솔로/2인/3인과 보스 차지 대응을 따로 본다. 실제 전투 길이·승률·카운터 봉쇄·무한 회복·사용감은 이번 결정적 검사의 측정 대상이 아니며 직접 플레이 비교가 필요하다. 관찰이 없으므로 임의의 추가 상향/하향은 수행하지 않았다.
