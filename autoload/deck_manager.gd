# autoload/deck_manager.gd
# 개체별 턴 시스템 — 영웅별 덱/핸드/discard/exhaust/에너지 분리.
# 모든 데이터: Dictionary[hero_id → {draw, hand, discard, exhaust, energy, pending_cost_reduction, pending_all_cost_zero, cards_played_this_turn}]
# 외부 호출자 일부 (legacy) 는 card.owner_id 자동 분기. setup_for_battle 호출 전 add_card_to_deck 도 임시 풀에 저장 후 setup 시 분배.
class_name DeckManagerClass
extends Node

var base_draw_count: int = 4
const MAX_ENERGY: int = 3

# 영웅별 데이터 — setup_for_battle 후 채워짐
var _heroes: Dictionary = {}  # hero_id → {draw, hand, discard, exhaust, energy, pending_cost_reduction, pending_all_cost_zero, cards_played_this_turn}

# 전투 외 (메타) — start_run 시 add_card_to_deck 으로 누적되는 임시 풀.
# setup_for_battle 시 owner_id 기반으로 _heroes 에 분배.
var _meta_deck: Array = []  # 전투 외 보유 카드 전체

var debug_unlimited_energy: bool = false

signal card_drawn(card: Resource)
signal card_played(card: Resource)
signal hand_changed()
signal energy_changed(new_energy: int)

# ── Legacy properties — 외부 호출자 점진 마이그레이션 + 테스트 호환 ──
# Array property 는 첫 영웅 ref 반환 (in-place .append() / .erase() 호환).
# scalar property 는 setter 도 제공 — 첫 영웅에만 적용.
var draw_pile: Array:
	get: return _first_hero_pile("draw")
var hand: Array:
	get: return _first_hero_pile("hand")
var discard_pile: Array:
	get: return _first_hero_pile("discard")
var exhaust_pile: Array:
	get: return _first_hero_pile("exhaust")
var current_energy: int:
	get:
		for hid in _heroes.keys():
			return _heroes[hid]["energy"]
		return 0
	set(value):
		for hid in _heroes.keys():
			_heroes[hid]["energy"] = value
			energy_changed.emit(value)
			return
var pending_cost_reduction: int:
	get:
		for hid in _heroes.keys():
			return _heroes[hid]["pending_cost_reduction"]
		return 0
	set(value):
		for hid in _heroes.keys():
			_heroes[hid]["pending_cost_reduction"] = value
			return
var pending_all_cost_zero: bool:
	get:
		for hid in _heroes.keys():
			return _heroes[hid]["pending_all_cost_zero"]
		return false
	set(value):
		for hid in _heroes.keys():
			_heroes[hid]["pending_all_cost_zero"] = value
			return

# 첫 영웅의 pile 직접 ref (in-place 수정 호환). _heroes 비어있으면 fallback.
func _first_hero_pile(pile_name: String) -> Array:
	if _heroes.is_empty():
		return _meta_deck if pile_name == "draw" else []
	for hid in _heroes.keys():
		return _heroes[hid][pile_name]
	return []

# 모든 영웅 pile 합산 (read-only) — 외부 합산 API 가 여전히 필요한 경우.
func _all_pile(pile_name: String) -> Array:
	if _heroes.is_empty():
		return _meta_deck.duplicate() if pile_name == "draw" else []
	var all: Array = []
	for hid in _heroes.keys():
		all.append_array(_heroes[hid][pile_name])
	return all

# ── 전투 초기화 ─────────────────────────────────────
func setup_for_battle(hero_ids: Array) -> void:
	_heroes.clear()
	for hid in hero_ids:
		_heroes[hid] = _new_hero_entry()
	# meta_deck 의 카드를 owner_id 기반으로 _heroes 에 분배
	for card in _meta_deck:
		var hid: String = card.owner_id
		if not _heroes.has(hid):
			# 영웅 없으면 무시 (사망 상태이지만 사용 안 함)
			continue
		(_heroes[hid]["draw"] as Array).append(card)
	for hid in _heroes.keys():
		(_heroes[hid]["draw"] as Array).shuffle()

func _new_hero_entry() -> Dictionary:
	return {
		"draw": [],
		"hand": [],
		"discard": [],
		"exhaust": [],
		"energy": 0,
		"pending_cost_reduction": 0,
		"pending_all_cost_zero": false,
		"cards_played_this_turn": 0,
		"draws_this_turn": 0,
	}

