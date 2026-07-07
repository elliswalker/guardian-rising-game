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

const TOWER_TEXTURES: Array[Texture2D] = [
	preload("res://assets/sprites/structures/encampment_tower_t1.png"),
	preload("res://assets/sprites/structures/encampment_tower_t2.png"),
	preload("res://assets/sprites/structures/encampment_tower_t3.png"),
	preload("res://assets/sprites/structures/encampment_tower_t4.png"),
]

@onready var _tower_sprite: Sprite2D = $TowerSprite
# Kingdom buildup (#49 critique): the camp GROWS — fire pit alone at T1,
# a tent joins at T2, the cabin at T3; the watch tower climbs throughout.
@onready var _tent: Sprite2D = get_node_or_null("Tent")
@onready var _cabin: Sprite2D = get_node_or_null("Cabin")
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
	# the watch tower gains a level with each tier and brightens
	if _tower_sprite:
		var tex: Texture2D = TOWER_TEXTURES[clampi(tier, 1, MAX_TIER) - 1]
		_tower_sprite.texture = tex
		_tower_sprite.offset = Vector2(-tex.get_width() * 0.5, -float(tex.get_height()))
		var t: float = float(tier - 1) / 3.0
		_tower_sprite.modulate = Color(0.52 + t * 0.22, 0.55 + t * 0.24, 0.60 + t * 0.30, 1.0)
	if _tent:
		_tent.visible = tier >= 2
	if _cabin:
		_cabin.visible = tier >= 3
	if _label:
		_label.text = "ENCAMPMENT  T%d" % tier
		_label.visible = not GameState.minimal_ui
