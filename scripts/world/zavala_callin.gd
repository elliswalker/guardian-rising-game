extends Node2D

# Zavala call-in — Striker Smash (EP-08, Moon shrine). The Titan drops in,
# winds up, and slams: heavy damage to everything in the blast radius.
# Every kill sheds a Mote of Light.

const WINDUP        := 0.55
const SLAM_DAMAGE   := 4
const SLAM_RADIUS   := 100.0

const SHOCKWAVE_SCENE := preload("res://scenes/world/ability_shockwave.tscn")
const PICKUP_SCENE    := preload("res://scenes/world/pickup.tscn")

const COLOR_ZAVALA := Color(0.45, 0.55, 0.75, 1.0)
const COLOR_ARC    := Color(0.55, 0.80, 1.0, 1.0)

var _timer: float = WINDUP
var _slammed: bool = false
var _body: ColorRect

func _ready() -> void:
	_body = ColorRect.new()
	_body.size = Vector2(10, 20)
	_body.position = Vector2(-5, -20)
	_body.color = COLOR_ZAVALA
	add_child(_body)
	var crest: ColorRect = ColorRect.new()
	crest.size = Vector2(4, 3)
	crest.position = Vector2(-2, -23)
	crest.color = COLOR_ARC
	add_child(crest)
	# drops in from above
	position.y -= 40.0
	var tween: Tween = create_tween()
	tween.tween_property(self, "position:y", position.y + 40.0, 0.3).set_ease(Tween.EASE_IN)

func _process(delta: float) -> void:
	_timer -= delta
	if _slammed or _timer > 0.0:
		return
	_slammed = true
	_slam()

func _slam() -> void:
	Sound.play("thunk", 2.0, 0.55)
	Sound.play("shot", -4.0, 0.7)
	var wave: Node2D = SHOCKWAVE_SCENE.instantiate() as Node2D
	wave.global_position = global_position
	get_parent().add_child(wave)
	for enemy: Node in get_tree().get_nodes_in_group("enemies"):
		var en: Node2D = enemy as Node2D
		if not en or not is_instance_valid(en):
			continue
		if global_position.distance_to(en.global_position) > SLAM_RADIUS:
			continue
		var pos: Vector2 = en.global_position
		if en.has_method("take_damage"):
			en.take_damage(SLAM_DAMAGE)
		var mote: Area2D = PICKUP_SCENE.instantiate() as Area2D
		mote.set("kind", "mote")
		mote.global_position = Vector2(pos.x, 145.0)
		get_parent().call_deferred("add_child", mote)
	var tween: Tween = create_tween()
	tween.tween_interval(0.5)
	tween.tween_property(self, "modulate:a", 0.0, 0.4)
	tween.tween_callback(queue_free)
