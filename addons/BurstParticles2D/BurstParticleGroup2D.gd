@tool

extends Node2D

class_name BurstParticleGroup2D

@export var repeat = true
@export var free_when_finished = true
@export var autostart = true

var lifetime = 0
var finished = true
var _elapsed: float = 0.0
var _counting: bool = false

func _process(delta: float):
	if not _counting:
		return
	_elapsed += delta
	if _elapsed >= lifetime:
		_counting = false
		_elapsed = 0.0
		_finish()

func _ready():
	child_entered_tree.connect(_on_child_entered_tree)
	for child in get_children():
		child.tree_exited.connect(_on_child_exited_tree)
		if child is BurstParticles2D:
			child.finished_burst.connect(_on_child_finished)
		update_children()
	if autostart or Engine.is_editor_hint():
		burst()

func _on_child_entered_tree(child: Node):
	if !child.tree_exited.is_connected(_on_child_exited_tree):
		child.tree_exited.connect(_on_child_exited_tree)
	if child is BurstParticles2D:
		if !child.finished_burst.is_connected(_on_child_finished):
			child.finished_burst.connect(_on_child_finished)
		if autostart or Engine.is_editor_hint():
			burst()

func update_children():
	lifetime = 0
	for child in get_children():
		if child is BurstParticles2D:
			if child.lifetime > lifetime:
				lifetime = child.lifetime
			child.repeat = repeat
			child.free_when_finished = free_when_finished
			child.autostart = autostart
		elif child is GPUParticles2D:
			var gpu_lifetime = child.lifetime * 2.0
			if gpu_lifetime > lifetime:
				lifetime = gpu_lifetime

func burst():
	finished = false
	_elapsed = 0.0
	_counting = true
	update_children()
	for child in get_children():
		if child is BurstParticles2D and child.is_inside_tree():
			child.burst()
		elif child is GPUParticles2D and child.is_inside_tree():
			child.restart()
			var dur: float = child.get_meta("emission_duration", -1.0)
			if dur > 0:
				get_tree().create_timer(dur, false).timeout.connect(func(): child.emitting = false)
		elif not (child is BurstParticles2D or child is GPUParticles2D) \
				and child.has_method("burst") and child.is_inside_tree():
			child.burst()

func _on_child_exited_tree():
	if get_child_count() == 0 and !Engine.is_editor_hint():
		queue_free()

func _on_child_finished():
	for child in get_children():
		if child is BurstParticles2D:
			if !child.finished:
				return
	_finish()

func _finish():
	_counting = false
	if finished:
		return
	finished = true
	if (repeat or Engine.is_editor_hint()):
		burst()
	elif free_when_finished:
		queue_free()
