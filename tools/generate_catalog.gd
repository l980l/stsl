# tools/generate_catalog.gd
# 실행: "H:/Program Files/Godot/Godot_v4.6.2-stable_win64_console.exe" --headless -s tools/generate_catalog.gd
# 주의: SceneTree 모드 — autoload 미초기화. 업그레이드 공식은 game_manager.gd:315-353 기준 직접 포팅.
extends SceneTree

const OUT_DIR := "res://docs/catalog/"

const NapoleonCards   = preload("res://resources/cards/cards_napoleon.gd")
const CleopatraCards  = preload("res://resources/cards/cards_cleopatra.gd")
const YiSunSinCards   = preload("res://resources/cards/cards_yi_sun_sin.gd")
const JoanCards       = preload("res://resources/cards/cards_joan_of_arc.gd")
const GenghisCards    = preload("res://resources/cards/cards_genghis_khan.gd")
const MusashiCards    = preload("res://resources/cards/cards_musashi.gd")

const GreekNormals    = preload("res://resources/enemies/greek/greek_normals.gd")
const GreekAct1       = preload("res://resources/enemies/greek/greek_act1.gd")
const GreekAct2       = preload("res://resources/enemies/greek/greek_act2.gd")
const GreekAct3       = preload("res://resources/enemies/greek/greek_act3.gd")
const NorseNormals    = preload("res://resources/enemies/norse/norse_normals.gd")
const NorseAct1       = preload("res://resources/enemies/norse/norse_act1.gd")
const NorseAct2       = preload("res://resources/enemies/norse/norse_act2.gd")
const NorseAct3       = preload("res://resources/enemies/norse/norse_act3.gd")
const EgyptNormals    = preload("res://resources/enemies/egyptian/egyptian_normals.gd")
const EgyptAct1       = preload("res://resources/enemies/egyptian/egyptian_act1.gd")
const EgyptAct2       = preload("res://resources/enemies/egyptian/egyptian_act2.gd")
const EgyptAct3       = preload("res://resources/enemies/egyptian/egyptian_act3.gd")
const BuddhistNormals = preload("res://resources/enemies/buddhist/buddhist_normals.gd")
const BuddhistAct1    = preload("res://resources/enemies/buddhist/buddhist_act1.gd")
const BuddhistAct2    = preload("res://resources/enemies/buddhist/buddhist_act2.gd")
const BuddhistAct3    = preload("res://resources/enemies/buddhist/buddhist_act3.gd")
const DaoistNormals   = preload("res://resources/enemies/daoist/daoist_normals.gd")
const DaoistAct1      = preload("res://resources/enemies/daoist/daoist_act1.gd")
const DaoistAct2      = preload("res://resources/enemies/daoist/daoist_act2.gd")
const DaoistAct3      = preload("res://resources/enemies/daoist/daoist_act3.gd")
const JapaneseNormals = preload("res://resources/enemies/japanese/japanese_normals.gd")
const JapaneseAct1    = preload("res://resources/enemies/japanese/japanese_act1.gd")
const JapaneseAct2    = preload("res://resources/enemies/japanese/japanese_act2.gd")
const JapaneseAct3    = preload("res://resources/enemies/japanese/japanese_act3.gd")

const RelicsGd        = preload("res://resources/relics/relics.gd")
const EventsAct1      = preload("res://resources/events/events_act1.gd")
const EventsAct2      = preload("res://resources/events/events_act2.gd")
const EventsAct3      = preload("res://resources/events/events_act3.gd")
const EventsBuddhist  = preload("res://resources/events/events_buddhist.gd")
const EventsJapanese  = preload("res://resources/events/events_japanese.gd")
const EventsDaoist    = preload("res://resources/events/events_daoist.gd")

const CardRes  = preload("res://resources/card_resource.gd")
const EffRes   = preload("res://resources/effect_resource.gd")
const IntentRes = preload("res://resources/intent_resource.gd")
const RelicRes = preload("res://resources/relic_resource.gd")
const ChoiceRes = preload("res://resources/event_choice_resource.gd")

func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	_generate_cards()
	_generate_enemies()
	_generate_relics()
	_generate_events()
	_write_readme()
	print("=== 도감 생성 완료 → ", OUT_DIR)
	quit()

# ─────────────────────────────────────────
# 업그레이드 공식 (game_manager.gd:315-353 동기화)
# ─────────────────────────────────────────

