extends Area2D

@onready var _pole:    ColorRect = $Pole
@onready var _banner:  ColorRect = $Banner
@onready var _label:   Label     = $Label

var _player_nearby: bool = false
var _activated: bool = false

func _ready() -> void:
	add_to_group("attack_flags")
	collision_layer = 0
	collision_mask = 8  # player
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	GameState.portal_broken.connect(_on_portal_broken)

func _process(_delta: float) -> void:
	if _player_nearby and not _activated:
		var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
		var pdist: float = global_position.distance_to(player.global_position) if player else 999999.0
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
	_banner.color = Color(0.80, 0.10, 0.10, 1.0)
	if _label:
		_label.text = "CHARGE"

func _on_portal_broken(_faction: String) -> void:
	if _label:
		_label.text = "VICTORY"
	_banner.color = Color(0.15, 0.70, 0.25, 1.0)
