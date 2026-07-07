extends CharacterBody2D

enum DregState {
	WANDERING,     # daytime — scavenging the field; flee when hit
	HIT_FLEE,      # briefly sprint right after being hit during day
	FERAL,         # night-wave mode — loot, swipe, rush walls
	CARRYING_GHOST,# has the ghost; escape right
	CARRYING_LOOT, # grabbed a glimmer shard/cache; escape right with it
	RETREATING,    # dawn — flee off screen right
}

const MOVE_SPEED          := 14.0
const WANDER_SPEED        := 6.5
const HIT_FLEE_SPEED      := 28.0
const HIT_FLEE_DURATION   := 3.0
const GRAVITY             := 225.0
const GLIMMER_DROP        := 5
const GHOST_AGGRO_RANGE   := 80.0
const GHOST_CAPTURE_RANGE := 13.0
const FRAME_DETECT_RANGE  := 50.0
const FRAME_ATTACK_RANGE  := 18.0
const WALL_ATTACK_COOLDOWN := 2.5
const RETREAT_SPEED       := 22.0
const RETREAT_EXIT_X      := 850.0
const RETARGET_INTERVAL   := 0.25
# Glimmer as Armor
const LOOT_DETECT_RANGE   := 70.0
const LOOT_GRAB_RANGE     := 10.0
const PLAYER_DETECT_RANGE := 70.0
const PLAYER_ATTACK_RANGE := 16.0
const SWIPE_COOLDOWN      := 1.5
const GHOST_STRAY_DIST    := 40.0  # ghost farther than this from player = unprotected
const CACHE_SCENE         := preload("res://scenes/world/glimmer_cache.tscn")
const WANDER_CHANGE_INTERVAL_MIN := 1.8
const WANDER_CHANGE_INTERVAL_MAX := 4.5
const WANDER_LEFT_BOUND   := 290.0   # dregs won't cross this during day
const WANDER_RIGHT_BOUND  := 800.0
# Frames left of this x are inside the encampment — protected from enemies
const SAFE_ZONE_X         := -50.0

const COLOR_DEFAULT  := Color.WHITE
const COLOR_CARRYING := Color(0.7, 0.15, 0.8, 1)
const COLOR_LOOT     := Color(1.0, 0.85, 0.25, 1.0)
const COLOR_HIT      := Color(1.0, 0.15, 0.0, 1)
const COLOR_TETHERED := Color(0.70, 0.45, 1.0, 1.0)

@onready var _sprite: Sprite2D = $DregSprite

# PRO art (#49): faces RIGHT, static until the animation sheets land
# (phase F wires sprite_loader.gd). Both frames point at the Pro texture.
const TEX_STAND := preload("res://assets/sprites/enemies/fallen/dreg_right.png")
# real mid-stride frame (#50) — 2-frame Kingdom walk
const TEX_WALK  := preload("res://assets/sprites/enemies/fallen/dreg_walk_right.png")
const WALK_FRAME_TIME := 0.15
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

# Set to false before add_child to spawn as a daytime wanderer instead of a night attacker
var _start_feral: bool = true
# Direction of advance toward the base (-1 = spawned right marching left).
# Spawners on dual-front planets set these before add_child.
var march_dir: float = -1.0
var exit_x: float = 850.0
var wander_left: float = 290.0
var wander_right: float = 800.0

var _dreg_state: DregState = DregState.FERAL
var _ghost: Node2D = null
var _frame_target: Node2D = null
var _is_dying: bool = false
var _wall_attack_timer: float = 0.0
var _retarget_timer: float = 0.0
var _wander_dir: float = 1.0
var _wander_timer: float = 0.0
var _hit_flee_timer: float = 0.0
var _tether_timer: float = 0.0
var _loot_target: Node2D = null
var _loot_value: int = 0
var _swipe_timer: float = 0.0
var _player: Node2D = null

func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 32
	collision_mask = 7   # ground(1) + walls(2) + towers(4)
	_wall_attack_timer = randf() * WALL_ATTACK_COOLDOWN
	_ghost = get_tree().get_first_node_in_group("ghost")
	if _start_feral:
		_dreg_state = DregState.FERAL
		# chitter carries in from off-screen — the warning arrives before the enemy
		Sound.play("chitter", -8.0, randf_range(0.85, 1.15))
	else:
		_dreg_state = DregState.WANDERING
		_wander_dir = [-1.0, 1.0][randi() % 2]
		_wander_timer = randf_range(WANDER_CHANGE_INTERVAL_MIN, WANDER_CHANGE_INTERVAL_MAX)
	GameState.dusk_triggered.connect(_on_dusk_triggered)
	GameState.dawn_triggered.connect(_on_dawn_triggered)

func _on_dusk_triggered(_day: int) -> void:
	if _dreg_state == DregState.WANDERING or _dreg_state == DregState.HIT_FLEE:
		_dreg_state = DregState.FERAL

func _on_dawn_triggered(_day: int) -> void:
	retreat()

