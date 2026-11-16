class_name SandwichMode
extends RefCounted
## Sandviç Ustası: sipariş, malzeme yığını, 3 kontrol hakkı ve yerel yavaş çekim.
## Tost fiziğini değiştirmez; zaman ölçeğini yalnızca bu mod uçuşunda uygular.

const INGREDIENTS: Array[String] = ["butter", "salami", "lettuce", "jam"]
const LABELS := {
	"butter": "Tereyağı",
	"salami": "Salam",
	"lettuce": "Marul",
	"jam": "Reçel",
}
const MAX_CLICKS := 3
const SLOW_MO_SCALE := 0.18
const SUCCESS_SCORE := 100
const LAUNCH_HEIGHT_MULT := 1.48

var order: Dictionary = {"butter": 0, "salami": 0, "lettuce": 0, "jam": 0}
var stack: Array[String] = []
var total_target: int = 0
var clicks_left: int = MAX_CLICKS
var time_scale: float = 1.0
var _owns_engine_scale := false


func generate_order() -> void:
	order = {"butter": 0, "salami": 0, "lettuce": 0, "jam": 0}
	total_target = randi_range(2, 4)
	for i in total_target:
		var pick: String = INGREDIENTS[randi() % INGREDIENTS.size()]
		order[pick] += 1
	stack.clear()
	clicks_left = MAX_CLICKS
	restore_time_scale()


func reset_round() -> void:
	generate_order()


func on_launched() -> void:
	clicks_left = MAX_CLICKS
	apply_time_scale(SLOW_MO_SCALE)


func count_of(ingredient_id: String) -> int:
	var n := 0
	for item in stack:
		if item == ingredient_id:
			n += 1
	return n


func remaining_needed(ingredient_id: String) -> int:
	return maxi(0, int(order.get(ingredient_id, 0)) - count_of(ingredient_id))


func can_collect(ingredient_id: String) -> bool:
	return remaining_needed(ingredient_id) > 0


func try_collect(ingredient_id: String, airborne: bool) -> String:
	if not airborne:
		return "grounded"
	if not INGREDIENTS.has(ingredient_id):
		return "unknown"
	if remaining_needed(ingredient_id) <= 0:
		if int(order.get(ingredient_id, 0)) <= 0:
			return "not_in_order"
		return "enough"
	stack.append(ingredient_id)
	if stack.size() >= total_target:
		restore_time_scale()
	return "ok"


func use_control() -> bool:
	if clicks_left <= 0:
		return false
	clicks_left -= 1
	return true


func is_order_filled() -> bool:
	if stack.size() != total_target:
		return false
	for key in order.keys():
		if count_of(String(key)) != int(order[key]):
			return false
	return true


func evaluate_landing(correct_face: bool) -> Dictionary:
	restore_time_scale()
	var exact := is_order_filled()
	var success := correct_face and exact
	var points := SUCCESS_SCORE if success else 0
	var reason := "success"
	if not correct_face:
		reason = "wrong_face"
	elif not exact:
		reason = "wrong_order"
	return {
		"success": success,
		"points": points,
		"reason": reason,
		"correct_face": correct_face,
		"exact_order": exact,
	}


func apply_time_scale(scale: float) -> void:
	time_scale = clampf(scale, 0.05, 1.0)
	Engine.time_scale = time_scale
	_owns_engine_scale = time_scale < 0.999


func restore_time_scale() -> void:
	time_scale = 1.0
	if _owns_engine_scale or not is_equal_approx(Engine.time_scale, 1.0):
		Engine.time_scale = 1.0
	_owns_engine_scale = false


func order_lines() -> PackedStringArray:
	var lines: PackedStringArray = PackedStringArray()
	for key in INGREDIENTS:
		var need := int(order.get(key, 0))
		if need <= 0:
			continue
		var have := count_of(key)
		lines.append("%s %d / %d" % [LABELS[key], have, need])
	return lines
