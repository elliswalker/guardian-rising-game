extends Node2D

# Tree — choppable for Glimmer and a new BuildSite.
# Player marks for chopping. Builders then walk to it and chop on demand.
# When felled: spawns a BuildSite stump at this position.

const HP_MAX            := 4
const GLIMMER_PER_CHOP  := 10
const GLIMMER_FINAL     := 15
const INTERACT_RANGE    := 28.0

const BUILD_SITE_SCENE := preload("res://scenes/world/build_site.tscn")

@onready var _foliage: ColorRect = $Foliage
@onready var _trunk:   ColorRect = $Trunk

var _hp: int = HP_MAX
var _commissioned: bool = false
var _player_nearby: bool = false

func _ready() -> void:
	add_to_group("trees")

func _process(_delta: float) -> void:
	if _commissioned:
		return
	_check_player_proximity()

func _check_player_proximity() -> void:
	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if not player:
		return
	var nearby: bool = global_position.distance_to(player.global_position) < INTERACT_RANGE
	if nearby != _player_nearby:
		_player_nearby = nearby
		if nearby:
			GameState.show_action_prompt(self, "[ SPACE ]  Mark for Chopping", 10)
		else:
			GameState.hide_action_prompt(self)
	if nearby and GameState.is_prompt_owner(self) and Input.is_action_just_pressed("action"):
		commission()

func commission() -> void:
	_commissioned = true
	_player_nearby = false
	GameState.hide_action_prompt(self)
	# The tree appears slightly brighter once commissioned
	_foliage.modulate = Color(1.2, 1.2, 0.8, 1.0)

# Returns true when the tree falls. Called by builder on each swing.
func chop() -> bool:
	_hp -= 1
	GameState.add_glimmer(GLIMMER_PER_CHOP)
	_update_visual()
	if _hp <= 0:
		GameState.add_glimmer(GLIMMER_FINAL)
		_spawn_build_site()
		queue_free()
		return true
	return false

func _spawn_build_site() -> void:
	var site: Node2D = BUILD_SITE_SCENE.instantiate() as Node2D
	site.global_position = global_position
	get_parent().add_child(site)

func _update_visual() -> void:
	var t: float = float(_hp) / float(HP_MAX)
	_foliage.color = Color(0.18 + t * 0.15, 0.48 + t * 0.22, 0.12, 1.0)
	_trunk.color = Color(0.35 - (1.0 - t) * 0.12, 0.22 - (1.0 - t) * 0.05, 0.10, 1.0)
	if _commissioned:
		_foliage.modulate = Color(1.2, 1.2, 0.8, 1.0)
