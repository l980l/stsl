# scenes/rest/rest_scene.gd
extends Node2D

func _ready() -> void:
	pass  # 버튼 클릭 대기

func _on_heal_pressed() -> void:
	for hero in TeamManager.heroes:
		TeamManager.heal(hero.hero_id, int(hero.max_hp * 0.3))
	_leave()

func _on_leave_pressed() -> void:
	_leave()

func _leave() -> void:
	GameManager._advance_nodes_from(GameManager.current_node_id)
	GameManager.change_state(GameManager.GameState.MAP)
	GameManager._request_scene("res://scenes/map/map_scene.tscn")
