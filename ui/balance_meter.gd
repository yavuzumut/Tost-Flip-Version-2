@tool
extends Control
class_name BalanceMeter
## AĞIRLIK DENGESİ çubuğu: kırmızı-sarı-yeşil-sarı-kırmızı gradyan üzerinde kayan işaretçi.
## value: -1 (sola aşırı) .. 0 (dengeli) .. +1 (sağa aşırı)

@export_range(-1.0, 1.0) var value := 0.0:
	set(v):
		value = clampf(v, -1.0, 1.0)
		if Engine.is_editor_hint():
			_shown = value
			queue_redraw()
@export_range(0.0, 1.0) var wobble := 0.0   ## tereyağı katmanı arttıkça işaretçi titrer
@export var follow_speed := 10.0
@export var bar_height := 14.0
@export var gradient: Gradient

var _shown := 0.0
var _time := 0.0
var _marker_box := StyleBoxFlat.new()
var _track_box := StyleBoxFlat.new()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if gradient == null:
		gradient = Gradient.new()
		gradient.offsets = PackedFloat32Array([0.0, 0.3, 0.5, 0.7, 1.0])
		gradient.colors = PackedColorArray([
			Color("e8394a"), Color("f2c14e"), Color("5cc95a"), Color("f2c14e"), Color("e8394a")])
	_track_box.bg_color = Color("5a2e12")
	_track_box.set_corner_radius_all(int(bar_height * 0.5) + 3)
	_marker_box.bg_color = Color("fffaf0")
	_marker_box.border_color = Color("5a2e12")
	_marker_box.set_border_width_all(2)
	_marker_box.set_corner_radius_all(4)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_time += delta
	var target := value + sin(_time * 17.0) * wobble * 0.07
	_shown = lerpf(_shown, clampf(target, -1.0, 1.0), clampf(delta * follow_speed, 0.0, 1.0))
	queue_redraw()


func _draw() -> void:
	var h := minf(bar_height, size.y)
	var y := (size.y - h) * 0.5
	var r := h * 0.5
	# Koyu çerçeve
	draw_style_box(_track_box, Rect2(0, y - 3, size.x, h + 6))
	# Gradyan dolgu (dilimler + yuvarlak uçlar)
	var x0 := r
	var x1 := size.x - r
	var steps := maxi(8, int((x1 - x0) / 3.0))
	for i in steps:
		var t := float(i) / steps
		var xa := lerpf(x0, x1, t)
		var xb := lerpf(x0, x1, float(i + 1) / steps) + 0.6
		draw_rect(Rect2(xa, y, xb - xa, h), gradient.sample(t))
	draw_circle(Vector2(x0, y + r), r, gradient.sample(0.0))
	draw_circle(Vector2(x1, y + r), r, gradient.sample(1.0))
	# Üstte hafif parlama
	draw_rect(Rect2(x0, y + 2, x1 - x0, h * 0.25), Color(1, 1, 1, 0.22))
	# İşaretçi
	var mx := lerpf(x0, x1, (_shown + 1.0) * 0.5)
	var mw := 10.0
	draw_style_box(_marker_box, Rect2(mx - mw * 0.5, y - 7, mw, h + 14))
