extends Node2D

# Cosmodrome — planet 2 (EP-14). Still Fallen, but the encampment sits in the
# middle and night waves attack from BOTH sides. One new system per world.
# Two portals (one per side); the planet is cleared when both are down.

const DREG_SCENE      := preload("res://scenes/enemies/dreg.tscn")
const VANDAL_SCENE    := preload("res://scenes/enemies/vandal.tscn")
const CACHE_SCENE     := preload("res://scenes/world/glimmer_cache.tscn")
const FRAME_SCENE     := preload("res://scenes/world/guardian.tscn")
const TREE_SCENE      := preload("res://scenes/world/tree.tscn")
const SHIP_SCENE      := preload("res://scenes/world/ship.tscn")
const BEACON_SCENE    := preload("res://scenes/world/beacon.tscn")
const PORTAL_SCENE    := preload("res://scenes/world/portal.tscn")
const FLAG_SCENE      := preload("res://scenes/world/attack_flag.tscn")
const WILDLIFE_SCENE  := preload("res://scenes/world/wildlife.tscn")
const WALL_SCENE      := preload("res://scenes/world/wall.tscn")
const FOUNDRY_SCENE   := preload("res://scenes/world/foundry.tscn")
const SERVITOR_SCENE  := preload("res://scenes/enemies/servitor.tscn")
const HERMIT_SCENE    := preload("res://scenes/world/hermit.tscn")

const PLANET_NAME := "cosmodrome"

const MAX_DORMANT_FRAMES := 6
const FRAME_SPAWN_XS: Array[float] = [-460.0, -310.0, -190.0, 195.0, 320.0, 470.0]
const TREE_POSITIONS: Array[float] = [-620.0, -480.0, -370.0, 380.0, 500.0, 640.0,
	-760.0, -900.0, 760.0, 900.0]

const COLOR_SKY_DAY   := Color(0.45, 0.44, 0.48, 1)   # Cosmodrome grey-rust
const COLOR_SKY_DUSK  := Color(0.52, 0.30, 0.16, 1)
const COLOR_SKY_NIGHT := Color(0.07, 0.07, 0.15, 1)
const COLOR_SKY_BLOOD := Color(0.45, 0.08, 0.10, 1)

const DAY_DURATION_BASE := 120.0
const DAY_DURATION_DEC  := 2.0
const DAY_DURATION_MIN  := 90.0
const DUSK_DURATION     := 12.0
const MAX_WAVE_SIZE     := 16   # split across two fronts
const DAWN_DURATION     := 5.5
const NIGHT_WAVE_TIMEOUT := 35.0

const SPIKE_FIRST_DAY      := 5
const SPIKE_INTERVAL       := 5
const SPIKE_MULTIPLIER     := 2.0
const QUIET_NIGHT_DURATION := 10.0
const COUNTERATTACK_MIN    := 6

const EXIT_RIGHT := 1150.0
const EXIT_LEFT  := -1150.0

enum Phase { DAY, DUSK, NIGHT, DAWN }

var spawn_point_right: Marker2D
var spawn_point_left: Marker2D
var _sky_rect: ColorRect
var _sun_disc: TextureRect

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
var _clear_countdown: float = -1.0
var _next_spawn_side: float = 1.0
# Seeded per run+planet so the layout is stable across visits (EP-15)
var _portal_guards_today: bool = false
var _layout_rng := RandomNumberGenerator.new()
var _portals_broken: int = 0

