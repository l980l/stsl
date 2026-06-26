# resources/monster_catalog.gd
# 도감용 전체 몬스터 집계기. 각 신화의 normals(encounters) + act1~3(elites+boss) 를 모아 반환.
# 자동 연동: enemy 파일의 encounters()/elites()/boss() 에 등록되면 도감에 자동 노출.
class_name MonsterCatalog
extends RefCounted

# 도감 표시 순서 (= 그룹 순서)
const MYTH_ORDER := ["greek", "egyptian", "norse", "buddhist", "daoist", "japanese"]

const _NORMALS := {
	"greek":    preload("res://resources/enemies/greek/greek_normals.gd"),
	"egyptian": preload("res://resources/enemies/egyptian/egyptian_normals.gd"),
	"norse":    preload("res://resources/enemies/norse/norse_normals.gd"),
	"buddhist": preload("res://resources/enemies/buddhist/buddhist_normals.gd"),
	"daoist":   preload("res://resources/enemies/daoist/daoist_normals.gd"),
	"japanese": preload("res://resources/enemies/japanese/japanese_normals.gd"),
}
const _ACTS := {
	"greek": [preload("res://resources/enemies/greek/greek_act1.gd"), preload("res://resources/enemies/greek/greek_act2.gd"), preload("res://resources/enemies/greek/greek_act3.gd")],
	"egyptian": [preload("res://resources/enemies/egyptian/egyptian_act1.gd"), preload("res://resources/enemies/egyptian/egyptian_act2.gd"), preload("res://resources/enemies/egyptian/egyptian_act3.gd")],
	"norse": [preload("res://resources/enemies/norse/norse_act1.gd"), preload("res://resources/enemies/norse/norse_act2.gd"), preload("res://resources/enemies/norse/norse_act3.gd")],
	"buddhist": [preload("res://resources/enemies/buddhist/buddhist_act1.gd"), preload("res://resources/enemies/buddhist/buddhist_act2.gd"), preload("res://resources/enemies/buddhist/buddhist_act3.gd")],
	"daoist": [preload("res://resources/enemies/daoist/daoist_act1.gd"), preload("res://resources/enemies/daoist/daoist_act2.gd"), preload("res://resources/enemies/daoist/daoist_act3.gd")],
	"japanese": [preload("res://resources/enemies/japanese/japanese_act1.gd"), preload("res://resources/enemies/japanese/japanese_act2.gd"), preload("res://resources/enemies/japanese/japanese_act3.gd")],
}

# 몬스터 고유 식별 키 — enemy_name ("enemy.{myth}.{slug}") 은 전역 유일.
static func monster_key(enemy) -> String:
	return enemy.enemy_name

# 전체 몬스터 배열. enemy_name 으로 중복 제거.
static func get_all_monsters() -> Array:
	var out: Array = []
	var seen: Dictionary = {}
	for myth in MYTH_ORDER:
		var nf = _NORMALS[myth]
		for grp in nf.encounters():
			for nm in grp:
				_add(nf, nm, out, seen)
		for af in _ACTS[myth]:
			for nm in af.elites():
				_add(af, nm, out, seen)
			_add(af, af.boss(), out, seen)
	return out

# 메서드명 문자열 → EnemyResource (정적 함수 호출, scene 은 도감에서 불필요하므로 null)
static func _add(file, method: String, out: Array, seen: Dictionary) -> void:
	if method == "" or not file.has_method(method):
		return
	var e = file.call(method, null)
	if e == null or e.enemy_name == "" or e.enemy_name in seen:
		return
	seen[e.enemy_name] = true
	out.append(e)
