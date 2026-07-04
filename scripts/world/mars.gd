extends Node2D

# Mars — planet 4. Cabal siege warfare: enemies don't march in from the
# horizon, they arrive in DROP PODS that slam into the mid-field. Distance
# buys you nothing here — the war lands on top of you.
# Kill the Incendiary Colossus at the launch site to end the siege.
# The Osiris shrine grants Well of Radiance.

const LEGIONARY_SCENE := preload("res://scenes/enemies/legionary.tscn")
const PSION_SCENE     := preload("res://scenes/enemies/psion.tscn")
const PHALANX_SCENE   := preload("res://scenes/enemies/phalanx.tscn")
const COLOSSUS_SCENE  := preload("res://scenes/enemies/colossus.tscn")
const CACHE_SCENE     := preload("res://scenes/world/glimmer_cache.tscn")
const FRAME_SCENE     := preload("res://scenes/world/guardian.tscn")
const SHIP_SCENE      := preload("res://scenes/world/ship.tscn")
const PORTAL_SCENE    := preload("res://scenes/world/portal.tscn")
const FLAG_SCENE      := preload("res://scenes/world/attack_flag.tscn")
const WALL_SCENE      := preload("res://scenes/world/wall.tscn")
const SHRINE_SCENE    := preload("res://scenes/world/ghost_shrine.tscn")
const PICKUP_SCENE    := preload("res://scenes/world/pickup.tscn")

const PLANET_NAME := "mars"

const MAX_DORMANT_FRAMES := 6
const FRAME_SPAWN_XS: Array[float] = [195.0, 255.0, 320.0, 400.0, 470.0, 545.0]

const COLOR_SKY_DAY   := Color(0.52, 0.34, 0.24, 1)   # dusty red
const COLOR_SKY_DUSK  := Color(0.45, 0.20, 0.12, 1)
const COLOR_SKY_NIGHT := Color(0.12, 0.06, 0.07, 1)
const COLOR_SKY_BLOOD := Color(0.45, 0.08, 0.10, 1)

const DAY_DURATION_BASE := 90.0
const DAY_DURATION_DEC  := 3.0
const DAY_DURATION_MIN  := 60.0
const DUSK_DURATION     := 12.0
const MAX_WAVE_SIZE     := 16
const DAWN_DURATION     := 5.5
const NIGHT_WAVE_TIMEOUT := 35.0

const SPIKE_FIRST_DAY      := 5
const SPIKE_INTERVAL       := 5
const SPIKE_MULTIPLIER     := 2.0
const QUIET_NIGHT_DURATION := 10.0
const COUNTERATTACK_MIN    := 7

# Drop-pod siege: pods land INSIDE the field, 2-3 enemies each
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
	GameState.encampment_x = -100.0
	GameState.dual_front = false
	GameState.portal_active = not GameState.planets_cleared.get(PLANET_NAME, false)
	GameState.portal_broken.connect(_on_portal_broken)
	_layout_rng.seed = hash(PLANET_NAME) + GameState.current_run * 7919
	ParallaxLoader.build($ParallaxBackground, PLANET_NAME)
	_jitter_layout()
	_spawn_world_objects()
	_spawn_initial_caches()
	_restore_planet_state()
	_start_day()

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
	_spawn_day_scavengers()
	_try_spawn_frame()
	GameState.day_started.emit(day)

# Psion scavengers prowl the field by day, racing your sweeperbots for
# caches. They don't fight until dusk — but every cache they grab is yours lost.
func _spawn_day_scavengers() -> void:
	if GameState.day_number <= 1:
		return
	for i in 2:
		var psion: CharacterBody2D = PSION_SCENE.instantiate() as CharacterBody2D
		psion.set("day_scavenger", true)
		psion.global_position = Vector2(randf_range(350.0, 720.0), 136.0)
		add_child(psion)

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
		_trigger_dawn()
		return
	if _night_spawned < _night_total:
		_spawn_timer -= delta
		if _spawn_timer <= 0.0:
			var pod_size: int = mini(randi_range(POD_SIZE_MIN, POD_SIZE_MAX), _night_total - _night_spawned)
			_drop_pod(pod_size)
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
	GameState.portal_active = false
	# the launch site empties its last pods
	var count: int = maxi(COUNTERATTACK_MIN, mini(4 + (GameState.day_number - 1) * 2, MAX_WAVE_SIZE))
	while count > 0:
		var pod_size: int = mini(randi_range(POD_SIZE_MIN, POD_SIZE_MAX), count)
		_drop_pod(pod_size)
		count -= pod_size
	_transition_sky(COLOR_SKY_BLOOD, 1.5)

# ── DROP PODS ─────────────────────────────────────────────────────────────────

func _drop_pod(count: int) -> void:
	var pod_x: float = _pick_pod_x()
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
	tween.tween_property(pod, "modulate:a", 0.3, 4.0)

func _pick_pod_x() -> float:
	# pods aim inside the field but respect the outermost wall — the siege
	# lands in your yard, not inside your living room
	var outer_wall_x: float = POD_MIN_X
	for wall: Node in get_tree().get_nodes_in_group("walls"):
		var wn: Node2D = wall as Node2D
		if wn and is_instance_valid(wn):
			outer_wall_x = maxf(outer_wall_x, wn.global_position.x + 30.0)
	return randf_range(maxf(POD_MIN_X, outer_wall_x), POD_MAX_X)

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
		enemy.global_position = Vector2(pod_x + float(i) * 12.0 - 6.0, 136.0)
		add_child(enemy)

# ── WORLD SETUP ───────────────────────────────────────────────────────────────

func _spawn_world_objects() -> void:
	var ship: Node2D = SHIP_SCENE.instantiate() as Node2D
	ship.position = Vector2(-280.0, 142.0)
	add_child(ship)

	# the drop-pod launch site — Mars's portal
	var portal: Node2D = PORTAL_SCENE.instantiate() as Node2D
	portal.position = Vector2(740.0, 148.0)
	portal.set("faction", "cabal")
	add_child(portal)

	# the Incendiary Colossus guards the launch site (patrols 640-760)
	var colossus: CharacterBody2D = COLOSSUS_SCENE.instantiate() as CharacterBody2D
	colossus.position = Vector2(700.0, 132.0)
	add_child(colossus)

	var flag: Node2D = FLAG_SCENE.instantiate() as Node2D
	flag.position = Vector2(600.0, 148.0)
	add_child(flag)

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

	# world-secret shards
	for x: float in [-330.0, 690.0]:
		var shard: Area2D = PICKUP_SCENE.instantiate() as Area2D
		shard.set("kind", "shard")
		shard.position = Vector2(x, 143.0)
		add_child(shard)

func _spawn_initial_caches() -> void:
	var positions: Array[float] = [-125.0, -70.0, -15.0, 45.0, 110.0, 175.0, 245.0, 320.0]
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
	var spawn_x: float = FRAME_SPAWN_XS[randi() % FRAME_SPAWN_XS.size()]
	var frame: CharacterBody2D = FRAME_SCENE.instantiate() as CharacterBody2D
	frame.global_position = Vector2(spawn_x, 136.0)
	add_child(frame)

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