# ── 본인 차례 시작/종료 ──────────────────────────────
func start_hero_turn(hero_id: String) -> void:
	if not _heroes.has(hero_id):
		return
	var entry: Dictionary = _heroes[hero_id]
	entry["energy"] = MAX_ENERGY
	entry["pending_cost_reduction"] = 0
	entry["pending_all_cost_zero"] = false
	entry["cards_played_this_turn"] = 0
	entry["draws_this_turn"] = 0
	energy_changed.emit(entry["energy"])
	# innate 카드 먼저
	var innate_count: int = 0
	for i in range((entry["draw"] as Array).size() - 1, -1, -1):
		if (entry["draw"] as Array)[i].get("is_innate") == true:
			var c = (entry["draw"] as Array)[i]
			(entry["draw"] as Array).remove_at(i)
			(entry["hand"] as Array).append(c)
			card_drawn.emit(c)
			innate_count += 1
	draw_cards_h(hero_id, max(0, base_draw_count - innate_count))

func end_hero_turn(hero_id: String) -> void:
	if not _heroes.has(hero_id):
		return
	var entry: Dictionary = _heroes[hero_id]
	var retained: Array = []
	for card in entry["hand"]:
		if card.get("is_retain") == true:
			retained.append(card)
		elif card.get("is_ethereal") == true:
			(entry["exhaust"] as Array).append(card)
		else:
			(entry["discard"] as Array).append(card)
	entry["hand"] = retained
	hand_changed.emit()

func draw_cards_h(hero_id: String, count: int) -> void:
	if not _heroes.has(hero_id):
		return
	var entry: Dictionary = _heroes[hero_id]
	for i in range(count):
		if (entry["draw"] as Array).is_empty():
			_reshuffle(hero_id)
		if (entry["draw"] as Array).is_empty():
			break
		var card: Resource = (entry["draw"] as Array).pop_back()
		(entry["hand"] as Array).append(card)
		entry["draws_this_turn"] += 1
		card_drawn.emit(card)
	hand_changed.emit()

# Legacy — 첫 영웅 또는 모든 영웅 분배. 외부 호출자 (draw_cards(count)) 보존.
func draw_cards(count: int) -> void:
	# 첫 영웅에만 (legacy 의미)
	for hid in _heroes.keys():
		draw_cards_h(hid, count)
		return

func _reshuffle(hero_id: String) -> void:
	var entry: Dictionary = _heroes[hero_id]
	entry["draw"] = (entry["discard"] as Array).duplicate()
	(entry["draw"] as Array).shuffle()
	(entry["discard"] as Array).clear()

# ── 카드 사용 / can_play ────────────────────────────
func can_play(card: Resource) -> bool:
	# owner_id 기반 자동 분기 (legacy 호환)
	if card == null:
		return false
	return can_play_hero(card.owner_id, card)

func can_play_hero(hero_id: String, card: Resource) -> bool:
	if not _heroes.has(hero_id):
		return false
	var entry: Dictionary = _heroes[hero_id]
	if debug_unlimited_energy:
		return (entry["hand"] as Array).has(card)
	if entry["pending_all_cost_zero"]:
		return (entry["hand"] as Array).has(card)
	var effective_cost: int = max(0, card.cost - entry["pending_cost_reduction"])
	return (entry["hand"] as Array).has(card) and entry["energy"] >= effective_cost

func play_card(card: Resource) -> bool:
	return play_card_hero(card.owner_id, card)

func play_card_hero(hero_id: String, card: Resource) -> bool:
	if not can_play_hero(hero_id, card):
		return false
	var entry: Dictionary = _heroes[hero_id]
	var effective_cost: int = 0 if entry["pending_all_cost_zero"] else max(0, card.cost - entry["pending_cost_reduction"])
	entry["pending_cost_reduction"] = 0
	if not debug_unlimited_energy:
		entry["energy"] -= effective_cost
	energy_changed.emit(entry["energy"])
	(entry["hand"] as Array).erase(card)
	entry["cards_played_this_turn"] += 1
	if card.get("card_type") == 2 or card.get("is_exhaust") == true:
		(entry["exhaust"] as Array).append(card)
	else:
		(entry["discard"] as Array).append(card)
	card_played.emit(card)
	hand_changed.emit()
	return true

func exhaust_card(card: Resource) -> void:
	var hid: String = card.owner_id
	if not _heroes.has(hid):
		return
	var entry: Dictionary = _heroes[hid]
	(entry["hand"] as Array).erase(card)
	(entry["exhaust"] as Array).append(card)
	hand_changed.emit()

func discard_card(card: Resource) -> void:
	var hid: String = card.owner_id
	if not _heroes.has(hid):
		return
	var entry: Dictionary = _heroes[hid]
	if not (entry["hand"] as Array).has(card):
		return
	(entry["hand"] as Array).erase(card)
	(entry["discard"] as Array).append(card)
	hand_changed.emit()

# ── Getters (영웅별 + 통합) ───────────────────────
func get_hand(hero_id: String) -> Array:
	return (_heroes[hero_id]["hand"] as Array) if _heroes.has(hero_id) else []

