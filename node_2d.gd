extends Node2D

const RECORD_PATH := "user://tost_flip_record.save"
const MAX_LIVES := 3
const MAX_BUTTER := 5
const GameHUD = preload("res://ui/hud.gd")
const SkilledModeScript = preload("res://modes/skilled_mode.gd")
const SandwichModeScript = preload("res://modes/sandwich_mode.gd")
const RodentModeScript = preload("res://modes/rodent_mode.gd")
const SpaceModeScript = preload("res://modes/space_mode.gd")
const IngredientStationScript = preload("res://gameplay/ingredient_station.gd")
const ModeSelectMenuScript = preload("res://ui/mode_select_menu.gd")
const SkilledShopScript = preload("res://ui/skilled_shop.gd")

enum GameMode { CLASSIC, SKILLED, SANDWICH, RODENT, SPACE }
enum GameState { MAIN_MENU, MODE_SELECT, COLLECTION, READY, FLYING, LANDED, RODENT_STOLEN, GAME_OVER }

@onready var gameplay_area: Node2D = $GameplayArea
@onready var toast: Toast = $GameplayArea/Toast
@onready var ground: StaticBody2D = $GameplayArea/Table
@onready var plate: StaticBody2D = $GameplayArea/Plate
@onready var hud: GameHUD = $HUD
@onready var menu_bg: Sprite2D = $MenuBG
@onready var mode_select_menu: Control = $CanvasLayer/ModeSelectMenu
@onready var skilled_shop: Control = $CanvasLayer/SkilledShop
@onready var ingredient_stations: Node2D = $GameplayArea/IngredientStations
@onready var space_world: Node = $GameplayArea/SpaceWorld
@onready var rodent_visuals: Node = $GameplayArea/RodentVisuals
@onready var space_hud: PanelContainer = $HUD/SpaceHUD
@onready var kitchen_background: CanvasItem = $GameplayArea/Background
@onready var toast_shadow: CanvasItem = $GameplayArea/ToastShadow
@onready var table_visual: CanvasItem = $GameplayArea/Table/Sprite2D
@onready var plate_visual: CanvasItem = $GameplayArea/Plate/Sprite2D
@onready var table_collision: CollisionShape2D = $GameplayArea/Table/CollisionShape2D
@onready var plate_collision: CollisionShape2D = $GameplayArea/Plate/CollisionShape2D

@onready var menu_music: AudioStreamPlayer = $MenuMusic
@onready var menu_music2: AudioStreamPlayer = $MenuMusic2
@onready var menu_music3: AudioStreamPlayer = $MenuMusic3

@onready var classic_music: AudioStreamPlayer = $KlasikmodandothersMusic
@onready var galactic_music: AudioStreamPlayer = $GalaktikmodMusic

@onready var fail_music: AudioStreamPlayer = $FailMusic

var active_mode: GameMode = GameMode.CLASSIC
var skilled_mgr = SkilledModeScript.new()
var sandwich_mgr = SandwichModeScript.new()
var rodent_mgr = RodentModeScript.new()
var space_mgr = SpaceModeScript.new()
var remaining_air_boosts: int = 0
var _pending_sale_reward: int = 0
var _space_landing_tween: Tween

var state := GameState.MAIN_MENU
var score := 0
var best_score := 0
var lives := MAX_LIVES
var butter_layers := 0
var _start_pos := Vector2.ZERO
var _kitchen_start_pos := Vector2.ZERO
var _table_collision_origin := Vector2.ZERO
var _plate_collision_was_disabled := false
var _round := 0   # bekleyen restart zamanlayıcılarının eski tura ait olup olmadığını anlamak için

var _best_score_label: Label

var _menu_button: Button

func _ready() -> void:
	_load_best_score()
	_best_score_label = $CanvasLayer/MainMenu/BestScoreDisplay/BestScoreValue
	_best_score_label.text = str(best_score)
	ground.add_to_group("ground")
	plate.add_to_group("ground")
	# Tost tabağın ortasında, tabak yüzeyine oturarak başlar.
	_start_pos = Vector2(plate.global_position.x, _surface_top(plate) - toast.toast_size.y * 0.5)
	_kitchen_start_pos = _start_pos
	_table_collision_origin = table_collision.position
	_plate_collision_was_disabled = plate_collision.disabled
	toast.landed.connect(_on_toast_landed)
	toast.touchdown.connect(_on_toast_touchdown)
	_create_ingredient_stations()
	rodent_visuals.call("set_active", false, rodent_mgr)
	hud.retry_pressed.connect(_on_retry_pressed)
	hud.menu_pressed.connect(_show_main_menu)
	hud.shop_pressed.connect(_on_shop_opened)
	hud.sell_pressed.connect(_on_sell_pressed)

	mode_select_menu.back_pressed.connect(_show_main_menu)
	mode_select_menu.mode_chosen.connect(_on_mode_chosen)

	skilled_shop.mode_manager = skilled_mgr
	skilled_shop.upgraded.connect(_on_shop_upgraded)
	skilled_shop.closed.connect(_on_shop_closed)
	_create_menu_button()
	_show_main_menu()
	_setup_menu_animations()
	_play_menu_intro()
	menu_music.finished.connect(_on_menu_music_finished)
	menu_music2.finished.connect(_on_menu_music_finished)
	menu_music3.finished.connect(_on_menu_music_finished)

