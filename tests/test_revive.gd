# tests/test_revive.gd
# 부활(REVIVE) 버그 수정 검증 테스트 (Plan 28-B)
class_name TestRevive
extends RefCounted

const TeamManagerClass   = preload("res://autoload/team_manager.gd")
const BattleManagerClass = preload("res://autoload/battle_manager.gd")
const DeckManagerClass   = preload("res://autoload/deck_manager.gd")
const HeroRes            = preload("res://resources/hero_resource.gd")
const EnemyRes           = preload("res://resources/enemy_resource.gd")
const IntentRes          = preload("res://resources/intent_resource.gd")

var passed: int = 0
var failed: int = 0
var _signal_counter: int = 0

func run_all() -> Dictionary:
	print("[TestRevive] 부활 버그 수정 테스트 시작")
	test_revive_clears_block()
	test_revive_clears_status()
	test_revive_emits_signal()
	test_team_manager_saves_alive_state()
	test_team_manager_from_dict_without_alive_key()
	return { "passed": passed, "failed": failed }

func _assert(cond: bool, msg: String) -> void:
	if cond:
		print("  PASS: " + msg)
		passed += 1
	else:
		print("  FAIL: " + msg)
		failed += 1

# ────────────────────────────────────────────
# 헬퍼
# ────────────────────────────────────────────

func _make_bm() -> BattleManagerClass:
	var bm := BattleManagerClass.new()
	bm.team_mgr = TeamManagerClass.new()
	bm.deck_mgr = DeckManagerClass.new()
	return bm

func _make_hero(id: String, hp: int) -> Resource:
	var h := HeroRes.new()
	h.hero_id = id
	h.hero_name = id
	h.max_hp = hp
	return h

func _make_dummy_enemy() -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "더미 적"
	e.max_hp = 10
	var intent := IntentRes.new()
	intent.action_type = IntentRes.ActionType.ATTACK
	intent.value = 1
	intent.target = IntentRes.TargetType.RANDOM
	e.intent_pattern = [intent]
	return e

# ────────────────────────────────────────────
# 1. revive() → 블록 0 초기화
# ────────────────────────────────────────────
func test_revive_clears_block() -> void:
	print("[TestRevive] test_revive_clears_block")
	var bm := _make_bm()
	var tm: TeamManagerClass = bm.team_mgr
	tm.add_hero(_make_hero("napoleon", 50))
	bm.setup_battle([_make_dummy_enemy()])

	# 블록 10 부여 후 사망
	bm._hero_block["napoleon"] = 10
	tm._hero_alive["napoleon"] = false
	tm._hero_hp["napoleon"] = 0

	# 부활
	tm.revive("napoleon", 20)

	_assert(bm._hero_block.get("napoleon", -1) == 0,
		"revive() 후 _hero_block == 0")

# ────────────────────────────────────────────
# 2. revive() → 상태(독 등) 초기화
# ────────────────────────────────────────────
func test_revive_clears_status() -> void:
	print("[TestRevive] test_revive_clears_status")
	var bm := _make_bm()
	var tm: TeamManagerClass = bm.team_mgr
	tm.add_hero(_make_hero("napoleon", 50))
	bm.setup_battle([_make_dummy_enemy()])

	# 독 상태 부여 후 사망
	bm._hero_status["napoleon"] = {"poison_dmg": 5, "poison_dur": 3}
	tm._hero_alive["napoleon"] = false
	tm._hero_hp["napoleon"] = 0

	# 부활
	tm.revive("napoleon", 20)

	var status: Dictionary = bm._hero_status.get("napoleon", {"_not_cleared": true})
	_assert(status.is_empty(),
		"revive() 후 _hero_status 비어있음")

# ────────────────────────────────────────────
# 3. revive() → hero_revived 시그널 1회 emit
# ────────────────────────────────────────────
func _on_test_revived(_id: String) -> void:
	_signal_counter += 1

func test_revive_emits_signal() -> void:
	print("[TestRevive] test_revive_emits_signal")
	var tm := TeamManagerClass.new()
	tm.add_hero(_make_hero("napoleon", 50))
	tm._hero_alive["napoleon"] = false
	tm._hero_hp["napoleon"] = 0

	_signal_counter = 0
	tm.hero_revived.connect(_on_test_revived)

	tm.revive("napoleon", 20)

	_assert(_signal_counter == 1,
		"revive() 호출 시 hero_revived 시그널 1회 emit")

# ────────────────────────────────────────────
# 4. to_dict() → from_dict() : alive==false 유지
# ────────────────────────────────────────────
func test_team_manager_saves_alive_state() -> void:
	print("[TestRevive] test_team_manager_saves_alive_state")
	var tm := TeamManagerClass.new()
	tm.add_hero(_make_hero("napoleon", 50))
	tm.add_hero(_make_hero("cleopatra", 60))

	# napoleon 사망 처리
	tm._hero_alive["napoleon"] = false
	tm._hero_hp["napoleon"] = 0

	# 저장 → 복원
	var d: Dictionary = tm.to_dict()
	var tm2 := TeamManagerClass.new()
	tm2.from_dict(d)

	_assert(tm2.is_alive("napoleon") == false,
		"저장/로드 후 사망한 napoleon은 alive==false 유지")
	_assert(tm2.is_alive("cleopatra") == true,
		"저장/로드 후 생존한 cleopatra는 alive==true 유지")

# ────────────────────────────────────────────
# 5. hero_alive 키 없는 dict → from_dict → 전원 alive==true
# ────────────────────────────────────────────
func test_team_manager_from_dict_without_alive_key() -> void:
	print("[TestRevive] test_team_manager_from_dict_without_alive_key")
	# 구버전 세이브 데이터 (hero_alive 키 없음)
	var legacy_dict: Dictionary = {
		"heroes": [
			{"hero_id": "napoleon", "hero_name": "나폴레옹", "max_hp": 70, "current_hp": 35},
			{"hero_id": "cleopatra", "hero_name": "클레오파트라", "max_hp": 60, "current_hp": 60},
		]
	}
	var tm := TeamManagerClass.new()
	tm.from_dict(legacy_dict)

	_assert(tm.is_alive("napoleon") == true,
		"hero_alive 키 없는 구버전 세이브 → napoleon alive==true")
	_assert(tm.is_alive("cleopatra") == true,
		"hero_alive 키 없는 구버전 세이브 → cleopatra alive==true")
