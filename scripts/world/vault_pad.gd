extends Area2D

# Vault pad — one half of the encampment vault (EP-10, banker analog).
# Two pads stand side by side: DEPOSIT and WITHDRAW. Vaulted glimmer is safe
# from combat scatter but isn't armoring you — that trade-off is the feature.
# Withdrawals are daytime-only, Kingdom banker style.

enum Mode { DEPOSIT, WITHDRAW }

@export var mode: Mode = Mode.DEPOSIT

const CHUNK := 50

const COLOR_DEPOSIT  := Color(0.95, 0.80, 0.25, 1.0)
const COLOR_WITHDRAW := Color(0.35, 0.75, 0.55, 1.0)

@onready var _marker: Sprite2D = $Marker
@onready var _label: Label = $Label

var _player_inside: bool = false
var _is_day: bool = true

func _ready() -> void:
	add_to_group("vault_pads")
	collision_mask = 8  # player layer
	_marker.self_modulate = COLOR_DEPOSIT if mode == Mode.DEPOSIT else COLOR_WITHDRAW
	_label.text = "VAULT IN" if mode == Mode.DEPOSIT else "VAULT OUT"
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	GameState.day_started.connect(func(_d: int) -> void: _is_day = true)
	GameState.dusk_triggered.connect(func(_d: int) -> void: _is_day = false)

func _process(_delta: float) -> void:
	if not _player_inside:
		return
	_show_prompt()  # re-assert each frame to recover from preemption
	if GameState.is_prompt_owner(self) and Input.is_action_just_pressed("action"):
		_do_action()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_inside = true
		_show_prompt()

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_inside = false
		GameState.hide_action_prompt(self)

func _show_prompt() -> void:
	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	var pdist: float = global_position.distance_to(player.global_position) if player else 999999.0
	if GameState.camp_tier() < 4:
		GameState.show_action_prompt(self, "Vault — Requires Encampment T4", 6, pdist)
		return
	var stored: int = GameState.vaulted_glimmer
	if mode == Mode.DEPOSIT:
		var amount: int = mini(CHUNK, GameState.glimmer)
		if amount > 0:
			GameState.show_action_prompt(self,
				"[ SPACE ]  Vault %d ◈   (stored: %d)" % [amount, stored], 6, pdist)
		else:
			GameState.show_action_prompt(self, "Nothing to vault   (stored: %d)" % stored, 6, pdist)
		return
	if not _is_day:
		GameState.show_action_prompt(self, "Vault sealed until dawn   (stored: %d)" % stored, 6, pdist)
		return
	var out: int = mini(CHUNK, stored)
	if out > 0:
		GameState.show_action_prompt(self,
			"[ SPACE ]  Withdraw %d ◈   (stored: %d)" % [out, stored], 6, pdist)
	else:
		GameState.show_action_prompt(self, "Vault empty", 6, pdist)

func _do_action() -> void:
	if GameState.camp_tier() < 4:
		return
	if mode == Mode.DEPOSIT:
		var amount: int = mini(CHUNK, GameState.glimmer)
		if amount > 0:
			GameState.glimmer -= amount
			GameState.vault_deposit(amount)
	else:
		if not _is_day:
			return
		var out: int = mini(CHUNK, GameState.vaulted_glimmer)
		if out > 0:
			GameState.vault_withdraw(out)
			GameState.add_glimmer(out)
	_show_prompt()