func _apply_upgrade(card: Resource, level: int) -> Resource:
	if level == 0:
		return card
	var c: Resource = card.duplicate(true)
	var rate: float = 0.0
	match c.rarity:
		CardRes.Rarity.UNCOMMON:  rate = 0.10
		CardRes.Rarity.RARE:      rate = 0.12
		CardRes.Rarity.LEGENDARY: rate = 0.14
		CardRes.Rarity.DIVINE:    rate = 0.16
	var PERCENT_TYPES: Array = [
		EffRes.EffectType.DAMAGE, EffRes.EffectType.BLOCK,
		EffRes.EffectType.HEAL, EffRes.EffectType.BLOCK_ALL,
		EffRes.EffectType.HEAL_ALL, EffRes.EffectType.FORMATION_BLOCK,
		EffRes.EffectType.COUNTER_BLOCK, EffRes.EffectType.POISON_BURST,
		EffRes.EffectType.CONSUME_MORALE, EffRes.EffectType.CONDITIONAL_DMG,
	]
	var INT_TYPES: Array = [
		EffRes.EffectType.DRAW, EffRes.EffectType.ENERGY,
		EffRes.EffectType.GAIN_MORALE, EffRes.EffectType.APPLY_STATUS,
		EffRes.EffectType.CHARM, EffRes.EffectType.COST_NEXT,
		EffRes.EffectType.SUMMON_TOKEN,
	]
	for i in range(level):
		for effect in c.effects:
			if effect.effect_type in PERCENT_TYPES:
				var lv: int = i + 1
				effect.value = int(effect.base_value * (1.0 + rate * lv))
				effect.bonus_value = int(effect.base_bonus_value * (1.0 + rate * lv))
			elif effect.effect_type == EffRes.EffectType.APPLY_STATUS and effect.status_type.begins_with("power."):
				effect.value = effect.base_value + (i + 1) * 5
			elif effect.effect_type in INT_TYPES:
				effect.value = effect.base_value + (i + 1)
				effect.bonus_value = effect.base_bonus_value + (i + 1) if effect.base_bonus_value > 0 else 0
	return c

func _format_effects(card: Resource) -> String:
	var parts: Array = []
	for e in card.effects:
		parts.append(e.display_text())
	if card.is_exhaust:  parts.append("[%s]" % tr("card.tag.exhaust"))
	if card.is_ethereal: parts.append("[%s]" % tr("card.tag.ethereal"))
	if card.is_retain:   parts.append("[%s]" % tr("card.tag.retain"))
	if card.is_innate:   parts.append("[%s]" % tr("card.tag.innate"))
	return " ".join(parts)

# ─────────────────────────────────────────
# 이름 변환 헬퍼
# ─────────────────────────────────────────

func _rarity_name(r: int) -> String:
	match r:
		CardRes.Rarity.COMMON:    return "COMMON"
		CardRes.Rarity.UNCOMMON:  return "UNCOMMON"
		CardRes.Rarity.RARE:      return "RARE"
		CardRes.Rarity.LEGENDARY: return "LEGENDARY"
		CardRes.Rarity.DIVINE:    return "DIVINE"
	return "?"

func _card_type_name(t: int) -> String:
	match t:
		CardRes.CardType.ATTACK: return "공격"
		CardRes.CardType.SKILL:  return "기술"
		CardRes.CardType.POWER:  return "권능"
	return "?"

func _action_type_name(t: int) -> String:
	match t:
		IntentRes.ActionType.ATTACK: return "ATK"
		IntentRes.ActionType.BUFF:   return "BUFF"
		IntentRes.ActionType.DEBUFF: return "DEBUFF"
		IntentRes.ActionType.SPECIAL: return "SPECIAL"
	return "?"

func _target_name(t: int) -> String:
	match t:
		IntentRes.TargetType.RANDOM:      return "RANDOM"
		IntentRes.TargetType.ALL:         return "ALL"
		IntentRes.TargetType.LOWEST_HP:   return "LOWEST_HP"
		IntentRes.TargetType.LAST_ATTACKER: return "LAST_ATK"
	return "?"

func _trigger_name(t: int) -> String:
	match t:
		RelicRes.TriggerType.PASSIVE:           return "PASSIVE"
		RelicRes.TriggerType.BATTLE_START:      return "BATTLE_START"
		RelicRes.TriggerType.PLAYER_TURN_START: return "TURN_START"
		RelicRes.TriggerType.PLAYER_TURN_END:   return "TURN_END"
		RelicRes.TriggerType.BATTLE_WIN:        return "BATTLE_WIN"
		RelicRes.TriggerType.ON_HERO_DAMAGED:   return "ON_DAMAGED"
	return "?"

