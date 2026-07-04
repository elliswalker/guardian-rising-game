extends CanvasLayer

@onready var glimmer_label: Label     = $GlimmerLabel
@onready var wave_label: Label        = $WaveLabel
@onready var dusk_label: Label        = $DuskLabel
@onready var day_label: Label         = $DayLabel
@onready var action_prompt: Label     = $ActionPrompt
@onready var ghost_icon               = $GhostIcon
@onready var wave_alert               = $WaveAlert

var _wave_tween: Tween
var _day_tween: Tween
var _dusk_active: bool = true

func _ready() -> void:
	_apply_design_tokens()

	GameState.glimmer_changed.connect(_on_glimmer_changed)
	GameState.vault_changed.connect(func(_v: int) -> void: _on_glimmer_changed(GameState.glimmer))
	GameState.shards_changed.connect(func(_s: int) -> void: _on_glimmer_changed(GameState.glimmer))
	GameState.ghost_captured.connect(_on_ghost_captured)
	GameState.ghost_released.connect(_on_ghost_released)
	GameState.wave_changed.connect(_on_wave_changed)
	GameState.action_prompt_show.connect(_on_action_prompt_show)
	GameState.action_prompt_hide.connect(_on_action_prompt_hide)
	GameState.dusk_timer_updated.connect(_on_dusk_timer_updated)
	GameState.dawn_triggered.connect(_on_dawn_triggered)
	GameState.day_started.connect(_on_day_started)

	_on_glimmer_changed(GameState.glimmer)
	call_deferred("_connect_ghost_ability")
	wave_label.modulate.a = 0.0
	action_prompt.modulate.a = 0.0

func _connect_ghost_ability() -> void:
	var ghost_node: Node = get_tree().get_first_node_in_group("ghost")
	if ghost_node and ghost_node.has_signal("ability_cooldown_updated"):
		ghost_node.ability_cooldown_updated.connect(
			func(f: float) -> void: ghost_icon.set_ability_fraction(f)
		)

func _apply_design_tokens() -> void:
	DesignTokens.apply_font(glimmer_label, DesignTokens.FONT_LG)
	DesignTokens.apply_font(wave_label, DesignTokens.FONT_MD)
	DesignTokens.apply_font(day_label, DesignTokens.FONT_SM)
	DesignTokens.apply_font(action_prompt, DesignTokens.FONT_MD)

	glimmer_label.add_theme_color_override("font_color", DesignTokens.GLIMMER_GOLD)
	action_prompt.add_theme_color_override("font_color", DesignTokens.ARC)

func _on_glimmer_changed(value: int) -> void:
	var text: String = "◈  %d" % value
	if GameState.vaulted_glimmer > 0:
		text += "   ⛨ %d" % GameState.vaulted_glimmer
	if GameState.legendary_shards > 0:
		text += "   ✦ %d" % GameState.legendary_shards
	glimmer_label.text = text

func _on_ghost_captured() -> void:
	ghost_icon.is_captured = true

func _on_ghost_released() -> void:
	ghost_icon.is_captured = false

func _on_wave_changed(wave: int) -> void:
	_dusk_active = false
	var fade: Tween = create_tween()
	fade.tween_property(dusk_label, "modulate:a", 0.0, 0.4)

	wave_alert.show_wave(wave, _faction_for_wave(wave))

	wave_label.text = "WAVE %d" % wave
	if _wave_tween:
		_wave_tween.kill()
	_wave_tween = create_tween()
	_wave_tween.tween_property(wave_label, "modulate:a", 1.0, 0.4)
	_wave_tween.tween_interval(2.5)
	_wave_tween.tween_property(wave_label, "modulate:a", 0.0, 0.8)

func _faction_for_wave(_wave: int) -> String:
	# Faction is locked to the PLANET, never the wave
	match GameState.current_planet:
		"moon":
			return "hive"
		"mars":
			return "cabal"
	return "fallen"

func _on_dusk_timer_updated(seconds: int) -> void:
	if not _dusk_active:
		return
	var urgency: float = clampf(1.0 - float(seconds) / 30.0, 0.0, 1.0)
	ghost_icon.set_dusk_urgency(urgency)

func _on_dawn_triggered(_day_number: int) -> void:
	if _wave_tween:
		_wave_tween.kill()
	wave_label.text = "DAWN"
	wave_label.modulate = Color(0.85, 0.75, 0.45, 0.0)
	_wave_tween = create_tween()
	_wave_tween.tween_property(wave_label, "modulate:a", 1.0, 0.6)
	_wave_tween.tween_interval(2.0)
	_wave_tween.tween_property(wave_label, "modulate:a", 0.0, 1.5)
	ghost_icon.set_dusk_urgency(0.0)

func _on_day_started(day_number: int) -> void:
	_dusk_active = true
	day_label.text = "Day %s" % _to_roman(day_number)
	if _day_tween:
		_day_tween.kill()
	day_label.modulate.a = 0.0
	_day_tween = create_tween()
	_day_tween.tween_property(day_label, "modulate:a", 1.0, 0.8)
	_day_tween.tween_interval(2.5)
	_day_tween.tween_property(day_label, "modulate:a", 0.0, 1.2)

func _to_roman(n: int) -> String:
	const VALS := [1000, 900, 500, 400, 100, 90, 50, 40, 10, 9, 5, 4, 1]
	const SYMS := ["M","CM","D","CD","C","XC","L","XL","X","IX","V","IV","I"]
	var result := ""
	var num := n
	for i in VALS.size():
		while num >= VALS[i]:
			result += SYMS[i]
			num -= VALS[i]
	return result

func _on_action_prompt_show(text: String) -> void:
	action_prompt.text = text
	var tween: Tween = create_tween()
	tween.tween_property(action_prompt, "modulate:a", 1.0, 0.25)

func _on_action_prompt_hide() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(action_prompt, "modulate:a", 0.0, 0.2)
