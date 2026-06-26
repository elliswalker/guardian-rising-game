extends Node2D

const ATTACK_RANGE := 45.0
const ATTACK_COOLDOWN := 1.5

const COLOR_IDLE   := Color(0.55, 0.60, 0.65, 1.0)
const COLOR_FIRING := Color(1.0,  0.95, 0.4,  1.0)

@onready var _turret_sprite: ColorRect = $TurretSprite

var _attack_timer: float = 0.0

func _ready() -> void:
	add_to_group("defenders")

func _process(delta: float) -> void:
	_attack_timer -= delta
	if _attack_timer <= 0.0:
		_attack_timer = ATTACK_COOLDOWN
		_attack_nearest_enemy()

func _attack_nearest_enemy() -> void:
	var nearest: Node = null
	var nearest_dist: float = ATTACK_RANGE
	for enemy: Node in get_tree().get_nodes_in_group("enemies"):
		var enemy_node: Node2D = enemy as Node2D
		if not enemy_node:
			continue
		var dist: float = global_position.distance_to(enemy_node.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = enemy
	if nearest and nearest.has_method("take_damage"):
		nearest.take_damage(1)
		_flash()

func _flash() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(_turret_sprite, "color", COLOR_FIRING, 0.0)
	tween.tween_interval(0.1)
	tween.tween_property(_turret_sprite, "color", COLOR_IDLE, 0.15)