func _relic_effect_name(t: int) -> String:
	match t:
		RelicRes.EffectType.HEAL:               return "HEAL"
		RelicRes.EffectType.ENERGY:             return "ENERGY"
		RelicRes.EffectType.DRAW:               return "DRAW"
		RelicRes.EffectType.APPLY_STATUS_ENEMY: return "STATUS_ENEMY"
		RelicRes.EffectType.MAX_HP:             return "MAX_HP"
		RelicRes.EffectType.RECOVER_CARD:       return "RECOVER_CARD"
		RelicRes.EffectType.GAIN_MORALE:        return "MORALE"
		RelicRes.EffectType.COST_REDUCTION:     return "COST_DOWN"
		RelicRes.EffectType.BLOCK:              return "BLOCK"
		RelicRes.EffectType.DAMAGE_HERO:        return "DMG_HERO"
	return "?"

func _choice_effect_name(t: int) -> String:
	match t:
		ChoiceRes.EffectType.NONE:          return "없음"
		ChoiceRes.EffectType.GOLD:          return "골드"
		ChoiceRes.EffectType.HEAL:          return "HP회복"
		ChoiceRes.EffectType.DRAW_UP:       return "드로우+1(영구)"
		ChoiceRes.EffectType.REMOVE_CARD:   return "카드제거"
		ChoiceRes.EffectType.ADD_RELIC:     return "렐릭추가"
		ChoiceRes.EffectType.ADD_HERO:      return "영웅추가"
		ChoiceRes.EffectType.ADD_RELIC_GAMBLE: return "랜덤렐릭"
		ChoiceRes.EffectType.TRIGGER_BATTLE: return "전투"
		ChoiceRes.EffectType.ADD_CARD:      return "카드추가"
		ChoiceRes.EffectType.MULTI:         return "다중효과"
	return "?"

# ─────────────────────────────────────────
# 파일 쓰기 헬퍼
# ─────────────────────────────────────────

func _write_text(rel_path: String, text: String) -> void:
	var abs_path: String = ProjectSettings.globalize_path(OUT_DIR + rel_path)
	var f := FileAccess.open(abs_path, FileAccess.WRITE)
	if f:
		f.store_string(text)
		f.close()
		print("  → ", abs_path)
	else:
		printerr("파일 쓰기 실패: ", abs_path)

func _write_csv(rel_path: String, rows: Array) -> void:
	var lines: PackedStringArray = []
	for row in rows:
		var cells: Array = []
		for cell in row:
			var s: String = str(cell)
			if "," in s or "\"" in s or "\n" in s:
				s = "\"" + s.replace("\"", "\"\"") + "\""
			cells.append(s)
		lines.append(",".join(cells))
	var abs_path: String = ProjectSettings.globalize_path(OUT_DIR + rel_path)
	var f := FileAccess.open(abs_path, FileAccess.WRITE)
	if f:
		# UTF-8 BOM — 엑셀에서 한글 깨짐 방지
		f.store_8(0xEF); f.store_8(0xBB); f.store_8(0xBF)
		f.store_string("\n".join(lines) + "\n")
		f.close()
		print("  → ", abs_path)
	else:
		printerr("파일 쓰기 실패: ", abs_path)

# ─────────────────────────────────────────
# 카드 도감
# ─────────────────────────────────────────

