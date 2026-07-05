extends Area2D

# Elemental Ghost discovery site (EP-08). Bond once with Shards + Glimmer;
# after that, any shrine you've bonded becomes a free attunement station —
# only one Ghost rides with you at a time (design rule).
#
# Earth: Sundance (Solar) — Cayde-6's Golden Gun
# Moon:  Targe (Arc)     — Zavala's Striker Smash

@export var super_name: String = "golden_gun"
@export var ghost_name: String = "Sundance"
@export var super_label: String = "Golden Gun"
@export var shard_cost: int = 3
@export var glimmer_cost: int = 100
@export var ember_color: Color = Color(1.0, 0.55, 0.15)

@onready var _hollow: ColorRect = $Hollow
@onready var _ghost_body: ColorRect = $GhostBody
@onready var _glow: ColorRect = $Glow

var _player_nearby: bool = false
var _pulse: float = 0.0

func _ready() -> void:
	add_to_group("ghost_shrines")
	collision_mask = 8
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_glow.color = Color(ember_color.r, ember_color.g, ember_color.b, 0.3)
	_ghost_body.color = ember_color.lightened(0.3)
	if _bonded():
		_ghost_body.visible = false
		_glow.modulate.a = 0.0

func _bonded() -> bool:
	return GameState.unlocked_supers.has(super_name)

func _process(delta: float) -> void:
	_pulse += delta
	if not _bonded():
		_glow.modulate.a = 0.25 + sin(_pulse * 2.0) * 0.15
	if not _player_nearby:
		return
	if _bonded() and GameState.equipped_super == super_name:
		return  # already riding with you
	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	var pdist: float = global_position.distance_to(player.global_position) if player else 999999.0
	if _bonded():
		# free switch — one Ghost at a time
		GameState.show_action_prompt(self,
			"[ SPACE ]  Attune %s   (%s)" % [ghost_name, super_label], 11, pdist)
		if GameState.is_prompt_owner(self) and Input.is_action_just_pressed("action") and GameState.try_consume_action():
			GameState.equipped_super = super_name
			GameState.super_equipped.emit(super_name)
			GameState.hide_action_prompt(self)
			Sound.play("ding", 0.0, 1.2)
	elif GameState.legendary_shards >= shard_cost:
		GameState.show_action_prompt(self,
			"[ SPACE ]  Bond with %s  —  %d ✦ + %d ◈   (%s)" %
			[ghost_name, shard_cost, glimmer_cost, super_label], 11, pdist)
		if GameState.is_prompt_owner(self) and Input.is_action_just_pressed("action") and GameState.try_consume_action():
			_claim()
	else:
		GameState.show_action_prompt(self,
			"A Ghost stirs here...  (%d/%d ✦)" % [GameState.legendary_shards, shard_cost], 11, pdist)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_nearby = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_nearby = false
		GameState.hide_action_prompt(self)

func _claim() -> void:
	if not GameState.spend_shards(shard_cost):
		return
	if not GameState.spend_glimmer(glimmer_cost):
		GameState.add_shard(shard_cost)  # refund on failed glimmer spend
		return
	GameState.unlocked_supers.append(super_name)
	GameState.equipped_super = super_name
	GameState.super_equipped.emit(super_name)
	GameState.hide_action_prompt(self)
	Sound.play("ding", 0.0, 1.2)
	# the Ghost rises and joins you
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(_ghost_body, "position:y", _ghost_body.position.y - 30.0, 1.2)
	tween.tween_property(_ghost_body, "modulate:a", 0.0, 1.4)
	tween.tween_property(_glow, "modulate:a", 0.0, 1.4)
	tween.chain().tween_callback(func() -> void:
		_ghost_body.visible = false
	)
