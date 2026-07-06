class_name OptionsPanel
extends VBoxContainer

# Shared options rows (#48) — Kingdom rules: sparse centered text, no
# boxes. Up/Down selects, Left/Right adjusts, Esc/back returns.
# Used by both the main menu and the pause menu.

signal closed

const COLOR_DIM := Color(0.55, 0.58, 0.64, 1.0)
const COLOR_LIT := Color(0.95, 0.96, 1.00, 1.0)

var _rows: Array[Label] = []
var _index: int = 0

func _ready() -> void:
	alignment = BoxContainer.ALIGNMENT_CENTER
	add_theme_constant_override("separation", 8)
	for i in 6:
		var row := Label.new()
		row.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row.add_theme_font_size_override("font_size", 13)
		add_child(row)
		_rows.append(row)
	_refresh()

func _refresh() -> void:
	var vals: Array[String] = [
		"MASTER  %s" % _meter(Settings.master_volume),
		"MUSIC   %s" % _meter(Settings.music_volume),
		"SFX     %s" % _meter(Settings.sfx_volume),
		"FULLSCREEN  %s" % ("ON" if Settings.fullscreen else "OFF"),
		"VSYNC  %s" % ("ON" if Settings.vsync else "OFF"),
		"BACK",
	]
	for i in _rows.size():
		_rows[i].text = ("· %s ·" % vals[i]) if i == _index else vals[i]
		_rows[i].add_theme_color_override("font_color", COLOR_LIT if i == _index else COLOR_DIM)

func _meter(steps: int) -> String:
	return "|".repeat(steps) + "·".repeat(10 - steps)

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_down"):
		_index = (_index + 1) % _rows.size()
		_refresh()
	elif event.is_action_pressed("ui_up"):
		_index = (_index - 1 + _rows.size()) % _rows.size()
		_refresh()
	elif event.is_action_pressed("ui_left"):
		_adjust(-1)
	elif event.is_action_pressed("ui_right"):
		_adjust(1)
	elif event.is_action_pressed("ui_accept") and _index == 5:
		_close()
	elif event.is_action_pressed("ui_cancel"):
		_close()
	else:
		return
	get_viewport().set_input_as_handled()

func _adjust(dir: int) -> void:
	match _index:
		0: Settings.master_volume = clampi(Settings.master_volume + dir, 0, 10)
		1: Settings.music_volume = clampi(Settings.music_volume + dir, 0, 10)
		2: Settings.sfx_volume = clampi(Settings.sfx_volume + dir, 0, 10)
		3: Settings.fullscreen = not Settings.fullscreen
		4: Settings.vsync = not Settings.vsync
		_: return
	Settings.apply()
	Sound.play("clink", -6.0, 1.2)
	_refresh()

func _close() -> void:
	Settings.save()
	closed.emit()