func _generate_cards() -> void:
	var heroes: Array = [
		{ "id": "napoleon",     "name": "나폴레옹 (Napoleon)",       "cls": NapoleonCards  },
		{ "id": "cleopatra",    "name": "클레오파트라 (Cleopatra)",    "cls": CleopatraCards },
		{ "id": "yi_sun_sin",   "name": "이순신 (Yi Sun-sin)",        "cls": YiSunSinCards  },
		{ "id": "joan_of_arc",  "name": "잔 다르크 (Joan of Arc)",    "cls": JoanCards      },
		{ "id": "genghis_khan", "name": "칭기즈칸 (Genghis Khan)",   "cls": GenghisCards   },
		{ "id": "musashi",      "name": "미야모토 무사시 (Musashi)",   "cls": MusashiCards   },
	]

	var md: String = "# 카드 도감 (자동 생성)\n\n"
	md += "> 이 파일은 `tools/generate_catalog.gd`로 자동 생성됩니다. 직접 수정 금지.\n"
	md += "> 재생성: `godot --headless -s tools/generate_catalog.gd`\n\n"

	var csv_rows: Array = [["영웅", "이름", "코스트", "타입", "희귀도", "최대강화", "효과_0강", "효과_1강", "효과_2강"]]

	for hero in heroes:
		var cls = hero["cls"]
		md += "## %s\n\n" % hero["name"]

		# 시작 덱
		var starter: Array = cls.starter_deck()
		var starter_count: Dictionary = {}
		for c in starter:
			starter_count[c.card_name] = starter_count.get(c.card_name, 0) + 1
		var starter_parts: Array = []
		for cname in starter_count:
			starter_parts.append("%s ×%d" % [tr(cname), starter_count[cname]])
		md += "### 시작 덱\n- %s\n\n" % ", ".join(starter_parts)

		# 시작 덱 카드도 CSV에 추가 (중복 제거)
		var seen_starters: Dictionary = {}
		for card in starter:
			if card.card_name in seen_starters:
				continue
			seen_starters[card.card_name] = true
			var max_lv: int = card.max_upgrade_level()
			var eff0: String = _format_effects(card)
			var eff1: String = "—" if max_lv < 1 else _format_effects(_apply_upgrade(card, 1))
			var eff2: String = "—" if max_lv < 2 else _format_effects(_apply_upgrade(card, 2))
			csv_rows.append([
				hero["id"], tr(card.card_name), card.cost,
				_card_type_name(card.card_type),
				_rarity_name(card.rarity),
				max_lv, eff0, eff1 if max_lv >= 1 else "", eff2 if max_lv >= 2 else ""
			])

		# 카드 풀
		var pool: Array = cls.pool()
		md += "### 카드 풀 (%d종)\n\n" % pool.size()
		md += "| 이름 | 코스트 | 타입 | 희귀도 | 0강 | 1강 | 2강 |\n"
		md += "|------|--------|------|--------|-----|-----|-----|\n"

		for card in pool:
			var max_lv: int = card.max_upgrade_level()
			var eff0: String = _format_effects(card)
			var eff1: String = "—" if max_lv < 1 else _format_effects(_apply_upgrade(card, 1))
			var eff2: String = "—" if max_lv < 2 else _format_effects(_apply_upgrade(card, 2))
			md += "| %s | %d | %s | %s | %s | %s | %s |\n" % [
				tr(card.card_name), card.cost,
				_card_type_name(card.card_type),
				_rarity_name(card.rarity),
				eff0, eff1, eff2
			]
			csv_rows.append([
				hero["id"], tr(card.card_name), card.cost,
				_card_type_name(card.card_type),
				_rarity_name(card.rarity),
				max_lv, eff0, eff1 if max_lv >= 1 else "", eff2 if max_lv >= 2 else ""
			])
		md += "\n"

	_write_text("cards.md", md)
	_write_csv("cards.csv", csv_rows)

# ─────────────────────────────────────────
# 적 도감
# ─────────────────────────────────────────

func _format_intent(intent: Resource) -> String:
	var s: String = _action_type_name(intent.action_type)
	if intent.value > 0:
		s += " %d" % intent.value
	if intent.status_type != "" and intent.status_type != "weak":
		s += "(%s)" % intent.status_type
	elif intent.action_type in [IntentRes.ActionType.DEBUFF, IntentRes.ActionType.BUFF] and intent.status_type == "weak":
		s += "(weak)"
	if intent.action_type == IntentRes.ActionType.ATTACK or intent.action_type == IntentRes.ActionType.DEBUFF:
		if intent.value > 0 or intent.action_type == IntentRes.ActionType.DEBUFF:
			s += " [%s]" % _target_name(intent.target)
	if intent.condition != "":
		s += " <%s>" % intent.condition
	return s

func _format_pattern(pattern: Array) -> String:
	var parts: Array = []
	for intent in pattern:
		parts.append(_format_intent(intent))
	return " → ".join(parts)

func _enemy_section_md(enemy: Resource, act: int, category: String) -> String:
	var s: String = "### %s (HP %d)\n" % [enemy.enemy_name, enemy.max_hp]
	if enemy.phase_thresholds.size() == 0:
		s += "**인텐트**: %s\n\n" % _format_pattern(enemy.intent_pattern)
	else:
		for pi in range(enemy.phase_patterns.size()):
			var threshold_str: String = ""
			if pi < enemy.phase_thresholds.size():
				threshold_str = "HP ≤ %.0f%%" % (enemy.phase_thresholds[pi] * 100)
			else:
				threshold_str = "최종 페이즈"
			s += "**Phase %d** (%s): %s\n\n" % [pi, threshold_str, _format_pattern(enemy.phase_patterns[pi])]
	return s

