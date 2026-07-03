extends Node2D

# Tree — choppable for Glimmer and a new BuildSite.
# Player marks for chopping. Builders then walk to it and chop on demand.
# Felled trees yield glimmer only - wall positions are authored.

const HP_MAX            := 4
const GLIMMER_PER_CHOP  := 10
const GLIMMER_FINAL     := 15
const INTERACT_RANGE    := 28.0

@onready var _foliage: Sprite2D = $Foliage
@onready var _trunk:   Sprite2D = $Trunk

var _hp: int = HP_MAX
var _commissioned: bool = false
var _player_nearby: bool = false

func _ready() -> void:
	add_to_group("trees")
	_update_visual()

func _process(_delta: float) -> void:
	if _commissioned:
		return
	_check_player_proximity()

func _check_player_proximity() -> void:
	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if not player:
		return
	var dist: float = global_position.distance_to(player.global_position)
	var nearby: bool = dist < INTERACT_RANGE
	if nearby:
		GameState.show_action_prompt(self, "[ SPACE ]  Mark for Chopping", 10, dist)
	elif _player_nearby:
		GameState.hide_action_prompt(self)
	_player_nearby = nearby
	if nearby and GameState.is_prompt_owner(self) and Input.is_action_just_pressed("action"):
		commission()

func commission() -> void:
	_commissioned = true
	_player_nearby = false
	GameState.hide_action_prompt(self)
	_update_visual()  # commissioned trees render brighter

# Returns true when the tree falls. Called by builder on each swing.
func chop() -> bool:
	_hp -= 1
	GameState.add_glimmer(GLIMMER_PER_CHOP)
	_update_visual()
	if _hp <= 0:
		# Wall positions are authored — a felled tree yields glimmer, not a build slot
		GameState.add_glimmer(GLIMMER_FINAL)
		queue_free()
		return true
	return false

func _update_visual() -> void:
	var t: float = float(_hp) / float(HP_MAX)
	var fol: Color = Color(0.18 + t * 0.15, 0.48 + t * 0.22, 0.12, 1.0)
	if _commissioned:
		# marked for chopping — brighter, yellow-shifted
		fol = Color(minf(fol.r * 1.8, 1.0), minf(fol.g * 1.5, 1.0), fol.b * 0.8, 1.0)
	_foliage.modulate = fol
	_trunk.modulate = Color(0.35 - (1.0 - t) * 0.12, 0.22 - (1.0 - t) * 0.05, 0.10, 1.0)
