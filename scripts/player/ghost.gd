extends Node2D

const MAX_TETHER: float = 105.0
const FOLLOW_SPEED: float = 8.0
const BOB_SPEED: float = 2.5
const BOB_AMPLITUDE: float = 2.0
const WARNING_THRESHOLD: float = 0.65

const ABILITY_COOLDOWN := 20.0
const ABILITY_COOLDOWN_MIN := 8.0

const CALLIN_SCENES: Dictionary = {
	"golden_gun": preload("res://scenes/world/cayde_callin.tscn"),
	"striker": preload("res://scenes/world/zavala_callin.tscn"),
}

signal ability_cooldown_updated(fraction: float)  # 1.0 = ready, 0.0 = just used

const COLOR_NORMAL_BODY := Color(0.9, 0.95, 1.0, 0.9)
const COLOR_NORMAL_GLOW := Color(0.4, 0.8, 1.0, 0.25)
const COLOR_CAPTURED_BODY := Color(1.0, 0.35, 0.1, 0.9)
const COLOR_CAPTURED_GLOW := Color(1.0, 0.2, 0.0, 0.3)

@onready var _ghost_sprite: CanvasItem = $GhostSprite
@onready var _glow_sprite: ColorRect = $GlowSprite
@onready var _pulse_ring: ColorRect = $PulseRing

var player: CharacterBody2D
var is_captured: bool = false
var carrier: Node2D = null
var invincible: bool = false
var _bob_time: float = 0.0
var _base_offset: Vector2 = Vector2(18.0, -22.0)
var _ability_cooldown_remaining: float = 0.0
var _ability_cooldown_total: float = ABILITY_COOLDOWN

func _ready() -> void:
	add_to_group("ghost")
	player = get_tree().get_first_node_in_group("player") as CharacterBody2D
	GameState.dusk_triggered.connect(_on_dusk_triggered)

func _process(delta: float) -> void:
	_bob_time += delta

	if is_captured and carrier and is_instance_valid(carrier):
		global_position = carrier.global_position + Vector2(0.0, -12.0)
		_apply_struggle(delta)
	elif player:
		_follow_player(delta)

	_check_tether()
	_tick_cooldown(delta)
	queue_redraw()

func _tick_cooldown(delta: float) -> void:
	if _ability_cooldown_remaining <= 0.0:
		return
	_ability_cooldown_remaining -= delta
	if _ability_cooldown_remaining <= 0.0:
		_ability_cooldown_remaining = 0.0
	ability_cooldown_updated.emit(1.0 - _ability_cooldown_remaining / _ability_cooldown_total)

# The Speaker doesn't fight (Kingdom rule) — supers are named Guardians
# answering the call. No elemental Ghost bonded yet = no super at all.
func use_ability() -> void:
	if _ability_cooldown_remaining > 0.0 or is_captured:
		return
	if not CALLIN_SCENES.has(GameState.equipped_super):
		return
	# Motes of Light collected since the last super shorten this cooldown
	_ability_cooldown_total = maxf(ABILITY_COOLDOWN - GameState.mote_reduction, ABILITY_COOLDOWN_MIN)
	GameState.mote_reduction = 0.0
	_ability_cooldown_remaining = _ability_cooldown_total
	ability_cooldown_updated.emit(0.0)
	var callin: Node2D = CALLIN_SCENES[GameState.equipped_super].instantiate() as Node2D
	callin.global_position = Vector2(global_position.x, 148.0)
	get_parent().add_child(callin)

func _follow_player(delta: float) -> void:
	var target: Vector2 = player.global_position + _base_offset
	global_position = global_position.lerp(target, FOLLOW_SPEED * delta)
	position.y += sin(_bob_time * BOB_SPEED) * BOB_AMPLITUDE * delta

func _apply_struggle(delta: float) -> void:
	var t: float = _bob_time * 10.0
	position += Vector2(sin(t * 7.3) * 0.6, cos(t * 5.1) * 0.6) * delta * 60.0

func _check_tether() -> void:
	if not player or invincible:
		return
	var dist: float = global_position.distance_to(player.global_position)
	if dist >= MAX_TETHER:
		GameState.trigger_game_over()

func _draw() -> void:
	if not player:
		return
	var dist: float = global_position.distance_to(player.global_position)
	var t: float = clamp(dist / MAX_TETHER, 0.0, 1.0)

	if t < WARNING_THRESHOLD and not is_captured:
		return

	var alpha: float = remap(t, WARNING_THRESHOLD, 1.0, 0.0, 1.0) if not is_captured else 0.6
	var col: Color = Color(0.4 + t * 0.4, 0.8 - t * 0.6, 1.0 - t * 0.8, alpha)
	var width: float = 1.0 + t * 2.0
	draw_line(Vector2.ZERO, to_local(player.global_position), col, width)

func capture(enemy: Node2D) -> void:
	if invincible:
		return
	is_captured = true
	carrier = enemy
	GameState.on_ghost_captured()
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(_ghost_sprite, "modulate", COLOR_CAPTURED_BODY, 0.3)
	tween.tween_property(_glow_sprite, "color", COLOR_CAPTURED_GLOW, 0.3)

func release() -> void:
	is_captured = false
	carrier = null
	GameState.on_ghost_released()
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(_ghost_sprite, "modulate", COLOR_NORMAL_BODY, 0.4)
	tween.tween_property(_glow_sprite, "color", COLOR_NORMAL_GLOW, 0.4)

func set_invincible(value: bool) -> void:
	invincible = value

func _on_dusk_triggered(_day: int) -> void:
	_emit_pulse()

func _emit_pulse() -> void:
	if not _pulse_ring:
		return
	_pulse_ring.pivot_offset = Vector2(7.0, 7.0)
	_pulse_ring.scale = Vector2.ONE
	_pulse_ring.modulate.a = 0.85
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(_pulse_ring, "scale", Vector2(7.0, 7.0), 1.4).set_ease(Tween.EASE_OUT)
	tween.tween_property(_pulse_ring, "modulate:a", 0.0, 1.4).set_ease(Tween.EASE_OUT)