func _enemy_csv_rows(enemy: Resource, act: int, category: String) -> Array:
	var rows: Array = []
	if enemy.phase_thresholds.size() == 0:
		for ti in range(enemy.intent_pattern.size()):
			var intent: Resource = enemy.intent_pattern[ti]
			rows.append([act, category, enemy.enemy_name, enemy.max_hp, 0, ti + 1,
				_action_type_name(intent.action_type), intent.value,
				_target_name(intent.target) if intent.action_type in [IntentRes.ActionType.ATTACK, IntentRes.ActionType.DEBUFF] else "",
				intent.status_type, intent.condition])
	else:
		for pi in range(enemy.phase_patterns.size()):
			var pattern: Array = enemy.phase_patterns[pi]
			for ti in range(pattern.size()):
				var intent: Resource = pattern[ti]
				rows.append([act, category, enemy.enemy_name, enemy.max_hp, pi, ti + 1,
					_action_type_name(intent.action_type), intent.value,
					_target_name(intent.target) if intent.action_type in [IntentRes.ActionType.ATTACK, IntentRes.ActionType.DEBUFF] else "",
					intent.status_type, intent.condition])
	return rows

func _gen_mythology(md: String, csv_rows: Array, act_num: int, title: String,
		normals: Array, elites1: Array, boss1: Resource,
		elites2: Array, boss2: Resource, elites3: Array, boss3: Resource) -> String:
	md += "## %s\n\n" % title
	md += "### 일반 적\n\n"
	for e in normals:
		md += _enemy_section_md(e, act_num, "normal")
		csv_rows.append_array(_enemy_csv_rows(e, act_num, "normal"))
	md += "### Act 1 엘리트\n\n"
	for e in elites1:
		md += _enemy_section_md(e, act_num, "elite")
		csv_rows.append_array(_enemy_csv_rows(e, act_num, "elite"))
	md += "### Act 1 보스\n\n"
	md += _enemy_section_md(boss1, act_num, "boss")
	csv_rows.append_array(_enemy_csv_rows(boss1, act_num, "boss"))
	md += "### Act 2 엘리트\n\n"
	for e in elites2:
		md += _enemy_section_md(e, act_num + 1, "elite")
		csv_rows.append_array(_enemy_csv_rows(e, act_num + 1, "elite"))
	md += "### Act 2 보스\n\n"
	md += _enemy_section_md(boss2, act_num + 1, "boss")
	csv_rows.append_array(_enemy_csv_rows(boss2, act_num + 1, "boss"))
	md += "### Act 3 엘리트\n\n"
	for e in elites3:
		md += _enemy_section_md(e, act_num + 2, "elite")
		csv_rows.append_array(_enemy_csv_rows(e, act_num + 2, "elite"))
	md += "### Act 3 보스\n\n"
	md += _enemy_section_md(boss3, act_num + 2, "boss")
	csv_rows.append_array(_enemy_csv_rows(boss3, act_num + 2, "boss"))
	return md

