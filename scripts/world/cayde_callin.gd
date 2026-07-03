extends Node2D

# Cayde-6 call-in — Golden Gun (EP-08). The Speaker doesn't fight; Cayde
# steps out of the light, fires three shots, tips his hat, and is gone.
# Each shot kills a small enemy outright and drops a Mote of Light.

const SHOT_DAMAGE   := 3
const SHOT_INTERVAL := 0.45
const MAX_SHOTS     := 3
const RANGE         := 220.0

const PICKUP_SCENE := preload("res://scenes/world/pickup.tscn")

const COLOR_CAYDE  := Color(0.85, 0.70, 0.45, 1.0)
const COLOR_FLAME  := Color(1.0, 0.62, 0.10, 1.0)

var _shots_left: int = MAX_SHOTS
var _timer: float = 0.4
var _body: ColorRect
var _flame: ColorRect

func _ready() -> void:
	_body = ColorRect.new()
	_body.size = Vector2(8, 18)
	_body.position = Vector2(-4, -18)
	_body.color = COLOR_CAYDE
	add_child(_body)
	_flame = ColorRect.new()
	_flame.size = Vector2(4, 4)
	_flame.position = Vector2(-2, -24)
	_flame.color = COLOR_FLAME
	add_child(_flame)
	modulate.a = 0.0
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.25)

func _process(delta: float) -> void:
	_flame.modulate.a = 0.6 + sin(Time.get_ticks_msec() / 80.0) * 0.4
	_timer -= delta
	if _timer > 0.0:
		return
	if _shots_left <= 0:
		_depart()
		return
	_timer = SHOT_INTERVAL
	_shots_left -= 1
	_fire()

func _fire() -> void:
	var target: Node2D = _nearest_enemy()
	if not target:
		return
	_draw_tracer(target.global_position)
	var pos: Vector2 = target.global_position
	if target.has_method("take_damage"):
		target.take_damage(SHOT_DAMAGE)
	# every Golden Gun hit sheds a Mote of Light
	var mote: Area2D = PICKUP_SCENE.instantiate() as Area2D
	mote.set("kind", "mote")
	mote.global_position = Vector2(pos.x, 145.0)
	get_parent().call_deferred("add_child", mote)

func _nearest_enemy() -> Node2D:
	var nearest: Node2D = null
	var nearest_dist: float = RANGE
	for enemy: Node in get_tree().get_nodes_in_group("enemies"):
		var en: Node2D = enemy as Node2D
		if en and is_instance_valid(en):
			var dist: float = global_position.distance_to(en.global_position)
			if dist < nearest_dist:
				nearest_dist = dist
				nearest = en
	return nearest

func _draw_tracer(to: Vector2) -> void:
	var tracer: Line2D = Line2D.new()
	tracer.width = 1.5
	tracer.default_color = COLOR_FLAME
	tracer.add_point(Vector2(0, -14))
	tracer.add_point(to_local(to))
	add_child(tracer)
	var tween: Tween = tracer.create_tween()
	tween.tween_property(tracer, "modulate:a", 0.0, 0.2)
	tween.tween_callback(tracer.queue_free)

func _depart() -> void:
	set_process(false)
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.4)
	tween.tween_callback(queue_free)
