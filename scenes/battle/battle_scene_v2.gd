# scenes/battle/battle_scene_v2.gd
# 개체별 턴 시스템 프로토타입 씬 — F6 실행. 영웅 3 + 적 2 고정 셋업.
# UI 매우 단순 (텍스트 위주). 카드 = Button. 적 타겟 = 카드 클릭 후 적 클릭.
extends Control

const _NapoleonCards  = preload("res://resources/cards/cards_napoleon.gd")
const _JoanCards      = preload("res://resources/cards/cards_joan_of_arc.gd")
const _CleopatraCards = preload("res://resources/cards/cards_cleopatra.gd")
const _HeroRegistry   = preload("res://resources/heroes/hero_registry.gd")
const _GreekNormals   = preload("res://resources/enemies/greek/greek_normals.gd")

const WIN_W := 1920.0
const WIN_H := 1080.0

var _queue_label: Label
var _turn_label: Label
var _end_btn: Button
var _hero_panels: Dictionary = {}   # hero_id → {root, hp_lbl, block_lbl, energy_lbl, status_lbl}
var _enemy_panels: Array = []       # [{root, hp_lbl, block_lbl, intent_lbl, status_lbl}]
var _hand_box: HBoxContainer
var _hero_target_box: HBoxContainer
var _enemy_target_box: HBoxContainer
var _msg_label: Label

var _selected_card: Resource = null  # 카드 선택 상태 (타겟 대기)
var _selected_needs_target: String = "none"  # none / enemy / ally / self / all

func _ready() -> void:
	custom_minimum_size = Vector2(WIN_W, WIN_H)
	_build_ui()
	_setup_battle()

func _build_ui() -> void:
	# 좌상단 turn queue
	_queue_label = _make_label(Vector2(20, 20), Vector2(380, 200), 20)
	_queue_label.text = "Turn Queue"
	add_child(_queue_label)

	# 중앙 상단 차례 라벨 (현재 차례 캐릭터 이름)
	_turn_label = _make_label(Vector2(WIN_W * 0.5 - 300, 20), Vector2(600, 50), 32)
	_turn_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_turn_label)

	# 메시지 라벨 (중앙)
	_msg_label = _make_label(Vector2(WIN_W * 0.5 - 400, WIN_H * 0.45), Vector2(800, 40), 22)
	_msg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_msg_label)

	# 적 패널 컨테이너 (상단 가로 배치)
	_enemy_target_box = HBoxContainer.new()
	_enemy_target_box.position = Vector2(WIN_W * 0.5 - 400, 150)
	_enemy_target_box.size = Vector2(800, 280)
	_enemy_target_box.add_theme_constant_override("separation", 40)
	_enemy_target_box.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(_enemy_target_box)

	# 영웅 패널 컨테이너 (하단 가로 배치)
	_hero_target_box = HBoxContainer.new()
	_hero_target_box.position = Vector2(WIN_W * 0.5 - 600, 600)
	_hero_target_box.size = Vector2(1200, 200)
	_hero_target_box.add_theme_constant_override("separation", 30)
	_hero_target_box.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(_hero_target_box)

	# 핸드 (영웅 패널 아래)
	_hand_box = HBoxContainer.new()
	_hand_box.position = Vector2(20, 870)
	_hand_box.size = Vector2(WIN_W - 240, 180)
	_hand_box.add_theme_constant_override("separation", 12)
	_hand_box.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(_hand_box)

	# 차례 종료 버튼
	_end_btn = Button.new()
	_end_btn.text = "차례 종료"
	_end_btn.position = Vector2(WIN_W - 200, 900)
	_end_btn.size = Vector2(180, 80)
	_end_btn.add_theme_font_size_override("font_size", 24)
	_end_btn.pressed.connect(_on_end_pressed)
	add_child(_end_btn)

func _make_label(pos: Vector2, sz: Vector2, font_size: int) -> Label:
	var lbl := Label.new()
	lbl.position = pos
	lbl.size = sz
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", Color.WHITE)
	lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	lbl.add_theme_constant_override("outline_size", 4)
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return lbl

