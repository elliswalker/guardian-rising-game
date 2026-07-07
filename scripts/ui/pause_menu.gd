extends CanvasLayer

# Pause menu autoload (#48) — Esc in any gameplay scene. Kingdom rules:
# dim the world, sparse centered text, nothing else. Options shares the
# same panel as the main menu.

const COLOR_DIM := Color(0.55, 0.58, 0.64, 1.0)
const COLOR_LIT := Color(0.95, 0.96, 1.00, 1.0)
const ENTRIES: Array[String] = ["RESUME", "OPTIONS", "SAVE & QUIT TO MENU", "QUIT TO DESKTOP"]

var _shade: ColorRect
var _box: VBoxContainer
var _status: Label
var _rows: Array[Label] = []
var _options: OptionsPanel
var _index: int = 0
var _mode: String = "menu"

func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_shade = ColorRect.new()
	_shade.size = Vector2(1280, 720)
	_shade.color = Color(0.02, 0.03, 0.05, 0.72)
	add_child(_shade)
	_box = VBoxContainer.new()
	_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_box.add_theme_constant_override("separation", 14)
	_box.position = Vector2(390, 250)
	_box.size = Vector2(500, 220)
	add_child(_box)
	var title := Label.new()
	title.text = "\u2014  P A U S E D  \u2014"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", COLOR_LIT)
	_box.add_child(title)
	_status = Label.new()
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.add_theme_font_size_override("font_size", 12)
	_status.add_theme_color_override("font_color", Color(0.78, 0.66, 0.35, 1.0))
	_box.add_child(_status)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 10)
	_box.add_child(gap)
	for text: String in ENTRIES:
		var row := Label.new()
		row.text = text
		row.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row.add_theme_font_size_override("font_size", 15)
		_box.add_child(row)
		_rows.append(row)
	_options = OptionsPanel.new()
	_options.position = Vector2(440, 250)
	_options.size = Vector2(400, 240)
	_options.visible = false
	_options.closed.connect(func() -> void:
		_mode = "menu"
		_refresh())
	add_child(_options)

func _in_gameplay() -> bool:
	return get_tree().get_first_node_in_group("world") != null

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		if visible and _mode == "menu":
			_menu_input(event)
		return
	if not _in_gameplay():
		return
	if visible and _mode == "options":
		return  # panel consumes its own Esc
	get_viewport().set_input_as_handled()
	if visible:
		_resume()
	else:
		_pause()

func _menu_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_down"):
		_index = (_index + 1) % _rows.size()
		_refresh()
	elif event.is_action_pressed("ui_up"):
		_index = (_index - 1 + _rows.size()) % _rows.size()
		_refresh()
	elif event.is_action_pressed("ui_accept") or event.is_action_pressed("action"):
		_choose()
	else:
		return
	get_viewport().set_input_as_handled()

func _pause() -> void:
	visible = true
	_index = 0
	_mode = "menu"
	get_tree().paused = true
	_status.text = "DAY %d      \u25c8 %d" % [GameState.day_number, GameState.glimmer]
	_refresh()

func _resume() -> void:
	visible = false
	get_tree().paused = false

func _refresh() -> void:
	_box.visible = _mode == "menu"
	_options.visible = _mode == "options"
	for i in _rows.size():
		_rows[i].text = ("◈  %s  ◈" % ENTRIES[i]) if i == _index else ENTRIES[i]
		_rows[i].add_theme_color_override("font_color", COLOR_LIT if i == _index else COLOR_DIM)

func _choose() -> void:
	match _index:
		0:
			_resume()
		1:
			_mode = "options"
			_refresh()
		2:
			GameState.save_game()
			_resume()
			Sound.stop_music(1.0)
			get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
		3:
			GameState.save_game()
			get_tree().quit()
