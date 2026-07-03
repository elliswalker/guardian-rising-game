extends CharacterBody2D

const SPARROW_SPEED := 55.0
const RUN_SPEED := 38.0
const WALK_SPEED := 20.0
const LIMP_SPEED := 10.0
const GRAVITY := 225.0
const DOUBLE_TAP_WINDOW := 0.3

# Glimmer as Armor — hits shed glimmer as shards instead of wounding
const HIT_INVULN := 1.0
const KNOCK_FRACTION := 0.10
const KNOCK_MIN := 10
const KNOCK_MAX := 50
const SHARD_GROUND_Y := 144.0
const CACHE_SCENE := preload("res://scenes/world/glimmer_cache.tscn")

@onready var sparrow_sprite: CanvasItem = $SparrowSprite
@onready var guardian_sprite: CanvasItem = $GuardianSprite

var has_ghost := true
var is_hurt := false
var _is_running: bool = false
var _last_tap_dir: float = 0.0
var _last_tap_time: float = -1.0
var _invuln_timer: float = 0.0

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
	if _invuln_timer > 0.0:
		_invuln_timer -= delta
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

# Glimmer as Armor: an enemy swipe knocks glimmer off as shard pickups.
# Returns true if glimmer was shed (attacker uses this to know the hit landed).
func take_hit() -> bool:
	if _invuln_timer > 0.0 or GameState.glimmer <= 0:
		return false
	var knock: int = clampi(int(GameState.glimmer * KNOCK_FRACTION), KNOCK_MIN, KNOCK_MAX)
	knock = mini(knock, GameState.glimmer)
	GameState.glimmer -= knock
	_invuln_timer = HIT_INVULN
	_spawn_shards(knock)
	_flash_hit()
	return true

func _spawn_shards(total: int) -> void:
	var count: int = clampi(ceili(float(total) / 10.0), 2, 5)
	var base: int = total / count
	var remainder: int = total - base * count
	for i in count:
		var shard: Area2D = CACHE_SCENE.instantiate() as Area2D
		shard.set("glimmer_amount", base + (remainder if i == 0 else 0))
		shard.set("despawn_after", 20.0)
		shard.global_position = Vector2(
			global_position.x + randf_range(-28.0, 28.0), SHARD_GROUND_Y)
		get_parent().add_child(shard)

func _flash_hit() -> void:
	if not guardian_sprite:
		return
	var tween: Tween = create_tween()
	tween.tween_property(guardian_sprite, "modulate", Color(1.0, 0.3, 0.2, 1.0), 0.05)
	tween.tween_property(guardian_sprite, "modulate", Color.WHITE, 0.3)

func _on_ghost_captured() -> void:
	has_ghost = false
	_is_running = false
	if sparrow_sprite:
		sparrow_sprite.visible = false

func _on_ghost_released() -> void:
	has_ghost = true
	if sparrow_sprite:
		sparrow_sprite.visible = true
