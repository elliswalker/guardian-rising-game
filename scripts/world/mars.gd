extends Node2D

# Mars — planet 4. Cabal siege warfare: enemies don't march in from the
# horizon, they arrive in DROP PODS that slam into the mid-field — on BOTH
# flanks now (#30). Distance buys you nothing here — the war lands on top
# of you, from two launch sites at once.
# Kill each Incendiary Colossus at its launch site to end the siege.
# The Osiris shrine grants Well of Radiance.

const LEGIONARY_SCENE := preload("res://scenes/enemies/legionary.tscn")
const PSION_SCENE     := preload("res://scenes/enemies/psion.tscn")
const PHALANX_SCENE   := preload("res://scenes/enemies/phalanx.tscn")
const COLOSSUS_SCENE  := preload("res://scenes/enemies/colossus.tscn")
const CACHE_SCENE     := preload("res://scenes/world/glimmer_cache.tscn")
const FRAME_SCENE     := preload("res://scenes/world/guardian.tscn")
const SHIP_SCENE      := preload("res://scenes/world/ship.tscn")
const BEACON_SCENE    := preload("res://scenes/world/beacon.tscn")
const PORTAL_SCENE    := preload("res://scenes/world/portal.tscn")
const FLAG_SCENE      := preload("res://scenes/world/attack_flag.tscn")
const WALL_SCENE      := preload("res://scenes/world/wall.tscn")
const SHRINE_SCENE    := preload("res://scenes/world/ghost_shrine.tscn")
const PICKUP_SCENE    := preload("res://scenes/world/pickup.tscn")

const PLANET_NAME := "mars"

const MAX_DORMANT_FRAMES := 6
const FRAME_SPAWN_XS: Array[float] = [-460.0, -310.0, -190.0, 195.0, 320.0, 470.0]

const EXIT_RIGHT := 1150.0
const EXIT_LEFT  := -1150.0

const COLOR_SKY_DAY   := Color(0.52, 0.34, 0.24, 1)   # dusty red
const COLOR_SKY_DUSK  := Color(0.45, 0.20, 0.12, 1)
const COLOR_SKY_NIGHT := Color(0.12, 0.06, 0.07, 1)
const COLOR_SKY_BLOOD := Color(0.45, 0.08, 0.10, 1)

const DAY_DURATION_BASE := 120.0
const DAY_DURATION_DEC  := 2.0
const DAY_DURATION_MIN  := 90.0
const DUSK_DURATION     := 12.0
const MAX_WAVE_SIZE     := 16
const DAWN_DURATION     := 5.5
const NIGHT_WAVE_TIMEOUT := 35.0

const SPIKE_FIRST_DAY      := 5
const SPIKE_INTERVAL       := 5
const SPIKE_MULTIPLIER     := 2.0
const QUIET_NIGHT_DURATION := 10.0
const COUNTERATTACK_MIN    := 7

# Drop-pod siege: pods land INSIDE the field, 2-3 enemies each.
# X bounds are magnitudes — mirrored across both flanks.
const POD_MIN_X    := 430.0
const POD_MAX_X    := 860.0
const POD_SIZE_MIN := 2
const POD_SIZE_MAX := 3

enum Phase { DAY, DUSK, NIGHT, DAWN }

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
var _clear_countdown: float = -1.0
var _next_spawn_side: float = 1.0
var _portals_broken: int = 0
var _portal_guards_today: bool = false
var _layout_rng := RandomNumberGenerator.new()

func _ready() -> void:
	add_to_group("world")
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
	_jitter_layout()
	_spawn_world_objects()
	_spawn_shoreline()
	_spawn_initial_caches()
	_restore_planet_state()
	_start_day()

func _jitter_layout() -> void:
	for site: Node in get_tree().get_nodes_in_group("build_sites"):
		var sn: Node2D = site as Node2D
		if sn:
			sn.global_position.x += _layout_rng.randf_range(-18.0, 18.0)

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
	_try_spawn_frame()
	GameState.day_started.emit(day)

# Psion scavengers prowl both flanks by day, racing your sweeperbots for
# caches. They don't fight until dusk — but every cache they grab is yours lost.
func _spawn_day_scavengers() -> void:
	if GameState.day_number <= 1:
		return
	for i in 2:
		var side: float = 1.0 if i % 2 == 0 else -1.0
		var psion: CharacterBody2D = PSION_SCENE.instantiate() as CharacterBody2D
		psion.set("day_scavenger", true)
		_configure_side(psion, side)
		if side > 0.0:
			var min_x: float = _frontier(1.0, 350.0)
			if min_x >= 700.0:
				continue  # walls own that flank
			psion.global_position = Vector2(randf_range(min_x, 720.0), 136.0)
		else:
			var max_x: float = _frontier(-1.0, -350.0)
			if max_x <= -700.0:
				continue
			psion.global_position = Vector2(randf_range(-720.0, max_x), 136.0)
		add_child(psion)

