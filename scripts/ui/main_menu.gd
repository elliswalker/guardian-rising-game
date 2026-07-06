extends Node2D

# Main menu (#48) — Kingdom rules: the world IS the menu. The Earth
# plates drift slowly behind sparse centered text; the Ghost hovers over
# the title. No boxes, no chrome. Version stamp bottom-right (0.0.x).

const GHOST_TEX := preload("res://assets/sprites/player/ghost.png")
const SKY_TEX   := preload("res://assets/backgrounds/earth/layer_0.png")
const MID_TEX   := preload("res://assets/backgrounds/earth/layer_2.png")

const COLOR_DIM := Color(0.55, 0.58, 0.64, 1.0)
const COLOR_LIT := Color(0.95, 0.96, 1.00, 1.0)
const DRIFT_SPEED := 4.0  # px/s — the slow K2C title pan

var _entries: Array[Label] = []
var _index: int = 0
var _mode: String = "menu"   # menu | palette | options
var _mid_sprite: Sprite2D
var _ghost: Sprite2D
var _time: float = 0.0
var _palette_index: int = 0
var _palette_label: Label
var _preview: Sprite2D
var _options: OptionsPanel
var _menu_box: VBoxContainer

func _ready() -> void:
	_build_backdrop()
	_build_title()
	_build_menu()
	_build_palette_picker()
	_build_options()
	_build_version()
	Sound.play_music("day")
	_refresh()

func _build_backdrop() -> void:
	var sky := Sprite2D.new()
	sky.texture = SKY_TEX
	sky.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sky.centered = false
	sky.position = Vector2(0, -180)
	sky.modulate = Color(0.62, 0.60, 0.68)  # dusk-dark: calm, not bright
	add_child(sky)
	_mid_sprite = Sprite2D.new()
	_mid_sprite.texture = MID_TEX
	_mid_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_mid_sprite.centered = false
	_mid_sprite.scale = Vector2(2.0, 2.0)
	_mid_sprite.position = Vector2(0, 720.0 - float(MID_TEX.get_height()) * 2.0)
	_mid_sprite.modulate = Color(0.45, 0.44, 0.52)
	add_child(_mid_sprite)
	var shade := ColorRect.new()
	shade.size = Vector2(1280, 720)
	shade.color = Color(0.03, 0.04, 0.07, 0.45)
	add_child(shade)

func _build_title() -> void:
	var title := Label.new()
	title.text = "G U A R D I A N   R I S I N G"
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Color(0.92, 0.94, 1.0))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(0, 150)
	title.size = Vector2(1280, 60)
	add_child(title)
	_ghost = Sprite2D.new()
	_ghost.texture = GHOST_TEX
	_ghost.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_ghost.scale = Vector2(3.0, 3.0)
	_ghost.position = Vector2(640, 110)
	add_child(_ghost)

func _build_menu() -> void:
	_menu_box = VBoxContainer.new()
	_menu_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_menu_box.add_theme_constant_override("separation", 12)
	_menu_box.position = Vector2(440, 300)
	_menu_box.size = Vector2(400, 240)
	add_child(_menu_box)
	for text: String in ["CONTINUE", "NEW RUN", "OPTIONS", "QUIT"]:
		var row := Label.new()
		row.text = text
		row.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row.add_theme_font_size_override("font_size", 16)
		_menu_box.add_child(row)
		_entries.append(row)
	if not GameState.has_save():
		_index = 1  # no save: land on NEW RUN

func _build_palette_picker() -> void:
	_palette_label = Label.new()
	_palette_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_palette_label.add_theme_font_size_override("font_size", 14)
	_palette_label.position = Vector2(440, 430)
	_palette_label.size = Vector2(400, 30)
	_palette_label.visible = false
	add_child(_palette_label)
	_preview = Sprite2D.new()
	_preview.texture = preload("res://assets/sprites/player/hunter.png")
	_preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_preview.scale = Vector2(4.0, 4.0)
	_preview.position = Vector2(640, 380)
	_preview.visible = false
	add_child(_preview)

