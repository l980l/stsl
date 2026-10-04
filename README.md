# STSL

Godot 4.6으로 제작한 **덱빌딩 + 팀빌딩 로그라이크 카드 게임**입니다. 영웅 조합, 카드, 유물, 상태이상과 시너지를 조합해 챕터를 돌파하는 플레이를 목표로 합니다.

## Tech Stack

- Godot 4.6 / GDScript / Jolt Physics
- Autoload 기반 상태 관리와 Resource 기반 게임 데이터
- GPU 파티클, CSV 기반 다국어 처리, 테스트·디버그 도구

## Gameplay Systems

- 카드·유물·이벤트·영웅·적·상태이상·시너지 기반의 전투 시스템
- 팀 편성, 덱 구성, 맵·상점·챕터 진행, 영웅 해금, 튜토리얼과 도감
- 저장·설정·오디오·장면 전환을 분리한 Autoload 아키텍처
- 카드와 전투, UI·튜토리얼을 포함한 다국어 콘텐츠 관리

## Architecture

| Area | Main Autoload |
| --- | --- |
| 게임 진행 | `GameManager`, `ProgressManager`, `SaveManager` |
| 전투·조합 | `BattleManager`, `DeckManager`, `TeamManager` |
| 사용자 경험 | `SceneTransition`, `AudioManager`, `UISound`, `LocaleManager` |
| 개발 지원 | `DebugManager`, `GameSettings`, `IconUtils` |

## AI-assisted Production

AI를 결과물의 검증 가능한 제작 공정에 연결했습니다.

- **Claude Code**: Godot 프로젝트의 기능 구현과 반복적인 개발 작업에 활용했습니다.
- **ACE-Step 1.5**: 오픈 모델을 로컬 환경에서 실행해 게임 BGM을 생성했습니다.
- **Nano Banana**: 프로젝트 내 이미지 에셋 제작에 활용했습니다.

AI 산출물은 게임 내 적용 후 동작, 표현, 밸런스를 직접 확인하며 수정했습니다.

## Run

1. Godot **4.6**에서 이 저장소를 Import합니다.
2. `project.godot`을 열고 실행합니다.

기본 진입 씬은 `scenes/main_menu/main_menu_scene.tscn`입니다.

## Project Structure

| Path | Description |
| --- | --- |
| `autoload` | 전역 게임 상태 및 매니저 |
| `characters`, `resources`, `scenes`, `src` | 게임 데이터, 게임플레이, UI |
| `assets` | 아트, 폰트, 셰이더, 파티클 |
| `docs` | GDD, 밸런스, 콘텐츠 설계, 제작 로드맵 |
| `tests`, `tools` | 검증과 콘텐츠 제작 지원 도구 |
