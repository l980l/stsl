# autoload/debug_manager.gd
extends Node

const _SHORTCUT_TEXT = "── 전투 전용 ──\n[Shift+Q]  전투 즉시 승리\n[Shift+I]  무적 토글 (영웅 피해 차단)\n[Shift+E]  무한 코스트 토글\n[Shift+D]  카드 1장 드로우\n[Shift+H]  적 HP 설정 → 적 클릭\n[Shift+G]  그리드 토글\n── 전체 공통 ──\n[Shift+A]  카드 추가 창\n[Shift+R]  덱 편집기 (카드 제거)\n[Shift+U]  카드 강화\n[Shift+C]  목록 고정/해제"

var _pinned_label: Label = null

func _ready() -> void:
	if not OS.is_debug_build():
		return
	var layer := CanvasLayer.new()
	layer.layer = 100

	var hover_lbl := Label.new()
	hover_lbl.text = "🛠 디버그 단축키"
	hover_lbl.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	hover_lbl.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	hover_lbl.grow_vertical = Control.GROW_DIRECTION_BEGIN
	hover_lbl.offset_left = -160
	hover_lbl.offset_top = -30
	hover_lbl.add_theme_font_size_override("font_size", 13)
	hover_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	hover_lbl.mouse_filter = Control.MOUSE_FILTER_STOP
	hover_lbl.tooltip_text = _SHORTCUT_TEXT
	layer.add_child(hover_lbl)

	_pinned_label = Label.new()
	_pinned_label.text = "🛠 디버그 단축키\n" + _SHORTCUT_TEXT
	_pinned_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_pinned_label.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_pinned_label.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_pinned_label.offset_left = -220
	_pinned_label.offset_top = -220
	_pinned_label.add_theme_font_size_override("font_size", 12)
	_pinned_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3, 0.85))
	_pinned_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pinned_label.visible = false
	layer.add_child(_pinned_label)

	add_child(layer)

func _unhandled_key_input(event: InputEvent) -> void:
	if not OS.is_debug_build() or not event.pressed or event.echo:
		return
	if not event.shift_pressed:
		return
	if event.keycode == KEY_C:
		if _pinned_label != null:
			_pinned_label.visible = not _pinned_label.visible
		return
	match event.keycode:
		KEY_A:
			var opts := _collect_party_card_pools()
			_make_checkbox_dialog("카드 추가", opts, "덱 추가", func(picked: Array):
				for card in picked:
					DeckManager.add_card_to_deck(card.duplicate(true))
			)
		KEY_R:
			var opts: Array = []
			for card in DeckManager.get_full_deck():
				var suffix := " +%d" % card.upgrade_level if card.upgrade_level > 0 else ""
				opts.append(["%s%s (코%d)  |  %s" % [card.card_name, suffix, card.cost, _effect_summary(card)], card, _rarity_color(card.rarity)])
			_make_checkbox_dialog("덱 편집 — 제거할 카드", opts, "제거", func(picked: Array):
				for card in picked:
					if not DeckManager.remove_from_deck(card):
						DeckManager.hand.erase(card)
				if not picked.is_empty():
					DeckManager.hand_changed.emit()
			)
		KEY_U:
			var opts: Array = []
			for card in DeckManager.get_full_deck():
				if not card.can_upgrade():
					continue
				var suffix := " +%d → +%d" % [card.upgrade_level, card.upgrade_level + 1]
				opts.append(["%s%s (코%d)  |  %s" % [card.card_name, suffix, card.cost, _effect_summary(card)], card, _rarity_color(card.rarity)])
			_make_checkbox_dialog("카드 강화", opts, "강화", func(picked: Array):
				for card in picked:
					GameManager.upgrade_card(card)
				if not picked.is_empty():
					DeckManager.hand_changed.emit()
			)

func _rarity_color(r: int) -> Color:
	match r:
		CardResource.Rarity.COMMON:    return Color(1.0, 1.0, 1.0)
		CardResource.Rarity.UNCOMMON:  return Color(0.3, 0.6, 1.0)
		CardResource.Rarity.RARE:      return Color(0.7, 0.3, 1.0)
		CardResource.Rarity.LEGENDARY: return Color(1.0, 0.6, 0.1)
		CardResource.Rarity.DIVINE:    return Color(1.0, 0.2, 0.2)
		_: return Color(1.0, 1.0, 1.0)

func _collect_party_card_pools() -> Array:
	var results: Array = []
	for hero in TeamManager.heroes:
		var path := "res://resources/cards/cards_%s.gd" % hero.hero_id
		if not ResourceLoader.exists(path):
			continue
		var script = load(path)
		if script == null or not script.has_method("pool"):
			continue
		for card in script.pool():
			var fx := _effect_summary(card)
			var label := "[%s] %s  C%d  |  %s" % [hero.hero_id, card.card_name, card.cost, fx]
			results.append([label, card, _rarity_color(card.rarity)])
	return results

func _effect_summary(card: Resource) -> String:
	var parts: Array = []
	for eff in card.effects:
		parts.append(eff.display_text())
	return " / ".join(parts)

func _make_checkbox_dialog(title: String, options: Array, confirm_text: String, on_confirm: Callable) -> void:
	var dlg := AcceptDialog.new()
	dlg.title = title
	dlg.get_ok_button().text = confirm_text
	dlg.add_cancel_button("닫기")
	dlg.min_size = Vector2i(600, 560)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(560, 480)
	var vbox := VBoxContainer.new()
	scroll.add_child(vbox)
	var checks: Array = []
	for opt in options:
		var cb := CheckBox.new()
		cb.text = opt[0]
		cb.set_meta("payload", opt[1])
		if opt.size() >= 3:
			cb.add_theme_color_override("font_color", opt[2])
		vbox.add_child(cb)
		checks.append(cb)
	dlg.add_child(scroll)
	dlg.confirmed.connect(func():
		var picked: Array = []
		for c in checks:
			if c.button_pressed:
				picked.append(c.get_meta("payload"))
		on_confirm.call(picked)
		dlg.queue_free()
	)
	dlg.canceled.connect(func(): dlg.queue_free())
	get_tree().root.add_child(dlg)
	dlg.popup_centered()
