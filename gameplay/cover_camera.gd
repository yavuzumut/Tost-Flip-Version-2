extends Camera2D
## Dünya sahnesini (mutfak + masa) her en-boy oranında ekranı boşluksuz kaplayacak şekilde yakınlaştırır.
## 16:9'da etkisizdir (zoom = 1). Daha geniş ekranda üstten (tavan/HUD bölgesi) kırpar,
## daha uzun ekranda yanlardan kırpar; masa ve tabak her zaman görünür kalır.
## HUD ayrı CanvasLayer'da olduğu için kameradan etkilenmez, anchor'larıyla kenarlara yapışır.

@export var design_size := Vector2(1152, 648)


func _ready() -> void:
	get_viewport().size_changed.connect(_fit)
	_fit()


func _fit() -> void:
	var vp := get_viewport_rect().size
	var z := maxf(vp.x / design_size.x, vp.y / design_size.y)
	zoom = Vector2(z, z)
	var visible_size := vp / z
	position = Vector2(design_size.x * 0.5, design_size.y - visible_size.y * 0.5)
