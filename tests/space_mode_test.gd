extends SceneTree

const SpaceScript = preload("res://modes/space_mode.gd")


func _init() -> void:
	var mode = SpaceScript.new()
	mode.start_run(Vector2(1152, 648))
	var target := 0
	for item in mode.order.values():
		target += int(item)
	assert(target >= 2 and target <= 4, "Order should contain 2 to 4 ingredients")
	for item in mode.order.keys():
		for _i in int(mode.order[item]):
			mode.stack.append(String(item))
	assert(mode._evaluate_order() == 250, "Exact order should award 250")
	mode.stack.append("butter")
	assert(mode._evaluate_order() == target * 45, "Extra items should void exact bonus but keep matched points")

	mode.total_score = 125
	mode.start_run(Vector2(1152, 648))
	assert(mode.total_score == 125, "Total score should persist between runs")
	mode.stack.clear()
	for item in mode.order.keys():
		for _i in int(mode.order[item]):
			mode.stack.append(String(item))
	mode.altitude = 1.0
	var landing: Dictionary = mode.update(0.1, Vector2(576, 255))
	assert(landing["landing"], "Run should finish when altitude reaches zero")
	assert(landing["round_points"] == 250, "Landing should award current round points")
	assert(mode.total_score == 375, "Round points should add to cumulative total")
	mode.start_run(Vector2(1152, 648))
	assert(mode.total_score == 375, "Cumulative score should survive the next run reset")

	mode.shield_timer = 1.0
	assert(mode._collide({"type": "asteroid"}) == "shield", "Shield should suppress asteroid penalty")
	print("SpaceMode rules passed")
	quit(0)
