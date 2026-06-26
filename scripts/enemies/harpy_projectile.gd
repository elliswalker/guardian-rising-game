extends Area2D

# Harpy projectile — fast shot that travels left, targeting the player and frames.
# Bypasses walls (they're at ground level; this is fired from above).

const SPEED  := 100.0
const DAMAGE := 1

func _ready() -> void:
	collision_layer = 0
	collision_mask = 24  # player(8) + frames(16)
	body_entered.connect(_on_body_entered)
	get_tree().create_timer(4.0).timeout.connect(queue_free)

func _process(delta: float) -> void:
	position.x -= SPEED * delta

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(DAMAGE)
		queue_free()
	elif body.is_in_group("frame_npc"):
		if body.has_method("knocked_dormant"):
			body.knocked_dormant()
		queue_free()
