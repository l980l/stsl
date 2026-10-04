# Local asset setup

STSL의 코드, 씬, 리소스 정의, 경량 SVG UI 아이콘은 Git으로 관리한다. 용량이 큰 원본
아트와 오디오는 Git LFS를 사용하지 않으며, Google Drive를 정본 및 백업 위치로 사용한다.

## Git에서 제외되는 로컬 자산

- `assets/audio/`
- `assets/art/cards/`
- `assets/art/chapters/`
- `assets/art/characters/`
- `assets/art/enemies/`
- `assets/art/events/`
- `assets/art/heroes/`
- `assets/art/scenes/`
- `assets/art/backgrounds/` 중 `objects/`, `critters/`, `particles/` 이외의 파일

추적되는 SVG UI·배경 요소(예: `assets/art/ui/intent/`, `assets/art/ui/map/`,
`assets/art/backgrounds/objects/`)는 새 파일을 만들면 일반 Git 커밋에 포함한다.

## 새 컴퓨터에서 복원

1. GitHub에서 저장소를 클론한다.
2. Google Drive의 STSL 자산 백업에서 위 폴더들을 저장소 루트에 같은 경로로 복사한다.
3. Godot에서 프로젝트를 열어 임포트가 완료될 때까지 기다린다. `.godot/`과 `*.import`는
   로컬에서 자동 생성되므로 복사하거나 커밋하지 않는다.
4. 게임을 실행해 카드·영웅·적 이미지와 BGM/SFX가 정상적으로 로드되는지 확인한다.

## 작업 규칙

- 코드·`.tscn`·`.tres`·`.gd`·`.uid`·필수 SVG·문서는 Git 브랜치에 커밋한다.
- 신규 대형 아트/오디오는 Drive의 동일 경로에도 즉시 백업한다.
- 자산 파일 경로나 이름을 바꿀 때는 해당 변경을 설명하는 문서 또는 커밋 메시지를 남긴다.
- `export_presets.cfg`는 배포 설정 재현을 위해 Git으로 관리한다. 인증서·서명 키 같은
  비밀 파일은 저장소 밖에 보관하고 경로만 로컬에서 설정한다.
