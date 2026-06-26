extends CanvasLayer

@onready var scan_line: ColorRect = $ScanLine
@onready var message: Label = $Message

func _ready() -> void:
	scan_line.visible = false
	message.modulate.a = 0.0
	_play_opening()

func _play_opening() -> void:
	var tween: Tween = create_tween()
	tween.tween_interval(0.8)
	tween.tween_callback(func(): scan_line.visible = true)
	tween.tween_property(scan_line, "position:y", 0.0, 1.4).from(718.0).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(scan_line, "modulate:a", 0.0, 0.4)
	tween.tween_interval(0.3)
	tween.tween_property(message, "modulate:a", 1.0, 1.2)
	tween.tween_interval(2.5)
	tween.tween_property(message, "modulate:a", 0.0, 0.6)
	tween.tween_callback(_go_to_game)

func _go_to_game() -> void:
	get_tree().change_scene_to_file("res://scenes/world/earth_highway.tscn")
