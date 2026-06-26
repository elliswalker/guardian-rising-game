extends Control

var is_captured: bool = false
var pulse_time: float = 0.0
var _dusk_urgency: float = 0.0
var _ability_fraction: float = 1.0  # 1.0 = ready, 0.0 = just used

func set_dusk_urgency(value: float) -> void:
	_dusk_urgency = clampf(value, 0.0, 1.0)

func set_ability_fraction(f: float) -> void:
	_ability_fraction = clampf(f, 0.0, 1.0)

func _process(delta: float) -> void:
	pulse_time += delta
	queue_redraw()

func _draw() -> void:
	var center := size / 2.0
	var r: float = min(size.x, size.y) * 0.44
	var pts := PackedVector2Array()
	# Octagon via 8 vertices at 22.5° offset
	for i in range(8):
		var a := deg_to_rad(22.5 + i * 45.0)
		pts.append(center + Vector2(cos(a), sin(a)) * r)

	var pulse_speed: float = 2.2 + _dusk_urgency * 7.0
	var pulse := (sin(pulse_time * pulse_speed) + 1.0) * 0.5

	var fill_col: Color
	var line_col: Color

	if is_captured:
		fill_col = Color(0.5, 0.05, 0.05, 0.35)
		line_col = Color(1.0, 0.2, 0.2, 0.8)
	else:
		fill_col = Color(0.0, 0.47, 0.63, 0.2 + pulse * 0.15)
		line_col = Color(0.0, 0.75, 1.0, 0.7 + pulse * 0.3)

	draw_polygon(pts, PackedColorArray([fill_col]))
	for i in range(pts.size()):
		draw_line(pts[i], pts[(i + 1) % pts.size()], line_col, 2.0)

	# Inner dot
	var dot_col := Color(0.0, 0.75, 1.0, 0.6) if not is_captured else Color(1.0, 0.2, 0.2, 0.5)
	draw_circle(center, r * 0.18, dot_col)

	# Ability cooldown sweep — outer arc ring, fills clockwise from top
	if _ability_fraction < 1.0:
		var arc_r: float = r + 5.0
		var sweep: float = TAU * _ability_fraction
		var arc_col := Color(0.0, 0.75, 1.0, 0.7)
		draw_arc(center, arc_r, -PI * 0.5, -PI * 0.5 + sweep, 32, arc_col, 2.0)
		# Background track
		draw_arc(center, arc_r, -PI * 0.5 + sweep, -PI * 0.5 + TAU, 32, Color(0.2, 0.2, 0.3, 0.4), 2.0)
