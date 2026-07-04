extends CanvasLayer

@onready var scan_line: ColorRect = $ScanLine
@onready var message: Label = $Message

func _ready() -> void:
	scan_line.visible = false
	message.modulate.a = 0.0
	_play_opening()

# Aliens-style motion-tracker resurrection: a first hesitant sweep with
# static interference, a confident second pass, then the words.
func _play_opening() -> void:
	var tween: Tween = create_tween()
	tween.tween_interval(0.8)
	tween.tween_callback(func() -> void:
		scan_line.visible = true
		Sound.play("clink", -10.0, 0.5))
	# pass 1 — slow, struggling, interference flickers
	tween.tween_property(scan_line, "position:y", 360.0, 0.9).from(718.0).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(_interference_burst)
	tween.tween_property(scan_line, "modulate:a", 0.25, 0.15)
	tween.tween_property(scan_line, "modulate:a", 1.0, 0.15)
	tween.tween_property(scan_line, "position:y", 180.0, 0.5).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(_interference_burst)
	# pass 2 — the Light catches; fast clean sweep
	tween.tween_callback(func() -> void: Sound.play("clink", -8.0, 0.7))
	tween.tween_property(scan_line, "position:y", 718.0, 0.05)
	tween.tween_property(scan_line, "position:y", 0.0, 0.7).set_ease(Tween.EASE_OUT)
	tween.tween_property(scan_line, "modulate:a", 0.0, 0.4)
	tween.tween_interval(0.3)
	tween.tween_callback(func() -> void: Sound.play("dawn", -8.0, 0.9))
	tween.tween_property(message, "modulate:a", 1.0, 1.2)
	tween.tween_interval(2.5)
	tween.tween_property(message, "modulate:a", 0.0, 0.6)
	tween.tween_callback(_go_to_game)

# brief horizontal static bars — the tracker fighting to resolve a signal
func _interference_burst() -> void:
	for i in 3:
		var bar: ColorRect = ColorRect.new()
		bar.size = Vector2(randf_range(180.0, 520.0), randf_range(1.0, 3.0))
		bar.position = Vector2(randf_range(0.0, 760.0), randf_range(80.0, 640.0))
		bar.color = Color(0.35, 0.75, 1.0, randf_range(0.15, 0.5))
		add_child(bar)
		var t: Tween = bar.create_tween()
		t.tween_interval(randf_range(0.05, 0.2))
		t.tween_property(bar, "modulate:a", 0.0, 0.15)
		t.tween_callback(bar.queue_free)

func _go_to_game() -> void:
	# Resume a saved run where it left off; otherwise begin at the Last City
	if GameState.has_save() and GameState.load_game():
		return
	get_tree().change_scene_to_file("res://scenes/world/earth_highway.tscn")
