# 씬 진입·캐릭터 아트 CPU 최적화 — 2026-10-11

## 범위와 구현

PR #236 머지 결과 `1710ca63a05583ce9f4effbcde42017387eaf68a`에서 `perf/scene-stutters`를 만들었다. 같은 pearlfish worktree와 로컬 미추적 에셋·위키 변경을 보존했다. 이번 작업은 미커밋이며 원격 변경은 없다. 옛 로컬 `work/pearlfish`는 보존한다.

- `CharacterArtCache`: 영웅·적·보스 페이즈 일러스트를 최대 24개 FIFO로 유지한다. 살아 있는 캐릭터가 없어도 반복 진입 시 PNG를 재로딩하지 않는다. 노드·ShaderMaterial은 공유하지 않으며 기존 크기/크롭/플래시를 유지한다. 개수 제한이지 바이트 제한은 아니며, 텍스처를 보관하는 만큼 메모리 사용은 늘어난다. 종료 때 캐시를 비운다.
- `SceneTransition`: 모든 autoload가 준비된 뒤 전투 PackedScene 하나를 동기로 미리 읽고 보관한다. 전투는 `change_scene_to_packed`, 나머지는 기존 파일 전환이다. 사전 로드 실패 시 기존 파일 방식으로 돌아간다. **약 0.5초의 첫 로드 비용을 시작 화면으로 옮긴 것이지 없앤 것이 아니다.** 새 스레드는 사용하지 않는다.
- 하트 파티클: 4,096개 픽셀의 GDScript polygon 검사를 native `Geometry2D` 검사로 바꿨다. 마스크와 최종 픽셀 바이트의 기존 결과 일치를 검사한다.
- `STSL_PROFILE_CPU=1`: 씬 교체·배경·UI·영웅·적·전투 ready 동기 구간을 `[stsl_cpu]` JSON으로 출력한다. 기본 실행에서는 출력하지 않는다. 비동기 전투 intro 전체 길이나 GPU 완료 시간을 측정하지 않는다.

## 방법과 관측

Godot 4.7.2 Mono, Apple M2, Metal/mobile, 1920×1080. 모든 실행은 `--audio-driver Dummy`와 별도 `STSL-campaign-bot-*` 저장 폴더를 사용했다. 실제 사용자 볼륨·저장 데이터는 변경하지 않았다.

| 동기 CPU 구간 | 변경 전 | 변경 후 |
| --- | ---: | ---: |
| Cleopatra 생성·add_child·ready, 5회 p50 | 85.336ms | 0.749ms |
| 같은 scarab 아트, 첫 회 제외 4회 p50 | 21.305ms | 0.036ms |
| 하트 텍스처 cold 생성, 5회 p50 | 14.103ms | 7.300ms |

새 아트의 첫 로드 비용은 남는다. scarab 첫 로드는 22.818→23.581ms로 개선되지 않았다. 서로 다른 5개 적 그림 p50도 21.347→21.725ms였다. 셰이더 생성만 있는 적 ready는 원래 0.322ms였으므로, 근거 없이 셰이더 공용화를 추가하지 않았다.

원본은 `log/campaign-bot/STSL-campaign-bot-f0MyjG/`의 `character-before.json`, `character-after.json`, `vfx-before.json`, `vfx-after.json`이다. 초기 벤치의 종료 커서 캐시 정리 누락으로 RID 오류가 있었으며, 최종 벤치에는 정리를 추가하고 종료 오류가 없음을 확인했다. CPU 구간 측정 자체와 종료 검증을 구별한다. 환경·부하가 완전히 같지 않은 작은 표본이므로 다른 텍스처의 미세한 변동을 개선으로 해석하지 않는다.

캠페인 계측 기준은 Cleopatra·seed42·정상 1배속·45초 제한이다. 변경 전 `f0MyjG` 첫 전투의 파일 교체는 499.199ms, ready는 148.920ms였다. 다음 전투 ready는 263.508ms(액터 222.944ms)였다. 이 수치는 기존 정상 화면 29분 완주 FPS와 별개인 동기 메서드 비용이다.

중간 변경 후 `meJ9Vb`에서는 첫 교체 3.755ms, 시작 화면 warm 473.879ms를 관측했다. 해당 런 후반에 별도 테스트 프로세스가 잠깐 겹쳤으므로 반복 전투 성능의 정본으로 사용하지 않고 단독 실행을 다시 했다.

