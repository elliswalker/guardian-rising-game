class_name Shoreline
extends RefCounted

# Kingdom water (#50): a deep still column, drifting surface reflections
# and a lit waterline — replaces the flat color blocks the shorelines
# used to be. Water plane meets the ground line at y=150.

const TEX_SHIMMER := preload("res://assets/backgrounds/water_tile.png")


static func build(parent: Node2D, x0: float, width: float, deep: Color, glint: Color) -> void:
	var body := ColorRect.new()
	body.color = deep
	body.position = Vector2(x0, 150.5)
	body.size = Vector2(width, 262.0)
	body.z_index = 1
	parent.add_child(body)
	var shimmer := TextureRect.new()
	shimmer.texture = TEX_SHIMMER
	shimmer.stretch_mode = TextureRect.STRETCH_TILE
	shimmer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	shimmer.position = Vector2(x0, 151.0)
	shimmer.size = Vector2(width, 48.0)
	shimmer.modulate = Color(glint.r, glint.g, glint.b, 0.8)
	shimmer.z_index = 2
	parent.add_child(shimmer)
	var tw: Tween = shimmer.create_tween().set_loops()
	tw.tween_property(shimmer, "modulate:a", 0.4, 1.9).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(shimmer, "modulate:a", 0.8, 1.9).set_ease(Tween.EASE_IN_OUT)
	var surf := ColorRect.new()
	surf.color = Color(glint.r, glint.g, glint.b, 0.95)
	surf.position = Vector2(x0, 150.0)
	surf.size = Vector2(width, 1.5)
	surf.z_index = 2
	parent.add_child(surf)
