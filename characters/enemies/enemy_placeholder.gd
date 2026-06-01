# characters/enemies/enemy_placeholder.gd
# 몬스터 일러스트 표시 placeholder — character_placeholder 의 영웅용 패턴을 enemy 에 맞게 복제.
# 사용법: scene.instantiate() 후 set_enemy_id("enemy.greek.hydra") 호출 → assets/art/enemies/greek_hydra.png 로드.
# 페이즈 전환 시 battle_scene._on_boss_phase_changed 가 swap_to_phase(N) 호출 → _pN.png 가 있으면 교체.
extends Node2D

const _FLASH_SHADER := """
shader_type canvas_item;
uniform vec4 flash_color : source_color = vec4(0.0);
void fragment() {
	COLOR.rgb += flash_color.rgb * flash_color.a;
}
"""

@onready var body: ColorRect = $Body
@onready var anim_player: AnimationPlayer = $AnimationPlayer

const _ENEMY_ART_DIR := "res://assets/art/enemies/"
# 캐릭터 sprite 영역 — character_placeholder 와 동일 (80×80 local, 외부 scale 로 시각 확대).
const _SPRITE_W := 80.0
const _SPRITE_H := 80.0

var _flash_mat: ShaderMaterial = null
var _flash_tween: Tween = null
var _illust_sprite: Sprite2D = null
var _enemy_id: String = ""    # "{myth}_{name}" 형식 — 페이즈 swap 시 사용
var _phase: int = 0

func _ready() -> void:
	var shader := Shader.new()
	shader.code = _FLASH_SHADER
	_flash_mat = ShaderMaterial.new()
	_flash_mat.shader = shader
	body.material = _flash_mat
	_build_animations()
	anim_player.play("idle")

# battle_scene 가 enemy 스폰 직후 호출. enemy_name = "enemy.{myth}.{name}".
func set_enemy_id(enemy_name: String) -> void:
	# "enemy.greek.hydra" → "greek_hydra"
	var parts: PackedStringArray = enemy_name.split(".")
	if parts.size() >= 3:
		_enemy_id = "%s_%s" % [parts[1], parts[2]]
	else:
		# fallback — enemy_name 그대로 사용
		_enemy_id = enemy_name
	_phase = 0
	_load_sprite(0)

# battle_scene._on_boss_phase_changed 가 호출. _p{phase}.png 없으면 직전 sprite 유지.
func swap_to_phase(phase: int) -> void:
	if phase <= 0 or _enemy_id == "":
		return
	var path := _ENEMY_ART_DIR + "%s_p%d.png" % [_enemy_id, phase]
	if not ResourceLoader.exists(path):
		return  # 이미지 없으면 swap 안 함
	_phase = phase
	_apply_texture(load(path))

# phase 0 일러스트 로드 + Sprite2D 셋업
func _load_sprite(phase: int) -> void:
	if _enemy_id == "":
		return
	var path: String
	if phase <= 0:
		path = _ENEMY_ART_DIR + _enemy_id + ".png"
	else:
		path = _ENEMY_ART_DIR + "%s_p%d.png" % [_enemy_id, phase]
		if not ResourceLoader.exists(path):
			path = _ENEMY_ART_DIR + _enemy_id + ".png"
	if not ResourceLoader.exists(path):
		return  # 이미지 없으면 placeholder ColorRect (빨강) 유지
	_apply_texture(load(path))

# Sprite2D 생성 (최초) 또는 텍스처 교체 (페이즈 swap). character_placeholder fit 알고리즘 그대로.
func _apply_texture(tex: Texture2D) -> void:
	if _illust_sprite == null:
		_illust_sprite = Sprite2D.new()
		add_child(_illust_sprite)
		_illust_sprite.position = Vector2.ZERO
		# placeholder ColorRect 숨김 + flash shader 를 sprite 로 이동
		body.color = Color(0, 0, 0, 0)
		_illust_sprite.material = _flash_mat
		body.material = null
	_illust_sprite.texture = tex
	var src_size: Vector2 = tex.get_size()
	# 외부 char_node.scale 비균등 (1.44, 2.4) 으로 sprite 가 시각상 늘어남 →
	# sprite.scale 을 외부 역수로 보정해 시각 비율 유지 (uniform).
	var ext_x: float = absf(scale.x) if absf(scale.x) > 0.0001 else 1.0
	var ext_y: float = absf(scale.y) if absf(scale.y) > 0.0001 else 1.0
	var area_w: float = _SPRITE_W * ext_x
	var area_h: float = _SPRITE_H * ext_y
	# 시각상 cover (큰 쪽 기준) — 한쪽 일치 후 다른 쪽 영역 초과 region 잘림
	var a_w: float = area_w / src_size.x
	var a_h: float = area_h / src_size.y
	var a: float = max(a_w, a_h)
	_illust_sprite.scale = Vector2(a / ext_x, a / ext_y)
	_illust_sprite.region_enabled = false
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
