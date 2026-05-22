# tests/test_damage_pipeline.gd
# DamageContext + compute_damage() 순수 함수 단위 테스트.
# autoload 의존 없음 — BattleManagerClass를 직접 preload해 static 함수 호출.
class_name TestDamagePipeline
extends RefCounted

const BattleManagerClass = preload("res://autoload/battle_manager.gd")

var passed: int = 0
var failed: int = 0

func run_all() -> Dictionary:
	test_base_only()
	test_flat_bonus()
	test_out_pct()
	test_combined_flat_out_pct_crit()
	test_in_pct_vulnerable()
	test_dnd_mult()
	test_mitigation_chain()
	test_invuln()
	test_no_negative_result()
	return {"passed": passed, "failed": failed}

func _assert(cond: bool, msg: String) -> void:
	if cond:
		passed += 1
		print("  PASS: " + msg)
	else:
		failed += 1
		print("  FAIL: " + msg)

func _make_ctx() -> BattleManagerClass.DamageContext:
	return BattleManagerClass.DamageContext.new()

func test_base_only() -> void:
	print("[TestDamagePipeline] test_base_only")
	# base 20, 모디파이어 없음 → 20
	var ctx := _make_ctx()
	ctx.base = 20
	_assert(BattleManagerClass.compute_damage(ctx) == 20, "base 20 → 20")

func test_flat_bonus() -> void:
	print("[TestDamagePipeline] test_flat_bonus")
	# base 20, flat 5 → 25
	var ctx := _make_ctx()
	ctx.base = 20
	ctx.flat = 5
	_assert(BattleManagerClass.compute_damage(ctx) == 25, "base 20 + flat 5 → 25")

func test_out_pct() -> void:
	print("[TestDamagePipeline] test_out_pct")
	# base 20, out_pct 0.25 → floor(20 × 1.25) = 25
	var ctx := _make_ctx()
	ctx.base = 20
	ctx.out_pct = 0.25
	_assert(BattleManagerClass.compute_damage(ctx) == 25, "base 20 × (1+0.25) → 25")

func test_combined_flat_out_pct_crit() -> void:
	print("[TestDamagePipeline] test_combined_flat_out_pct_crit")
	# base 20, flat 5, out_pct 0.25, crit_mult 3.0
	# → floor(25 × 1.25 × 3.0) = floor(93.75) = 93
	var ctx := _make_ctx()
	ctx.base = 20
	ctx.flat = 5
	ctx.out_pct = 0.25
	ctx.crit_mult = 3.0
	_assert(BattleManagerClass.compute_damage(ctx) == 93, "base 20 flat 5 out_pct 0.25 crit ×3 → 93")

func test_in_pct_vulnerable() -> void:
	print("[TestDamagePipeline] test_in_pct_vulnerable")
	# base 20, in_pct 0.5 → floor(20 × 1.5) = 30
	var ctx := _make_ctx()
	ctx.base = 20
	ctx.in_pct = 0.5
	_assert(BattleManagerClass.compute_damage(ctx) == 30, "base 20 vulnerable(+0.5) → 30")

func test_dnd_mult() -> void:
	print("[TestDamagePipeline] test_dnd_mult")
	# base 20, dnd_mult 2.0 → 40
	var ctx := _make_ctx()
	ctx.base = 20
	ctx.dnd_mult = 2.0
	_assert(BattleManagerClass.compute_damage(ctx) == 40, "base 20 dnd ×2 → 40")

func test_mitigation_chain() -> void:
	print("[TestDamagePipeline] test_mitigation_chain")
	# base 100, mitigation [0.5, 0.2] → floor(100 × 0.5 × 0.2) = 10
	var ctx := _make_ctx()
	ctx.base = 100
	ctx.mitigation = [0.5, 0.2]
	_assert(BattleManagerClass.compute_damage(ctx) == 10, "base 100 × 0.5 × 0.2 → 10")

func test_invuln() -> void:
	print("[TestDamagePipeline] test_invuln")
	# invuln=true → 0 (base 999여도)
	var ctx := _make_ctx()
	ctx.base = 999
	ctx.flat = 100
	ctx.invuln = true
	_assert(BattleManagerClass.compute_damage(ctx) == 0, "invuln → 0")

func test_no_negative_result() -> void:
	print("[TestDamagePipeline] test_no_negative_result")
	# base 5, mitigation 극소값 → 결과 ≥ 0 (max(0,...) 보장)
	var ctx := _make_ctx()
	ctx.base = 5
	ctx.mitigation = [0.0]
	_assert(BattleManagerClass.compute_damage(ctx) >= 0, "mitigation 0.0이어도 결과 ≥ 0")
