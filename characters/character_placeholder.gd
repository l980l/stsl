# characters/character_placeholder.gd
# 플레이스홀더 캐릭터 공통 스크립트
# Blender 스프라이트 시트 완성 후 이 스크립트를 제거하고
# AnimatedSprite2D + 실제 스프라이트로 교체하면 됨
extends Node2D

const _FLASH_SHADER := """
shader_type canvas_item;
uniform vec4 flash_color : source_color = vec4(0.0);
void fragment() {
	// 평소 ColorRect alpha 유지 — alpha=1 강제 시 일러스트 뒤의 placeholder 가 사각형으로 노출됨
	COLOR.rgb += flash_color.rgb * flash_color.a;
}
"""

@onready var body: ColorRect = $Body
@onready var anim_player: AnimationPlayer = $AnimationPlayer

var _flash_mat: ShaderMaterial = null
var _flash_tween: Tween = null

func _ready() -> void:
	var shader := Shader.new()
	shader.code = _FLASH_SHADER
	_flash_mat = ShaderMaterial.new()
	_flash_mat.shader = shader
	body.material = _flash_mat
	_build_animations()
	anim_player.play("idle")

func flash(color: Color, duration: float) -> void:
	if _flash_tween and _flash_tween.is_valid(): _flash_tween.kill()
	_flash_mat.set_shader_parameter("flash_color", color)
	_flash_tween = create_tween()
	_flash_tween.tween_method(
		func(a: float) -> void: _flash_mat.set_shader_parameter("flash_color", Color(color.r, color.g, color.b, a)),
		color.a, 0.0, duration
	)

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
	a.length = 1.0
	return a

func _make_attack() -> Animation:
	var rest := body.position
	var a := Animation.new()
	a.length = 0.5
	var t := a.add_track(Animation.TYPE_VALUE)
	a.track_set_path(t, "Body:position")
	a.track_insert_key(t, 0.0, rest)
	a.track_insert_key(t, 0.2, rest + Vector2(60, 0))
	a.track_insert_key(t, 0.5, rest)
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
