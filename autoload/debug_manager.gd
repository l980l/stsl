# autoload/debug_manager.gd
extends Node

const _SHORTCUT_TEXT = "── 전투 전용 ──\n[Shift+Q]  전투 즉시 승리\n[Shift+I]  무적 토글 (영웅 피해 차단)\n[Shift+E]  무한 코스트 토글\n[Shift+D]  카드 1장 드로우\n[Shift+H]  적 HP 설정 → 적 클릭\n[Shift+G]  그리드 토글\n[Shift+O]  더미 몬스터 추가\n[Shift+S]  더미 소환수 추가 (1번 영웅)\n── 전체 공통 ──\n[Shift+T]  번역 키 표시 토글\n[Shift+M]  몬스터 선택 전투\n[Shift+B]  영웅 HP 조정\n[Shift+W]  현재 챕터 즉시 클리어\n[Shift+F]  현재 Act 클리어 → 다음 Act 진입\n[Shift+P]  파티에 영웅 추가\n[Shift+A]  카드 추가 창\n[Shift+R]  덱 편집기 (카드 제거)\n[Shift+U]  카드 강화\n[Shift+N]  영웅 즉시 해금 창\n[Shift+L]  렐릭 추가 창\n[Shift+X]  렐릭 제거 창\n[Shift+V]  이벤트 씬 입장\n[Shift+C]  목록 고정/해제"

var _pinned_label: Label = null
var _hover_lbl: Label = null
var _show_keys: bool = false
var _saved_translations: Array = []

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
	_hover_lbl = hover_lbl
	_apply_key_mode_style()

	_pinned_label = Label.new()
	_pinned_label.text = "🛠 디버그 단축키\n" + _SHORTCUT_TEXT
	_pinned_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_pinned_label.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_pinned_label.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_pinned_label.offset_left = -220
	_pinned_label.offset_top = -260
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
	if event.keycode == KEY_T:
		_show_keys = not _show_keys
		if _show_keys:
			_remove_all_translations()
		else:
			_restore_all_translations()
		_apply_key_mode_style()
		get_tree().reload_current_scene()
		return
	match event.keycode:
		KEY_W:
			GameManager._end_run_won()
		KEY_F:
			GameManager.pending_boss_upgrade = false
			GameManager.pending_boss_recruit = false
			if GameManager.current_act < GameManager.MAX_ACTS:
				GameManager._start_next_act()
			else:
				GameManager._end_run_won()
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
				opts.append(["[%s] %s%s (코%d)  |  %s" % [card.owner_id, tr(card.card_name), suffix, card.cost, _effect_summary(card)], card, _rarity_color(card.rarity)])
			_sort_card_opts(opts)
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
				opts.append(["[%s] %s%s (코%d)  |  %s" % [card.owner_id, tr(card.card_name), suffix, card.cost, _effect_summary(card)], card, _rarity_color(card.rarity)])
			_sort_card_opts(opts)
			_make_checkbox_dialog("카드 강화", opts, "강화", func(picked: Array):
				for card in picked:
					GameManager.upgrade_card(card)
				if not picked.is_empty():
					DeckManager.hand_changed.emit()
			)
		KEY_P:
			_open_hero_add_dialog()
		KEY_N:
			_open_hero_unlock_dialog()
		KEY_L:
			_open_relic_add_dialog()
		KEY_X:
			_open_relic_remove_dialog()
		KEY_M:
			_open_monster_pick_dialog()
		KEY_B:
			_open_hero_hp_dialog()
		KEY_V:
			_open_event_enter_dialog()

# ── 영웅 파티 추가 ──────────────────────────────────

func _open_hero_add_dialog() -> void:
	var HR = load("res://resources/heroes/hero_registry.gd")
	var tm = get_tree().root.get_node_or_null("TeamManager")
	var current_ids: Dictionary = {}
	if tm:
		for h in tm.heroes:
			current_ids[h.hero_id] = true
	if current_ids.size() >= 3:
		var dlg := AcceptDialog.new()
		dlg.title = "파티 추가 불가"
		dlg.dialog_text = "파티원이 이미 3명입니다."
		dlg.confirmed.connect(func(): dlg.queue_free())
		dlg.canceled.connect(func(): dlg.queue_free())
		get_tree().root.add_child(dlg)
		dlg.popup_centered()
		return
	var opts: Array = []
	for hid in HR.all_hero_ids():
		var info: Dictionary = HR.get_display_info(hid)
		var in_party: bool = hid in current_ids
		var color := Color(0.55, 0.55, 0.55) if in_party else Color.WHITE
		var status := "  (파티 중)" if in_party else ""
		opts.append(["%s  [%s]%s" % [tr(info.get("name", hid)), hid, status], hid, color])
	_make_checkbox_dialog("파티에 영웅 추가", opts, "추가", func(picked: Array):
		for hid in picked:
			if hid in current_ids:
				continue
			var hero: Resource = GameManager._make_hero_by_id(hid)
			if hero == null:
				continue
			if tm:
				tm.add_hero(hero)
			GameManager._add_initial_deck_for(hero)
	)

