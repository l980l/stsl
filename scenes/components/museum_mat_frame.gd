# scenes/components/museum_mat_frame.gd
# Museum Mat 프레임 — ui_sample/ui_kits/portraits 의 .pf--square (Square · Museum mat) 디자인.
# 구성: 매트 밴드(16px) + 외곽 브라스 1px 테두리 + 안쪽 art 영역 테두리 + 4코너 L자 마크 + 외곽 후광.
# 사용처: 배틀씬 영웅·몬스터 스프라이트 영역 둘레.
class_name MuseumMatFrame
extends Control

const MAT_INSET    := 4    # 매트 밴드 두께 (외곽~안쪽 art 영역 사이)
const BORDER_THICK := 1
const GLOW_BANDS   := 3    # 외곽 후광 밴드 수

# 색상 — 인스턴스화 후 외부에서 덮어쓰기 가능
var frame_color: Color = Color("#b8962e")               # SacredPalette.BRASS_500
var mat_color: Color = Color(0.07, 0.05, 0.13, 1.0)     # 어두운 남색 매트 (불투명)
var inner_border_color: Color = Color(0, 0, 0, 0.55)
var glow_color: Color = Color(0.83, 0.66, 0.28, 0.20)   # 브라스 톤 후광

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw() -> void:
	var w := size.x
	var h := size.y
	if w <= 0 or h <= 0:
		return

	# 1) 외곽 브라스 후광 — 알파 감쇠 윤곽선 밴드
	for i in range(GLOW_BANDS):
		var off: float = float(i + 1) * 2.0
		var alpha: float = glow_color.a * pow(0.55, float(i))
		var c := Color(glow_color.r, glow_color.g, glow_color.b, alpha)
		draw_rect(Rect2(-off, -off, w + off * 2.0, h + off * 2.0), c, false, 1.0)

	# 2) 매트 밴드 — 4개 띠 (안쪽 art 영역은 비워둠 → 스프라이트가 보임)
	draw_rect(Rect2(0, 0, w, MAT_INSET), mat_color, true)                                       # top
	draw_rect(Rect2(0, h - MAT_INSET, w, MAT_INSET), mat_color, true)                           # bottom
	draw_rect(Rect2(0, MAT_INSET, MAT_INSET, h - MAT_INSET * 2), mat_color, true)               # left
	draw_rect(Rect2(w - MAT_INSET, MAT_INSET, MAT_INSET, h - MAT_INSET * 2), mat_color, true)   # right

	# 3) 외곽 브라스 1px 테두리
	draw_rect(Rect2(0, 0, w, h), frame_color, false, BORDER_THICK)

	# 4) 안쪽 art 영역 테두리 (어두운 헤어라인)
	draw_rect(Rect2(MAT_INSET, MAT_INSET, w - MAT_INSET * 2, h - MAT_INSET * 2),
		inner_border_color, false, BORDER_THICK)