func _generate_enemies() -> void:
	var md: String = "# 적 도감 (자동 생성)\n\n"
	md += "> 이 파일은 `tools/generate_catalog.gd`로 자동 생성됩니다. 직접 수정 금지.\n\n"
	var csv_rows: Array = [["Act", "분류", "이름", "HP", "페이즈", "턴", "액션", "값", "타겟", "상태", "조건"]]

	# 그리스 신화
	md = _gen_mythology(md, csv_rows, 1, "그리스 신화 (Greek)",
		[GreekNormals.satyr(null), GreekNormals.harpy(null), GreekNormals.cyclops(null),
		 GreekNormals.snake(null), GreekNormals.cerberus(null), GreekNormals.myrmidon(null)],
		[GreekAct1.minotaur(null), GreekAct1.medusa(null), GreekAct1.gorgon(null), GreekAct1.scylla(null)],
		GreekAct1.hydra(null),
		[GreekAct2.cerberus(null), GreekAct2.charon(null), GreekAct2.erinyes(null)],
		GreekAct2.hades(null),
		[GreekAct3.ares_hound(null), GreekAct3.poseidon_apostle(null), GreekAct3.hephaestus_automaton(null)],
		GreekAct3.kronos(null))

	# 북유럽 신화
	md = _gen_mythology(md, csv_rows, 1, "북유럽 신화 (Norse)",
		[NorseNormals.draugr(null), NorseNormals.urdr_spider(null), NorseNormals.jotun_soldier(null),
		 NorseNormals.volva_witch(null), NorseNormals.hrimfaxi_rider(null), NorseNormals.garlarr_snake(null)],
		[NorseAct1.nidhogg_larva(null), NorseAct1.skoll(null), NorseAct1.hrimthurs_scout(null)],
		NorseAct1.fjorgynn(null),
		[NorseAct2.troll_warrior(null), NorseAct2.norn(null), NorseAct2.vanir_elf(null)],
		NorseAct2.surtr(null),
		[NorseAct3.fenrir_cub(null), NorseAct3.valkyrie(null), NorseAct3.jormungandr_shard(null)],
		NorseAct3.jormungandr(null))

	# 이집트 신화
	md = _gen_mythology(md, csv_rows, 1, "이집트 신화 (Egyptian)",
		[EgyptNormals.sand_scout(null), EgyptNormals.desert_scorpion(null), EgyptNormals.mummy_warrior(null),
		 EgyptNormals.sphinx_cub(null), EgyptNormals.sand_ifrit(null), EgyptNormals.ka_spirit(null)],
		[EgyptAct1.jackal_warrior(null), EgyptAct1.scarab_queen(null), EgyptAct1.obelisk_guardian(null)],
		EgyptAct1.sekhmet(null),
		[EgyptAct2.apep_snake(null), EgyptAct2.seth_hound(null), EgyptAct2.ba_bird(null)],
		EgyptAct2.osiris(null),
		[EgyptAct3.apophis_serpent(null), EgyptAct3.set_tempest(null), EgyptAct3.isis_phantom(null)],
		EgyptAct3.ra_horakhty(null))

	# 불교 신화
	md = _gen_mythology(md, csv_rows, 1, "불교 신화 (Buddhist)",
		[BuddhistNormals.yaksha(null), BuddhistNormals.virudhaka(null), BuddhistNormals.asura(null),
		 BuddhistNormals.garuda(null), BuddhistNormals.mara_soldier(null), BuddhistNormals.vajrapani(null)],
		[BuddhistAct1.vaisravana(null), BuddhistAct1.deva_guardian(null), BuddhistAct1.dharma_general(null)],
		BuddhistAct1.mahavairocana(null),
		[BuddhistAct2.asura_king(null), BuddhistAct2.naga_king(null), BuddhistAct2.agni_buddha(null)],
		BuddhistAct2.guanyin(null),
		[BuddhistAct3.yama(null), BuddhistAct3.ksitigarbha(null), BuddhistAct3.vairocana(null)],
		BuddhistAct3.acalanatha(null))

	# 도교 신화
	md = _gen_mythology(md, csv_rows, 1, "도교 신화 (Daoist)",
		[DaoistNormals.hermit_ghost(null), DaoistNormals.child_immortal(null), DaoistNormals.celestial_soldier(null),
		 DaoistNormals.mountain_spirit(null), DaoistNormals.dao_disciple(null), DaoistNormals.azure_guardian(null)],
		[DaoistAct1.golden_elixir(null), DaoistAct1.silver_elixir(null), DaoistAct1.black_wind_immortal(null)],
		DaoistAct1.eastern_king(null),
		[DaoistAct2.crimson_immortal(null), DaoistAct2.nine_dragon(null), DaoistAct2.twin_immortals(null)],
		DaoistAct2.xuanwu(null),
		[DaoistAct3.white_tiger(null), DaoistAct3.vermilion_bird(null), DaoistAct3.black_tortoise(null)],
		DaoistAct3.jade_emperor(null))

	# 일본 신화
	md = _gen_mythology(md, csv_rows, 1, "일본 신화 (Japanese)",
		[JapaneseNormals.oni(null), JapaneseNormals.tengu(null), JapaneseNormals.yuki_onna(null),
		 JapaneseNormals.kappa(null), JapaneseNormals.shuten_minion(null), JapaneseNormals.ronin_ghost(null)],
		[JapaneseAct1.oni_general(null), JapaneseAct1.yamamba(null), JapaneseAct1.invincible_ronin(null)],
		JapaneseAct1.raijin(null),
		[JapaneseAct2.chaos_tengu(null), JapaneseAct2.yasha(null), JapaneseAct2.nureriyon(null)],
		JapaneseAct2.shuten_doji(null),
		[JapaneseAct3.iwato_guardian(null), JapaneseAct3.susanoo_blade(null), JapaneseAct3.blizzard_queen(null)],
		JapaneseAct3.yamata_no_orochi(null))

	_write_text("enemies.md", md)
	_write_csv("enemies.csv", csv_rows)

