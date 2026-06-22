# characters/character_placeholder.gd
# 플레이스홀더 캐릭터 공통 스크립트
# Blender 스프라이트 시트 완성 후 이 스크립트를 제거하고
# AnimatedSprite2D + 실제 스프라이트로 교체하면 됨
extends Node2D

const _FLASH_SHADER := """
shader_type canvas_item;
uniform vec4 flash_color : source_color = vec4(0.0);
uniform float desat : hint_range(0.0, 1.0) = 0.0;  // 사망 시 회색조 (0=원색, 1=완전 흑백)
void fragment() {
	// 평소 ColorRect alpha 유지 — alpha=1 강제 시 일러스트 뒤의 placeholder 가 사각형으로 노출됨
	float gray = dot(COLOR.rgb, vec3(0.299, 0.587, 0.114));
	COLOR.rgb = mix(COLOR.rgb, vec3(gray), desat);
	COLOR.rgb += flash_color.rgb * flash_color.a;
}
"""

@onready var body: ColorRect = $Body
@onready var anim_player: AnimationPlayer = $AnimationPlayer

const _HERO_ART_DIR := "res://assets/art/heroes/"
# 캐릭터 sprite 영역 — placeholder Body ColorRect 와 동일 (80x80 local).
# 일러스트는 이 영역 안에 비율 유지하며 맞춤.
const _SPRITE_W := 80.0
const _SPRITE_H := 80.0

var _flash_mat: ShaderMaterial = null
var _flash_tween: Tween = null
var _gray_tween: Tween = null
var _illust_sprite: Sprite2D = null

func _ready() -> void:
	var shader := Shader.new()
	shader.code = _FLASH_SHADER
	_flash_mat = ShaderMaterial.new()
	_flash_mat.shader = shader
	body.material = _flash_mat
	# 영웅 일러스트 — node.name ("Napoleon") → owner_id ("napoleon") → assets/art/heroes/{id}.png
	var hero_id: String = name.to_snake_case()
	var illust_path: String = _HERO_ART_DIR + hero_id + ".png"
	if ResourceLoader.exists(illust_path):
		_illust_sprite = Sprite2D.new()
		var tex: Texture2D = load(illust_path)
		_illust_sprite.texture = tex
		var src_size: Vector2 = tex.get_size()
		# 외부 char_node.scale 비균등 (1.44, 2.4) 으로 sprite 가 시각상 늘어남 →
		# sprite.scale 을 외부 역수로 보정 (sx*ext_x = sy*ext_y) → 시각 비율 유지 (uniform).
		var ext_x: float = absf(scale.x) if absf(scale.x) > 0.0001 else 1.0
		var ext_y: float = absf(scale.y) if absf(scale.y) > 0.0001 else 1.0
		var area_w: float = _SPRITE_W * ext_x  # 시각 영역 가로
		var area_h: float = _SPRITE_H * ext_y  # 시각 영역 세로
		# 시각상 cover (큰 쪽 기준) — 한쪽 일치 후 다른 쪽 영역 초과 region 잘림.
		var a_w: float = area_w / src_size.x  # 시각상 가로 일치 시 common scale
		var a_h: float = area_h / src_size.y  # 시각상 세로 일치 시 common scale
		var a: float = max(a_w, a_h)
		_illust_sprite.scale = Vector2(a / ext_x, a / ext_y)
		# region 잘림 — 작은 쪽이 영역 초과
		if a == a_w:
			# 가로 일치, 세로 초과면 아래쪽 잘림
			var max_src_h: float = area_h / a
			if src_size.y > max_src_h:
				_illust_sprite.region_enabled = true
				_illust_sprite.region_rect = Rect2(0, 0, src_size.x, max_src_h)
		else:
			# 세로 일치, 가로 초과면 좌우 가운데 잘림
			var max_src_w: float = area_w / a
			if src_size.x > max_src_w:
				_illust_sprite.region_enabled = true
				var x_off: float = (src_size.x - max_src_w) / 2.0
				_illust_sprite.region_rect = Rect2(x_off, 0, max_src_w, src_size.y)
		_illust_sprite.position = Vector2.ZERO
		add_child(_illust_sprite)
		# placeholder ColorRect 숨김
		body.color = Color(0, 0, 0, 0)
		# flash shader 를 sprite 로 이동
		_illust_sprite.material = _flash_mat
		body.material = null
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

# 사망 시 스프라이트를 부드럽게 회색조로 — 디졸브 VFX 와 병행, alpha 페이드는 하지 않음 (시체로 남김).
func set_dead_grayscale(duration: float = 0.6) -> void:
	if _flash_mat == null:
		return
	if _gray_tween and _gray_tween.is_valid(): _gray_tween.kill()
	_gray_tween = create_tween()
	_gray_tween.tween_method(
		func(v: float) -> void: _flash_mat.set_shader_parameter("desat", v),
		0.0, 1.0, duration
	).set_ease(Tween.EASE_OUT)

# 부활 시 원색 복구
func clear_grayscale() -> void:
	if _gray_tween and _gray_tween.is_valid(): _gray_tween.kill()
	if _flash_mat != null:
		_flash_mat.set_shader_parameter("desat", 0.0)

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
