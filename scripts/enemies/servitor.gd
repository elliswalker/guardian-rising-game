extends CharacterBody2D

const HP_MAX           := 20
const MOVE_SPEED       := 5.0
const TETHER_RANGE     := 95.0
const TETHER_INTERVAL  := 4.5
const TETHER_DURATION  := 2.2
const HOVER_AMPLITUDE  := 7.0
const HOVER_SPEED      := 1.4
const PATROL_LEFT_X    := 650.0
const PATROL_RIGHT_X   := 750.0

const COLOR_HEALTHY := Color.WHITE
const COLOR_DAMAGED := Color(1.0, 0.5, 0.5, 1.0)
const COLOR_HIT     := Color(1.0,  0.5,  1.0,  1.0)

@onready var _sprite:       CanvasItem = $ServitorSprite
@onready var _tether_ring:  ColorRect = $TetherRing
@onready var _glow:         ColorRect = $Glow

var _hp: int = HP_MAX
var _is_dying: bool = false
var _tether_timer: float = TETHER_INTERVAL * 0.6
var _hover_time: float = 0.0
var _patrol_dir: float = -1.0

func _ready() -> void:
	add_to_group("enemies")
	add_to_group("bosses")
	collision_layer = 32
	collision_mask = 0   # floats, doesn't walk on ground
	motion_mode = MOTION_MODE_FLOATING
	_update_visual()

func _physics_process(delta: float) -> void:
	if _is_dying:
		return
	_hover_time += delta
	velocity.x = _patrol_dir * MOVE_SPEED
	velocity.y = sin(_hover_time * HOVER_SPEED) * HOVER_AMPLITUDE * 2.5
	if global_position.x <= PATROL_LEFT_X:
		_patrol_dir = 1.0
	elif global_position.x >= PATROL_RIGHT_X:
		_patrol_dir = -1.0
	move_and_slide()
	_tether_timer -= delta
	if _tether_timer <= 0.0:
		_tether_timer = TETHER_INTERVAL
		_cast_tether()

func _cast_tether() -> void:
	_tether_ring.modulate.a = 0.9
	var tween: Tween = create_tween()
	tween.tween_property(_tether_ring, "modulate:a", 0.0, 0.55)
	for enemy: Node in get_tree().get_nodes_in_group("enemies"):
		if enemy == self:
			continue
		var en: Node2D = enemy as Node2D
		if not en or not is_instance_valid(en):
			continue
		if global_position.distance_to(en.global_position) < TETHER_RANGE:
			if en.has_method("apply_tether"):
				en.apply_tether(TETHER_DURATION)

# Dual-portal planets: set before add_child to bind this servitor to one portal
var bound_portal_x: float = INF

func take_damage(amount: int) -> void:
	if _is_dying:
		return
	_hp = maxi(_hp - amount, 0)
	_update_visual()
	var flash: Tween = create_tween()
	flash.tween_property(_sprite, "modulate", COLOR_HIT, 0.0)
	flash.tween_interval(0.08)
	flash.tween_property(_sprite, "modulate", _sprite.modulate, 0.14)
	if _hp <= 0:
		_die()

func _die() -> void:
	_is_dying = true
	set_physics_process(false)
	for portal: Node in get_tree().get_nodes_in_group("portals"):
		if not portal.has_method("break_portal"):
			continue
		# Bound servitors (dual-portal planets) only break their own portal
		var pn: Node2D = portal as Node2D
		if bound_portal_x != INF and pn and absf(pn.global_position.x - bound_portal_x) > 120.0:
			continue
		portal.call("break_portal")
	_launch_skiff()
	var tween: Tween = create_tween()
	tween.tween_property(_sprite, "modulate:a", 0.0, 1.8)
	tween.tween_property(_glow,   "modulate:a", 0.0, 1.2)
	tween.chain().tween_callback(queue_free)

func _launch_skiff() -> void:
	var skiff: ColorRect = ColorRect.new()
	skiff.size = Vector2(44, 12)
	skiff.color = Color(0.28, 0.32, 0.38, 0.92)
	skiff.position = Vector2(global_position.x - 22.0, global_position.y - 18.0)
	get_parent().add_child(skiff)
	var tween: Tween = skiff.create_tween()
	tween.set_parallel(true)
	tween.tween_property(skiff, "position:x", global_position.x + 260.0, 3.0).set_ease(Tween.EASE_IN)
	tween.tween_property(skiff, "position:y", global_position.y - 130.0,  3.0).set_ease(Tween.EASE_OUT)
	tween.tween_property(skiff, "modulate:a", 0.0, 3.0)
	tween.chain().tween_callback(skiff.queue_free)

func _update_visual() -> void:
	var t: float = float(_hp) / float(HP_MAX)
	_sprite.modulate = Color.WHITE.lerp(COLOR_DAMAGED, 1.0 - t)
