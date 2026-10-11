# 정상 렌더링 캠페인 성능 측정 — 2026-10-11

## 결과

클레오파트라·시드 42·정상 1배속으로 챕터 1→2를 실제 클리어했다. 90개 방, 전투 23+22회, 1,773.8초(29분 34초), 실행기 종료 코드 0이다. 지속적으로 낮은 FPS보다는 화면 전환과 전투 중 간헐적인 긴 프레임이 문제다. 이번 작업은 계측이며 게임 최적화는 아직 적용하지 않았다.

| 구간 | 프레임 수 | p50(ms) | p95(ms) | p99(ms) | 최대(ms) | >50ms |
|---|---:|---:|---:|---:|---:|---:|
| 전체 | 104,273 | 16.678 | 17.737 | 27.445 | 603.566 | 500 |
| 포커스된 전투 씬 | 98,250 | 16.678 | 17.731 | 24.784 | 402.554 | 276 |
| 포커스된 씬 경계 | 473 | 44.959 | 362.073 | 547.822 | 603.566 | 220 |
| 포커스된 맵 | 2,657 | 16.680 | 17.516 | 17.941 | 42.614 | 0 |
| 포커스된 카드 보상 | 1,279 | 16.663 | 17.465 | 17.772 | 32.719 | 0 |

전체 >33.333ms는 820회(0.786%), >50ms는 500회(0.480%). 전투와 씬 경계가 >50ms의 496/500회를 차지한다. 전투 구간은 같은 씬 파일 경로의 표본이며 초기화·연출을 제외한 순수 정상 상태를 뜻하지 않는다. 씬 경계는 파일 경로가 달라진 프레임 간격이지 전환 전체 소요 시간은 아니다.

## 측정 조건과 증거

- Godot 4.7.2 Mono, macOS, Apple M2, Metal Forward Mobile, 창/viewport 1920×1080. 마스터 0·Master mute·Dummy 오디오 드라이버. 실제 사용자 저장·음량은 건드리지 않았다.
- 긴 런 동안 다른 자동 테스트 엔진을 함께 실행하지 않았다. 프로파일러 옵션은 사용하지 않았다. 봇 판단·계측 오버헤드, VSync, OS 스케줄링은 포함한다.
- 창 표시·포커스를 기록하고 OS 화면 캡처로 초기 실제 표시를 확인했다. 창에 포커스를 다시 강제로 주는 반복 동작은 없다. 전체 중 mixed/unfocused 표본은 13개이고 모든 느린 표본은 focused였다. 지속적인 화면 비가림까지 보장하지는 않는다.
- [원본 보고서](../log/campaign-bot/STSL-campaign-bot-o7Zinb/report.json), [느린 프레임/행동](../log/campaign-bot/STSL-campaign-bot-o7Zinb/report.json.frames.jsonl), [엔진 로그](../log/campaign-bot/STSL-campaign-bot-o7Zinb/engine.log), [OS 화면 캡처](../log/campaign-bot/STSL-campaign-bot-o7Zinb/onscreen-early.png). 원본은 로컬 ignored 경로이므로 문서를 다른 컴퓨터에 옮기면 함께 복사해야 한다.
- 소스 HEAD `afe1bee`, dirty 210 entries, 런 지문 `7f797996d6e0172b209a5e82f4ec469f24c1bf12f9c07062ec51f8c9e4faed36`. 아트·음원·셰이더는 지문 범위 밖이다. 엔진/SCRIPT ERROR는 없지만 미제작 음원 경고가 남아 있다.

> 이전 `3dBzUZ`, `LvZ1n5`와 짧은 렌더링 스모크는 Metal 실행과 실제 OS 화면 표시를 혼동했다. 특히 `LvZ1n5`는 창 복원 전 화면에 표시되지 않았고 취소했다. 이들의 수치를 보이는 게임의 FPS 기준으로 사용하지 않는다. 이전 로그는 보존하며 이번 `o7Zinb`로 기준을 대체한다.

## 병목 후보와 확신 수준

