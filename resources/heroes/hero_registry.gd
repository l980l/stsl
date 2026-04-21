# resources/heroes/hero_registry.gd
# 영웅 중앙 레지스트리 — 영웅 데이터 단일 정의 지점
# M5 영웅 추가 시 이 파일에만 분기 추가하면 해금·씬·영입 전체에 반영됨
class_name HeroRegistry
extends RefCounted

static func all_hero_ids() -> Array:
	return ["napoleon", "cleopatra", "yi_sun_sin"]

static func make_hero(hero_id: String) -> Resource:
	var HeroRes = load("res://resources/hero_resource.gd")
	var hero: Resource = HeroRes.new()
	hero.hero_id = hero_id
	match hero_id:
		"napoleon":
			hero.hero_name = "나폴레옹"
			hero.historical_figure = "나폴레옹 보나파르트"
			hero.max_hp = 1000
			hero.character_scene = load("res://characters/heroes/napoleon/napoleon.tscn")
			hero.unlock_condition = "default"
			hero.unlock_description = ""
		"cleopatra":
			hero.hero_name = "클레오파트라"
			hero.historical_figure = "클레오파트라 7세"
			hero.max_hp = 1000
			hero.character_scene = load("res://characters/heroes/cleopatra/cleopatra.tscn")
			hero.unlock_condition = "default"
			hero.unlock_description = ""
		"yi_sun_sin":
			hero.hero_name = "이순신"
			hero.historical_figure = "이순신 장군"
			hero.max_hp = 1000
			hero.character_scene = load("res://characters/heroes/yi_sun_sin/yi_sun_sin.tscn")
			hero.unlock_condition = "default"
			hero.unlock_description = ""
	return hero

static func get_display_info(hero_id: String) -> Dictionary:
	match hero_id:
		"napoleon":
			return {
				"name": "나폴레옹",
				"hp": 1000,
				"desc": "포지션: 공격형 지휘관\n고유 메카닉: 사기(Morale)\n아키타입: 돌격(Blitz)\n\n스타터: 스트라이크×3 + 디펜드×2",
				"unlock_description": "",
			}
		"cleopatra":
			return {
				"name": "클레오파트라",
				"hp": 1000,
				"desc": "포지션: 디버프/조종형\n고유 메카닉: 매혹(Charm)\n아키타입: 독살(Venom)\n\n스타터: 독침×2 + 왕실 방어×2",
				"unlock_description": "",
			}
		"yi_sun_sin":
			return {
				"name": "이순신",
				"hp": 1000,
				"desc": "포지션: 방어형 역공\n고유 메카닉: 진형(Formation)\n아키타입: 거북선(Turtle)\n\n스타터: 방패×2 + 역공×2",
				"unlock_description": "",
			}
	return {}
