extends Node2D

const MAX_RADIUS := 160.0
const DURATION   := 0.5

var _time: float = 0.0

func _process(delta: float) -> void:
	_time += delta
	queue_redraw()
	if _time >= DURATION:
		queue_free()

func _draw() -> void:
	var frac: float = _time / DURATION
	var radius: float = frac * MAX_RADIUS
	var alpha: float = (1.0 - frac) * 0.85
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 40, Color(0.0, 0.75, 1.0, alpha), 3.0)
	draw_arc(Vector2.ZERO, radius + 5.0, 0.0, TAU, 40, Color(0.5, 0.9, 1.0, alpha * 0.35), 7.0)
	# Flash fill at the start
	if frac < 0.2:
		var fill_alpha: float = (1.0 - frac / 0.2) * 0.18
		draw_circle(Vector2.ZERO, radius, Color(0.0, 0.75, 1.0, fill_alpha))