최종 단독 실행 `VBqULF`는 의도한 45초 제한으로 종료1·`stall`이며 엔진 오류/경고는 없었다. 첫 전투 교체 4.720ms, startup warm 466.246ms, 첫 ready 146.518ms였다. 처음 보는 일러스트 비용이 남아 첫 ready는 사실상 동일하다. 두 번째 전투 ready는 159.268ms(영웅1.547ms·적135.645ms·배경11.268ms)로 기준263.508ms보다 짧았다. 다만 적 구성·아트 첫 로드·부하가 동일하다는 보장이 없어 단일 표본 감소를 일반 개선율로 쓰지 않는다. 반복 영웅 아트 비용 제거는 별도 벤치로 확인했다. 다른 씬 첫 교체(event84ms/card_pick66ms)도 여전히 남는다.

## 재현과 검사

```sh
STSL_PROFILE_CPU=1 bash tools/run_campaign_bot.sh --chapter=1 --hero=cleopatra --seed=42 --speed=1 --max-seconds=45
```

45초 제한 결과 `stall`/종료1은 완주나 실패 버그가 아니라 의도한 측정 종료다. 벤치 스크립트 `tools/profile_character_setup.gd`, `tools/profile_vfx_textures.gd`는 렌더링·Dummy 오디오·격리 user 폴더를 요구한다. 실행기가 생성한 임시 프로젝트 경로에서만 실행한다.

- `tests/test_gpu_particle_helpers.gd`: 마스크 4,096개 좌표·최종 이미지 동일성 2검사 통과.
- `tests/run_character_art_cache.gd`: 캐시 동일성·24개 한도/FIFO·없는 경로·영웅/적 sprite fit·인스턴스 재질 독립성 17검사 통과. autoload 준비 후 실행해야 하므로 일반 동기 테스트 러너와 별도다.
- `tests/test_scene_transition_recovery.gd`: startup cache·Resource 재사용·성공 전환·없는 파일 입력 복구 PASS. 별도 `STSL-transition-test-*` 저장 폴더 필요. 없는 파일의 의도한 오류 3개 외 추가 오류·종료 경고 없음.
- 최종 `tests/test_runner.gd`: **1,886 passed / 0 failed**, 엔진 오류·경고 없음. 기존 suite는 일부 RNG 기반으로 실행별 검사 수가 달라진다. `git diff --check`, 실행기 `bash -n`도 통과했다.

## 남은 한계

이번 수치는 전체 FPS 개선율이나 모든 전투 끊김 해소의 증명이 아니다. 처음 등장하는 PNG·배경·다른 씬 로드, GPU 파티클·렌더링 비용은 남는다. Metal profiler의 0ms는 여전히 유효한 GPU 타이밍이 아니다. 기존 [정상 화면 완주 성능 보고서](performance-profile-2026-10-11.md)의 결과는 덮어쓰지 않으며, 변경 후 전체 focused 정상 배속 완주는 별도 후속이다.

## 선택적 다음 전투 준비 — 사용자 승인 후속

`SceneTransition.go(BATTLE_PATH)`에서 fade-out 완료 후 선택된 팀 최대3명의 실제 씬 root 이름, 확정된 `pending_enemies` ID로 필요한 그림 경로만 만든다. 선택된 보스의 phase_thresholds에 해당하는 페이즈 그림도 존재할 때만 준비한다. 없는 파일·fallback-only 적·중복 경로를 제외한다. 다른 적/영웅·챕터 전체를 미리 읽지 않는다. 배경의 무작위 오브젝트 선택은 전투 씬에서 여전히 진행하며 이번 준비 대상으로 옮기지 않았다.

캐시에 없는 그림은 검은 전환 화면의 작은 진행 막대를 표시하고 한 프레임당 한 장씩 동기 로드한다. 이미 캐시된 그림은 즉시 건너뛴다. 스레드를 추가하지 않고, 캐시24개/종료 해제를 유지한다. **첫 로드 시간은 그대로 필요하고 전환이 그만큼 길어진다.** 개별 그림 로드가 걸리는 동안 진행 막대도 일시 정지할 수 있다. 전투 화면 ready 구간에서 부담을 떼어낸 것이며 총 로드 비용 제거·완전 비동기 로딩이라고 부르지 않는다.

무음 격리 정상1배속45초 `lgAJWG`: 첫 준비는 hero Cleopatra와 scarab 두 경로뿐(중복 scarab은 하나), 153.282ms였다. 씬 교체3.712ms, ready33.984ms(영웅0.747ms·적5.742ms). 이전 `VBqULF` 첫 ready146.518ms에서 그림 로드를 분리한 효과를 확인했다. 후속 전투 ready38.626ms/27.000ms, 새 sand_rat 한 장 준비48.391ms. 의도한45초 cap·`stall`·종료1이며 엔진 오류/경고 없음. 적/환경 RNG·OS 부하 차이 때문에 전체 FPS 개선율로 환산하지 않는다.

