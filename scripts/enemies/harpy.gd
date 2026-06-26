extends CharacterBody2D

# Vex Harpy — aerial unit that flies above the wall line, bypassing all ground defenses.
# Fires projectiles at the player and frames. Vulnerable to tower fire and redjacks.

const MOVE_SPEED      := 22.0
const HOVER_Y         := 100.0   # above the wall line (walls are at y=148)
const FIRE_INTERVAL   := 5.0
const HP_MAX          := 2
const GLIMMER_DROP    := 5
const RETREAT_SPEED   := 32.0
const RETREAT_EXIT_X  := 900.0

const COLOR_DEFAULT := Color.WHITE
const COLOR_HIT     := Color(1.0, 0.95, 0.40, 1.0)

const PROJECTILE_SCENE := preload("res://scenes/enemies/harpy_projectile.tscn")

@onready var _sprite: CanvasItem = $HarpySprite

var _hp: int = HP_MAX
var _is_dying: bool = false
var _fire_timer: float = 0.0
var _retreating: bool = false
var _tether_timer: float = 0.0

func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 32
	collision_mask = 1   # ground only — no wall/tower collisions (flies over them)
	motion_mode = MOTION_MODE_FLOATING
	_fire_timer = randf_range(1.5, FIRE_INTERVAL)
	GameState.dawn_triggered.connect(_on_dawn_triggered)

func _on_dawn_triggered(_day: int) -> void:
	if not _is_dying:
		_retreating = true

func apply_tether(duration: float) -> void:
	_tether_timer = maxf(_tether_timer, duration)

func _physics_process(delta: float) -> void:
	if _tether_timer > 0.0:
		_tether_timer -= delta
	if _retreating:
		velocity.x = RETREAT_SPEED
		velocity.y = 0.0
		move_and_slide()
		if global_position.x > RETREAT_EXIT_X:
			queue_free()
		return
	velocity.x = -MOVE_SPEED
	var y_diff: float = global_position.y - HOVER_Y
	velocity.y = -clampf(y_diff * 4.0, -60.0, 60.0)
	move_and_slide()
	_fire_timer -= delta
	if _fire_timer <= 0.0:
		_fire_timer = FIRE_INTERVAL
		_shoot()

func _shoot() -> void:
	var proj = PROJECTILE_SCENE.instantiate()
	proj.global_position = global_position + Vector2(-6.0, 0.0)
	get_parent().add_child(proj)

func take_damage(amount: int) -> void:
	if _is_dying or _tether_timer > 0.0:
		return
	_hp = maxi(_hp - amount, 0)
	if _hp <= 0:
		_die()
		return
	var tween: Tween = create_tween()
	tween.tween_property(_sprite, "modulate", COLOR_HIT, 0.06)
	tween.chain().tween_property(_sprite, "modulate", COLOR_DEFAULT, 0.12)

func _die() -> void:
	_is_dying = true
	set_physics_process(false)
	GameState.add_glimmer(GLIMMER_DROP)
	var tween: Tween = create_tween()
	tween.tween_property(_sprite, "modulate", COLOR_HIT, 0.06)
	tween.chain().tween_property(_sprite, "modulate:a", 0.0, 0.5)
	tween.chain().tween_callback(queue_free)
