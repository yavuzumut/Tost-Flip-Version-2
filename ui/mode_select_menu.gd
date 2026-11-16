class_name ModeSelectMenu
extends Control
## Oyun Modları Seçim Menüsü.
## Beş oyun modu iki sayfaya dağıtılmıştır.
## Sayfa 1: Klasik + Usta Şef  |  Sayfa 2: Sandviç Ustası, Kemirgen, Uzay Sandviçi

signal back_pressed
signal mode_chosen(mode_index: int)   # 0: Klasik, 1: Usta Şef, 2: Sandviç, 3: Kemirgen, 4: Uzay

enum Mode { CLASSIC = 0, SKILLED = 1, SANDWICH = 2, RODENT = 3, SPACE = 4 }

const GLOW_SHADER := preload("res://ui/mode_card_glow.gdshader")
const CARD_ASPECT := 2.0 / 3.0          # kart görselleri 1536x2304
const GLOW_PAD := 24.0                  # Glow/Shadow düğümlerinin kart dışına taşma payı (px)
const SHADOW_SHIFT := 10.0              # gölgenin aşağı kayması (px)
const SIDE_MARGIN := 40.0
const PAGE2_SCALE := 0.9                # kilitli kartlar biraz daha küçük
const HOVER_SCALE := 1.03
const SELECTED_SCALE := 1.06
const HOVER_GLOW := 0.35
const PAGE_ANIM_TIME := 0.32
const LOCKED_TINT := Color(0.78, 0.72, 0.66, 1.0)
const LOCKED_TINT_HOVER := Color(0.88, 0.82, 0.76, 1.0)
const DOT_ACTIVE := Color(1, 1, 1, 1)
const DOT_INACTIVE := Color(0.33, 0.2, 0.12, 0.85)

@onready var _card_classic: TextureButton = %CardClassic
@onready var _card_chef: TextureButton = %CardChef
@onready var _card_sandwich: TextureButton = %CardSandwich
@onready var _card_chaos: TextureButton = %CardChaos
@onready var _card_space: TextureButton = %CardSpace

@onready var _select_btn: Button = %PlayButton
@onready var _back_btn: Button = %BackButton

@onready var _header: Control = %Header
@onready var _cards_area: Control = %CardsArea
@onready var _pagination: Control = %Pagination
@onready var _pages: Array[HBoxContainer] = [%Page1, %Page2]
@onready var _page_dots: Array[TextureButton] = [%PageDot1, %PageDot2]
@onready var _prev_page_btn: Button = %PrevPage
@onready var _next_page_btn: Button = %NextPage

var selected_mode: int = Mode.CLASSIC
var current_page := 0

var _unlocked_cards := {}               # TextureButton -> Mode
var _locked_cards: Array[TextureButton] = []
var _hovered_card: TextureButton = null
var _card_tweens := {}                  # TextureButton -> Tween
var _pulse_tween: Tween
var _page_tween: Tween
var _intro_tween: Tween


func _ready() -> void:
	_unlocked_cards = {
		_card_classic: Mode.CLASSIC,
		_card_chef: Mode.SKILLED,
		_card_sandwich: Mode.SANDWICH,
		_card_chaos: Mode.RODENT,
		_card_space: Mode.SPACE,
	}
	_locked_cards.clear()
	for card in _unlocked_cards:
		card.self_modulate = Color.WHITE
		var lock_badge := card.get_node_or_null("LockBadge") as CanvasItem
		if lock_badge:
			lock_badge.hide()
	for card in _all_cards():
		_setup_card(card)

	_card_classic.pressed.connect(func(): _select_mode(Mode.CLASSIC, _card_classic))
	_card_chef.pressed.connect(func(): _select_mode(Mode.SKILLED, _card_chef))
	_card_sandwich.pressed.connect(func(): _select_mode(Mode.SANDWICH, _card_sandwich))

	_card_chaos.pressed.connect(func(): _select_mode(Mode.RODENT, _card_chaos))
	_card_space.pressed.connect(func(): _select_mode(Mode.SPACE, _card_space))

	_select_btn.pressed.connect(func(): mode_chosen.emit(selected_mode))
	_back_btn.pressed.connect(func(): back_pressed.emit())

	# Sayfalama
	_prev_page_btn.pressed.connect(func(): _go_to_page(current_page - 1))
	_next_page_btn.pressed.connect(func(): _go_to_page(current_page + 1))
	for i in _page_dots.size():
		_page_dots[i].pressed.connect(_go_to_page.bind(i))

	for btn: Control in [_back_btn, _select_btn, _prev_page_btn, _next_page_btn]:
		_setup_button_anim(btn)

	_cards_area.resized.connect(_layout_cards)
	visibility_changed.connect(_on_visibility_changed)

	_show_page_immediate(0)
	_update_pagination()
	_layout_cards()

	# Varsayılan seçim
	call_deferred("_select_mode", Mode.CLASSIC, _card_classic)


