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
const SHRINE_SCENE    := preload("res://scenes/world/ghost_shrine.tscn")
const PICKUP_SCENE    := preload("res://scenes/world/pickup.tscn")
const HERMIT_SCENE    := preload("res://scenes/world/hermit.tscn")
const SERVITOR_SCENE  := preload("res://scenes/enemies/servitor.tscn")
const FLAG_SCENE      := preload("res://scenes/world/attack_flag.tscn")
const WILDLIFE_SCENE  := preload("res://scenes/world/wildlife.tscn")
const WALL_SCENE      := preload("res://scenes/world/wall.tscn")

const PLANET_NAME := "earth"

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
# Seeded per run+planet so the layout is stable across visits (EP-15)
var _layout_rng := RandomNumberGenerator.new()

func _ready() -> void:
	add_to_group("world")
	spawn_point_right = $SpawnRight
	_sky_rect = $ParallaxBackground/SkyLayer/SkyRect
	_sun_disc = $SkyUI/SunDisc
	if GameState.travel_mode:
		GameState.travel_mode = false
	else:
		GameState.new_run()
	GameState.current_planet = PLANET_NAME
	GameState.encampment_x = -100.0
	GameState.dual_front = false
	GameState.portal_active = not GameState.planets_cleared.get(PLANET_NAME, false)
	GameState.portal_broken.connect(_on_portal_broken)
	_layout_rng.seed = hash(PLANET_NAME) + GameState.current_run * 7919
	ParallaxLoader.build($ParallaxBackground, PLANET_NAME)
	_jitter_layout()
	_spawn_trees()
	_spawn_world_objects()
	_spawn_initial_caches()
	_restore_planet_state()
	_start_day()

# EP-15: shuffle authored positions within bands each run. Same seed per
# run+planet, so returning to a planet finds the same layout.
func _jitter_layout() -> void:
	for site: Node in get_tree().get_nodes_in_group("build_sites"):
		var sn: Node2D = site as Node2D
		if sn:
			sn.global_position.x += _layout_rng.randf_range(-18.0, 18.0)
	for f: Node in get_tree().get_nodes_in_group("frame_npc"):
		var fn: Node2D = f as Node2D
		if fn:
			fn.global_position.x += _layout_rng.randf_range(-25.0, 25.0)

func _process(delta: float) -> void:
	match _phase:
		Phase.DAY:   _process_day(delta)
		Phase.DUSK:  _process_dusk(delta)
		Phase.NIGHT: _process_night(delta)
		Phase.DAWN:  _process_dawn(delta)

# ── DAY ────────────────────────────────────────────────────────────────────────

func _start_day() -> void:
	if not GameState.portal_active:
		GameState.planets_cleared[PLANET_NAME] = true
		if GameState.all_planets_cleared():
			GameState.trigger_victory()
			return
		# This planet is cleared — peaceful days continue; leave by ship
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
	# Early dawn: field cleared before all spawns finished. The portal
	# Servitor is a permanent resident — don't let it hold the night open.
	if _night_spawned > 0 and _non_boss_enemy_count() == 0:
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

func _non_boss_enemy_count() -> int:
	var count: int = 0
	for e: Node in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(e) and not e.is_in_group("bosses"):
			count += 1
	return count

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
	GameState.portal_active = false
	var count: int = maxi(COUNTERATTACK_MIN, mini(3 + (GameState.day_number - 1) * 2, MAX_WAVE_SIZE))
	_spawn_dreg_pack(count)
	_transition_sky(COLOR_SKY_BLOOD, 1.5)

# ── PLANET STATE (EP-07 away simulation) ─────────────────────────────────────

func save_planet_state() -> void:
	var walls: Array = []
	for wall: Node in get_tree().get_nodes_in_group("walls"):
		var wn: Node2D = wall as Node2D
		if wn and is_instance_valid(wn):
			walls.append({"x": wn.global_position.x, "hp": int(wn.get("_hp"))})
	var towers: Array = []
	for t: Node in get_tree().get_nodes_in_group("towers"):
		var tn: Node2D = t as Node2D
		if tn and is_instance_valid(tn) and bool(tn.get("_built")):
			towers.append({"x": tn.global_position.x, "hp": int(tn.get("_hp")), "special": String(tn.get("special"))})
	var workers: Array = []
	for f: Node in get_tree().get_nodes_in_group("frame_npc"):
		if f.has_method("worker_role"):
			var role: String = f.call("worker_role")
			if role != "":
				workers.append(role)
	GameState.planet_states[PLANET_NAME] = {
		"departed_day": GameState.day_number,
		"walls": walls,
		"towers": towers,
		"workers": workers,
	}

