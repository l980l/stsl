# resources/enemies/japanese/japanese_act3.gd
# 일본 신화 Act 3 — 엘리트 3종(아마노이와토 수문장·스사노오의 검·유키온나의 여왕) + 보스(야마타노오로치)
const EnemyRes  = preload("res://resources/enemy_resource.gd")
const IntentRes = preload("res://resources/intent_resource.gd")

static func iwato_guardian(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.japanese.iwato_guardian"; e.max_hp = 1900; e.character_scene = scene
	e.mythology = "japanese"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.BUFF; i1.value = 70; i1.status_type = "block"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 170; i2.target = IntentRes.TargetType.RANDOM; i2.damage_type = "holy_slash"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.BUFF; i3.value = 50; i3.status_type = "block"
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.ATTACK; i4.value = 190; i4.target = IntentRes.TargetType.LOWEST_HP; i4.damage_type = "holy_arrow"
	e.intent_pattern = [i1, i2, i3, i4]
	e.charm_resistance = 20
	return e

static func susanoo_blade(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.japanese.susanoo_blade"; e.max_hp = 2000; e.character_scene = scene
	e.mythology = "japanese"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.BUFF; i1.value = 3; i1.status_type = "strength"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 190; i2.target = IntentRes.TargetType.LOWEST_HP; i2.damage_type = "lightning"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 170; i3.target = IntentRes.TargetType.RANDOM; i3.damage_type = "lightning"
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.DEBUFF; i4.value = 2; i4.status_type = "vulnerable"
	i4.target = IntentRes.TargetType.ALL
	e.intent_pattern = [i1, i2, i3, i4]
	e.charm_resistance = 20
	return e

static func jorogumo(scene: PackedScene) -> Resource:
	# 조로구모 — 거미 여인. 거미줄로 속박(speed_penalty)하며 독을 먹이는 엘리트
	# (구 blizzard_queen 리스킨, 메커니즘 동일 — 공격 속성만 ice→poison)
	var e := EnemyRes.new()
	e.enemy_name = "enemy.japanese.jorogumo"; e.max_hp = 1800; e.character_scene = scene
	e.mythology = "japanese"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.DEBUFF; i1.value = 3; i1.status_type = "weak"
	i1.target = IntentRes.TargetType.ALL
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 160; i2.target = IntentRes.TargetType.LOWEST_HP; i2.damage_type = "bite_attack"
	var i3 := IntentRes.new()
	# 거미줄의 속박 — 영웅 전체 speed_penalty 4 (3턴 일정 효과)
	i3.action_type = IntentRes.ActionType.DEBUFF; i3.value = 4; i3.status_type = "speed_penalty"
	i3.duration = 3; i3.target = IntentRes.TargetType.ALL
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.ATTACK; i4.value = 180; i4.target = IntentRes.TargetType.RANDOM; i4.damage_type = "bite_attack"
	var i5 := IntentRes.new()
	i5.action_type = IntentRes.ActionType.BUFF; i5.value = 2; i5.status_type = "strength"
	e.intent_pattern = [i1, i2, i3, i4, i5]
	e.charm_resistance = 20
	return e

static func yamata_no_orochi(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.japanese.yamata_no_orochi"; e.max_hp = 4800; e.character_scene = scene
	e.mythology = "japanese"; e.grade = EnemyRes.Grade.BOSS
	e.phase_thresholds = [0.66, 0.33]
	# Phase 0 — 여덟 머리 (8 heads)
	var p0i1 := IntentRes.new()
	p0i1.action_type = IntentRes.ActionType.ATTACK; p0i1.value = 150; p0i1.target = IntentRes.TargetType.RANDOM; p0i1.damage_type = "bite_attack"
	var p0i2 := IntentRes.new()
	p0i2.action_type = IntentRes.ActionType.ATTACK; p0i2.value = 150; p0i2.target = IntentRes.TargetType.RANDOM; p0i2.damage_type = "bite_attack"
	var p0i3 := IntentRes.new()
	p0i3.action_type = IntentRes.ActionType.DEBUFF; p0i3.value = 2; p0i3.status_type = "weak"
	p0i3.target = IntentRes.TargetType.ALL
	var p0i4 := IntentRes.new()
	p0i4.action_type = IntentRes.ActionType.ATTACK; p0i4.value = 140; p0i4.target = IntentRes.TargetType.ALL; p0i4.damage_type = "fire"
	var p0i5 := IntentRes.new()
	p0i5.action_type = IntentRes.ActionType.BUFF; p0i5.value = 1; p0i5.status_type = "strength"
	# Phase 1 — 다섯 머리 (공격력 증가)
	var p1i1 := IntentRes.new()
	p1i1.action_type = IntentRes.ActionType.ATTACK; p1i1.value = 190; p1i1.target = IntentRes.TargetType.RANDOM; p1i1.damage_type = "bite_attack"
	var p1i2 := IntentRes.new()
	p1i2.action_type = IntentRes.ActionType.ATTACK; p1i2.value = 190; p1i2.target = IntentRes.TargetType.RANDOM; p1i2.damage_type = "bite_attack"
	var p1i3 := IntentRes.new()
	p1i3.action_type = IntentRes.ActionType.DEBUFF; p1i3.value = 2; p1i3.status_type = "vulnerable"
	p1i3.target = IntentRes.TargetType.ALL
	var p1i4 := IntentRes.new()
	p1i4.action_type = IntentRes.ActionType.ATTACK; p1i4.value = 180; p1i4.target = IntentRes.TargetType.ALL; p1i4.damage_type = "fire"
	var p1i5 := IntentRes.new()
	p1i5.action_type = IntentRes.ActionType.BUFF; p1i5.value = 2; p1i5.status_type = "strength"
	# Phase 2 — 두 머리 (최고 공격력) — CHARGE_UP 등장: 2턴 → 강공격 + stun
	var p2i1 := IntentRes.new()
	p2i1.action_type = IntentRes.ActionType.ATTACK; p2i1.value = 230; p2i1.target = IntentRes.TargetType.LOWEST_HP; p2i1.damage_type = "bite_attack"
	var p2_charge_bite := IntentRes.new()
	p2_charge_bite.action_type = IntentRes.ActionType.ATTACK; p2_charge_bite.value = 260; p2_charge_bite.target = IntentRes.TargetType.LAST_ATTACKER; p2_charge_bite.damage_type = "bite_attack"
	var p2_charge_stun := IntentRes.new()
	p2_charge_stun.action_type = IntentRes.ActionType.DEBUFF; p2_charge_stun.value = 1; p2_charge_stun.status_type = "stun"
	p2_charge_stun.target = IntentRes.TargetType.LAST_ATTACKER
	var p2i2 := IntentRes.new()
	p2i2.action_type = IntentRes.ActionType.CHARGE_UP; p2i2.charge_turns = 2; p2i2.payoff_intents = [p2_charge_bite, p2_charge_stun]
	var p2i3 := IntentRes.new()
	p2i3.action_type = IntentRes.ActionType.DEBUFF; p2i3.value = 3; p2i3.status_type = "vulnerable"
	p2i3.target = IntentRes.TargetType.ALL
	var p2i4 := IntentRes.new()
	p2i4.action_type = IntentRes.ActionType.ATTACK; p2i4.value = 220; p2i4.target = IntentRes.TargetType.ALL; p2i4.damage_type = "fire"
	var p2i5 := IntentRes.new()
	p2i5.action_type = IntentRes.ActionType.BUFF; p2i5.value = 3; p2i5.status_type = "strength"
	# yamata_no_orochi (8 머리 뱀) — turn_modes [head1, head2, head3] 3-mode 순환 (8 머리 추상).
	# 각 모드 다른 공격 의미. + INFLICT_WEAKNESS weakness_fire (스사노오 전설 — 화살 약점).
	e.turn_modes = ["head1", "head2", "head3"]
	var p1i_switch := IntentRes.new()
	p1i_switch.action_type = IntentRes.ActionType.FORM_SWITCH; p1i_switch.play_animation = "buff"
	var p2i_switch := IntentRes.new()
	p2i_switch.action_type = IntentRes.ActionType.FORM_SWITCH; p2i_switch.play_animation = "buff"
	var p2i_curse := IntentRes.new()
	p2i_curse.action_type = IntentRes.ActionType.INFLICT_WEAKNESS; p2i_curse.value = 3; p2i_curse.status_type = "weakness_fire"
	p2i_curse.target = IntentRes.TargetType.ALL; p2i_curse.play_animation = "debuff"
	e.phase_patterns = [
		[p0i1, p0i2, p0i3, p0i4, p0i5],
		[p1i_switch, p1i1, p1i2, p1i3, p1i4, p1i5],
		[p2i_switch, p2i_curse, p2i1, p2i2, p2i3, p2i4, p2i5]
	]
	e.intent_pattern = e.phase_patterns[0]
	e.charm_resistance = 20
	return e

static func elites() -> Array:
	return ["iwato_guardian", "susanoo_blade", "jorogumo"]

static func boss() -> String:
	return "yamata_no_orochi"
