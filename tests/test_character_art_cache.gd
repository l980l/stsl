class_name TestCharacterArtCache
extends RefCounted

const CACHE := preload("res://characters/character_art_cache.gd")
const HERO_SCENE := preload("res://characters/heroes/cleopatra/cleopatra.tscn")
const ENEMY_SCENE := preload("res://characters/enemies/enemy_placeholder.tscn")
const HERO_ART := "res://assets/art/heroes/cleopatra.png"
const ENEMY_ID := "enemy.egyptian.scarab"

var passed := 0
var failed := 0

func run_all() -> Dictionary:
	test_cached_identity_without_live_nodes()
	test_fifo_eviction_is_bounded()
	test_missing_path_is_not_cached()
	test_battle_selection_only()
	test_sprite_fit_and_per_instance_materials()
	CACHE.clear()
	return {"passed": passed, "failed": failed}

func test_battle_selection_only() -> void:
	var hero := preload("res://resources/hero_resource.gd").new()
	hero.character_scene = HERO_SCENE
	var enemy := preload("res://resources/enemy_resource.gd").new()
	enemy.enemy_name = ENEMY_ID
	enemy.character_scene = ENEMY_SCENE
	CACHE.clear()
	var paths := CACHE.battle_paths([hero], [enemy, enemy])
	_assert(paths.size() == 2, "next battle includes only selected hero and distinct enemy art")
	_assert(HERO_ART in paths, "hero path follows actual scene root name")
	_assert("res://assets/art/enemies/egyptian_scarab.png" in paths, "enemy path matches runtime ID")
	_assert(CACHE.size() == 0, "selecting paths does not eagerly load unrelated art")
	enemy.enemy_name = "enemy.invalid.missing"
	_assert(CACHE.battle_paths([], [enemy]).is_empty(), "missing art remains placeholder without loading")
	enemy.enemy_name = ENEMY_ID
	enemy.character_scene = null
	_assert(CACHE.battle_paths([], [enemy]).is_empty(), "fallback-only enemy does not prepare unused illustration")
	enemy.character_scene = ENEMY_SCENE
	enemy.enemy_name = "enemy.greek.hydra"
	enemy.phase_thresholds = [0.6, 0.3]
	paths = CACHE.battle_paths([], [enemy])
	_assert("res://assets/art/enemies/greek_hydra_p2.png" in paths, "selected boss phase illustration is prepared")
	_assert("res://assets/art/enemies/egyptian_scarab.png" not in paths, "unselected enemy illustration is not prepared")

func _assert(condition: bool, message: String) -> void:
	if condition:
		passed += 1
		print("  PASS: " + message)
	else:
		failed += 1
		print("  FAIL: " + message)

func test_cached_identity_without_live_nodes() -> void:
	print("[TestCharacterArtCache] test_cached_identity_without_live_nodes")
	CACHE.clear()
	var first := CACHE.get_texture(HERO_ART)
	var second := CACHE.get_texture(HERO_ART)
	_assert(first != null, "실제 영웅 아트 로드")
	_assert(first == second, "라이브 캐릭터 노드 없이도 동일 Texture2D 재사용")
	_assert(CACHE.size() == 1, "동일 경로는 캐시 항목 하나")

func test_fifo_eviction_is_bounded() -> void:
	print("[TestCharacterArtCache] test_fifo_eviction_is_bounded")
	CACHE.clear()
	var files := DirAccess.get_files_at("res://assets/art/enemies/")
	var paths: Array[String] = []
	for file_name in files:
		if file_name.ends_with(".png"):
			paths.append("res://assets/art/enemies/" + file_name)
			if paths.size() > CACHE.max_entries():
				break
	_assert(paths.size() > CACHE.max_entries(), "FIFO 검증용 아트가 캐시 한도보다 많음")
	for path in paths:
		CACHE.get_texture(path)
	_assert(CACHE.size() == CACHE.max_entries(), "캐시 크기는 최대 항목 수로 제한")
	_assert(not CACHE.has_texture(paths[0]), "가장 먼저 넣은 항목이 FIFO로 제거")
	_assert(CACHE.has_texture(paths.back()), "가장 나중에 넣은 항목은 유지")