func _setup_battle() -> void:
	# 영웅 3 — napoleon/joan_of_arc/cleopatra. speed 차등.
	var heroes: Array = []
	var hero_cards: Dictionary = {}
	for hid: String in ["napoleon", "joan_of_arc", "cleopatra"]:
		var h: Resource = _HeroRegistry.make_hero(hid)
		heroes.append(h)
		hero_cards[hid] = _build_starter_deck(hid)
	# Speed 차등 — joan 65, napoleon 50, cleopatra 45 (테스트용)
	heroes[0].speed = 50
	heroes[1].speed = 65
	heroes[2].speed = 45

	# 적 2 — greek normals (적당한 normal 적)
	var character_default: PackedScene = load("res://scenes/components/character_default.tscn") if ResourceLoader.exists("res://scenes/components/character_default.tscn") else null
	var enemies: Array = []
	enemies.append(_GreekNormals.satyr(character_default))
	enemies.append(_GreekNormals.harpy(character_default))
	enemies[0].speed = 40
	enemies[1].speed = 55

	DeckManagerV2.setup(hero_cards)
	BattleManagerV2.setup(heroes, enemies)
	_create_hero_panels(heroes)
	_create_enemy_panels(enemies)
	_connect_signals()
	BattleManagerV2.start_battle()

func _build_starter_deck(hid: String) -> Array:
	match hid:
		"napoleon":
			return [
				_NapoleonCards._strike(), _NapoleonCards._strike(), _NapoleonCards._strike(),
				_NapoleonCards._defend(), _NapoleonCards._defend(),
				_NapoleonCards._hussar_charge(), _NapoleonCards._salvo(),
				_NapoleonCards._artillery_volley(),
			]
		"joan_of_arc":
			return [
				_JoanCards._strike(), _JoanCards._strike(),
				_JoanCards._defend(), _JoanCards._defend(),
				_JoanCards._holy_smite(), _JoanCards._holy_bolt(),
				_JoanCards._holy_touch(), _JoanCards._crusaders_faith(),
			]
		"cleopatra":
			return [
				_CleopatraCards._strike(), _CleopatraCards._strike(),
				_CleopatraCards._defend(), _CleopatraCards._defend(),
				_CleopatraCards._venom_needle(), _CleopatraCards._sandstorm(),
				_CleopatraCards._cleopatras_kiss(),
			]
	return []

func _create_hero_panels(heroes: Array) -> void:
	for h in heroes:
		var panel := Panel.new()
		panel.custom_minimum_size = Vector2(220, 160)
		var vbox := VBoxContainer.new()
		vbox.position = Vector2(8, 8)
		vbox.size = Vector2(204, 144)
		panel.add_child(vbox)
		var name_lbl := Label.new()
		name_lbl.text = h.hero_id + " (spd " + str(h.speed) + ")"
		name_lbl.add_theme_font_size_override("font_size", 16)
		vbox.add_child(name_lbl)
		var hp_lbl := Label.new()
		hp_lbl.add_theme_font_size_override("font_size", 14)
		vbox.add_child(hp_lbl)
		var block_lbl := Label.new()
		block_lbl.add_theme_font_size_override("font_size", 14)
		vbox.add_child(block_lbl)
		var energy_lbl := Label.new()
		energy_lbl.add_theme_font_size_override("font_size", 14)
		vbox.add_child(energy_lbl)
		var status_lbl := Label.new()
		status_lbl.add_theme_font_size_override("font_size", 12)
		vbox.add_child(status_lbl)
		# 클릭 = 영웅 타겟 (ally/self 카드 사용 시)
		panel.gui_input.connect(_on_hero_panel_clicked.bind(h.hero_id))
		_hero_target_box.add_child(panel)
		_hero_panels[h.hero_id] = {
			"root": panel, "hp": hp_lbl, "block": block_lbl,
			"energy": energy_lbl, "status": status_lbl, "name": name_lbl,
		}
	_refresh_all_hero_panels()

func _create_enemy_panels(enemies: Array) -> void:
	for i in range(enemies.size()):
		var enemy: Resource = enemies[i]
		var panel := Panel.new()
		panel.custom_minimum_size = Vector2(220, 220)
		var vbox := VBoxContainer.new()
		vbox.position = Vector2(8, 8)
		vbox.size = Vector2(204, 204)
		panel.add_child(vbox)
		var name_lbl := Label.new()
		name_lbl.text = enemy.enemy_name + " (spd " + str(enemy.speed) + ")"
		name_lbl.add_theme_font_size_override("font_size", 16)
		vbox.add_child(name_lbl)
		var hp_lbl := Label.new()
		hp_lbl.add_theme_font_size_override("font_size", 14)
		vbox.add_child(hp_lbl)
		var block_lbl := Label.new()
		block_lbl.add_theme_font_size_override("font_size", 14)
		vbox.add_child(block_lbl)
		var intent_lbl := Label.new()
		intent_lbl.add_theme_font_size_override("font_size", 14)
		intent_lbl.add_theme_color_override("font_color", Color.YELLOW)
		vbox.add_child(intent_lbl)
		var status_lbl := Label.new()
		status_lbl.add_theme_font_size_override("font_size", 12)
		vbox.add_child(status_lbl)
		panel.gui_input.connect(_on_enemy_panel_clicked.bind(i))
		_enemy_target_box.add_child(panel)
		_enemy_panels.append({
			"root": panel, "hp": hp_lbl, "block": block_lbl,
			"intent": intent_lbl, "status": status_lbl, "name": name_lbl,
		})
	_refresh_all_enemy_panels()