# ── 영웅 해금 ───────────────────────────────────────

func _open_hero_unlock_dialog() -> void:
	var pm: ProgressManagerClass = get_node_or_null("/root/ProgressManager")
	var HR = load("res://resources/heroes/hero_registry.gd")
	var opts: Array = []
	for hid in HR.all_hero_ids():
		var info: Dictionary = HR.get_display_info(hid)
		var locked: bool = pm == null or not pm.is_hero_unlocked(hid)
		var color := Color.WHITE if locked else Color(0.55, 0.55, 0.55)
		var status := "잠금" if locked else "해금됨"
		opts.append(["%s  [%s]  —  %s" % [tr(info.get("name", hid)), hid, status], hid, color])
	_make_checkbox_dialog("영웅 즉시 해금", opts, "즉시 해금", func(picked: Array):
		if pm == null:
			return
		for hid in picked:
			if pm.unlock_hero(hid):
				pm.hero_unlocked.emit(hid)
	, true)

# ── 렐릭 추가 ───────────────────────────────────────

func _open_relic_add_dialog() -> void:
	var RelicsGd = load("res://resources/relics/relics.gd")
	var all_relics: Array = RelicsGd.build_pool()
	var opts: Array = []
	for r in all_relics:
		var owned: bool = GameManager.has_relic(r.relic_name)
		var color := Color(0.55, 0.55, 0.55) if owned else Color.WHITE
		var suffix := "  (보유중)" if owned else ""
		opts.append(["%s%s  —  %s" % [tr(r.relic_name), suffix, tr(r.description)], r, color])
	_make_checkbox_dialog("렐릭 추가", opts, "획득", func(picked: Array):
		for r in picked:
			GameManager.add_relic(r)
	)

# ── 렐릭 제거 ───────────────────────────────────────

func _open_relic_remove_dialog() -> void:
	if GameManager.relics.is_empty():
		var dlg := AcceptDialog.new()
		dlg.title = "렐릭 제거"
		dlg.dialog_text = "보유 중인 렐릭이 없습니다."
		dlg.confirmed.connect(func(): dlg.queue_free())
		dlg.canceled.connect(func(): dlg.queue_free())
		get_tree().root.add_child(dlg)
		dlg.popup_centered()
		return
	var opts: Array = []
	for r in GameManager.relics:
		opts.append(["%s  —  %s" % [tr(r.relic_name), tr(r.description)], r, Color.WHITE])
	_make_checkbox_dialog("렐릭 제거", opts, "제거", func(picked: Array):
		for r in picked:
			GameManager.relics.erase(r)
	)

# ── 영웅 HP 조정 ────────────────────────────────────

func _open_hero_hp_dialog() -> void:
	var heroes: Array = TeamManager.heroes
	if heroes.is_empty():
		return

	var dlg := AcceptDialog.new()
	dlg.title = "영웅 HP 조정"
	dlg.get_ok_button().text = "적용"
	dlg.add_cancel_button("닫기")
	dlg.min_size = Vector2i(440, 60 + heroes.size() * 52)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)

	var edits: Array = []

	for hero in heroes:
		var cur_hp: int = TeamManager.get_current_hp(hero.hero_id)
		var max_hp: int = hero.max_hp
		var alive: bool = TeamManager.is_alive(hero.hero_id)

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)

		var name_lbl := Label.new()
		name_lbl.text = tr(hero.hero_name) + ("  (사망)" if not alive else "")
		name_lbl.custom_minimum_size = Vector2(130, 0)
		if not alive:
			name_lbl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55))
		row.add_child(name_lbl)

		var edit := LineEdit.new()
		edit.text = str(cur_hp)
		edit.custom_minimum_size = Vector2(70, 0)
		row.add_child(edit)

		var max_lbl := Label.new()
		max_lbl.text = "/ %d" % max_hp
		row.add_child(max_lbl)

		var cap_max: int = max_hp
		var max_btn := Button.new()
		max_btn.text = "MAX"
		max_btn.pressed.connect(func(): edit.text = str(cap_max))
		row.add_child(max_btn)

		var half_btn := Button.new()
		half_btn.text = "½"
		half_btn.pressed.connect(func(): edit.text = str(max(1, cap_max >> 1)))
		row.add_child(half_btn)

		var one_btn := Button.new()
		one_btn.text = "1"
		one_btn.pressed.connect(func(): edit.text = "1")
		row.add_child(one_btn)

		vbox.add_child(row)
		edits.append({"hero_id": hero.hero_id, "edit": edit, "max_hp": max_hp})

	dlg.add_child(vbox)

	dlg.confirmed.connect(func():
		for e in edits:
			var val: int = clamp(e["edit"].text.to_int(), 0, e["max_hp"])
			var hid: String = e["hero_id"]
			if val <= 0:
				if TeamManager.is_alive(hid):
					TeamManager.take_damage(hid, TeamManager.get_current_hp(hid))
			elif not TeamManager.is_alive(hid):
				TeamManager.revive(hid, val)
			else:
				TeamManager._hero_hp[hid] = val
				TeamManager.hero_healed.emit(hid, 0)
		dlg.queue_free()
	)
	dlg.canceled.connect(func(): dlg.queue_free())
	get_tree().root.add_child(dlg)
	dlg.popup_centered()

