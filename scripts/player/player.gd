extends CharacterBody2D

const SPARROW_SPEED := 55.0
const RUN_SPEED := 38.0
const WALK_SPEED := 20.0
const LIMP_SPEED := 10.0
const GRAVITY := 225.0
const DOUBLE_TAP_WINDOW := 0.3

@onready var sparrow_sprite: CanvasItem = $SparrowSprite
@onready var guardian_sprite: CanvasItem = $GuardianSprite

var has_ghost := true
var is_hurt := false
var _is_running: bool = false
var _last_tap_dir: float = 0.0
var _last_tap_time: float = -1.0

var _speed: float:
	get:
		if has_ghost:
			return SPARROW_SPEED
		if is_hurt:
			return LIMP_SPEED
		if _is_running:
			return RUN_SPEED
		return WALK_SPEED

var _ghost: Node2D = null

func _ready() -> void:
	add_to_group("player")
	collision_layer = 8  # bit 3 — not seen by guardians (mask=1) or enemies (mask=3)
	collision_mask = 1   # still detects ground on layer 1
	GameState.ghost_captured.connect(_on_ghost_captured)
	GameState.ghost_released.connect(_on_ghost_released)
	call_deferred("_link_ghost")

func _link_ghost() -> void:
	_ghost = get_tree().get_first_node_in_group("ghost") as Node2D

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	_check_double_tap()
	var direction := Input.get_axis("move_left", "move_right")
	if direction == 0.0:
		_is_running = false
	velocity.x = direction * _speed if direction else move_toward(velocity.x, 0, _speed)

	move_and_slide()
	_update_facing(direction)

func _check_double_tap() -> void:
	var tap_dir: float = 0.0
	if Input.is_action_just_pressed("move_right"):
		tap_dir = 1.0
	elif Input.is_action_just_pressed("move_left"):
		tap_dir = -1.0
	if tap_dir == 0.0:
		return
	var now: float = Time.get_ticks_msec() / 1000.0
	if tap_dir == _last_tap_dir and (now - _last_tap_time) < DOUBLE_TAP_WINDOW:
		_is_running = true
	else:
		_is_running = false
	_last_tap_dir = tap_dir
	_last_tap_time = now

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ability") and _ghost and is_instance_valid(_ghost):
		_ghost.call("use_ability")

func _update_facing(direction: float) -> void:
	if direction != 0:
		scale.x = sign(direction)

func _on_ghost_captured() -> void:
	has_ghost = false
	_is_running = false
	if sparrow_sprite:
		sparrow_sprite.visible = false

func _on_ghost_released() -> void:
	has_ghost = true
	if sparrow_sprite:
		sparrow_sprite.visible = true
