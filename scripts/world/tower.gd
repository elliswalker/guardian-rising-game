extends StaticBody2D

const MAX_HP         := 8
const SHOOT_RANGE    := 110.0
const SHOOT_COOLDOWN := 2.0
const HITS_PER_HP    := 4  # tower is sturdier than a wall

const COLOR_HEALTHY    := Color(0.50, 0.44, 0.36, 1.0)
const COLOR_DAMAGED    := Color(0.28, 0.22, 0.16, 1.0)
const COLOR_GARRISONED := Color(0.30, 0.65, 0.35, 1.0)

@onready var _sprite: ColorRect = $TowerSprite

var _hp: int = MAX_HP
var _hit_buffer: int = 0
var _collapsed: bool = false
var _garrison: Node2D = null
var _shoot_timer: float = 0.0
var _bullet_scene: PackedScene = null

func _ready() -> void:
	add_to_group("towers")
	collision_layer = 4  # always solid — enemies target and attack towers
	collision_mask = 0
	var bullet_path := "res://scenes/world/bullet.tscn"
	if ResourceLoader.exists(bullet_path):
		_bullet_scene = load(bullet_path)
	_update_visual()

func _process(delta: float) -> void:
	_shoot_timer -= delta
	if _shoot_timer <= 0.0:
		_shoot_timer = SHOOT_COOLDOWN
		_fire_at_nearest_enemy()

# Garrison API kept for future use — towers currently auto-fire without it
func garrison(redjack: Node2D) -> void:
	_garrison = redjack
	_update_visual()

func release_garrison() -> void:
	_garrison = null
	_update_visual()

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
		if _garrison and is_instance_valid(_garrison) and _garrison.has_method("exit_tower"):
			_garrison.exit_tower()
		_garrison = null
		queue_free()
		return
	_update_visual()

func _update_visual() -> void:
	if _garrison != null and is_instance_valid(_garrison):
		_sprite.color = COLOR_GARRISONED
	else:
		var t: float = float(_hp) / float(MAX_HP)
		_sprite.color = COLOR_HEALTHY.lerp(COLOR_DAMAGED, 1.0 - t)

func _fire_at_nearest_enemy() -> void:
	if not _bullet_scene:
		return
	var nearest: Node2D = null
	var nearest_dist: float = SHOOT_RANGE
	for enemy: Node in get_tree().get_nodes_in_group("enemies"):
		var en: Node2D = enemy as Node2D
		if not en or not is_instance_valid(en):
			continue
		var dist: float = global_position.distance_to(en.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = en
	if not nearest:
		return
	var bullet: Node2D = _bullet_scene.instantiate() as Node2D
	var dir: float = sign(nearest.global_position.x - global_position.x)
	bullet.set("_dir", dir)
	bullet.global_position = global_position + Vector2(dir * 8.0, -8.0)
	get_parent().add_child(bullet)
