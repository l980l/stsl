# resources/map_node_resource.gd
class_name MapNodeResource
extends Resource

enum RoomType { BATTLE, ELITE, REST, SHOP, BOSS, EVENT, SECRET }

@export var node_id: int = 0
@export var floor_num: int = 0      # 0 = 첫째 층, 9 = 보스 층
@export var column: int = 0         # 0, 1, 2
@export var room_type: RoomType = RoomType.BATTLE
@export var connections: Array = [] # 다음 층 연결 node_id 목록 (Array[int])
@export var parents: Array = []     # 이전 층 연결 node_id 목록 (Array[int]) — 알고리즘/검증용
@export var visited: bool = false
