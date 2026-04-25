# Sacred UI — 버튼 스타일 가이드

CSS 원본(`ui_kits/sacred/sacred.css` `.sbtn` 계열) 기반.  
Godot 구현: `autoload/sacred_theme.gd` → `animate_button()` / `attach_outer_glow()`.

---

## 사용 패턴

```gdscript
# 1. 버튼 생성 및 씬에 추가
var btn := Button.new()
btn.theme_type_variation = "PrimaryButton"   # 타입 지정
btn.size = Vector2(300, 60)
add_child(btn)

# 2. animate_button 호출 (항상 add_child 이후)
SacredTheme.animate_button(btn)
# → theme_type_variation을 읽어 장식선·후광·텍스트 자동 분기
```

> **주의**: `animate_button`은 반드시 `add_child` 이후에 호출 (`btn.size`가 확정돼야 glow 크기 계산 가능).

---

## PrimaryButton

CSS: `.sbtn--primary`  
사용처: 메인메뉴 New Game / Continue 등 주요 액션.

| 속성 | 기본 | 호버 |
|---|---|---|
| 배경 | INK_900 + 보라 틴트 | 동일 |
| 테두리 | BRASS_500 | BRASS_400 |
| 텍스트 | BRASS_300 (금색) | BONE_100 (흰색) |
| 외부 후광 | opacity 0.1 (희미하게 상시) | opacity 0.3 |
| 장식선 | BRASS_700 그라디언트 | BRASS_400 (밝아짐) |

```gdscript
btn.theme_type_variation = "PrimaryButton"
SacredTheme.animate_button(btn)
# → 내부: attach_outer_glow(btn, 24.0, 0.1, 0.3) 자동 호출
```

---

## Button (Standard)

CSS: `.sbtn`  
사용처: 일반 UI 버튼.

| 속성 | 기본 | 호버 |
|---|---|---|
| 배경 | INK_1000 | 동일 |
| 테두리 | BRASS_700 | BRASS_500 |
| 텍스트 | BONE_100 (흰색) | BRASS_300 (금색) |
| 외부 후광 | 없음 | opacity 0.2 |
| 장식선 | BRASS_700 그라디언트 | BRASS_400 (밝아짐) |

```gdscript
# theme_type_variation 설정 없음 (기본 "Button")
SacredTheme.animate_button(btn)
```

---

## VowButton

CSS: `.sbtn--vow`  
사용처: 뒤로가기, 취소 등 부차적 액션 (ghost 스타일).

| 속성 | 기본 | 호버 |
|---|---|---|
| 배경 | 투명 | 투명 |
| 테두리 | LINE_2 | BONE_400 |
| 텍스트 | FG_2 | FG_2 (약간 밝아짐) |
| 외부 후광 | 없음 | 없음 |
| 장식선 | BRASS_700 그라디언트 | BRASS_400 (밝아짐) |

CSS 스펙: `.sbtn--vow:hover { box-shadow: none }` → 후광 미적용.

```gdscript
btn.theme_type_variation = "VowButton"
SacredTheme.animate_button(btn)
```

---

## ChapterButton (챕터 카드)

CSS: `.chapter:hover { box-shadow: 0 0 40px rgba(212,169,72,0.2) }`  
사용처: 챕터 선택 화면의 카드 버튼 (600×560).

PrimaryButton과 동일한 후광 수치. 단, 카드는 `_hover_card()`로 Y 트윈·halo를 별도 처리하므로 `animate_button` 대신 `attach_outer_glow`만 수동 호출.

```gdscript
card.theme_type_variation = "ChapterButton"
card.clip_contents = false   # 카드 외곽 glow가 잘리지 않도록
add_child(card)
SacredTheme.attach_outer_glow(card, 20.0, 0.1, 0.3)
```

---

## 공통 구현 원칙

### StyleBox shadow 없음
Godot `StyleBoxFlat.shadow_size`(내장 drop-shadow)와 `attach_outer_glow` 셰이더가 겹치면 두 겹 후광이 생긴다.  
→ 모든 버튼 StyleBox에서 shadow 제거, 후광은 `attach_outer_glow` 단일 처리.

### attach_outer_glow 시그니처
```gdscript
SacredTheme.attach_outer_glow(
    btn: Button,
    pad: float = 24.0,           # 버튼 외곽 glow 확장 크기 (px)
    default_opacity: float = 0.0, # 비호버 시 glow 강도
    hover_opacity: float = 1.0    # 호버 시 glow 강도
)
```

셰이더: 버튼 직사각형 SDF — 버튼 내부는 alpha 0, 외곽 `pad`px 구간만 BRASS_400 색상으로 페이드.  
`show_behind_parent = true`로 버튼 StyleBox 뒤에서 렌더링.
