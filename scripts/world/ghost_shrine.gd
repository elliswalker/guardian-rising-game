extends Area2D

# Elemental Ghost discovery site (EP-08). Earth: Sundance — Cayde-6's Ghost,
# waiting in a firelit hollow. Unlock with Legendary Shards + Glimmer to bond:
# their super becomes your double-tap ability.

const SHARD_COST   := 3
const GLIMMER_COST := 100
const SUPER_NAME   := "golden_gun"

const COLOR_EMBER  := Color(1.0, 0.55, 0.15, 1.0)

@onready var _hollow: ColorRect = $Hollow
@onready var _ghost_body: ColorRect = $GhostBody
@onready var _glow: ColorRect = $Glow

var _player_nearby: bool = false
var _claimed: bool = false
var _pulse: float = 0.0

func _ready() -> void:
	add_to_group("ghost_shrines")
	collision_mask = 8
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_claimed = GameState.equipped_super == SUPER_NAME

func _process(delta: float) -> void:
	_pulse += delta
	if not _claimed:
		_glow.modulate.a = 0.25 + sin(_pulse * 2.0) * 0.15
	if not _player_nearby or _claimed:
		return
	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	var pdist: float = global_position.distance_to(player.global_position) if player else 999999.0
	if GameState.legendary_shards >= SHARD_COST:
		GameState.show_action_prompt(self,
			"[ SPACE ]  Bond with Sundance  —  %d ✦ + %d ◈   (Golden Gun)" % [SHARD_COST, GLIMMER_COST], 11, pdist)
		if GameState.is_prompt_owner(self) and Input.is_action_just_pressed("action"):
			_claim()
	else:
		GameState.show_action_prompt(self,
			"A Ghost stirs in the firelight...  (%d/%d ✦)" % [GameState.legendary_shards, SHARD_COST], 11, pdist)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_nearby = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_nearby = false
		GameState.hide_action_prompt(self)

func _claim() -> void:
	if not GameState.spend_shards(SHARD_COST):
		return
	if not GameState.spend_glimmer(GLIMMER_COST):
		GameState.add_shard(SHARD_COST)  # refund on failed glimmer spend
		return
	_claimed = true
	GameState.equipped_super = SUPER_NAME
	GameState.super_equipped.emit(SUPER_NAME)
	GameState.hide_action_prompt(self)
	# Sundance rises and joins you
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(_ghost_body, "position:y", _ghost_body.position.y - 30.0, 1.2)
	tween.tween_property(_ghost_body, "modulate:a", 0.0, 1.4)
	tween.tween_property(_glow, "modulate:a", 0.0, 1.4)
	tween.chain().tween_callback(func() -> void:
		_ghost_body.visible = false
	)
