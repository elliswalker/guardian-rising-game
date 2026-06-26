extends Area2D

var glimmer_amount: int = 75

var _bob_time: float = 0.0
var _base_y: float = 0.0

func _ready() -> void:
	add_to_group("glimmer_caches")
	_base_y = position.y
	collision_mask = 8 | 16  # player (layer 4) + frame NPCs (layer 5)
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	_bob_time += delta
	position.y = _base_y + sin(_bob_time * 3.0) * 1.0

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.is_in_group("sweeperbots"):
		GameState.add_glimmer(glimmer_amount)
		queue_free()
