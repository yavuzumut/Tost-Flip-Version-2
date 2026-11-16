class_name SpaceMode
extends RefCounted
## Horizontal arcade flight rules. The Toast body is frozen while this mode owns it.

const START_ALTITUDE := 2400.0
const INGREDIENTS: Array[String] = ["butter", "salami", "lettuce", "jam"]
const INGREDIENT_LABELS := {"butter": "Tereyağı", "salami": "Salam", "lettuce": "Marul", "jam": "Reçel"}

var altitude := START_ALTITUDE
var total_score := 0
var round_score := 0
var turbo_timer := 0.0
var shield_timer := 0.0
var landing_timer := 0.0
var objects: Array[Dictionary] = []
var planets: Array[Dictionary] = []
var order: Dictionary = {}
var stack: Array[String] = []
var viewport_size := Vector2(1152.0, 648.0)
var _spawn_timer := 0.4
var _planet_timer := 1.5
var _resolved := false


func start_run(size: Vector2) -> void:
	viewport_size = size
	altitude = START_ALTITUDE
	turbo_timer = 0.0
	shield_timer = 0.0
	landing_timer = 0.0
	_spawn_timer = 0.4
	_planet_timer = 1.5
	objects.clear()
	planets.clear()
	stack.clear()
	round_score = 0
	_resolved = false
	order = {"butter": 0, "salami": 0, "lettuce": 0, "jam": 0}
	var target := randi_range(2, 4)
	for _i in target:
		var item := INGREDIENTS[randi_range(0, INGREDIENTS.size() - 1)]
		order[item] += 1
	planets.append({"type": "moon", "position": Vector2(size.x * 0.19, size.y * 0.81), "radius": 47.0, "speed": 25.0})
	planets.append({"type": "jupiter", "position": Vector2(size.x * 0.79, size.y * 1.1), "radius": 69.0, "speed": 20.0})


func update(delta: float, toast_position: Vector2) -> Dictionary:
	var events := {"landing": false, "collisions": [], "landed_timer_finished": false}
	if landing_timer > 0.0:
		landing_timer = maxf(0.0, landing_timer - delta)
		if landing_timer <= 0.0:
			events["landed_timer_finished"] = true
		return events

	if _resolved:
		return events

	turbo_timer = maxf(0.0, turbo_timer - delta)
	shield_timer = maxf(0.0, shield_timer - delta)
	var turbo := turbo_timer > 0.0
	var speed_mult := 2.6 if turbo else 1.0
	altitude = maxf(0.0, altitude - 48.0 * speed_mult * delta)

	_planet_timer -= delta
	if _planet_timer <= 0.0 and altitude > 650.0 and planets.size() < 2:
		_planet_timer = randf_range(6.5, 10.5)
		var types: Array[String] = ["moon", "jupiter", "saturn", "mars"]
		planets.append({"type": types.pick_random(), "position": Vector2(randf_range(viewport_size.x * 0.2, viewport_size.x * 0.8), viewport_size.y + 100.0), "radius": randf_range(43.0, 71.0), "speed": randf_range(19.0, 29.0)})
	for i in range(planets.size() - 1, -1, -1):
		planets[i]["position"].y -= planets[i]["speed"] * speed_mult * delta
		if planets[i]["position"].y < -130.0:
			planets.remove_at(i)

	if altitude > 240.0:
		_spawn_timer -= delta * (1.35 if turbo else 1.0)
		if _spawn_timer <= 0.0:
			_spawn_timer = randf_range(0.48, 0.78)
			_spawn_entity()

	for i in range(objects.size() - 1, -1, -1):
		var obj: Dictionary = objects[i]
		obj["position"].y -= obj["speed"] * (1.45 if turbo else 1.0) * delta
		obj["position"].x += obj["vx"] * delta
		obj["rotation"] += obj["rotation_speed"] * delta
		var reach := 49.0 if obj["type"] in ["roadster", "jam_cat"] else 41.0
		if absf(obj["position"].x - toast_position.x) < reach and absf(obj["position"].y - toast_position.y) < 34.0:
			var effect := _collide(obj)
			events["collisions"].append({"type": obj["type"], "effect": effect})
			objects.remove_at(i)
		elif obj["position"].y < -90.0:
			objects.remove_at(i)

	if altitude <= 0.0:
		events["landing"] = true
		events["round_points"] = _evaluate_order()
		round_score = int(events["round_points"])
		total_score += round_score
		_resolved = true
		landing_timer = 4.2
		turbo_timer = 0.0
		shield_timer = 0.0
		objects.clear()
	return events


func order_lines() -> PackedStringArray:
	var lines := PackedStringArray()
	for item in INGREDIENTS:
		if int(order.get(item, 0)) > 0:
			lines.append("%s %d / %d" % [String(INGREDIENT_LABELS[item]), _count(item), int(order[item])])
	return lines


func _spawn_entity() -> void:
	var roll := randf()
	var kind := "butter"
	if roll < 0.54:
		var needed: Array[String] = []
		for item in INGREDIENTS:
			if _count(item) < int(order[item]):
				needed.append(item)
		kind = needed.pick_random() if not needed.is_empty() and randf() < 0.7 else INGREDIENTS.pick_random()
	elif roll < 0.82:
		kind = "asteroid"
	elif roll < 0.91:
		kind = "roadster"
	else:
		kind = "jam_cat"
	objects.append({"type": kind, "position": Vector2(randf_range(viewport_size.x * 0.1, viewport_size.x * 0.9), viewport_size.y + 55.0), "speed": randf_range(162.0, 222.0), "vx": randf_range(-27.0, 27.0), "rotation": randf() * TAU, "rotation_speed": randf_range(-2.8, 2.8)})


func _collide(obj: Dictionary) -> String:
	if shield_timer > 0.0:
		return "shield"
	var kind: String = obj["type"]
	if INGREDIENTS.has(kind):
		stack.append(kind)
		return "collected"
	if kind == "asteroid":
		if not stack.is_empty():
			stack.remove_at(randi_range(0, stack.size() - 1))
			return "lost_ingredient"
		return "asteroid_empty"
	if kind == "roadster":
		turbo_timer = 14.0
		return "turbo"
	if kind == "jam_cat":
		shield_timer = 14.0
		return "shield_started"
	return "none"


func _evaluate_order() -> int:
	var matched := 0
	var exact := stack.size() == _target_size()
	for item in INGREDIENTS:
		var have := _count(item)
		var need := int(order.get(item, 0))
		matched += mini(have, need)
		if have != need:
			exact = false
	return 250 if exact else matched * 45


func _target_size() -> int:
	var total := 0
	for item in INGREDIENTS:
		total += int(order.get(item, 0))
	return total


func _count(item: String) -> int:
	var total := 0
	for entry in stack:
		if entry == item:
			total += 1
	return total