func _connect_signals() -> void:
	BattleManagerV2.turn_started.connect(_on_turn_started)
	BattleManagerV2.turn_ended.connect(_on_turn_ended)
	BattleManagerV2.queue_changed.connect(_on_queue_changed)
	BattleManagerV2.round_started.connect(_on_round_started)
	BattleManagerV2.hero_damaged.connect(_on_actor_changed)
	BattleManagerV2.hero_healed.connect(_on_actor_changed)
	BattleManagerV2.hero_died.connect(_on_any_state_changed)
	BattleManagerV2.enemy_damaged.connect(_on_actor_changed)
	BattleManagerV2.enemy_died.connect(_on_any_state_changed)
	BattleManagerV2.status_applied.connect(_on_any_state_changed)
	BattleManagerV2.battle_won.connect(_on_battle_won)
	BattleManagerV2.battle_lost.connect(_on_battle_lost)
	DeckManagerV2.hand_changed.connect(_on_hand_changed)
	DeckManagerV2.energy_changed.connect(_on_energy_changed)

func _on_turn_started(actor_id: String) -> void:
	_selected_card = null
	_selected_needs_target = "none"
	_msg_label.text = ""
	var display: String
	if actor_id.begins_with("hero:"):
		var hid: String = actor_id.substr(5)
		display = "▶ " + hid + " 의 차례"
		_end_btn.disabled = false
		_rebuild_hand(hid)
	else:
		var idx: int = actor_id.substr(6).to_int()
		var ename: String = BattleManagerV2.get_enemies()[idx].enemy_name
		display = "▶ " + ename + " 의 차례"
		_end_btn.disabled = true
		_clear_hand()
	_turn_label.text = display
	_refresh_all_hero_panels()
	_refresh_all_enemy_panels()

func _on_turn_ended(_actor_id: String) -> void:
	_clear_hand()
	_selected_card = null
	_selected_needs_target = "none"

func _on_queue_changed() -> void:
	var queue: Array = BattleManagerV2.get_turn_queue()
	var lines: Array[String] = ["Turn Queue:"]
	for i in range(queue.size()):
		var a: String = queue[i]
		if a.begins_with("hero:"):
			lines.append(str(i + 1) + ". " + a.substr(5))
		else:
			var idx: int = a.substr(6).to_int()
			lines.append(str(i + 1) + ". " + BattleManagerV2.get_enemies()[idx].enemy_name)
	_queue_label.text = "\n".join(lines)

func _on_round_started(round_num: int) -> void:
	_msg_label.text = "라운드 %d 시작" % round_num

func _on_actor_changed(_a, _b = null) -> void:
	_refresh_all_hero_panels()
	_refresh_all_enemy_panels()

func _on_any_state_changed(_a = null, _b = null, _c = null) -> void:
	_refresh_all_hero_panels()
	_refresh_all_enemy_panels()

func _on_hand_changed(hero_id: String) -> void:
	# 현재 차례 영웅이면 핸드 다시 그림
	var cur: String = BattleManagerV2.get_current_actor()
	if cur == "hero:" + hero_id:
		_rebuild_hand(hero_id)
	_refresh_hero_panel(hero_id)

func _on_energy_changed(hero_id: String, _new_energy: int) -> void:
	_refresh_hero_panel(hero_id)

func _on_battle_won() -> void:
	_msg_label.text = "★ 승리! ★"
	_end_btn.disabled = true
	_clear_hand()

func _on_battle_lost() -> void:
	_msg_label.text = "× 패배 ×"
	_end_btn.disabled = true
	_clear_hand()

func _rebuild_hand(hero_id: String) -> void:
	_clear_hand()
	for card in DeckManagerV2.get_hand(hero_id):
		var btn := Button.new()
		btn.text = "%s (%d)" % [tr(card.card_name), card.cost]
		btn.custom_minimum_size = Vector2(180, 140)
		btn.add_theme_font_size_override("font_size", 14)
		btn.pressed.connect(_on_card_clicked.bind(card))
		if not DeckManagerV2.can_play(hero_id, card):
			btn.disabled = true
		_hand_box.add_child(btn)