# Scavengers stay beyond that side's outermost wall
func _frontier(side: float, base: float) -> float:
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

func _pod_interval() -> float:
	# pods carry 2-3 enemies, so the cadence is slower than a walk-in stream
	return maxf(3.0, 9.0 - float(GameState.day_number) * 0.5)

func _process_night(delta: float) -> void:
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
			var pod_size: int = mini(randi_range(POD_SIZE_MIN, POD_SIZE_MAX), _night_total - _night_spawned)
			_drop_pod(pod_size, _next_spawn_side)
			_next_spawn_side = -_next_spawn_side  # alternate flanks
			_night_spawned += pod_size
			_spawn_timer = _pod_interval()
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
		if enemy.is_in_group("bosses"):
			continue  # the Colossus holds the launch site
		if enemy.has_method("retreat"):
			enemy.retreat()
	GameState.dawn_triggered.emit(GameState.day_number)

func _process_dawn(delta: float) -> void:
	_dawn_timer -= delta
	if _dawn_timer <= 0.0:
		_start_day()

# ── PORTAL ────────────────────────────────────────────────────────────────────

func _on_portal_broken(_faction: String) -> void:
	_portals_broken += 1
	if _portals_broken >= 2:
		GameState.portal_active = false
	# the falling launch site empties its last pods — on both flanks
	var count: int = maxi(COUNTERATTACK_MIN, mini(4 + (GameState.day_number - 1) * 2, MAX_WAVE_SIZE))
	var side: float = 1.0
	while count > 0:
		var pod_size: int = mini(randi_range(POD_SIZE_MIN, POD_SIZE_MAX), count)
		_drop_pod(pod_size, side)
		side = -side
		count -= pod_size
	_transition_sky(COLOR_SKY_BLOOD, 1.5)

# ── DROP PODS ─────────────────────────────────────────────────────────────────

func _configure_side(enemy: CharacterBody2D, side: float) -> void:
	# side +1 = right flank, marches left toward center camp
	enemy.set("march_dir", -side)
	enemy.set("exit_x", EXIT_RIGHT if side > 0.0 else EXIT_LEFT)

func _drop_pod(count: int, side: float) -> void:
	var pod_x: float = _pick_pod_x(side)
	# the pod itself: a slab that falls, slams, and burns out
	var pod: ColorRect = ColorRect.new()
	pod.size = Vector2(16, 22)
	pod.color = Color(0.40, 0.28, 0.28, 1.0)
	pod.position = Vector2(pod_x - 8.0, -120.0)
	add_child(pod)
	var tween: Tween = pod.create_tween()
	tween.tween_property(pod, "position:y", 128.0, 0.55).set_ease(Tween.EASE_IN)
	tween.tween_callback(func() -> void:
		Sound.play("thunk", 2.0, 0.5)
		_disgorge_pod(pod_x, count)
	)
	tween.tween_interval(2.0)
	tween.tween_property(pod, "modulate:a", 0.0, 4.0)
	tween.tween_callback(pod.queue_free)  # no ghost pods littering the field

func _pick_pod_x(side: float) -> float:
	# pods aim inside that flank but respect its outermost wall — the siege
	# lands in your yard, not inside your living room
	if side > 0.0:
		var outer_r: float = POD_MIN_X
		for wall: Node in get_tree().get_nodes_in_group("walls"):
			var wn: Node2D = wall as Node2D
			if wn and is_instance_valid(wn) and wn.global_position.x > 0.0:
				outer_r = maxf(outer_r, wn.global_position.x + 30.0)
		return randf_range(minf(outer_r, POD_MAX_X - 20.0), POD_MAX_X)
	var outer_l: float = -POD_MIN_X
	for wall: Node in get_tree().get_nodes_in_group("walls"):
		var wn: Node2D = wall as Node2D
		if wn and is_instance_valid(wn) and wn.global_position.x < 0.0:
			outer_l = minf(outer_l, wn.global_position.x - 30.0)
	return randf_range(-POD_MAX_X, maxf(outer_l, -POD_MAX_X + 20.0))

func _disgorge_pod(pod_x: float, count: int) -> void:
	var day: int = GameState.day_number
	for i in count:
		var scene: PackedScene = LEGIONARY_SCENE
		var roll: float = randf()
		if day >= 4 and roll < 0.25:
			scene = PHALANX_SCENE
		elif day >= 2 and roll < 0.55:
			scene = PSION_SCENE
		var enemy: CharacterBody2D = scene.instantiate() as CharacterBody2D
		_configure_side(enemy, 1.0 if pod_x > 0.0 else -1.0)
		enemy.global_position = Vector2(pod_x + float(i) * 12.0 - 6.0, 136.0)
		add_child(enemy)

