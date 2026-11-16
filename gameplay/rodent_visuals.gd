extends Node2D
## Connects the rodent rule manager to the imported character scenes and animations.

const BirdScene: PackedScene = preload("res://modes/rodent/Bird.tscn")
const MouseScene: PackedScene = preload("res://modes/rodent/Mouse.tscn")
const CockroachScene: PackedScene = preload("res://modes/rodent/Cockroach.tscn")
const BackgroundScene: PackedScene = preload("res://modes/rodent/RodentBackground.tscn")

var mode: RodentMode
var _background: Node2D
var _bird: Node2D
var _bird_sprite: AnimatedSprite2D
var _mouse: Area2D
var _mouse_sprite: AnimatedSprite2D
var _cockroach: Sprite2D
var _mouse_steal_timer := 0.0
var _mouse_run_timer := 0.0


func _ready() -> void:
	z_index = 1
	_background = BackgroundScene.instantiate() as Node2D
	_background.name = "RodentBackground"
	add_child(_background)

	_bird = BirdScene.instantiate() as Node2D
	_bird.name = "Bird"
	add_child(_bird)
	_bird_sprite = _bird.get_node("AnimatedSprite2D") as AnimatedSprite2D
	_bird_sprite.animation_finished.connect(_on_bird_animation_finished)

	_mouse = MouseScene.instantiate() as Area2D
	_mouse.name = "Mouse"
	add_child(_mouse)
	_mouse_sprite = _mouse.get_node("AnimatedSprite2D") as AnimatedSprite2D

	_cockroach = CockroachScene.instantiate() as Sprite2D
	_cockroach.name = "Cockroach"
	add_child(_cockroach)
	_layout_cockroach()
	visible = false
	set_process(false)


func set_active(active: bool, manager: RodentMode = null) -> void:
	visible = active
	set_process(active)
	if manager != null:
		mode = manager
	if active and mode != null:
		_sync()


func on_mouse_stole_butter() -> void:
	_mouse_steal_timer = 0.55
	_mouse_run_timer = 0.0
	_play_mouse("steal")


func _process(delta: float) -> void:
	if not visible or mode == null:
		return
	if _mouse_steal_timer > 0.0:
		_mouse_steal_timer = maxf(0.0, _mouse_steal_timer - delta)
		if _mouse_steal_timer == 0.0:
			_mouse_run_timer = 0.45
	elif _mouse_run_timer > 0.0:
		_mouse_run_timer = maxf(0.0, _mouse_run_timer - delta)
	_sync()


func _sync() -> void:
	_bird.position = mode.bird_position
	match mode.bird_state:
		RodentMode.BirdState.PERCHED:
			_play_bird("idle")
			_bird_sprite.flip_h = false
		RodentMode.BirdState.SWOOPING:
			if _bird_sprite.animation != "swoop" and _bird_sprite.animation != "fly":
				_play_bird("swoop")
			_bird_sprite.flip_h = true
		RodentMode.BirdState.RETURNING:
			_play_bird("return")
			_bird_sprite.flip_h = false

	_mouse.position = Vector2(mode.butter_x - 88.0, RodentMode.BUTTER_Y)
	if _mouse_steal_timer > 0.0:
		_play_mouse("steal")
	elif _mouse_run_timer > 0.0:
		_play_mouse("run")
	elif mode.mouse_scared_timer > 0.0:
		_play_mouse("scared")
	elif mode.butter_x < RodentMode.BUTTER_HOME_X - 1.0:
		_play_mouse("walk")
	else:
		_play_mouse("idle")
	_mouse_sprite.flip_h = false
	_background.call("set_blackout", mode.light_blackout_timer)


func _play_bird(animation_name: StringName) -> void:
	if _bird_sprite.animation != animation_name:
		_bird_sprite.play(animation_name)


func _play_mouse(animation_name: StringName) -> void:
	if _mouse_sprite.animation != animation_name:
		_mouse_sprite.play(animation_name)


func _on_bird_animation_finished() -> void:
	if mode != null and mode.bird_state == RodentMode.BirdState.SWOOPING and _bird_sprite.animation == "swoop":
		_bird_sprite.play("fly")


func _layout_cockroach() -> void:
	var image_size := _cockroach.texture.get_size()
	var viewport_size := get_viewport_rect().size
	var scale_factor := maxf(viewport_size.x / image_size.x, viewport_size.y / image_size.y)
	_cockroach.scale = Vector2.ONE * scale_factor
	_cockroach.position = Vector2(
		(1535.0 - image_size.x * 0.5) * scale_factor + viewport_size.x * 0.5,
		(575.0 - image_size.y * 0.5) * scale_factor + viewport_size.y * 0.5
	)