# Called by earth_highway at dawn
func retreat() -> void:
	if _is_dying or _dreg_state == DregState.RETREATING:
		return
	if _dreg_state == DregState.CARRYING_GHOST:
		if _ghost and is_instance_valid(_ghost) and _ghost.carrier == self:
			_ghost.release()
	_dreg_state = DregState.RETREATING
	_sprite.modulate =COLOR_DEFAULT

# Called by Servitor tether
func apply_tether(duration: float) -> void:
	_tether_timer = maxf(_tether_timer, duration)
	_sprite.modulate =COLOR_TETHERED

func _physics_process(delta: float) -> void:
	_animate_walk(delta)
	if _tether_timer > 0.0:
		_tether_timer -= delta
		if _tether_timer <= 0.0:
			_sprite.modulate =COLOR_DEFAULT
		velocity = Vector2.ZERO
		if not is_on_floor():
			velocity.y += GRAVITY * delta
		move_and_slide()
		return

	match _dreg_state:
		DregState.WANDERING:
			_process_wandering(delta)
		DregState.HIT_FLEE:
			_process_hit_flee(delta)
		DregState.FERAL:
			_process_feral(delta)
		DregState.CARRYING_GHOST:
			_process_carrying(delta)
		DregState.CARRYING_LOOT:
			_process_retreating(delta)
		DregState.RETREATING:
			_process_retreating(delta)

# ── Wandering (day) ───────────────────────────────────────────────────────────