func _clear_hand() -> void:
	for c in _hand_box.get_children():
		c.queue_free()

func _on_card_clicked(card: Resource) -> void:
	var cur: String = BattleManagerV2.get_current_actor()
	if not cur.begins_with("hero:"):
		return
	_selected_card = card
	_selected_needs_target = _card_target_type(card)
	match _selected_needs_target:
		"none":
			_play_selected(-1, "")
		"enemy":
			_msg_label.text = "타겟 적을 클릭"
		"ally":
			_msg_label.text = "타겟 영웅을 클릭"
		_:
			_play_selected(-1, "")

func _card_target_type(card: Resource) -> String:
	# 첫 effect 기준 — DAMAGE/APPLY_STATUS+SINGLE → enemy, HEAL+target!=SELF → ally, 그 외 → none
	for eff in card.effects:
		match eff.effect_type:
			0:  # DAMAGE
				if eff.target == "SINGLE":
					return "enemy"
				return "none"
			2:  # APPLY_STATUS
				if eff.target == "SINGLE" and not eff.status_type.begins_with("power."):
					# weak/vulnerable 같은 enemy debuff
					if eff.status_type in ["weak", "vulnerable", "poison"]:
						return "enemy"
				return "none"
			7:  # HEAL
				if eff.target != "SELF":
					return "ally"
				return "none"
	return "none"

func _on_enemy_panel_clicked(event: InputEvent, idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if _selected_card != null and _selected_needs_target == "enemy":
			_play_selected(idx, "")

func _on_hero_panel_clicked(event: InputEvent, hid: String) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if _selected_card != null and _selected_needs_target == "ally":
			_play_selected(-1, hid)

func _play_selected(enemy_idx: int, hero_id: String) -> void:
	if _selected_card == null:
		return
	var ok: bool = BattleManagerV2.play_card(_selected_card, enemy_idx, hero_id)
	if ok:
		_msg_label.text = ""
	_selected_card = null
	_selected_needs_target = "none"

func _on_end_pressed() -> void:
	BattleManagerV2.end_current_turn()

func _refresh_all_hero_panels() -> void:
	for hid in _hero_panels.keys():
		_refresh_hero_panel(hid)

func _refresh_hero_panel(hid: String) -> void:
	if not _hero_panels.has(hid):
		return
	var p: Dictionary = _hero_panels[hid]
	var hp: int = BattleManagerV2.get_hero_hp(hid)
	var max_hp: int = BattleManagerV2.get_hero_max_hp(hid)
	p["hp"].text = "HP: %d / %d" % [hp, max_hp]
	p["block"].text = "Block: %d" % BattleManagerV2.get_hero_block(hid)
	p["energy"].text = "Energy: %d / %d" % [DeckManagerV2.get_energy(hid), DeckManagerV2.MAX_ENERGY]
	var s: Dictionary = BattleManagerV2.get_hero_status(hid)
	p["status"].text = _format_status(s)
	if hp <= 0:
		p["root"].modulate = Color(0.4, 0.4, 0.4)
	else:
		p["root"].modulate = Color.WHITE

func _refresh_all_enemy_panels() -> void:
	for i in range(_enemy_panels.size()):
		_refresh_enemy_panel(i)

func _refresh_enemy_panel(idx: int) -> void:
	if idx >= _enemy_panels.size():
		return
	var p: Dictionary = _enemy_panels[idx]
	var hp: int = BattleManagerV2.get_enemy_hp(idx)
	var max_hp: int = BattleManagerV2.get_enemy_max_hp(idx)
	p["hp"].text = "HP: %d / %d" % [hp, max_hp]
	p["block"].text = "Block: %d" % BattleManagerV2.get_enemy_block(idx)
	var intent: Resource = BattleManagerV2.get_enemy_current_intent(idx)
	if intent != null:
		p["intent"].text = "Next: %s %d" % [_intent_kind(intent), intent.value]
	else:
		p["intent"].text = ""
	p["status"].text = _format_status(BattleManagerV2.get_enemy_status(idx))
	if not BattleManagerV2.is_enemy_alive(idx):
		p["root"].modulate = Color(0.3, 0.3, 0.3)
	else:
		p["root"].modulate = Color.WHITE

func _intent_kind(intent: Resource) -> String:
	match intent.action_type:
		0: return "공격"
		1: return "버프"
		2: return "디버프"
		_: return "특수"

func _format_status(s: Dictionary) -> String:
	if s.is_empty():
		return ""
	var parts: Array[String] = []
	for k in s.keys():
		var v: int = s[k]
		if v > 0:
			parts.append("%s:%d" % [k, v])
	return ", ".join(parts)
