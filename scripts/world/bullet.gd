extends Area2D

const SPEED  := 120.0
const DAMAGE := 1
const MAX_X  := 420.0  # despawn if it leaves the active area

@onready var _sprite: ColorRect = $BulletSprite

var _dir: float = 1.0  # set by tower before add_child: sign toward target

func _ready() -> void:
	collision_layer = 0
	collision_mask = 32  # layer 32 — enemy layer
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	position.x += _dir * SPEED * delta
	if abs(global_position.x) > MAX_X:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		body.take_damage(DAMAGE)
		queue_free()
