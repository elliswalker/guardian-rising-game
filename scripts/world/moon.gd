extends Node2D

# The Moon — planet 3. Hive territory: it is ALWAYS night here.
# The loop keeps its shape, but the "day" is a dark lull under a distant
# Earth, the dusk is Omnigul's warning shriek, and the surges are thrall
# floods. Kill the Wizard at the tomb to collapse the soul lantern.
# The Ascendant Forge here unlocks Shield-tier (metal) walls.

const THRALL_SCENE    := preload("res://scenes/enemies/thrall.tscn")
const WIZARD_SCENE    := preload("res://scenes/enemies/wizard.tscn")
const CACHE_SCENE     := preload("res://scenes/world/glimmer_cache.tscn")
const FRAME_SCENE     := preload("res://scenes/world/guardian.tscn")
const SHIP_SCENE      := preload("res://scenes/world/ship.tscn")
const PORTAL_SCENE    := preload("res://scenes/world/portal.tscn")
const FLAG_SCENE      := preload("res://scenes/world/attack_flag.tscn")
const WALL_SCENE      := preload("res://scenes/world/wall.tscn")
const FOUNDRY_SCENE   := preload("res://scenes/world/foundry.tscn")
const SHRINE_SCENE    := preload("res://scenes/world/ghost_shrine.tscn")
const PICKUP_SCENE    := preload("res://scenes/world/pickup.tscn")

const PLANET_NAME := "moon"

const MAX_DORMANT_FRAMES := 6
const FRAME_SPAWN_XS: Array[float] = [195.0, 260.0, 330.0, 410.0, 480.0, 550.0]

# Always night — even the lull is dark. The Earth hangs where the sun would be.
const COLOR_SKY_LULL    := Color(0.10, 0.10, 0.20, 1)
const COLOR_SKY_WARNING := Color(0.14, 0.07, 0.16, 1)
const COLOR_SKY_SURGE   := Color(0.05, 0.04, 0.10, 1)
const COLOR_SKY_BLOOD   := Color(0.40, 0.06, 0.10, 1)

const LULL_DURATION    := 75.0  # fixed — the Moon's pressure is the surges, not the clock
const WARNING_DURATION := 8.0
const MAX_WAVE_SIZE    := 18
const RESPITE_DURATION := 5.0
const SURGE_TIMEOUT    := 35.0

const SPIKE_FIRST_DAY      := 5
const SPIKE_INTERVAL       := 5
const SPIKE_MULTIPLIER     := 2.0
const QUIET_SURGE_DURATION := 10.0
const COUNTERATTACK_MIN    := 8

enum Phase { LULL, WARNING, SURGE, RESPITE }

var spawn_point_right: Marker2D
var _sky_rect: ColorRect
var _earth_disc: ColorRect

var _phase: Phase = Phase.LULL
var _lull_timer: float = 0.0
var _warning_timer: float = 0.0
var _respite_timer: float = 0.0
var _surge_total: int = 0
var _surge_spawned: int = 0
var _spawn_timer: float = 0.0
var _post_spawn_timer: float = 0.0
var _spike_this_surge: bool = false
var _quiet_surge_pending: bool = false
var _quiet_this_surge: bool = false
var _last_lull_seconds: int = -1
var _layout_rng := RandomNumberGenerator.new()

func _ready() -> void:
	add_to_group("world")
	spawn_point_right = $SpawnRight
	_sky_rect = $ParallaxBackground/SkyLayer/SkyRect
	_earth_disc = $SkyUI/EarthDisc
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
	_spawn_world_objects()
	_spawn_shoreline()
	_spawn_initial_caches()
	_restore_planet_state()
	_start_lull()

func _jitter_layout() -> void:
	for site: Node in get_tree().get_nodes_in_group("build_sites"):
		var sn: Node2D = site as Node2D
		if sn:
			sn.global_position.x += _layout_rng.randf_range(-18.0, 18.0)

func _process(delta: float) -> void:
	match _phase:
		Phase.LULL:    _process_lull(delta)
		Phase.WARNING: _process_warning(delta)
		Phase.SURGE:   _process_surge(delta)
		Phase.RESPITE: _process_respite(delta)

# ── LULL (the Moon's "day": dark, calm, build) ────────────────────────────────

func _start_lull() -> void:
	if not GameState.portal_active:
		GameState.planets_cleared[PLANET_NAME] = true
		if GameState.all_planets_cleared():
			GameState.trigger_victory()
			return
	GameState.day_number += 1
	_lull_timer = LULL_DURATION
	_phase = Phase.LULL
	_transition_sky(COLOR_SKY_LULL, 3.5)
	_spawn_lull_caches()
	_spawn_lull_wanderers()
	_try_spawn_frame()
	GameState.day_started.emit(GameState.day_number)

