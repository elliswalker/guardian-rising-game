extends Control

@onready var _bg: ColorRect          = $Background
@onready var _left_accent: ColorRect = $LeftAccent
@onready var _faction_label: Label   = $FactionLabel
@onready var _subtitle_label: Label  = $SubtitleLabel
@onready var _wave_number: Label     = $WaveNumber
@onready var _pulse_bar: ColorRect   = $PulseBar

const FADE_IN  := 0.3
const HOLD     := 2.8
const FADE_OUT := 0.5

var _tween: Tween

func _ready() -> void:
	modulate.a = 0.0
	_apply_faction("fallen")
	DesignTokens.apply_font(_faction_label, DesignTokens.FONT_LG)
	DesignTokens.apply_font(_subtitle_label, DesignTokens.FONT_SM)
	DesignTokens.apply_font(_wave_number, DesignTokens.FONT_2XL)

func show_wave(wave: int, faction: String = "fallen") -> void:
	_apply_faction(faction)
	var display := DesignTokens.get_faction_display(faction)
	_faction_label.text = display["name"]
	_subtitle_label.text = display["subtitle"]
	_wave_number.text = "%02d" % wave

	if _tween:
		_tween.kill()
	modulate.a = 0.0
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 1.0, FADE_IN).set_ease(Tween.EASE_OUT)
	_tween.tween_interval(HOLD)
	_tween.tween_property(self, "modulate:a", 0.0, FADE_OUT)

func _apply_faction(faction: String) -> void:
	var colors := DesignTokens.get_faction_colors(faction)
	var light: Color = colors["light"]
	var dark: Color  = colors["dark"]
	_bg.color           = Color(dark.r, dark.g, dark.b, 0.92)
	_left_accent.color  = light
	_pulse_bar.color    = light
	_faction_label.add_theme_color_override("font_color", light)
	_subtitle_label.add_theme_color_override("font_color", Color(light.r, light.g, light.b, 0.65))
	_wave_number.add_theme_color_override("font_color", light)
