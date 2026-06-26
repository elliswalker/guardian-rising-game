extends CharacterBody2D

# Cabal Incendiary Colossus — flamethrower pushes and burns front line.
# On death: fuel tank explodes, cabal ship flees.
# TODO: flamethrower AoE pushback + burn DoT on player/frames; ship departure animation.

const HP_MAX           := 24
const MOVE_SPEED       := 6.0
const FLAME_RANGE      := 55.0
const FLAME_INTERVAL   := 3.5
const FLAME_PUSH_FORCE := 80.0  # x-velocity applied to targets pushed left
const GRAVITY          := 225.0
const PATROL_LEFT_X    := 640.0
const PATROL_RIGHT_X   := 760.0

const COLOR_HEALTHY := Color(0.72, 0.35, 0.12, 1.0)
const COLOR_DAMAGED := Color(0.45, 0.20, 0.06, 1.0)

@onready var _sprite:  ColorRect = $ColossusSprite
@onready var _flame:   ColorRect = $FlameSprite

var _hp: int = HP_MAX
var _is_dying: bool = false
var _flame_timer: float = FLAME_INTERVAL * 0.5
var _patrol_dir: float = -1.0

func _ready() -> void:
	add_to_group("enemies")
	add_to_group("bosses")
	collision_layer = 32
	collision_mask = 1  # walks on ground

func _physics_process(delta: float) -> void:
	if _is_dying:
		return
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	velocity.x = _patrol_dir * MOVE_SPEED
	if global_position.x <= PATROL_LEFT_X:
		_patrol_dir = 1.0
	elif global_position.x >= PATROL_RIGHT_X:
		_patrol_dir = -1.0
	move_and_slide()
	_flame_timer -= delta
	if _flame_timer <= 0.0:
		_flame_timer = FLAME_INTERVAL
		_fire_flamethrower()

func _fire_flamethrower() -> void:
	# TODO: push all player/frame_npc nodes within FLAME_RANGE left by FLAME_PUSH_FORCE
	# and apply a burn DoT (apply_burn(damage, duration) method on targets)
	_flame.modulate.a = 0.9
	var tween: Tween = create_tween()
	tween.tween_property(_flame, "modulate:a", 0.0, 0.6)

func take_damage(amount: int) -> void:
	if _is_dying:
		return
	_hp = maxi(_hp - amount, 0)
	_sprite.color = COLOR_HEALTHY.lerp(COLOR_DAMAGED, 1.0 - float(_hp) / float(HP_MAX))
	if _hp <= 0:
		_die()

func _die() -> void:
	_is_dying = true
	set_physics_process(false)
	for portal: Node in get_tree().get_nodes_in_group("portals"):
		if portal.has_method("break_portal"):
			portal.call("break_portal")
	# TODO: explosion visual + cabal ship departure
	var tween: Tween = create_tween()
	tween.tween_property(_sprite, "modulate:a", 0.0, 2.0)
	tween.chain().tween_callback(queue_free)
