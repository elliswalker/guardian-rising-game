extends CharacterBody2D

# Cabal Legionary — slow, high HP. Deals double melee damage to walls.

const MOVE_SPEED          := 10.0
const GRAVITY             := 225.0
const GLIMMER_DROP        := 10
const FRAME_DETECT_RANGE  := 50.0
const FRAME_ATTACK_RANGE  := 20.0
const WALL_ATTACK_COOLDOWN := 2.8
const RETREAT_SPEED       := 18.0
const RETREAT_EXIT_X      := 850.0
const HP_MAX              := 3

const COLOR_DEFAULT := Color.WHITE
const COLOR_HIT     := Color(1.0, 0.6, 0.3, 1.0)
const COLOR_DAMAGED := Color(1.0, 0.5, 0.5, 1.0)

@onready var _sprite: CanvasItem = $LegionarySprite

var _hp: int = HP_MAX
var _is_dying: bool = false
var _wall_attack_timer: float = 0.0
var _frame_target: Node2D = null
var _retreating: bool = false

func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 32
	collision_mask = 7
	_wall_attack_timer = randf() * WALL_ATTACK_COOLDOWN
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
				n.take_damage(2)
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
	var damaged_color: Color = Color.WHITE.lerp(COLOR_DAMAGED, 1.0 - float(_hp) / float(HP_MAX))
	var tween := create_tween()
	tween.tween_property(_sprite, "modulate", COLOR_HIT, 0.0)
	tween.tween_property(_sprite, "modulate", damaged_color, 0.2)

func _die() -> void:
	_is_dying = true
	set_physics_process(false)
	GameState.add_glimmer(GLIMMER_DROP)
	var tween := create_tween()
	tween.tween_property(_sprite, "modulate", COLOR_HIT, 0.0)
	tween.tween_property(_sprite, "modulate:a", 0.0, 0.4)
	tween.tween_callback(queue_free)
