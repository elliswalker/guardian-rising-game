extends Area2D

# Cosmodrome Foundry (EP-06) — restore it once to permanently unlock
# advanced wall/tower materials (tier 3) across every planet this run.
# The Kingdom Stone Mine, GR-flavored.

const RESTORE_COST := 300

@onready var _body: ColorRect = $Body
@onready var _glow: ColorRect = $Glow

var _player_nearby: bool = false

func _ready() -> void:
	add_to_group("foundry")
	collision_mask = 8  # player layer
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_update_visual()

func _process(_delta: float) -> void:
	if not _player_nearby or GameState.stone_unlocked:
		return
	GameState.show_action_prompt(self,
		"[ SPACE ]  Restore Foundry  —  %d ◈   (unlocks Metal-tier walls & towers)" % RESTORE_COST, 9)
	if GameState.is_prompt_owner(self) and Input.is_action_just_pressed("action"):
		_restore()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_nearby = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_nearby = false
		GameState.hide_action_prompt(self)

func _restore() -> void:
	if not GameState.spend_glimmer(RESTORE_COST):
		return
	GameState.stone_unlocked = true
	GameState.hide_action_prompt(self)
	_update_visual()

func _update_visual() -> void:
	if GameState.stone_unlocked:
		_body.color = Color(0.55, 0.45, 0.30, 1.0)   # lit forge
		_glow.color = Color(1.0, 0.55, 0.15, 0.35)   # ember glow
	else:
		_body.color = Color(0.25, 0.24, 0.22, 1.0)   # cold ruin
		_glow.color = Color(1.0, 0.55, 0.15, 0.0)
