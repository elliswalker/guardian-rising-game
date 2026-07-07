extends Area2D

enum JobType { REDJACK, SWEEPERBOT, BUILDER }

@export var job_type: JobType = JobType.REDJACK

const COSTS: Dictionary = {
	JobType.REDJACK:    150,
	JobType.SWEEPERBOT: 100,
	JobType.BUILDER:    125,
}
# Encampment tier required before this job type unlocks (EP-09)
const TIER_REQUIRED: Dictionary = {
	JobType.REDJACK:    1,
	JobType.SWEEPERBOT: 2,
	JobType.BUILDER:    1,
}
const LABELS: Dictionary = {
	JobType.REDJACK:    "Redjack",
	JobType.SWEEPERBOT: "Sweeperbot",
	JobType.BUILDER:    "Builder",
}
const COLORS: Dictionary = {
	JobType.REDJACK:    Color(0.75, 0.12, 0.08, 1.0),
	JobType.SWEEPERBOT: Color(0.78, 0.63, 0.18, 1.0),
	JobType.BUILDER:    Color(0.30, 0.55, 0.90, 1.0),
}

@onready var _marker: Sprite2D = $Marker
@onready var _label: Label = $Label

var _player_inside: bool = false

func _ready() -> void:
	add_to_group("job_posts")
	collision_mask = 8
	_marker.self_modulate = COLORS[job_type]
	_label.text = LABELS[job_type].to_upper()
	_label.visible = not GameState.minimal_ui
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(_delta: float) -> void:
	if _player_inside:
		_show_prompt()  # re-assert each frame to recover from preemption
		if GameState.is_prompt_owner(self) and Input.is_action_just_pressed("action") and GameState.try_consume_action():
			_try_create_job()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_inside = true
		_show_prompt()

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_inside = false
		GameState.hide_action_prompt(self)

func _show_prompt() -> void:
	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	var pdist: float = global_position.distance_to(player.global_position) if player else 999999.0
	if GameState.camp_tier() < TIER_REQUIRED[job_type]:
		GameState.show_action_prompt(self,
			"%s — Requires Encampment T%d" % [LABELS[job_type], TIER_REQUIRED[job_type]], 6, pdist)
		return
	var cost: int = COSTS[job_type]
	var label: String = LABELS[job_type]
	var available: int = get_tree().get_nodes_in_group("frame_waiting").size() \
		+ get_tree().get_nodes_in_group("frame_following").size()
	if available > 0:
		GameState.show_action_prompt(self,
			"[ SPACE ]  Assign %s  —  %d ◈   (%d available)" % [label, cost, available], 6, pdist)
	else:
		GameState.show_action_prompt(self, "[ SPACE ]  Create %s Job  —  %d ◈" % [label, cost], 6, pdist)

func _try_create_job() -> void:
	if GameState.camp_tier() < TIER_REQUIRED[job_type]:
		return
	if not GameState.spend_glimmer(COSTS[job_type]):
		return
	match job_type:
		JobType.REDJACK:
			GameState.redjack_jobs_available += 1
			GameState.redjack_job_created.emit()
		JobType.SWEEPERBOT:
			GameState.sweeperbot_jobs_available += 1
			GameState.sweeperbot_job_created.emit()
		JobType.BUILDER:
			GameState.builder_jobs_available += 1
			GameState.builder_job_created.emit()
	_show_prompt()
