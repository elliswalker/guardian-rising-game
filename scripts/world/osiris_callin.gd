extends Node2D

# Osiris call-in — Well of Radiance (EP-08, Mars shrine). The Warlock
# plants a burning well: enemies wading through it scorch over time.
# Kills shed Motes of Light.

const WELL_DURATION := 6.0
const WELL_RADIUS   := 70.0
const TICK_INTERVAL := 0.5
const TICK_DAMAGE   := 1

const PICKUP_SCENE := preload("res://scenes/world/pickup.tscn")

const COLOR_OSIRIS := Color(0.85, 0.75, 0.50, 1.0)
const COLOR_FLAME  := Color(1.0, 0.62, 0.10, 0.35)

var _life: float = WELL_DURATION
var _tick: float = 0.0
var _figure: ColorRect
var _well: ColorRect

func _ready() -> void:
	_figure = ColorRect.new()
	_figure.size = Vector2(8, 20)
	_figure.position = Vector2(-4, -20)
	_figure.color = COLOR_OSIRIS
	add_child(_figure)
	_well = ColorRect.new()
	_well.size = Vector2(WELL_RADIUS * 2.0, 6.0)
	_well.position = Vector2(-WELL_RADIUS, -4)
	_well.color = COLOR_FLAME
	add_child(_well)
	Sound.play("dusk", -4.0, 1.6)
	# Osiris plants the well and departs
	var tween: Tween = create_tween()
	tween.tween_interval(0.8)
	tween.tween_property(_figure, "modulate:a", 0.0, 0.5)

func _process(delta: float) -> void:
	_life -= delta
	_well.modulate.a = 0.6 + sin(Time.get_ticks_msec() / 90.0) * 0.4
	if _life <= 1.2:
		_well.modulate.a *= _life / 1.2  # gutters out
	if _life <= 0.0:
		queue_free()
		return
	_tick -= delta
	if _tick > 0.0:
		return
	_tick = TICK_INTERVAL
	for enemy: Node in get_tree().get_nodes_in_group("enemies"):
		var en: Node2D = enemy as Node2D
		if not en or not is_instance_valid(en):
			continue
		if absf(en.global_position.x - global_position.x) > WELL_RADIUS:
			continue
		var pos: Vector2 = en.global_position
		if en.has_method("take_damage"):
			en.take_damage(TICK_DAMAGE)
		if not is_instance_valid(en):  # scorched to death — shed a mote
			var mote: Area2D = PICKUP_SCENE.instantiate() as Area2D
			mote.set("kind", "mote")
			mote.global_position = Vector2(pos.x, 145.0)
			get_parent().call_deferred("add_child", mote)
