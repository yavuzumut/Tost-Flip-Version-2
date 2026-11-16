extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://node_2d.tscn") as PackedScene
	assert(packed != null, "Main scene should load")
	var game := packed.instantiate()
	root.add_child(game)
	await process_frame

	game.start_game(game.GameMode.RODENT)
	assert(game.state == game.GameState.READY, "Rodent mode should start ready")
	assert(game.rodent_visuals.visible, "Rodent visuals should be enabled")
	assert(not game.space_hud.visible, "Space HUD should be hidden in Rodent mode")
	var bird: AnimatedSprite2D = game.rodent_visuals.get_node("Bird/AnimatedSprite2D")
	var mouse: AnimatedSprite2D = game.rodent_visuals.get_node("Mouse/AnimatedSprite2D")
	assert(bird.sprite_frames.get_frame_count("idle") == 4, "Bird idle frames should load")
	assert(bird.sprite_frames.get_frame_count("fly") == 8, "Bird fly frames should load")
	assert(bird.sprite_frames.get_frame_count("swoop") == 6, "Bird swoop frames should load")
	assert(bird.sprite_frames.get_frame_count("return") == 6, "Bird return frames should load")
	assert(mouse.sprite_frames.get_frame_count("idle") == 4, "Mouse idle frames should load")
	assert(mouse.sprite_frames.get_frame_count("walk") == 4, "Mouse walk frames should load")
	assert(mouse.sprite_frames.get_frame_count("run") == 6, "Mouse run frames should load")
	assert(mouse.sprite_frames.get_frame_count("steal") == 6, "Mouse steal frames should load")
	assert(mouse.sprite_frames.get_frame_count("scared") == 4, "Mouse scared frames should load")
	game.rodent_mgr.bird_state = game.rodent_mgr.BirdState.SWOOPING
	game.rodent_visuals.call("_sync")
	assert(bird.animation == "swoop", "Bird should swoop when its threat state begins")
	game.rodent_mgr.bird_state = game.rodent_mgr.BirdState.RETURNING
	game.rodent_visuals.call("_sync")
	assert(bird.animation == "return", "Bird should return to its nest after stealing")
	game.rodent_mgr.bird_state = game.rodent_mgr.BirdState.PERCHED
	game.rodent_mgr.scare_mouse()
	game.rodent_visuals.call("_sync")
	assert(mouse.animation == "scared", "Mouse should play scared animation after a click")
	game.rodent_visuals.call("on_mouse_stole_butter")
	game.rodent_visuals.call("_sync")
	assert(mouse.animation == "steal", "Mouse should play its theft animation when butter is stolen")
	assert(game.rodent_visuals.get_node("Cockroach") is Sprite2D, "Cockroach should remain a single static Sprite2D")
	game.rodent_mgr.light_blackout_timer = 1.0
	game.rodent_visuals.call("_sync")
	var rodent_background: Node2D = game.rodent_visuals.get_node("RodentBackground")
	assert(rodent_background._darkness_target == 1.0, "Blackout should darken the Rodent background")
	rodent_background.call("_process", 0.3)
	assert(rodent_background.get_node("Blackout").color.a > 0.7, "Blackout should fade over the full game view")
	game._show_main_menu()
	assert(not game.plate_collision.disabled, "Leaving Rodent mode should restore the shared plate collider")

	game.start_game(game.GameMode.SPACE)
	assert(game.state == game.GameState.FLYING, "Space mode should begin a flight")
	assert(game.toast._space_control, "Space mode should own toast movement")
	assert(game.space_hud.visible, "Space HUD should be enabled")
	game.space_mgr.total_score = 375
	game._show_main_menu()
	game.start_game(game.GameMode.SPACE)
	assert(game.space_mgr.total_score == 375, "Space score should persist across runs in this session")

	print("Mode integration passed")
	quit(0)
