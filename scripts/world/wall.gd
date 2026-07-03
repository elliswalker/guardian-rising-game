extends StaticBody2D

const MAX_HP := 8

# Indexed by tier (1–4). Tier 0 unused.
const COLOR_HEALTHY: Array[Color] = [
	Color.TRANSPARENT,
	Color(0.72, 0.58, 0.38, 1.0),  # Wood
	Color(0.60, 0.38, 0.28, 1.0),  # Brick
	Color(0.42, 0.46, 0.52, 1.0),  # Metal
	Color(0.65, 0.78, 1.00, 1.0),  # Shield
]
const COLOR_BROKEN: Array[Color] = [
	Color.TRANSPARENT,
	Color(0.46, 0.34, 0.20, 1.0),  # Broken Wood
	Color(0.36, 0.20, 0.14, 1.0),  # Broken Brick
	Color(0.26, 0.28, 0.32, 1.0),  # Broken Metal
	Color(0.35, 0.45, 0.68, 1.0),  # Broken Shield
]

const HITS_PER_HP := 3  # dreg hits required to lose 1 HP; wood wall survives 6 hits

# Player pays to commission an upgrade at the wall; a builder executes it
const UPGRADE_COST := 50
const TIER_NAMES: Array[String] = ["", "Wood", "Brick", "Metal", "Shield"]
const INTERACT_RANGE := 22.0

@onready var _sprite: Sprite2D = $WallSprite

# Set this before add_child() to spawn a wall at the correct tier.
# Default 2 = Healthy Wood.
var _hp: int = 2
var _hit_buffer: int = 0  # accumulates hits; every HITS_PER_HP reduces _hp by 1
var _collapsed: bool = false
var _upgrade_commissioned: bool = false
var _prompt_showing: bool = false

func _ready() -> void:
	add_to_group("walls")
	collision_layer = 2
	collision_mask = 0
	_update_visual()

func _process(_delta: float) -> void:
	if _upgrade_commissioned or _collapsed or _hp >= MAX_HP or not is_healthy():
		_drop_prompt()
		return
	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if not player:
		return
	var pdist: float = global_position.distance_to(player.global_position)
	if pdist >= INTERACT_RANGE:
		_drop_prompt()
		return
	_prompt_showing = true
	if can_upgrade():
		GameState.show_action_prompt(self,
			"[ SPACE ]  Reinforce Wall  —  %d ◈   (→ %s)" % [UPGRADE_COST, TIER_NAMES[current_tier() + 1]],
			8, pdist)
		if GameState.is_prompt_owner(self) and Input.is_action_just_pressed("action"):
			_commission_upgrade()
	else:
		GameState.show_action_prompt(self,
			"Reinforce to %s — Requires Foundry unlock" % TIER_NAMES[current_tier() + 1], 8, pdist)

func _drop_prompt() -> void:
	if _prompt_showing:
		_prompt_showing = false
		GameState.hide_action_prompt(self)

func _commission_upgrade() -> void:
	if not GameState.spend_glimmer(UPGRADE_COST):
		return
	_upgrade_commissioned = true
	_drop_prompt()

func current_tier() -> int:
	return ceili(float(maxi(_hp, 1)) / 2.0)

func is_healthy() -> bool:
	return _hp > 0 and (_hp % 2) == 0

func can_upgrade() -> bool:
	if not is_healthy() or _hp >= MAX_HP:
		return false
	# Material gating (EP-06): tier 3 needs the Cosmodrome foundry unlock,
	# tier 4 needs the metal unlock (future planet)
	var next_tier: int = current_tier() + 1
	if next_tier >= 3 and not GameState.stone_unlocked:
		return false
	if next_tier >= 4 and not GameState.metal_unlocked:
		return false
	return true

func take_damage(amount: int) -> void:
	if _collapsed:
		return
	_hit_buffer += amount
	if _hit_buffer < HITS_PER_HP:
		return
	_hit_buffer = 0
	_hp = maxi(_hp - 1, 0)
	if _hp <= 0:
		_collapsed = true
		_collapse()
		return
	_update_visual()

func _update_visual() -> void:
	if _hp <= 0:
		return
	var tier: int = current_tier()
	_sprite.modulate = COLOR_BROKEN[tier] if (_hp % 2) == 1 else COLOR_HEALTHY[tier]

func repair() -> void:
	if _hp <= 0:
		return
	_hit_buffer = 0  # cancel any partially-accumulated damage
	if (_hp % 2) == 1:  # broken state — restore to healthy within this tier
		_hp = mini(_hp + 1, MAX_HP)
		_update_visual()

func upgrade() -> void:
	if not can_upgrade():
		return
	_hit_buffer = 0
	_hp = mini(_hp + 2, MAX_HP)
	_upgrade_commissioned = false
	Sound.play("thunk", 0.0, 1.1)
	_update_visual()

func _collapse() -> void:
	var build_site_scene: PackedScene = load("res://scenes/world/build_site.tscn")
	var site: Node2D = build_site_scene.instantiate() as Node2D
	site.global_position = global_position
	site.set("_remembered_tier", current_tier())
	get_parent().add_child(site)
	queue_free()
