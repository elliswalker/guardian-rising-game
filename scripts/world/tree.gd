extends Node2D

# Tree — choppable for Glimmer and a new BuildSite.
# Player marks for chopping. Builders then walk to it and chop on demand.
# Felled trees yield glimmer only - wall positions are authored.

const HP_MAX            := 4
const GLIMMER_PER_CHOP  := 10
const GLIMMER_FINAL     := 15
const INTERACT_RANGE    := 28.0

const TEX_STYLES: Array[Texture2D] = [
	preload("res://assets/sprites/structures/pro_tree_oak.png"),
	preload("res://assets/sprites/structures/pro_tree_oak2.png"),
	preload("res://assets/sprites/structures/pro_tree_birch.png"),
	preload("res://assets/sprites/structures/pro_tree_birch2.png"),
]
const TEX_BUSH := preload("res://assets/sprites/structures/pro_bush.png")
const TEX_TUFT := preload("res://assets/sprites/structures/pro_tuft.png")

@onready var _foliage: Sprite2D = $Foliage
@onready var _trunk:   Sprite2D = $Trunk

var _bushes: Array[Sprite2D] = []

var _hp: int = HP_MAX
var _commissioned: bool = false
var _player_nearby: bool = false

func _ready() -> void:
	add_to_group("trees")
	_apply_style()
	_spawn_ground_cover()
	_update_visual()

# Mixed copse styles (#50): each tree rolls one of four full-tree arts
func _apply_style() -> void:
	var tex: Texture2D = TEX_STYLES[randi() % TEX_STYLES.size()]
	var target_h: float = randf_range(38.0, 50.0)
	var s: float = target_h / float(tex.get_height())
	_foliage.texture = tex
	_foliage.scale = Vector2(s, s)
	_foliage.position = Vector2(0.0, 2.0 - target_h * 0.5)
	_trunk.visible = false

# K2C ground cover: brush huddles at the trunk and fades once cleared (#50)
func _spawn_ground_cover() -> void:
	for i in randi() % 3:
		var bush := Sprite2D.new()
		var tex: Texture2D = TEX_BUSH if randf() < 0.6 else TEX_TUFT
		var h: float = randf_range(5.0, 9.0)
		bush.texture = tex
		bush.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		bush.scale = Vector2(h / float(tex.get_height()), h / float(tex.get_height()))
		bush.position = position + Vector2(randf_range(-24.0, 24.0), 2.0 - h * 0.5)
		bush.z_index = -3
		_bushes.append(bush)
		get_parent().add_child.call_deferred(bush)

func _fade_ground_cover() -> void:
	for bush: Sprite2D in _bushes:
		if not is_instance_valid(bush):
			continue
		var tw: Tween = bush.create_tween()
		tw.tween_property(bush, "modulate:a", 0.0, 2.0)
		tw.tween_callback(bush.queue_free)

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
	if nearby and GameState.is_prompt_owner(self) and Input.is_action_just_pressed("action") \
			and GameState.try_consume_action():
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
		_fade_ground_cover()
		queue_free()
		return true
	return false

func _update_visual() -> void:
	# Pro foliage is baked-color art (#49) — the old green tint made it neon.
	# Tint only signals state now: darkens as HP drops, warms when marked.
	var t: float = float(_hp) / float(HP_MAX)
	var fol: Color = Color(0.72 + t * 0.28, 0.72 + t * 0.28, 0.72 + t * 0.28, 1.0)
	if _commissioned:
		fol = Color(1.0, 0.85, 0.55, 1.0)  # marked for chopping — warm flag
	_foliage.modulate = fol
