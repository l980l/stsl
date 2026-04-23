# 폰트 파일 배치 안내

이 디렉토리에 아래 폰트 파일 3종을 직접 배치하세요. 모두 SIL Open Font License (OFL) 라이선스입니다.

## 필요 파일

| 파일명 | 용도 | 다운로드 |
|---|---|---|
| `NotoSans-Regular.ttf` | 라틴·그리스어·스페인어·프랑스어·이탈리아어 기본 폰트 | https://fonts.google.com/specimen/Noto+Sans |
| `NotoSansCJK-Regular.ttc` | 한국어·일본어·중국어 전체 포함 | https://github.com/notofonts/noto-cjk/releases |
| `NotoSansArabic-Regular.ttf` | 아랍어 | https://github.com/notofonts/arabic/releases |

## 설치 후

1. Godot 에디터에서 `resources/theme/global_theme.tres` 열기
2. `default_font` → `NotoSans-Regular.ttf` 연결
3. 해당 FontFile의 `fallbacks` 배열에 `NotoSansCJK-Regular.ttc`, `NotoSansArabic-Regular.ttf` 순서로 추가
4. 프로젝트 재임포트

## 폰트 누락 시

Godot 기본 폰트로 자동 폴백됩니다. 라틴 문자는 정상 표시되고 CJK/아랍 글리프는 박스로 표시되지만 기능은 정상 동작합니다.
