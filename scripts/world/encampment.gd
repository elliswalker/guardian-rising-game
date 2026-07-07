extends Area2D

# Encampment — the Kingdom center ladder (EP-09, rebuilt #50): nothing
# here is instant anymore. Pay glimmer to commission the next tier, then
# BUILDERS raise it — a short build for the fire, longer for every roof.
#
# T0 (start): a smoldering fire pit in the ash — camp not yet lit
# T1: the fire burns — redjack jobs unlock
# T2: walk-in tent — +sweeperbots, towers
# T3: scrap shack — +vault
# T4: brick hall — the Charge

const TIER_COSTS: Dictionary = { 1: 50, 2: 200, 3: 400, 4: 600 }
const TIER_SWINGS: Dictionary = { 1: 2, 2: 5, 3: 8, 4: 12 }
const TIER_UNLOCKS: Dictionary = {
	1: "Light the Fire",
	2: "Sweeperbots + Towers",
	3: "The Vault",
	4: "The Charge",
}
const MAX_TIER := 4

@onready var _tent: Sprite2D = get_node_or_null("Tent")
@onready var _shack: Sprite2D = get_node_or_null("Shack")
@onready var _brick: Sprite2D = get_node_or_null("Brick")
@onready var _fire: Sprite2D = get_node_or_null("FirePit")
@onready var _mound: Sprite2D = get_node_or_null("Mound")
@onready var _rubble: Sprite2D = get_node_or_null("Rubble")
@onready var _label: Label = $Label

var _player_inside: bool = false
var _commissioned: bool = false
var _build_progress: int = 0

func _ready() -> void:
	add_to_group("encampment")
	collision_mask = 8  # player layer
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_update_visual()

func _process(_delta: float) -> void:
	if not _player_inside or GameState.camp_tier() >= MAX_TIER or _commissioned:
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
	_commissioned = true
	_build_progress = 0
	GameState.hide_action_prompt(self)
	GameState.queue_build_job(self)
	_update_visual()

# ── Builder contract (same handshake as build_site / tower / ship) ───────────

func add_progress(amount: int) -> bool:
	if not _commissioned:
		return true
	_build_progress += amount
	if _build_progress >= int(TIER_SWINGS[GameState.camp_tier() + 1]):
		call_deferred("_finish_tier")
	return true

func is_complete() -> bool:
	return not _commissioned

func _finish_tier() -> void:
	if not _commissioned:
		return
	_commissioned = false
	var next_tier: int = GameState.camp_tier() + 1
	GameState.set_camp_tier(next_tier)
	GameState.encampment_upgraded.emit(next_tier)
	Sound.play("thunk", 0.0, 0.7)
	_update_visual()
	if next_tier >= MAX_TIER:
		GameState.hide_action_prompt(self)

func _update_visual() -> void:
	var tier: int = GameState.camp_tier()
	if _fire:
		# T0 is a collapsed ruin — the fire doesn't exist until it's BUILT
		_fire.visible = tier >= 1
	if _rubble:
		_rubble.visible = tier <= 0 and not _commissioned
	if _tent:
		_tent.visible = tier == 2
	if _shack:
		_shack.visible = tier == 3
	if _brick:
		_brick.visible = tier >= 4
	if _mound:
		_mound.visible = _commissioned
	if _label:
		_label.text = "ENCAMPMENT  T%d" % tier
		_label.visible = not GameState.minimal_ui
