extends StaticBody2D

const MAX_HP         := 8
const SHOOT_RANGE    := 110.0
const SHOOT_COOLDOWN := 2.0
const HITS_PER_HP    := 4  # tower is sturdier than a wall
const BUILD_COST     := 150
const BUILD_SWINGS   := 4

const COLOR_HEALTHY    := Color(0.50, 0.44, 0.36, 1.0)
const COLOR_DAMAGED    := Color(0.28, 0.22, 0.16, 1.0)
const COLOR_UNBUILT    := Color(0.35, 0.33, 0.30, 0.45)

@onready var _sprite: Sprite2D = $TowerSprite

var _built: bool = false
var _commissioned: bool = false
var _build_progress: int = 0
var _hp: int = MAX_HP
var _hit_buffer: int = 0
var _collapsed: bool = false
var _shoot_timer: float = 0.0
var _player_nearby: bool = false
var _bullet_scene: PackedScene = null

func _ready() -> void:
	add_to_group("towers")
	collision_layer = 0  # passable scaffold until built
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
	if not _built:
		if _player_nearby and not _commissioned:
			GameState.show_action_prompt(self, "[ SPACE ]  Build Tower  —  %d ◈" % BUILD_COST, 12)
			if GameState.is_prompt_owner(self) and Input.is_action_just_pressed("action"):
				_commission()
		return
	_shoot_timer -= delta
	if _shoot_timer <= 0.0:
		_shoot_timer = SHOOT_COOLDOWN
		_fire_at_nearest_enemy()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_nearby = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_nearby = false
		if not _built:
			GameState.hide_action_prompt(self)

func _commission() -> void:
	if not GameState.spend_glimmer(BUILD_COST):
		return
	_commissioned = true
	GameState.hide_action_prompt(self)
	GameState.queue_build_job(self)

# Builder interface — same contract as build_site.gd / ship.gd
func add_progress(amount: int) -> bool:
	if _built:
		return true
	_build_progress = mini(_build_progress + amount, BUILD_SWINGS)
	if _build_progress >= BUILD_SWINGS:
		_built = true
		collision_layer = 4  # now solid — enemies can target and attack it
		_update_visual()
	return true

func is_complete() -> bool:
	return _built

func take_damage(amount: int) -> void:
	if _collapsed or not _built:
		return
	_hit_buffer += amount
	if _hit_buffer < HITS_PER_HP:
		return
	_hit_buffer = 0
	_hp = maxi(_hp - 1, 0)
	if _hp <= 0:
		_collapsed = true
		queue_free()
		return
	_update_visual()

func _update_visual() -> void:
	if not _built:
		_sprite.modulate = COLOR_UNBUILT
		return
	var t: float = float(_hp) / float(MAX_HP)
	_sprite.modulate = COLOR_HEALTHY.lerp(COLOR_DAMAGED, 1.0 - t)

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