# A few thralls shuffle in the dark during the lull — the Moon is never
# truly empty. They turn feral when the warning shriek sounds.
func _spawn_lull_wanderers() -> void:
	if GameState.day_number <= 1:
		return
	var min_x: float = 380.0
	for wall: Node in get_tree().get_nodes_in_group("walls"):
		var wn: Node2D = wall as Node2D
		if wn and is_instance_valid(wn):
			min_x = maxf(min_x, wn.global_position.x + 40.0)
	if min_x >= 680.0:
		return  # walls own the field
	for i in 2:
		var thrall: CharacterBody2D = THRALL_SCENE.instantiate() as CharacterBody2D
		thrall.set("_start_feral", false)
		thrall.set("wander_left", min_x)
		thrall.set("wander_right", 760.0)
		thrall.global_position = Vector2(randf_range(min_x, 700.0), 136.0)
		add_child(thrall)

func _process_lull(delta: float) -> void:
	_lull_timer -= delta
	var secs: int = maxi(0, ceili(_lull_timer))
	if secs != _last_lull_seconds:
		_last_lull_seconds = secs
		GameState.dusk_timer_updated.emit(secs)
	if _lull_timer <= 0.0:
		_last_lull_seconds = -1
		_start_warning()

# ── WARNING (the shriek before the flood) ─────────────────────────────────────

func _start_warning() -> void:
	_phase = Phase.WARNING
	_warning_timer = WARNING_DURATION
	_transition_sky(COLOR_SKY_WARNING, 2.0)
	Sound.play("chitter", 0.0, 0.55)  # low-pitched shriek stand-in
	GameState.dusk_triggered.emit(GameState.day_number)

func _process_warning(delta: float) -> void:
	_warning_timer -= delta
	if _warning_timer <= 0.0:
		_start_surge()

# ── SURGE (thrall flood) ──────────────────────────────────────────────────────

func _start_surge() -> void:
	_phase = Phase.SURGE
	if not GameState.portal_active:
		_trigger_respite()
		return
	var day: int = GameState.day_number
	_quiet_this_surge = _quiet_surge_pending
	_quiet_surge_pending = false
	if _quiet_this_surge:
		_spike_this_surge = false
		_surge_total = 0
		_surge_spawned = 0
		_spawn_timer = 0.0
		_post_spawn_timer = SURGE_TIMEOUT - QUIET_SURGE_DURATION
		_transition_sky(COLOR_SKY_SURGE, 3.0)
		return
	_spike_this_surge = day >= SPIKE_FIRST_DAY and day % SPIKE_INTERVAL == 0
	_surge_total = mini(5 + (day - 1) * 2, MAX_WAVE_SIZE)
	if _spike_this_surge:
		_surge_total = int(float(_surge_total) * SPIKE_MULTIPLIER)
		_quiet_surge_pending = true
	_surge_spawned = 0
	_spawn_timer = 1.0
	_post_spawn_timer = 0.0
	GameState.wave_number = day
	GameState.wave_changed.emit(day)
	_transition_sky(COLOR_SKY_BLOOD if _spike_this_surge else COLOR_SKY_SURGE, 3.0)

func _surge_interval() -> float:
	# thralls flood faster than anything on Earth
	return maxf(0.6, 3.0 - float(GameState.day_number) * 0.25)

func _process_surge(delta: float) -> void:
	if _surge_spawned > 0 and get_tree().get_nodes_in_group("enemies").size() <= _boss_count():
		_trigger_respite()
		return
	if _surge_spawned < _surge_total:
		_spawn_timer -= delta
		if _spawn_timer <= 0.0:
			_spawn_thrall()
			_surge_spawned += 1
			_spawn_timer = _surge_interval()
	else:
		_post_spawn_timer += delta
		if _post_spawn_timer >= SURGE_TIMEOUT:
			_trigger_respite()

# The Wizard lives here permanently — don't let its presence stall the respite
func _boss_count() -> int:
	var count: int = 0
	for b: Node in get_tree().get_nodes_in_group("bosses"):
		if is_instance_valid(b):
			count += 1
	return count

func _trigger_respite() -> void:
	_phase = Phase.RESPITE
	_respite_timer = RESPITE_DURATION
	_transition_sky(COLOR_SKY_LULL, 3.5)
	for enemy: Node in get_tree().get_nodes_in_group("enemies"):
		if enemy.is_in_group("bosses"):
			continue  # the Wizard never retreats
		if enemy.has_method("retreat"):
			enemy.retreat()
	GameState.dawn_triggered.emit(GameState.day_number)

func _process_respite(delta: float) -> void:
	_respite_timer -= delta
	if _respite_timer <= 0.0:
		_start_lull()

# ── PORTAL / BOSS ─────────────────────────────────────────────────────────────

func _on_portal_broken(_faction: String) -> void:
	GameState.portal_active = false
	# the lantern's collapse spills one last flood
	var count: int = maxi(COUNTERATTACK_MIN, mini(5 + (GameState.day_number - 1) * 2, MAX_WAVE_SIZE))
	for i in count:
		_spawn_thrall()
	_transition_sky(COLOR_SKY_BLOOD, 1.5)

# ── WORLD SETUP ───────────────────────────────────────────────────────────────


