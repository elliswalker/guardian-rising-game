extends Node2D

const DREG_SCENE      := preload("res://scenes/enemies/dreg.tscn")
const VANDAL_SCENE    := preload("res://scenes/enemies/vandal.tscn")
const THRALL_SCENE    := preload("res://scenes/enemies/thrall.tscn")
const LEGIONARY_SCENE := preload("res://scenes/enemies/legionary.tscn")
const CACHE_SCENE     := preload("res://scenes/world/glimmer_cache.tscn")
const FRAME_SCENE     := preload("res://scenes/world/guardian.tscn")
const TREE_SCENE      := preload("res://scenes/world/tree.tscn")
const SHIP_SCENE      := preload("res://scenes/world/ship.tscn")
const PORTAL_SCENE    := preload("res://scenes/world/portal.tscn")
const SERVITOR_SCENE  := preload("res://scenes/enemies/servitor.tscn")
const FLAG_SCENE      := preload("res://scenes/world/attack_flag.tscn")
const WILDLIFE_SCENE  := preload("res://scenes/world/wildlife.tscn")

const MAX_DORMANT_FRAMES := 6
# Far-field positions — recruitable during day but exposed at night
const FRAME_SPAWN_XS: Array[float] = [195.0, 250.0, 310.0, 390.0, 460.0, 540.0]

# Trees scattered across the extended field
const TREE_POSITIONS: Array[float] = [360.0, 430.0, 510.0, 590.0, 660.0]

const COLOR_SKY_DAY   := Color(0.42, 0.47, 0.55, 1)
const COLOR_SKY_DUSK  := Color(0.55, 0.32, 0.18, 1)
const COLOR_SKY_NIGHT := Color(0.08, 0.07, 0.18, 1)
const COLOR_SKY_BLOOD := Color(0.45, 0.08, 0.10, 1)

const DAY_DURATION_BASE := 90.0
const DAY_DURATION_DEC  := 3.0
const DAY_DURATION_MIN  := 60.0
const DUSK_DURATION     := 12.0
const MAX_WAVE_SIZE     := 14
const NIGHT_PACK_SIZE   := 3
const NIGHT_PACK_INTERVAL := 3.5
const DAWN_DURATION        := 5.5
# After all wave spawns, dawn fires after this timeout OR when enemies clear — whichever first.
# This ensures retreat() is called on living enemies rather than only firing when the field is empty.
const NIGHT_WAVE_TIMEOUT   := 35.0

# Night rhythm — spike nights and the mercy beat that follows them
const SPIKE_FIRST_DAY      := 5
const SPIKE_INTERVAL       := 5     # spike night every N days
const SPIKE_MULTIPLIER     := 2.0
const QUIET_NIGHT_DURATION := 10.0  # recovery night: brief, empty, then dawn
const COUNTERATTACK_MIN    := 6

# Day wanderers: Fallen dregs wander the field, count scales with day
const DAY_DREG_COUNT    := 2
const DAY_DREG_MIN_X    := 400.0
const DAY_DREG_MAX_X    := 720.0

enum Phase { DAY, DUSK, NIGHT, DAWN }

var spawn_point_right: Marker2D
var _sky_rect: ColorRect
var _sun_disc: ColorRect

var _phase: Phase = Phase.DAY
var _day_timer: float = 0.0
var _day_duration: float = DAY_DURATION_BASE
var _dusk_timer: float = 0.0
var _last_dusk_seconds: int = -1
var _dawn_timer: float = 0.0
var _night_total: int = 0
var _night_spawned: int = 0
var _spawn_timer: float = 0.0
var _post_spawn_timer: float = 0.0
var _spike_this_night: bool = false
var _quiet_night_pending: bool = false
var _quiet_this_night: bool = false

func _ready() -> void:
	add_to_group("world")
	spawn_point_right = $SpawnRight
	_sky_rect = $ParallaxBackground/SkyLayer/SkyRect
	_sun_disc = $SkyUI/SunDisc
	GameState.new_run()
	GameState.portal_broken.connect(_on_portal_broken)
	_spawn_trees()
	_spawn_world_objects()
	_spawn_initial_caches()
	_start_day()

func _process(delta: float) -> void:
	match _phase:
		Phase.DAY:   _process_day(delta)
		Phase.DUSK:  _process_dusk(delta)
		Phase.NIGHT: _process_night(delta)
		Phase.DAWN:  _process_dawn(delta)

# ── DAY ────────────────────────────────────────────────────────────────────────

func _start_day() -> void:
	if not GameState.portal_active:
		GameState.trigger_victory()
		return
	GameState.day_number += 1
	var day: int = GameState.day_number
	_day_duration = maxf(DAY_DURATION_MIN, DAY_DURATION_BASE - float(day - 1) * DAY_DURATION_DEC)
	_day_timer = _day_duration
	_last_dusk_seconds = -1
	_phase = Phase.DAY
	if _sun_disc:
		_sun_disc.visible = true
		_update_sun()
	_spawn_day_caches()
	_spawn_day_dregs()
	_spawn_day_wildlife()
	if day > 1:
		_try_spawn_frame()
	GameState.day_started.emit(day)

