## ParallaxLoader — plug-and-play parallax backgrounds (Kingdom's whole look).
##
## Drop PNG layers into  res://assets/backgrounds/<planet>/  named so they
## sort far-to-near (layer_0.png = farthest/slowest ... layer_3.png = nearest).
## Non-redistributable (paid) packs go in  assets/backgrounds_licensed/<planet>/
## which is gitignored; the loader checks both folders.
##
## Each level controller calls:
##   ParallaxLoader.build($ParallaxBackground, PLANET_NAME)
## and, inside its _transition_sky:
##   ParallaxLoader.tint(get_tree(), tinted_color, duration)
## so the whole world shifts with the time of day — not just the sky.
##
## No PNGs present = no layers added; the flat-color sky look is unchanged.

class_name ParallaxLoader
extends RefCounted

const DIRS: Array[String] = [
	"res://assets/backgrounds/%s/",
	"res://assets/backgrounds_licensed/%s/",
]
const HORIZON_Y := 155.0    # layer bottoms sit here (ground line is 150)
const TARGET_HEIGHT := 380.0  # world-units of sky the nearest layer should cover
const GROUP := "parallax_art"
const FG_SCALE := 2.0       # fg strips are authored at half-res like the layers
const FG_BOTTOM_Y := 188.0  # fg strip bottoms sit below the ground line

static func build(parallax_bg: ParallaxBackground, planet: String) -> void:
	var paths: Array[String] = _find_layers(planet, "layer_")
	for i in paths.size():
		var texture: Texture2D = load(paths[i])
		if not texture:
			continue
		var t: float = float(i + 1) / float(paths.size() + 1)  # 0=celestial, 1=treeline
		var layer := ParallaxLayer.new()
		layer.motion_scale = Vector2(lerpf(0.08, 0.65, t), lerpf(0.02, 0.12, t))
		var h: float = float(texture.get_height())
		var w: float = float(texture.get_width())
		# integer scale for crisp pixels where possible (320x180-class packs → 2x)
		var s: float = maxf(1.0, roundf(TARGET_HEIGHT / h)) if h <= TARGET_HEIGHT else TARGET_HEIGHT / h
		layer.motion_mirroring = Vector2(w * s, 0.0)  # seamless horizontal repeat
		var sprite := Sprite2D.new()
		sprite.texture = texture
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.centered = false
		sprite.scale = Vector2(s, s)
		sprite.position = Vector2(0.0, HORIZON_Y - h * s)
		sprite.add_to_group(GROUP)
		layer.add_child(sprite)
		parallax_bg.add_child(layer)
	_build_foreground(parallax_bg, planet)

## Foreground ground cover (fg_*.png) rides IN FRONT of the world: its own
## ParallaxBackground at canvas layer 0 (above the default canvas, below the
## HUD at layer 1) with motion_scale > 1 so it slides past faster than play.
static func _build_foreground(parallax_bg: ParallaxBackground, planet: String) -> void:
	var paths: Array[String] = _find_layers(planet, "fg_")
	if paths.is_empty():
		return
	var parent: Node = parallax_bg.get_parent()
	if not parent:
		return
	var fg_bg := ParallaxBackground.new()
	fg_bg.name = "ForegroundParallax"
	fg_bg.layer = 0
	for i in paths.size():
		var texture: Texture2D = load(paths[i])
		if not texture:
			continue
		var layer := ParallaxLayer.new()
		layer.motion_scale = Vector2(1.3 + 0.15 * float(i), 1.0)
		var h: float = float(texture.get_height())
		var w: float = float(texture.get_width())
		layer.motion_mirroring = Vector2(w * FG_SCALE, 0.0)
		var sprite := Sprite2D.new()
		sprite.texture = texture
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.centered = false
		sprite.scale = Vector2(FG_SCALE, FG_SCALE)
		sprite.position = Vector2(0.0, FG_BOTTOM_Y - h * FG_SCALE)
		sprite.add_to_group(GROUP)
		layer.add_child(sprite)
		fg_bg.add_child(layer)
	parent.add_child.call_deferred(fg_bg)

## Kingdom's trick: the color of the hour lands on every layer, not just the
## sky. Call from the level's _transition_sky with the same target color.
static func tint(tree: SceneTree, sky_color: Color, duration: float) -> void:
	for node: Node in tree.get_nodes_in_group(GROUP):
		var ci: CanvasItem = node as CanvasItem
		if not ci or not is_instance_valid(ci):
			continue
		var target: Color = Color.WHITE.lerp(sky_color, 0.35)
		var tween: Tween = ci.create_tween()
		tween.tween_property(ci, "modulate", target, duration).set_ease(Tween.EASE_IN_OUT)

static func _find_layers(planet: String, prefix: String) -> Array[String]:
	var found: Dictionary = {}
	for dir_pattern: String in DIRS:
		var dir_path: String = dir_pattern % planet
		if not DirAccess.dir_exists_absolute(dir_path):
			continue
		for file: String in DirAccess.get_files_at(dir_path):
			# exported PCKs list foo.png.import / foo.png.remap — normalize
			var name: String = file.replace(".import", "").replace(".remap", "")
			if not name.ends_with(".png") or not name.begins_with(prefix):
				continue
			var full: String = dir_path + name
			if ResourceLoader.exists(full):
				found[full] = true
	var paths: Array[String] = []
	paths.assign(found.keys())
	paths.sort()  # filename order = far-to-near
	return paths
