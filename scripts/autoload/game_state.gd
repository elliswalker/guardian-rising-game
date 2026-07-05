extends Node

signal glimmer_changed(new_value: int)
signal vault_changed(new_value: int)
signal encampment_upgraded(new_tier: int)
signal shards_changed(new_value: int)
signal super_equipped(super_name: String)
signal ghost_captured
signal ghost_released
signal game_over
signal wave_changed(new_wave: int)
signal action_prompt_show(text: String)
signal action_prompt_hide
signal redjack_job_created
signal sweeperbot_job_created
signal builder_job_created
signal dusk_timer_updated(seconds: int)
signal dusk_triggered(day_number: int)
signal dawn_triggered(day_number: int)
signal day_started(day_number: int)
signal build_job_queued
signal attack_ordered
signal portal_broken(faction: String)
signal victory

# D1's cap, per Ellis (OQ-03). With armor live the risk tension comes from
# the 10% scatter-on-hit, not the ceiling — the cap is just the bag size.
const GLIMMER_CAP := 25000
const SAVE_PATH := "user://guardian_rising_save.json"

# Set by each level controller in _ready — Earth camp sits left, Cosmodrome center
var encampment_x: float = -100.0
var dual_front: bool = false

# EP-12 no-text migration v1: compact prompts, no wave banners — the sky
# and audio carry the announcements. Flip false to restore verbose text.
var minimal_ui: bool = true

const PLANET_SCENES: Dictionary = {
	"earth": "res://scenes/world/earth_highway.tscn",
	"cosmodrome": "res://scenes/world/cosmodrome.tscn",
	"moon": "res://scenes/world/moon.tscn",
	"mars": "res://scenes/world/mars.tscn",
}

var glimmer: int = 0:
	set(value):
		glimmer = clampi(value, 0, GLIMMER_CAP)
		glimmer_changed.emit(glimmer)

# Vaulted glimmer is safe from combat scatter but isn't armor (EP-10)
var vaulted_glimmer: int = 0
# Center-tier ladder: 1=builders, 2=+redjacks, 3=+sweepers/towers, 4=+vault.
# PER PLANET (#34): every world starts at T1 — build the camp from scratch.
var encampment_tiers: Dictionary = {}

func camp_tier() -> int:
	return int(encampment_tiers.get(current_planet, 1))

func set_camp_tier(tier: int) -> void:
	encampment_tiers[current_planet] = tier

# Away-decay Beacon (#40) — the lighthouse analog. Per planet, tier 0-3;
# each tier protects 0/10/20/30 away-nights from the decay simulation.
var beacon_tiers: Dictionary = {}

func beacon_tier() -> int:
	return int(beacon_tiers.get(current_planet, 0))

func set_beacon_tier(tier: int) -> void:
	beacon_tiers[current_planet] = tier

func beacon_nights(planet: String) -> int:
	var protections: Array[int] = [0, 10, 20, 30]
	return protections[clampi(int(beacon_tiers.get(planet, 0)), 0, 3)]

# ── Ghosts & supers (EP-08) ──────────────────────────────────────────────────
var legendary_shards: int = 0
var equipped_super: String = ""      # "" until an elemental Ghost is found
var unlocked_supers: Array[String] = []  # bonded shrines become free switch stations
var mote_reduction: float = 0.0      # seconds shaved off the next super cooldown

func add_shard(amount: int = 1) -> void:
	legendary_shards += amount
	shards_changed.emit(legendary_shards)

func spend_shards(amount: int) -> bool:
	if legendary_shards >= amount:
		legendary_shards -= amount
		shards_changed.emit(legendary_shards)
		return true
	return false

