extends CharacterBody2D

enum State {
	DORMANT,
	SEEKING_JOB_POST,    # walks to nearest job post after recruitment
	WAITING,             # at a job post, waiting for a job to be created
	PATROL,
	ENGAGE,
	REPOSITIONING,
	DEFENDING,
	SWEEPING,
	SEEKING_SITE,
	BUILDING,
	BUILDER_IDLE,        # wanders near encampment; auto-scans for repair work
	REPAIRING,           # moving to / hammering a broken wall (free, no player input)
	CHOPPING,            # walking to / chopping a tree for glimmer
	SEEKING_TOWER,       # walking to a tower to garrison it
	GARRISONED,          # stationed inside a tower; hidden, fires projectiles
	RETURNING_TO_SPAWN,  # knocked dormant — walking back to original position
	FLEEING,             # running toward encampment safe zone
	ASSAULTING,          # player ordered attack — march right, fight everything
}

const GRAVITY := 225.0
const TRAVEL_SPEED := 19.0
const PATROL_SPEED := 12.0
const CHASE_SPEED := 23.0
const REPOSITION_SPEED := 26.0
const SWEEP_SPEED := 19.0
const RECRUIT_RANGE := 19.0
const RECRUIT_COST := 75
const ENEMY_DETECT_RANGE := 63.0
const ATTACK_RANGE_ENGAGE := 21.0
const ATTACK_RANGE_DEFEND := 53.0
const ATTACK_COOLDOWN := 1.5
const SWEEP_RETARGET_INTERVAL := 1.5
const BUILD_SWING_TIME := 1.0  # seconds per hammer swing; 4 swings completes a wall
const BUILD_ARRIVE_RANGE := 8.0
const JOB_POST_ARRIVE_RANGE := 12.0
# Slightly slower than dreg MOVE_SPEED (14) so fleeing workers can be caught
const FLEE_SPEED := 12.0
# Workers flee from any enemy within this range; Redjacks use ENEMY_DETECT_RANGE
const WORKER_FLEE_RANGE := 55.0
# Redjacks flee when this many enemies are in detect range simultaneously
const REDJACK_FLEE_THRESHOLD := 5
# Builder scans this far for broken walls while idle
const REPAIR_SCAN_RANGE := 120.0
const REPAIR_SCAN_INTERVAL := 0.5
# Glimmer cost per wall upgrade tier; deducted when builder claims the upgrade
const UPGRADE_COST := 50
# How often a defending redjack checks if its wall is still standing
const GUARD_SCAN_INTERVAL := 0.5

const COLOR_DORMANT  := Color(0.35, 0.35, 0.35, 0.6)
const COLOR_WAITING  := Color(0.75, 0.75, 0.75, 1.0)
const COLOR_REDJACK  := Color(0.75, 0.12, 0.08, 1.0)
const COLOR_BUILDER  := Color(0.30, 0.55, 0.90, 1.0)
const COLOR_FARMER   := Color(0.78, 0.63, 0.18, 1.0)
const COLOR_FLASH    := Color(1.0,  1.0,  0.5,  1.0)
const COLOR_LOCKER   := Color(0.06, 0.22, 0.30, 0.95)
const COLOR_INDICATOR_AMBER := Color(1.0, 0.65, 0.05, 1.0)

@onready var _sprite: ColorRect = $FrameSprite
@onready var _locker_sprite: ColorRect = $LockerSprite
@onready var _indicator_light: ColorRect = $IndicatorLight

var state: State = State.DORMANT
var _player: CharacterBody2D
var _target_enemy: Node2D
var _job_post_target: Node2D
var _build_site_target: Node2D
var _wall_target_pos: Vector2
var _spawn_pos: Vector2
var _attack_timer: float = 0.0
var _sweep_timer: float = 0.0
var _cache_target: Node2D = null
var _build_timer: float = 0.0
var _patrol_dir: float = 1.0
var _prompt_showing: bool = false
var _is_builder: bool = false
var _repair_target: Node2D = null
var _tree_target: Node2D = null
var _repair_scan_timer: float = 0.0
var _is_upgrading: bool = false
var _tower: Node2D = null
var _guard_scan_timer: float = 0.0

