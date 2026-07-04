extends Area2D

# Away-decay Beacon (#40) — the Two Crowns lighthouse analog. Raise it
# before you leave and the planet holds while you're gone: each tier
# protects more away-nights from the decay simulation. Leaving becomes a
# provisioning decision, not a coin flip.
#
# T1 Signal (150◈) — holds 10 nights
# T2 Relay  (300◈) — holds 20 nights
# T3 Aegis  (500◈) — holds 30 nights

const TIER_COSTS: Array[int] = [150, 300, 500]
const TIER_NIGHTS: Array[int] = [0, 10, 20, 30]
const TIER_NAMES: Array[String] = ["", "Signal", "Relay", "Aegis"]
const MAX_TIER := 3

const LAMP_COLORS: Array[Color] = [
	Color(0.25, 0.28, 0.32, 0.0),   # unlit
	Color(0.45, 0.85, 1.00, 0.9),   # Signal — pale arc blue
	Color(0.55, 0.95, 0.75, 0.95),  # Relay — steady green
	Color(1.00, 0.85, 0.45, 1.0),   # Aegis — golden
]

@onready var _mast: Sprite2D = $Mast
@onready var _lamp: ColorRect = $Lamp

var _player_inside: bool = false
var _pulse: Tween = null

func _ready() -> void:
	add_to_group("beacons")
	collision_layer = 0
	collision_mask = 8  # player
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_update_visual()

func _process(_delta: float) -> void:
	if not _player_inside:
		return
	var tier: int = GameState.beacon_tier()
	if tier >= MAX_TIER:
		return
	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	var pdist: float = global_position.distance_to(player.global_position) if player else 999999.0
	GameState.show_action_prompt(self,
		"[ SPACE ]  Beacon %s — %d ◈   (holds %d nights)" %
		[TIER_NAMES[tier + 1], TIER_COSTS[tier], TIER_NIGHTS[tier + 1]], 6, pdist)
	if GameState.is_prompt_owner(self) and Input.is_action_just_pressed("action"):
		_try_upgrade()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_inside = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_inside = false
		GameState.hide_action_prompt(self)

func _try_upgrade() -> void:
	var tier: int = GameState.beacon_tier()
	if tier >= MAX_TIER:
		return
	if not GameState.spend_glimmer(TIER_COSTS[tier]):
		return
	GameState.set_beacon_tier(tier + 1)
	Sound.play("ding", -2.0, 0.9 + 0.15 * float(tier))
	_update_visual()
	if GameState.beacon_tier() >= MAX_TIER:
		GameState.hide_action_prompt(self)

func _update_visual() -> void:
	var tier: int = GameState.beacon_tier()
	if _mast:
		var t: float = float(tier) / float(MAX_TIER)
		_mast.modulate = Color(0.45 + t * 0.3, 0.48 + t * 0.3, 0.54 + t * 0.3, 1.0)
	if not _lamp:
		return
	_lamp.color = LAMP_COLORS[clampi(tier, 0, MAX_TIER)]
	if _pulse:
		_pulse.kill()
		_pulse = null
	if tier > 0:
		# the lamp breathes — visible from across the camp, a promise kept
		_pulse = create_tween().set_loops()
		_pulse.tween_property(_lamp, "modulate:a", 0.35, 1.4).set_ease(Tween.EASE_IN_OUT)
		_pulse.tween_property(_lamp, "modulate:a", 1.0, 1.4).set_ease(Tween.EASE_IN_OUT)
