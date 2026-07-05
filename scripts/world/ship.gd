extends Node2D

# The Guardian's ship — broken down on Earth (Level 1), needs staged repair.
# Player commissions each stage. Builders work it like a build site.
# Stage 0 = wreck, Stage 1 = hull, Stage 2 = engines, Stage 3 = ready to launch.

const STAGE_COST:   Array[int] = [150, 200, 300]
const STAGE_SWINGS: Array[int] = [3,   4,   5  ]
const INTERACT_RANGE := 32.0

const STAGE_HULL_COLORS: Array[Color] = [
	Color(0.25, 0.22, 0.20, 1.0),  # wreck — rusted dark
	Color(0.42, 0.40, 0.36, 1.0),  # hull up
	Color(0.58, 0.55, 0.50, 1.0),  # engines mounted
	Color(0.80, 0.78, 0.72, 1.0),  # launch-ready — bright
]

@onready var _hull:   Sprite2D = $Hull
@onready var _engine: ColorRect = $Engine
@onready var _glow:   ColorRect = $Glow

var _stage: int = 0
var _build_progress: int = 0
var _stage_commissioned: bool = false
var _stage_complete: bool = false   # one-frame flag so builder detaches cleanly
var _player_nearby: bool = false

func _ready() -> void:
	add_to_group("ship")
	if GameState.ships_built.get(GameState.current_planet, false):
		_stage = 3  # this planet's pad is built — you landed clean
	_update_visual()

func _process(_delta: float) -> void:
	_check_player_proximity()

func _check_player_proximity() -> void:
	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if not player:
		return
	var pdist: float = global_position.distance_to(player.global_position)
	var nearby: bool = pdist < INTERACT_RANGE
	if nearby:
		_show_prompt(pdist)
	elif _player_nearby:
		GameState.hide_action_prompt(self)
	_player_nearby = nearby
	if nearby and GameState.is_prompt_owner(self) and Input.is_action_just_pressed("action") and GameState.try_consume_action():
		_on_interact()

func _show_prompt(pdist: float = 999999.0) -> void:
	if _stage >= 3:
		GameState.show_action_prompt(self, "[ SPACE ]  Launch", 9, pdist)
	elif _stage_commissioned:
		GameState.show_action_prompt(self, "Builders are working on the ship...", 9, pdist)
	else:
		GameState.show_action_prompt(self, "[ SPACE ]  Repair Ship  —  %d ◈" % STAGE_COST[_stage], 9, pdist)

func _on_interact() -> void:
	if _stage >= 3:
		_launch()
		return
	if _stage_commissioned:
		return
	if not GameState.spend_glimmer(STAGE_COST[_stage]):
		return
	_stage_commissioned = true
	GameState.hide_action_prompt(self)
	GameState.queue_build_job(self)

# Builder interface — same contract as build_site.gd
func add_progress(amount: int) -> bool:
	if _stage >= 3 or _stage_complete:
		return true
	_build_progress = mini(_build_progress + amount, STAGE_SWINGS[_stage])
	if _build_progress >= STAGE_SWINGS[_stage]:
		_stage_complete = true
		call_deferred("_advance_stage")
	return true

func is_complete() -> bool:
	return _stage_complete or _stage >= 3

func _advance_stage() -> void:
	_stage = mini(_stage + 1, 3)
	if _stage >= 3:
		# the wreck becomes this planet's landing pad — future visits land clean
		GameState.ships_built[GameState.current_planet] = true
		Sound.play("ding")
	_build_progress = 0
	_stage_commissioned = false
	_stage_complete = false
	_update_visual()
	if _player_nearby:
		_show_prompt()

func _update_visual() -> void:
	_hull.modulate = STAGE_HULL_COLORS[_stage]
	var glow_alpha: float = float(_stage) / 3.0 * 0.55
	_glow.modulate.a = glow_alpha
	_engine.modulate.a = 0.3 + float(_stage) / 3.0 * 0.7

func _launch() -> void:
	GameState.hide_action_prompt(self)
	# Snapshot this planet so the away-simulation can run while we're gone
	var world: Node = get_tree().get_first_node_in_group("world")
	if world and world.has_method("save_planet_state"):
		world.call("save_planet_state")
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(_hull,   "modulate:a", 0.0, 1.2)
	tween.tween_property(_engine, "modulate:a", 0.0, 0.8)
	tween.tween_property(_glow,   "modulate:a", 2.0, 0.4)
	tween.chain().tween_property(_glow, "modulate:a", 0.0, 0.6)
	tween.chain().tween_callback(func() -> void:
		get_tree().change_scene_to_file("res://scenes/ui/planet_select.tscn")
	)
