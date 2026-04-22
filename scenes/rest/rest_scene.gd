# scenes/rest/rest_scene.gd
extends Node2D

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.08, 0.04)
	bg.size = Vector2(1920, 1080)
	add_child(bg)

	var title := Label.new()
	title.text = tr("ui.rest.title")
	title.position = Vector2(760, 100)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	add_child(title)
	title.size = Vector2(400, 60)
	LabelUtils.fit_text(title, 36, 22)

	# 영웅 HP 표시
	var tm := _get_tm()
	if tm:
		for i in range(tm.heroes.size()):
			var hero: Resource = tm.heroes[i]
			var current_hp: int = tm.get_current_hp(hero.hero_id) if tm.has_method("get_current_hp") else hero.max_hp
			var lbl := Label.new()
			lbl.text = "%s  HP: %d / %d" % [hero.hero_name, current_hp, hero.max_hp]
			lbl.position = Vector2(660, 240 + i * 50)
			lbl.size = Vector2(600, 40)
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lbl.add_theme_font_size_override("font_size", 20)
			add_child(lbl)

	var heal_btn := Button.new()
	heal_btn.text = tr("ui.rest.btn_heal")
	heal_btn.position = Vector2(760, 480)
	heal_btn.add_theme_font_size_override("font_size", 20)
	heal_btn.pressed.connect(_on_heal_pressed)
	add_child(heal_btn)
	heal_btn.size = Vector2(400, 55)
	LabelUtils.fit_text(heal_btn, 20, 12)

	var upgrade_btn := Button.new()
	upgrade_btn.text = tr("ui.rest.btn_upgrade")
	upgrade_btn.position = Vector2(760, 545)
	upgrade_btn.add_theme_font_size_override("font_size", 20)
	upgrade_btn.pressed.connect(_on_upgrade_pressed)
	add_child(upgrade_btn)
	upgrade_btn.size = Vector2(400, 55)
	LabelUtils.fit_text(upgrade_btn, 20, 12)

	var leave_btn := Button.new()
	leave_btn.text = tr("ui.rest.btn_leave")
	leave_btn.position = Vector2(760, 610)
	leave_btn.add_theme_font_size_override("font_size", 20)
	leave_btn.pressed.connect(_on_leave_pressed)
	add_child(leave_btn)
	leave_btn.size = Vector2(400, 55)
	LabelUtils.fit_text(leave_btn, 20, 12)

func _get_tm() -> Object:
	if Engine.has_singleton("TeamManager"):
		return Engine.get_singleton("TeamManager")
	var ml := Engine.get_main_loop()
	if ml and ml.root:
		return ml.root.get_node_or_null("TeamManager")
	return null

func _on_heal_pressed() -> void:
	var tm := _get_tm()
	if tm:
		for hero in tm.heroes:
			tm.heal(hero.hero_id, int(hero.max_hp * 0.3))
	GameManager.complete_rest()

func _on_upgrade_pressed() -> void:
	GameManager.enter_card_upgrade()

func _on_leave_pressed() -> void:
	GameManager.complete_rest()
