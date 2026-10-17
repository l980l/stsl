# 영웅 방어도 수명 — 2026-10-16

사용자 승인에 따라 전투 중 영구 잔여 방어를 대체한다. 과거 v3 제안서의 '현행 유지'와 시너지 개편 당시 전투 결과는 변경 전 기록이다. 적의 방어도 규칙과 카드 수치 자체는 바꾸지 않는다.

## 규칙

- 영웅 자신의 턴 시작/종료, 다른 영웅의 피격, 적의 준비/강화/디버프만으로는 소멸하지 않는다.
- 해당 영웅이 적의 공격을 받으면 피해만큼 방어를 소비하고, 그 **공격 행동 전체**가 끝날 때 기존 방어의 잔여분을 제거한다. 완전 방어·피해0인 공격도 포함한다.
- CHARGE_UP의 중첩 payoff는 하나의 행동이다. 모든 타격이 기존 방어를 공유하고 마지막 효과 후 잔여분을 제거한다. double_action의 다음 intent는 별개 행동이다.
- 광역은 실제 공격받은 각 영웅에게 적용한다. 피해를 내는 MIMIC도 포함한다. 독/출혈/희생 HP 비용/적 반사 등 일반 피해 경로는 새 소멸 계기가 아니다.
- 피격 유물/권능/시그널 반응으로 새로 얻은 방어는 보존한다. 기존 방어부터 피해에 소비하며, 새 방어도 같은 행동의 후속 타격에서 소비될 수 있다. 공격 종료 시점에 남은 새 방어는 다음 공격을 위해 유지한다.
- 영웅 방어 UI는 소멸 시 즉시 갱신한다. 방어 수치의 툴팁과 기본 튜토리얼의 13언어 안내를 새 규칙으로 바꾼다.

예: 기존10으로 피해3×2를 막으면 HP 손실0·방어0이다. 첫 타격 반응으로 새4를 얻었다면 같은 연타 후 방어4를 유지한다. 기존2로 피해3×2를 맞고 첫 타격 후 새4를 얻으면 HP 손실1·방어1이다.

## 검증 계약

규칙 단위 검사는 실제 BattleManager/IntentResource를 사용하고, 적 치명타·서명 효과·VFX 대기를 제거한 고정 fixture로 경계별 최종 HP/방어/갱신 시그널을 확인한다. 합격 조건은 명시된 기대 상태와 일치하는 것이다. 자동 검사는 재미나 최종 밸런스를 증명하지 않는다.

재현(모두 Dummy 오디오·격리 user://):

```sh
bash tools/run_live_balance_checks.sh run_block_lifetime run_archetype_synergy run_small_number_live test_tutorial_integration
bash tools/run_live_balance_checks.sh run_archetype_playtest
STSL_LEGACY_COMBAT=1 bash tools/run_live_balance_checks.sh test_runner
```

전투 표본은 [시너지 개편](archetype_synergy_revision.md)의 동일 18패키지×2전투×2시드, 같은 손패순 정책/입력96회 제한을 재사용한다. 개편 전 저장된 `STSL-tutorial-validation-live-2KSc61/archetype_playtest.json`의 작은 정수 candidate와 새 실행 candidate를 동일 구성으로 대조한다. 단위는 72개 고정 구성의 paired 전투이며, 결과/영웅 입력 수/합계 잔여 HP 차이만 해석한다. 정책은 방어 소멸에 적응하지 않은 기존 봇이며 유물/손상된 캠페인/사람 플레이는 미측정이다. 전투 결과가 악화되어도 임의 상향하지 않고 해당 구성·피격 양상을 후속 대상으로 기록한다.

## 실제 실행 결과

- `jmpD9u`: 전용46검사 통과·실패0. 단일/광역/피해0/완전방어, 중첩연타, 반응 방어의 기존 풀/부족한 풀, 실제 double_action, 자기 차례/자해/독, UI 갱신 시그널, 13언어 번역 로딩과 ko/en 신규 문구를 검증했다. `block_lifetime_checks.json`에 개별 결과/소스 지문/commit+dirty를 저장했다. 개발 중 불리언 closure의 일회성 반응 fixture 오류는 참조형 플래그로 수정했으며 실패 실행을 최종 결과에 포함하지 않는다.
- `eZzoDZ`: 시너지485·작은정수1672·튜토리얼312 통과, 실패0. 기존/작은정수72쌍144전투 모두승리·입력제한/미완료0·paired 궤적 고유72. 두 단위 간 HP 차이는 최대44.2로 커졌으며, 단위 동등성이나 최종 밸런스 합격으로 해석하지 않는다.
- `jX7RyS`: 기존 단위 전체 회귀4155 통과·실패0.
- `uLxQP7`: 번역 재임포트 후 카드 표시 검사52403·실제 튜토리얼312 통과·실패0. 새 방어 툴팁의 실제 hover/13언어 전체 화면 가독성은 별도 미측정이다.
- 위 게임 테스트 로그의 SCRIPT ERROR/ERROR/WARNING0. 에디터 재임포트는 기존 미추적 BurstParticles2D 내 중첩 프로젝트 무시 경고1건과 구별한다. 두 CSV 모두14열·키 중복 없음.

### 같은 작은 정수 조건의 변경 전후 대조

이전 `2KSc61`과 현재 `eZzoDZ`의 `archetype_playtest.json`에서 candidate만 segment/encounter/seed로 대응했다. fixture 문자열은 같고, 기록된 실제 소비 소스 지문 중 바뀐 것은 `battle_manager.gd`뿐이다. 두 JSON은 각각 `/Users/kimkwanhyeon/Library/Application Support/STSL-tutorial-validation-live-<접두사>/`에 있다. 로그는 `log/live-balance/STSL-tutorial-validation-live-<접두사>/`다.

- 72/72 대응, 승리72→72·승패변화0. 영웅 입력69개 동일·3개는1회 증가·빨라진 구성0.
- 팀 잔여 HP(최대300) 차이 평균−11.56, 범위−66~0. 최대 손실은 잔다르크 `holy_bolt,orleans_charge` / Sekhmet / 시드202에서271→205였다. 방어 약화의 실제 영향이므로 '기존 밸런스 유지'로 보고하지 않는다.
- 입력 증가3개는 나폴레옹 `line_reform,charge_bugle`, 이순신 `consecutive_defense,charge_stance`, 잔다르크 `holy_touch,communion`의 Sekhmet/시드202다. 카드 수치는 임의 보정하지 않았다.

후속은 방어 관련 카드의 사람 플레이·저HP/유물 포함 캠페인 검증이다. 고정 손패순 봇은 방어를 공격 직전에 배치하거나 이전/소비를 의도적으로 선택하는 숙련 정책이 아니며, 이 표본으로 모든 덱이 균형 잡혔다고 결론내리지 않는다.
