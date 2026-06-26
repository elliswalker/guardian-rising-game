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
var _player_nearby: bool = false
var _bullet_scene: PackedScene = null

func _ready() -> void:
	add_to_group("towers")
	collision_layer = 0  # passable until garrisoned
	collision_mask = 0
	var bullet_path := "res://scenes/world/bullet.tscn"
	if ResourceLoader.exists(bullet_path):
		_bullet_scene = load(bullet_path)
	_update_visual()
	var zone: Area2D = $GarrisonZone
	if zone:
		zone.body_entered.connect(_on_body_entered)
		zone.body_exited.connect(_on_body_exited)

func _process(delta: float) -> void:
	# Re-assert prompt every frame so it survives preemption by higher-priority prompts
	if _player_nearby and _garrison == null:
		if _has_nearby_tree():
			GameState.show_action_prompt(self, "Clear the area first", 5)
		else:
			GameState.show_action_prompt(self, "[ SPACE ]  Garrison Tower", 5)
		if Input.is_action_just_pressed("action") and not _has_nearby_tree():
			_assign_nearest_redjack()

	# Fire at enemies when garrisoned
	if _garrison == null or not is_instance_valid(_garrison):
		_garrison = null
		return
	_shoot_timer -= delta
	if _shoot_timer <= 0.0:
		_shoot_timer = SHOOT_COOLDOWN
		_fire_at_nearest_enemy()

func _has_nearby_tree() -> bool:
	for tree: Node in get_tree().get_nodes_in_group("trees"):
		var tn: Node2D = tree as Node2D
		if tn and global_position.distance_to(tn.global_position) < 38.0:
			if not tn.get("_commissioned"):
				return true
	return false

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_nearby = true
		if _garrison == null:
			if _has_nearby_tree():
				GameState.show_action_prompt(self, "Clear the area first", 5)
			else:
				GameState.show_action_prompt(self, "[ SPACE ]  Garrison Tower", 5)

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_nearby = false
		GameState.hide_action_prompt(self)

func _assign_nearest_redjack() -> void:
	var best: Node2D = null
	var best_dist: float = INF
	for f: Node in get_tree().get_nodes_in_group("redjacks"):
		var fn: Node2D = f as Node2D
		if not fn or not is_instance_valid(fn):
			continue
		if not fn.has_method("is_available_for_garrison"):
			continue
		if not fn.call("is_available_for_garrison"):
			continue
		var dist: float = global_position.distance_to(fn.global_position)
		if dist < best_dist:
			best_dist = dist
			best = fn
	if best and best.has_method("walk_to_tower"):
		GameState.action_prompt_hide.emit()
		_player_nearby = false
		best.call("walk_to_tower", self)

func garrison(redjack: Node2D) -> void:
	_garrison = redjack
	collision_layer = 4  # now solid — enemies can target and attack it
	_update_visual()

func release_garrison() -> void:
	_garrison = null
	collision_layer = 0  # back to passable
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