# The land ends in liquid, not a cliff (#25)
func _spawn_shoreline() -> void:
	var water_n720 := ColorRect.new()
	water_n720.color = Color(0.04, 0.04, 0.10, 1.0)
	water_n720.position = Vector2(-720.0, 152.0)
	water_n720.size = Vector2(335.0, 260.0)
	add_child(water_n720)
	var surf_n720 := ColorRect.new()
	surf_n720.color = Color(0.14, 0.14, 0.26, 0.9)
	surf_n720.position = Vector2(-720.0, 152.0)
	surf_n720.size = Vector2(335.0, 2.0)
	add_child(surf_n720)
	var tw_n720: Tween = surf_n720.create_tween().set_loops()
	tw_n720.tween_property(surf_n720, "modulate:a", 0.55, 1.7).set_ease(Tween.EASE_IN_OUT)
	tw_n720.tween_property(surf_n720, "modulate:a", 1.0, 1.7).set_ease(Tween.EASE_IN_OUT)

func _spawn_world_objects() -> void:
	var ship: Node2D = SHIP_SCENE.instantiate() as Node2D
	ship.position = Vector2(-280.0, 142.0)
	add_child(ship)

	# the Hive tomb — its soul lantern feeds the surges
	var portal: Node2D = PORTAL_SCENE.instantiate() as Node2D
	portal.position = Vector2(740.0, 148.0)
	portal.set("faction", "hive")
	add_child(portal)

	# the Wizard tends the lantern; kill it to collapse the tomb
	var wizard: CharacterBody2D = WIZARD_SCENE.instantiate() as CharacterBody2D
	wizard.position = Vector2(695.0, 118.0)
	add_child(wizard)

	var flag: Node2D = FLAG_SCENE.instantiate() as Node2D
	flag.position = Vector2(620.0, 148.0)
	add_child(flag)

	# Ascendant Forge — metal unlock, gates Shield-tier walls (EP-06 tier 4)
	var forge: Node2D = FOUNDRY_SCENE.instantiate() as Node2D
	forge.set("unlock_kind", "metal")
	forge.set("restore_cost", 500)
	forge.set("display_name", "Ascendant Forge")
	forge.set("unlock_label", "unlocks Shield-tier walls")
	forge.position = Vector2(540.0, 148.0)
	add_child(forge)

	# Targe waits in the dark — Zavala's Ghost (Arc / Striker Smash)
	if true:
		var shrine: Area2D = SHRINE_SCENE.instantiate() as Area2D
		shrine.set("super_name", "striker")
		shrine.set("ghost_name", "Targe")
		shrine.set("super_label", "Striker Smash")
		shrine.set("shard_cost", 4)
		shrine.set("glimmer_cost", 150)
		shrine.set("ember_color", Color(0.45, 0.75, 1.0))
		shrine.position = Vector2(430.0, 148.0)
		add_child(shrine)

	# world-secret shards near the wreck and deep in the dark
	for x: float in [-330.0, 660.0]:
		var shard: Area2D = PICKUP_SCENE.instantiate() as Area2D
		shard.set("kind", "shard")
		shard.position = Vector2(x, 143.0)
		add_child(shard)

# ── SPAWNING ──────────────────────────────────────────────────────────────────

func _spawn_thrall() -> void:
	var thrall: CharacterBody2D = THRALL_SCENE.instantiate() as CharacterBody2D
	thrall.global_position = spawn_point_right.global_position + Vector2(randf_range(0.0, 24.0), 0.0)
	add_child(thrall)

func _spawn_initial_caches() -> void:
	# no fauna, no trees — the Moon economy leans on caches and sweeping
	var positions: Array[float] = [-125.0, -70.0, -15.0, 45.0, 110.0, 180.0, 250.0, 330.0, 410.0]
	for x: float in positions:
		_spawn_cache_at(x)

func _spawn_lull_caches() -> void:
	if GameState.day_number <= 1:
		return
	var player: Node = get_tree().get_first_node_in_group("player")
	var center_x: float = player.global_position.x if player else 0.0
	for i: int in 4:
		_spawn_cache_at(center_x + randf_range(-185.0, 185.0))

func _spawn_cache_at(x: float) -> void:
	var cache: Node2D = CACHE_SCENE.instantiate() as Node2D
	cache.position = Vector2(x, 146.0)
	cache.set("glimmer_amount", randi_range(50, 130))
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
	}

func _restore_planet_state() -> void:
	if not GameState.planet_states.has(PLANET_NAME):
		return
	var st: Dictionary = GameState.planet_states[PLANET_NAME]
	GameState.planet_states.erase(PLANET_NAME)
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
	var nights: int = maxi(GameState.day_number - int(st["departed_day"]), 0)
	var walls: Array = st["walls"]
	var workers: Array = st["workers"]
	var enc: float = GameState.encampment_x
	for i in nights:
		var day: int = int(st["departed_day"]) + i + 1
		var enemies: int = mini(5 + (day - 1) * 2, MAX_WAVE_SIZE)
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
