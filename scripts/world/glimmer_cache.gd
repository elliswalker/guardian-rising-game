extends Area2D

var glimmer_amount: int = 75
# Shards knocked loose in combat despawn; standing caches (0) never do.
var despawn_after: float = 0.0

var _bob_time: float = 0.0
var _base_y: float = 0.0
var _age: float = 0.0

func _ready() -> void:
	add_to_group("glimmer_caches")
	_base_y = position.y
	collision_mask = 8 | 16  # player (layer 4) + frame NPCs (layer 5)
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	_bob_time += delta
	position.y = _base_y + sin(_bob_time * 3.0) * 1.0
	if despawn_after <= 0.0:
		return
	_age += delta
	var remaining: float = despawn_after - _age
	if remaining <= 0.0:
		queue_free()
	elif remaining < 5.0:
		# blink faster as despawn approaches
		visible = fmod(_age, 0.4) < (0.2 + remaining * 0.04)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.is_in_group("sweeperbots"):
		GameState.add_glimmer(glimmer_amount)
		queue_free()
