# tools/encounter_balance.gd
# 60 일반 인카운터 정적 밸런스 분석 — 잠재 outlier 식별용
# 실행: "H:/Program Files/Godot/Godot_v4.6.2-stable_win64_console.exe" --headless -s tools/encounter_balance.gd
extends SceneTree

const OUT_PATH := "res://docs/balance/encounter_balance_v2.csv"
const IntentRes = preload("res://resources/intent_resource.gd")

const MYTHOLOGIES := {
	"greek":     preload("res://resources/enemies/greek/greek_normals.gd"),
	"norse":     preload("res://resources/enemies/norse/norse_normals.gd"),
	"egyptian":  preload("res://resources/enemies/egyptian/egyptian_normals.gd"),
	"buddhist":  preload("res://resources/enemies/buddhist/buddhist_normals.gd"),
	"daoist":    preload("res://resources/enemies/daoist/daoist_normals.gd"),
	"japanese":  preload("res://resources/enemies/japanese/japanese_normals.gd"),
}

# 메커니즘 분류 (위험도 가중치)
const T2_T3_ACTIONS := [
	IntentRes.ActionType.HEAL_ALLY, IntentRes.ActionType.BUFF_ALLY,
	IntentRes.ActionType.COUNTER_PREPARE, IntentRes.ActionType.MARK_TARGET,
	IntentRes.ActionType.SACRIFICE, IntentRes.ActionType.WARD,
	IntentRes.ActionType.SUMMON, IntentRes.ActionType.MIMIC,
]

func _init() -> void:
	var lines: Array[String] = []
	lines.append("mythology,enc_idx,difficulty_label,monster_count,total_hp,cycle_damage,attack_count,t1_count,t2t3_count,death_rattle,sigs_enabled,risk_score,monsters,mechanisms")

	for myth in MYTHOLOGIES.keys():
		var mod = MYTHOLOGIES[myth]
		var encs: Array = mod.encounters()
		for i in range(encs.size()):
			var keys: Array = encs[i]
			var row := _analyze_encounter(myth, i, keys, mod)
			lines.append(row)

	var f := FileAccess.open(OUT_PATH, FileAccess.WRITE)
	if f == null:
		push_error("Cannot open output: %s" % OUT_PATH)
		quit(1)
		return
	for line in lines:
		f.store_line(line)
	f.close()
	print("[encounter_balance] %d rows → %s" % [lines.size() - 1, OUT_PATH])
	quit(0)

func _analyze_encounter(myth: String, idx: int, keys: Array, mod: GDScript) -> String:
	var difficulty_labels := ["매우약함","약함","약함","보통","보통","다소강함","강함","강함","매우강함","최강"]
	var diff_label: String = difficulty_labels[idx] if idx < 10 else "?"
	var monster_count: int = keys.size()
	var total_hp: int = 0
	var cycle_damage: int = 0
	var attack_count: int = 0
	var t1_count: int = 0      # phase_thresholds 보유 (BERSERK/DESPERATE/PHASE)
	var t2t3_count: int = 0    # tier 2~3 ActionType 보유 monsters
	var death_rattle_count: int = 0
	var sigs_disabled_count: int = 0
	var monster_names: Array = []
	var mechanism_set: Dictionary = {}

	for key in keys:
		var enemy: Resource = mod.call(key, null)
		if enemy == null:
			continue
		monster_names.append(key)
		total_hp += enemy.max_hp

		var pat: Array = enemy.intent_pattern
		# 사이클 데미지 — ATTACK value 합 (strength 보정 미고려, base만)
		var enemy_cycle_dmg: int = 0
		var has_t2t3: bool = false
		for intent in pat:
			match intent.action_type:
				IntentRes.ActionType.ATTACK:
					attack_count += 1
					enemy_cycle_dmg += intent.value
					if intent.target == IntentRes.TargetType.ALL:
						# ALL 공격은 ~3마리 영웅 가정 → 데미지 ×2 가중
						enemy_cycle_dmg += intent.value * 2
				_:
					if intent.action_type in T2_T3_ACTIONS:
						has_t2t3 = true
						mechanism_set[IntentRes.ActionType.keys()[intent.action_type]] = true
		cycle_damage += enemy_cycle_dmg

		if not enemy.phase_thresholds.is_empty():
			t1_count += 1
			mechanism_set["PHASE_TRIGGER"] = true
		if has_t2t3:
			t2t3_count += 1
		if enemy.death_trigger != null:
			death_rattle_count += 1
			mechanism_set["DEATH_RATTLE"] = true
		if enemy.get("signatures_enabled") == false:
			sigs_disabled_count += 1

	# 위험도 점수 = HP/100 + 데미지/50 + tier1*5 + tier2t3*8 + death*4 - sigs_disabled*3
	# 인카운터 #1~3는 보수적, #8~10은 공격적 — 단순 합산으로 outlier 가시화
	var risk: int = int(total_hp / 100.0) + int(cycle_damage / 50.0) + t1_count * 5 + t2t3_count * 8 + death_rattle_count * 4 - sigs_disabled_count * 3

	var monsters_str: String = "|".join(monster_names)
	var mechs_str: String = "|".join(mechanism_set.keys()) if mechanism_set.size() > 0 else "-"
	var sigs_enabled_str: String = "all" if sigs_disabled_count == 0 else "%d disabled" % sigs_disabled_count

	return "%s,%d,%s,%d,%d,%d,%d,%d,%d,%d,%s,%d,%s,%s" % [
		myth, idx, diff_label, monster_count, total_hp, cycle_damage, attack_count,
		t1_count, t2t3_count, death_rattle_count, sigs_enabled_str, risk,
		monsters_str, mechs_str
	]
