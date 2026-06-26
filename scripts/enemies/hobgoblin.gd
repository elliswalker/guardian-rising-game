extends CharacterBody2D

# Vex Hobgoblin — ranged sniper. Drifts slowly left, fires beam shots at walls/frames.
# Retracts into hardened shell (immune) on hit. Must be damaged 3 times to kill.

const GRAVITY             := 225.0
const DRIFT_SPEED         := 5.0
const FIRE_INTERVAL       := 4.5
const RETRACT_DURATION    := 2.0
const HP_MAX              := 3
const GLIMMER_DROP        := 8
const RETREAT_SPEED       := 28.0
const RETREAT_EXIT_X      := 900.0

const COLOR_DEFAULT   := Color.WHITE
const COLOR_RETRACTED := Color(0.5, 0.5, 0.5, 1.0)
const COLOR_HIT       := Color(1.0, 0.90, 0.30, 1.0)
const COLOR_DAMAGED   := Color(1.0, 0.5, 0.5, 1.0)

const BEAM_SCENE := preload("res://scenes/enemies/hobgoblin_beam.tscn")

@onready var _sprite: CanvasItem = $HobgoblinSprite

var _hp: int = HP_MAX
var _is_dying: bool = false
var _is_retracted: bool = false
var _retract_timer: float = 0.0
var _fire_timer: float = 0.0
var _retreating: bool = false
var _tether_timer: float = 0.0

func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 32
	collision_mask = 7
	_fire_timer = randf_range(2.0, FIRE_INTERVAL)
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
		if not is_on_floor():
			velocity.y += GRAVITY * delta
		velocity.x = RETREAT_SPEED
		move_and_slide()
		if global_position.x > RETREAT_EXIT_X:
			queue_free()
		return
	if _is_retracted:
		_retract_timer -= delta
		if _retract_timer <= 0.0:
			_is_retracted = false
			_sprite.modulate = Color.WHITE.lerp(COLOR_DAMAGED, 1.0 - float(_hp) / float(HP_MAX))
		if not is_on_floor():
			velocity.y += GRAVITY * delta
		velocity.x = 0.0
		move_and_slide()
		return
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	velocity.x = -DRIFT_SPEED
	move_and_slide()
	_fire_timer -= delta
	if _fire_timer <= 0.0:
		_fire_timer = FIRE_INTERVAL
		_shoot()

func _shoot() -> void:
	var beam = BEAM_SCENE.instantiate()
	beam.global_position = global_position + Vector2(-6.0, -12.0)
	get_parent().add_child(beam)

func take_damage(amount: int) -> void:
	if _is_dying or _tether_timer > 0.0 or _is_retracted:
		return
	_hp = maxi(_hp - amount, 0)
	if _hp <= 0:
		_die()
		return
	_is_retracted = true
	_retract_timer = RETRACT_DURATION
	_sprite.modulate = COLOR_RETRACTED

func _die() -> void:
	_is_dying = true
	set_physics_process(false)
	GameState.add_glimmer(GLIMMER_DROP)
	var tween: Tween = create_tween()
	tween.tween_property(_sprite, "modulate", COLOR_HIT, 0.08)
	tween.chain().tween_property(_sprite, "modulate:a", 0.0, 0.4)
	tween.chain().tween_callback(queue_free)