# ─────────────────────────────────────────
# 렐릭 도감
# ─────────────────────────────────────────

func _generate_relics() -> void:
	var pool: Array = RelicsGd.build_pool()

	var md: String = "# 렐릭 도감 (자동 생성)\n\n"
	md += "> 이 파일은 `tools/generate_catalog.gd`로 자동 생성됩니다. 직접 수정 금지.\n\n"
	md += "## 공용 풀 (%d종)\n\n" % pool.size()
	md += "| 이름 | 트리거 | 효과 | 값 | 전용 영웅 | 저주 |\n"
	md += "|------|--------|------|-----|-----------|------|\n"

	var csv_rows: Array = [["이름", "설명", "트리거", "효과", "값", "조건값", "bonus_value", "전용_영웅", "저주", "penalty_트리거", "penalty_효과", "penalty_값"]]

	for relic in pool:
		var hero_str: String = relic.owner_hero_id if relic.owner_hero_id != "" else "—"
		var cursed_str: String = "✓" if relic.is_cursed else "—"
		# ON_HERO_DAMAGED 등 condition_value 사용 시 "값 (피해 ≥N)" 형태로 표시
		var val_str: String = "%d" % relic.value
		if relic.condition_value > 0:
			val_str = "%d (피해 ≥%d)" % [relic.value, relic.condition_value]
		md += "| %s | %s | %s | %s | %s | %s |\n" % [
			relic.relic_name, _trigger_name(relic.trigger),
			_relic_effect_name(relic.effect_type), val_str,
			hero_str, cursed_str
		]
		if relic.is_cursed:
			md += "| ↳ 저주 | %s | %s | %d | — | — |\n" % [
				_trigger_name(relic.penalty_trigger),
				_relic_effect_name(relic.penalty_effect_type),
				relic.penalty_value
			]
		csv_rows.append([
			relic.relic_name, relic.description,
			_trigger_name(relic.trigger), _relic_effect_name(relic.effect_type),
			relic.value, relic.condition_value, relic.bonus_value, relic.owner_hero_id,
			"true" if relic.is_cursed else "",
			_trigger_name(relic.penalty_trigger) if relic.is_cursed else "",
			_relic_effect_name(relic.penalty_effect_type) if relic.is_cursed else "",
			relic.penalty_value if relic.is_cursed else "",
		])

	_write_text("relics.md", md)
	_write_csv("relics.csv", csv_rows)

# ─────────────────────────────────────────
# 이벤트 도감
# ─────────────────────────────────────────

func _generate_events() -> void:
	var md: String = "# 이벤트 도감 (자동 생성)\n\n"
	md += "> 이 파일은 `tools/generate_catalog.gd`로 자동 생성됩니다. 직접 수정 금지.\n\n"

	var csv_rows: Array = [["Act", "이벤트명", "설명", "선택지번호", "선택지이름",
		"효과타입", "값", "골드비용", "HP비용",
		"보조효과", "보조값", "확률%", "실패효과", "실패값",
		"전투티어", "보상효과", "보상값", "카드ID", "필요영웅"]]

	var event_sets: Array = [
		{ "label": "Act 1 (공용)", "act": 1, "pool": EventsAct1.build_pool() },
		{ "label": "Act 2 (공용)", "act": 2, "pool": EventsAct2.build_pool() },
		{ "label": "Act 3 (공용)", "act": 3, "pool": EventsAct3.build_pool() },
		{ "label": "불교 신화",    "act": 1, "pool": EventsBuddhist.build_pool() },
		{ "label": "일본 신화",    "act": 1, "pool": EventsJapanese.build_pool() },
		{ "label": "도교 신화",    "act": 1, "pool": EventsDaoist.build_pool() },
	]
	for eset in event_sets:
		var pool: Array = eset["pool"]
		var act_num: int = eset["act"]
		md += "## %s (%d종)\n\n" % [eset["label"], pool.size()]
		for event in pool:
			md += "### %s\n" % event.event_name
			if event.description != "":
				md += "> %s\n\n" % event.description
			for ci in range(event.choices.size()):
				var choice: Resource = event.choices[ci]
				md += "- **%s**%s\n" % [choice.label, _choice_summary(choice)]
				csv_rows.append([act_num, event.event_name, event.description, ci + 1, choice.label,
					_choice_effect_name(choice.effect_type), choice.value, choice.cost_gold, choice.cost_hp,
					_choice_effect_name(choice.secondary_effect_type), choice.secondary_value,
					choice.success_chance, _choice_effect_name(choice.alt_effect_type), choice.alt_value,
					choice.encounter_tier,
					_choice_effect_name(choice.reward_effect_type), choice.reward_value,
					choice.card_id, choice.required_hero_id])
			md += "\n"

	_write_text("events.md", md)
	_write_csv("events.csv", csv_rows)

