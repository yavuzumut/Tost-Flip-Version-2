class_name SkilledShop
extends Control
## Usta Şef Modu Dükkân paneli.
## Ekmek, tereyağı ve hava takviyesi yükseltmelerini sunar.

signal closed
signal upgraded(type: String)

const SkilledModeScript = preload("res://modes/skilled_mode.gd")

var mode_manager: SkilledModeScript

@onready var _shop_panel: Control = %ShopPanel
@onready var _money_label: Label = %ShopMoneyLabel
@onready var _close_button: Button = %CloseButton

# Ekmek kartı bileşenleri
@onready var _bread_level_label: Label = %BreadLevelLabel
@onready var _bread_desc: Label = %BreadDesc
@onready var _bread_btn: Button = %BreadUpgradeBtn
@onready var _bread_dots: HBoxContainer = %BreadDots

# Tereyağı kartı bileşenleri
@onready var _butter_level_label: Label = %ButterLevelLabel
@onready var _butter_desc: Label = %ButterDesc
@onready var _butter_btn: Button = %ButterUpgradeBtn
@onready var _butter_dots: HBoxContainer = %ButterDots

# Hava takviyesi kartı bileşenleri
@onready var _air_level_label: Label = %AirLevelLabel
@onready var _air_desc: Label = %AirDesc
@onready var _air_btn: Button = %AirUpgradeBtn
@onready var _air_dots: HBoxContainer = %AirDots

var _dot_full_style: StyleBoxFlat
var _dot_empty_style: StyleBoxFlat
var _buttons: Array[Button] = []


func _ready() -> void:
	_init_dot_styles()

	_buttons = [_bread_btn, _butter_btn, _air_btn, _close_button]
	for btn in _buttons:
		_setup_button_anim(btn)

	_close_button.pressed.connect(close)
	_bread_btn.pressed.connect(func(): _on_upgrade_pressed("bread"))
	_butter_btn.pressed.connect(func(): _on_upgrade_pressed("butter"))
	_air_btn.pressed.connect(func(): _on_upgrade_pressed("air_boost"))

	visibility_changed.connect(_on_visibility_changed)
	refresh()


func _unhandled_input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()


func close() -> void:
	hide()
	closed.emit()


func _init_dot_styles() -> void:
	_dot_full_style = StyleBoxFlat.new()
	_dot_full_style.bg_color = Color("38aa38")
	_dot_full_style.border_color = Color("1e661e")
	_dot_full_style.set_border_width_all(2)
	_dot_full_style.set_corner_radius_all(6)

	_dot_empty_style = StyleBoxFlat.new()
	_dot_empty_style.bg_color = Color("f0e5d0")
	_dot_empty_style.border_color = Color("a88960")
	_dot_empty_style.set_border_width_all(2)
	_dot_empty_style.set_corner_radius_all(6)


func refresh() -> void:
	if mode_manager == null:
		return

	_money_label.text = "%d" % mode_manager.money

	# 1. Ekmek Kartı
	var b_lvl: int = mode_manager.bread_level
	_bread_level_label.text = "Seviye %d / 5" % b_lvl
	if b_lvl < 5:
		var cur_cap: int = mode_manager.get_max_butter_layers()
		var nxt_cap: int = cur_cap + 1
		_bread_desc.text = "Maksimum katman: %d -> %d\nTork direnci: +%%15" % [cur_cap, nxt_cap]
		var cost: int = mode_manager.get_upgrade_cost("bread")
		_bread_btn.text = "%d 🪙" % cost
		_bread_btn.disabled = mode_manager.money < cost
	else:
		_bread_desc.text = "Maksimum katman: %d (En Yüksek!)\nMaksimum denge ve direnç." % mode_manager.get_max_butter_layers()
		_bread_btn.text = "MAKS"
		_bread_btn.disabled = true
	_update_dots(_bread_dots, b_lvl, 5)

	# 2. Tereyağı Kartı
	var t_lvl: int = mode_manager.butter_level
	_butter_level_label.text = "Seviye %d / 5" % t_lvl
	if t_lvl < 5:
		var cur_mult: float = mode_manager.get_butter_multiplier()
		var nxt_mult: float = mode_manager.BUTTER_MULTIPLIERS[t_lvl]
		_butter_desc.text = "Satış çarpanı: x%.2f -> x%.2f\nDaha yüksek kazanç!" % [cur_mult, nxt_mult]
		var cost: int = mode_manager.get_upgrade_cost("butter")
		_butter_btn.text = "%d 🪙" % cost
		_butter_btn.disabled = mode_manager.money < cost
	else:
		_butter_desc.text = "Satış çarpanı: x%.2f (Altın Kalite!)\nEn yüksek tost fiyatı." % mode_manager.get_butter_multiplier()
		_butter_btn.text = "MAKS"
		_butter_btn.disabled = true
	_update_dots(_butter_dots, t_lvl, 5)

	# 3. Hava Takviyesi Kartı
	var a_lvl: int = mode_manager.air_boost_level
	_air_level_label.text = "Seviye %d / 2" % a_lvl
	if a_lvl < 2:
		_air_desc.text = "Havada ekstra takviye: %d -> %d hak\nSpace tuşu ile fırla!" % [a_lvl, a_lvl + 1]
		var cost: int = mode_manager.get_upgrade_cost("air_boost")
		_air_btn.text = "%d 🪙" % cost
		_air_btn.disabled = mode_manager.money < cost
	else:
		_air_desc.text = "Havada ekstra takviye: %d hak (Maksimum!)\nSpace tuşu ile göklere!" % a_lvl
		_air_btn.text = "MAKS"
		_air_btn.disabled = true
	_update_dots(_air_dots, a_lvl, 2)


func _update_dots(container: HBoxContainer, current: int, total: int) -> void:
	var children := container.get_children()
	for i in children.size():
		var dot := children[i] as Panel
		dot.visible = i < total
		dot.add_theme_stylebox_override("panel", _dot_full_style if i < current else _dot_empty_style)


func _on_upgrade_pressed(type: String) -> void:
	if mode_manager != null and mode_manager.upgrade(type):
		refresh()
		upgraded.emit(type)


# --- BUTON ANİMASYONLARI & MODAL AÇILIŞ -------------------------------------

func _setup_button_anim(btn: Button) -> void:
	btn.resized.connect(func(): btn.pivot_offset = btn.size * 0.5)
	btn.pivot_offset = btn.size * 0.5
	btn.mouse_entered.connect(_animate_scale.bind(btn, 1.06))
	btn.mouse_exited.connect(_animate_scale.bind(btn, 1.0))
	btn.button_down.connect(_animate_scale.bind(btn, 0.95))
	btn.button_up.connect(func(): _animate_scale(btn, 1.06 if btn.is_hovered() else 1.0))


func _animate_scale(btn: Control, target: float) -> void:
	if btn is BaseButton and (btn as BaseButton).disabled:
		target = 1.0
	var tw := btn.create_tween()
	tw.tween_property(btn, "scale", Vector2.ONE * target, 0.12) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_visibility_changed() -> void:
	if not visible or not is_node_ready():
		return
	refresh()
	# Açılışta yumuşak belirme ve hafif pop efekti
	_shop_panel.pivot_offset = _shop_panel.size * 0.5
	_shop_panel.scale = Vector2.ONE * 0.94
	modulate.a = 0.0

	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "modulate:a", 1.0, 0.2).set_trans(Tween.TRANS_SINE)
	tw.tween_property(_shop_panel, "scale", Vector2.ONE, 0.22) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
