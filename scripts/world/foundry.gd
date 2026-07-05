extends Area2D

# Tech-unlock ruin (EP-06) — the Kingdom Stone/Iron Mine, GR-flavored.
# Cosmodrome: Foundry (stone) unlocks tier-3 Metal walls/towers.
# Moon: Ascendant Forge (metal) unlocks tier-4 Shield walls.
# Restore once; the unlock is permanent for the run, across every planet.

@export var unlock_kind: String = "stone"   # "stone" or "metal"
@export var restore_cost: int = 300
@export var display_name: String = "Foundry"
@export var unlock_label: String = "unlocks Metal-tier walls & towers"

@onready var _body: ColorRect = $Body
@onready var _glow: ColorRect = $Glow

var _player_nearby: bool = false

func _ready() -> void:
	add_to_group("foundry")
	collision_mask = 8  # player layer
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_update_visual()

func _is_unlocked() -> bool:
	return GameState.metal_unlocked if unlock_kind == "metal" else GameState.stone_unlocked

func _process(_delta: float) -> void:
	if not _player_nearby or _is_unlocked():
		return
	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	var pdist: float = global_position.distance_to(player.global_position) if player else 999999.0
	GameState.show_action_prompt(self,
		"[ SPACE ]  Restore %s  —  %d ◈   (%s)" % [display_name, restore_cost, unlock_label], 9, pdist)
	if GameState.is_prompt_owner(self) and Input.is_action_just_pressed("action") and GameState.try_consume_action():
		_restore()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_nearby = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_nearby = false
		GameState.hide_action_prompt(self)

func _restore() -> void:
	if not GameState.spend_glimmer(restore_cost):
		return
	if unlock_kind == "metal":
		GameState.metal_unlocked = true
	else:
		GameState.stone_unlocked = true
	GameState.hide_action_prompt(self)
	Sound.play("ding")
	_update_visual()

func _update_visual() -> void:
	if _is_unlocked():
		_body.color = Color(0.55, 0.45, 0.30, 1.0)   # lit forge
		_glow.color = Color(1.0, 0.55, 0.15, 0.35)   # ember glow
	else:
		_body.color = Color(0.25, 0.24, 0.22, 1.0)   # cold ruin
		_glow.color = Color(1.0, 0.55, 0.15, 0.0)