func _process_wandering(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	_wander_timer -= delta
	if _wander_timer <= 0.0:
		_wander_timer = randf_range(WANDER_CHANGE_INTERVAL_MIN, WANDER_CHANGE_INTERVAL_MAX)
		_wander_dir = [-1.0, 1.0][randi() % 2]
	# Bounce off wander bounds
	if global_position.x <= wander_left and _wander_dir < 0.0:
		_wander_dir = 1.0
	elif global_position.x >= wander_right and _wander_dir > 0.0:
		_wander_dir = -1.0
	velocity.x = _wander_dir * WANDER_SPEED
	move_and_slide()

func _process_hit_flee(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	velocity.x = signf(exit_x - global_position.x) * HIT_FLEE_SPEED
	move_and_slide()
	_hit_flee_timer -= delta
	if _hit_flee_timer <= 0.0:
		_dreg_state = DregState.WANDERING
		_wander_dir = -1.0
		_wander_timer = randf_range(WANDER_CHANGE_INTERVAL_MIN, WANDER_CHANGE_INTERVAL_MAX)

# ── Feral (night attack) ──────────────────────────────────────────────────────

func _process_feral(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	_swipe_timer -= delta
	_retarget_timer -= delta
	if _retarget_timer <= 0.0:
		_retarget_timer = RETARGET_INTERVAL
		_evaluate_feral_targets()
	_execute_feral_movement()
	move_and_slide()
	_wall_attack_timer -= delta
	if _wall_attack_timer <= 0.0:
		_process_attacks()

func _get_player() -> Node2D:
	if not _player or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Node2D
	return _player

# A wealthy player shields a nearby ghost — hits knock glimmer loose instead.
# The ghost is takeable when the player is broke, or when it has strayed.
func _ghost_is_takeable() -> bool:
	if not _ghost or not is_instance_valid(_ghost) or _ghost.is_captured:
		return false
	if global_position.distance_to(_ghost.global_position) >= GHOST_AGGRO_RANGE:
		return false
	var player: Node2D = _get_player()
	if player and GameState.glimmer > 0 \
			and _ghost.global_position.distance_to(player.global_position) < GHOST_STRAY_DIST:
		return false
	return true

func _player_is_swipeable() -> bool:
	var player: Node2D = _get_player()
	return player != null and GameState.glimmer > 0 \
		and global_position.distance_to(player.global_position) < PLAYER_DETECT_RANGE

# Priority (Kingdom order): ground loot > exposed ghost > wealthy player > frames
func _evaluate_feral_targets() -> void:
	_frame_target = null
	_loot_target = _find_nearest_loot()
	if _loot_target:
		return
	if _ghost_is_takeable() or _player_is_swipeable():
		return
	_frame_target = _find_nearest_working_frame()

func _execute_feral_movement() -> void:
	# 1. Ground loot is irresistible
	if _loot_target and is_instance_valid(_loot_target):
		var to_loot: Vector2 = _loot_target.global_position - global_position
		if abs(to_loot.x) < LOOT_GRAB_RANGE:
			_grab_loot(_loot_target)
		else:
			velocity.x = sign(to_loot.x) * MOVE_SPEED
		return
	# 2. Exposed ghost
	if _ghost_is_takeable():
		var to_ghost: Vector2 = _ghost.global_position - global_position
		if abs(to_ghost.x) < GHOST_CAPTURE_RANGE and not _ghost.is_captured:
			_ghost.capture(self)
			_dreg_state = DregState.CARRYING_GHOST
			_sprite.modulate =COLOR_CARRYING
		else:
			velocity.x = sign(to_ghost.x) * MOVE_SPEED
		return
	# 3. Wealthy player — swipe glimmer off him
	if _player_is_swipeable():
		var player: Node2D = _get_player()
		var to_player: Vector2 = player.global_position - global_position
		if abs(to_player.x) <= PLAYER_ATTACK_RANGE:
			velocity.x = 0.0
			if _swipe_timer <= 0.0:
				_swipe_timer = SWIPE_COOLDOWN
				player.call("take_hit")
		else:
			velocity.x = sign(to_player.x) * MOVE_SPEED
		return
	# 4. Working frames
	if _frame_target and is_instance_valid(_frame_target):
		var dist: float = global_position.distance_to(_frame_target.global_position)
		var dir: float = sign(_frame_target.global_position.x - global_position.x)
		velocity.x = 0.0 if dist <= FRAME_ATTACK_RANGE else dir * MOVE_SPEED
		return
	velocity.x = march_dir * MOVE_SPEED

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
	_loot_target = null
	_dreg_state = DregState.CARRYING_LOOT
	_sprite.modulate =COLOR_LOOT

func _drop_loot() -> void:
	if _loot_value <= 0:
		return
	var shard: Area2D = CACHE_SCENE.instantiate() as Area2D
	shard.set("glimmer_amount", _loot_value)
	shard.set("despawn_after", 20.0)
	shard.global_position = Vector2(global_position.x, 144.0)
	get_parent().call_deferred("add_child", shard)
	_loot_value = 0

# ── Ghost carrier ─────────────────────────────────────────────────────────────

func _process_carrying(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	# Verify still holding ghost
	if not _ghost or not is_instance_valid(_ghost) or not _ghost.is_captured or _ghost.carrier != self:
		_dreg_state = DregState.FERAL
		_sprite.modulate =COLOR_DEFAULT
		return
	velocity.x = signf(exit_x - global_position.x) * RETREAT_SPEED
	move_and_slide()

# ── Retreating (dawn) ─────────────────────────────────────────────────────────

func _process_retreating(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	velocity.x = signf(exit_x - global_position.x) * RETREAT_SPEED
	move_and_slide()
	if absf(global_position.x - exit_x) < 12.0:
		queue_free()

# ── Attack resolution ─────────────────────────────────────────────────────────

func _process_attacks() -> void:
	if _frame_target and is_instance_valid(_frame_target):
		if global_position.distance_to(_frame_target.global_position) < FRAME_ATTACK_RANGE:
			if _frame_target.has_method("take_worker_hit"):
				_frame_target.take_worker_hit()
			elif _frame_target.has_method("knocked_dormant"):
				_frame_target.knocked_dormant()
			_frame_target = null
			_wall_attack_timer = WALL_ATTACK_COOLDOWN
			return
	for i in get_slide_collision_count():
		var col: KinematicCollision2D = get_slide_collision(i)
		var collider := col.get_collider()
		if collider is Node:
			var n: Node = collider as Node
			if n.is_in_group("walls") or n.is_in_group("towers"):
				if n.has_method("take_damage"):
					n.take_damage(1)
					_wall_attack_timer = WALL_ATTACK_COOLDOWN
				return

# ── Helpers ────────────────────────────────────────────────────────────────────

func _find_nearest_working_frame() -> Node2D:
	var best: Node2D = null
	var best_dist: float = FRAME_DETECT_RANGE
	for pass_num in 2:
		for f: Node in get_tree().get_nodes_in_group("frame_npc"):
			var fn: Node2D = f as Node2D
			if not fn or not is_instance_valid(fn):
				continue
			if not fn.has_method("is_active_worker") or not fn.call("is_active_worker"):
				continue
			if absf(fn.global_position.x - GameState.encampment_x) < 55.0:
				continue
			if pass_num == 0 and not fn.is_in_group("redjacks"):
				continue
			var dist: float = global_position.distance_to(fn.global_position)
			if dist < best_dist:
				best_dist = dist
				best = fn
		if best:
			break
	return best

func take_damage(_amount: int) -> void:
	if _is_dying or _tether_timer > 0.0:
		return
	# Day wanderers: flee instead of die
	if _dreg_state == DregState.WANDERING:
		_dreg_state = DregState.HIT_FLEE
		_hit_flee_timer = HIT_FLEE_DURATION
		_sprite.modulate =COLOR_HIT
		var tween: Tween = create_tween()
		tween.tween_property(_sprite, "modulate", COLOR_DEFAULT, 0.3)
		return
	_is_dying = true
	set_physics_process(false)
	var tween: Tween = create_tween()
	tween.tween_property(_sprite, "modulate", COLOR_HIT, 0.0)
	tween.tween_property(_sprite, "modulate", COLOR_DEFAULT, 0.12)
	tween.tween_callback(die)

func die() -> void:
	if _ghost and is_instance_valid(_ghost) and _ghost.carrier == self:
		_ghost.release()
	_drop_loot()  # stolen glimmer falls back to the ground, recoverable
	GameState.add_glimmer(GLIMMER_DROP)
	queue_free()