func _process_day(delta: float) -> void:
	_day_timer -= delta
	_update_sun()
	var curr_secs: int = maxi(0, ceili(_day_timer))
	if curr_secs != _last_dusk_seconds:
		_last_dusk_seconds = curr_secs
		GameState.dusk_timer_updated.emit(curr_secs)
	if _day_timer <= 0.0:
		_start_dusk()

func _update_sun() -> void:
	if not _sun_disc:
		return
	var t: float = 1.0 - clampf(_day_timer / _day_duration, 0.0, 1.0)
	var cx: float = lerpf(50.0, 1230.0, t)
	var cy: float = 155.0 - sin(t * PI) * 125.0
	_sun_disc.position = Vector2(cx - 9.0, cy - 9.0)

# ── DUSK ───────────────────────────────────────────────────────────────────────

func _start_dusk() -> void:
	_phase = Phase.DUSK
	_dusk_timer = DUSK_DURATION
	_transition_sky(COLOR_SKY_DUSK, 3.0)
	GameState.dusk_triggered.emit(GameState.day_number)

func _process_dusk(delta: float) -> void:
	_dusk_timer -= delta
	if _dusk_timer <= 0.0:
		_start_night()

# ── NIGHT ───────────────────────────────────────────────────────────────────────

func _start_night() -> void:
	_phase = Phase.NIGHT
	if _sun_disc:
		_sun_disc.visible = false
	if not GameState.portal_active:
		# Portal destroyed — skip night, go straight to victory dawn
		_trigger_dawn()
		return
	var day: int = GameState.day_number
	_quiet_this_night = _quiet_night_pending
	_quiet_night_pending = false
	if _quiet_this_night:
		# Recovery night — the enemy is spent after the spike. Brief, empty, merciful.
		_spike_this_night = false
		_night_total = 0
		_night_spawned = 0
		_spawn_timer = 0.0
		_post_spawn_timer = NIGHT_WAVE_TIMEOUT - QUIET_NIGHT_DURATION
		_transition_sky(COLOR_SKY_NIGHT, 3.0)
		return
	_spike_this_night = day >= SPIKE_FIRST_DAY and day % SPIKE_INTERVAL == 0
	_night_total = mini(3 + (day - 1) * 2, MAX_WAVE_SIZE)
	if _spike_this_night:
		_night_total = int(float(_night_total) * SPIKE_MULTIPLIER)  # deliberately exceeds the cap
		_quiet_night_pending = true
	_night_spawned = 0
	_spawn_timer = 1.5
	_post_spawn_timer = 0.0
	GameState.wave_number = day
	GameState.wave_changed.emit(day)
	_transition_sky(COLOR_SKY_BLOOD if _spike_this_night else COLOR_SKY_NIGHT, 3.0)

func _night_pack_size() -> int:
	return 1

func _night_pack_interval() -> float:
	return maxf(0.8, 4.5 - float(GameState.day_number) * 0.3)

func _process_night(delta: float) -> void:
	# Early dawn: field cleared before all spawns finished
	if _night_spawned > 0 and get_tree().get_nodes_in_group("enemies").is_empty():
		_trigger_dawn()
		return
	if _night_spawned < _night_total:
		_spawn_timer -= delta
		if _spawn_timer <= 0.0:
			var to_spawn: int = mini(_night_pack_size(), _night_total - _night_spawned)
			_spawn_dreg_pack(to_spawn)
			_night_spawned += to_spawn
			_spawn_timer = _night_pack_interval()
	else:
		_post_spawn_timer += delta
		if _post_spawn_timer >= NIGHT_WAVE_TIMEOUT:
			_trigger_dawn()

# ── DAWN ────────────────────────────────────────────────────────────────────────

func _trigger_dawn() -> void:
	_phase = Phase.DAWN
	_dawn_timer = DAWN_DURATION
	_transition_sky(COLOR_SKY_DAY, 3.5)
	for enemy: Node in get_tree().get_nodes_in_group("enemies"):
		if enemy.has_method("retreat"):
			enemy.retreat()
	GameState.dawn_triggered.emit(GameState.day_number)

func _process_dawn(delta: float) -> void:
	_dawn_timer -= delta
	if _dawn_timer <= 0.0:
		_start_day()

# The portal's death rattle — everything it has left pours out at once.
# Victory is only reached by surviving this and making it to the next dawn.
func _on_portal_broken(_faction: String) -> void:
	var count: int = maxi(COUNTERATTACK_MIN, mini(3 + (GameState.day_number - 1) * 2, MAX_WAVE_SIZE))
	_spawn_dreg_pack(count)
	_transition_sky(COLOR_SKY_BLOOD, 1.5)

# ── WORLD SETUP ───────────────────────────────────────────────────────────────

