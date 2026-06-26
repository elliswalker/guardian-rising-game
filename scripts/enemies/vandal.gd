extends CharacterBody2D

# Fallen Vandal — faster and tougher than a Dreg. Feral only (no day wandering).
# On hit: stumbles briefly, then continues. Does not flee.

enum State { FERAL, HIT_STUN, RETREATING }

const MOVE_SPEED          := 20.0
const HIT_STUN_SPEED      := 5.0
const GRAVITY             := 225.0
const GLIMMER_DROP        := 8
const GHOST_AGGRO_RANGE   := 90.0
const GHOST_CAPTURE_RANGE := 13.0
const FRAME_DETECT_RANGE  := 55.0
const FRAME_ATTACK_RANGE  := 18.0
const WALL_ATTACK_COOLDOWN := 2.0
const RETREAT_SPEED       := 24.0
const RETREAT_EXIT_X      := 850.0
const HIT_STUN_DURATION   := 0.35
const HP_MAX              := 2

const COLOR_DEFAULT  := Color.WHITE
const COLOR_HIT      := Color(1.0, 0.25, 0.1, 1.0)

@onready var _sprite: CanvasItem = $VandalSprite

var _hp: int = HP_MAX
var _state: State = State.FERAL
var _ghost: Node2D = null
var _frame_target: Node2D = null
var _is_dying: bool = false
var _wall_attack_timer: float = 0.0
var _hit_stun_timer: float = 0.0

func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 32
	collision_mask = 7
	_wall_attack_timer = randf() * WALL_ATTACK_COOLDOWN
	_ghost = get_tree().get_first_node_in_group("ghost")
	GameState.dawn_triggered.connect(_on_dawn_triggered)

func _on_dawn_triggered(_day: int) -> void:
	if not _is_dying:
		retreat()

func retreat() -> void:
	if _is_dying or _state == State.RETREATING:
		return
	_state = State.RETREATING

func _physics_process(delta: float) -> void:
	match _state:
		State.FERAL:       _do_feral(delta)
		State.HIT_STUN:    _do_hit_stun(delta)
		State.RETREATING:  _do_retreat(delta)

func _do_feral(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	# Ghost capture takes priority
	if _ghost and is_instance_valid(_ghost) and not _ghost.is_captured:
		var to_ghost := _ghost.global_position - global_position
		if global_position.distance_to(_ghost.global_position) < GHOST_AGGRO_RANGE:
			if abs(to_ghost.x) < GHOST_CAPTURE_RANGE:
				_ghost.capture(self)
			else:
				velocity.x = sign(to_ghost.x) * MOVE_SPEED
			move_and_slide()
			return
	_frame_target = _find_nearest_frame()
	if _frame_target and is_instance_valid(_frame_target):
		var dist := global_position.distance_to(_frame_target.global_position)
		velocity.x = 0.0 if dist <= FRAME_ATTACK_RANGE else sign(_frame_target.global_position.x - global_position.x) * MOVE_SPEED
	else:
		velocity.x = -MOVE_SPEED
	move_and_slide()
	_wall_attack_timer -= delta
	if _wall_attack_timer <= 0.0:
		_process_attacks()

func _do_hit_stun(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	velocity.x = move_toward(velocity.x, 0.0, HIT_STUN_SPEED * delta * 10.0)
	move_and_slide()
	_hit_stun_timer -= delta
	if _hit_stun_timer <= 0.0:
		_state = State.FERAL

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

func take_damage(amount: int) -> void:
	if _is_dying:
		return
	_hp = maxi(_hp - amount, 0)
	if _hp <= 0:
		_die()
		return
	_state = State.HIT_STUN
	_hit_stun_timer = HIT_STUN_DURATION
	var tween := create_tween()
	tween.tween_property(_sprite, "modulate", COLOR_HIT, 0.0)
	tween.tween_property(_sprite, "modulate", COLOR_DEFAULT, 0.2)

func _die() -> void:
	_is_dying = true
	set_physics_process(false)
	if _ghost and is_instance_valid(_ghost) and _ghost.is_captured and _ghost.carrier == self:
		_ghost.release()
	GameState.add_glimmer(GLIMMER_DROP)
	var tween := create_tween()
	tween.tween_property(_sprite, "modulate", COLOR_HIT, 0.0)
	tween.tween_property(_sprite, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)
