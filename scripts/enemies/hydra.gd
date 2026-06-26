extends CharacterBody2D

# Vex Hydra — rotating shield makes damage cycle longer; crashes on death, breaks Vex portal.

const HP_MAX          := 18
const MOVE_SPEED      := 4.0
const SHIELD_CYCLE    := 6.0   # total seconds per shield cycle
const SHIELD_ON_TIME  := 4.5   # shielded portion of the cycle
const HOVER_AMPLITUDE := 5.0
const HOVER_SPEED     := 1.1
const PATROL_LEFT_X   := 650.0
const PATROL_RIGHT_X  := 750.0

const COLOR_HEALTHY      := Color.WHITE
const COLOR_DAMAGED      := Color(1.0, 0.5, 0.5, 1.0)
const COLOR_SHIELD_ON    := Color(0.45, 0.90, 0.70, 0.55)
const COLOR_SHIELD_OFF   := Color(0.45, 0.90, 0.70, 0.0)

@onready var _sprite:  CanvasItem = $HydraSprite
@onready var _shield:  ColorRect = $ShieldSprite
@onready var _glow:    ColorRect = $Glow

var _hp: int = HP_MAX
var _is_dying: bool = false
var _shield_timer: float = 0.0
var _shield_active: bool = true
var _hover_time: float = 0.0
var _patrol_dir: float = -1.0

func _ready() -> void:
	add_to_group("enemies")
	add_to_group("bosses")
	collision_layer = 32
	collision_mask = 0
	motion_mode = MOTION_MODE_FLOATING
	_shield_active = true
	_shield_timer = SHIELD_ON_TIME
	_update_visual()

func _physics_process(delta: float) -> void:
	if _is_dying:
		return
	_hover_time += delta
	velocity.x = _patrol_dir * MOVE_SPEED
	velocity.y = sin(_hover_time * HOVER_SPEED) * HOVER_AMPLITUDE * 2.0
	if global_position.x <= PATROL_LEFT_X:
		_patrol_dir = 1.0
	elif global_position.x >= PATROL_RIGHT_X:
		_patrol_dir = -1.0
	move_and_slide()
	_tick_shield(delta)

func _tick_shield(delta: float) -> void:
	_shield_timer -= delta
	if _shield_timer <= 0.0:
		_shield_active = not _shield_active
		_shield_timer = SHIELD_ON_TIME if _shield_active else (SHIELD_CYCLE - SHIELD_ON_TIME)
		_update_visual()

func take_damage(amount: int) -> void:
	if _is_dying or _shield_active:
		return
	_hp = maxi(_hp - amount, 0)
	_update_visual()
	if _hp <= 0:
		_die()

func _die() -> void:
	_is_dying = true
	set_physics_process(false)
	_crash_to_floor()

func _crash_to_floor() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(self, "global_position:y", 148.0, 0.35).set_ease(Tween.EASE_IN)
	tween.tween_callback(func() -> void:
		for portal: Node in get_tree().get_nodes_in_group("portals"):
			if portal.has_method("break_portal"):
				portal.call("break_portal")
		var collapse: Tween = create_tween()
		collapse.tween_property(_sprite, "modulate:a", 0.0, 2.0)
		collapse.tween_property(_glow,   "modulate:a", 0.0, 1.5)
		collapse.chain().tween_callback(queue_free)
	)

func _update_visual() -> void:
	var t: float = float(_hp) / float(HP_MAX)
	_sprite.modulate = Color.WHITE.lerp(COLOR_DAMAGED, 1.0 - t)
	_shield.color = COLOR_SHIELD_ON if _shield_active else COLOR_SHIELD_OFF
