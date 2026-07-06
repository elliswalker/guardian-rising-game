extends CharacterBody2D

# Cabal Phalanx — a walking siege door. Very slow, very tough behind the
# tower shield, and hits walls like a battering ram.

const MOVE_SPEED          := 7.0
const GRAVITY             := 225.0
const GLIMMER_DROP        := 14
const WALL_ATTACK_COOLDOWN := 3.0
const RETREAT_SPEED       := 14.0
const HP_MAX              := 6

const COLOR_DEFAULT := Color.WHITE
const COLOR_HIT     := Color(1.0, 0.6, 0.3, 1.0)
const COLOR_DAMAGED := Color(1.0, 0.5, 0.5, 1.0)

@onready var _sprite: Sprite2D = $PhalanxSprite

# 2-frame walk cycle (#46)
const TEX_STAND := preload("res://assets/sprites/enemies/cabal/phalanx_right.png")
const TEX_WALK  := TEX_STAND  # same texture until the animation sheets (#49 phase F)
const WALK_FRAME_TIME := 0.28
var _walk_t: float = 0.0

func _animate_walk(delta: float) -> void:
	if not _sprite:
		return
	if absf(velocity.x) < 2.0:
		_walk_t = 0.0
		_sprite.texture = TEX_STAND
		return
	_sprite.flip_h = velocity.x < 0.0  # Pro art faces right
	_walk_t += delta
	_sprite.texture = TEX_WALK if fmod(_walk_t, WALK_FRAME_TIME * 2.0) >= WALK_FRAME_TIME else TEX_STAND

var march_dir: float = -1.0
var exit_x: float = 850.0

var _hp: int = HP_MAX
var _is_dying: bool = false
var _wall_attack_timer: float = 0.0
var _retreating: bool = false

func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 32
	collision_mask = 7
	_wall_attack_timer = randf() * WALL_ATTACK_COOLDOWN
	GameState.dawn_triggered.connect(func(_d: int) -> void:
		if not _is_dying:
			_retreating = true)

func retreat() -> void:
	if not _is_dying:
		_retreating = true

func _physics_process(delta: float) -> void:
	_animate_walk(delta)
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	if _retreating:
		velocity.x = signf(exit_x - global_position.x) * RETREAT_SPEED
		move_and_slide()
		if absf(global_position.x - exit_x) < 12.0:
			queue_free()
		return
	# no target-seeking — the door only knows forward
	velocity.x = march_dir * MOVE_SPEED
	move_and_slide()
	_wall_attack_timer -= delta
	if _wall_attack_timer <= 0.0:
		_process_attacks()

func _process_attacks() -> void:
	_wall_attack_timer = WALL_ATTACK_COOLDOWN
	for i in get_slide_collision_count():
		var col: KinematicCollision2D = get_slide_collision(i)
		var body := col.get_collider()
		if body is Node:
			var n: Node = body as Node
			if (n.is_in_group("walls") or n.is_in_group("towers")) and n.has_method("take_damage"):
				n.take_damage(3)  # battering ram
				Sound.play("thunk", -6.0, 0.7)
				return

func take_damage(amount: int) -> void:
	if _is_dying:
		return
	_hp = maxi(_hp - amount, 0)
	if _hp <= 0:
		_die()
		return
	var damaged_color: Color = Color.WHITE.lerp(COLOR_DAMAGED, 1.0 - float(_hp) / float(HP_MAX))
	var tween := create_tween()
	tween.tween_property(_sprite, "modulate", COLOR_HIT, 0.0)
	tween.tween_property(_sprite, "modulate", damaged_color, 0.2)

func _die() -> void:
	_is_dying = true
	set_physics_process(false)
	GameState.add_glimmer(GLIMMER_DROP)
	var tween := create_tween()
	tween.tween_property(_sprite, "modulate", COLOR_HIT, 0.0)
	tween.tween_property(_sprite, "modulate:a", 0.0, 0.4)
	tween.tween_callback(queue_free)