# ── 몬스터 선택 전투 ────────────────────────────────

func _open_monster_pick_dialog() -> void:
	var dummy_scene: PackedScene = load("res://characters/enemies/satyr/satyr.tscn")
	var registry: Dictionary = GameManager._get_mythology_registry()
	var opts: Array = []

	for myth in ["greek", "egyptian", "norse", "korean", "chinese", "japanese"]:
		var entry: Dictionary = registry.get(myth, {})
		if entry.is_empty():
			continue

		var normals_mod = entry["normals"]
		var seen: Dictionary = {}
		for encounter in normals_mod.encounters():
			for fn: String in encounter:
				if seen.has(fn):
					continue
				seen[fn] = true
				var enemy: Resource = normals_mod.call(fn, dummy_scene)
				opts.append(["[%s · 일반]  %s" % [myth, tr(enemy.enemy_name)],
					{"module": normals_mod, "fn_name": fn}, true, Color.WHITE])

		var acts: Array = entry["acts"]
		for act_i in range(acts.size()):
			var act_mod = acts[act_i]
			if act_mod == null:
				continue
			if act_mod.has_method("elites"):
				for fn: String in act_mod.elites():
					var enemy: Resource = act_mod.call(fn, dummy_scene)
					opts.append(["[%s · 엘리트 A%d]  %s" % [myth, act_i + 1, tr(enemy.enemy_name)],
						{"module": act_mod, "fn_name": fn}, true, Color(0.9, 0.7, 0.3)])
			if act_mod.has_method("boss"):
				var fn: String = act_mod.boss()
				if fn != "":
					var enemy: Resource = act_mod.call(fn, dummy_scene)
					opts.append(["[%s · 보스 A%d]  %s" % [myth, act_i + 1, tr(enemy.enemy_name)],
						{"module": act_mod, "fn_name": fn}, true, Color(1.0, 0.4, 0.4)])

	_make_radio_dialog("몬스터 선택 전투", opts, "전투 시작", func(payload: Dictionary):
		var enemy: Resource = payload["module"].call(payload["fn_name"], dummy_scene)
		GameManager.pending_enemies = [enemy]
		GameManager._request_scene("res://scenes/battle/battle_scene.tscn")
	)

# ── 이벤트 씬 입장 ──────────────────────────────────

func _open_event_enter_dialog() -> void:
	var all_events: Array = []
	var event_paths := [
		"res://resources/events/events_act1.gd",
		"res://resources/events/events_act2.gd",
		"res://resources/events/events_act3.gd",
		"res://resources/events/events_korean.gd",
		"res://resources/events/events_chinese.gd",
		"res://resources/events/events_japanese.gd",
	]
	for path in event_paths:
		if ResourceLoader.exists(path):
			var script = load(path)
			if script and script.has_method("build_pool"):
				all_events.append_array(script.build_pool())

	var available_names: Dictionary = {}
	for ev in GameManager._build_event_pool():
		available_names[ev.event_name] = true

	var available_opts: Array = []
	var unavailable_opts: Array = []
	var seen: Dictionary = {}
	for ev in all_events:
		if ev.event_name in seen:
			continue
		seen[ev.event_name] = true
		var is_avail: bool = ev.event_name in available_names
		var color := Color.WHITE if is_avail else Color(0.5, 0.5, 0.5)
		var desc: String = tr(ev.get("description")) if ev.get("description") != null else ""
		var label: String = "%s  —  %s" % [tr(ev.event_name), desc] if desc != "" else tr(ev.event_name)
		if is_avail:
			available_opts.append([label, ev, true, color])
		else:
			unavailable_opts.append([label, ev, false, color])

	_make_radio_dialog("이벤트 씬 입장", available_opts + unavailable_opts, "입장", func(ev: Resource):
		GameManager.pending_event = ev
		GameManager._request_scene("res://scenes/event/event_scene.tscn")
	)