func _unhandled_input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event.is_action_pressed("ui_left"):
		_go_to_page(current_page - 1)
		accept_event()
	elif event.is_action_pressed("ui_right"):
		_go_to_page(current_page + 1)
		accept_event()
	elif event.is_action_pressed("ui_cancel"):
		accept_event()
		back_pressed.emit()


# --- KART SEÇİMİ ------------------------------------------------------------

func _select_mode(mode: int, card_btn: TextureButton) -> void:
	selected_mode = mode
	for card in _unlocked_cards:
		_refresh_card(card)

	# Seçilen karta küçük bir "zıplama" ve yumuşak altın parıltı nabzı
	_kill_card_tween(card_btn)
	var tw := card_btn.create_tween()
	_card_tweens[card_btn] = tw
	tw.tween_property(card_btn, "scale", Vector2.ONE * (SELECTED_SCALE + 0.03), 0.1) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(card_btn, "scale", Vector2.ONE * _target_scale(card_btn), 0.22) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_method(_set_glow.bind(card_btn), _get_glow(card_btn), 1.0, 0.2)
	_start_pulse(card_btn)


func _shake_card(card: Control) -> void:
	var tw := card.create_tween()
	var base_pos := card.position
	for offset in [8.0, -8.0, 5.0, -5.0, 0.0]:
		tw.tween_property(card, "position:x", base_pos.x + offset, 0.04)


func _setup_card(card: TextureButton) -> void:
	var glow := card.get_node("Glow") as TextureRect
	var glow_mat := ShaderMaterial.new()
	glow_mat.shader = GLOW_SHADER
	glow_mat.set_shader_parameter("intensity", 0.0)
	glow.material = glow_mat

	var shadow := card.get_node("Shadow") as TextureRect
	var shadow_mat := ShaderMaterial.new()
	shadow_mat.shader = GLOW_SHADER
	shadow_mat.set_shader_parameter("glow_color", Color(0.16, 0.06, 0.01, 1.0))
	shadow_mat.set_shader_parameter("rim_strength", 0.0)
	shadow_mat.set_shader_parameter("intensity", 0.55)
	shadow.material = shadow_mat

	card.mouse_entered.connect(_on_card_hover.bind(card, true))
	card.mouse_exited.connect(_on_card_hover.bind(card, false))
	card.resized.connect(_on_card_resized.bind(card))
	_on_card_resized(card)


func _on_card_resized(card: TextureButton) -> void:
	var s := card.size
	if s.x <= 0.0 or s.y <= 0.0:
		return
	card.pivot_offset = s * 0.5
	var outer := s + Vector2.ONE * GLOW_PAD * 2.0
	var pad := Vector2(GLOW_PAD / outer.x, GLOW_PAD / outer.y)
	var aspect := s.x / s.y

	var glow_mat := (card.get_node("Glow") as CanvasItem).material as ShaderMaterial
	glow_mat.set_shader_parameter("pad", pad)
	glow_mat.set_shader_parameter("aspect", aspect)
	glow_mat.set_shader_parameter("rim_width", 4.5 / s.x)
	glow_mat.set_shader_parameter("glow_width", 15.0 / s.x)

	var shadow_mat := (card.get_node("Shadow") as CanvasItem).material as ShaderMaterial
	shadow_mat.set_shader_parameter("pad", pad)
	shadow_mat.set_shader_parameter("aspect", aspect)
	shadow_mat.set_shader_parameter("glow_width", 7.0 / s.x)


