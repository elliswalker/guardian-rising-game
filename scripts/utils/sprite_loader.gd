## SpriteLoader
## Call SpriteLoader.build(node, character_name) after placing PNG sheets in assets/sprites/
## Expects sprite sheets at res://assets/sprites/[folder]/[name]/[name]_sheet.png
## Sheet layout (rows): 0=idle, 1=walk, 2=attack, 3=hit, 4=death
## Frame count per row: idle=2, walk=4, attack=3, hit=1, death=3
## Canvas sizes: characters=32×64, small=24×48, standard=32×64, elite=40×80, heavy=56×96, floater=48×48

class_name SpriteLoader
extends RefCounted

const ANIM_IDLE   := "idle"
const ANIM_WALK   := "walk"
const ANIM_ATTACK := "attack"
const ANIM_HIT    := "hit"
const ANIM_DEATH  := "death"

const FRAME_COUNTS: Dictionary = {
	ANIM_IDLE:   2,
	ANIM_WALK:   4,
	ANIM_ATTACK: 3,
	ANIM_HIT:    1,
	ANIM_DEATH:  3,
}

const ANIM_SPEEDS: Dictionary = {
	ANIM_IDLE:   4.0,
	ANIM_WALK:   8.0,
	ANIM_ATTACK: 10.0,
	ANIM_HIT:    8.0,
	ANIM_DEATH:  6.0,
}

const SIZES: Dictionary = {
	"characters": Vector2i(32, 64),
	"player":     Vector2i(32, 64),
	"small":      Vector2i(24, 48),
	"standard":   Vector2i(32, 64),
	"elite":      Vector2i(40, 80),
	"heavy":      Vector2i(56, 96),
	"floater":    Vector2i(48, 48),
}

## Replace a ColorRect placeholder with a live AnimatedSprite2D.
## node: the ColorRect node to replace (must have a valid parent)
## sheet_path: e.g. "res://assets/sprites/characters/speaker/speaker_sheet.png"
## frame_size: e.g. Vector2i(32, 64)
## Returns the new AnimatedSprite2D, or null if sheet not found.
static func replace_rect(node: ColorRect, sheet_path: String, frame_size: Vector2i) -> AnimatedSprite2D:
	if not ResourceLoader.exists(sheet_path):
		push_warning("SpriteLoader: sheet not found at %s — keeping ColorRect" % sheet_path)
		return null

	var texture: Texture2D = load(sheet_path)
	var frames: SpriteFrames = _build_frames(texture, frame_size)

	var sprite := AnimatedSprite2D.new()
	sprite.name = node.name
	sprite.sprite_frames = frames
	sprite.position = node.position + Vector2(frame_size.x * 0.5, frame_size.y * 0.5)
	sprite.play(ANIM_IDLE)

	var parent: Node = node.get_parent()
	var idx: int = node.get_index()
	parent.remove_child(node)
	node.queue_free()
	parent.add_child(sprite)
	parent.move_child(sprite, idx)

	return sprite

## Build a SpriteFrames resource from a sheet texture + frame size.
static func _build_frames(texture: Texture2D, frame_size: Vector2i) -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")

	var anim_names: Array[String] = [ANIM_IDLE, ANIM_WALK, ANIM_ATTACK, ANIM_HIT, ANIM_DEATH]
	for row: int in anim_names.size():
		var anim_name: String = anim_names[row]
		var count: int = FRAME_COUNTS[anim_name]
		frames.add_animation(anim_name)
		frames.set_animation_loop(anim_name, true)
		frames.set_animation_speed(anim_name, ANIM_SPEEDS[anim_name])

		for col: int in count:
			var region := Rect2i(col * frame_size.x, row * frame_size.y, frame_size.x, frame_size.y)
			var atlas := AtlasTexture.new()
			atlas.atlas = texture
			atlas.region = region
			frames.add_frame(anim_name, atlas)

	return frames

## Convenience: load by folder category name (uses SIZES lookup)
static func build_from_category(node: ColorRect, folder: String, name: String, category: String) -> AnimatedSprite2D:
	var frame_size: Vector2i = SIZES.get(category, Vector2i(32, 64))
	var path: String = "res://assets/sprites/%s/%s/%s_sheet.png" % [folder, name, name]
	return replace_rect(node, path, frame_size)
