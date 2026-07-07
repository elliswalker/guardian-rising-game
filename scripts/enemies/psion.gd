extends CharacterBody2D

# Cabal Psion — fast, fragile skirmisher. The Cabal's thief: swipes glimmer
# off the Speaker, grabs ground shards, and runs them back to the pods.

enum State { FERAL, CARRYING_LOOT, RETREATING }

const MOVE_SPEED          := 22.0
const GRAVITY             := 225.0
const GLIMMER_DROP        := 6
const FRAME_DETECT_RANGE  := 55.0
const FRAME_ATTACK_RANGE  := 16.0
const WALL_ATTACK_COOLDOWN := 2.2
const RETREAT_SPEED       := 26.0
# Glimmer as Armor
const LOOT_DETECT_RANGE   := 80.0
const LOOT_GRAB_RANGE     := 10.0
const PLAYER_DETECT_RANGE := 85.0
const PLAYER_ATTACK_RANGE := 16.0
const SWIPE_COOLDOWN      := 1.1
const CACHE_SCENE         := preload("res://scenes/world/glimmer_cache.tscn")

const COLOR_DEFAULT := Color.WHITE
const COLOR_HIT     := Color(0.85, 0.55, 1.0, 1.0)
const COLOR_LOOT    := Color(1.0, 0.85, 0.25, 1.0)

@onready var _sprite: Sprite2D = $PsionSprite

# 2-frame walk cycle (#46)
const TEX_STAND := preload("res://assets/sprites/enemies/cabal/psion_right.png")
# real mid-stride frame (#50) — 2-frame Kingdom walk
const TEX_WALK  := preload("res://assets/sprites/enemies/cabal/psion_walk_right.png")
const WALK_FRAME_TIME := 0.13
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

var march_dir: float = -1.0
var exit_x: float = 850.0
# Day scavenger (Mars ambience): only hunts ground loot — racing your
# sweeperbots for caches. No swiping, no frame attacks until dusk.
var day_scavenger: bool = false

var _state: State = State.FERAL
var _frame_target: Node2D = null
var _is_dying: bool = false
var _wall_attack_timer: float = 0.0
var _loot_value: int = 0
var _swipe_timer: float = 0.0
var _player: Node2D = null

func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 32
	collision_mask = 7
	_wall_attack_timer = randf() * WALL_ATTACK_COOLDOWN
	GameState.dusk_triggered.connect(func(_d: int) -> void:
		day_scavenger = false)  # the war resumes at dusk
	GameState.dawn_triggered.connect(func(_d: int) -> void:
		if not _is_dying:
			retreat())

func retreat() -> void:
	if _is_dying or _state == State.RETREATING:
		return
	_state = State.RETREATING

func _physics_process(delta: float) -> void:
	_animate_walk(delta)
	match _state:
		State.FERAL:         _do_feral(delta)
		State.CARRYING_LOOT: _do_retreat(delta)
		State.RETREATING:    _do_retreat(delta)

func _get_player() -> Node2D:
	if not _player or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Node2D
	return _player

func _do_feral(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	_swipe_timer -= delta
	# 1. Ground loot
	var loot: Node2D = _find_nearest_loot()
	if loot:
		var to_loot := loot.global_position - global_position
		if abs(to_loot.x) < LOOT_GRAB_RANGE:
			_grab_loot(loot)
		else:
			velocity.x = sign(to_loot.x) * MOVE_SPEED
		move_and_slide()
		return
	# Day scavengers only loot — no fighting until dusk
	if day_scavenger:
		velocity.x = (march_dir if int(Time.get_ticks_msec() / 2600.0) % 2 == 0 else -march_dir) * 6.0
		move_and_slide()
		return
	# 2. Wealthy player
	var player: Node2D = _get_player()
	if player and GameState.glimmer > 0 \
			and global_position.distance_to(player.global_position) < PLAYER_DETECT_RANGE:
		var to_player := player.global_position - global_position
		if abs(to_player.x) <= PLAYER_ATTACK_RANGE:
			velocity.x = 0.0
			if _swipe_timer <= 0.0:
				_swipe_timer = SWIPE_COOLDOWN
				player.call("take_hit")
		else:
			velocity.x = sign(to_player.x) * MOVE_SPEED
		move_and_slide()
		return
	# 3. Frames / march
	_frame_target = _find_nearest_frame()
	if _frame_target and is_instance_valid(_frame_target):
		var dist := global_position.distance_to(_frame_target.global_position)
		var dir: float = sign(_frame_target.global_position.x - global_position.x)
		velocity.x = 0.0 if dist <= FRAME_ATTACK_RANGE else dir * MOVE_SPEED
	else:
		velocity.x = march_dir * MOVE_SPEED
	move_and_slide()
	_wall_attack_timer -= delta
	if _wall_attack_timer <= 0.0:
		_process_attacks()

func _do_retreat(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	velocity.x = signf(exit_x - global_position.x) * RETREAT_SPEED
	move_and_slide()
	if absf(global_position.x - exit_x) < 12.0:
		queue_free()

func _find_nearest_loot() -> Node2D:
	var nearest: Node2D = null
	var nearest_dist: float = LOOT_DETECT_RANGE
	for cache: Node in get_tree().get_nodes_in_group("glimmer_caches"):
		var cn: Node2D = cache as Node2D
		if not cn or not is_instance_valid(cn):
			continue
		var dist: float = global_position.distance_to(cn.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = cn
	return nearest

func _grab_loot(loot: Node2D) -> void:
	_loot_value += int(loot.get("glimmer_amount"))
	loot.queue_free()
	_state = State.CARRYING_LOOT
	_sprite.modulate = COLOR_LOOT

func _drop_loot() -> void:
	if _loot_value <= 0:
		return
	var shard: Area2D = CACHE_SCENE.instantiate() as Area2D
	shard.set("glimmer_amount", _loot_value)
	shard.set("despawn_after", 20.0)
	shard.global_position = Vector2(global_position.x, 144.0)
	get_parent().call_deferred("add_child", shard)
	_loot_value = 0

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
	_drop_loot()  # stolen glimmer falls back, recoverable
	GameState.add_glimmer(GLIMMER_DROP)
	var tween := create_tween()
	tween.tween_property(_sprite, "modulate", COLOR_HIT, 0.0)
	tween.tween_property(_sprite, "modulate:a", 0.0, 0.25)
	tween.tween_callback(queue_free)