func _on_card_hover(card: TextureButton, entered: bool) -> void:
	if entered:
		_hovered_card = card
	elif _hovered_card == card:
		_hovered_card = null
	_refresh_card(card)


func _is_selected(card: TextureButton) -> bool:
	return _unlocked_cards.has(card) and _unlocked_cards[card] == selected_mode


func _target_scale(card: TextureButton) -> float:
	var hovered := card == _hovered_card
	if _is_selected(card):
		return SELECTED_SCALE + (0.01 if hovered else 0.0)
	return HOVER_SCALE if hovered else 1.0


func _target_glow(card: TextureButton) -> float:
	if _is_selected(card):
		return 1.0
	if card == _hovered_card and _unlocked_cards.has(card):
		return HOVER_GLOW
	return 0.0


## Kartın ölçek, parıltı ve renk tonunu mevcut duruma (seçili/üzerinde/kilitli) göre yumuşakça günceller.
func _refresh_card(card: TextureButton) -> void:
	_kill_card_tween(card)
	var tw := card.create_tween().set_parallel(true)
	_card_tweens[card] = tw
	tw.tween_property(card, "scale", Vector2.ONE * _target_scale(card), 0.18) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_method(_set_glow.bind(card), _get_glow(card), _target_glow(card), 0.18)
	if card in _locked_cards:
		var tint := LOCKED_TINT_HOVER if card == _hovered_card else LOCKED_TINT
		tw.tween_property(card, "self_modulate", tint, 0.18)
	if not _is_selected(card):
		_set_pulse(card, 1.0)


func _kill_card_tween(card: TextureButton) -> void:
	var old: Tween = _card_tweens.get(card)
	if old != null and old.is_valid():
		old.kill()


func _get_glow(card: TextureButton) -> float:
	var mat := (card.get_node("Glow") as CanvasItem).material as ShaderMaterial
	return float(mat.get_shader_parameter("intensity"))


func _set_glow(value: float, card: TextureButton) -> void:
	var mat := (card.get_node("Glow") as CanvasItem).material as ShaderMaterial
	mat.set_shader_parameter("intensity", value)


func _set_pulse(card: TextureButton, value: float) -> void:
	var mat := (card.get_node("Glow") as CanvasItem).material as ShaderMaterial
	mat.set_shader_parameter("pulse", value)


func _start_pulse(card: TextureButton) -> void:
	if _pulse_tween != null and _pulse_tween.is_valid():
		_pulse_tween.kill()
	_set_pulse(card, 1.0)
	var setter := func(v: float): _set_pulse(card, v)
	_pulse_tween = create_tween().set_loops()
	_pulse_tween.tween_method(setter, 1.0, 0.72, 0.9) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT).set_delay(0.3)
	_pulse_tween.tween_method(setter, 0.72, 1.0, 0.9) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _all_cards() -> Array[TextureButton]:
	return [_card_classic, _card_chef, _card_sandwich, _card_chaos, _card_space]


# --- YERLEŞİM ---------------------------------------------------------------

## Kart boyutlarını kullanılabilir alana göre hesaplar; her zaman tam 2:3 oranı korunur.
func _layout_cards() -> void:
	var area := _cards_area.size
	if area.x <= 0.0 or area.y <= 0.0:
		return
	var avail_w := area.x - SIDE_MARGIN * 2.0

	var gap1 := float(_pages[0].get_theme_constant("separation"))
	var h1 := minf(area.y * 0.96, (avail_w - gap1) / 2.0 / CARD_ASPECT)
	for card in [_card_classic, _card_chef]:
		card.custom_minimum_size = Vector2(floorf(h1 * CARD_ASPECT), floorf(h1))

	var gap2 := float(_pages[1].get_theme_constant("separation"))
	var h2 := minf(h1 * PAGE2_SCALE, (avail_w - gap2 * 2.0) / 3.0 / CARD_ASPECT)
	for card in [_card_sandwich, _card_chaos, _card_space]:
		card.custom_minimum_size = Vector2(floorf(h2 * CARD_ASPECT), floorf(h2))


# --- SAYFALAMA --------------------------------------------------------------