func _create_menu_button() -> void:
	# OYNA butonunu (MenuButtons'un ilk çocuğu) şablon olarak kopyala
	var source := $CanvasLayer/MainMenu/MenuButtons.get_child(0) as BaseButton
	if source == null:
		push_warning("OYNA butonu bulunamadı, düz buton kullanılıyor.")
		_menu_button = Button.new()
		_menu_button.text = "Ana Menü"
	else:
		_menu_button = source.duplicate(0) as BaseButton  # 0: sinyaller kopyalanmasın
		if _menu_button is Button:
			(_menu_button as Button).text = "ANA MENÜ"
			_menu_button.add_theme_font_size_override("font_size", 22)  # uzun yazı sığsın diye

	_menu_button.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_menu_button.focus_mode = Control.FOCUS_NONE
	_menu_button.custom_minimum_size = Vector2(190.0, 64.0)
	_menu_button.position = Vector2(20.0, 160.0)
	_menu_button.size = Vector2(190.0, 64.0)
	_menu_button.pivot_offset = _menu_button.size / 2.0
	_menu_button.pressed.connect(_show_main_menu)
	$CanvasLayer.add_child(_menu_button)
	_menu_button.hide()

func _ground_top() -> float:
	return _surface_top(ground)


func _surface_top(body: StaticBody2D) -> float:
	var cs := body.get_node("CollisionShape2D") as CollisionShape2D
	var y := body.global_position.y + cs.position.y
	if cs.shape is RectangleShape2D:
		y -= (cs.shape as RectangleShape2D).size.y * 0.5
	return y


func _process(delta: float) -> void:
	if active_mode == GameMode.SPACE and (state == GameState.FLYING or state == GameState.LANDED):
		_tick_space_mode(delta)
		return
	if active_mode == GameMode.RODENT and state in [GameState.READY, GameState.FLYING, GameState.LANDED, GameState.RODENT_STOLEN]:
		_tick_rodent_mode(delta)
	if state == GameState.READY or state == GameState.FLYING or state == GameState.LANDED:
		if active_mode != GameMode.RODENT and active_mode != GameMode.SPACE:
			hud.set_balance(toast.get_balance(), float(butter_layers) / _max_butter_layers())


func _tick_rodent_mode(delta: float) -> void:
	var events: Dictionary = rodent_mgr.update(delta, toast.global_position, state == GameState.FLYING and toast.airborne)
	if events["bird_triggered"]:
		toast.freeze = true
		toast.linear_velocity = Vector2.ZERO
		toast.angular_velocity = 0.0
		hud.show_result("Çok yükseldin! Kuş saldırıyor.", false)
	if state == GameState.RODENT_STOLEN:
		toast.global_position = rodent_mgr.bird_position + Vector2(0, 12)
	if events["toast_stolen"]:
		butter_layers = 0
		toast.set_butter_layers(0)
		toast.freeze = true
		state = GameState.RODENT_STOLEN
		hud.hide_sell_button()
		hud.show_result("Kuş tostu çaldı! 0 puan", false)
	if events["mouse_stole_butter"]:
		butter_layers = 0
		toast.set_butter_layers(0)
		rodent_visuals.call("on_mouse_stole_butter")
		hud.show_result("Fare tereyağını kaçırdı!", false)
	if events["blackout_started"]:
		hud.show_result("Hamam böceği ışığı kapattı!", false)
	if events["bird_returned"]:
		toast.reset_to(_start_pos)
		toast.set_butter_layers(0)
		state = GameState.READY
		hud.show_result("Kuş yuvasına döndü. Yeni atış hazır.", true)
	_refresh_hud()


