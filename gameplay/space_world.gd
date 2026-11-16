extends Node2D
## Visual presentation for SpaceMode. SpaceMode remains the sole gameplay authority.

const PlanetScene = preload("res://scenes/space/planet.tscn")
const CollectibleScene = preload("res://scenes/space/space_collectible.tscn")
const AsteroidScene = preload("res://scenes/space/asteroid.tscn")
const PlayerScene = preload("res://scenes/space/space_player.tscn")
const PLANET_TEXTURES := {
	"moon": "res://assets/modes/space/planets/01_ay.png",
	"mars": "res://assets/modes/space/planets/02_mars.png",
	"jupiter": "res://assets/modes/space/planets/03_jupiter.png",
	"saturn": "res://assets/modes/space/planets/04_saturn.png",
}
const INGREDIENT_TEXTURES := {
	"butter": "res://assets/modes/space/collectibles/01_peynir.png",
	"salami": "res://assets/modes/space/collectibles/02_salam.png",
	"lettuce": "res://assets/modes/space/collectibles/03_marul.png",
	"jam": "res://assets/modes/space/collectibles/04_recel_kavanozu.png",
}

var mode: SpaceMode
var _size := Vector2(1152, 648)
var _last_altitude := SpaceMode.START_ALTITUDE
var _stars: Array[ColorRect] = []
var _planet_nodes: Array[Node2D] = []
var _object_nodes: Array[Node2D] = []
var _player: Node2D
var _ground: Node2D
var _topping_nodes: Dictionary = {}

func _ready() -> void:
	_size = get_viewport_rect().size
	_build_stars()
	_build_landing_area()
	_player = PlayerScene.instantiate()
	$PlayerContainer.add_child(_player)
	visible = false
	get_node("../Toast/Sprite2D").visible = true

func present(manager: SpaceMode) -> void:
	mode = manager
	get_node("../Toast/Sprite2D").visible = false
	visible = true
	_last_altitude = manager.altitude
	_sync_world()

func clear() -> void:
	visible = false
	get_node("../Toast/Sprite2D").visible = true
	_clear_nodes(_object_nodes)
	_clear_nodes(_planet_nodes)
	_topping_nodes.clear()

func sync_player(position: Vector2, toppings: Array[String], shield_active: bool = false) -> void:
	if not is_instance_valid(_player):
		return
	_player.position = position
	_player.rotation = PI + (sin(Time.get_ticks_msec() * 0.006) * 0.12 if shield_active else 0.0)
	var mapping := {"butter": "Butter", "salami": "Salami", "lettuce": "Lettuce", "jam": "Jam"}
	var counts := {"butter": 0, "salami": 0, "lettuce": 0, "jam": 0}
	for item in toppings:
		counts[item] = int(counts.get(item, 0)) + 1
	for item in mapping:
		var sprite := _player.get_node("Visual/" + mapping[item]) as Sprite2D
		sprite.visible = int(counts[item]) > 0
		sprite.scale = Vector2.ONE * minf(0.14, 0.12 + (int(counts[item]) - 1) * 0.008) if sprite.visible else Vector2.ZERO

func _process(delta: float) -> void:
	if not visible or mode == null:
		return
	var travel := maxf(0.0, _last_altitude - mode.altitude)
	_last_altitude = mode.altitude
	var speed := 0.6 if mode.turbo_timer <= 0.0 else 1.56
	for star in _stars:
		star.position.y -= delta * 24.0 * speed
		if star.position.y < -4.0:
			star.position.y = _size.y + 3.0
	if travel > 0.0:
		_sync_world()
	_sync_nodes(_planet_nodes, mode.planets, true)
	_sync_nodes(_object_nodes, mode.objects, false)

func _build_stars() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in 72:
		var star := ColorRect.new()
		star.name = "Star%02d" % i
		var d := rng.randf_range(1.0, 3.0)
		star.position = Vector2(rng.randf_range(8.0, _size.x - 8.0), rng.randf_range(8.0, _size.y - 8.0))
		star.size = Vector2.ONE * d
		star.color = Color(0.88, 0.93, 1.0, rng.randf_range(0.35, 0.9))
		star.mouse_filter = Control.MOUSE_FILTER_IGNORE
		$Starfield.add_child(star)
		_stars.append(star)