func _ready() -> void:
	add_to_group("frame_npc")
	collision_layer = 16  # frame NPC layer — player and enemies pass through
	collision_mask = 1    # ground only
	_sprite.color = COLOR_DORMANT
	_spawn_pos = global_position
	_restore_locker()
	GameState.redjack_job_created.connect(_on_redjack_job_created)
	GameState.sweeperbot_job_created.connect(_on_sweeperbot_job_created)
	GameState.builder_job_created.connect(_on_builder_job_created)
	GameState.dusk_triggered.connect(_on_dusk_triggered)
	GameState.attack_ordered.connect(_on_attack_ordered)

func _physics_process(delta: float) -> void:
	# Flee check — runs for every active state except dormant/returning/already fleeing/garrisoned
	match state:
		State.DORMANT, State.RETURNING_TO_SPAWN, State.FLEEING, \
		State.GARRISONED, State.SEEKING_TOWER, State.REPOSITIONING:
			pass
		_:
			if _should_flee():
				_start_fleeing()

	match state:
		State.DORMANT:
			velocity.x = 0.0
			_check_recruit_prompt()

		State.SEEKING_JOB_POST:
			_do_seek_job_post()

		State.WAITING:
			velocity = Vector2.ZERO

		State.PATROL:
			_do_patrol(delta)

		State.ENGAGE:
			_do_engage(delta)

		State.REPOSITIONING:
			_do_reposition(delta)

		State.DEFENDING:
			velocity.x = 0.0
			_attack_timer -= delta
			if _attack_timer <= 0.0:
				_attack_timer = ATTACK_COOLDOWN
				_do_attack(ATTACK_RANGE_DEFEND)
			if is_in_group("redjacks"):
				_guard_scan_timer -= delta
				if _guard_scan_timer <= 0.0:
					_guard_scan_timer = GUARD_SCAN_INTERVAL
					_check_wall_behind()

		State.SWEEPING:
			_do_sweep(delta)

		State.SEEKING_SITE:
			_do_seek_site(delta)

		State.BUILDING:
			velocity.x = 0.0
			_do_building(delta)

		State.BUILDER_IDLE:
			_do_builder_idle(delta)

		State.REPAIRING:
			_do_repair(delta)

		State.CHOPPING:
			_do_chop(delta)

		State.SEEKING_TOWER:
			_do_seek_tower()

		State.GARRISONED:
			velocity = Vector2.ZERO

		State.RETURNING_TO_SPAWN:
			_do_return_to_spawn()

		State.FLEEING:
			_do_flee()

		State.ASSAULTING:
			_do_assault(delta)

	if not is_on_floor():
		velocity.y += GRAVITY * delta
	move_and_slide()

# ── Dormant ───────────────────────────────────────────────────────────────────

func _check_recruit_prompt() -> void:
	if not _player:
		_player = get_tree().get_first_node_in_group("player") as CharacterBody2D
	if not _player:
		return
	var near: bool = global_position.distance_to(_player.global_position) < RECRUIT_RANGE
	var closest: bool = near and _is_closest_dormant_frame()
	if closest and not _prompt_showing:
		_prompt_showing = true
		GameState.show_action_prompt(self, "[ SPACE ]  Reactivate Frame  —  %d ◈" % RECRUIT_COST, 11)
	elif not closest and _prompt_showing:
		_prompt_showing = false
		GameState.hide_action_prompt(self)
	if closest and GameState.is_prompt_owner(self) and Input.is_action_just_pressed("action"):
		_recruit()

func _is_closest_dormant_frame() -> bool:
	if not _player:
		return true
	var my_dist: float = global_position.distance_to(_player.global_position)
	for f: Node in get_tree().get_nodes_in_group("frame_npc"):
		if f == self:
			continue
		var fn: Node2D = f as Node2D
		if not fn or not is_instance_valid(fn):
			continue
		if int(fn.get("state")) != State.DORMANT:
			continue
		if fn.global_position.distance_to(_player.global_position) < my_dist - 0.5:
			return false
	return true

func _recruit() -> void:
	if not GameState.spend_glimmer(RECRUIT_COST):
		return
	if _prompt_showing:
		_prompt_showing = false
		GameState.action_prompt_hide.emit()
	_open_locker()
	add_to_group("frame_following")
	_sprite.color = COLOR_WAITING
	_find_nearest_job_post()
	state = State.SEEKING_JOB_POST

func is_active_worker() -> bool:
	return state != State.DORMANT and state != State.RETURNING_TO_SPAWN \
		and state != State.GARRISONED

