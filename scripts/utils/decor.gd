class_name Decor
extends RefCounted

# Ground-cover scatter (#50): rocks, bushes and tufts strewn between the
# camp and the world edges so the walk to the portal reads as terrain,
# not a treadmill. Pure dressing — no collision, tucked behind gameplay.

const GROUND_Y := 150.0


static func scatter(parent: Node2D, paths: Array[String], count: int,
		rng: RandomNumberGenerator, x_min: float, x_max: float,
		h_min: float, h_max: float, mirror: bool) -> void:
	for i in count:
		var tex: Texture2D = load(paths[rng.randi_range(0, paths.size() - 1)])
		if not tex:
			continue
		var spr := Sprite2D.new()
		spr.texture = tex
		spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var target_h: float = rng.randf_range(h_min, h_max)
		var sc: float = target_h / float(tex.get_height())
		spr.scale = Vector2(sc, sc)
		spr.flip_h = rng.randf() < 0.5
		var x: float = rng.randf_range(x_min, x_max)
		if mirror and rng.randf() < 0.5:
			x = -x
		spr.position = Vector2(x, GROUND_Y - target_h * 0.5 + 0.5)
		spr.z_index = -4
		parent.add_child(spr)