# 선택지 한 줄 요약 — 비용/주효과/보조/확률/전투/조건 모두 표시
func _choice_summary(choice: Resource) -> String:
	var parts: PackedStringArray = []

	# 비용
	if choice.cost_gold > 0:
		parts.append("[골드 -%d]" % choice.cost_gold)
	if choice.cost_hp > 0:
		parts.append("[HP -%d]" % choice.cost_hp)

	# 조건부
	if choice.required_hero_id != "":
		parts.append("[%s 전용]" % choice.required_hero_id)

	# 주효과
	match choice.effect_type:
		ChoiceRes.EffectType.NONE:
			pass
		ChoiceRes.EffectType.TRIGGER_BATTLE:
			var tier_str: String = "엘리트 전투" if choice.encounter_tier >= 1 else "전투"
			var reward_str: String = ""
			if choice.reward_effect_type != ChoiceRes.EffectType.NONE:
				var rname: String = _choice_effect_name(choice.reward_effect_type)
				reward_str = " → 보상: %s%s" % [rname, (" %d" % choice.reward_value) if choice.reward_value > 0 else ""]
			parts.append("→ %s%s" % [tier_str, reward_str])
		ChoiceRes.EffectType.ADD_CARD:
			var card_label: String = ("(%s)" % choice.card_id) if choice.card_id != "" else ""
			parts.append("→ 카드추가 %s" % card_label)
		_:
			var name1: String = _choice_effect_name(choice.effect_type)
			if choice.value > 0:
				parts.append("→ %s %d" % [name1, choice.value])
			else:
				parts.append("→ %s" % name1)

	# 보조 효과 (MULTI)
	if choice.secondary_effect_type != ChoiceRes.EffectType.NONE:
		var s_name: String = _choice_effect_name(choice.secondary_effect_type)
		if choice.secondary_value > 0:
			parts.append("+ %s %d" % [s_name, choice.secondary_value])
		else:
			parts.append("+ %s" % s_name)

	# 확률 (성공/실패)
	if choice.success_chance > 0 and choice.success_chance < 100:
		var alt_str: String = ""
		if choice.alt_effect_type != ChoiceRes.EffectType.NONE:
			var aname: String = _choice_effect_name(choice.alt_effect_type)
			if choice.alt_value > 0:
				alt_str = " / 실패: %s %d" % [aname, choice.alt_value]
			else:
				alt_str = " / 실패: %s" % aname
		parts.append("[%d%% 성공%s]" % [choice.success_chance, alt_str])

	if parts.is_empty():
		return ""
	return " " + " ".join(parts)

# ─────────────────────────────────────────
# README
# ─────────────────────────────────────────

func _write_readme() -> void:
	var md: String = "# 콘텐츠 도감 (기획자용)\n\n"
	md += "`tools/generate_catalog.gd`로 자동 생성되는 카드/적/렐릭/이벤트 전체 목록.\n\n"
	md += "## 재생성 방법\n\n프로젝트 루트에서:\n\n"
	md += "```bash\n\"H:/Program Files/Godot/Godot_v4.6.2-stable_win64_console.exe\" --headless -s tools/generate_catalog.gd\n```\n\n"
	md += "## 수정 금지\n\n이 폴더의 `.md`/`.csv` 파일은 자동 생성됩니다. 직접 수정하지 마세요.\n"
	md += "내용을 바꾸려면 원본(`resources/cards/`, `resources/enemies/`, `resources/events/`, `resources/relics/`)을 수정한 뒤 재생성하세요.\n\n"
	md += "## 파일 구성\n\n"
	md += "- `cards.md` / `cards.csv` — 영웅별 카드 (나폴레옹/클레오파트라/이순신/잔다르크/칭기즈칸/무사시), 강화 0/1/2강\n"
	md += "- `enemies.md` / `enemies.csv` — 신화별 적 (그리스/북유럽/이집트/한국/중국/일본, 일반/엘리트/보스), 인텐트 전수\n"
	md += "- `relics.md` / `relics.csv` — 공용 렐릭 풀, 저주 penalty 포함\n"
	md += "- `events.md` / `events.csv` — Act별 이벤트, 선택지 전수\n"
	_write_text("README.md", md)
