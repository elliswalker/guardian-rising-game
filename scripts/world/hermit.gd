extends Node2D

# Hermit-equivalent (EP-13): a one-of-a-kind specialist found deep in the
# field. Carry them on the Sparrow (they ride along) and settle them at a
# BUILT tower to convert it into a unique structure. Kingdom hermits,
# Destiny-flavored.
#
# kinds:
#   "gunsmith" — ADU-8: converts a tower into a long-range Ballista Tower
#   "tinker"   — SIVA Tinker: converts a tower into a Flare Tower that
#                draws a new dormant frame to the field each dawn

@export var kind: String = "gunsmith"

const CARRY_OFFSET := Vector2(-12.0, -20.0)
const INTERACT_RANGE := 24.0
const SETTLE_RANGE := 26.0

const NAMES: Dictionary = {
	"gunsmith": "ADU-8, Gunsmith",
	"tinker": "SIVA Tinker",
}
const CONVERSIONS: Dictionary = {
	"gunsmith": "Ballista Tower",
	"tinker": "Flare Tower",
}

@onready var _body: ColorRect = $Body

var _carried: bool = false
var _settled: bool = false
var _player: Node2D = null

func _ready() -> void:
	add_to_group("hermits")
	GameState.dusk_triggered.connect(func(_d: int) -> void:
		if not _carried and not _settled:
			modulate.a = 0.25)  # hides in the wreckage at night
	GameState.day_started.connect(func(_d: int) -> void:
		modulate.a = 1.0)

func _process(_delta: float) -> void:
	if _settled:
		return
	if not _player or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Node2D
		if not _player:
			return
	if _carried:
		global_position = _player.global_position + CARRY_OFFSET
		var tower: Node2D = _nearest_convertible_tower()
		if tower:
			GameState.show_action_prompt(self,
				"[ SPACE ]  Settle %s  —  %s" % [NAMES[kind], CONVERSIONS[kind]], 10)
			if GameState.is_prompt_owner(self) and Input.is_action_just_pressed("action"):
				_settle(tower)
		else:
			GameState.hide_action_prompt(self)
		return
	# waiting in the field — day only
	if modulate.a < 0.9:
		return
	var near: bool = global_position.distance_to(_player.global_position) < INTERACT_RANGE
	if near:
		GameState.show_action_prompt(self, "[ SPACE ]  Carry %s" % NAMES[kind], 10)
		if GameState.is_prompt_owner(self) and Input.is_action_just_pressed("action"):
			_carried = true
	else:
		GameState.hide_action_prompt(self)

func _nearest_convertible_tower() -> Node2D:
	for t: Node in get_tree().get_nodes_in_group("towers"):
		var tn: Node2D = t as Node2D
		if not tn or not is_instance_valid(tn):
			continue
		if not bool(tn.get("_built")):
			continue
		if String(tn.get("special")) != "":
			continue  # already converted
		if global_position.distance_to(tn.global_position) < SETTLE_RANGE:
			return tn
	return null

func _settle(tower: Node2D) -> void:
	if tower.has_method("convert_special"):
		tower.call("convert_special", kind)
	_settled = true
	_carried = false
	GameState.used_hermits.append(kind)
	GameState.hide_action_prompt(self)
	Sound.play("ding")
	# perch beside the tower's head, permanently
	global_position = tower.global_position + Vector2(8.0, -40.0)
	set_process(false)