# ── Planets (EP-06/07/14) ────────────────────────────────────────────────────
var current_planet: String = "earth"
# Rebuilding the ship on a planet turns that spot into its landing pad (#31)
var ships_built: Dictionary = {}
var stone_unlocked: bool = false   # Cosmodrome foundry — gates wall/tower tier 3
var metal_unlocked: bool = false   # future planet — gates tier 4
var planets_cleared: Dictionary = {}  # planet -> true once its portals fall
var planet_states: Dictionary = {}    # planet -> departure snapshot for away-sim
var used_hermits: Array[String] = []  # hermit kinds already settled this run
# true while switching planets — tells the next level _ready NOT to reset the run
var travel_mode: bool = false

var is_ghost_captured := false
var wave_number: int = 0
var day_number: int = 0
var redjack_jobs_available: int = 0
var sweeperbot_jobs_available: int = 0
var builder_jobs_available: int = 0
var current_run := 0
var is_attack_phase: bool = false
var portal_active: bool = true
var run_time_seconds: float = 0.0

var _game_over_triggered: bool = false
var _build_queue: Array[Node] = []
var _prompt_owner: Object = null
var _prompt_priority: int = 0
var _prompt_text: String = ""
var _prompt_dist: float = 999999.0
var _prompt_stamp: int = 0  # frame of the owner's last re-assert (keep-alive)

func _ready() -> void:
	# Autosave at every dawn — the Kingdom rhythm: each survived night is kept
	day_started.connect(func(_d: int) -> void: save_game())

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and current_run > 0:
		save_game()

# ── Save / Load (M4-04). Permadeath: death or victory wipes the save. ────────

func save_game() -> void:
	if current_run <= 0:
		return
	# fold the live planet into planet_states so one snapshot covers everything
	var world: Node = get_tree().get_first_node_in_group("world")
	if world and world.has_method("save_planet_state"):
		world.call("save_planet_state")
	var data: Dictionary = {
		"version": 1,
		"current_run": current_run,
		"day_number": day_number,
		"glimmer": glimmer,
		"vaulted_glimmer": vaulted_glimmer,
		"legendary_shards": legendary_shards,
		"equipped_super": equipped_super,
		"unlocked_supers": unlocked_supers,
		"mote_reduction": mote_reduction,
		"encampment_tiers": encampment_tiers,
		"beacon_tiers": beacon_tiers,
		"current_planet": current_planet,
		"ships_built": ships_built,
		"stone_unlocked": stone_unlocked,
		"metal_unlocked": metal_unlocked,
		"planets_cleared": planets_cleared,
		"planet_states": planet_states,
		"used_hermits": used_hermits,
		"redjack_jobs_available": redjack_jobs_available,
		"sweeperbot_jobs_available": sweeperbot_jobs_available,
		"builder_jobs_available": builder_jobs_available,
	}
	var f: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func clear_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))

# Resumes at the morning of the day the save was made (save fires at dawn,
# level _ready re-runs _start_day which re-increments the counter).
func load_game() -> bool:
	if not has_save():
		return false
	var f: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not f:
		return false
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if not (parsed is Dictionary):
		return false
	var d: Dictionary = parsed
	current_run = int(d.get("current_run", 1))
	day_number = int(d.get("day_number", 1)) - 1  # _start_day adds it back
	glimmer = int(d.get("glimmer", 0))
	vaulted_glimmer = int(d.get("vaulted_glimmer", 0))
	vault_changed.emit(vaulted_glimmer)
	legendary_shards = int(d.get("legendary_shards", 0))
	shards_changed.emit(legendary_shards)
	equipped_super = String(d.get("equipped_super", ""))
	unlocked_supers.assign(d.get("unlocked_supers", []))
	mote_reduction = float(d.get("mote_reduction", 0.0))
	encampment_tiers = d.get("encampment_tiers", {})
	beacon_tiers = d.get("beacon_tiers", {})
	current_planet = String(d.get("current_planet", "earth"))
	ships_built = d.get("ships_built", {})
	stone_unlocked = bool(d.get("stone_unlocked", false))
	metal_unlocked = bool(d.get("metal_unlocked", false))
	planets_cleared = d.get("planets_cleared", {})
	planet_states = d.get("planet_states", {})
	used_hermits.assign(d.get("used_hermits", []))
	redjack_jobs_available = int(d.get("redjack_jobs_available", 0))
	sweeperbot_jobs_available = int(d.get("sweeperbot_jobs_available", 0))
	builder_jobs_available = int(d.get("builder_jobs_available", 0))
	is_ghost_captured = false
	is_attack_phase = false
	portal_active = not planets_cleared.get(current_planet, false)
	_game_over_triggered = false
	_victory_triggered = false
	travel_mode = true  # tells the level _ready not to reset the run
	get_tree().change_scene_to_file(PLANET_SCENES[current_planet])
	return true

