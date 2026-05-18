# tools/dump_act_enemies.gd
# 헤드리스 실행: godot --headless --script tools/dump_act_enemies.gd
# 6 신화 × 3 act = 18 act 파일에서 ELITE / BOSS 적 메타를 두 csv 로 dump.
# NORMAL 은 tools/dump_normal_enemies.gd 가 담당.
extends SceneTree

const ELITE_OUT := "res://docs/balance/elite_enemies.csv"
const BOSS_OUT  := "res://docs/balance/boss_enemies.csv"

const MYTHOLOGIES := ["greek", "egyptian", "norse", "buddhist", "daoist", "japanese"]
const ACTS := [1, 2, 3]

const COMMON_HEADER := "mythology,act,key,hp,speed,pattern_len,damage_types,max_atk,buff_str,buff_blk,debuff_weak,debuff_vul,debuff_poison,has_all,has_special,has_prepare,signatures_enabled,has_phases,phase_count,has_card_trigger,charm_resistance,pattern_summary"

func _initialize() -> void:
	var elite_rows: Array = [COMMON_HEADER]
	var boss_rows: Array = [COMMON_HEADER]
	for myth in MYTHOLOGIES:
		for act in ACTS:
			var path := "res://resources/enemies/%s/%s_act%d.gd" % [myth, myth, act]
			var mod: GDScript = load(path)
			if mod == null:
				push_error("로드 실패: " + path)
				continue
			# ELITE
			for key in mod.elites():
				var enemy: Resource = mod.call(key, null)
				if enemy != null:
					elite_rows.append(_format_row(myth, act, key, enemy))
			# BOSS
			var boss_key: String = mod.boss()
			var boss_enemy: Resource = mod.call(boss_key, null)
			if boss_enemy != null:
				boss_rows.append(_format_row(myth, act, boss_key, boss_enemy))
	_write_csv(ELITE_OUT, elite_rows)
	_write_csv(BOSS_OUT, boss_rows)
	print("[dump_act_enemies] %d elites → %s" % [elite_rows.size() - 1, ELITE_OUT])
	print("[dump_act_enemies] %d bosses → %s" % [boss_rows.size() - 1, BOSS_OUT])
	quit(0)

func _format_row(myth: String, act: int, key: String, enemy: Resource) -> String:
	var damage_types: Dictionary = {}
	var buff_str := 0
	var buff_blk := 0
	var debuff_weak := 0
	var debuff_vul := 0
	var debuff_poison := 0
	var has_all := false
	var has_special := false
	var has_prepare := false
	var max_atk := 0
	var parts: Array = []

	for intent in enemy.intent_pattern:
		var atype: int = intent.action_type
		var v: int = intent.value
		var tgt: int = intent.target
		var stype: String = intent.status_type
		var dtype: String = intent.damage_type
		# IntentResource.ActionType: ATTACK=0, BUFF=1, DEBUFF=2, BLOCK=3, HEAL=4, SPECIAL=5,
		# PREPARE=6, HEAL_ALLY=7, BUFF_ALLY=8, COUNTER_PREPARE=9, MARK_TARGET=10, SACRIFICE=11, WARD=12, SUMMON=13
		match atype:
			0:  # ATTACK
				if dtype != "": damage_types[dtype] = true
				if v > max_atk: max_atk = v
				parts.append("A%d/%s" % [v, dtype if dtype != "" else "?"])
			1:  # BUFF
				if stype == "strength": buff_str += v
				elif stype == "block": buff_blk += v
				parts.append("B:%s+%d" % [stype, v])
			2:  # DEBUFF
				if stype == "weak": debuff_weak += v
				elif stype == "vulnerable": debuff_vul += v
				elif stype == "poison": debuff_poison += v
				parts.append("D:%s+%d" % [stype, v])
			3: parts.append("BLK%d" % v)
			4: parts.append("HEAL%d" % v)
			5:
				has_special = true
				parts.append("SP:%s" % stype if stype != "" else "SP")
			6:
				has_prepare = true
				parts.append("PREP")
			7: parts.append("HA%d" % v)
			8: parts.append("BA:%s+%d" % [stype, v])
			9: parts.append("CPR")
			10: parts.append("MARK")
			11: parts.append("SAC%d" % v)
			12: parts.append("WARD")
			13: parts.append("SUM")
			_: parts.append("?%d" % atype)
		if tgt == 3:  # TargetType.ALL
			has_all = true

	var has_phases: bool = enemy.phase_thresholds.size() > 0
	var phase_count: int = (enemy.phase_thresholds.size() + 1) if has_phases else 1
	var has_card_trigger: bool = enemy.card_count_trigger.size() > 0

	return "%s,%d,%s,%d,%d,%d,%s,%d,%d,%d,%d,%d,%d,%s,%s,%s,%s,%s,%d,%s,%d,%s" % [
		myth, act, key, enemy.max_hp, enemy.speed,
		enemy.intent_pattern.size(), "|".join(damage_types.keys()), max_atk,
		buff_str, buff_blk, debuff_weak, debuff_vul, debuff_poison,
		"Y" if has_all else "N",
		"Y" if has_special else "N",
		"Y" if has_prepare else "N",
		"Y" if enemy.signatures_enabled else "N",
		"Y" if has_phases else "N",
		phase_count,
		"Y" if has_card_trigger else "N",
		enemy.charm_resistance,
		"->".join(parts),
	]

func _write_csv(path: String, rows: Array) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_error("Cannot open output: %s — 파일이 다른 프로그램에 열려있는지 확인" % path)
		return
	# UTF-8 BOM — Excel 호환
	f.store_buffer(PackedByteArray([0xEF, 0xBB, 0xBF]))
	for line in rows:
		f.store_line(line)
	f.close()
