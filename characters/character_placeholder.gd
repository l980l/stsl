# characters/character_placeholder.gd
# 플레이스홀더 캐릭터 공통 스크립트
# Blender 스프라이트 시트 완성 후 이 스크립트를 제거하고
# AnimatedSprite2D + 실제 스프라이트로 교체하면 됨
extends Node2D

@onready var body: ColorRect = $Body
@onready var anim_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	_build_animations()
	anim_player.play("idle")

func _build_animations() -> void:
	var lib := AnimationLibrary.new()
	lib.add_animation("idle", _make_idle())
	lib.add_animation("attack", _make_attack())
	lib.add_animation("hurt", _make_hurt())
	lib.add_animation("death", _make_death())
	anim_player.add_animation_library("", lib)

func _make_idle() -> Animation:
	var a := Animation.new()
	a.loop_mode = Animation.LOOP_LINEAR
	a.length = 1.2
	var t := a.add_track(Animation.TYPE_VALUE)
	a.track_set_path(t, "Body:position")
	a.track_insert_key(t, 0.0, Vector2.ZERO)
	a.track_insert_key(t, 0.6, Vector2(0, -8))
	a.track_insert_key(t, 1.2, Vector2.ZERO)
	return a

func _make_attack() -> Animation:
	var a := Animation.new()
	a.length = 0.5
	var t := a.add_track(Animation.TYPE_VALUE)
	a.track_set_path(t, "Body:position")
	a.track_insert_key(t, 0.0, Vector2.ZERO)
	a.track_insert_key(t, 0.2, Vector2(60, 0))
	a.track_insert_key(t, 0.5, Vector2.ZERO)
	return a

func _make_hurt() -> Animation:
	var a := Animation.new()
	a.length = 0.4
	var t := a.add_track(Animation.TYPE_VALUE)
	a.track_set_path(t, "Body:modulate")
	a.track_insert_key(t, 0.0, Color.WHITE)
	a.track_insert_key(t, 0.1, Color(1.0, 0.267, 0.267, 1.0))
	a.track_insert_key(t, 0.4, Color.WHITE)
	return a

func _make_death() -> Animation:
	var a := Animation.new()
	a.length = 0.8
	var t := a.add_track(Animation.TYPE_VALUE)
	a.track_set_path(t, "Body:modulate")
	a.track_insert_key(t, 0.0, Color.WHITE)
	a.track_insert_key(t, 0.8, Color(1, 1, 1, 0))
	return a