func add_glimmer(amount: int) -> void:
	glimmer += amount

func spend_glimmer(amount: int) -> bool:
	if glimmer >= amount:
		glimmer -= amount
		return true
	return false

func vault_deposit(amount: int) -> void:
	vaulted_glimmer += amount
	vault_changed.emit(vaulted_glimmer)

func vault_withdraw(amount: int) -> void:
	vaulted_glimmer = maxi(vaulted_glimmer - amount, 0)
	vault_changed.emit(vaulted_glimmer)

# Travel: the flight always lands the next morning. Day counter is global.
func travel_to(planet: String) -> void:
	travel_mode = true
	current_planet = planet
	day_number += 1
	get_tree().change_scene_to_file(PLANET_SCENES[planet])

func all_planets_cleared() -> bool:
	for planet: String in PLANET_SCENES:
		if not planets_cleared.get(planet, false):
			return false
	return true

func on_ghost_captured() -> void:
	is_ghost_captured = true
	ghost_captured.emit()

func on_ghost_released() -> void:
	is_ghost_captured = false
	ghost_released.emit()

func trigger_game_over() -> void:
	if _game_over_triggered:
		return
	_game_over_triggered = true
	clear_save()  # permadeath — the Light is gone, the run is gone
	game_over.emit()
	await get_tree().create_timer(0.1).timeout
	get_tree().change_scene_to_file("res://scenes/ui/game_over.tscn")

var _victory_triggered: bool = false

func trigger_victory() -> void:
	if _victory_triggered:
		return
	_victory_triggered = true
	clear_save()  # the campaign is complete
	victory.emit()
	await get_tree().create_timer(0.1).timeout
	get_tree().change_scene_to_file("res://scenes/ui/victory.tscn")

func queue_build_job(site: Node, priority: bool = false) -> void:
	if site not in _build_queue:
		if priority:
			_build_queue.push_front(site)
		else:
			_build_queue.push_back(site)
	build_job_queued.emit()

# Enemies parked on a site make it unbuildable for now — a builder
# ping-ponging against the flee radius helps nobody (#47)
const BUILD_DANGER_RANGE := 90.0

func site_contested(site: Node2D) -> bool:
	for e: Node in get_tree().get_nodes_in_group("enemies"):
		var en: Node2D = e as Node2D
		if en and is_instance_valid(en) \
				and absf(en.global_position.x - site.global_position.x) < BUILD_DANGER_RANGE:
			return true
	return false

# Builders build INWARD-OUT (#47), not first-queued-first-served: prefer
# the claimer's own side of camp, then the job nearest the CAMP (the safe
# core grows outward), then nearest the builder. Contested sites are
# skipped — they stay queued and get retried on the next idle scan.
func claim_build_job(builder_x: float) -> Node:
	var builder_side: float = signf(builder_x - encampment_x)
	var best: Node = null
	var best_key: Array = []
	for site: Node in _build_queue:
		var sn: Node2D = site as Node2D
		if not sn or not is_instance_valid(sn):
			continue
		if site_contested(sn):
			continue
		var same_side: int = 0 if signf(sn.global_position.x - encampment_x) == builder_side else 1
		var key: Array = [
			same_side,
			absf(sn.global_position.x - encampment_x),
			absf(sn.global_position.x - builder_x),
		]
		if best == null or key < best_key:
			best = site
			best_key = key
	if best:
		_build_queue.erase(best)
	return best

