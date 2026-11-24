extends Area2D
class_name IngredientStation
## Mutfaktaki tıklanabilir malzeme istasyonu. Çarpışma ile malzeme vermez.

const WOOD_TEX := preload("res://assets/skilled/wood_button_pill.png")
const BUTTER_TEX := preload("res://assets/modes/space/collectibles/05_tereyagi.png")
const LETTUCE_TEX := preload("res://assets/modes/space/collectibles/03_marul.png")
const SALAMI_TEX := preload("res://assets/modes/space/collectibles/02_salam.png")
const JAM_TEX := preload("res://assets/modes/space/collectibles/04_recel_kavanozu.png")

@export var ingredient_id := "butter"
@export var display_name := "Tereyağı"

var _sprite: Sprite2D
var _icon: Sprite2D
var _label: Label
var _enabled := true


func _ready() -> void:
	input_pickable = true
	monitoring = false
	monitorable = false

	_sprite = Sprite2D.new()
	_sprite.texture = WOOD_TEX
	_sprite.scale = Vector2(0.28, 0.42)
	add_child(_sprite)

	if ingredient_id == "butter" or ingredient_id == "lettuce" or ingredient_id == "salami" or ingredient_id == "jam":
		_icon = Sprite2D.new()
		match ingredient_id:
			"butter":
				_icon.texture = BUTTER_TEX
			"lettuce":
				_icon.texture = LETTUCE_TEX
			"salami":
				_icon.texture = SALAMI_TEX
			"jam":
				_icon.texture = JAM_TEX

		_icon.position = Vector2(-42, -2)
		_icon.scale = Vector2(0.05, 0.05) if ingredient_id == "butter" else Vector2(0.08, 0.08)
		add_child(_icon)

	_label = Label.new()
	_label.text = display_name
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.position = Vector2(-52, -16)
	_label.size = Vector2(120, 32)
	_label.add_theme_font_size_override("font_size", 16)
	_label.add_theme_color_override("font_color", Color("fff3d6"))
	_label.add_theme_color_override("font_outline_color", Color("4a220c"))
	_label.add_theme_constant_override("outline_size", 6)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 52.0
	shape.shape = circle
	add_child(shape)

	mouse_entered.connect(_on_hover.bind(true))
	mouse_exited.connect(_on_hover.bind(false))


func set_enabled(on: bool) -> void:
	_enabled = on
	input_pickable = on
	modulate = Color.WHITE if on else Color(0.75, 0.75, 0.75, 0.85)


func _on_hover(entered: bool) -> void:
	if not _enabled:
		return
	modulate = Color(1.12, 1.08, 0.95) if entered else Color.WHITE