func _build_options() -> void:
	_options = OptionsPanel.new()
	_options.position = Vector2(440, 300)
	_options.size = Vector2(400, 260)
	_options.visible = false
	_options.closed.connect(func() -> void:
		_mode = "menu"
		_refresh())
	add_child(_options)

func _build_version() -> void:
	var v := Label.new()
	v.text = "v%s" % str(ProjectSettings.get_setting("application/config/version", "0.0.0"))
	v.add_theme_font_size_override("font_size", 10)
	v.add_theme_color_override("font_color", Color(0.45, 0.48, 0.55, 0.8))
	v.position = Vector2(1200, 696)
	add_child(v)

func _process(delta: float) -> void:
	_time += delta
	# the slow pan — the world breathes behind the menu
	if _mid_sprite:
		_mid_sprite.position.x = -fmod(_time * DRIFT_SPEED, float(MID_TEX.get_width()) * 2.0 * 0.5)
	if _ghost:
		_ghost.position.y = 110.0 + sin(_time * 1.6) * 5.0

func _refresh() -> void:
	_menu_box.visible = _mode == "menu"
	_options.visible = _mode == "options"
	_palette_label.visible = _mode == "palette"
	_preview.visible = _mode == "palette"
	if _mode == "menu":
		var has_save: bool = GameState.has_save()
		for i in _entries.size():
			var lit: bool = i == _index
			var dim_extra: bool = i == 0 and not has_save
			_entries[i].text = ("· %s ·" % ["CONTINUE", "NEW RUN", "OPTIONS", "QUIT"][i]) if lit \
				else ["CONTINUE", "NEW RUN", "OPTIONS", "QUIT"][i]
			var col: Color = COLOR_LIT if lit else COLOR_DIM
			if dim_extra:
				col = Color(0.32, 0.34, 0.38, 0.7)
			_entries[i].add_theme_color_override("font_color", col)
	elif _mode == "palette":
		var pname: String = GameState.PALETTE_ORDER[_palette_index]
		_palette_label.text = "<   %s   >      [ SPACE ] begin" % pname.to_upper()
		_palette_label.add_theme_color_override("font_color", COLOR_LIT)
		_preview.modulate = GameState.PALETTES[pname]

func _unhandled_input(event: InputEvent) -> void:
	if _mode == "options":
		return  # the panel handles itself
	if _mode == "palette":
		_palette_input(event)
		return
	if event.is_action_pressed("ui_down"):
		_index = (_index + 1) % _entries.size()
		_refresh()
	elif event.is_action_pressed("ui_up"):
		_index = (_index - 1 + _entries.size()) % _entries.size()
		_refresh()
	elif event.is_action_pressed("ui_accept") or event.is_action_pressed("action"):
		_choose()

func _palette_input(event: InputEvent) -> void:
	var count: int = GameState.PALETTE_ORDER.size()
	if event.is_action_pressed("ui_left"):
		_palette_index = (_palette_index - 1 + count) % count
		Sound.play("clink", -6.0, 1.1)
		_refresh()
	elif event.is_action_pressed("ui_right"):
		_palette_index = (_palette_index + 1) % count
		Sound.play("clink", -6.0, 1.1)
		_refresh()
	elif event.is_action_pressed("ui_accept") or event.is_action_pressed("action"):
		_start_new_run()
	elif event.is_action_pressed("ui_cancel"):
		_mode = "menu"
		_refresh()

func _choose() -> void:
	match _index:
		0:  # CONTINUE — load_game() restores state AND changes scene itself
			if not GameState.has_save():
				return
			Sound.play("ding", -4.0)
			GameState.load_game()
		1:  # NEW RUN -> palette pick first
			Sound.play("clink", -4.0)
			_mode = "palette"
			_refresh()
		2:  # OPTIONS
			_mode = "options"
			_refresh()
		3:  # QUIT
			get_tree().quit()

func _start_new_run() -> void:
	GameState.clear_save()
	GameState.player_palette = GameState.PALETTE_ORDER[_palette_index]
	Sound.play("ding", -2.0)
	get_tree().change_scene_to_file("res://scenes/world/opening.tscn")
