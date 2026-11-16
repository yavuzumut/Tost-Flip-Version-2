extends SceneTree

const RodentScript = preload("res://modes/rodent_mode.gd")


func _init() -> void:
	var mode = RodentScript.new()
	mode.start()
	var bird_event: Dictionary = mode.update(0.016, Vector2(450, 100), true)
	assert(bird_event["bird_triggered"], "Bird should attack above the danger line")

	mode.start()
	mode.butter_x = 45.0
	var mouse_event: Dictionary = mode.update(0.016, Vector2.ZERO, false)
	assert(mouse_event["mouse_stole_butter"], "Mouse should steal butter at its boundary")
	mode.scare_mouse(1.0)
	var safe_event: Dictionary = mode.update(0.25, Vector2.ZERO, false)
	assert(not safe_event["mouse_stole_butter"], "Scared mouse should not steal butter")
	assert(mode.mouse_scared_timer > 0.0, "Fear timer should count down")

	mode.light_pending_timer = 0.01
	var light_event: Dictionary = mode.update(0.02, Vector2(500, 400), true)
	assert(light_event["blackout_started"], "Pending roach event should blackout during flight")
	assert(mode.light_blackout_timer >= 1.17 and mode.light_blackout_timer <= 2.0, "Blackout duration should be bounded")
	print("RodentMode rules passed")
	quit(0)
