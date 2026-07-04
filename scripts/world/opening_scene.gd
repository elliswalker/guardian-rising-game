extends CanvasLayer

@onready var scan_line: ColorRect = $ScanLine
@onready var message: Label = $Message

func _ready() -> void:
	scan_line.visible = false
	message.modulate.a = 0.0
	_play_opening()

# Aliens motion-tracker, done right: ONE smooth sweep bottom-to-top, pings
# quickening as the scan resolves, static crackling DURING the sweep — the
# line never teleports. Lock-on, then the words.
func _play_opening() -> void:
	var tween: Tween = create_tween()
	tween.tween_interval(0.7)
	tween.tween_callback(func() -> void:
		scan_line.visible = true
		_schedule_pings()
		_schedule_static())
	tween.tween_property(scan_line, "position:y", 36.0, 2.8).from(700.0) \
		.set_ease(Tween.EASE_IN_OUT)
	# lock-on: the line brightens once, then dissolves
	tween.tween_property(scan_line, "modulate:a", 1.0, 0.08)
	tween.tween_callback(func() -> void: Sound.play("ding", -6.0, 0.8))
	tween.tween_property(scan_line, "modulate:a", 0.0, 0.5)
	tween.tween_interval(0.3)
	tween.tween_callback(func() -> void: Sound.play("dawn", -8.0, 0.9))
	tween.tween_property(message, "modulate:a", 1.0, 1.2)
	tween.tween_interval(2.5)
	tween.tween_property(message, "modulate:a", 0.0, 0.6)
	tween.tween_callback(_go_to_game)

# tracker pings on a quickening cadence as the signal resolves
func _schedule_pings() -> void:
	for delay: float in [0.0, 0.65, 1.2, 1.65, 2.0, 2.3, 2.5, 2.65]:
		var t: Tween = create_tween()
		t.tween_interval(maxf(delay, 0.01))
		t.tween_callback(func() -> void:
			Sound.play("clink", -12.0, 0.5 + delay * 0.12))

# soft static rows that crackle during the sweep — interference, not glitches
func _schedule_static() -> void:
	for delay: float in [0.5, 0.9, 1.4, 1.9]:
		var t: Tween = create_tween()
		t.tween_interval(delay)
		t.tween_callback(func() -> void:
			for i in 2:
				var bar: ColorRect = ColorRect.new()
				bar.size = Vector2(randf_range(160.0, 480.0), randf_range(1.0, 2.0))
				bar.position = Vector2(randf_range(0.0, 800.0), randf_range(100.0, 620.0))
				bar.color = Color(0.35, 0.75, 1.0, randf_range(0.08, 0.22))
				add_child(bar)
				var bt: Tween = bar.create_tween()
				bt.tween_property(bar, "modulate:a", 0.0, 0.18)
				bt.tween_callback(bar.queue_free))

func _go_to_game() -> void:
	# Resume a saved run where it left off; otherwise begin at the Last City
	if GameState.has_save() and GameState.load_game():
		return
	get_tree().change_scene_to_file("res://scenes/world/earth_highway.tscn")