func _ready() -> void:
	add_to_group("world")
	spawn_point_right = $SpawnRight
	spawn_point_left = $SpawnLeft
	_sky_rect = $ParallaxBackground/SkyLayer/SkyRect
	_sun_disc = $SkyUI/SunDisc
	if GameState.travel_mode:
		GameState.travel_mode = false
	else:
		GameState.new_run()
	GameState.current_planet = PLANET_NAME
	GameState.encampment_x = 0.0
	GameState.dual_front = true
	GameState.portal_active = not GameState.planets_cleared.get(PLANET_NAME, false)
	GameState.portal_broken.connect(_on_portal_broken)
	_layout_rng.seed = hash(PLANET_NAME) + GameState.current_run * 7919
	ParallaxLoader.build($ParallaxBackground, PLANET_NAME)
	_scatter_decor()
	_jitter_layout()
	_spawn_trees()
	_spawn_world_objects()
	_spawn_shoreline()
	_spawn_initial_caches()
	_restore_planet_state()
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
		GameState.planets_cleared[PLANET_NAME] = true
		if GameState.all_planets_cleared():
			GameState.trigger_victory()
			return
	GameState.day_number += 1
	var day: int = GameState.day_number
	_day_duration = maxf(DAY_DURATION_MIN, DAY_DURATION_BASE - float(day - 1) * DAY_DURATION_DEC)
	_day_timer = _day_duration
	_portal_guards_today = false
	_last_dusk_seconds = -1
	_phase = Phase.DAY
	if _sun_disc:
		_sun_disc.visible = true
		_update_sun()
	_spawn_day_caches()
	_spawn_day_wildlife()
	_try_spawn_frame()
	GameState.day_started.emit(day)

func _process_day(delta: float) -> void:
	_day_timer -= delta
	_check_portal_guards()
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

# ── DUSK / NIGHT / DAWN ───────────────────────────────────────────────────────

func _start_dusk() -> void:
	_phase = Phase.DUSK
	_dusk_timer = DUSK_DURATION
	_transition_sky(COLOR_SKY_DUSK, 3.0)
	GameState.dusk_triggered.emit(GameState.day_number)

func _process_dusk(delta: float) -> void:
	_dusk_timer -= delta
	if _dusk_timer <= 0.0:
		_start_night()

func _start_night() -> void:
	_phase = Phase.NIGHT
	if _sun_disc:
		_sun_disc.visible = false
	if not GameState.portal_active:
		_trigger_dawn()
		return
	var day: int = GameState.day_number
	_quiet_this_night = _quiet_night_pending
	_quiet_night_pending = false
	if _quiet_this_night:
		_spike_this_night = false
		_night_total = 0
		_night_spawned = 0
		_spawn_timer = 0.0
		_post_spawn_timer = NIGHT_WAVE_TIMEOUT - QUIET_NIGHT_DURATION
		_transition_sky(COLOR_SKY_NIGHT, 3.0)
		return
	_spike_this_night = day >= SPIKE_FIRST_DAY and day % SPIKE_INTERVAL == 0
	_night_total = mini(4 + (day - 1) * 2, MAX_WAVE_SIZE)
	if _spike_this_night:
		_night_total = int(float(_night_total) * SPIKE_MULTIPLIER)
		_quiet_night_pending = true
	_night_spawned = 0
	_clear_countdown = -1.0
	_spawn_timer = 1.5
	_post_spawn_timer = 0.0
	GameState.wave_number = day
	GameState.wave_changed.emit(day)
	_transition_sky(COLOR_SKY_BLOOD if _spike_this_night else COLOR_SKY_NIGHT, 3.0)

func _night_pack_interval() -> float:
	return maxf(0.8, 4.5 - float(GameState.day_number) * 0.3)

func _process_night(delta: float) -> void:
	# Portal Servitors are permanent residents — count only wave enemies
	if _night_spawned > 0 and _non_boss_enemy_count() == 0:
		# field is clear — the survivors catch their breath before dawn breaks
		if _clear_countdown < 0.0:
			_clear_countdown = 12.0
		_clear_countdown -= delta
		if _clear_countdown <= 0.0:
			_clear_countdown = -1.0
			_trigger_dawn()
		return
	_clear_countdown = -1.0
	if _night_spawned < _night_total:
		_spawn_timer -= delta
		if _spawn_timer <= 0.0:
			_spawn_enemy_on_side(_next_spawn_side)
			_next_spawn_side = -_next_spawn_side  # alternate fronts
			_night_spawned += 1
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