# ── WORLD SETUP ───────────────────────────────────────────────────────────────


# The land ends in liquid at BOTH ends now (#25, #30)
func _spawn_shoreline() -> void:
	for x0: float in [-1420.0, 1255.0]:
		var water := ColorRect.new()
		water.color = Color(0.30, 0.17, 0.11, 1.0)
		water.position = Vector2(x0, 152.0)
		water.size = Vector2(165.0, 260.0)
		add_child(water)
		var surf := ColorRect.new()
		surf.color = Color(0.50, 0.31, 0.19, 0.9)
		surf.position = Vector2(x0, 152.0)
		surf.size = Vector2(165.0, 2.0)
		add_child(surf)
		var tw: Tween = surf.create_tween().set_loops()
		tw.tween_property(surf, "modulate:a", 0.55, 1.7).set_ease(Tween.EASE_IN_OUT)
		tw.tween_property(surf, "modulate:a", 1.0, 1.7).set_ease(Tween.EASE_IN_OUT)

func _spawn_world_objects() -> void:
	var ship: Node2D = SHIP_SCENE.instantiate() as Node2D
	ship.position = Vector2(-90.0, 142.0)
	add_child(ship)

	# the away-decay Beacon stands with the camp (#40)
	var beacon: Area2D = BEACON_SCENE.instantiate() as Area2D
	beacon.position = Vector2(-115.0, 148.0)
	add_child(beacon)

	# TWO drop-pod launch sites — Mars's portals, one per flank
	var site_r: Node2D = PORTAL_SCENE.instantiate() as Node2D
	site_r.position = Vector2(880.0, 148.0)
	site_r.set("faction", "cabal")
	add_child(site_r)

	var site_l: Node2D = PORTAL_SCENE.instantiate() as Node2D
	site_l.position = Vector2(-880.0, 148.0)
	site_l.set("faction", "cabal")
	add_child(site_l)

	# an Incendiary Colossus guards each launch site
	var col_r: CharacterBody2D = COLOSSUS_SCENE.instantiate() as CharacterBody2D
	col_r.set("bound_portal_x", 880.0)
	col_r.position = Vector2(830.0, 132.0)
	add_child(col_r)

	var col_l: CharacterBody2D = COLOSSUS_SCENE.instantiate() as CharacterBody2D
	col_l.set("bound_portal_x", -880.0)
	col_l.position = Vector2(-830.0, 132.0)
	add_child(col_l)

	# one charge banner per front — each plants itself at that side's outermost wall
	var flag_r: Node2D = FLAG_SCENE.instantiate() as Node2D
	flag_r.set("side", 1.0)
	flag_r.position = Vector2(220.0, 148.0)
	add_child(flag_r)

	var flag_l: Node2D = FLAG_SCENE.instantiate() as Node2D
	flag_l.set("side", -1.0)
	flag_l.position = Vector2(-220.0, 148.0)
	add_child(flag_l)

	# Seguira waits in the dunes — Osiris's Ghost (Solar / Well of Radiance)
	var shrine: Area2D = SHRINE_SCENE.instantiate() as Area2D
	shrine.set("super_name", "well")
	shrine.set("ghost_name", "Seguira")
	shrine.set("super_label", "Well of Radiance")
	shrine.set("shard_cost", 5)
	shrine.set("glimmer_cost", 200)
	shrine.set("ember_color", Color(1.0, 0.75, 0.30))
	shrine.position = Vector2(455.0, 148.0)
	add_child(shrine)

	# world-secret shards buried at both ends of the war zone
	for x: float in [-1050.0, 1050.0]:
		var shard: Area2D = PICKUP_SCENE.instantiate() as Area2D
		shard.set("kind", "shard")
		shard.position = Vector2(x, 143.0)
		add_child(shard)

func _spawn_initial_caches() -> void:
	var positions: Array[float] = [-320.0, -245.0, -175.0, -110.0, -45.0, 45.0, 110.0, 175.0, 245.0, 320.0]
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
	var cache: Node2D = CACHE_SCENE.instantiate() as Node2D
	cache.position = Vector2(x, 146.0)
	cache.set("glimmer_amount", randi_range(45, 125))
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
	var enc: float = GameState.encampment_x
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
	var leg: CharacterBody2D = LEGIONARY_SCENE.instantiate() as CharacterBody2D
	_configure_side(leg, 1.0)
	leg.global_position = player.global_position + Vector2(50.0, 0.0) if player else Vector2(100.0, 135.0)
	add_child(leg)

func debug_force_dusk() -> void:
	_day_timer = 0.0
