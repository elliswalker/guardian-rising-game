extends Area2D

const SPEED      := 120.0
const MAX_TRAVEL := 400.0  # despawn after traveling this far from launch

@onready var _sprite: ColorRect = $BulletSprite

var _dir: float = 1.0    # set by tower before add_child: sign toward target
var damage: int = 1      # ballista towers fire heavier shots
var _start_x: float = 0.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 32  # layer 32 — enemy layer
	_start_x = global_position.x
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	position.x += _dir * SPEED * delta
	if absf(global_position.x - _start_x) > MAX_TRAVEL:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		body.take_damage(damage)
		queue_free()