# ── PORTALS ───────────────────────────────────────────────────────────────────

func _on_portal_broken(_faction: String) -> void:
	_portals_broken += 1
	if _portals_broken >= 2:
		GameState.portal_active = false
	# death rattle from whichever side just fell — spawn on both to be cruel
	var count: int = maxi(COUNTERATTACK_MIN, mini(4 + (GameState.day_number - 1) * 2, MAX_WAVE_SIZE))
	for i in count:
		_spawn_enemy_on_side(1.0 if i % 2 == 0 else -1.0)
	_transition_sky(COLOR_SKY_BLOOD, 1.5)

# ── WORLD SETUP ───────────────────────────────────────────────────────────────

func _jitter_layout() -> void:
	for site: Node in get_tree().get_nodes_in_group("build_sites"):
		var sn: Node2D = site as Node2D
		if sn:
			sn.global_position.x += _layout_rng.randf_range(-18.0, 18.0)

func _spawn_trees() -> void:
	# K2C copses (#50): each mark grows a cluster of 1-3 mixed-style trees
	for x: float in TREE_POSITIONS:
		for i in _layout_rng.randi_range(1, 3):
			var tree: Node2D = TREE_SCENE.instantiate() as Node2D
			var off: float = _layout_rng.randf_range(-25.0, 25.0) + float(i) * 22.0
			tree.position = Vector2(x + off, 148.0)
			add_child(tree)


# The land ends in liquid, not a cliff (#25)
func _spawn_shoreline() -> void:
	var water_n1420 := ColorRect.new()
	water_n1420.color = Color(0.14, 0.18, 0.24, 1.0)
	water_n1420.position = Vector2(-1420.0, 152.0)
	water_n1420.size = Vector2(165.0, 260.0)
	add_child(water_n1420)
	var surf_n1420 := ColorRect.new()
	surf_n1420.color = Color(0.30, 0.38, 0.48, 0.9)
	surf_n1420.position = Vector2(-1420.0, 152.0)
	surf_n1420.size = Vector2(165.0, 2.0)
	add_child(surf_n1420)
	var tw_n1420: Tween = surf_n1420.create_tween().set_loops()
	tw_n1420.tween_property(surf_n1420, "modulate:a", 0.55, 1.7).set_ease(Tween.EASE_IN_OUT)
	tw_n1420.tween_property(surf_n1420, "modulate:a", 1.0, 1.7).set_ease(Tween.EASE_IN_OUT)
	var water_1255 := ColorRect.new()
	water_1255.color = Color(0.14, 0.18, 0.24, 1.0)
	water_1255.position = Vector2(1255.0, 152.0)
	water_1255.size = Vector2(165.0, 260.0)
	add_child(water_1255)
	var surf_1255 := ColorRect.new()
	surf_1255.color = Color(0.30, 0.38, 0.48, 0.9)
	surf_1255.position = Vector2(1255.0, 152.0)
	surf_1255.size = Vector2(165.0, 2.0)
	add_child(surf_1255)
	var tw_1255: Tween = surf_1255.create_tween().set_loops()
	tw_1255.tween_property(surf_1255, "modulate:a", 0.55, 1.7).set_ease(Tween.EASE_IN_OUT)
	tw_1255.tween_property(surf_1255, "modulate:a", 1.0, 1.7).set_ease(Tween.EASE_IN_OUT)

