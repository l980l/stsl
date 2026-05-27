# autoload/label_utils.gd
# NOTE: autoload 등록하지 않음 — static 유틸 (MapGenerator 와 동일 패턴)
class_name LabelUtils
extends RefCounted

# Control 의 폰트를 영역에 맞게 자동 축소.
# - Label + autowrap 있음 → 세로 초과 시 축소 (줄바꿈 발생, width 고정)
# - Label autowrap 없음 / Button / 기타 Control → 가로 초과 시 축소 (1줄 유지)
# target_w: size.x 가 레이아웃 패스 전에 0일 수 있으므로, layout_mode=0 라벨은 명시 전달 권장.
static func fit_text(control: Control, max_px: int, min_px: int, target_w: float = -1.0, target_h: float = -1.0, wrap_fallback: bool = false) -> void:
	if not control.is_inside_tree():
		return
	# wrap_fallback 모드: 이전 호출에서 활성화된 wrap 상태를 매번 reset
	# (안 그러면 wrap 분기로 빠져 max_px 그대로 wrap 됨 — 같은 텍스트가 1/2 줄 비결정적)
	if wrap_fallback and control is Label:
		var l := control as Label
		l.autowrap_mode = TextServer.AUTOWRAP_OFF
		l.clip_text = true
	control.add_theme_font_size_override("font_size", max_px)

	var is_wrap_label := control is Label and (control as Label).autowrap_mode != TextServer.AUTOWRAP_OFF
	if is_wrap_label:
		# 줄바꿈 라벨: layout 정착 후 한 프레임씩 줄임
		var lbl := control as Label
		var fs := max_px
		var check_h: float = target_h if target_h > 0.0 else lbl.size.y
		await control.get_tree().process_frame
		# await 후 라벨이 free 됐을 수 있음 (카드 핸드 갱신/언어 변경 등). 가드.
		if not is_instance_valid(lbl) or not lbl.is_inside_tree():
			return
		while lbl.get_line_count() * lbl.get_line_height() > check_h and fs > min_px:
			fs -= 1
			lbl.add_theme_font_size_override("font_size", fs)
			await lbl.get_tree().process_frame
			if not is_instance_valid(lbl) or not lbl.is_inside_tree():
				return
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
			# 최소 폰트에서도 여전히 가로 초과면 줄바꿈 활성화 (Label 만, target_w 명시된 경우만)
			if fs == min_px and control is Label and target_w > 0.0 and font:
				var min_w: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, min_px).x
				if min_w > check_w:
					var lbl := control as Label
					lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
					lbl.clip_text = false  # wrap 시 clip 해제 (clip + wrap 충돌 회피)
					lbl.custom_minimum_size.x = check_w
