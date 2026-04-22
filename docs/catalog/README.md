# 콘텐츠 도감 (기획자용)

`tools/generate_catalog.gd`로 자동 생성되는 카드/적/렐릭/이벤트 전체 목록.

## 재생성 방법

프로젝트 루트에서:

```bash
"H:/Program Files/Godot/Godot_v4.6.2-stable_win64_console.exe" --headless -s tools/generate_catalog.gd
```

## 수정 금지

이 폴더의 `.md`/`.csv` 파일은 자동 생성됩니다. 직접 수정하지 마세요.
내용을 바꾸려면 원본(`resources/cards/`, `resources/enemies/`, `resources/events/`, `resources/relics/`)을 수정한 뒤 재생성하세요.

## 파일 구성

- `cards.md` / `cards.csv` — 영웅별 카드 (나폴레옹/클레오파트라/이순신/잔다르크/칭기즈칸/무사시), 강화 0/1/2강
- `enemies.md` / `enemies.csv` — 신화별 적 (그리스/북유럽/이집트/한국/중국/일본, 일반/엘리트/보스), 인텐트 전수
- `relics.md` / `relics.csv` — 공용 렐릭 풀, 저주 penalty 포함
- `events.md` / `events.csv` — Act별 이벤트, 선택지 전수
