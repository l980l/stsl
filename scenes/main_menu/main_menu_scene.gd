# scenes/main_menu/main_menu_scene.gd
extends Node2D

const CreditsOverlay := preload("res://scenes/ui/credits_overlay.gd")
const CodexOverlayScene := preload("res://scenes/ui/codex_scene.tscn")

func _ready() -> void:
	AudioManager.play_bgm_dynamic("menu", "")
	_build_ui()

func _build_ui() -> void:
	var P := SacredPalette

	var bg := ColorRect.new()
	bg.color = P.INK_900
	bg.position = Vector2.ZERO
	bg.size = Vector2(1920, 1080)
	add_child(bg)

	var crosshatch := SacredTheme.make_crosshatch_overlay()
	crosshatch.position = Vector2.ZERO
	crosshatch.size = Vector2(1920, 1080)
	add_child(crosshatch)

	# 상단 금빛 수평선 장식
	var top_line := ColorRect.new()
	top_line.color = P.BRASS_700
	top_line.position = Vector2(0, 180)
	top_line.size = Vector2(1920, 1)
	add_child(top_line)

	# 소제목 eyebrow
	var eyebrow := Label.new()
	eyebrow.theme_type_variation = "EyebrowLabel"
	eyebrow.text = "— THE CARD GAME —"
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	eyebrow.position = Vector2(660, 200)
	eyebrow.size = Vector2(600, 30)
	add_child(eyebrow)

	# 메인 타이틀
	var title := Label.new()
	title.theme_type_variation = "TitleLabel"
	title.add_theme_font_size_override("font_size", 72)
	title.add_theme_color_override("font_color", P.BRASS_300)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.text = tr("ui.main_menu.title")
	title.position = Vector2(660, 235)
	title.size = Vector2(600, 110)
	add_child(title)
	LabelUtils.fit_text(title, 72, 36)

	# 구분선
	var divider := ColorRect.new()
	divider.color = P.BRASS_700
	divider.position = Vector2(760, 360)
	divider.size = Vector2(400, 1)
	add_child(divider)

	# 버튼 수직 스택 — 새 게임 / (이어하기) / 크레딧 / 종료
	var btn_y := 420.0

	# 새 게임 버튼 (Primary)
	_add_menu_button(tr("ui.main_menu.new_game"), btn_y, "PrimaryButton", _on_new_game)
	btn_y += 80.0

	# 이어하기 버튼 (Primary — 있을 때만)
	if SaveManager.has_save():
		_add_menu_button(tr("ui.main_menu.continue"), btn_y, "PrimaryButton", _on_continue)
		btn_y += 80.0

	# 도감 버튼 (Vow)
	_add_menu_button(tr("ui.main_menu.codex"), btn_y, "VowButton", _on_codex)
	btn_y += 80.0

	# 크레딧 버튼 (Vow)
	_add_menu_button(tr("ui.main_menu.credits"), btn_y, "VowButton", _on_credits)
	btn_y += 80.0

	# 종료 버튼 (Vow)
	_add_menu_button(tr("ui.main_menu.quit"), btn_y, "VowButton", _on_quit)

	# 하단 금빛 수평선 장식
	var bot_line := ColorRect.new()
	bot_line.color = P.BRASS_700
	bot_line.position = Vector2(0, 900)
	bot_line.size = Vector2(1920, 1)
	add_child(bot_line)

# 메뉴 버튼 빌더 — 810,y 기준 300×60, 폰트 16, 호버 애니메이션.
func _add_menu_button(text: String, y: float, variation: String, handler: Callable) -> void:
	var btn := Button.new()
	btn.theme_type_variation = variation
	btn.position = Vector2(810, y)
	btn.size = Vector2(300, 60)
	btn.add_theme_font_size_override("font_size", 16)
	btn.text = text
	btn.pressed.connect(handler)
	add_child(btn)
	LabelUtils.fit_text(btn, 16, 12)
	SacredTheme.animate_button(btn)

func _on_new_game() -> void:
	SaveManager.clear_save()
	SceneTransition.go("res://scenes/chapter_select/chapter_select_scene.tscn")

func _on_continue() -> void:
	SaveManager.load_save()
	SceneTransition.go("res://scenes/map/map_scene.tscn")

func _on_codex() -> void:
	if get_node_or_null("CodexOverlay") != null:
		return
	var ov := CodexOverlayScene.instantiate()
	ov.name = "CodexOverlay"
	add_child(ov)

func _on_credits() -> void:
	if get_node_or_null("CreditsOverlay") != null:
		return
	var overlay := CreditsOverlay.new()
	overlay.name = "CreditsOverlay"
	add_child(overlay)

func _on_quit() -> void:
	get_tree().quit()
