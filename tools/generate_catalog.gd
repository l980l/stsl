# tools/generate_catalog.gd
# 실행: "H:/Program Files/Godot/Godot_v4.6.2-stable_win64_console.exe" --headless -s tools/generate_catalog.gd
# 주의: SceneTree 모드 — autoload 미초기화. 업그레이드 공식은 game_manager.gd:315-353 기준 직접 포팅.
extends SceneTree

const OUT_DIR := "res://docs/catalog/"

const NapoleonCards  = preload("res://resources/cards/cards_napoleon.gd")
const CleopatraCards = preload("res://resources/cards/cards_cleopatra.gd")
const YiSunSinCards  = preload("res://resources/cards/cards_yi_sun_sin.gd")
const EnemiesAct1    = preload("res://resources/enemies/enemies_act1.gd")
const RelicsGd       = preload("res://resources/relics/relics.gd")
const EventsAct1     = preload("res://resources/events/events_act1.gd")

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
			elif effect.effect_type in INT_TYPES:
				effect.value = effect.base_value + (i + 1)
				effect.bonus_value = effect.base_bonus_value + (i + 1) if effect.base_bonus_value > 0 else 0
	return c

# ─────────────────────────────────────────
# 효과 포매터 (battle_scene.gd:_card_effect_text 동기화)
# ─────────────────────────────────────────

func _format_effect(effect: Resource) -> String:
	match effect.effect_type:
		EffRes.EffectType.DAMAGE:
			var suffix: String = " ALL" if effect.target == "ALL" else ""
			return "DMG %d%s" % [effect.value, suffix]
		EffRes.EffectType.BLOCK:
			var suffix: String = " ALL" if effect.target == "ALL" else ""
			return "BLOCK %d%s" % [effect.value, suffix]
		EffRes.EffectType.BLOCK_ALL:
			return "BLOCK ALL %d" % effect.value
		EffRes.EffectType.HEAL:
			return "HEAL %d" % effect.value
		EffRes.EffectType.HEAL_ALL:
			return "HEAL ALL %d" % effect.value
		EffRes.EffectType.DRAW:
			return "DRAW %d" % effect.value
		EffRes.EffectType.ENERGY:
			return "ENERGY +%d" % effect.value
		EffRes.EffectType.APPLY_STATUS:
			return "%s %d" % [effect.status_type.to_upper(), effect.value]
		EffRes.EffectType.CHARM:
			return "CHARM %d" % effect.value
		EffRes.EffectType.GAIN_MORALE:
			return "MORALE +%d" % effect.value
		EffRes.EffectType.CONSUME_MORALE:
			return "소모사기 %d → DMG %d" % [effect.value, effect.bonus_value]
		EffRes.EffectType.POISON_BURST:
			return "POISON BURST"
		EffRes.EffectType.COUNTER_BLOCK:
			return "방어도×%d%% DMG" % effect.value
		EffRes.EffectType.FORMATION_BLOCK:
			return "생존영웅×BLOCK %d" % effect.value
		EffRes.EffectType.COST_NEXT:
			return "다음카드 비용 -%d" % effect.value
		EffRes.EffectType.CONDITIONAL_DMG:
			return "DMG %d(조건:%d)[%s]" % [effect.bonus_value, effect.value, effect.status_type]
		EffRes.EffectType.SUMMON_TOKEN:
			return "소환 ×%d" % effect.value
	return "?"

func _format_effects(card: Resource) -> String:
	var parts: Array = []
	for e in card.effects:
		parts.append(_format_effect(e))
	return " + ".join(parts)

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
		CardRes.CardType.ATTACK: return "ATTACK"
		CardRes.CardType.SKILL:  return "SKILL"
		CardRes.CardType.POWER:  return "POWER"
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
	_write_text(rel_path, "\n".join(lines) + "\n")

# ─────────────────────────────────────────
# 카드 도감
# ─────────────────────────────────────────

