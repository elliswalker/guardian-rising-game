extends Area2D

# Encampment — the Kingdom center-tier ladder (EP-09).
# Paid tiers gate what jobs and structures are available. The upgrade is the
# one workerless build: pay glimmer and it happens.
#
# T1 (start): builders AND redjacks — a camp can defend itself from day one
# T2: +sweeperbot jobs, towers buildable
# T3: +vault pads
# T4: the Charge — an army needs a full war camp behind it

const TIER_COSTS: Dictionary = { 2: 200, 3: 400, 4: 600 }
const TIER_UNLOCKS: Dictionary = {
	2: "Sweeperbots + Towers",
	3: "The Vault",
	4: "The Charge",
}
const MAX_TIER := 4

# ONE building per tier, replacing the last, each larger (#50) — the
# K2C center: campfire -> tent -> shack -> brick hall. Fire pit stays
# beside the Speaker as the camp's heart.
@onready var _tent: Sprite2D = get_node_or_null("Tent")
@onready var _shack: Sprite2D = get_node_or_null("Shack")
@onready var _brick: Sprite2D = get_node_or_null("Brick")
@onready var _label: Label = $Label

var _player_inside: bool = false

func _ready() -> void:
	add_to_group("encampment")
	collision_mask = 8  # player layer
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_update_visual()

func _process(_delta: float) -> void:
	if not _player_inside or GameState.camp_tier() >= MAX_TIER:
		return
	_show_prompt()  # re-assert each frame to recover from preemption
	if GameState.is_prompt_owner(self) and Input.is_action_just_pressed("action") and GameState.try_consume_action():
		_try_upgrade()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_inside = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_inside = false
		GameState.hide_action_prompt(self)

func _show_prompt() -> void:
	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	var pdist: float = global_position.distance_to(player.global_position) if player else 999999.0
	var next_tier: int = GameState.camp_tier() + 1
	GameState.show_action_prompt(self,
		"[ SPACE ]  Encampment T%d  —  %d ◈   (%s)" %
		[next_tier, TIER_COSTS[next_tier], TIER_UNLOCKS[next_tier]], 7, pdist)

func _try_upgrade() -> void:
	var next_tier: int = GameState.camp_tier() + 1
	if not GameState.spend_glimmer(TIER_COSTS[next_tier]):
		return
	GameState.set_camp_tier(next_tier)
	GameState.encampment_upgraded.emit(next_tier)
	_update_visual()
	if next_tier >= MAX_TIER:
		GameState.hide_action_prompt(self)

func _update_visual() -> void:
	var tier: int = GameState.camp_tier()
	if _tent:
		_tent.visible = tier == 2
	if _shack:
		_shack.visible = tier == 3
	if _brick:
		_brick.visible = tier >= 4
	if _label:
		_label.text = "ENCAMPMENT  T%d" % tier
		_label.visible = not GameState.minimal_ui