func _build_landing_area() -> void:
	_ground = $LandingArea
	_ground.visible = false
	var grass := ColorRect.new()
	grass.name = "GroundFallback"
	grass.size = Vector2(_size.x, _size.y + 180)
	grass.color = Color("#2d7946")
	_ground.add_child(grass)
	var marker := ColorRect.new()
	marker.name = "LandingMarker"
	marker.position = Vector2(_size.x * 0.5 - 90, 24)
	marker.size = Vector2(180, 20)
	marker.color = Color("#c7443c")
	_ground.add_child(marker)

func _sync_world() -> void:
	if mode == null:
		return
	_ground.visible = mode.altitude < 520.0 or mode.landing_timer > 0.0
	if _ground.visible:
		var progress := 1.0 - clampf(mode.altitude / 520.0, 0.0, 1.0)
		_ground.position.y = lerpf(_size.y + 150.0, _size.y - 172.0, progress)
	_sync_nodes(_planet_nodes, mode.planets, true)
	_sync_nodes(_object_nodes, mode.objects, false)

func _sync_nodes(nodes: Array[Node2D], values: Array[Dictionary], planets: bool) -> void:
	while nodes.size() > values.size():
		var old: Node2D = nodes.pop_back()
		old.queue_free()
	while nodes.size() < values.size():
		var value: Dictionary = values[nodes.size()]
		var node := _make_entity(String(value.type), planets)
		$PlanetContainer.add_child(node) if planets else $SpaceObjectContainer.add_child(node)
		nodes.append(node)
	for i in values.size():
		var value := values[i]
		var node := nodes[i]
		if node.get_meta("kind", "") != String(value.type):
			node.queue_free()
			node = _make_entity(String(value.type), planets)
			$PlanetContainer.add_child(node) if planets else $SpaceObjectContainer.add_child(node)
			nodes[i] = node
		node.position = value.position
		node.rotation = float(value.get("rotation", 0.0))
		if planets:
			node.call("configure", load(PLANET_TEXTURES.get(String(value.type), "")), float(value.get("radius", 50.0)) * 2.0)

func _make_entity(kind: String, planet: bool) -> Node2D:
	var scene: PackedScene
	if planet:
		scene = PlanetScene
	elif INGREDIENT_TEXTURES.has(kind):
		scene = CollectibleScene
	elif kind == "asteroid":
		scene = AsteroidScene
	else:
		return _make_powerup_placeholder(kind)
	var node := scene.instantiate() as Node2D
	node.set_meta("kind", kind)
	if not planet and INGREDIENT_TEXTURES.has(kind):
		var sprite := node.get_node("CollectibleSprite") as Sprite2D
		sprite.texture = load(INGREDIENT_TEXTURES[kind]) as Texture2D
		var longest := maxf(sprite.texture.get_width(), sprite.texture.get_height())
		sprite.scale = Vector2.ONE * 45.0 / longest
	return node

func _make_powerup_placeholder(kind: String) -> Node2D:
	# Existing mechanic markers remain until the dedicated roadster and cat art is supplied.
	var node := Node2D.new()
	node.set_meta("kind", kind)
	node.set_meta("missing_art", true)
	var marker := Polygon2D.new()
	var points := PackedVector2Array()
	var radius := 29.0
	for i in 32:
		var angle := TAU * float(i) / 32.0
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	marker.polygon = points
	marker.color = Color("#d95e4d") if kind == "roadster" else Color("#bd65bd")
	node.add_child(marker)
	var label := Label.new()
	label.text = "A" if kind == "roadster" else "K"
	label.position = Vector2(-12, -17)
	label.size = Vector2(24, 30)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color("#fff8ea"))
	label.add_theme_color_override("font_outline_color", Color("#34251e"))
	label.add_theme_constant_override("outline_size", 3)
	node.add_child(label)
	return node

func _clear_nodes(nodes: Array[Node2D]) -> void:
	for node in nodes:
		node.queue_free()
	nodes.clear()
