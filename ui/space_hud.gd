extends PanelContainer
## HUD only displays values supplied by the existing SpaceMode manager.

@onready var _distance: Label = $Column/AltitudeDisplay
@onready var _progress: ProgressBar = $Column/AltitudeProgress
@onready var _order: Label = $Column/OrderDisplay
@onready var _powers: Label = $Column/PowerUpDisplay
@onready var _score: Label = $Column/ScoreDisplay
@onready var _result: Label = $Column/ResultPanel

func set_space_state(altitude: float, total_score: int, round_score: int, order_lines: PackedStringArray, turbo: float, shield: float, landed: bool) -> void:
	_distance.text = "Dünyaya kalan: %d m" % int(ceil(altitude))
	_progress.value = (1.0 - clampf(altitude / 2400.0, 0.0, 1.0)) * 100.0
	_order.text = "   ·   ".join(order_lines) if not order_lines.is_empty() else "Malzeme siparişi tamamlandı"
	var active := PackedStringArray()
	if turbo > 0.0:
		active.append("Turbo %.1f sn" % turbo)
	if shield > 0.0:
		active.append("Kalkan %.1f sn" % shield)
	_powers.text = "   ·   ".join(active) if not active.is_empty() else "Güç: —"
	_score.text = "Bu tur: %d     Toplam: %d" % [round_score, total_score]
	_result.text = "İniş tamamlandı" if landed else ""
