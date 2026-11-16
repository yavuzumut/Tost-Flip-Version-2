extends CanvasLayer
class_name GameHUD
## Oynanış HUD'u. Görsel yerleşim hud.tscn'de; bu script yalnızca değerleri günceller.
## GameManager (node_2d.gd) set_* fonksiyonlarını çağırır, HUD oyun mantığı içermez.

signal retry_pressed
signal menu_pressed
signal shop_pressed
signal sell_pressed

const BALANCE_LIMIT := 0.6   ## |değer| bunu aşarsa DENGESİZ

@export var heart_full: Texture2D
@export var heart_empty: Texture2D
@export var cell_full: StyleBox
@export var cell_empty: StyleBox

const BalanceMeterScript = preload("res://ui/balance_meter.gd")

@onready var _mode_label: Label = %ModeLabel
@onready var _score_value: Label = %ScoreValue
@onready var _butter_count: Label = %ButterCount
@onready var _butter_cells: HBoxContainer = %ButterCells
@onready var _lives_label: Label = %LivesLabel
@onready var _hearts: HBoxContainer = %Hearts
@onready var _balance_state: Label = %BalanceState
@onready var _balance_meter: Control = %BalanceMeter
@onready var _balance_panel: PanelContainer = $Root/BalancePanel
@onready var _result_label: Label = %ResultLabel
@onready var _game_over: Control = %GameOverPanel
@onready var _final_score: Label = %FinalScore
@onready var _final_best: Label = %FinalBest

# Usta Şef Modu Arayüz Elemanları
@onready var _money_panel: PanelContainer = %MoneyPanel
@onready var _money_value: Label = %MoneyValue
@onready var _shop_button: Button = %ShopButton
@onready var _sell_button: Button = %SellButton
@onready var _air_boost_panel: PanelContainer = %AirBoostPanel
@onready var _air_boost_label: Label = %AirBoostLabel
@onready var _butter_panel: PanelContainer = %ButterPanel
@onready var _lives_panel: PanelContainer = %LivesPanel
@onready var _sandwich_hud: SandwichHUD = %SandwichPanel
@onready var _left_click_hint: Label = %LeftClick
@onready var _right_click_hint: Label = %RightClick

var _lives := -1
var _butter := -1
var _score := -1
var _money := -1
var _balanced := true
var _result_tween: Tween


func _ready() -> void:
	%RetryButton.pressed.connect(func(): retry_pressed.emit())
	%MenuButton.pressed.connect(func(): menu_pressed.emit())
	_shop_button.pressed.connect(func(): shop_pressed.emit())
	_sell_button.pressed.connect(func(): sell_pressed.emit())

	_result_label.visible = false
	_game_over.visible = false
	_sell_button.visible = false
	_set_balance_state(true, true)


# --- MOD & BAŞLIK ------------------------------------------------------------
func set_mode_title(title: String) -> void:
	_mode_label.text = title


# --- SKOR -------------------------------------------------------------------
func set_score(value: int) -> void:
	var changed := _score >= 0 and value > _score
	_score = value
	_score_value.text = str(value)
	if changed:
		_pop(_score_value, 1.35)


# --- USTA ŞEF MODU EKONOMİ & YETENEKLER --------------------------------------
func set_skilled_ui_visible(is_skilled: bool) -> void:
	_money_panel.visible = is_skilled
	_shop_button.visible = is_skilled
	_air_boost_panel.visible = is_skilled
	if not is_skilled:
		_sell_button.visible = false


func set_sandwich_ui_visible(is_sandwich: bool) -> void:
	_sandwich_hud.visible = is_sandwich
	_butter_panel.visible = not is_sandwich
	_lives_panel.visible = not is_sandwich
	_balance_panel.visible = not is_sandwich
	if is_sandwich:
		set_skilled_ui_visible(false)
		set_controls_hint("Sol tık: Fırlat / 3 hak yön ver", "İstasyon: Malzeme ekle")
	else:
		_balance_panel.visible = true
		set_controls_hint("Sol tık: Fırlat / Sola döndür", "Sağ tık: Sağa döndür")


func set_rodent_ui_visible(is_rodent: bool) -> void:
	_sandwich_hud.visible = false
	_butter_panel.visible = true
	_lives_panel.visible = not is_rodent
	_balance_panel.visible = not is_rodent
	if is_rodent:
		set_skilled_ui_visible(false)
		set_controls_hint("Sol tık: Fırlat / Fareyi korkut", "Tereyağı tabağına tıkla")


func set_space_ui_visible(is_space: bool) -> void:
	_butter_panel.visible = not is_space
	_lives_panel.visible = not is_space
	_balance_panel.visible = not is_space
	_sandwich_hud.visible = false
	if is_space:
		set_skilled_ui_visible(false)
		set_controls_hint("A/D veya oklar: Hareket", "Fare: Tostu yönlendir")


func set_sandwich_order(lines: PackedStringArray, collected: int, target: int) -> void:
	_sandwich_hud.set_order_display(lines, collected, target)


func set_sandwich_clicks(current: int, maximum: int) -> void:
	_sandwich_hud.set_clicks(current, maximum)


