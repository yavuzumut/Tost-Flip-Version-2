class_name RodentMode
extends RefCounted
## Threat state and rules for the Rodent mode. Presentation stays in scene nodes.

const BIRD_DANGER_Y := 268.0
const BUTTER_HOME_X := 300.0
const BUTTER_Y := 492.0

enum BirdState { PERCHED, SWOOPING, RETURNING }

var bird_home := Vector2(965.0, 102.0)
var bird_position := bird_home
var bird_state := BirdState.PERCHED
var bird_has_toast := false
var mouse_scared_timer := 0.0
var light_pending_timer := -1.0
var light_blackout_timer := 0.0
var roach_progress := 0.0
var butter_x := BUTTER_HOME_X
var score := 0
var _round_resolved := false


func start() -> void:
	bird_position = bird_home
	bird_state = BirdState.PERCHED
	bird_has_toast = false
	mouse_scared_timer = 0.0
	light_pending_timer = -1.0
	light_blackout_timer = 0.0
	_roach_reset()
	butter_x = BUTTER_HOME_X
	_round_resolved = false


func on_launch() -> bool:
	if bird_state == BirdState.PERCHED:
		_round_resolved = false
	if randf() < 0.25 and light_blackout_timer <= 0.0 and light_pending_timer <= 0.0:
		light_pending_timer = 0.18
		return true
	return false


func scare_mouse(duration: float = 4.0) -> void:
	mouse_scared_timer = duration


func update(delta: float, toast_position: Vector2, toast_airborne: bool) -> Dictionary:
	var events := {"bird_triggered": false, "toast_stolen": false, "mouse_stole_butter": false, "blackout_started": false, "bird_returned": false}

	if not _round_resolved and bird_state == BirdState.PERCHED and toast_airborne and toast_position.y < BIRD_DANGER_Y:
		bird_state = BirdState.SWOOPING
		events["bird_triggered"] = true

	if bird_state == BirdState.SWOOPING:
		var to_toast := toast_position - bird_position
		var distance := to_toast.length()
		if distance <= 28.0:
			bird_has_toast = true
			bird_state = BirdState.RETURNING
			_round_resolved = true
			events["toast_stolen"] = true
		else:
			bird_position += to_toast / distance * 630.0 * delta
	elif bird_state == BirdState.RETURNING:
		var to_home := bird_home - bird_position
		var distance := to_home.length()
		if distance <= 18.0:
			bird_position = bird_home
			bird_state = BirdState.PERCHED
			bird_has_toast = false
			events["bird_returned"] = true
		else:
			bird_position += to_home / distance * 516.0 * delta

	if mouse_scared_timer > 0.0:
		mouse_scared_timer = maxf(0.0, mouse_scared_timer - delta)
		butter_x = move_toward(butter_x, BUTTER_HOME_X, 180.0 * delta)
	else:
		butter_x -= 15.6 * delta
		if butter_x <= 45.0:
			butter_x = BUTTER_HOME_X
			mouse_scared_timer = 2.5
			events["mouse_stole_butter"] = true

	if light_pending_timer > 0.0:
		light_pending_timer -= delta
		roach_progress = minf(1.0, roach_progress + delta * 5.0)
		if light_pending_timer <= 0.0:
			light_pending_timer = -1.0
			if toast_airborne:
				light_blackout_timer = randf_range(1.2, 2.0)
				events["blackout_started"] = true
	else:
		roach_progress = maxf(0.0, roach_progress - delta * 3.0)

	light_blackout_timer = maxf(0.0, light_blackout_timer - delta)
	return events


func record_plain_landing() -> int:
	score += 20
	return 20


func record_buttered_sale(layers: int) -> int:
	var reward := maxi(0, layers * 45 + layers * (layers - 1) * 20)
	score += reward
	return reward


func _roach_reset() -> void:
	roach_progress = 0.0