1. **카드 UI 갱신 — 측정된 비용, 우선순위 높음.** `card_scene_v2.gd:327`의 `refresh()`는 스타일·그라디언트와 원형 이미지 텍스처를 다시 만든다. `battle_scene.gd:2022`는 손패 노드를 전부 제거하고 재생성한다. 정상 렌더링 별도 마이크로벤치(각 20회, 초기 갱신 후)에 실제 카드 5장 `refresh()`가 p50 **7.589ms**, p95 **9.857ms**, 최대 **11.604ms**였다. 60FPS 예산 16.7ms의 상당 부분이다. 원형 비용 텍스처 p50 0.882ms, 보석 1.401ms도 관측했다. 텍스트만 변경할 때 전체 갱신을 피하고 불변 장식 텍스처를 재사용하는 것이 첫 최적화 후보다. 실제 손패 재생성 총비용이나 403ms 끊김의 단독 원인이라고 확정하지 않는다.
2. **동기 씬 전환/초기화 — 관측과 코드가 일치, 세부 원인 미분리.** `SceneTransition.go()`는 `change_scene_to_file()`로 전환하며 전투 `_ready()`에서 배경·UI·캐릭터를 만든다. 최대 603.566ms는 챕터1·2막·11층의 `enter_node` 문맥에 있었다. 로드 캐시 여부·리소스 업로드·노드 생성·첫 렌더링 중 무엇이 지배적인지는 추가 단계별 타이밍이 필요하다. fade의 의도된 0.22/0.28초와 한 프레임 정지를 동일시하지 않는다.
3. **VFX 초기 생성/셰이더/GPU — 미확인.** 파티클·재질 생성 경로는 있으나 이번 프레임 기록만으로 GPU 병목을 확정할 수 없다. 최근 행동은 상관관계 단서이지 그 카드의 인과 증거가 아니다. `Performance.TIME_PROCESS` 역시 전체 긴 프레임을 CPU/GPU로 정확히 분해하지 않는다.

카드 마이크로벤치: [JSON](../log/campaign-bot/STSL-campaign-bot-o7Zinb/card-refresh-profile.json), [엔진 로그](../log/campaign-bot/STSL-campaign-bot-o7Zinb/card-refresh-engine.log). 메서드 호출의 wall time(제출 포함)이며 GPU 완료 시간은 아니다. 실제 전투 손패 모드가 아닌 REWARD 카드 5장으로 공통 `refresh()` 경로를 측정했다.

## GPU 진단의 한계

별도 45초 전투 런에 `--gpu-profile --profiling`을 붙였다. Metal 환경의 stdout은 `GPU PROFILE (total 0.0ms)`만 제공해 유효한 GPU 시간/단계별 결과를 얻지 못했다. **GPU 부하가 0이라는 뜻이 아니다.** `--profiling`에서도 독립 실행 stdout에 함수별 스크립트 시간 자료는 나오지 않았다. 이 런은 원래 완주 기준과 합산하지 않으며 GPU 병목 판단은 보류한다. 다음 단계는 에디터 profiler 연결 또는 Metal GPU 캡처와 씬 초기화 구간별 CPU 타이밍이다.

## 재현 및 다음 순서

검증: 프레임 프로브(분위수·분모·창 상태 분류)와 봇 정책 전용 검사 PASS, 카드 마이크로벤치 종료0·엔진 오류 없음, 실행기 `bash -n` 및 `git diff --check` 통과. GPU 진단은 의도된 45초 제한에 도달해 `stall`/종료1이며 완주 성공으로 세지 않는다. [GPU 로그](../log/campaign-bot/STSL-campaign-bot-o7Zinb/gpu-engine.log)와 [보고서](../log/campaign-bot/STSL-campaign-bot-o7Zinb/gpu-report.json)를 보존했다. 전체 회귀 묶음은 이번 계측 변경 후 다시 실행하지 않았다.

```sh
bash tools/run_campaign_bot.sh --chapter=both --hero=cleopatra --seed=42 --speed=1 --max-seconds=3600
```

실행기가 출력한 새 격리 프로젝트 경로로 다음 검사를 단독 실행한다.

```sh
/Applications/Godot_mono.app/Contents/MacOS/Godot --audio-driver Dummy --path /tmp/STSL-campaign-bot-실행이름 -s res://tools/profile_card_refresh.gd -- --report=/절대경로/card-refresh.json
```

첫 수정 후보는 카드 불변 장식 캐싱·중복 갱신 감소, 두 번째는 씬 초기화 단계별 분리 계측이다. 수정 전후 동일 조건으로 짧은 재현과 완주를 비교하고 시드·전역 RNG·다른 앱 부하 차이를 기록한다. 튜토리얼과 다른 영웅/시드·전 분기까지 이 런으로 검증한 것은 아니다.

