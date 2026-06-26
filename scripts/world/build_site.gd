extends Area2D

const WALL_SCENE  := preload("res://scenes/world/wall.tscn")
const SWING_COUNT := 4
const BUILD_COST  := 50  # glimmer charged when player actions the job

@onready var _site_sprite: ColorRect = $SiteSprite
@onready var _glow: ColorRect = $Glow

# Tier memory from the wall that was here before (1=Wood … 4=Shield).
var _remembered_tier: int = 1
var _progress: int = 0
var _actioned: bool = false   # true once the player has paid to queue this job
var _pulse_time: float = 0.0
var _player_nearby: bool = false

func _ready() -> void:
	add_to_group("build_sites")
	collision_mask = 8  # player layer
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	# If spawned while the player is already inside (e.g. wall just collapsed), show prompt
	call_deferred("_check_initial_overlap")

func _check_initial_overlap() -> void:
	for body: Node2D in get_overlapping_bodies():
		if body.is_in_group("player"):
			_on_body_entered(body)
			break

func _exit_tree() -> void:
	if _player_nearby:
		GameState.hide_action_prompt(self)

func _process(delta: float) -> void:
	_pulse_time += delta
	_update_visual()
	if _player_nearby and not _actioned:
		var blocking: Node2D = _get_blocking_tree()
		if blocking:
			GameState.show_action_prompt(self, "[ SPACE ]  Mark Tree  —  Clear Path", 12)
			if GameState.is_prompt_owner(self) and Input.is_action_just_pressed("action"):
				blocking.call("commission")
		else:
			GameState.show_action_prompt(self, "[ SPACE ]  Build Wall  —  %d ◈" % BUILD_COST, 12)
			if GameState.is_prompt_owner(self) and Input.is_action_just_pressed("action"):
				_action_job()

func _get_blocking_tree() -> Node2D:
	for tree: Node in get_tree().get_nodes_in_group("trees"):
		var tn: Node2D = tree as Node2D
		if tn and global_position.distance_to(tn.global_position) < 38.0:
			if not tn.get("_commissioned"):
				return tn
	return null

func _has_nearby_tree() -> bool:
	return _get_blocking_tree() != null

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_nearby = true
		if not _actioned:
			if _has_nearby_tree():
				GameState.show_action_prompt(self, "[ SPACE ]  Mark Tree  —  Clear Path", 12)
			else:
				GameState.show_action_prompt(self, "[ SPACE ]  Build Wall  —  %d ◈" % BUILD_COST, 12)

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_nearby = false
		if not _actioned:
			GameState.hide_action_prompt(self)

func _action_job() -> void:
	if _has_nearby_tree():
		return
	if not GameState.spend_glimmer(BUILD_COST):
		return
	_actioned = true
	GameState.hide_action_prompt(self)
	GameState.queue_build_job(self)

# Called by the builder each swing. Always succeeds — cost already paid.
func add_progress(amount: int) -> bool:
	_progress = mini(_progress + amount, SWING_COUNT)
	if _progress >= SWING_COUNT:
		_spawn_wall()
	return true

func is_complete() -> bool:
	return _progress >= SWING_COUNT

func _update_visual() -> void:
	var pulse: float = 0.6 + sin(_pulse_time * 2.2) * 0.4
	if not _actioned:
		_site_sprite.modulate = Color(1.0, 1.0, 1.0, 0.45 + pulse * 0.4)
		_glow.modulate.a = 0.3
		return
	match _progress:
		0:
			_site_sprite.modulate = Color(0.80, 0.80, 0.80, pulse * 0.4)
			_glow.modulate.a = 0.15
		1:  # 25 %
			_site_sprite.modulate = Color(1.00, 0.85, 0.40, pulse * 0.65)
			_glow.modulate.a = 0.35
		2:  # 50 %
			_site_sprite.modulate = Color(1.00, 0.70, 0.20, pulse * 0.80)
			_glow.modulate.a = 0.55
		3:  # 75 %
			_site_sprite.modulate = Color(1.00, 0.58, 0.05, pulse * 0.95)
			_glow.modulate.a = 0.80

func _spawn_wall() -> void:
	var wall: Node2D = WALL_SCENE.instantiate() as Node2D
	# Set _hp before add_child so _ready()/_update_visual() picks it up immediately.
	wall.set("_hp", _remembered_tier * 2)
	wall.global_position = global_position
	get_parent().add_child(wall)
	queue_free()
