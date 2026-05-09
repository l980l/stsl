# resources/enemies/egyptian/egyptian_normals.gd
# 이집트 신화 — 일반 적 20종 + 인카운터 10개 (난이도 오름차순)
const EnemyRes  = preload("res://resources/enemy_resource.gd")
const IntentRes = preload("res://resources/intent_resource.gd")

# ──── 기존 6종 (재배치) ────

static func ka_spirit(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.egyptian.ka_spirit"; e.max_hp = 320; e.character_scene = scene
	e.mythology = "egyptian"; e.signatures_enabled = false  # 인카운터 #1
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 55; i1.target = IntentRes.TargetType.RANDOM; i1.damage_type = "curse"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.DEBUFF; i2.value = 2; i2.status_type = "vulnerable"; i2.target = IntentRes.TargetType.RANDOM
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 55; i3.target = IntentRes.TargetType.RANDOM; i3.damage_type = "curse"
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.DEBUFF; i4.value = 2; i4.status_type = "weak"; i4.target = IntentRes.TargetType.RANDOM
	e.intent_pattern = [i1, i2, i3, i4]
	return e

static func sphinx_cub(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.egyptian.sphinx_cub"; e.max_hp = 350; e.character_scene = scene
	e.mythology = "egyptian"; e.signatures_enabled = false  # 인카운터 #3
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 80; i1.target = IntentRes.TargetType.RANDOM; i1.damage_type = "slash"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 80; i2.target = IntentRes.TargetType.RANDOM; i2.damage_type = "slash"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 80; i3.target = IntentRes.TargetType.RANDOM; i3.damage_type = "slash"
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.ATTACK; i4.value = 80; i4.target = IntentRes.TargetType.RANDOM; i4.damage_type = "slash"
	var i5 := IntentRes.new()
	i5.action_type = IntentRes.ActionType.SPECIAL; i5.value = 1
	e.intent_pattern = [i1, i2, i3, i4, i5]
	return e

static func desert_scorpion(scene: PackedScene) -> Resource:
	# DEATH-RATTLE: 죽을 때 ALL poison +2 (사막 전갈의 마지막 독)
	var e := EnemyRes.new()
	e.enemy_name = "enemy.egyptian.desert_scorpion"; e.max_hp = 420; e.character_scene = scene
	e.mythology = "egyptian"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 70; i1.target = IntentRes.TargetType.RANDOM; i1.damage_type = "poison"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.DEBUFF; i2.value = 4; i2.status_type = "poison"; i2.target = IntentRes.TargetType.RANDOM
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 70; i3.target = IntentRes.TargetType.RANDOM; i3.damage_type = "poison"
	e.intent_pattern = [i1, i2, i3]
	var dt := IntentRes.new()
	dt.action_type = IntentRes.ActionType.DEBUFF; dt.value = 2; dt.status_type = "poison"; dt.target = IntentRes.TargetType.ALL
	e.death_trigger = dt
	return e

static func sand_scout(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.egyptian.sand_scout"; e.max_hp = 380; e.character_scene = scene
	e.mythology = "egyptian"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 90; i1.target = IntentRes.TargetType.RANDOM; i1.damage_type = "projectile"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.BUFF; i2.value = 1; i2.status_type = "strength"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 90; i3.target = IntentRes.TargetType.RANDOM; i3.damage_type = "projectile"
	e.intent_pattern = [i1, i2, i3]
	return e

static func sand_ifrit(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.egyptian.sand_ifrit"; e.max_hp = 450; e.character_scene = scene
	e.mythology = "egyptian"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.BUFF; i1.value = 2; i1.status_type = "strength"; i1.condition = "준비"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 230; i2.target = IntentRes.TargetType.ALL; i2.damage_type = "fire"
	e.intent_pattern = [i1, i2]
	return e

static func mummy_warrior(scene: PackedScene) -> Resource:
	# T0-DEBUFF누적: weak 2회 적층 → 큰 한 방 (붕대 감긴 전사의 함정)
	var e := EnemyRes.new()
	e.enemy_name = "enemy.egyptian.mummy_warrior"; e.max_hp = 600; e.character_scene = scene
	e.mythology = "egyptian"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.DEBUFF; i1.value = 2; i1.status_type = "weak"; i1.target = IntentRes.TargetType.RANDOM
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 100; i2.target = IntentRes.TargetType.RANDOM; i2.damage_type = "blunt"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.DEBUFF; i3.value = 2; i3.status_type = "weak"; i3.target = IntentRes.TargetType.RANDOM
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.ATTACK; i4.value = 160; i4.target = IntentRes.TargetType.LOWEST_HP; i4.damage_type = "blunt"
	e.intent_pattern = [i1, i2, i3, i4]
	return e

# ──── 신규 14종 ────

static func scarab(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.egyptian.scarab"; e.max_hp = 260; e.character_scene = scene
	e.mythology = "egyptian"; e.signatures_enabled = false  # 인카운터 #2
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 50; i1.target = IntentRes.TargetType.RANDOM; i1.damage_type = "slash"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 65; i2.target = IntentRes.TargetType.RANDOM; i2.damage_type = "slash"
	e.intent_pattern = [i1, i2]
	return e

static func sand_wraith(scene: PackedScene) -> Resource:
	# T1-DESPERATE: HP 30% 미만 strength +2 (모래 망령 마지막 저주)
	var e := EnemyRes.new()
	e.enemy_name = "enemy.egyptian.sand_wraith"; e.max_hp = 310; e.character_scene = scene
	e.mythology = "egyptian"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.DEBUFF; i1.value = 1; i1.status_type = "weak"; i1.target = IntentRes.TargetType.RANDOM
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 70; i2.target = IntentRes.TargetType.RANDOM; i2.damage_type = "curse"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.DEBUFF; i3.value = 1; i3.status_type = "vulnerable"; i3.target = IntentRes.TargetType.RANDOM
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.ATTACK; i4.value = 70; i4.target = IntentRes.TargetType.RANDOM; i4.damage_type = "curse"
	e.intent_pattern = [i1, i2, i3, i4]
	e.phase_thresholds = [0.3]
	e.phase_buffs = [[{"status": "strength", "value": 2}]]
	return e

static func sand_rat(scene: PackedScene) -> Resource:
	# T0-CHARGE: 짧은 PREPARE → LOWEST_HP 큰 한 방. 3마리 동시 출현 (#5)
	var e := EnemyRes.new()
	e.enemy_name = "enemy.egyptian.sand_rat"; e.max_hp = 280; e.character_scene = scene
	e.mythology = "egyptian"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 50; i1.target = IntentRes.TargetType.RANDOM; i1.damage_type = "slash"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.PREPARE; i2.value = 0
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 100; i3.target = IntentRes.TargetType.LOWEST_HP; i3.damage_type = "slash"
	e.intent_pattern = [i1, i2, i3]
	return e

static func anubis_guard(scene: PackedScene) -> Resource:
	# T2-GUARD: 동료에게 block 부여 + 자기 block. 인카운터 #6 보호자 역할
	var e := EnemyRes.new()
	e.enemy_name = "enemy.egyptian.anubis_guard"; e.max_hp = 330; e.character_scene = scene
	e.mythology = "egyptian"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.BUFF; i1.value = 25; i1.status_type = "block"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.BUFF_ALLY; i2.value = 15; i2.status_type = "block"; i2.target = IntentRes.TargetType.LOWEST_HP
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 80; i3.target = IntentRes.TargetType.RANDOM; i3.damage_type = "slash"
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.ATTACK; i4.value = 80; i4.target = IntentRes.TargetType.RANDOM; i4.damage_type = "slash"
	e.intent_pattern = [i1, i2, i3, i4]
	return e

static func nile_crocodile(scene: PackedScene) -> Resource:
	# T1-BERSERK: HP 50% 미만 도달 시 strength +3 자동 (배고픈 짐승)
	var e := EnemyRes.new()
	e.enemy_name = "enemy.egyptian.nile_crocodile"; e.max_hp = 360; e.character_scene = scene
	e.mythology = "egyptian"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 85; i1.target = IntentRes.TargetType.RANDOM; i1.damage_type = "blunt"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 85; i2.target = IntentRes.TargetType.LOWEST_HP; i2.damage_type = "blunt"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.DEBUFF; i3.value = 1; i3.status_type = "vulnerable"; i3.target = IntentRes.TargetType.RANDOM
	e.intent_pattern = [i1, i2, i3]
	e.phase_thresholds = [0.5]
	e.phase_buffs = [[{"status": "strength", "value": 3}]]
	return e

static func clay_soldier(scene: PackedScene) -> Resource:
	# T2-GUARD: 매 사이클 동료에게 block 부여 + 자기 block (점토 진형)
	var e := EnemyRes.new()
	e.enemy_name = "enemy.egyptian.clay_soldier"; e.max_hp = 380; e.character_scene = scene
	e.mythology = "egyptian"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.BUFF; i1.value = 25; i1.status_type = "block"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.BUFF_ALLY; i2.value = 20; i2.status_type = "block"; i2.target = IntentRes.TargetType.LOWEST_HP
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 85; i3.target = IntentRes.TargetType.RANDOM; i3.damage_type = "blunt"
	e.intent_pattern = [i1, i2, i3]
	return e

static func tomb_wraith(scene: PackedScene) -> Resource:
	# T2-DEATH-RATTLE: 죽을 때 무덤의 저주 — ALL vulnerable +2
	var e := EnemyRes.new()
	e.enemy_name = "enemy.egyptian.tomb_wraith"; e.max_hp = 320; e.character_scene = scene
	e.mythology = "egyptian"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.DEBUFF; i1.value = 2; i1.status_type = "weak"; i1.target = IntentRes.TargetType.RANDOM
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 75; i2.target = IntentRes.TargetType.RANDOM; i2.damage_type = "curse"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 75; i3.target = IntentRes.TargetType.RANDOM; i3.damage_type = "curse"
	e.intent_pattern = [i1, i2, i3]
	var dt := IntentRes.new()
	dt.action_type = IntentRes.ActionType.DEBUFF; dt.value = 2; dt.status_type = "vulnerable"; dt.target = IntentRes.TargetType.ALL
	e.death_trigger = dt
	return e

static func khopesh_warrior(scene: PackedScene) -> Resource:
	# T2-BUFFER: 매 사이클 동료에게 strength +1 부여. 자기 공격은 작게
	var e := EnemyRes.new()
	e.enemy_name = "enemy.egyptian.khopesh_warrior"; e.max_hp = 340; e.character_scene = scene
	e.mythology = "egyptian"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.BUFF_ALLY; i1.value = 1; i1.status_type = "strength"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 70; i2.target = IntentRes.TargetType.RANDOM; i2.damage_type = "slash"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 70; i3.target = IntentRes.TargetType.RANDOM; i3.damage_type = "slash"
	e.intent_pattern = [i1, i2, i3]
	return e

static func jackal_priest(scene: PackedScene) -> Resource:
	# T2-HEALER: 매 사이클 LOWEST_HP 동료 HP +25 회복 (자칼 신관)
	var e := EnemyRes.new()
	e.enemy_name = "enemy.egyptian.jackal_priest"; e.max_hp = 280; e.character_scene = scene
	e.mythology = "egyptian"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.HEAL_ALLY; i1.value = 25; i1.target = IntentRes.TargetType.LOWEST_HP
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.DEBUFF; i2.value = 1; i2.status_type = "weak"; i2.target = IntentRes.TargetType.RANDOM
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 55; i3.target = IntentRes.TargetType.RANDOM; i3.damage_type = "curse"
	e.intent_pattern = [i1, i2, i3]
	return e

static func desert_ghoul(scene: PackedScene) -> Resource:
	# T2-DEATH-RATTLE: 죽을 때 원혼의 분노 — 동료에게 strength +2 부여
	var e := EnemyRes.new()
	e.enemy_name = "enemy.egyptian.desert_ghoul"; e.max_hp = 290; e.character_scene = scene
	e.mythology = "egyptian"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 65; i1.target = IntentRes.TargetType.RANDOM; i1.damage_type = "slash"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 65; i2.target = IntentRes.TargetType.RANDOM; i2.damage_type = "slash"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.BUFF; i3.value = 1; i3.status_type = "strength"
	e.intent_pattern = [i1, i2, i3]
	var dt := IntentRes.new()
	dt.action_type = IntentRes.ActionType.BUFF_ALLY; dt.value = 2; dt.status_type = "strength"
	e.death_trigger = dt
	return e

static func sobek_spawn(scene: PackedScene) -> Resource:
	# T1-DESPERATE: HP 30% 미만 도달 시 strength +3 (소벡의 마지막 광기)
	var e := EnemyRes.new()
	e.enemy_name = "enemy.egyptian.sobek_spawn"; e.max_hp = 450; e.character_scene = scene
	e.mythology = "egyptian"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 110; i1.target = IntentRes.TargetType.RANDOM; i1.damage_type = "blunt"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 110; i2.target = IntentRes.TargetType.LOWEST_HP; i2.damage_type = "blunt"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.DEBUFF; i3.value = 2; i3.status_type = "vulnerable"; i3.target = IntentRes.TargetType.RANDOM
	e.intent_pattern = [i1, i2, i3]
	e.phase_thresholds = [0.3]
	e.phase_buffs = [[{"status": "strength", "value": 3}]]
	return e

static func ammit_cub(scene: PackedScene) -> Resource:
	# T1-BERSERK: HP 50% 미만 strength +3 (영혼 포식자의 광기)
	var e := EnemyRes.new()
	e.enemy_name = "enemy.egyptian.ammit_cub"; e.max_hp = 400; e.character_scene = scene
	e.mythology = "egyptian"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.BUFF; i1.value = 1; i1.status_type = "strength"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 100; i2.target = IntentRes.TargetType.RANDOM; i2.damage_type = "slash"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 100; i3.target = IntentRes.TargetType.ALL; i3.damage_type = "slash"
	e.intent_pattern = [i1, i2, i3]
	e.phase_thresholds = [0.5]
	e.phase_buffs = [[{"status": "strength", "value": 3}]]
	return e

static func sphinx_adult(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.egyptian.sphinx_adult"; e.max_hp = 720; e.character_scene = scene
	e.mythology = "egyptian"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 120; i1.target = IntentRes.TargetType.RANDOM; i1.damage_type = "slash"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 120; i2.target = IntentRes.TargetType.RANDOM; i2.damage_type = "slash"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 120; i3.target = IntentRes.TargetType.RANDOM; i3.damage_type = "slash"
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.SPECIAL; i4.value = 1
	var i5 := IntentRes.new()
	i5.action_type = IntentRes.ActionType.ATTACK; i5.value = 150; i5.target = IntentRes.TargetType.LOWEST_HP; i5.damage_type = "slash"
	e.intent_pattern = [i1, i2, i3, i4, i5]
	return e

static func pyramid_golem(scene: PackedScene) -> Resource:
	# T2-GUARD: 동료에게 block 부여 + 자기 큰 block (피라미드 골렘 방어)
	var e := EnemyRes.new()
	e.enemy_name = "enemy.egyptian.pyramid_golem"; e.max_hp = 680; e.character_scene = scene
	e.mythology = "egyptian"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.BUFF; i1.value = 50; i1.status_type = "block"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.BUFF_ALLY; i2.value = 30; i2.status_type = "block"; i2.target = IntentRes.TargetType.LOWEST_HP
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 150; i3.target = IntentRes.TargetType.RANDOM; i3.damage_type = "blunt"
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.ATTACK; i4.value = 100; i4.target = IntentRes.TargetType.ALL; i4.damage_type = "blunt"
	e.intent_pattern = [i1, i2, i3, i4]
	return e

# ──── 인카운터 조합 테이블 (난이도 오름차순 1~10) ────

static func encounters() -> Array:
	return [
		["ka_spirit"],
		["scarab", "scarab"],
		["sphinx_cub"],
		["desert_scorpion", "sand_wraith"],
		["sand_rat", "sand_rat", "sand_rat"],
		["anubis_guard", "sand_scout", "nile_crocodile"],
		["clay_soldier", "clay_soldier", "sand_ifrit"],
		["tomb_wraith", "khopesh_warrior", "jackal_priest", "desert_ghoul"],
		["mummy_warrior", "sobek_spawn", "ammit_cub"],
		["sphinx_adult", "pyramid_golem"],
	]
