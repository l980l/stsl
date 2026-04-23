# autoload/label_utils.gd
# NOTE: autoload 등록하지 않음 — static 유틸 (MapGenerator 와 동일 패턴)
class_name LabelUtils
extends RefCounted

# Control 의 폰트를 영역에 맞게 자동 축소.
# - Label + autowrap 있음 → 세로 초과 시 축소 (줄바꿈 발생, width 고정)
# - Label autowrap 없음 / Button / 기타 Control → 가로 초과 시 축소 (1줄 유지)
static func fit_text(control: Control, max_px: int, min_px: int) -> void:
	var tree := control.get_tree()
	if tree == null:
		return
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
		while control.get_minimum_size().x > control.size.x and fs > min_px:
			fs -= 1
			control.add_theme_font_size_override("font_size", fs)
			await tree.process_frame
