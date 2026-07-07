extends Area2D

# Small special pickups: Legendary Shards and Motes of Light (EP-08).
# kind = "shard" → +1 Legendary Shard on player contact
# kind = "mote"  → shaves seconds off the next super cooldown

@export var kind: String = "shard"

const MOTE_REDUCTION := 2.0
const MOTE_CAP       := 12.0
const MOTE_DESPAWN   := 15.0

@onready var _body: Sprite2D = $Body  # drawn shard art (#49)

var _bob_time: float = 0.0
var _base_y: float = 0.0
var _age: float = 0.0

func _ready() -> void:
	collision_mask = 8  # player only
	_base_y = position.y
	body_entered.connect(_on_body_entered)
	if kind == "mote":
		_body.self_modulate = Color(0.75, 1.05, 1.35, 1.0)  # mote: shift violet art to ice-blue
	else:
		_body.self_modulate = Color.WHITE  # shard: native violet

func _process(delta: float) -> void:
	_bob_time += delta
	position.y = _base_y + sin(_bob_time * 3.5) * 1.5
	if kind == "mote":
		_age += delta
		if _age >= MOTE_DESPAWN:
			queue_free()
		elif _age > MOTE_DESPAWN - 4.0:
			visible = fmod(_age, 0.4) < 0.25

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	if kind == "shard":
		GameState.add_shard(1)
	else:
		GameState.mote_reduction = minf(GameState.mote_reduction + MOTE_REDUCTION, MOTE_CAP)
	queue_free()
