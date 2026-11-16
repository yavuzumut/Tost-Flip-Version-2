extends Sprite2D
## Tostun masa/tabak üzerindeki yumuşak gölgesi. Tost yükseldikçe küçülür ve soluklaşır,
## böylece oyuncu tostun yüksekliğini ve ineceği yeri daha kolay okur.

@export var toast_path: NodePath
@export var surface_y := 566.0
@export var max_height := 320.0
@export var max_alpha := 0.4

var _toast: Node2D
var _base_scale := Vector2.ONE


func _ready() -> void:
	_toast = get_node_or_null(toast_path) as Node2D
	_base_scale = scale


func _process(_delta: float) -> void:
	if _toast == null:
		return
	visible = _toast.visible
	var h := clampf(surface_y - _toast.global_position.y, 0.0, max_height)
	var t := 1.0 - h / max_height
	global_position = Vector2(_toast.global_position.x, surface_y)
	scale = _base_scale * lerpf(0.45, 1.0, t)
	modulate.a = max_alpha * lerpf(0.3, 1.0, t)
