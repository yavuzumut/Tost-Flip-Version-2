extends Node2D

@onready var sprite: Sprite2D = $PlanetSprite

func configure(texture: Texture2D, diameter: float) -> void:
	sprite.texture = texture
	if texture:
		var longest := maxf(texture.get_width(), texture.get_height())
		sprite.scale = Vector2.ONE * diameter / longest
