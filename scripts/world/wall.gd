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

@onready var _sprite: Sprite2D = $WallSprite

# Set this before add_child() to spawn a wall at the correct tier.
# Default 2 = Healthy Wood.
var _hp: int = 2
var _hit_buffer: int = 0  # accumulates hits; every HITS_PER_HP reduces _hp by 1
var _collapsed: bool = false

func _ready() -> void:
	add_to_group("walls")
	collision_layer = 2
	collision_mask = 0
	_update_visual()

func current_tier() -> int:
	return ceili(float(maxi(_hp, 1)) / 2.0)

func is_healthy() -> bool:
	return _hp > 0 and (_hp % 2) == 0

func can_upgrade() -> bool:
	return is_healthy() and _hp < MAX_HP

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
	_update_visual()

func _collapse() -> void:
	var build_site_scene: PackedScene = load("res://scenes/world/build_site.tscn")
	var site: Node2D = build_site_scene.instantiate() as Node2D
	site.global_position = global_position
	site.set("_remembered_tier", current_tier())
	get_parent().add_child(site)
	queue_free()
