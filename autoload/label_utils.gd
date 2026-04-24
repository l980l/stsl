# autoload/label_utils.gd
# NOTE: autoload 등록하지 않음 — static 유틸 (MapGenerator 와 동일 패턴)
class_name LabelUtils
extends RefCounted

# Control 의 폰트를 영역에 맞게 자동 축소.
# - Label + autowrap 있음 → 세로 초과 시 축소 (줄바꿈 발생, width 고정)
# - Label autowrap 없음 / Button / 기타 Control → 가로 초과 시 축소 (1줄 유지)
# target_w: size.x 가 레이아웃 패스 전에 0일 수 있으므로, layout_mode=0 라벨은 명시 전달 권장.
static func fit_text(control: Control, max_px: int, min_px: int, target_w: float = -1.0) -> void:
	if not control.is_inside_tree():
		return
	control.add_theme_font_size_override("font_size", max_px)

	var is_wrap_label := control is Label and (control as Label).autowrap_mode != TextServer.AUTOWRAP_OFF
	if is_wrap_label:
		# 줄바꿈 라벨: layout 정착 후 한 프레임씩 줄임
		var lbl := control as Label
		var fs := max_px
		await control.get_tree().process_frame
		while lbl.get_line_count() * lbl.get_line_height() > lbl.size.y and fs > min_px:
			fs -= 1
			lbl.add_theme_font_size_override("font_size", fs)
			await lbl.get_tree().process_frame
	else:
		if control is Label:
			(control as Label).vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		# size.x 가 레이아웃 패스 전 0일 수 있으므로 offset 폴백 사용
		var check_w: float = target_w
		if check_w <= 0.0:
			check_w = control.size.x
		if check_w <= 0.0:
			check_w = control.offset_right - control.offset_left
		if check_w <= 0.0:
			return

		# Font.get_string_size() 로 직접 측정 — 레이아웃 패스 불필요
		var text := ""
		if control is Label:
			text = (control as Label).text
		elif control is Button:
			text = (control as Button).text
		var font: Font = control.get_theme_font("font")
		var text_w: float = 0.0
		if font and not text.is_empty():
			text_w = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, max_px).x
		if text_w <= 0.0:
			text_w = control.get_minimum_size().x
		if text_w > check_w and text_w > 0.0:
			var fs: int = max(min_px, int(max_px * check_w / text_w))
			control.add_theme_font_size_override("font_size", fs)
