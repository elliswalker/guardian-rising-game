extends Area2D

# Hobgoblin ranged beam — travels left, damages walls/towers/frames on contact.

const SPEED  := 140.0
const DAMAGE := 1

func _ready() -> void:
	collision_layer = 0
	collision_mask = 22  # walls(2) + towers(4) + frames(16)
	body_entered.connect(_on_body_entered)
	get_tree().create_timer(3.0).timeout.connect(queue_free)

func _process(delta: float) -> void:
	position.x -= SPEED * delta

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("walls") or body.is_in_group("towers"):
		if body.has_method("take_damage"):
			body.take_damage(DAMAGE)
		queue_free()
	elif body.is_in_group("frame_npc"):
		if body.has_method("knocked_dormant"):
			body.knocked_dormant()
		queue_free()