OS 화면 캡처로 해당 테스트 창이 실제 화면에 있고 전투를 그리는 것을 확인했다(`/tmp/orca-computer-use`가 아니라 macOS 임시 폴더의 `d340f208-0583-4b68-9db1-ae831165057c-screenshot.png`). 첫 ready의 CPU 구간값은 포커스 기반 전체 FPS와 별도다.

검사: `tests/run_character_art_cache.gd` **29통과/실패0**(선택/중복/없는 파일/fallback/보스phase/첫 준비/warm skip/진행 막대 정리 포함), 전체 `test_runner.gd` 최종 **1896통과/실패0**, 전환복구 PASS(의도한 없는 파일 오류3개), `git diff --check` 통과. 개인 저장·음량은 변경하지 않았다.

## GPU/VFX 조사: 확인과 미확인 구별

**GPU 병목은 아직 확인되지 않았다.** 위의 GPU 비용이 남는다는 표현은 원인 확정이 아니라 조사 미완료를 뜻한다. 이번에도 root viewport의 render-time 계측을 활성화했지만 GPU API 값이 전부0으로 나왔다. GPU 부하0/정상이라는 증거가 아니며 `unavailable/zero`로 표시한다. Metal Instruments 도구인 `xctrace`도 현재 설치 환경에서 찾을 수 없었다. 설치·렌더러 변경은 하지 않았다.

새 `tools/profile_battle_vfx.gd`는 실제 FireBlastGPU를 고정 위치·고정 particle seed로 반복한다. helper 텍스처 준비→첫 이펙트 관찰2.25초→A/B/B/A 각3초(A=이펙트 없음, B=0/0.5/1/1.5초에4개 생성). CPU process/viewport CPU/frame setup, GPU, draw/object, 파이프라인 생성 변화와 프레임 간격을 기록한다. 게임 전체 전투가 아닌 **분리된 화염 이펙트 실험**이며 다른 이펙트·배경·혼합 연출을 대표하지 않는다. TIME_PROCESS도 순수 CPU 점유 시간과 동일시하지 않는다.

유효 정본 `log/campaign-bot/STSL-campaign-bot-lgAJWG/vfx-abba-final.json`, 종료0·엔진 오류/경고 없음:

| 구간 | focused 표본 | 프레임 p50 / p95 / 최대(ms) |
| --- | ---: | ---: |
| A1 | 181 | 16.684 / 17.276 / 27.413 |
| B1 | 181 | 16.683 / 18.352 / 21.548 |
| B2 | 181 | 16.646 / 17.460 / 18.005 |
| A2 | 181 | 16.660 / 17.312 / 19.484 |

모든 phase focus 표본 비율100%. B의 draw call 중앙값29/최대40(A는3), object 중앙값34(A는8)로 실제 렌더링 작업이 추가됨을 확인했다. 첫 이펙트는136표본·p95 17.401ms·최대28.514ms, 파이프라인 생성4회, node+play 호출0.119ms였다. helper 텍스처가 이미 준비된 상태이며 지연 생성되는 emitter 비용은0.119ms에 포함되지 않는다. **이 조건에서 수백 ms 정지를 재현하지 못했다**는 결론만 낸다. GPU 원인 부재·모든 전투 최적화 완료라고 결론내리지 않는다.

첫 `vfx-abba.json`은 B표본이0으로 포커스 불충분하여 제외했다. 중간 `vfx-abba-focused.json`도 보존한다. 마지막 도구에 raw frame_samples/95% focus coverage 조건을 추가한 `vfx-abba-raw.json` 실행은 phase 일부가 포커스를 잃어 전체 invalid·종료1로 정상 차단됐으며 ABBA 결론에 사용하지 않는다. 그 실행의 partial 표본을 유효 정본에 합치지 않는다. 현재 도구는 raw 프레임·pipeline 누적값도 남겨 이후 사건별 상관관계 조사에 쓸 수 있다. 실패한 측정을 성공으로 숨기지 않는다.

성능 테스트 창의 실제 OS 위치/표시를 캡처로 확인했으며, 진단 도구가 측정 중 자신의 창을 앞으로 가져오는 동작은 테스트에만 있다. 1920×1080 논리 viewport·960×540 실제 window이며 새 캡처는 macOS 임시 `aa02c5fb-53ad-478a-8dc1-1b2b128478aa-screenshot.png`이다. headless 실행은 명시적으로 거절하는 guard도 재검증했다.

다음 원인 조사는 끊기는 **정확한 카드·적·배경 조합**을 재현해 이 raw 계측과 연결하거나, 유효한 GPU 계측 환경에서 진행한다. 이번 변경으로 파티클 수/그림 품질/전투 규칙은 낮추지 않았다. 코드·문서·위키는 로컬 미커밋이며 원격 변경 없음.