func _tick_space_mode(delta: float) -> void:
	if state == GameState.FLYING:
		var direction := 0.0
		if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
			direction -= 1.0
		if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
			direction += 1.0
		if direction != 0.0:
			toast.position.x += direction * 390.0 * delta
		else:
			var pointer := gameplay_area.get_global_mouse_position()
			if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
				toast.position.x = move_toward(toast.position.x, pointer.x, 444.0 * delta)
			elif pointer.y > 170.0:
				toast.position.x = move_toward(toast.position.x, pointer.x, 324.0 * delta)
		var view_size := get_viewport_rect().size
		toast.position.x = clampf(toast.position.x, 96.0, view_size.x - 96.0)
		toast.position.y = lerpf(toast.position.y, 255.0, delta * 5.0)
		if space_mgr.shield_timer > 0.0:
			toast.rotation += 18.0 * delta
		else:
			toast.rotation = PI

	var events: Dictionary = space_mgr.update(delta, toast.position)
	for collision in events["collisions"]:
		var effect: String = collision["effect"]
		match effect:
			"collected":
				hud.show_result("Malzeme eklendi", true)
				toast.set_space_toppings(space_mgr.stack)
			"lost_ingredient":
				hud.show_result("Asteroit çarptı! Bir malzeme düştü.", false)
				toast.set_space_toppings(space_mgr.stack)
			"asteroid_empty":
				hud.show_result("Asteroit çarptı!", false)
			"turbo":
				hud.show_result("Arabalı astronot: Turbo!", true)
			"shield_started":
				hud.show_result("Reçelli kedi: Kalkan!", true)
			"shield":
				hud.show_result("Kalkan çarpışmayı engelledi", true)
			"_":
				pass
	if events["landing"]:
		state = GameState.LANDED
		toast.rotation = PI
		toast.set_space_toppings(space_mgr.stack)
		_space_landing_tween = create_tween()
		_space_landing_tween.tween_property(toast, "position", Vector2(get_viewport_rect().size.x * 0.5, get_viewport_rect().size.y - 172.0), 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		var points := int(events["round_points"])
		var result := "Tur +%d puan" % points if points > 0 else "Bu tur eşleşme yok: 0 puan"
		hud.show_result(result, points > 0)
	if events["landed_timer_finished"]:
		_start_space_run()
	space_world.call("sync_player", toast.position, space_mgr.stack, space_mgr.shield_timer > 0.0)
	space_hud.call("set_space_state", space_mgr.altitude, space_mgr.total_score, space_mgr.round_score, space_mgr.order_lines(), space_mgr.turbo_timer, space_mgr.shield_timer, state == GameState.LANDED)
	hud.set_score(space_mgr.total_score)


func _start_space_run() -> void:
	if _space_landing_tween != null and _space_landing_tween.is_valid():
		_space_landing_tween.kill()
	var size := get_viewport_rect().size
	space_mgr.start_run(size)
	toast.reset_to(Vector2(size.x * 0.5, 255.0))
	toast.set_space_control(true)
	toast.rotation = PI
	toast.set_space_toppings([])
	state = GameState.FLYING
	space_world.call("present", space_mgr)
	space_world.call("sync_player", toast.position, space_mgr.stack, false)
	space_hud.show()
	space_hud.call("set_space_state", space_mgr.altitude, space_mgr.total_score, space_mgr.round_score, space_mgr.order_lines(), space_mgr.turbo_timer, space_mgr.shield_timer, false)
	hud.set_score(space_mgr.total_score)


func _handle_rodent_click(event: InputEventMouseButton) -> bool:
	if event.button_index != MOUSE_BUTTON_LEFT:
		return false
	var point := gameplay_area.get_global_mouse_position()
	var mouse_point := Vector2(rodent_mgr.butter_x - 88.0, RodentModeScript.BUTTER_Y)
	if rodent_mgr.mouse_scared_timer <= 0.0 and point.distance_to(mouse_point) <= 30.0:
		rodent_mgr.scare_mouse()
		hud.show_result("Fare korktu!", true)
		return true
	if point.distance_to(Vector2(rodent_mgr.butter_x, RodentModeScript.BUTTER_Y)) <= 42.0:
		if state != GameState.FLYING or not toast.airborne:
			hud.show_result("Önce tostu fırlat!", false)
		elif butter_layers >= MAX_BUTTER:
			hud.show_result("Maksimum tereyağı katmanı", false)
		else:
			butter_layers += 1
			toast.set_butter_layers(butter_layers)
			rodent_mgr.scare_mouse(2.0)
			hud.show_result("Tereyağı +1", true)
			_refresh_hud()
		return true
	return false


func _handle_space_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	if state == GameState.LANDED:
		_start_space_run()
	elif state == GameState.FLYING:
		var pointer := gameplay_area.get_global_mouse_position()
		toast.position.x = clampf(pointer.x, 96.0, get_viewport_rect().size.x - 96.0)


func _max_butter_layers() -> int:
	if active_mode == GameMode.SKILLED:
		return skilled_mgr.get_max_butter_layers()
	return MAX_BUTTER


func _unhandled_input(event: InputEvent) -> void:
	if skilled_shop.visible:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		if state != GameState.MAIN_MENU and state != GameState.MODE_SELECT and state != GameState.COLLECTION:
			_show_main_menu()
			return
	if active_mode == GameMode.SPACE:
		_handle_space_input(event)
		return

	if active_mode == GameMode.SANDWICH:
		_handle_sandwich_input(event)
		return
	if active_mode == GameMode.RODENT and event is InputEventMouseButton and event.pressed:
		if _handle_rodent_click(event as InputEventMouseButton):
			return

	# 1. Hava Takviyesi Kontrolü (Space tuşu - Yalnızca Usta Şef Modunda havada iken)
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE:
		if active_mode == GameMode.SKILLED and state == GameState.FLYING and toast.airborne:
			if remaining_air_boosts > 0:
				remaining_air_boosts -= 1
				toast.air_boost()
				hud.set_air_boost_display(remaining_air_boosts, skilled_mgr.get_max_air_boosts())
		return

	# 2. Fare Tıklama Kontrolleri (Klasik ve Usta Şef için ortak)
	if not (event is InputEventMouseButton and event.pressed):
		return
	var btn := (event as InputEventMouseButton).button_index
	match state:
		GameState.READY:
			if btn == MOUSE_BUTTON_LEFT:
				toast.launch()
				state = GameState.FLYING
				if active_mode == GameMode.RODENT:
					rodent_mgr.on_launch()
				hud.hide_sell_button()
		GameState.FLYING:
			if not toast.airborne:
				return  # yere değdi, kontrol kilitli
			if btn == MOUSE_BUTTON_LEFT:
				toast.spin(-1)
			elif btn == MOUSE_BUTTON_RIGHT:
				toast.spin(1)
		GameState.LANDED:
			# Usta Şef modunda oyuncu tostu satmadan yeni tur için sol tıkla doğrudan fırlatabilir!
			if active_mode == GameMode.SKILLED and btn == MOUSE_BUTTON_LEFT and lives > 0:
				_round += 1
				_pending_sale_reward = 0
				hud.hide_sell_button()
				hud.hide_result()
				toast.reset_to(_start_pos)
				toast.set_butter_layers(butter_layers)
				toast.launch()
				state = GameState.FLYING
				remaining_air_boosts = skilled_mgr.get_max_air_boosts()
				hud.set_air_boost_display(remaining_air_boosts, skilled_mgr.get_max_air_boosts())
			elif active_mode == GameMode.RODENT and btn == MOUSE_BUTTON_LEFT:
				_start_rodent_round()


func _start_rodent_round() -> void:
	_restart()
	toast.launch()
	state = GameState.FLYING
	rodent_mgr.on_launch()
	hud.hide_sell_button()


func _on_toast_touchdown() -> void:
	if active_mode == GameMode.SANDWICH:
		sandwich_mgr.restore_time_scale()


func _on_toast_landed(butter_down: bool) -> void:
	if state != GameState.FLYING:
		return

	state = GameState.LANDED
	_bounce_plate_if_hit()

	if active_mode == GameMode.SANDWICH:
		_finish_sandwich_round(not butter_down)
		return
	if active_mode == GameMode.RODENT:
		_finish_rodent_round(butter_down)
		return

	if butter_down:
		# Tereyağlı yüz yere geldi: 1 hava hakkı gider, tereyağı katmanları sıfırlanır.
		lives = maxi(0, lives - 1)
		butter_layers = 0
		_pending_sale_reward = 0
		hud.hide_sell_button()
		hud.show_result("Tereyağı yere yapıştı! -1 hak", false)

	else:
		# Başarılı iniş
		var max_cap := _max_butter_layers()
		var gained := 1 + butter_layers
		score += gained
		butter_layers = mini(butter_layers + 1, max_cap)

		# Yeni rekor kontrolü
		if score > best_score:
			best_score = score
			_save_best_score()
			if _best_score_label != null:
				_best_score_label.text = str(best_score)

		hud.show_result("KAZANDIN! +%d puan" % gained, true)

		# Usta Şef Modunda satış opsiyonu sunulur
		if active_mode == GameMode.SKILLED:
			_pending_sale_reward = skilled_mgr.calculate_reward(butter_layers)
			hud.show_sell_button(_pending_sale_reward)

	toast.set_butter_layers(butter_layers)
	_refresh_hud()

	var this_round := _round
	if lives <= 0:
		fail_music.play()
		hud.hide_sell_button()
		state = GameState.GAME_OVER
		await get_tree().create_timer(1.1).timeout
		if this_round == _round and state == GameState.GAME_OVER:
			hud.show_game_over(score, best_score)
		return

	# Klasik modda veya başarısız inişte otomatik restart yapılır.
	# Usta Şef modunda başarılı inişte oyuncu satışı yapabilsin diye otomatik başlatılmaz.
	if active_mode == GameMode.CLASSIC or butter_down:
		await get_tree().create_timer(1.2).timeout
		if this_round == _round and state == GameState.LANDED:
			_restart()


func _finish_rodent_round(butter_down: bool) -> void:
	if butter_down:
		butter_layers = 0
		toast.set_butter_layers(0)
		_pending_sale_reward = 0
		hud.hide_sell_button()
		hud.show_result("Ters düştü! Katmanlar kayboldu.", false)
	else:
		if butter_layers == 0:
			var gained: int = rodent_mgr.record_plain_landing()
			score = rodent_mgr.score
			hud.show_result("Sade iniş +%d" % gained, true)
		else:
			_pending_sale_reward = butter_layers * 45 + butter_layers * (butter_layers - 1) * 20
			hud.show_result("İniş başarılı. Tostu sat veya yeni tur başlat.", true)
			hud.show_sell_button(_pending_sale_reward, "Puan")
	_refresh_hud()


func _bounce_plate_if_hit() -> void:
	var sprite := plate.get_node("Sprite2D") as Sprite2D
	var shape := (plate.get_node("CollisionShape2D") as CollisionShape2D).shape as RectangleShape2D
	if absf(toast.global_position.x - plate.global_position.x) > shape.size.x * 0.5 + 40.0:
		return
	var base := sprite.scale
	var tw := create_tween()
	tw.tween_property(sprite, "scale", Vector2(base.x * 1.03, base.y * 0.94), 0.07)
	tw.tween_property(sprite, "scale", base, 0.25).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _refresh_hud() -> void:
	hud.set_score(score)
	if active_mode != GameMode.RODENT and active_mode != GameMode.SPACE:
		hud.set_lives(lives, MAX_LIVES)
	hud.set_butter(butter_layers, _max_butter_layers())
	if active_mode == GameMode.SKILLED:
		hud.set_money(skilled_mgr.money)
		hud.set_air_boost_display(remaining_air_boosts, skilled_mgr.get_max_air_boosts())


func _load_best_score() -> void:
	if not FileAccess.file_exists(RECORD_PATH):
		return

	var file := FileAccess.open(RECORD_PATH, FileAccess.READ)
	if file == null:
		push_warning("Rekor dosyasi okunamadi.")
		return

	var saved := file.get_as_text().strip_edges()
	if saved.is_valid_int():
		best_score = maxi(0, saved.to_int())

	print("Kayitli rekor: ", best_score)


func _save_best_score() -> void:
	var file := FileAccess.open(RECORD_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Rekor kaydedilemedi.")
		return

	file.store_string(str(best_score))
	print("Yeni rekor: ", best_score)


func get_level(points: int) -> int:
	if points >= 6:
		return 3
	elif points >= 3:
		return 2
	else:
		return 1


# --- USTA ŞEF MODU AKSİYONLARI -----------------------------------------------

func _on_sell_pressed() -> void:
	if _pending_sale_reward <= 0:
		return
	var amount := _pending_sale_reward
	_pending_sale_reward = 0
	if active_mode == GameMode.RODENT:
		rodent_mgr.record_buttered_sale(butter_layers)
		score = rodent_mgr.score
		hud.show_result("Tost satıldı! +%d puan" % amount, true)
		hud.hide_sell_button()
		butter_layers = 0
		toast.set_butter_layers(0)
		_refresh_hud()
		_restart()
		return
	skilled_mgr.add_money(amount)
	hud.set_money(skilled_mgr.money)
	hud.show_result("Tost Satıldı! +%d 🪙" % amount, true)
	hud.hide_sell_button()

	butter_layers = 0
	toast.set_butter_layers(0)
	_refresh_hud()
	_restart()


func _on_shop_opened() -> void:
	hud.hide()
	_menu_button.hide()
	skilled_shop.refresh()
	skilled_shop.show()


func _on_shop_closed() -> void:
	_menu_button.show()
	if state == GameState.READY or state == GameState.FLYING or state == GameState.LANDED:
		hud.show()
		_refresh_hud()
	elif state == GameState.GAME_OVER:
		hud.show()
		_refresh_hud()
		hud.show_game_over(score, best_score)


func _on_shop_upgraded(_type: String) -> void:
	hud.set_money(skilled_mgr.money)
	toast.set_torque_resistance(skilled_mgr.get_torque_resistance())
	remaining_air_boosts = skilled_mgr.get_max_air_boosts()
	_refresh_hud()


# --- OYUN BAŞLATMA & MOD SEÇİMİ ---------------------------------------------

func _on_play_button_pressed() -> void:
	$CanvasLayer/MainMenu.hide()
	$CanvasLayer/CollectionMenu.hide()
	skilled_shop.hide()
	_menu_button.hide()
	mode_select_menu.show()
	state = GameState.MODE_SELECT


func _on_mode_chosen(mode_idx: int) -> void:
	mode_select_menu.hide()
	match mode_idx:
		1:
			start_game(GameMode.SKILLED)
		2:
			start_game(GameMode.SANDWICH)
		3:
			start_game(GameMode.RODENT)
		4:
			start_game(GameMode.SPACE)
		_:
			start_game(GameMode.CLASSIC)


func start_game(mode: GameMode) -> void:
	stop_all_music()

	if mode == GameMode.SPACE:
		galactic_music.play()
	else:
		classic_music.play()
	_apply_rodent_environment(false)
	active_mode = mode
	menu_bg.hide()
	$CanvasLayer/MainMenu.hide()
	$CanvasLayer/CollectionMenu.hide()
	mode_select_menu.hide()
	skilled_shop.hide()

	gameplay_area.show()
	toast.show()
	space_world.call("clear")
	rodent_visuals.call("set_active", false, rodent_mgr)
	space_hud.hide()
	kitchen_background.show()
	ground.show()
	plate.show()
	toast_shadow.show()
	hud.show()
	_menu_button.show()
	hud.hide_game_over()
	hud.hide_result()
	hud.hide_sell_button()

	score = 0
	lives = MAX_LIVES
	butter_layers = 0
	_pending_sale_reward = 0
	toast.set_butter_layers(0)

	sandwich_mgr.restore_time_scale()
	ingredient_stations.hide()
	hud.set_sandwich_ui_visible(false)
	hud.set_rodent_ui_visible(false)
	hud.set_space_ui_visible(false)

	if active_mode == GameMode.CLASSIC:
		hud.set_mode_title("KLASİK MOD")
		hud.set_skilled_ui_visible(false)
		toast.set_torque_resistance(1.0)
		remaining_air_boosts = 0
	elif active_mode == GameMode.SKILLED:
		hud.set_mode_title("USTA ŞEF MODU")
		hud.set_skilled_ui_visible(true)
		hud.set_money(skilled_mgr.money)
		toast.set_torque_resistance(skilled_mgr.get_torque_resistance())
		remaining_air_boosts = skilled_mgr.get_max_air_boosts()
		hud.set_air_boost_display(remaining_air_boosts, skilled_mgr.get_max_air_boosts())
	elif active_mode == GameMode.SANDWICH:
		hud.set_mode_title("SANDVİÇ USTASI")
		hud.set_skilled_ui_visible(false)
		hud.set_sandwich_ui_visible(true)
		toast.set_torque_resistance(1.0)
		remaining_air_boosts = 0
		sandwich_mgr.generate_order()
		ingredient_stations.show()
		_refresh_sandwich_hud()
	elif active_mode == GameMode.RODENT:
		hud.set_mode_title("KEMİRGEN MODU")
		hud.set_skilled_ui_visible(false)
		hud.set_rodent_ui_visible(true)
		rodent_mgr.start()
		score = rodent_mgr.score
		_apply_rodent_environment(true)
		rodent_visuals.call("set_active", true, rodent_mgr)
		toast.set_torque_resistance(1.0)
	else:
		hud.set_mode_title("UZAY SANDVİÇİ")
		hud.set_skilled_ui_visible(false)
		hud.set_space_ui_visible(true)
		kitchen_background.hide()
		ground.hide()
		plate.hide()
		toast_shadow.hide()
		toast.set_torque_resistance(1.0)
		score = space_mgr.total_score
		_start_space_run()
		return

	_restart()


func _on_retry_pressed() -> void:
	hud.hide_game_over()
	hud.hide_sell_button()
	score = 0
	lives = MAX_LIVES
	butter_layers = 0
	_pending_sale_reward = 0
	toast.set_butter_layers(0)
	if active_mode == GameMode.SKILLED:
		remaining_air_boosts = skilled_mgr.get_max_air_boosts()
	if active_mode == GameMode.SANDWICH:
		sandwich_mgr.reset_round()
		_refresh_sandwich_hud()
	_round += 1
	_restart()


func _restart() -> void:
	_round += 1
	toast.reset_to(_start_pos)
	toast.set_butter_layers(butter_layers)
	state = GameState.READY
	hud.hide_result()
	if active_mode == GameMode.SKILLED:
		remaining_air_boosts = skilled_mgr.get_max_air_boosts()
	if active_mode == GameMode.SANDWICH:
		_refresh_sandwich_hud()
	_refresh_hud()
	print("Seviye: ", get_level(score), " | Puan: ", score)


# KOLEKSIYON BUTONU
func _on_collection_button_pressed() -> void:
	menu_bg.show()
	gameplay_area.hide()
	toast.hide()
	hud.hide()
	_menu_button.hide()
	skilled_shop.hide()
	mode_select_menu.hide()
	$CanvasLayer/MainMenu.hide()
	$CanvasLayer/CollectionMenu.show()
	state = GameState.COLLECTION


# CIKIS BUTONU
func _on_exit_button_pressed() -> void:
	get_tree().quit()


# GERI BUTONU
func _on_back_button_pressed() -> void:
	_show_main_menu()


# ANA MENU
func _show_main_menu() -> void:
	_round += 1
	_apply_rodent_environment(false)
	if _space_landing_tween != null and _space_landing_tween.is_valid():
		_space_landing_tween.kill()
	sandwich_mgr.restore_time_scale()
	space_world.call("clear")
	rodent_visuals.call("set_active", false, rodent_mgr)
	space_hud.hide()
	toast.reset_to(_start_pos)
	toast.hide()
	gameplay_area.hide()
	ingredient_stations.hide()
	menu_bg.show()

	hud.hide()
	_menu_button.hide()
	hud.hide_game_over()
	hud.hide_result()
	hud.hide_sell_button()
	skilled_shop.hide()
	mode_select_menu.hide()

	$CanvasLayer/CollectionMenu.hide()
	$CanvasLayer/MainMenu.show()

	state = GameState.MAIN_MENU
	
	stop_all_music()
	play_random_menu_music()


func _apply_rodent_environment(enabled: bool) -> void:
	if enabled:
		kitchen_background.hide()
		table_visual.hide()
		plate_visual.hide()
		toast_shadow.hide()
		table_collision.position.y = -43.0
		plate_collision.disabled = true
		_start_pos = Vector2(get_viewport_rect().size.x * 0.5, 467.0)
	else:
		kitchen_background.show()
		table_visual.show()
		plate_visual.show()
		toast_shadow.show()
		table_collision.position = _table_collision_origin
		plate_collision.disabled = _plate_collision_was_disabled
		_start_pos = _kitchen_start_pos


func _setup_menu_animations() -> void:
	# Ana menü butonları
	for child in $CanvasLayer/MainMenu/MenuButtons.get_children():
		if child is Button:
			var button := child as Button

			button.pivot_offset = button.size / 2.0

			button.mouse_entered.connect(
				_animate_menu_button.bind(button, 1.08)
			)
			button.mouse_exited.connect(
				_animate_menu_button.bind(button, 1.0)
			)
			button.button_down.connect(
				_animate_menu_button.bind(button, 1.12)
			)

	# Koleksiyon GERİ butonu
	var back_button := $CanvasLayer/CollectionMenu/BackButton as Button

	if back_button == null:
		push_warning("BackButton normal Button türünde değil.")
		return

	back_button.pivot_offset = back_button.size / 2.0

	back_button.mouse_entered.connect(
		_animate_menu_button.bind(back_button, 1.08)
	)
	back_button.mouse_exited.connect(
		_animate_menu_button.bind(back_button, 1.0)
	)
	back_button.button_down.connect(
		_animate_menu_button.bind(back_button, 0.95)
	)
	back_button.button_up.connect(
		_animate_menu_button.bind(back_button, 1.08)
	)


func _animate_menu_button(button: Button, target_scale: float) -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", Vector2(target_scale, target_scale), 0.15)


# ANA MENU GIRIS ANIMASYONU
func _play_menu_intro() -> void:
	var title := $CanvasLayer/MainMenu/TitleLogo
	var buttons := $CanvasLayer/MainMenu/MenuButtons
	var record := $CanvasLayer/MainMenu/BestScoreDisplay

	# Başlangıçta saydam yap
	title.modulate.a = 0.0
	buttons.modulate.a = 0.0
	record.modulate.a = 0.0

	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)

	# Logo
	tween.tween_property(
		title, "modulate:a", 1.0, 0.5
	)

	# Ahşap butonlar
	tween.tween_property(
		buttons, "modulate:a", 1.0, 0.5
	).set_delay(0.15)

	# Rekor notu
	tween.tween_property(
		record, "modulate:a", 1.0, 0.5
	).set_delay(0.30)


func _exit_tree() -> void:
	sandwich_mgr.restore_time_scale()


# --- SANDVİÇ USTASI ----------------------------------------------------------

func _create_ingredient_stations() -> void:
	var specs := [
		{"id": "lettuce", "name": "Marul", "pos": Vector2(198, 302)},
		{"id": "butter", "name": "Tereyağı", "pos": Vector2(352, 312)},
		{"id": "salami", "name": "Salam", "pos": Vector2(508, 306)},
		{"id": "jam", "name": "Reçel", "pos": Vector2(1038, 428)},
	]
	for spec in specs:
		var station: IngredientStation = IngredientStationScript.new()
		station.ingredient_id = spec["id"]
		station.display_name = spec["name"]
		station.position = spec["pos"]
		ingredient_stations.add_child(station)


func _handle_sandwich_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed):
		return
	if (event as InputEventMouseButton).button_index != MOUSE_BUTTON_LEFT:
		return
	var world_mouse := gameplay_area.get_global_mouse_position()
	for child in ingredient_stations.get_children():
		if child is IngredientStation and world_mouse.distance_to(child.global_position) <= 56.0:
			_on_ingredient_pressed(child.ingredient_id)
			return

	match state:
		GameState.READY:
			_launch_sandwich()
		GameState.FLYING:
			if not toast.airborne:
				return
			if sandwich_mgr.use_control():
				var mid := get_viewport().get_visible_rect().size.x * 0.5
				toast.spin(-1 if event.position.x < mid else 1)
				_refresh_sandwich_hud()
			else:
				hud.show_result("3 hak bitti!", false)


