extends Node2D

const PULSE_SPEED := 1.8

@onready var _outer: ColorRect = $Outer
@onready var _inner: ColorRect = $Inner
@onready var _base:  ColorRect = $Base

var _broken: bool = false
var _pulse_time: float = 0.0
var faction: String = "fallen"

func _ready() -> void:
	add_to_group("portals")

func _process(delta: float) -> void:
	if _broken:
		return
	_pulse_time += delta
	var pulse: float = 0.65 + sin(_pulse_time * PULSE_SPEED) * 0.35
	_inner.modulate.a = pulse
	_outer.modulate.a = pulse * 0.45

func break_portal() -> void:
	if _broken:
		return
	_broken = true
	GameState.portal_active = false
	GameState.portal_broken.emit(faction)
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(_outer, "modulate:a", 0.0, 1.8)
	tween.tween_property(_inner, "modulate:a", 0.0, 1.2)
	tween.tween_property(_base,  "color", Color(0.15, 0.15, 0.15, 0.6), 1.5)
	tween.chain().tween_callback(queue_free)
