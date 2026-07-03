extends CharacterBody2D

# Hive Wizard — blight field slows player and NPCs in range.
# Killing the Wizard collapses the soul lantern, ending Hive spawning.
# TODO: blight slow applied to player/frames; lantern explosion visual on death.

const HP_MAX       := 16
const MOVE_SPEED   := 7.0
const BLIGHT_RANGE := 70.0
const BLIGHT_SLOW  := 0.45  # multiplier applied to speed while in blight
const BLIGHT_PULSE := 2.5   # seconds between blight pulses
const HOVER_SPEED  := 0.9
const HOVER_AMPLITUDE := 9.0
const PATROL_LEFT_X := 640.0
const PATROL_RIGHT_X := 750.0

const COLOR_HEALTHY := Color.WHITE
const COLOR_DAMAGED := Color(1.0, 0.5, 0.5, 1.0)

@onready var _sprite:  CanvasItem = $WizardSprite
@onready var _blight:  ColorRect = $BlightZone

var _hp: int = HP_MAX
var _is_dying: bool = false
var _blight_timer: float = 0.0
var _hover_time: float = 0.0
var _patrol_dir: float = -1.0

func _ready() -> void:
	add_to_group("enemies")
	add_to_group("bosses")
	collision_layer = 32
	collision_mask = 0
	motion_mode = MOTION_MODE_FLOATING

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
	_blight_timer -= delta
	if _blight_timer <= 0.0:
		_blight_timer = BLIGHT_PULSE
		_apply_blight()

func _apply_blight() -> void:
	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player and global_position.distance_to(player.global_position) < BLIGHT_RANGE:
		if player.has_method("apply_blight"):
			player.call("apply_blight", BLIGHT_PULSE + 0.5)

func take_damage(amount: int) -> void:
	if _is_dying:
		return
	_hp = maxi(_hp - amount, 0)
	_sprite.modulate = Color.WHITE.lerp(COLOR_DAMAGED, 1.0 - float(_hp) / float(HP_MAX))
	if _hp <= 0:
		_die()

func _die() -> void:
	_is_dying = true
	set_physics_process(false)
	for portal: Node in get_tree().get_nodes_in_group("portals"):
		if portal.has_method("break_portal"):
			portal.call("break_portal")
	# TODO: spawn lantern explosion visual
	var tween: Tween = create_tween()
	tween.tween_property(_sprite, "modulate:a", 0.0, 2.0)
	tween.chain().tween_callback(queue_free)
