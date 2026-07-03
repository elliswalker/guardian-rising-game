extends Node2D

# Wildlife — small scavenger critters that roam the field during the day.
# Redjacks hunt them on patrol for glimmer (the Kingdom archer income role).
# They vanish at dusk.

const WANDER_SPEED   := 5.0
const FLEE_SPEED     := 16.0
const FLEE_RANGE     := 30.0   # bolts when a redjack gets this close
const WANDER_BOUND   := 60.0   # stays within this range of its spawn point
const GLIMMER_MIN    := 12
const GLIMMER_MAX    := 24
const WANDER_CHANGE_MIN := 1.2
const WANDER_CHANGE_MAX := 3.0

@onready var _body: Sprite2D = $Body

var _home_x: float = 0.0
var _dir: float = 1.0
var _wander_timer: float = 0.0
var _dead: bool = false

func _ready() -> void:
	add_to_group("wildlife")
	_home_x = global_position.x
	_dir = [-1.0, 1.0][randi() % 2]
	_wander_timer = randf_range(WANDER_CHANGE_MIN, WANDER_CHANGE_MAX)
	GameState.dusk_triggered.connect(_on_dusk_triggered)

func _process(delta: float) -> void:
	if _dead:
		return
	var hunter: Node2D = _nearest_hunter()
	if hunter and global_position.distance_to(hunter.global_position) < FLEE_RANGE:
		# bolt away from the hunter — catchable, but it takes a chase
		_dir = sign(global_position.x - hunter.global_position.x)
		if _dir == 0.0:
			_dir = 1.0
		global_position.x += _dir * FLEE_SPEED * delta
	else:
		_wander_timer -= delta
		if _wander_timer <= 0.0:
			_wander_timer = randf_range(WANDER_CHANGE_MIN, WANDER_CHANGE_MAX)
			_dir = [-1.0, 1.0][randi() % 2]
		global_position.x += _dir * WANDER_SPEED * delta
	# spring back toward home range
	if abs(global_position.x - _home_x) > WANDER_BOUND:
		_dir = sign(_home_x - global_position.x)
	if _body:
		_body.scale.x = -1.0 if _dir < 0.0 else 1.0

func _nearest_hunter() -> Node2D:
	var nearest: Node2D = null
	var nearest_dist: float = FLEE_RANGE
	for r: Node in get_tree().get_nodes_in_group("redjacks"):
		var rn: Node2D = r as Node2D
		if rn and is_instance_valid(rn):
			var dist: float = global_position.distance_to(rn.global_position)
			if dist < nearest_dist:
				nearest_dist = dist
				nearest = rn
	return nearest

func take_damage(_amount: int) -> void:
	if _dead:
		return
	_dead = true
	GameState.add_glimmer(randi_range(GLIMMER_MIN, GLIMMER_MAX))
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.25)
	tween.tween_callback(queue_free)

func _on_dusk_triggered(_day: int) -> void:
	# fauna clears out before the Fallen arrive
	if _dead:
		return
	_dead = true
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 1.5)
	tween.tween_callback(queue_free)