func get_energy(hero_id: String) -> int:
	return _heroes[hero_id]["energy"] if _heroes.has(hero_id) else 0

func get_pending_cost_reduction(hero_id: String) -> int:
	return _heroes[hero_id]["pending_cost_reduction"] if _heroes.has(hero_id) else 0

func set_pending_cost_reduction(hero_id: String, val: int) -> void:
	if _heroes.has(hero_id):
		_heroes[hero_id]["pending_cost_reduction"] = val

func add_pending_cost_reduction(hero_id: String, delta: int) -> void:
	if _heroes.has(hero_id):
		_heroes[hero_id]["pending_cost_reduction"] += delta

func set_pending_all_cost_zero(hero_id: String, val: bool) -> void:
	if _heroes.has(hero_id):
		_heroes[hero_id]["pending_all_cost_zero"] = val

func add_energy_h(hero_id: String, delta: int) -> void:
	if _heroes.has(hero_id):
		_heroes[hero_id]["energy"] += delta
		energy_changed.emit(_heroes[hero_id]["energy"])

func set_energy_h(hero_id: String, val: int) -> void:
	if _heroes.has(hero_id):
		_heroes[hero_id]["energy"] = val
		energy_changed.emit(val)

func get_cards_played_this_turn(hero_id: String) -> int:
	return _heroes[hero_id]["cards_played_this_turn"] if _heroes.has(hero_id) else 0

func get_draws_this_turn(hero_id: String) -> int:
	return _heroes[hero_id]["draws_this_turn"] if _heroes.has(hero_id) else 0

func get_draw_size(hero_id: String) -> int:
	return (_heroes[hero_id]["draw"] as Array).size() if _heroes.has(hero_id) else 0

func get_discard_size(hero_id: String) -> int:
	return (_heroes[hero_id]["discard"] as Array).size() if _heroes.has(hero_id) else 0

# 통합 hand — 모든 영웅 hand 합쳐서 (legacy 호환)
func get_all_hands() -> Array:
	var all: Array = []
	for hid in _heroes.keys():
		all.append_array(_heroes[hid]["hand"])
	return all

# ── meta deck (전투 외) ─────────────────────────────
func add_card_to_deck(card: Resource) -> void:
	# 도감 — 획득 카드는 발견 처리 (영구 저장). 모든 카드 획득 경로가 이 함수를 통과.
	# 키 = owner_id|card_name (카운터 등 공유 card_name 을 영웅별로 구분).
	# 헤드리스 테스트(_init 단계)에선 main_loop 이 아직 null 일 수 있어 방어.
	if card != null and card.card_name != "":
		var ml := Engine.get_main_loop()
		if ml is SceneTree:
			var pm = (ml as SceneTree).root.get_node_or_null("ProgressManager")
			if pm != null:
				pm.discover_card(card.owner_id + "|" + card.card_name)
	# 전투 외 — meta_deck 에 누적. 전투 시작 시 owner_id 기반 분배.
	# 전투 중 — owner 가 현재 차례 영웅이면 hand 로 (디버그 즉시 사용), 아니면 discard 로.
	if _heroes.is_empty():
		_meta_deck.append(card)
		return
	var hid: String = card.owner_id
	if not _heroes.has(hid):
		_meta_deck.append(card)
		hand_changed.emit()
		return
	var bm = Engine.get_main_loop().root.get_node_or_null("BattleManager")
	var current_hid: String = bm.get_current_hero_id() if bm and bm.has_method("get_current_hero_id") else ""
	if current_hid == hid:
		(_heroes[hid]["hand"] as Array).append(card)
	else:
		(_heroes[hid]["discard"] as Array).append(card)
	hand_changed.emit()

func get_meta_deck() -> Array:
	return _meta_deck.duplicate()

func get_full_deck() -> Array:
	# meta + 모든 영웅의 draw/hand/discard/exhaust 합산 (legacy 호환).
	# 보통 전투 외 시 호출 → _heroes 비어있으면 _meta_deck 만.
	if _heroes.is_empty():
		return _meta_deck.duplicate()
	var full: Array = []
	for hid in _heroes.keys():
		full.append_array(_heroes[hid]["draw"])
		full.append_array(_heroes[hid]["hand"])
		full.append_array(_heroes[hid]["discard"])
		full.append_array(_heroes[hid]["exhaust"])
	return full

func discard_random(n: int) -> void:
	# 모든 영웅 핸드 합쳐서 무작위 n장. 영웅별 discard 로.
	var all_hand_refs: Array = []  # [(hid, card)]
	for hid in _heroes.keys():
		for c in _heroes[hid]["hand"]:
			all_hand_refs.append([hid, c])
	for _i in range(min(n, all_hand_refs.size())):
		var pick = all_hand_refs[randi() % all_hand_refs.size()]
		var hid: String = pick[0]
		var card: Resource = pick[1]
		(_heroes[hid]["hand"] as Array).erase(card)
		(_heroes[hid]["discard"] as Array).append(card)
		all_hand_refs.erase(pick)
	hand_changed.emit()