func _generate_cards() -> void:
	var heroes: Array = [
		{ "id": "napoleon",  "name": "나폴레옹 (Napoleon)",  "cls": NapoleonCards },
		{ "id": "cleopatra", "name": "클레오파트라 (Cleopatra)", "cls": CleopatraCards },
		{ "id": "yi_sun_sin","name": "이순신 (Yi Sun-sin)",   "cls": YiSunSinCards },
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
			starter_parts.append("%s ×%d" % [cname, starter_count[cname]])
		md += "### 시작 덱\n- %s\n\n" % ", ".join(starter_parts)

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
				card.card_name, card.cost,
				_card_type_name(card.card_type),
				_rarity_name(card.rarity),
				eff0, eff1, eff2
			]
			csv_rows.append([
				hero["id"], card.card_name, card.cost,
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

func _generate_enemies() -> void:
	var md: String = "# 적 도감 (자동 생성)\n\n"
	md += "> 이 파일은 `tools/generate_catalog.gd`로 자동 생성됩니다. 직접 수정 금지.\n\n"

	var csv_rows: Array = [["Act", "분류", "이름", "HP", "페이즈", "턴", "액션", "값", "타겟", "상태", "조건"]]

	# Act1 적 (scene=null: 도감용이므로 씬 불필요)
	md += "## Act 1 (그리스 신화)\n\n"
	md += "### 일반 적\n\n"

	var normals_act1: Array = [
		EnemiesAct1.satyr(null), EnemiesAct1.harpy(null),
		EnemiesAct1.cyclops(null), EnemiesAct1.snake(null),
		EnemiesAct1.cerberus(null), EnemiesAct1.myrmidon(null),
	]
	for enemy in normals_act1:
		md += _enemy_section_md(enemy, 1, "normal")
		csv_rows.append_array(_enemy_csv_rows(enemy, 1, "normal"))

	md += "### 엘리트\n\n"
	var elites_act1: Array = [
		EnemiesAct1.minotaur(null), EnemiesAct1.medusa(null),
		EnemiesAct1.gorgon(null), EnemiesAct1.scylla(null),
	]
	for enemy in elites_act1:
		md += _enemy_section_md(enemy, 1, "elite")
		csv_rows.append_array(_enemy_csv_rows(enemy, 1, "elite"))

	md += "### 보스\n\n"
	var boss_act1: Resource = EnemiesAct1.hydra(null)
	md += _enemy_section_md(boss_act1, 1, "boss")
	csv_rows.append_array(_enemy_csv_rows(boss_act1, 1, "boss"))

	md += "## Act 2\n\n_Act 2 콘텐츠는 feat/act2-egypt 브랜치에서 추가 예정._\n\n"

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

	var csv_rows: Array = [["이름", "설명", "트리거", "효과", "값", "bonus_value", "전용_영웅", "저주", "penalty_트리거", "penalty_효과", "penalty_값"]]

	for relic in pool:
		var hero_str: String = relic.owner_hero_id if relic.owner_hero_id != "" else "—"
		var cursed_str: String = "✓" if relic.is_cursed else "—"
		md += "| %s | %s | %s | %d | %s | %s |\n" % [
			relic.relic_name, _trigger_name(relic.trigger),
			_relic_effect_name(relic.effect_type), relic.value,
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
			relic.value, relic.bonus_value, relic.owner_hero_id,
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

	var csv_rows: Array = [["Act", "이벤트명", "설명", "선택지번호", "선택지이름", "효과타입", "값", "골드비용", "HP비용"]]

	var pool1: Array = EventsAct1.build_pool()
	md += "## Act 1 (%d종)\n\n" % pool1.size()
	for event in pool1:
		md += "### %s\n" % event.event_name
		if event.description != "":
			md += "> %s\n\n" % event.description
		for ci in range(event.choices.size()):
			var choice: Resource = event.choices[ci]
			var cost_str: String = ""
			if choice.cost_gold > 0:
				cost_str += " (골드 -%d)" % choice.cost_gold
			if choice.cost_hp > 0:
				cost_str += " (HP -%d)" % choice.cost_hp
			var val_str: String = ""
			if choice.value > 0:
				val_str = " → %s %d" % [_choice_effect_name(choice.effect_type), choice.value]
			elif choice.effect_type != ChoiceRes.EffectType.NONE:
				val_str = " → %s" % _choice_effect_name(choice.effect_type)
			md += "- **%s**%s%s\n" % [choice.label, cost_str, val_str]
			csv_rows.append([1, event.event_name, event.description, ci + 1, choice.label,
				_choice_effect_name(choice.effect_type), choice.value, choice.cost_gold, choice.cost_hp])
		md += "\n"

	md += "## Act 2\n\n_Act 2 이벤트는 feat/act2-egypt 브랜치에서 추가 예정._\n\n"

	_write_text("events.md", md)
	_write_csv("events.csv", csv_rows)

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
	md += "- `cards.md` / `cards.csv` — 영웅별 카드 (나폴레옹/클레오파트라/이순신), 강화 0/1/2강\n"
	md += "- `enemies.md` / `enemies.csv` — Act별 적 (일반/엘리트/보스), 인텐트 전수\n"
	md += "- `relics.md` / `relics.csv` — 공용 렐릭 풀, 저주 penalty 포함\n"
	md += "- `events.md` / `events.csv` — Act별 이벤트, 선택지 전수\n"
	_write_text("README.md", md)
