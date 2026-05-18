# tools/dump_normal_enemies.gd
# 헤드리스 실행: godot --headless --script tools/dump_normal_enemies.gd
# 6 신화 일반 적 (normals) 메타 + 인카운터 구성을 두 csv 로 dump.
# PR #95 시점에 일회성으로 만들었던 normal_monsters.csv / normal_encounters.csv 를
# 영구 도구로 정착 — 적 패턴 변경 후 재실행만 하면 갱신.
extends SceneTree

const MON_OUT := "res://docs/balance/normal_monsters.csv"
const ENC_OUT := "res://docs/balance/normal_encounters.csv"

const MYTHOLOGIES := ["greek", "egyptian", "norse", "buddhist", "daoist", "japanese"]

func _initialize() -> void:
	var mon_rows: Array = ["mythology,key,hp,pattern_len,damage_types,buff_str,buff_blk,debuff_weak,debuff_vul,debuff_poison,has_all,has_low_hp,has_special,has_prepare,max_atk,pattern_summary"]
	var enc_rows: Array = ["mythology,enc_idx,difficulty,monsters,member_count,total_hp"]
	for myth in MYTHOLOGIES:
		var mod: GDScript = load("res://resources/enemies/%s/%s_normals.gd" % [myth, myth])
		if mod == null:
			push_error("로드 실패: %s_normals.gd" % myth)
			continue
		var keys: Array = _extract_function_keys(mod)
		var mon_meta: Dictionary = {}
		for key in keys:
			var enemy: Resource = mod.call(key, null)
			if enemy == null:
				continue
			var row: Dictionary = _analyze_monster(myth, key, enemy)
			mon_meta[key] = row
			mon_rows.append(_format_monster_row(row))
		# 인카운터 분석
		var encs: Array = mod.encounters()
		for i in range(encs.size()):
			var members: Array = encs[i]
			var total_hp := 0
			for k in members:
				if mon_meta.has(k):
					total_hp += mon_meta[k]["hp"]
			enc_rows.append("%s,%d,%d,%s,%d,%d" % [myth, i + 1, i + 1, "|".join(members), members.size(), total_hp])
	_write_csv(MON_OUT, mon_rows)
	_write_csv(ENC_OUT, enc_rows)
	print("[dump_normal_enemies] %d monsters → %s" % [mon_rows.size() - 1, MON_OUT])
	print("[dump_normal_enemies] %d encounters → %s" % [enc_rows.size() - 1, ENC_OUT])
	quit(0)

# 모듈의 static func 이름 추출 (encounters/등 제외, scene 인자 받는 함수만 추정)
func _extract_function_keys(mod: GDScript) -> Array:
	var out: Array = []
	for m in mod.get_script_method_list():
		var name: String = m["name"]
		if name == "encounters" or name.begins_with("_"):
			continue
		# scene 인자 받는 enemy factory 인지 — 인자 1개 (PackedScene) 가정
		if m["args"].size() != 1:
			continue
		out.append(name)
	out.sort()
	return out

func _analyze_monster(myth: String, key: String, enemy: Resource) -> Dictionary:
	var damage_types: Dictionary = {}
	var buff_str := 0
	var buff_blk := 0
	var debuff_weak := 0
	var debuff_vul := 0
	var debuff_poison := 0
	var has_all := false
	var has_low_hp := false
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
		# IntentResource.TargetType: SINGLE=0, RANDOM=1, LOWEST_HP=2, ALL=3, SELF=4, ALLY=5, ALL_ALLIES=6
		if tgt == 3:
			has_all = true

	# low_hp 트리거 — phase_thresholds 가 있으면 hp 트리거 보유
	if enemy.phase_thresholds.size() > 0:
		has_low_hp = true

	return {
		"mythology": myth,
		"key": key,
		"hp": enemy.max_hp,
		"pattern_len": enemy.intent_pattern.size(),
		"damage_types": "|".join(damage_types.keys()),
		"buff_str": buff_str,
		"buff_blk": buff_blk,
		"debuff_weak": debuff_weak,
		"debuff_vul": debuff_vul,
		"debuff_poison": debuff_poison,
		"has_all": "Y" if has_all else "N",
		"has_low_hp": "Y" if has_low_hp else "N",
		"has_special": "Y" if has_special else "N",
		"has_prepare": "Y" if has_prepare else "N",
		"max_atk": max_atk,
		"pattern_summary": "->".join(parts),
	}

func _format_monster_row(r: Dictionary) -> String:
	return "%s,%s,%d,%d,%s,%d,%d,%d,%d,%d,%s,%s,%s,%s,%d,%s" % [
		r["mythology"], r["key"], r["hp"], r["pattern_len"], r["damage_types"],
		r["buff_str"], r["buff_blk"], r["debuff_weak"], r["debuff_vul"], r["debuff_poison"],
		r["has_all"], r["has_low_hp"], r["has_special"], r["has_prepare"],
		r["max_atk"], r["pattern_summary"],
	]

func _write_csv(path: String, rows: Array) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_error("Cannot open output: %s" % path)
		return
	# UTF-8 BOM — Excel 호환
	f.store_buffer(PackedByteArray([0xEF, 0xBB, 0xBF]))
	for line in rows:
		f.store_line(line)
	f.close()