func _restore_planet_state() -> void:
	if not GameState.planet_states.has(PLANET_NAME):
		return
	var st: Dictionary = GameState.planet_states[PLANET_NAME]
	GameState.planet_states.erase(PLANET_NAME)
	_simulate_away_nights(st)
	# Rebuild surviving walls; consume the build site standing at each spot
	for w: Dictionary in st["walls"]:
		for site: Node in get_tree().get_nodes_in_group("build_sites"):
			var sn: Node2D = site as Node2D
			if sn and is_instance_valid(sn) and absf(sn.global_position.x - float(w["x"])) < 8.0:
				sn.queue_free()
		var wall: Node2D = WALL_SCENE.instantiate() as Node2D
		wall.set("_hp", int(w["hp"]))
		wall.global_position = Vector2(float(w["x"]), 148.0)
		add_child(wall)
	# Rebuild surviving towers onto the pre-placed scaffolds
	for t: Dictionary in st["towers"]:
		for tower: Node in get_tree().get_nodes_in_group("towers"):
			var tn: Node2D = tower as Node2D
			if tn and is_instance_valid(tn) and absf(tn.global_position.x - float(t["x"])) < 8.0:
				if tn.has_method("restore"):
					tn.call("restore", int(t["hp"]))
				var sp: String = String(t.get("special", ""))
				if sp != "" and tn.has_method("convert_special"):
					tn.call("convert_special", sp)
	# Surviving workers wake straight into their old roles
	for role: String in st["workers"]:
		for f: Node in get_tree().get_nodes_in_group("frame_npc"):
			if int(f.get("state")) == 0 and f.has_method("restore_role"):  # 0 = DORMANT
				f.call("restore_role", role)
				break

# While the Speaker is away, each night runs on paper:
# capacity = redjacks*3 + walls*2. A night that exceeds it costs the
# outermost wall; with no walls left, redjacks fall, then workers.
func _simulate_away_nights(st: Dictionary) -> void:
	if GameState.planets_cleared.get(PLANET_NAME, false):
		return
	var nights: int = maxi(GameState.day_number - int(st["departed_day"]), 0)
	var walls: Array = st["walls"]
	var workers: Array = st["workers"]
	var enc: float = GameState.encampment_x
	for i in nights:
		var day: int = int(st["departed_day"]) + i + 1
		var enemies: int = mini(3 + (day - 1) * 2, MAX_WAVE_SIZE)
		var redjacks: int = workers.count("redjack")
		var capacity: int = redjacks * 3 + walls.size() * 2
		if enemies <= capacity:
			continue
		if not walls.is_empty():
			walls.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
				return absf(float(a["x"]) - enc) > absf(float(b["x"]) - enc))
			walls.pop_front()  # outermost wall falls
		elif redjacks > 0:
			workers.erase("redjack")
		elif not workers.is_empty():
			workers.pop_back()

# ── WORLD SETUP ───────────────────────────────────────────────────────────────

func _spawn_trees() -> void:
	for x: float in TREE_POSITIONS:
		var tree: Node2D = TREE_SCENE.instantiate() as Node2D
		tree.position = Vector2(x + _layout_rng.randf_range(-25.0, 25.0), 148.0)
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

	# Sundance waits in a firelit hollow past the tree line (EP-08)
	var shrine: Node2D = SHRINE_SCENE.instantiate() as Node2D
	shrine.position = Vector2(560.0, 148.0)
	add_child(shrine)

	# world-secret shards: one near the wreck, one deep in the field
	for x: float in [-330.0, 685.0]:
		var shard: Area2D = PICKUP_SCENE.instantiate() as Area2D
		shard.set("kind", "shard")
		shard.position = Vector2(x, 143.0)
		add_child(shard)

	# ADU-8 the Gunsmith waits deep in the field (EP-13) — once per run
	if not GameState.used_hermits.has("gunsmith"):
		var hermit: Node2D = HERMIT_SCENE.instantiate() as Node2D
		hermit.set("kind", "gunsmith")
		hermit.position = Vector2(700.0, 148.0)
		add_child(hermit)

# ── SPAWNING ──────────────────────────────────────────────────────────────────

# Day wanderers belong OUTSIDE your borders - never behind the walls
func _day_frontier(base: float) -> float:
	var frontier: float = base
	for wall: Node in get_tree().get_nodes_in_group("walls"):
		var wn: Node2D = wall as Node2D
		if wn and is_instance_valid(wn):
			frontier = maxf(frontier, wn.global_position.x + 40.0)
	return frontier

func _spawn_day_dregs() -> void:
	var day: int = GameState.day_number
	var count: int = DAY_DREG_COUNT + (1 if day >= 3 else 0) + (1 if day >= 5 else 0)
	var min_x: float = _day_frontier(DAY_DREG_MIN_X)
	if min_x >= DAY_DREG_MAX_X - 20.0:
		return  # walls own the whole field
	for i in count:
		var dreg: CharacterBody2D = DREG_SCENE.instantiate() as CharacterBody2D
		dreg.set("_start_feral", false)
		dreg.set("wander_left", min_x)
		dreg.global_position = Vector2(randf_range(min_x, DAY_DREG_MAX_X), 136.0)
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
	# the hour lands on the whole world, not just the sky (Kingdom rule)
	ParallaxLoader.tint(get_tree(), target, duration)

# ── DEBUG ─────────────────────────────────────────────────────────────────────

func debug_spawn_dreg() -> void:
	var player: Node = get_tree().get_first_node_in_group("player")
	var dreg: CharacterBody2D = DREG_SCENE.instantiate() as CharacterBody2D
	dreg.global_position = player.global_position + Vector2(50.0, 0.0) if player else Vector2(100.0, 135.0)
	add_child(dreg)

func debug_force_dusk() -> void:
	_day_timer = 0.0
