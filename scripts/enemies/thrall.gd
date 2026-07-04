extends CharacterBody2D

# Hive Thrall — fast, fragile melee. Rushes walls and frames.
# Lowest HP and highest speed of any Hive unit. No ghost targeting.

const MOVE_SPEED          := 26.0
const GRAVITY             := 225.0
const GLIMMER_DROP        := 4
const FRAME_DETECT_RANGE  := 65.0
const FRAME_ATTACK_RANGE  := 14.0
const WALL_ATTACK_COOLDOWN := 1.8
const RETREAT_SPEED       := 32.0
const RETREAT_EXIT_X      := 850.0

const COLOR_DEFAULT := Color.WHITE
const COLOR_HIT     := Color(0.5, 1.0, 0.6, 1.0)

@onready var _sprite: CanvasItem = $ThrallSprite

# Set false before add_child for a lull-wanderer (Moon ambience): shuffles
# in the dark, bolts when hit, turns feral when the surge warning sounds.
var _start_feral: bool = true
var wander_left: float = 250.0
var wander_right: float = 750.0

var _is_dying: bool = false
var _wall_attack_timer: float = 0.0
var _frame_target: Node2D = null
var _retreating: bool = false
var _wandering: bool = false
var _wander_dir: float = 1.0
var _wander_timer: float = 0.0

func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 32
	collision_mask = 7
	_wall_attack_timer = randf() * WALL_ATTACK_COOLDOWN
	if not _start_feral:
		_wandering = true
		_wander_dir = [-1.0, 1.0][randi() % 2]
		_wander_timer = randf_range(1.2, 3.5)
	GameState.dusk_triggered.connect(func(_d: int) -> void:
		_wandering = false)
	GameState.dawn_triggered.connect(func(_d: int) -> void:
		if not _is_dying: _retreating = true
	)

func retreat() -> void:
	if not _is_dying:
		_retreating = true

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	if _retreating:
		velocity.x = RETREAT_SPEED
		move_and_slide()
		if global_position.x > RETREAT_EXIT_X:
			queue_free()
		return
	if _wandering:
		_wander_timer -= delta
		if _wander_timer <= 0.0:
			_wander_timer = randf_range(1.2, 3.5)
			_wander_dir = [-1.0, 1.0][randi() % 2]
		if global_position.x <= wander_left and _wander_dir < 0.0:
			_wander_dir = 1.0
		elif global_position.x >= wander_right and _wander_dir > 0.0:
			_wander_dir = -1.0
		velocity.x = _wander_dir * 5.0
		move_and_slide()
		return
	_frame_target = _find_nearest_frame()
	if _frame_target and is_instance_valid(_frame_target):
		var dist := global_position.distance_to(_frame_target.global_position)
		var dir: float = sign(_frame_target.global_position.x - global_position.x)
		velocity.x = 0.0 if dist <= FRAME_ATTACK_RANGE else dir * MOVE_SPEED
	else:
		velocity.x = -MOVE_SPEED
	move_and_slide()
	_wall_attack_timer -= delta
	if _wall_attack_timer <= 0.0:
		_process_attacks()

func _process_attacks() -> void:
	_wall_attack_timer = WALL_ATTACK_COOLDOWN
	if _frame_target and is_instance_valid(_frame_target):
		if global_position.distance_to(_frame_target.global_position) < FRAME_ATTACK_RANGE:
			if _frame_target.has_method("take_worker_hit"):
				_frame_target.take_worker_hit()
			elif _frame_target.has_method("knocked_dormant"):
				_frame_target.knocked_dormant()
			_frame_target = null
			return
	for i in get_slide_collision_count():
		var col: KinematicCollision2D = get_slide_collision(i)
		var body := col.get_collider()
		if body is Node:
			var n: Node = body as Node
			if (n.is_in_group("walls") or n.is_in_group("towers")) and n.has_method("take_damage"):
				n.take_damage(1)
				return

func _find_nearest_frame() -> Node2D:
	var best: Node2D = null
	var best_dist: float = FRAME_DETECT_RANGE
	for f: Node in get_tree().get_nodes_in_group("frame_npc"):
		var fn: Node2D = f as Node2D
		if not fn or not is_instance_valid(fn):
			continue
		if not fn.has_method("is_active_worker") or not fn.call("is_active_worker"):
			continue
		var dist: float = global_position.distance_to(fn.global_position)
		if dist < best_dist:
			best_dist = dist
			best = fn
	return best

func take_damage(_amount: int) -> void:
	if _is_dying:
		return
	_die()

func _die() -> void:
	_is_dying = true
	set_physics_process(false)
	GameState.add_glimmer(GLIMMER_DROP)
	var tween := create_tween()
	tween.tween_property(_sprite, "modulate", COLOR_HIT, 0.0)
	tween.tween_property(_sprite, "modulate:a", 0.0, 0.25)
	tween.tween_callback(queue_free)