func _spawn_world_objects() -> void:
	# The ship you landed in — leave whenever you like
	var ship: Node2D = SHIP_SCENE.instantiate() as Node2D
	ship.position = Vector2(-90.0, 142.0)
	add_child(ship)

	# the away-decay Beacon stands with the camp (#40)
	var beacon: Area2D = BEACON_SCENE.instantiate() as Area2D
	beacon.position = Vector2(-115.0, 148.0)
	add_child(beacon)

	var portal_r: Node2D = PORTAL_SCENE.instantiate() as Node2D
	portal_r.position = Vector2(880.0, 148.0)
	add_child(portal_r)

	var portal_l: Node2D = PORTAL_SCENE.instantiate() as Node2D
	portal_l.position = Vector2(-880.0, 148.0)
	add_child(portal_l)

	# Each portal has its own Servitor guardian — kill one, break one
	var serv_r: CharacterBody2D = SERVITOR_SCENE.instantiate() as CharacterBody2D
	serv_r.set("bound_portal_x", 880.0)
	serv_r.position = Vector2(830.0, 130.0)
	add_child(serv_r)

	var serv_l: CharacterBody2D = SERVITOR_SCENE.instantiate() as CharacterBody2D
	serv_l.set("bound_portal_x", -880.0)
	serv_l.position = Vector2(-830.0, 130.0)
	add_child(serv_l)

	# one charge banner per front — each plants itself at that side's outermost wall
	var flag_r: Node2D = FLAG_SCENE.instantiate() as Node2D
	flag_r.set("side", 1.0)
	flag_r.position = Vector2(220.0, 148.0)
	add_child(flag_r)

	var flag_l: Node2D = FLAG_SCENE.instantiate() as Node2D
	flag_l.set("side", -1.0)
	flag_l.position = Vector2(-220.0, 148.0)
	add_child(flag_l)

	# The cold Foundry — restore it to unlock Metal-tier materials everywhere
	var foundry: Node2D = FOUNDRY_SCENE.instantiate() as Node2D
	foundry.position = Vector2(560.0, 148.0)
	add_child(foundry)

	# The SIVA Tinker hides in the left field (EP-13) — once per run
	if not GameState.used_hermits.has("tinker"):
		var hermit: Node2D = HERMIT_SCENE.instantiate() as Node2D
		hermit.set("kind", "tinker")
		hermit.position = Vector2(-640.0, 148.0)
		add_child(hermit)

# ── SPAWNING ──────────────────────────────────────────────────────────────────

func _configure_side(enemy: CharacterBody2D, side: float) -> void:
	# side +1 = spawns right, marches left toward center camp
	enemy.set("march_dir", -side)
	enemy.set("exit_x", EXIT_RIGHT if side > 0.0 else EXIT_LEFT)

func _spawn_enemy_on_side(side: float) -> void:
	var day: int = GameState.day_number
	var scene: PackedScene = VANDAL_SCENE if (day >= 4 and randf() < 0.4) else DREG_SCENE
	var enemy: CharacterBody2D = scene.instantiate() as CharacterBody2D
	_configure_side(enemy, side)
	var marker: Marker2D = spawn_point_right if side > 0.0 else spawn_point_left
	enemy.global_position = marker.global_position
	add_child(enemy)

# Wanderers stay beyond that side's outermost wall
func _day_frontier(side: float, base: float) -> float:
	var frontier: float = base
	for wall: Node in get_tree().get_nodes_in_group("walls"):
		var wn: Node2D = wall as Node2D
		if not wn or not is_instance_valid(wn):
			continue
		if wn.global_position.x * side <= 0.0:
			continue
		if side > 0.0:
			frontier = maxf(frontier, wn.global_position.x + 40.0)
		else:
			frontier = minf(frontier, wn.global_position.x - 40.0)
	return frontier

func _spawn_day_dregs() -> void:
	var day: int = GameState.day_number
	var count: int = 2 + (1 if day >= 3 else 0) + (1 if day >= 5 else 0)
	for i in count:
		var side: float = 1.0 if i % 2 == 0 else -1.0
		var dreg: CharacterBody2D = DREG_SCENE.instantiate() as CharacterBody2D
		dreg.set("_start_feral", false)
		_configure_side(dreg, side)
		if side > 0.0:
			var min_x: float = _day_frontier(1.0, 350.0)
			if min_x >= 680.0:
				continue
			dreg.set("wander_left", min_x)
			dreg.set("wander_right", 780.0)
			dreg.global_position = Vector2(randf_range(min_x, 700.0), 136.0)
		else:
			var max_x: float = _day_frontier(-1.0, -350.0)
			if max_x <= -680.0:
				continue
			dreg.set("wander_left", -780.0)
			dreg.set("wander_right", max_x)
			dreg.global_position = Vector2(randf_range(-700.0, max_x), 136.0)
		add_child(dreg)

