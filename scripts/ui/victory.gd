extends CanvasLayer

@onready var background: ColorRect     = $Background
@onready var ghost_icon                = $GhostIcon
@onready var title_msg: Label          = $TitleMessage
@onready var subtitle_msg: Label       = $SubtitleMessage
@onready var time_value: Label         = $StatsRow/TimeSurvived/TimeValue
@onready var wave_value: Label         = $StatsRow/WavesHeld/WaveValue
@onready var glimmer_value: Label      = $StatsRow/GlimmerBanked/GlimmerValue
@onready var time_title: Label         = $StatsRow/TimeSurvived/TimeTitle
@onready var wave_title: Label         = $StatsRow/WavesHeld/WaveTitle
@onready var glimmer_title: Label      = $StatsRow/GlimmerBanked/GlimmerTitle
@onready var prompt: Label             = $Prompt

var _can_restart: bool = false

func _ready() -> void:
	background.color = Color(0.0, 0.0, 0.0, 0.0)
	title_msg.modulate.a = 0.0
	subtitle_msg.modulate.a = 0.0
	prompt.modulate.a = 0.0
	ghost_icon.is_captured = false
	ghost_icon.modulate.a = 0.0
	$StatsRow/TimeSurvived.modulate.a = 0.0
	$StatsRow/WavesHeld.modulate.a = 0.0
	$StatsRow/GlimmerBanked.modulate.a = 0.0

	_populate_stats()
	_apply_fonts()
	_play_sequence()

func _populate_stats() -> void:
	var total := int(GameState.run_time_seconds)
	time_value.text = "%d:%02d" % [total / 60, total % 60]
	wave_value.text = "%d" % GameState.wave_number
	glimmer_value.text = "%d" % GameState.glimmer

func _apply_fonts() -> void:
	DesignTokens.apply_font(title_msg, DesignTokens.FONT_XL)
	DesignTokens.apply_font(subtitle_msg, DesignTokens.FONT_MD)
	DesignTokens.apply_font(prompt, DesignTokens.FONT_MD)
	for lbl: Label in [time_value, wave_value, glimmer_value]:
		DesignTokens.apply_font(lbl, DesignTokens.FONT_XL)
	for lbl: Label in [time_title, wave_title, glimmer_title]:
		DesignTokens.apply_font(lbl, DesignTokens.FONT_SM)
		lbl.add_theme_color_override("font_color", DesignTokens.TEXT_SECONDARY)

	title_msg.add_theme_color_override("font_color", DesignTokens.GLIMMER_GOLD)
	subtitle_msg.add_theme_color_override("font_color", DesignTokens.ARC)
	prompt.add_theme_color_override("font_color", DesignTokens.GLIMMER_DIM)
	for lbl: Label in [time_value, wave_value, glimmer_value]:
		lbl.add_theme_color_override("font_color", DesignTokens.TEXT_PRIMARY)

func _play_sequence() -> void:
	var tween := create_tween()
	tween.tween_property(background, "color", Color(0.039, 0.039, 0.059, 1.0), 0.8)
	tween.tween_property(ghost_icon, "modulate:a", 1.0, 0.6)
	tween.tween_interval(0.3)
	tween.tween_property(title_msg, "modulate:a", 1.0, 1.0)
	tween.tween_interval(0.2)
	tween.tween_property(subtitle_msg, "modulate:a", 1.0, 0.6)
	tween.tween_interval(0.4)
	tween.tween_property($StatsRow/TimeSurvived as CanvasItem, "modulate:a", 1.0, 0.3)
	tween.tween_property($StatsRow/WavesHeld as CanvasItem, "modulate:a", 1.0, 0.3)
	tween.tween_property($StatsRow/GlimmerBanked as CanvasItem, "modulate:a", 1.0, 0.3)
	tween.tween_interval(0.5)
	tween.tween_property(prompt, "modulate:a", 1.0, 0.8)
	tween.tween_callback(func(): _can_restart = true)

func _input(event: InputEvent) -> void:
	if not _can_restart:
		return
	if event.is_action_pressed("action"):
		_can_restart = false
		_play_outro()

func _play_outro() -> void:
	var tween := create_tween()
	tween.tween_property(title_msg, "modulate:a", 0.0, 0.4)
	tween.parallel().tween_property(subtitle_msg, "modulate:a", 0.0, 0.3)
	tween.parallel().tween_property(prompt, "modulate:a", 0.0, 0.3)
	tween.parallel().tween_property(ghost_icon, "modulate:a", 0.0, 0.4)
	tween.parallel().tween_property($StatsRow as CanvasItem, "modulate:a", 0.0, 0.3)
	tween.tween_property(background, "color", Color(0.0, 0.0, 0.0, 1.0), 0.5)
	tween.tween_interval(0.3)
	tween.tween_callback(func():
		GameState.new_run()
		get_tree().change_scene_to_file("res://scenes/world/earth_highway.tscn")
	)
