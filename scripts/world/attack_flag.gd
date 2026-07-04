extends Area2D

@onready var _pole:    ColorRect = $Pole
@onready var _banner:  Sprite2D = $Banner
@onready var _label:   Label     = $Label

var _player_nearby: bool = false
var _activated: bool = false
var _orig_banner: Color
var _orig_label: String

func _ready() -> void:
	add_to_group("attack_flags")
	collision_layer = 0
	collision_mask = 8  # player
	_orig_banner = _banner.modulate
	_orig_label = _label.text if _label else ""
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	GameState.portal_broken.connect(_on_portal_broken)
	GameState.day_started.connect(_on_day_started)

# The charge is a one-day order — the flag resets at dawn until the planet falls
func _on_day_started(_day: int) -> void:
	if not GameState.portal_active:
		return
	_activated = false
	GameState.is_attack_phase = false
	_banner.modulate = _orig_banner
	if _label:
		_label.text = _orig_label

func _process(_delta: float) -> void:
	# no charge to send once the planet is quiet
	if _player_nearby and not _activated and GameState.portal_active:
		var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
		var pdist: float = global_position.distance_to(player.global_position) if player else 999999.0
		if GameState.camp_tier() < 4:
			# an army needs a FULL war camp behind it (#32)
			GameState.show_action_prompt(self, "The Charge — Requires Encampment T4", 8, pdist)
			return
		GameState.show_action_prompt(self, "[ SPACE ]  Send the Charge", 8, pdist)
		if GameState.is_prompt_owner(self) and Input.is_action_just_pressed("action"):
			_activate()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_player_nearby = true

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		_player_nearby = false
		GameState.hide_action_prompt(self)

func _activate() -> void:
	_activated = true
	GameState.hide_action_prompt(self)
	GameState.is_attack_phase = true
	GameState.attack_ordered.emit()
	_banner.modulate = Color(0.80, 0.10, 0.10, 1.0)
	if _label:
		_label.text = "CHARGE"

func _on_portal_broken(_faction: String) -> void:
	# Only celebrate when the whole planet is quiet (dual-portal planets)
	if GameState.portal_active:
		return
	if _label:
		_label.text = "VICTORY"
	_banner.modulate = Color(0.15, 0.70, 0.25, 1.0)
