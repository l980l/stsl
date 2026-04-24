# autoload/label_utils.gd
# NOTE: autoload 등록하지 않음 — static 유틸 (MapGenerator 와 동일 패턴)
class_name LabelUtils
extends RefCounted

# Control 의 폰트를 영역에 맞게 자동 축소.
# - Label + autowrap 있음 → 세로 초과 시 축소 (줄바꿈 발생, width 고정)
# - Label autowrap 없음 / Button / 기타 Control → 가로 초과 시 축소 (1줄 유지)
# target_w: 앵커 기반 버튼처럼 레이아웃이 텍스트 폭으로 이미 늘어난 경우,
#            원래 의도한 너비를 직접 전달해 비교 기준으로 삼음.
static func fit_text(control: Control, max_px: int, min_px: int, target_w: float = -1.0) -> void:
	if not control.is_inside_tree():
		return
	var tree := control.get_tree()
	var fs := max_px
	control.add_theme_font_size_override("font_size", fs)
	await tree.process_frame

	var is_wrap_label := control is Label and (control as Label).autowrap_mode != TextServer.AUTOWRAP_OFF
	if is_wrap_label:
		var lbl := control as Label
		while lbl.get_line_count() * lbl.get_line_height() > lbl.size.y and fs > min_px:
			fs -= 1
			lbl.add_theme_font_size_override("font_size", fs)
			await tree.process_frame
	else:
		var check_w: float = target_w if target_w > 0.0 else control.size.x
		while control.get_minimum_size().x > check_w and fs > min_px:
			fs -= 1
			control.add_theme_font_size_override("font_size", fs)
			await tree.process_frame
