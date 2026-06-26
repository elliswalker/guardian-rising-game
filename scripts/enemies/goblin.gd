extends CharacterBody2D

# Vex Goblin — basic Vex infantry. Faster than a Dreg.
# Day: wanders the field in pairs. On hit: stops and tracks, then resumes (no flee).
# Night (feral): rushes walls. Dawn: retreats right.

enum GoblinState {
	WANDERING,
	HIT_STOP,    # brief pause after being hit during day
	FERAL,
	RETREATING,
}

const MOVE_SPEED             := 18.0
const WANDER_SPEED           := 7.0
const WANDER_LEFT_BOUND      := 350.0
const WANDER_RIGHT_BOUND     := 780.0
const GRAVITY                := 225.0
const GLIMMER_DROP           := 6
const FRAME_DETECT_RANGE     := 55.0
const FRAME_ATTACK_RANGE     := 16.0
const WALL_ATTACK_COOLDOWN   := 2.2
const RETARGET_INTERVAL      := 0.22
const SAFE_ZONE_X            := -50.0
const RETREAT_SPEED          := 26.0
const RETREAT_EXIT_X         := 900.0
const WANDER_DIR_CHANGE_MIN  := 2.5
const WANDER_DIR_CHANGE_MAX  := 5.0
const HIT_STOP_DURATION      := 0.6

const COLOR_DEFAULT  := Color.WHITE
const COLOR_HIT      := Color(1.0,  0.90, 0.30, 1.0)
const COLOR_TETHERED := Color(0.55, 0.55, 0.70, 1.0)

@onready var _sprite: CanvasItem = $GoblinSprite

var _goblin_state: GoblinState = GoblinState.FERAL
var _start_feral: bool = true   # set false before add_child for day wanderers
var _frame_target: Node2D = null
var _is_dying: bool = false
var _wall_attack_timer: float = 0.0
var _retarget_timer: float = 0.0
var _tether_timer: float = 0.0
var _wander_dir: float = 1.0
var _wander_dir_timer: float = 0.0
var _hit_stop_timer: float = 0.0

func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 32
	collision_mask = 7
	if _start_feral:
		_goblin_state = GoblinState.FERAL
	else:
		_goblin_state = GoblinState.WANDERING
		_wander_dir = [-1.0, 1.0][randi() % 2]
		_wander_dir_timer = randf_range(WANDER_DIR_CHANGE_MIN, WANDER_DIR_CHANGE_MAX)
	_wall_attack_timer = randf() * WALL_ATTACK_COOLDOWN
	GameState.dusk_triggered.connect(_on_dusk_triggered)
	GameState.dawn_triggered.connect(_on_dawn_triggered)

func _on_dusk_triggered(_day: int) -> void:
	if _goblin_state == GoblinState.WANDERING or _goblin_state == GoblinState.HIT_STOP:
		_goblin_state = GoblinState.FERAL

func _on_dawn_triggered(_day: int) -> void:
	if not _is_dying:
		retreat()

func retreat() -> void:
	if _is_dying:
		return
	_goblin_state = GoblinState.RETREATING

func apply_tether(duration: float) -> void:
	_tether_timer = maxf(_tether_timer, duration)

func _physics_process(delta: float) -> void:
	if _tether_timer > 0.0:
		_tether_timer -= delta
		velocity.x = 0.0
		if not is_on_floor():
			velocity.y += GRAVITY * delta
		move_and_slide()
		return

	match _goblin_state:
		GoblinState.WANDERING:   _do_wander(delta)
		GoblinState.HIT_STOP:    _do_hit_stop(delta)
		GoblinState.FERAL:       _do_feral(delta)
		GoblinState.RETREATING:  _do_retreat(delta)

func _do_wander(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	_wander_dir_timer -= delta
	if _wander_dir_timer <= 0.0:
		_wander_dir_timer = randf_range(WANDER_DIR_CHANGE_MIN, WANDER_DIR_CHANGE_MAX)
		_wander_dir = -_wander_dir
	if global_position.x < WANDER_LEFT_BOUND:
		_wander_dir = 1.0
	elif global_position.x > WANDER_RIGHT_BOUND:
		_wander_dir = -1.0
	velocity.x = _wander_dir * WANDER_SPEED
	move_and_slide()

func _do_hit_stop(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	velocity.x = 0.0
	_hit_stop_timer -= delta
	if _hit_stop_timer <= 0.0:
		_goblin_state = GoblinState.WANDERING
	move_and_slide()

func _do_feral(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	_retarget_timer -= delta
	if _retarget_timer <= 0.0:
		_retarget_timer = RETARGET_INTERVAL
		_frame_target = _find_nearest_working_frame()
	if _frame_target and is_instance_valid(_frame_target):
		var dist: float = global_position.distance_to(_frame_target.global_position)
		var dir: float = sign(_frame_target.global_position.x - global_position.x)
		velocity.x = 0.0 if dist <= FRAME_ATTACK_RANGE else dir * MOVE_SPEED
	else:
		velocity.x = -MOVE_SPEED
	move_and_slide()
	_wall_attack_timer -= delta
	if _wall_attack_timer <= 0.0:
		_process_attacks()

func _do_retreat(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	velocity.x = RETREAT_SPEED
	move_and_slide()
	if global_position.x > RETREAT_EXIT_X:
		queue_free()

func _process_attacks() -> void:
	_wall_attack_timer = WALL_ATTACK_COOLDOWN
	if _frame_target and is_instance_valid(_frame_target):
		if global_position.distance_to(_frame_target.global_position) < FRAME_ATTACK_RANGE:
			if _frame_target.has_method("knocked_dormant"):
				_frame_target.knocked_dormant()
			_frame_target = null
			return
	for i in get_slide_collision_count():
		var col: KinematicCollision2D = get_slide_collision(i)
		var collider := col.get_collider()
		if collider is Node:
			var n: Node = collider as Node
			if n.is_in_group("walls") or n.is_in_group("towers"):
				if n.has_method("take_damage"):
					n.take_damage(1)
				return

func _find_nearest_working_frame() -> Node2D:
	var best: Node2D = null
	var best_dist: float = FRAME_DETECT_RANGE
	for f: Node in get_tree().get_nodes_in_group("frame_npc"):
		var fn: Node2D = f as Node2D
		if not fn or not is_instance_valid(fn):
			continue
		if not fn.has_method("is_active_worker") or not fn.call("is_active_worker"):
			continue
		if fn.global_position.x < SAFE_ZONE_X:
			continue
		var dist: float = global_position.distance_to(fn.global_position)
		if dist < best_dist:
			best_dist = dist
			best = fn
	return best

func take_damage(_amount: int) -> void:
	if _is_dying or _tether_timer > 0.0:
		return
	if _goblin_state == GoblinState.WANDERING or _goblin_state == GoblinState.HIT_STOP:
		# Day: pause and track the threat — don't die
		_goblin_state = GoblinState.HIT_STOP
		_hit_stop_timer = HIT_STOP_DURATION
		return
	_is_dying = true
	set_physics_process(false)
	var tween: Tween = create_tween()
	tween.tween_property(_sprite, "modulate", COLOR_HIT, 0.0)
	tween.tween_property(_sprite, "modulate", COLOR_DEFAULT, 0.12)
	tween.tween_callback(func() -> void:
		GameState.add_glimmer(GLIMMER_DROP)
		queue_free()
	)
