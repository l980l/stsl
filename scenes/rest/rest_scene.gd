# scenes/rest/rest_scene.gd
extends Node2D

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	var P := SacredPalette

	var bg := ColorRect.new()
	bg.color = P.INK_1000
	bg.size = Vector2(1920, 1080)
	add_child(bg)

	var eyebrow := Label.new()
	eyebrow.theme_type_variation = "EyebrowLabel"
	eyebrow.text = "— SHRINE —"
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	eyebrow.position = Vector2(760, 82)
	eyebrow.size = Vector2(400, 24)
	add_child(eyebrow)

	var title := Label.new()
	title.theme_type_variation = "TitleLabel"
	title.text = tr("ui.rest.title")
	title.position = Vector2(760, 110)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title)
	title.size = Vector2(400, 60)
	LabelUtils.fit_text(title, 36, 22)

	var tm := _get_tm()
	if tm:
		for i in range(tm.heroes.size()):
			var hero: Resource = tm.heroes[i]
			var current_hp: int = tm.get_current_hp(hero.hero_id) if tm.has_method("get_current_hp") else hero.max_hp
			var lbl := Label.new()
			lbl.theme_type_variation = "SubLabel"
			lbl.text = tr("ui.rest.hero_hp_format") % [tr(hero.hero_name), current_hp, hero.max_hp]
			lbl.position = Vector2(660, 250 + i * 50)
			lbl.size = Vector2(600, 40)
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			add_child(lbl)

	var heal_btn := Button.new()
	heal_btn.theme_type_variation = "PrimaryButton"
	heal_btn.text = tr("ui.rest.btn_heal")
	heal_btn.position = Vector2(760, 490)
	heal_btn.pressed.connect(_on_heal_pressed)
	add_child(heal_btn)
	heal_btn.size = Vector2(400, 55)
	LabelUtils.fit_text(heal_btn, 20, 12)
	SacredTheme.animate_button(heal_btn)

	var upgrade_btn := Button.new()
	upgrade_btn.theme_type_variation = "PrimaryButton"
	upgrade_btn.text = tr("ui.rest.btn_upgrade")
	upgrade_btn.position = Vector2(760, 555)
	upgrade_btn.pressed.connect(_on_upgrade_pressed)
	add_child(upgrade_btn)
	upgrade_btn.size = Vector2(400, 55)
	LabelUtils.fit_text(upgrade_btn, 20, 12)
	SacredTheme.animate_button(upgrade_btn)

	var leave_btn := Button.new()
	leave_btn.theme_type_variation = "VowButton"
	leave_btn.text = tr("ui.rest.btn_leave")
	leave_btn.position = Vector2(760, 625)
	leave_btn.pressed.connect(_on_leave_pressed)
	add_child(leave_btn)
	leave_btn.size = Vector2(400, 55)
	LabelUtils.fit_text(leave_btn, 20, 12)
	SacredTheme.animate_button(leave_btn)

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
