extends Node2D

const PULSE_SPEED := 1.8

# Arch plating / energy field / ground scorch tints per faction
const FACTION_COLORS: Dictionary = {
	"fallen": [Color(0.42, 0.30, 0.60), Color(0.72, 0.50, 1.00), Color(0.28, 0.12, 0.55, 0.80)],
	"hive":   [Color(0.30, 0.42, 0.36), Color(0.45, 0.95, 0.60), Color(0.10, 0.32, 0.18, 0.80)],
	"vex":    [Color(0.48, 0.44, 0.36), Color(1.00, 0.92, 0.62), Color(0.42, 0.36, 0.20, 0.80)],
	"cabal":  [Color(0.50, 0.36, 0.28), Color(1.00, 0.60, 0.30), Color(0.45, 0.20, 0.10, 0.80)],
}

@onready var _outer: Sprite2D = $Outer
@onready var _inner: Sprite2D = $Inner
@onready var _base:  ColorRect = $Base

var _broken: bool = false
var _pulse_time: float = 0.0
var faction: String = "fallen"

func _ready() -> void:
	add_to_group("portals")
	var cols: Array = FACTION_COLORS.get(faction, FACTION_COLORS["fallen"])
	_outer.self_modulate = cols[0]
	_inner.self_modulate = cols[1]
	_base.color = cols[2]

func _process(delta: float) -> void:
	if _broken:
		return
	_pulse_time += delta
	var pulse: float = 0.65 + sin(_pulse_time * PULSE_SPEED) * 0.35
	# the arch stays solid; only the energy field breathes
	_inner.modulate.a = pulse

func break_portal() -> void:
	if _broken:
		return
	_broken = true
	# The level controller decides portal_active — dual-portal planets
	# only go quiet when ALL portals are down.
	GameState.portal_broken.emit(faction)
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(_outer, "modulate:a", 0.0, 1.8)
	tween.tween_property(_inner, "modulate:a", 0.0, 1.2)
	tween.tween_property(_base,  "color", Color(0.15, 0.15, 0.15, 0.6), 1.5)
	tween.chain().tween_callback(queue_free)