func _launch_sandwich() -> void:
	toast.launch()
	toast.linear_velocity.y *= SandwichModeScript.LAUNCH_HEIGHT_MULT
	toast.angular_velocity = randf_range(-2.0, 2.0)
	state = GameState.FLYING
	sandwich_mgr.on_launched()
	_refresh_sandwich_hud()


func _on_ingredient_pressed(ingredient_id: String) -> void:
	if active_mode != GameMode.SANDWICH:
		return
	if state != GameState.FLYING or not toast.airborne:
		hud.show_result("Önce tostu fırlat!", false)
		return
	var result := sandwich_mgr.try_collect(ingredient_id, toast.airborne)
	match result:
		"ok":
			var label: String = SandwichModeScript.LABELS[ingredient_id]
			if sandwich_mgr.is_order_filled():
				hud.show_result("Sırt üstü indir!", true)
			else:
				hud.show_result("+ %s" % label, true)
			_refresh_sandwich_hud()
		"not_in_order":
			hud.show_result("Siparişte yok!", false)
		"enough":
			hud.show_result("Yeterince var!", false)


func _finish_sandwich_round(correct_face: bool) -> void:
	sandwich_mgr.restore_time_scale()
	var result: Dictionary = sandwich_mgr.evaluate_landing(correct_face)
	if result["success"]:
		score += int(result["points"])
		if score > best_score:
			best_score = score
			_save_best_score()
			if _best_score_label != null:
				_best_score_label.text = str(best_score)
		hud.show_result("HARİKA SANDVİÇ! +%d" % int(result["points"]), true)
	elif result["reason"] == "wrong_face":
		hud.show_result("Ters düştü! 0 puan", false)
	else:
		hud.show_result("Yanlış sipariş! 0 puan", false)

	sandwich_mgr.reset_round()
	_refresh_sandwich_hud()
	_refresh_hud()

	var this_round := _round
	await get_tree().create_timer(1.2).timeout
	if this_round == _round and state == GameState.LANDED:
		_restart()


func _refresh_sandwich_hud() -> void:
	hud.set_sandwich_order(
		sandwich_mgr.order_lines(),
		sandwich_mgr.stack.size(),
		sandwich_mgr.total_target
	)
	hud.set_sandwich_clicks(sandwich_mgr.clicks_left, sandwich_mgr.MAX_CLICKS)
func stop_all_music() -> void:
	menu_music.stop()
	menu_music2.stop()
	menu_music3.stop()

	classic_music.stop()
	galactic_music.stop()
func play_random_menu_music() -> void:
	var tracks = [
		menu_music,
		menu_music2,
		menu_music3
	]

	var selected = tracks.pick_random()
	selected.play()
func _on_menu_music_finished() -> void:
	if state == GameState.MAIN_MENU:
		play_random_menu_music()