## 후속 최적화 — 2026-10-11

사용자가 측정된 문제 해결을 요청한 뒤 다음을 적용했다. 위의 원래 측정은 수정 전 기록이며 보존한다.

- 카드 `refresh()`를 동적 텍스트와 장식 갱신으로 분리했다. 팔레트·희귀도가 같으면 스타일/그라디언트를 재생성하지 않는다. 비용 원형·보석은 고정 팔레트/희귀도 조합별로 재사용한다(최대6+30개). 입력·카드 수치·아트·색상은 변경하지 않았다. 테스트 종료에서 캐시를 명시적으로 해제한다.
- 손패의 순서와 Resource 참조가 같으면 기존 노드를 재사용한다. 재사용 때도 `setup`과 활성화/튜토리얼 게이팅을 갱신해 비용 감소와 상태 변경을 반영한다. 카드 교체·순서 변경·적 턴은 기존 재생성/제거 경로를 유지한다.
- 씬 전환의 실패 반환값을 확인해 오류 상태·실패 신호를 기록하고 기존 씬의 입력을 복구한다. threaded prefetch도 실험했지만 기존 동기 방식 대조 검사에 없는 종료 객체 잔존 경고가 발생했고 끊김 감소도 아직 측정하지 못해 **철회했다**. 씬 초기화·GPU 업로드의 수백 ms 끊김은 별도 미해결 항목이다.

동일 카드 마이크로벤치(정상 렌더링, 각20회, warm refresh)에서 5장 갱신 **p50 7.589→0.158ms(97.9% 감소)**, **p95 9.857→0.792ms**, 최대11.604→0.825ms였다. 원형 생성 자체는 p50 0.882→0.880ms로 비슷해, 생성 함수를 가속한 것이 아니라 반복 생성을 제거한 효과다. [수정 후 JSON](../log/campaign-bot/STSL-campaign-bot-o7Zinb/card-refresh-after.json)과 [로그](../log/campaign-bot/STSL-campaign-bot-o7Zinb/card-refresh-after.log)를 보존한다. OS 전체 부하를 통제한 반복 실험이나 전체 전투 FPS 개선율은 아니다.

회귀 검사: 최종 `test_runner.gd` 출력은 **1,899 passed, 0 failed**였다(앞선 실행은1,890·1,880 passed, 모두 실패0). 카드/손패 전용42개 통과(픽셀 동일성, 6영웅×5희귀도, 텍스트 변경, 인스턴스 공유, 같은 손패/비용 감소/순서 변경/적 턴 제거, classic↔modern 변경 시 강제 교체). 카드 검사 로그의 엔진 오류·경고 없음. 수정 후 30분 정상 화면 전체 재프로파일은 아직 하지 않았으며 403/604ms 최악값의 해소 여부는 미확인이다.

씬 전환 복구 전용 검사도 통과했다. 없는 파일을 요청해 `last_transition_error`·실패 신호·기존 씬 유지·입력 복구를 확인하며, 이 경로의 파일 없음 오류와 명시적 실패 로그는 의도된 진단이다. 최종 동기 방식 검사에 ObjectDB 종료 경고는 없었다. [최종 전체 검사](../log/campaign-bot/STSL-campaign-bot-o7Zinb/full-regression-after.log), [카드/손패 검사](../log/campaign-bot/STSL-campaign-bot-o7Zinb/card-regression-after.log), [전환 복구 검사](../log/campaign-bot/STSL-campaign-bot-o7Zinb/transition-recovery.log).

추가 진행 검사도 성공만 남기지 않았다. `a9xz4j` 가속 headless 런은 챕터1·1막12층 패배(67.65초, 종료1)로 완주 검증이 아니다. `BAWcwP` 정상 렌더링 검사는 75초 제한 종료(종료1), 5방·2전투 진행을 확인했다. [화면 캡처](../log/campaign-bot/STSL-campaign-bot-BAWcwP/onscreen-after.png)로 OS 표시를 확인했으나 대부분 unfocused여서 기존 focused 완주와 FPS를 비교하지 않는다. 두 런 모두 엔진/SCRIPT ERROR는 없고 조기 종료 시 ObjectDB 잔존 경고11개가 있었다. 종료 잔존 경고의 인과는 미분리이며 숨기지 않는다. 다른 앱을 사용하는 사용자의 포커스를 반복해서 빼앗지 않았다.