func _go_to_page(page: int) -> void:
	page = clampi(page, 0, _pages.size() - 1)
	if page == current_page:
		return
	# Önceki geçiş yarıda kaldıysa temiz bir duruma getir
	if _page_tween != null and _page_tween.is_valid():
		_page_tween.kill()
	_show_page_immediate(current_page)

	var dir := 1.0 if page > current_page else -1.0
	var old_page := _pages[current_page]
	var new_page := _pages[page]
	var dist := _cards_area.size.x * 0.3
	current_page = page
	_hovered_card = null
	_update_pagination()

	new_page.visible = true
	new_page.position.x = dir * dist
	new_page.modulate.a = 0.0

	_page_tween = create_tween().set_parallel(true) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_page_tween.tween_property(old_page, "position:x", -dir * dist, PAGE_ANIM_TIME)
	_page_tween.tween_property(old_page, "modulate:a", 0.0, PAGE_ANIM_TIME * 0.8)
	_page_tween.tween_property(new_page, "position:x", 0.0, PAGE_ANIM_TIME)
	_page_tween.tween_property(new_page, "modulate:a", 1.0, PAGE_ANIM_TIME)
	_page_tween.chain().tween_callback(_show_page_immediate.bind(page))


func _show_page_immediate(page: int) -> void:
	for i in _pages.size():
		var p := _pages[i]
		p.visible = i == page
		p.position.x = 0.0
		p.modulate.a = 1.0


func _update_pagination() -> void:
	for i in _page_dots.size():
		var dot := _page_dots[i]
		var active := i == current_page
		dot.pivot_offset = dot.custom_minimum_size * 0.5
		var tw := dot.create_tween().set_parallel(true)
		tw.tween_property(dot, "modulate", DOT_ACTIVE if active else DOT_INACTIVE, 0.2)
		tw.tween_property(dot, "scale", Vector2.ONE * (1.15 if active else 0.9), 0.2) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_prev_page_btn.disabled = current_page == 0
	_next_page_btn.disabled = current_page == _pages.size() - 1
	_prev_page_btn.modulate.a = 0.45 if _prev_page_btn.disabled else 1.0
	_next_page_btn.modulate.a = 0.45 if _next_page_btn.disabled else 1.0


# --- BUTON ANİMASYONLARI & GİRİŞ -------------------------------------------

func _setup_button_anim(btn: Control) -> void:
	btn.resized.connect(func(): btn.pivot_offset = btn.size * 0.5)
	btn.pivot_offset = btn.size * 0.5
	btn.mouse_entered.connect(_tween_scale.bind(btn, 1.06))
	btn.mouse_exited.connect(_tween_scale.bind(btn, 1.0))
	if btn is BaseButton:
		var b := btn as BaseButton
		b.button_down.connect(_tween_scale.bind(btn, 0.95))
		b.button_up.connect(func(): _tween_scale(btn, 1.06 if b.is_hovered() else 1.0))


func _tween_scale(ctrl: Control, target: float) -> void:
	if ctrl is BaseButton and (ctrl as BaseButton).disabled:
		target = 1.0
	var tw := ctrl.create_tween()
	tw.tween_property(ctrl, "scale", Vector2.ONE * target, 0.15) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_visibility_changed() -> void:
	if not visible or not is_node_ready():
		return
	if _page_tween != null and _page_tween.is_valid():
		_page_tween.kill()
	current_page = 0
	_hovered_card = null
	_show_page_immediate(0)
	_update_pagination()
	_layout_cards()
	_play_intro()


## Menü açılırken hafif bir belirme ve kartların yerine oturması.
func _play_intro() -> void:
	if _intro_tween != null and _intro_tween.is_valid():
		_intro_tween.kill()
	var faders: Array[Control] = [_header, _cards_area, _pagination, _back_btn, _select_btn]
	for c in faders:
		c.modulate.a = 0.0
	_intro_tween = create_tween().set_parallel(true) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	for i in faders.size():
		_intro_tween.tween_property(faders[i], "modulate:a", 1.0, 0.35).set_delay(i * 0.05)
	for card in _all_cards():
		card.scale = Vector2.ONE * 0.92
		_refresh_card(card)
