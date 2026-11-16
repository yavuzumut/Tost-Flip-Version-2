extends PanelContainer
class_name SandwichHUD
## Sandviç Ustası sipariş ve kontrol hakkı göstergesi. Oyun mantığı içermez.

@onready var _order_label: Label = $VBox/SandwichOrderLabel
@onready var _clicks_label: Label = $VBox/SandwichClicksLabel


func set_order_display(lines: PackedStringArray, collected: int, target: int) -> void:
	if lines.is_empty():
		_order_label.text = "Sipariş yok"
	else:
		_order_label.text = "\n".join(lines)
	tooltip_text = "Toplanan: %d / %d" % [collected, target]


func set_clicks(current: int, maximum: int) -> void:
	_clicks_label.text = "KONTROL: %d / %d" % [current, maximum]
