extends CharacterBody2D

# Vex Minotaur — heavy assault unit. Slow, high HP, deals double melee damage.
# Teleports past the first wall it reaches (Void teleport from Destiny lore).

const MOVE_SPEED         := 9.0
const GRAVITY            := 225.0
const HP_MAX             := 6
const WALL_ATTACK_CD     := 3.0
const FRAME_ATTACK_RANGE := 20.0
const GLIMMER_DROP       := 12
const RETREAT_SPEED      := 18.0
const RETREAT_EXIT_X     := 900.0
const TELEPORT_OFFSET    := -40.0   # teleports this far left past the wall

const COLOR_DEFAULT := Color.WHITE
const COLOR_HIT     := Color(1.0, 0.85, 0.25, 1.0)
const COLOR_DAMAGED := Color(1.0, 0.5, 0.5, 1.0)

@onready var _sprite: Sprite2D = $MinotaurSprite

# 2-frame walk cycle (#46)
const TEX_STAND := preload("res://assets/sprites/enemies/vex/minotaur_right.png")
const TEX_WALK  := TEX_STAND  # same texture until the animation sheets (#49 phase F)
const WALK_FRAME_TIME := 0.24
var _walk_t: float = 0.0

func _animate_walk(delta: float) -> void:
	if not _sprite:
		return
	if absf(velocity.x) < 2.0:
		_walk_t = 0.0
		_sprite.texture = TEX_STAND
		return
	_sprite.flip_h = velocity.x < 0.0  # Pro art faces right
	_walk_t += delta
	_sprite.texture = TEX_WALK if fmod(_walk_t, WALK_FRAME_TIME * 2.0) >= WALK_FRAME_TIME else TEX_STAND

var _hp: int = HP_MAX
var _is_dying: bool = false
var _teleported: bool = false
var _wall_attack_timer: float = 0.0
var _frame_target: Node2D = null
var _retarget_timer: float = 0.0
var _retreating: bool = false
var _tether_timer: float = 0.0

func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 32
	collision_mask = 7   # ground + walls + towers
	_wall_attack_timer = randf() * WALL_ATTACK_CD
	GameState.dawn_triggered.connect(_on_dawn_triggered)

func _on_dawn_triggered(_day: int) -> void:
	if not _is_dying:
		_retreating = true

func apply_tether(duration: float) -> void:
	_tether_timer = maxf(_tether_timer, duration)

func _physics_process(delta: float) -> void:
	_animate_walk(delta)
	if _tether_timer > 0.0:
		_tether_timer -= delta
	if _retreating:
		if not is_on_floor():
			velocity.y += GRAVITY * delta
		velocity.x = RETREAT_SPEED
		move_and_slide()
		if global_position.x > RETREAT_EXIT_X:
			queue_free()
		return
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	_retarget_timer -= delta
	if _retarget_timer <= 0.0:
		_retarget_timer = 0.3
		_frame_target = _find_nearest_frame()
	if _frame_target and is_instance_valid(_frame_target):
		var dist: float = global_position.distance_to(_frame_target.global_position)
		velocity.x = 0.0 if dist <= FRAME_ATTACK_RANGE else -MOVE_SPEED
	else:
		velocity.x = -MOVE_SPEED
	move_and_slide()
	_check_wall_teleport()
	_wall_attack_timer -= delta
	if _wall_attack_timer <= 0.0:
		_process_attacks()

func _check_wall_teleport() -> void:
	if _teleported:
		return
	for i in get_slide_collision_count():
		var col: KinematicCollision2D = get_slide_collision(i)
		var body := col.get_collider()
		if body is Node and (body as Node).is_in_group("walls"):
			_teleported = true
			global_position.x += TELEPORT_OFFSET
			return

func _process_attacks() -> void:
	_wall_attack_timer = WALL_ATTACK_CD
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
	var best_dist: float = 80.0
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
	if _is_dying or _tether_timer > 0.0:
		return
	_hp = maxi(_hp - amount, 0)
	if _hp <= 0:
		_die()
		return
	var damaged_color: Color = Color.WHITE.lerp(COLOR_DAMAGED, 1.0 - float(_hp) / float(HP_MAX))
	var tween: Tween = create_tween()
	tween.tween_property(_sprite, "modulate", COLOR_HIT, 0.06)
	tween.chain().tween_property(_sprite, "modulate", damaged_color, 0.15)

func _die() -> void:
	_is_dying = true
	set_physics_process(false)
	GameState.add_glimmer(GLIMMER_DROP)
	var tween: Tween = create_tween()
	tween.tween_property(_sprite, "modulate", COLOR_HIT, 0.08)
	tween.chain().tween_property(_sprite, "modulate:a", 0.0, 0.6)
	tween.chain().tween_callback(queue_free)