func _spawn_trees() -> void:
	for x: float in TREE_POSITIONS:
		var tree: Node2D = TREE_SCENE.instantiate() as Node2D
		tree.position = Vector2(x, 148.0)
		add_child(tree)

func _spawn_world_objects() -> void:
	# Ship sits wrecked to the LEFT of the encampment — player's exit from Earth.
	var ship: Node2D = SHIP_SCENE.instantiate() as Node2D
	ship.position = Vector2(-280.0, 142.0)
	add_child(ship)

	var portal: Node2D = PORTAL_SCENE.instantiate() as Node2D
	portal.position = Vector2(740.0, 148.0)
	add_child(portal)

	var servitor: CharacterBody2D = SERVITOR_SCENE.instantiate() as CharacterBody2D
	servitor.position = Vector2(698.0, 130.0)
	add_child(servitor)

	var flag: Node2D = FLAG_SCENE.instantiate() as Node2D
	flag.position = Vector2(620.0, 148.0)
	add_child(flag)

# ── SPAWNING ──────────────────────────────────────────────────────────────────

func _spawn_day_dregs() -> void:
	var day: int = GameState.day_number
	var count: int = DAY_DREG_COUNT + (1 if day >= 3 else 0) + (1 if day >= 5 else 0)
	for i in count:
		var dreg: CharacterBody2D = DREG_SCENE.instantiate() as CharacterBody2D
		dreg.set("_start_feral", false)
		dreg.global_position = Vector2(randf_range(DAY_DREG_MIN_X, DAY_DREG_MAX_X), 136.0)
		add_child(dreg)

func _spawn_day_wildlife() -> void:
	var count: int = 3 + (1 if GameState.day_number >= 3 else 0)
	for i in count:
		var critter: Node2D = WILDLIFE_SCENE.instantiate() as Node2D
		critter.position = Vector2(randf_range(220.0, 700.0), 147.0)
		add_child(critter)

func _spawn_dreg_pack(count: int) -> void:
	var day: int = GameState.day_number
	for i in count:
		var spawn_pos: Vector2 = spawn_point_right.global_position + Vector2(float(i) * 16.0, 0.0)
		var enemy: CharacterBody2D = _pick_fallen_enemy(day).instantiate()
		enemy.global_position = spawn_pos
		add_child(enemy)

func _pick_fallen_enemy(day: int) -> PackedScene:
	if day >= 4 and randf() < 0.4:
		return VANDAL_SCENE
	return DREG_SCENE

func _spawn_initial_caches() -> void:
	var positions: Array[float] = [-125.0, -75.0, -20.0, 40.0, 105.0, 170.0, 238.0, 313.0]
	for x: float in positions:
		_spawn_cache_at(x)

func _spawn_day_caches() -> void:
	if GameState.day_number <= 1:
		return
	_spawn_caches_near_player(3)

func _spawn_caches_near_player(count: int) -> void:
	var player: Node = get_tree().get_first_node_in_group("player")
	var center_x: float = player.global_position.x if player else 0.0
	for i: int in count:
		var offset_x: float = randf_range(-175.0, 175.0)
		_spawn_cache_at(center_x + offset_x)

func _spawn_cache_at(x: float) -> void:
	var cache: Node2D = CACHE_SCENE.instantiate() as Node2D
	cache.position = Vector2(x, 146.0)
	cache.set("glimmer_amount", randi_range(40, 120))
	add_child(cache)

func _try_spawn_frame() -> void:
	var dormant: int = 0
	for f: Node in get_tree().get_nodes_in_group("frame_npc"):
		if (f.get("state") as int) == 0:
			dormant += 1
	if dormant >= MAX_DORMANT_FRAMES:
		return
	var to_spawn: int = 2 if (GameState.day_number >= 3 and randf() < 0.5) else 1
	to_spawn = mini(to_spawn, MAX_DORMANT_FRAMES - dormant)
	for i in to_spawn:
		var spawn_x: float = FRAME_SPAWN_XS[randi() % FRAME_SPAWN_XS.size()]
		var frame: CharacterBody2D = FRAME_SCENE.instantiate() as CharacterBody2D
		frame.global_position = Vector2(spawn_x + float(i) * 18.0, 136.0)
		add_child(frame)

# ── HELPERS ───────────────────────────────────────────────────────────────────

func _transition_sky(target: Color, duration: float) -> void:
	if not _sky_rect:
		return
	var tinted: Color = Color(target.r, target.g, target.b, 0.55)
	var tween: Tween = create_tween()
	tween.tween_property(_sky_rect, "color", tinted, duration).set_ease(Tween.EASE_IN_OUT)

# ── DEBUG ─────────────────────────────────────────────────────────────────────

func debug_spawn_dreg() -> void:
	var player: Node = get_tree().get_first_node_in_group("player")
	var dreg: CharacterBody2D = DREG_SCENE.instantiate() as CharacterBody2D
	dreg.global_position = player.global_position + Vector2(50.0, 0.0) if player else Vector2(100.0, 135.0)
	add_child(dreg)

func debug_force_dusk() -> void:
	_day_timer = 0.0
