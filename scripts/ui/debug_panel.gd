extends CanvasLayer

@onready var toggle_ghost_btn: Button = $Panel/VBox/ToggleGhost

var _ghost_invincible: bool = false

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_toggle"):
		visible = not visible

func _on_spawn_dreg_pressed() -> void:
	var world: Node = get_tree().get_first_node_in_group("world")
	if world:
		world.call("debug_spawn_dreg")

func _on_force_dusk_pressed() -> void:
	var world: Node = get_tree().get_first_node_in_group("world")
	if world:
		world.call("debug_force_dusk")

func _on_add_glimmer_pressed() -> void:
	GameState.add_glimmer(500)

func _on_toggle_ghost_pressed() -> void:
	_ghost_invincible = not _ghost_invincible
	var ghost: Node = get_tree().get_first_node_in_group("ghost")
	if ghost:
		ghost.set("invincible", _ghost_invincible)
	toggle_ghost_btn.text = "Ghost Invincible: %s" % ("ON ✓" if _ghost_invincible else "OFF")

func _on_kill_all_pressed() -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		# take_damage(99) works on every enemy type; die() only existed on dreg
		if enemy.has_method("take_damage"):
			enemy.take_damage(99)
		elif enemy.has_method("die"):
			enemy.die()