func test_missing_path_is_not_cached() -> void:
	print("[TestCharacterArtCache] test_missing_path_is_not_cached")
	CACHE.clear()
	var texture := CACHE.get_texture("res://assets/art/enemies/not_a_real_enemy.png")
	_assert(texture == null, "없는 아트는 null → 기존 placeholder 유지")
	_assert(CACHE.size() == 0, "없는 경로는 캐시에 넣지 않음")

func test_sprite_fit_and_per_instance_materials() -> void:
	print("[TestCharacterArtCache] test_sprite_fit_and_per_instance_materials")
	CACHE.clear()
	var tree := Engine.get_main_loop() as SceneTree
	var hero_a := HERO_SCENE.instantiate()
	var hero_b := HERO_SCENE.instantiate()
	hero_a.scale = Vector2(1.44, 2.4)
	hero_b.scale = Vector2(1.44, 2.4)
	# Separate parents preserve both node names (art ID comes from the name).
	var parent_a := Node2D.new()
	var parent_b := Node2D.new()
	tree.root.add_child(parent_a)
	tree.root.add_child(parent_b)
	parent_a.add_child(hero_a)
	parent_b.add_child(hero_b)
	var hero_sprite_a: Sprite2D = hero_a.get("_illust_sprite")
	var hero_sprite_b: Sprite2D = hero_b.get("_illust_sprite")
	_assert(hero_sprite_a != null and hero_sprite_b != null, "캐시 적용 후에도 영웅 스프라이트 생성")
	_assert(hero_sprite_a.texture == hero_sprite_b.texture, "영웅 인스턴스는 같은 캐시 텍스처 공유")
	_assert(hero_sprite_a.material != hero_sprite_b.material, "영웅별 flash ShaderMaterial은 독립")
	_assert(_has_expected_fit(hero_sprite_a, hero_a.scale), "영웅 sprite fit 비율 유지")

	var enemy_a := ENEMY_SCENE.instantiate()
	var enemy_b := ENEMY_SCENE.instantiate()
	enemy_a.scale = Vector2(-1.44, 2.4)
	enemy_b.scale = Vector2(-1.44, 2.4)
	tree.root.add_child(enemy_a)
	tree.root.add_child(enemy_b)
	enemy_a.set_enemy_id(ENEMY_ID)
	enemy_b.set_enemy_id(ENEMY_ID)
	var enemy_sprite_a: Sprite2D = enemy_a.get("_illust_sprite")
	var enemy_sprite_b: Sprite2D = enemy_b.get("_illust_sprite")
	_assert(enemy_sprite_a != null and enemy_sprite_b != null, "캐시 적용 후에도 적 스프라이트 생성")
	_assert(enemy_sprite_a.texture == enemy_sprite_b.texture, "적 인스턴스는 같은 캐시 텍스처 공유")
	_assert(enemy_sprite_a.material != enemy_sprite_b.material, "적별 flash ShaderMaterial은 독립")
	_assert(_has_expected_fit(enemy_sprite_a, enemy_a.scale), "적 sprite fit 비율 유지")

	hero_a.free()
	hero_b.free()
	enemy_a.free()
	enemy_b.free()
	parent_a.free()
	parent_b.free()

func _has_expected_fit(sprite: Sprite2D, external_scale: Vector2) -> bool:
	if sprite == null or sprite.texture == null:
		return false
	var texture_size: Vector2 = sprite.texture.get_size()
	var ext_x := absf(external_scale.x)
	var ext_y := absf(external_scale.y)
	var visual_scale: float = maxf(80.0 * ext_x / texture_size.x, 80.0 * ext_y / texture_size.y)
	return is_equal_approx(sprite.scale.x, visual_scale / ext_x) and is_equal_approx(sprite.scale.y, visual_scale / ext_y)