func is_available_for_garrison() -> bool:
	return state != State.DORMANT and state != State.RETURNING_TO_SPAWN \
		and state != State.GARRISONED and state != State.SEEKING_TOWER \
		and state != State.FLEEING

# ── Knocked dormant (enemy hit outside walls) ─────────────────────────────────

func knocked_dormant() -> void:
	if _tower and is_instance_valid(_tower):
		if _tower.has_method("release_garrison"):
			_tower.release_garrison()
		_tower = null
		_sprite.modulate.a = 1.0
	remove_from_group("redjacks")
	remove_from_group("sweeperbots")
	remove_from_group("builders")
	remove_from_group("frame_waiting")
	remove_from_group("frame_following")
	if _is_builder:
		if GameState.build_job_queued.is_connected(_on_build_job_queued):
			GameState.build_job_queued.disconnect(_on_build_job_queued)
		if _build_site_target and is_instance_valid(_build_site_target):
			GameState.queue_build_job(_build_site_target, true)  # priority re-queue
	_is_builder = false
	_is_upgrading = false
	_target_enemy = null
	_build_site_target = null
	_repair_target = null
	_tree_target = null
	_job_post_target = null
	_tower = null
	if GameState.wave_changed.is_connected(_on_wave_changed):
		GameState.wave_changed.disconnect(_on_wave_changed)
	state = State.RETURNING_TO_SPAWN
	_sprite.color = COLOR_DORMANT

func _do_return_to_spawn() -> void:
	var dist: float = abs(global_position.x - _spawn_pos.x)
	if dist < 6.0:
		velocity.x = 0.0
		state = State.DORMANT
		_restore_locker()
	else:
		velocity.x = sign(_spawn_pos.x - global_position.x) * TRAVEL_SPEED

# ── Stasis locker ─────────────────────────────────────────────────────────────

func _restore_locker() -> void:
	if _locker_sprite:
		_locker_sprite.visible = true
		_locker_sprite.modulate.a = 1.0
	if _indicator_light:
		_indicator_light.visible = true
		_indicator_light.modulate.a = 1.0
		_indicator_light.color = COLOR_INDICATOR_AMBER

func _open_locker() -> void:
	if _locker_sprite:
		var tween: Tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(_locker_sprite, "modulate:a", 0.0, 0.35)
		tween.tween_property(_indicator_light, "modulate:a", 0.0, 0.2)
		tween.chain().tween_callback(func() -> void:
			if _locker_sprite: _locker_sprite.visible = false
			if _indicator_light: _indicator_light.visible = false
		)

# ── Flee ──────────────────────────────────────────────────────────────────────

func _should_flee() -> bool:
	match state:
		# Workers: flee only from enemies that have actually breached the wall line
		State.SWEEPING, State.SEEKING_SITE, State.BUILDING, State.BUILDER_IDLE, \
		State.REPAIRING, State.WAITING, State.SEEKING_JOB_POST:
			return _find_nearest_unblocked_enemy(WORKER_FLEE_RANGE) != null
		# Redjacks: fight until seriously outnumbered; last stand when no walls remain
		# REPOSITIONING excluded — let them reach the wall before becoming flee-eligible
		State.PATROL, State.ENGAGE, State.DEFENDING:
			if get_tree().get_nodes_in_group("walls").is_empty():
				return false  # last stand — hold the encampment, no retreat
			var count: int = 0
			for e: Node in get_tree().get_nodes_in_group("enemies"):
				var en: Node2D = e as Node2D
				if en and is_instance_valid(en) and global_position.distance_to(en.global_position) < ENEMY_DETECT_RANGE:
					count += 1
					if count >= REDJACK_FLEE_THRESHOLD:
						return true
			return false
	return false

func _is_blocked_by_wall(enemy_x: float) -> bool:
	var lo: float = minf(global_position.x, enemy_x)
	var hi: float = maxf(global_position.x, enemy_x)
	for wall: Node in get_tree().get_nodes_in_group("walls"):
		var wn: Node2D = wall as Node2D
		if wn and is_instance_valid(wn) and wn.global_position.x >= lo - 2.0 and wn.global_position.x < hi:
			return true
	return false