func _spawn_day_wildlife() -> void:
	var count: int = 4
	for i in count:
		var critter: Node2D = WILDLIFE_SCENE.instantiate() as Node2D
		var side: float = 1.0 if i % 2 == 0 else -1.0
		critter.position = Vector2(side * randf_range(200.0, 650.0), 147.0)
		add_child(critter)

func _spawn_initial_caches() -> void:
	var positions: Array[float] = [-260.0, -180.0, -120.0, -60.0, 60.0, 120.0, 180.0, 260.0]
	for x: float in positions:
		_spawn_cache_at(x)

func _spawn_day_caches() -> void:
	if GameState.day_number <= 1:
		return
	var player: Node = get_tree().get_first_node_in_group("player")
	var center_x: float = player.global_position.x if player else 0.0
	for i: int in 3:
		_spawn_cache_at(center_x + randf_range(-175.0, 175.0))

func _spawn_cache_at(x: float) -> void:
	# clamped to dry land (#50) — no more glimmer bobbing in the water
	var cache: Node2D = CACHE_SCENE.instantiate() as Node2D
	cache.position = Vector2(clampf(x, -1180.0, 1180.0), 146.0)
	cache.set("glimmer_amount", randi_range(40, 120))
	add_child(cache)

func _try_spawn_frame() -> void:
	var dormant: int = 0
	for f: Node in get_tree().get_nodes_in_group("frame_npc"):
		if (f.get("state") as int) == 0:
			dormant += 1
	if dormant >= MAX_DORMANT_FRAMES:
		return
	var spawn_x: float = _free_camp_x()
	if is_nan(spawn_x):
		return  # every camp is at capacity
	var frame: CharacterBody2D = FRAME_SCENE.instantiate() as CharacterBody2D
	frame.global_position = Vector2(spawn_x + float(_camp_occupancy(spawn_x)) * 14.0, 136.0)
	add_child(frame)

# Lockers are landmarks (Kingdom vagrant camps): each camp holds up to 2
# frames and only refills when below capacity.
const CAMP_CAPACITY := 2

func _camp_occupancy(spawn_x: float) -> int:
	var count: int = 0
	for f: Node in get_tree().get_nodes_in_group("frame_npc"):
		var fn: Node2D = f as Node2D
		if fn and is_instance_valid(fn) and absf(fn.global_position.x - spawn_x) < 26.0:
			count += 1
	return count

func _free_camp_x() -> float:
	for spawn_x: float in FRAME_SPAWN_XS:
		if _camp_occupancy(spawn_x) < CAMP_CAPACITY:
			return spawn_x
	return NAN


# ── PLANET STATE (EP-07 away simulation — same rules as Earth) ────────────────

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
		"portals_broken": _portals_broken,
	}