func set_controls_hint(left_text: String, right_text: String) -> void:
	_left_click_hint.text = left_text
	_right_click_hint.text = right_text


func set_money(amount: int) -> void:
	var changed := _money >= 0 and amount > _money
	_money = amount
	_money_value.text = "%d" % amount
	if changed:
		_pop(_money_value, 1.4)


func show_sell_button(reward: int, unit: String = "🪙") -> void:
	_sell_button.text = "Tostu Sat (+%d %s)" % [reward, unit]
	_sell_button.visible = true
	_pop(_sell_button, 1.25)


func hide_sell_button() -> void:
	_sell_button.visible = false


func set_air_boost_display(current: int, maximum: int) -> void:
	if maximum <= 0:
		_air_boost_panel.visible = false
		return
	_air_boost_panel.visible = true
	_air_boost_label.text = "Hava Boost (Space): %d / %d" % [current, maximum]



# --- TEREYAĞI ---------------------------------------------------------------
func set_butter(current: int, maximum: int) -> void:
	var gained := _butter >= 0 and current > _butter
	_butter = current
	_butter_count.text = "%d / %d Katman" % [current, maximum]
	var cells := _butter_cells.get_children()
	for i in cells.size():
		var cell := cells[i] as Panel
		cell.visible = i < maximum
		cell.add_theme_stylebox_override("panel", cell_full if i < current else cell_empty)
		if gained and i == current - 1:
			_pop(cell, 1.6)


# --- CAN (HAVA HAK) ---------------------------------------------------------
func set_lives(current: int, maximum: int) -> void:
	var lost := _lives >= 0 and current < _lives
	_lives = current
	_lives_label.text = "HAVA HAK: %d / %d" % [current, maximum]
	var hearts := _hearts.get_children()
	for i in hearts.size():
		var heart := hearts[i] as TextureRect
		heart.visible = i < maximum
		heart.texture = heart_full if i < current else heart_empty
		heart.scale = Vector2.ONE
		heart.rotation = 0.0
	if lost and current < hearts.size():
		_shake(hearts[current] as Control)


# --- AĞIRLIK DENGESİ --------------------------------------------------------
## value: -1..1 (tostun fiziksel dönüş dengesi), wobble: 0..1 (tereyağı yükü titreşimi)
func set_balance(value: float, wobble: float = 0.0) -> void:
	_balance_meter.value = value
	_balance_meter.wobble = wobble
	_set_balance_state(absf(value) <= BALANCE_LIMIT)


func _set_balance_state(balanced: bool, force := false) -> void:
	if balanced == _balanced and not force:
		return
	_balanced = balanced
	_balance_state.text = "DENGELİ" if balanced else "DENGESİZ"
	_balance_state.add_theme_color_override("font_color", Color("3fae3c") if balanced else Color("d8323f"))
	if not force:
		_pop(_balance_state, 1.2)


# --- SONUÇ / OYUN BİTTİ -----------------------------------------------------
func show_result(text: String, success: bool) -> void:
	if _result_tween and _result_tween.is_valid():
		_result_tween.kill()
	_result_label.text = text
	_result_label.add_theme_color_override("font_color", Color("fff3b0") if success else Color("ffb3a8"))
	_result_label.add_theme_color_override("font_outline_color", Color("2f6b1f") if success else Color("7a1e22"))
	_result_label.visible = true
	_result_label.modulate.a = 1.0
	_result_label.pivot_offset = _result_label.size * 0.5
	_result_label.scale = Vector2(0.6, 0.6)
	_result_tween = create_tween()
	_result_tween.tween_property(_result_label, "scale", Vector2.ONE, 0.25)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_result_tween.tween_interval(0.7)
	_result_tween.tween_property(_result_label, "modulate:a", 0.0, 0.25)
	_result_tween.tween_callback(_result_label.hide)


func hide_result() -> void:
	if _result_tween and _result_tween.is_valid():
		_result_tween.kill()
	_result_label.visible = false


func show_game_over(final_score: int, best: int) -> void:
	_final_score.text = "Skor: %d" % final_score
	_final_best.text = "Rekor: %d" % best
	_game_over.visible = true
	var card := %GameOverCard as Control
	card.pivot_offset = card.size * 0.5
	card.scale = Vector2(0.7, 0.7)
	_game_over.modulate.a = 0.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_game_over, "modulate:a", 1.0, 0.2)
	tw.tween_property(card, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func hide_game_over() -> void:
	_game_over.visible = false


# --- Küçük animasyon yardımcıları -------------------------------------------
func _pop(node: Control, amount: float) -> void:
	node.pivot_offset = node.size * 0.5
	var tw := node.create_tween()
	tw.tween_property(node, "scale", Vector2(amount, amount), 0.08)
	tw.tween_property(node, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _shake(node: Control) -> void:
	node.pivot_offset = node.size * 0.5
	var tw := node.create_tween()
	tw.tween_property(node, "scale", Vector2(1.4, 1.4), 0.08)
	for a in [0.35, -0.35, 0.2, -0.2, 0.0]:
		tw.tween_property(node, "rotation", a, 0.06)
	tw.tween_property(node, "scale", Vector2.ONE, 0.15)