func _find_nearest_unblocked_enemy(max_range: float) -> Node2D:
	var nearest: Node2D = null
	var nearest_dist: float = max_range
	for enemy: Node in get_tree().get_nodes_in_group("enemies"):
		var en: Node2D = enemy as Node2D
		if not en or not is_instance_valid(en):
			continue
		if _is_blocked_by_wall(en.global_position.x):
			continue
		var dist: float = global_position.distance_to(en.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = en
	return nearest

func _start_fleeing() -> void:
	_target_enemy = null
	# Intentionally keep _build_site_target and _repair_target so builder resumes after fleeing
	state = State.FLEEING

func _flee_target_x() -> float:
	if is_in_group("redjacks"):
		# Fall back to just behind the nearest wall to the left, not all the way to the encampment
		var best: float = GameState.ENCAMPMENT_X + 35.0
		for wall: Node in get_tree().get_nodes_in_group("walls"):
			var wn: Node2D = wall as Node2D
			if wn and is_instance_valid(wn) and wn.global_position.x < global_position.x - 8.0:
				best = maxf(best, wn.global_position.x - 10.0)
		return best
	return GameState.ENCAMPMENT_X + 35.0

func _do_flee() -> void:
	var safe_range: float = ENEMY_DETECT_RANGE if is_in_group("redjacks") else WORKER_FLEE_RANGE
	if _find_nearest_unblocked_enemy(safe_range) == null:
		_resume_after_flee()
		return
	velocity.x = -FLEE_SPEED
	var target: float = _flee_target_x()
	if global_position.x <= target:
		velocity.x = 0.0

func _resume_after_flee() -> void:
	if _is_builder:
		if _build_site_target and is_instance_valid(_build_site_target):
			state = State.SEEKING_SITE
		elif _repair_target and is_instance_valid(_repair_target):
			_build_timer = 0.0
			state = State.REPAIRING
		else:
			state = State.BUILDER_IDLE
	elif is_in_group("redjacks"):
		if get_tree().get_nodes_in_group("walls").is_empty():
			state = State.DEFENDING
		elif _tower and is_instance_valid(_tower):
			state = State.SEEKING_TOWER
		else:
			_start_repositioning()
	elif is_in_group("sweeperbots"):
		state = State.SWEEPING
	else:
		_find_nearest_job_post()
		state = State.SEEKING_JOB_POST

# ── Wall integrity scan (defending redjacks) ───────────────────────────────────

func _check_wall_behind() -> void:
	if get_tree().get_nodes_in_group("walls").is_empty():
		return  # last stand at encampment, stay put
	var target_x: float = _get_defend_target_x()
	if abs(global_position.x - target_x) <= 15.0:
		return  # properly stationed
	_start_repositioning()

# ── Seek job post ─────────────────────────────────────────────────────────────

func _find_nearest_job_post() -> void:
	var posts: Array[Node] = get_tree().get_nodes_in_group("job_posts")
	# First pass: prefer a post whose job type is currently available
	var nearest: Node2D = null
	var nearest_dist: float = INF
	for post: Node in posts:
		var pn: Node2D = post as Node2D
		if not pn or not is_instance_valid(pn):
			continue
		var ptype: int = int(pn.get("job_type"))
		var has_job: bool = false
		match ptype:
			0: has_job = GameState.redjack_jobs_available > 0
			1: has_job = GameState.sweeperbot_jobs_available > 0
			2: has_job = GameState.builder_jobs_available > 0
		if not has_job:
			continue
		var dist: float = global_position.distance_to(pn.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = pn
	if nearest:
		_job_post_target = nearest
		return
	# Second pass: no jobs available yet — go to nearest post to wait
	nearest_dist = INF
	for post: Node in posts:
		var pn: Node2D = post as Node2D
		if not pn or not is_instance_valid(pn):
			continue
		var dist: float = global_position.distance_to(pn.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = pn
	_job_post_target = nearest

func _do_seek_job_post() -> void:
	if not _job_post_target or not is_instance_valid(_job_post_target):
		_find_nearest_job_post()
		if not _job_post_target:
			velocity.x = 0.0
			_arrive_at_job_post()
			return
	var dist: float = abs(global_position.x - _job_post_target.global_position.x)
	if dist < JOB_POST_ARRIVE_RANGE:
		velocity.x = 0.0
		_arrive_at_job_post()
	else:
		velocity.x = sign(_job_post_target.global_position.x - global_position.x) * TRAVEL_SPEED

func _arrive_at_job_post() -> void:
	if state == State.WAITING:
		return
	remove_from_group("frame_following")
	add_to_group("frame_waiting")
	state = State.WAITING
	_sprite.color = COLOR_WAITING
	_try_take_post_job()

func _try_take_post_job() -> void:
	if not _job_post_target or not is_instance_valid(_job_post_target):
		return
	var ptype: int = int(_job_post_target.get("job_type"))
	match ptype:
		0:
			if GameState.redjack_jobs_available > 0:
				_on_redjack_job_created()
		1:
			if GameState.sweeperbot_jobs_available > 0:
				_on_sweeperbot_job_created()
		2:
			if GameState.builder_jobs_available > 0:
				_on_builder_job_created()

# ── Job assignment ─────────────────────────────────────────────────────────────

func _on_dusk_triggered(_day: int) -> void:
	# At dusk, redjacks leave patrol/engage and walk to their defensive wall positions
	if is_in_group("redjacks") and (state == State.PATROL or state == State.ENGAGE):
		_start_repositioning()

func _on_redjack_job_created() -> void:
	if state != State.WAITING:
		return
	if not _job_post_target or not is_instance_valid(_job_post_target):
		return
	if int(_job_post_target.get("job_type")) != 0:
		# Wrong post type — redirect to the post with an available job
		_redirect_to_job_with_type(0)
		return
	if GameState.redjack_jobs_available <= 0:
		return
	GameState.redjack_jobs_available -= 1
	remove_from_group("frame_waiting")
	add_to_group("redjacks")
	state = State.PATROL
	_sprite.color = COLOR_REDJACK
	GameState.wave_changed.connect(_on_wave_changed)
	if GameState.wave_number >= 1:
		_start_repositioning()

func _on_sweeperbot_job_created() -> void:
	if state != State.WAITING:
		return
	if not _job_post_target or not is_instance_valid(_job_post_target):
		return
	if int(_job_post_target.get("job_type")) != 1:
		_redirect_to_job_with_type(1)
		return
	if GameState.sweeperbot_jobs_available <= 0:
		return
	GameState.sweeperbot_jobs_available -= 1
	remove_from_group("frame_waiting")
	add_to_group("sweeperbots")
	state = State.SWEEPING
	_sprite.color = COLOR_FARMER

func _on_builder_job_created() -> void:
	if state != State.WAITING:
		return
	if not _job_post_target or not is_instance_valid(_job_post_target):
		return
	if int(_job_post_target.get("job_type")) != 2:
		_redirect_to_job_with_type(2)
		return
	if GameState.builder_jobs_available <= 0:
		return
	GameState.builder_jobs_available -= 1
	_is_builder = true
	remove_from_group("frame_waiting")
	add_to_group("builders")
	_sprite.color = COLOR_BUILDER
	GameState.build_job_queued.connect(_on_build_job_queued)
	_try_claim_build_job()

func _redirect_to_job_with_type(job_type: int) -> void:
	# Walk to the post that matches job_type so we can take the job there
	for post: Node in get_tree().get_nodes_in_group("job_posts"):
		var pn: Node2D = post as Node2D
		if pn and is_instance_valid(pn) and int(pn.get("job_type")) == job_type:
			_job_post_target = pn
			remove_from_group("frame_waiting")
			add_to_group("frame_following")
			state = State.SEEKING_JOB_POST
			return

func _try_claim_build_job() -> void:
	var job: Node = GameState.claim_next_build_job()
	if job and is_instance_valid(job):
		_build_site_target = job as Node2D
		state = State.SEEKING_SITE
	else:
		state = State.BUILDER_IDLE

func _on_build_job_queued() -> void:
	if state == State.BUILDER_IDLE:
		_try_claim_build_job()

# ── Patrol ────────────────────────────────────────────────────────────────────

func _patrol_right_bound() -> float:
	var furthest_x: float = 150.0
	for wall: Node in get_tree().get_nodes_in_group("walls"):
		var wn: Node2D = wall as Node2D
		if wn:
			furthest_x = maxf(furthest_x, wn.global_position.x - 15.0)
	return furthest_x

func _do_patrol(_delta: float) -> void:
	var enemy: Node2D = _find_nearest_enemy(ENEMY_DETECT_RANGE)
	if enemy:
		_target_enemy = enemy
		state = State.ENGAGE
		return
	var left_bound: float = GameState.ENCAMPMENT_X + 25.0
	var right_bound: float = _patrol_right_bound()
	if global_position.x >= right_bound:
		_patrol_dir = -1.0
	elif global_position.x <= left_bound:
		_patrol_dir = 1.0
	velocity.x = _patrol_dir * PATROL_SPEED

# ── Engage ────────────────────────────────────────────────────────────────────

func _do_engage(delta: float) -> void:
	if not _target_enemy or not is_instance_valid(_target_enemy):
		_target_enemy = null
		state = State.PATROL
		return
	var dist: float = global_position.distance_to(_target_enemy.global_position)
	if dist > ENEMY_DETECT_RANGE * 1.5:
		_target_enemy = null
		state = State.PATROL
		return
	if dist <= ATTACK_RANGE_ENGAGE:
		velocity.x = 0.0
		_attack_timer -= delta
		if _attack_timer <= 0.0:
			_attack_timer = ATTACK_COOLDOWN
			_do_attack(ATTACK_RANGE_ENGAGE)
	else:
		velocity.x = sign(_target_enemy.global_position.x - global_position.x) * CHASE_SPEED

# ── Sweep (Sweeperbot) ────────────────────────────────────────────────────────

func _do_sweep(delta: float) -> void:
	_sweep_timer -= delta
	if _sweep_timer <= 0.0 or not is_instance_valid(_cache_target):
		_sweep_timer = SWEEP_RETARGET_INTERVAL
		_cache_target = _find_nearest_cache()
	if _cache_target and is_instance_valid(_cache_target):
		velocity.x = sign(_cache_target.global_position.x - global_position.x) * SWEEP_SPEED
	else:
		var diff: float = GameState.ENCAMPMENT_X - global_position.x
		velocity.x = 0.0 if abs(diff) < 15.0 else sign(diff) * SWEEP_SPEED

func _find_nearest_cache() -> Node2D:
	var nearest: Node2D = null
	var nearest_dist: float = INF
	for cache: Node in get_tree().get_nodes_in_group("glimmer_caches"):
		var cn: Node2D = cache as Node2D
		if not cn or not is_instance_valid(cn):
			continue
		var dist: float = global_position.distance_to(cn.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = cn
	return nearest

# ── Builder ────────────────────────────────────────────────────────────────────

func _do_builder_idle(delta: float) -> void:
	_repair_scan_timer -= delta
	if _repair_scan_timer <= 0.0:
		_repair_scan_timer = REPAIR_SCAN_INTERVAL
		_check_for_repair_targets()
	var left: float = GameState.ENCAMPMENT_X - 20.0
	var right: float = GameState.ENCAMPMENT_X + 60.0
	if global_position.x >= right:
		_patrol_dir = -1.0
	elif global_position.x <= left:
		_patrol_dir = 1.0
	velocity.x = _patrol_dir * PATROL_SPEED

func _check_for_repair_targets() -> void:
	# Priority 1: free repair — seek nearest broken wall (no range limit; builder walks to it)
	var nearest_broken: Node2D = null
	var nearest_broken_dist: float = INF
	for wall: Node in get_tree().get_nodes_in_group("walls"):
		var wn: Node2D = wall as Node2D
		if not wn or not is_instance_valid(wn):
			continue
		var hp_val: Variant = wn.get("_hp")
		if hp_val == null:
			continue
		var hp_int: int = hp_val as int
		if hp_int > 0 and (hp_int % 2) == 1:  # broken (odd HP)
			var d: float = global_position.distance_to(wn.global_position)
			if d < nearest_broken_dist:
				nearest_broken_dist = d
				nearest_broken = wn
	if nearest_broken:
		_repair_target = nearest_broken
		_is_upgrading = false
		_build_timer = 0.0
		state = State.REPAIRING
		return
	# Priority 2: chop a tree for glimmer (only if commissioned by player)
	var nearest_tree: Node2D = null
	var nearest_tree_dist: float = REPAIR_SCAN_RANGE
	for tree: Node in get_tree().get_nodes_in_group("trees"):
		var tn: Node2D = tree as Node2D
		if not tn or not is_instance_valid(tn):
			continue
		if not tn.get("_commissioned"):
			continue
		var d: float = global_position.distance_to(tn.global_position)
		if d < nearest_tree_dist:
			nearest_tree_dist = d
			nearest_tree = tn
	if nearest_tree:
		_tree_target = nearest_tree
		_build_timer = 0.0
		state = State.CHOPPING

func _do_repair(delta: float) -> void:
	if not _repair_target or not is_instance_valid(_repair_target):
		_repair_target = null
		_is_upgrading = false
		state = State.BUILDER_IDLE
		return
	if _is_upgrading:
		# bail if wall was destroyed or already at max tier while walking over
		if not _repair_target.has_method("can_upgrade") or not _repair_target.call("can_upgrade"):
			_repair_target = null
			_is_upgrading = false
			_sprite.color = COLOR_BUILDER
			state = State.BUILDER_IDLE
			return
	else:
		var hp_val: Variant = _repair_target.get("_hp")
		var hp_int: int = hp_val as int if hp_val != null else 0
		if hp_int <= 0 or (hp_int % 2) == 0:  # wall gone or already healthy
			_repair_target = null
			_sprite.color = COLOR_BUILDER
			state = State.BUILDER_IDLE
			return
	var dist: float = abs(global_position.x - _repair_target.global_position.x)
	if dist > BUILD_ARRIVE_RANGE:
		velocity.x = sign(_repair_target.global_position.x - global_position.x) * TRAVEL_SPEED
		return
	velocity.x = 0.0
	_build_timer += delta
	var pulse: float = sin(_build_timer * TAU) * 0.5 + 0.5
	_sprite.color = COLOR_BUILDER.lerp(COLOR_FLASH, pulse)
	if _build_timer >= BUILD_SWING_TIME:
		_build_timer = 0.0
		if _repair_target and is_instance_valid(_repair_target):
			if _is_upgrading:
				_repair_target.call("upgrade")
			else:
				_repair_target.call("repair")
		_repair_target = null
		_is_upgrading = false
		_sprite.color = COLOR_BUILDER
		state = State.BUILDER_IDLE

func _do_seek_site(_delta: float) -> void:
	if not _build_site_target or not is_instance_valid(_build_site_target):
		_try_claim_build_job()
		return
	var dist: float = abs(global_position.x - _build_site_target.global_position.x)
	if dist < BUILD_ARRIVE_RANGE:
		velocity.x = 0.0
		_build_timer = 0.0
		state = State.BUILDING
	else:
		velocity.x = sign(_build_site_target.global_position.x - global_position.x) * TRAVEL_SPEED

func _do_building(delta: float) -> void:
	if not _build_site_target or not is_instance_valid(_build_site_target):
		_try_claim_build_job()
		return
	_build_timer += delta
	var pulse: float = sin(_build_timer * TAU) * 0.5 + 0.5
	_sprite.color = COLOR_BUILDER.lerp(COLOR_WAITING, pulse)
	if _build_timer >= BUILD_SWING_TIME:
		_build_timer -= BUILD_SWING_TIME  # keep rhythm; don't reset to 0
		if _build_site_target and is_instance_valid(_build_site_target):
			_build_site_target.add_progress(1)
			if not is_instance_valid(_build_site_target) or _build_site_target.is_complete():
				_build_site_target = null
				_sprite.color = COLOR_BUILDER
				_try_claim_build_job()

# ── Reposition ────────────────────────────────────────────────────────────────

func _on_wave_changed(wave: int) -> void:
	if wave >= 1 and (state == State.PATROL or state == State.ENGAGE):
		_start_repositioning()

func _get_defend_target_x() -> float:
	var walls: Array[Node] = get_tree().get_nodes_in_group("walls")
	var sorted: Array[Node2D] = []
	for wall: Node in walls:
		var wn: Node2D = wall as Node2D
		if wn and is_instance_valid(wn):
			sorted.append(wn)
	if sorted.is_empty():
		return 120.0
	sorted.sort_custom(func(a: Node2D, b: Node2D) -> bool: return a.global_position.x > b.global_position.x)
	var target: Node2D = sorted[0]
	var outer_hp: Variant = target.get("_hp")
	if outer_hp != null and int(outer_hp) <= 1 and sorted.size() > 1:
		target = sorted[1]
	return target.global_position.x - 10.0

func _start_repositioning() -> void:
	_target_enemy = null
	_wall_target_pos = Vector2(_get_defend_target_x(), global_position.y)
	state = State.REPOSITIONING

func _do_reposition(_delta: float) -> void:
	_wall_target_pos.x = _get_defend_target_x()
	if abs(global_position.x - _wall_target_pos.x) < 3.0:
		velocity.x = 0.0
		_guard_scan_timer = GUARD_SCAN_INTERVAL
		state = State.DEFENDING
	else:
		velocity.x = sign(_wall_target_pos.x - global_position.x) * REPOSITION_SPEED

# ── Tower garrison ────────────────────────────────────────────────────────────

func walk_to_tower(tower: Node2D) -> void:
	_tower = tower
	_target_enemy = null
	state = State.SEEKING_TOWER

func _do_seek_tower() -> void:
	if not _tower or not is_instance_valid(_tower):
		_tower = null
		state = State.PATROL
		return
	var dist: float = abs(global_position.x - _tower.global_position.x)
	if dist < BUILD_ARRIVE_RANGE:
		velocity.x = 0.0
		enter_tower(_tower)
	else:
		velocity.x = sign(_tower.global_position.x - global_position.x) * TRAVEL_SPEED

func enter_tower(tower: Node2D) -> void:
	_tower = tower
	tower.garrison(self)
	state = State.GARRISONED
	_sprite.color = COLOR_REDJACK  # visible, stationed at tower

func exit_tower() -> void:
	_tower = null
	if get_tree().get_nodes_in_group("walls").is_empty():
		state = State.DEFENDING
	else:
		_start_repositioning()

# ── Attack ────────────────────────────────────────────────────────────────────

func _do_attack(attack_range: float) -> void:
	var nearest: Node2D = _find_nearest_enemy(attack_range)
	if nearest and nearest.has_method("take_damage"):
		nearest.take_damage(1)
		_flash_attack()

func _flash_attack() -> void:
	var restore_color: Color = _sprite.color
	var tween: Tween = create_tween()
	tween.tween_property(_sprite, "color", COLOR_FLASH, 0.0)
	tween.tween_interval(0.08)
	tween.tween_property(_sprite, "color", restore_color, 0.12)

# ── Tree chopping (builders) ──────────────────────────────────────────────────

func _do_chop(delta: float) -> void:
	if not _tree_target or not is_instance_valid(_tree_target):
		_tree_target = null
		state = State.BUILDER_IDLE
		return
	var dist: float = abs(global_position.x - _tree_target.global_position.x)
	if dist > BUILD_ARRIVE_RANGE:
		velocity.x = sign(_tree_target.global_position.x - global_position.x) * TRAVEL_SPEED
		return
	velocity.x = 0.0
	_build_timer += delta
	var pulse: float = sin(_build_timer * TAU) * 0.5 + 0.5
	_sprite.color = COLOR_BUILDER.lerp(COLOR_FLASH, pulse)
	if _build_timer >= BUILD_SWING_TIME:
		_build_timer = 0.0
		if _tree_target and is_instance_valid(_tree_target):
			var fell: bool = _tree_target.call("chop")
			if fell or not is_instance_valid(_tree_target):
				_tree_target = null
				_sprite.color = COLOR_BUILDER
				state = State.BUILDER_IDLE

# ── Assault (player ordered charge) ──────────────────────────────────────────

func _on_attack_ordered() -> void:
	if state == State.DORMANT or state == State.RETURNING_TO_SPAWN or state == State.GARRISONED:
		return
	if not is_in_group("redjacks"):
		return
	_target_enemy = null
	state = State.ASSAULTING

func _do_assault(delta: float) -> void:
	# Extended detect range — includes bosses (in "enemies" group)
	var target: Node2D = _find_nearest_enemy(ENEMY_DETECT_RANGE * 2.5)
	if target:
		_target_enemy = target
		var dist: float = global_position.distance_to(target.global_position)
		if dist <= ATTACK_RANGE_ENGAGE:
			velocity.x = 0.0
			_attack_timer -= delta
			if _attack_timer <= 0.0:
				_attack_timer = ATTACK_COOLDOWN
				_do_attack(ATTACK_RANGE_ENGAGE)
		else:
			velocity.x = sign(target.global_position.x - global_position.x) * CHASE_SPEED
	else:
		velocity.x = TRAVEL_SPEED  # march right toward portal

# ── Attack ────────────────────────────────────────────────────────────────────

func _find_nearest_enemy(max_range: float) -> Node2D:
	var nearest: Node2D = null
	var nearest_dist: float = max_range
	for enemy: Node in get_tree().get_nodes_in_group("enemies"):
		var en: Node2D = enemy as Node2D
		if not en or not is_instance_valid(en):
			continue
		var dist: float = global_position.distance_to(en.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = en
	return nearest