# ── 직렬화 v3 ────────────────────────────────────
func to_dict() -> Dictionary:
	# 전투 외 — _meta_deck 직렬화. 전투 중이면 모든 영웅 합쳐서.
	var cards: Array = _meta_deck if _heroes.is_empty() else get_full_deck()
	var card_data := []
	for card in cards:
		var effects_data := []
		for eff in card.effects:
			effects_data.append({
				"effect_type": eff.effect_type,
				"value": eff.value,
				"target": eff.target,
				"status_type": eff.status_type,
				"bonus_value": eff.bonus_value,
			})
		card_data.append({
			"card_name": card.card_name,
			"owner_id": card.owner_id,
			"cost": card.cost,
			"play_animation": card.play_animation,
			"upgrade_level": card.upgrade_level,
			"effects": effects_data,
		})
	return {"version": 3, "base_draw_count": base_draw_count, "full_deck": card_data}

func from_dict(data: Dictionary) -> void:
	clear()
	base_draw_count = data.get("base_draw_count", 4)
	var CardRes = load("res://resources/card_resource.gd")
	var EffRes = load("res://resources/effect_resource.gd")
	for cd in data.get("full_deck", []):
		var card: Resource = CardRes.new()
		card.card_name = cd["card_name"]
		card.owner_id = cd["owner_id"]
		card.cost = cd["cost"]
		card.play_animation = cd.get("play_animation", "idle")
		card.upgrade_level = cd.get("upgrade_level", 0)
		var effects := []
		for ed in cd.get("effects", []):
			var eff: Resource = EffRes.new()
			eff.effect_type = ed["effect_type"]
			eff.value = ed["value"]
			eff.target = ed.get("target", "SINGLE")
			eff.status_type = ed.get("status_type", "")
			eff.bonus_value = ed.get("bonus_value", 0)
			effects.append(eff)
		card.effects = effects
		_meta_deck.append(card)

func remove_from_deck(card: Resource) -> bool:
	# meta + 모든 영웅 풀에서 검색
	if _meta_deck.has(card):
		_meta_deck.erase(card)
		return true
	for hid in _heroes.keys():
		for pile in ["draw", "discard", "hand", "exhaust"]:
			if (_heroes[hid][pile] as Array).has(card):
				(_heroes[hid][pile] as Array).erase(card)
				return true
	return false

func remove_random_card() -> bool:
	# 전투 외 — meta_deck 에서. 전투 중이면 모든 영웅 풀에서.
	if _heroes.is_empty():
		if _meta_deck.is_empty():
			return false
		_meta_deck.remove_at(randi() % _meta_deck.size())
		return true
	var pools: Array = []  # [(hid, pile_name, idx)]
	for hid in _heroes.keys():
		for pile in ["draw", "hand", "discard", "exhaust"]:
			var arr: Array = _heroes[hid][pile]
			for i in range(arr.size()):
				pools.append([hid, pile, i])
	if pools.is_empty():
		return false
	var pick = pools[randi() % pools.size()]
	(_heroes[pick[0]][pick[1]] as Array).remove_at(pick[2])
	return true

func consolidate_for_battle() -> void:
	# 모든 영웅의 hand/discard/exhaust 를 draw 로 합치고 shuffle.
	# 전투 종료 시 호출.
	for hid in _heroes.keys():
		var entry: Dictionary = _heroes[hid]
		(entry["draw"] as Array).append_array(entry["hand"])
		(entry["draw"] as Array).append_array(entry["discard"])
		(entry["draw"] as Array).append_array(entry["exhaust"])
		entry["hand"].clear()
		entry["discard"].clear()
		entry["exhaust"].clear()
		(entry["draw"] as Array).shuffle()
	hand_changed.emit()

func clear() -> void:
	_heroes.clear()
	_meta_deck.clear()

# ── Legacy 함수 wrapper — 외부 호출자 점진 마이그레이션 ──
# start_turn() (인자 없음) → 모든 영웅 차례 시작 (의미 변형: 통합 → 영웅별 합)
func start_turn() -> void:
	for hid in _heroes.keys():
		start_hero_turn(hid)

# draw_cards_legacy — draw_cards(count) 와 동의 (deprecated alias)
func draw_cards_legacy(count: int) -> void:
	draw_cards(count)

# discard_hand() — 모든 영웅 핸드 처리
func discard_hand() -> void:
	for hid in _heroes.keys():
		end_hero_turn(hid)
