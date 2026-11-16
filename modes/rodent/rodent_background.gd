extends Node2D

@onready var _art: Sprite2D = $BackgroundArt
@onready var _blackout: ColorRect = $Blackout

var _darkness := 0.0
var _darkness_target := 0.0


func _ready() -> void:
	get_viewport().size_changed.connect(_update_layout)
	_update_layout()


func _process(delta: float) -> void:
	_darkness = move_toward(_darkness, _darkness_target, delta * 5.0)
	var shade := _blackout.color
	shade.a = 0.76 * _darkness
	_blackout.color = shade


func set_blackout(timer: float) -> void:
	_darkness_target = 1.0 if timer > 0.0 else 0.0


func _update_layout() -> void:
	var view_size := get_viewport_rect().size
	var texture_size := _art.texture.get_size()
	var scale_factor := maxf(view_size.x / texture_size.x, view_size.y / texture_size.y)
	_art.position = view_size * 0.5
	_art.scale = Vector2.ONE * scale_factor
	_blackout.position = Vector2.ZERO
	_blackout.size = view_size