func _restore_planet_state() -> void:
	if not GameState.planet_states.has(PLANET_NAME):
		return
	var st: Dictionary = GameState.planet_states[PLANET_NAME]
	GameState.planet_states.erase(PLANET_NAME)
	_portals_broken = int(st.get("portals_broken", 0))
	_simulate_away_nights(st)
	for w: Dictionary in st["walls"]:
		for site: Node in get_tree().get_nodes_in_group("build_sites"):
			var sn: Node2D = site as Node2D
			if sn and is_instance_valid(sn) and absf(sn.global_position.x - float(w["x"])) < 8.0:
				sn.queue_free()
		var wall: Node2D = WALL_SCENE.instantiate() as Node2D
		wall.set("_hp", int(w["hp"]))
		wall.global_position = Vector2(float(w["x"]), 148.0)
		add_child(wall)
	for t: Dictionary in st["towers"]:
		for tower: Node in get_tree().get_nodes_in_group("towers"):
			var tn: Node2D = tower as Node2D
			if tn and is_instance_valid(tn) and absf(tn.global_position.x - float(t["x"])) < 8.0:
				if tn.has_method("restore"):
					tn.call("restore", int(t["hp"]))
				var sp: String = String(t.get("special", ""))
				if sp != "" and tn.has_method("convert_special"):
					tn.call("convert_special", sp)
	for role: String in st["workers"]:
		for f: Node in get_tree().get_nodes_in_group("frame_npc"):
			if int(f.get("state")) == 0 and f.has_method("restore_role"):
				f.call("restore_role", role)
				break

func _simulate_away_nights(st: Dictionary) -> void:
	if GameState.planets_cleared.get(PLANET_NAME, false):
		return
	# The Beacon holds the line while you're away (#40)
	var protected: int = GameState.beacon_nights(PLANET_NAME)
	var nights: int = maxi(GameState.day_number - int(st["departed_day"]) - protected, 0)
	var walls: Array = st["walls"]
	var workers: Array = st["workers"]
	var enc: float = 0.0
	for i in nights:
		var day: int = int(st["departed_day"]) + i + 1
		var enemies: int = mini(4 + (day - 1) * 2, MAX_WAVE_SIZE)
		var redjacks: int = workers.count("redjack")
		var capacity: int = redjacks * 3 + walls.size() * 2
		if enemies <= capacity:
			continue
		if not walls.is_empty():
			walls.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
				return absf(float(a["x"]) - enc) > absf(float(b["x"]) - enc))
			walls.pop_front()
		elif redjacks > 0:
			workers.erase("redjack")
		elif not workers.is_empty():
			workers.pop_back()

# ── HELPERS ───────────────────────────────────────────────────────────────────

func _transition_sky(target: Color, duration: float) -> void:
	if not _sky_rect:
		return
	var tinted: Color = Color(target.r, target.g, target.b, 0.55)
	var tween: Tween = create_tween()
	tween.tween_property(_sky_rect, "color", tinted, duration).set_ease(Tween.EASE_IN_OUT)
	# the hour lands on the whole world, not just the sky (Kingdom rule)
	ParallaxLoader.tint(get_tree(), target, duration)

# ── DEBUG (shared F1 panel) ───────────────────────────────────────────────────


# Wandering day enemies are gone (#50) — but walk up to a portal in
# daylight and it answers. Guards spawn once per day, and they aggro.
func _check_portal_guards() -> void:
	if _portal_guards_today or not GameState.portal_active:
		return
	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if not player:
		return
	for px_x: float in [880.0, -880.0]:
		if absf(player.global_position.x - px_x) < 200.0:
			_portal_guards_today = true
			for i in 2:
				debug_spawn_dreg()
			return

func debug_spawn_dreg() -> void:
	var player: Node = get_tree().get_first_node_in_group("player")
	var dreg: CharacterBody2D = DREG_SCENE.instantiate() as CharacterBody2D
	_configure_side(dreg, 1.0)
	dreg.global_position = player.global_position + Vector2(50.0, 0.0) if player else Vector2(100.0, 135.0)
	add_child(dreg)

func debug_force_dusk() -> void:
	_day_timer = 0.0

# World dressing (#50) — see scripts/utils/decor.gd
func _scatter_decor() -> void:
	var paths: Array[String] = [
		"res://assets/sprites/structures/pro_bush.png",
		"res://assets/sprites/structures/pro_tuft.png",
		"res://assets/sprites/structures/pro_mound.png",
	]
	Decor.scatter(self, paths, 30, _layout_rng, 170.0, 1230.0, 5.0, 12.0, true)