# ── UI 헬퍼 ─────────────────────────────────────────

func _make_checkbox_dialog(title: String, options: Array, confirm_text: String, on_confirm: Callable, show_select_all: bool = false) -> void:
	var dlg := AcceptDialog.new()
	dlg.title = title
	dlg.get_ok_button().text = confirm_text
	dlg.add_cancel_button("닫기")
	dlg.min_size = Vector2i(600, 580)

	var outer := VBoxContainer.new()

	var checks: Array = []

	if show_select_all:
		var toggle_state := [false]
		var sa_btn := Button.new()
		sa_btn.text = "전체 선택"
		sa_btn.pressed.connect(func():
			toggle_state[0] = not toggle_state[0]
			sa_btn.text = "전체 해제" if toggle_state[0] else "전체 선택"
			for c in checks:
				c.button_pressed = toggle_state[0]
		)
		outer.add_child(sa_btn)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(560, 480)
	var vbox := VBoxContainer.new()
	scroll.add_child(vbox)

	for opt in options:
		var cb := CheckBox.new()
		cb.text = opt[0]
		cb.set_meta("payload", opt[1])
		if opt.size() >= 3:
			cb.add_theme_color_override("font_color", opt[2])
		vbox.add_child(cb)
		checks.append(cb)

	outer.add_child(scroll)
	dlg.add_child(outer)

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

# options: Array of [label, payload, is_enabled, color]
# 단일 선택 (라디오 버튼). 활성화된 항목만 선택 가능.
func _make_radio_dialog(title: String, options: Array, confirm_text: String, on_confirm: Callable) -> void:
	var dlg := AcceptDialog.new()
	dlg.title = title
	dlg.get_ok_button().text = confirm_text
	dlg.add_cancel_button("닫기")
	dlg.min_size = Vector2i(900, 560)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(860, 480)
	var vbox := VBoxContainer.new()
	scroll.add_child(vbox)

	var group := ButtonGroup.new()
	var btns: Array = []

	for opt in options:
		var cb := CheckBox.new()
		cb.text = opt[0]
		cb.button_group = group
		cb.set_meta("payload", opt[1])
		var enabled: bool = opt[2] if opt.size() >= 3 else true
		cb.disabled = not enabled
		if opt.size() >= 4:
			cb.add_theme_color_override("font_color", opt[3])
		vbox.add_child(cb)
		btns.append(cb)

	dlg.add_child(scroll)

	dlg.confirmed.connect(func():
		var pressed_btn = group.get_pressed_button()
		if pressed_btn != null:
			on_confirm.call(pressed_btn.get_meta("payload"))
		dlg.queue_free()
	)
	dlg.canceled.connect(func(): dlg.queue_free())
	get_tree().root.add_child(dlg)
	dlg.popup_centered()

# ── 카드 유틸 ────────────────────────────────────────

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
			var label := "[%s] %s  C%d  |  %s" % [hero.hero_id, tr(card.card_name), card.cost, fx]
			results.append([label, card, _rarity_color(card.rarity)])
	return _sort_card_opts(results)

func _sort_card_opts(opts: Array) -> Array:
	opts.sort_custom(func(a, b):
		var a_owner: String = a[1].owner_id if a[1] != null else ""
		var b_owner: String = b[1].owner_id if b[1] != null else ""
		if a_owner != b_owner:
			return a_owner < b_owner
		return a[1].rarity < b[1].rarity
	)
	return opts

func _effect_summary(card: Resource) -> String:
	var parts: Array = []
	for eff in card.effects:
		parts.append(eff.display_text())
	return " / ".join(parts)

func _remove_all_translations() -> void:
	_saved_translations.clear()
	while true:
		var found := false
		for locale in Array(TranslationServer.get_loaded_locales()):
			var t := TranslationServer.get_translation_object(locale)
			if t != null:
				_saved_translations.append(t)
				TranslationServer.remove_translation(t)
				found = true
		if not found:
			break

func _restore_all_translations() -> void:
	for t in _saved_translations:
		TranslationServer.add_translation(t)
	_saved_translations.clear()
	TranslationServer.set_locale(LocaleManager.current_locale)

func _apply_key_mode_style() -> void:
	if _hover_lbl == null:
		return
	if _show_keys:
		_hover_lbl.text = "🛠 디버그 [KEY MODE]"
		_hover_lbl.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	else:
		_hover_lbl.text = "🛠 디버그 단축키"
		_hover_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