# The NEAREST interactable to the player wins the prompt; priority only
# breaks near-ties (objects genuinely stacked, e.g. a tree over a build site).
# Callers must re-assert every frame — ownership is a KEEP-ALIVE: an owner
# that stops asserting (freed, disabled, drifted out of range) loses the
# prompt within a few frames instead of blocking everyone with stale state.
func show_action_prompt(owner: Object, text: String, priority: int = 5, dist: float = 999999.0) -> void:
	var frame: int = Engine.get_process_frames()
	var owner_valid: bool = _prompt_owner != null and is_instance_valid(_prompt_owner)
	var owner_live: bool = owner_valid and frame - _prompt_stamp <= 3
	if owner_live and owner != _prompt_owner:
		if dist > _prompt_dist + 6.0:
			return  # someone closer holds the prompt
		if dist > _prompt_dist - 6.0 and priority < _prompt_priority:
			return  # effectively same spot — higher priority holds it
	if owner != _prompt_owner or text != _prompt_text:
		_prompt_owner = owner
		_prompt_text = text
		action_prompt_show.emit(text)
	_prompt_priority = priority
	_prompt_dist = dist
	_prompt_stamp = frame

func _process(_delta: float) -> void:
	# nobody re-asserting at all — clear the lingering prompt entirely
	if _prompt_owner != null \
			and Engine.get_process_frames() - _prompt_stamp > 10:
		_prompt_owner = null
		_prompt_priority = 0
		_prompt_text = ""
		_prompt_dist = 999999.0
		action_prompt_hide.emit()

func hide_action_prompt(owner: Object) -> void:
	if _prompt_owner == owner:
		_prompt_owner = null
		_prompt_priority = 0
		_prompt_text = ""
		_prompt_dist = 999999.0
		action_prompt_hide.emit()

# One action per frame (#45): when the acting owner hides its prompt, a
# neighboring interactable can claim ownership later the SAME frame while
# is_action_just_pressed is still true — and both pay. Every prompt-gated
# action site must also win this latch.
var _action_consumed_frame: int = -1

func try_consume_action() -> bool:
	var frame: int = Engine.get_process_frames()
	if _action_consumed_frame == frame:
		return false
	_action_consumed_frame = frame
	return true

func is_prompt_owner(caller: Object) -> bool:
	return _prompt_owner != null and is_instance_valid(_prompt_owner) and _prompt_owner == caller

func has_active_prompt() -> bool:
	return _prompt_owner != null and is_instance_valid(_prompt_owner)

func new_run() -> void:
	clear_save()
	current_run += 1
	glimmer = 0
	vaulted_glimmer = 0
	vault_changed.emit(0)
	encampment_tiers.clear()
	beacon_tiers.clear()
	legendary_shards = 0
	equipped_super = ""
	unlocked_supers.clear()
	mote_reduction = 0.0
	shards_changed.emit(0)
	current_planet = "earth"
	ships_built.clear()
	stone_unlocked = false
	metal_unlocked = false
	planets_cleared.clear()
	planet_states.clear()
	used_hermits.clear()
	travel_mode = false
	wave_number = 0
	day_number = 0
	redjack_jobs_available = 0
	sweeperbot_jobs_available = 0
	builder_jobs_available = 0
	is_ghost_captured = false
	is_attack_phase = false
	portal_active = true
	run_time_seconds = 0.0
	_game_over_triggered = false
	_victory_triggered = false
	_build_queue.clear()
	_prompt_owner = null
	_prompt_priority = 0
	_prompt_text = ""
	_prompt_dist = 999999.0
	action_prompt_hide.emit()
