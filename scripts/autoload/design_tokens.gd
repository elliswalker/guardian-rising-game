extends Node

# ── Base ──────────────────────────────────────────────────────────────────────
const VOID_BLACK    := Color(0.039, 0.039, 0.059)  # #0a0a0f
const SURFACE       := Color(0.067, 0.067, 0.094)  # #111118
const ELEVATED      := Color(0.102, 0.102, 0.141)  # #1a1a24
const BORDER        := Color(0.145, 0.145, 0.208)  # #252535
const MUTED         := Color(0.208, 0.208, 0.282)  # #353548

# ── Text ──────────────────────────────────────────────────────────────────────
const TEXT_PRIMARY   := Color(0.910, 0.878, 0.816)  # #e8e0d0
const TEXT_SECONDARY := Color(0.690, 0.659, 0.596)  # #b0a898
const TEXT_DISABLED  := Color(0.439, 0.408, 0.376)  # #706860

# ── Economy ───────────────────────────────────────────────────────────────────
const GLIMMER_GOLD := Color(0.941, 0.816, 0.376)  # #f0d060
const GLIMMER_DIM  := Color(0.784, 0.659, 0.188)  # #c8a830
const MOTES_LIGHT  := Color(1.000, 0.973, 0.753)  # #fff8c0
const LEGENDARY    := Color(0.545, 0.416, 0.063)  # #8b6a10

# ── Elements ──────────────────────────────────────────────────────────────────
const SOLAR := Color(1.000, 0.420, 0.000)  # #ff6b00
const VOID  := Color(0.482, 0.000, 1.000)  # #7b00ff
const ARC   := Color(0.000, 0.753, 1.000)  # #00c0ff

# ── Danger ────────────────────────────────────────────────────────────────────
const LIGHT_OUT       := Color(0.800, 0.102, 0.000)  # #cc1a00
const GHOST_WARN      := Color(1.000, 0.200, 0.200)  # #ff3333
const WARNING         := Color(1.000, 0.533, 0.000)  # #ff8800

# ── Factions ──────────────────────────────────────────────────────────────────
const FALLEN_LIGHT := Color(0.831, 0.584, 0.416)  # #d4956a
const FALLEN_DARK  := Color(0.545, 0.271, 0.075)  # #8b4513
const HIVE_LIGHT   := Color(0.290, 0.478, 0.353)  # #4a7a5a
const HIVE_DARK    := Color(0.176, 0.353, 0.247)  # #2d5a3f
const CABAL_LIGHT  := Color(0.769, 0.322, 0.165)  # #c4522a
const CABAL_DARK   := Color(0.545, 0.227, 0.102)  # #8b3a1a

# ── Font sizes ────────────────────────────────────────────────────────────────
const FONT_XS  := 10
const FONT_SM  := 12
const FONT_MD  := 16
const FONT_LG  := 20
const FONT_XL  := 28
const FONT_2XL := 40

# ── Spacing (4px grid) ────────────────────────────────────────────────────────
const SP1 := 4
const SP2 := 8
const SP3 := 12
const SP4 := 16
const SP6 := 24
const SP8 := 32
const SP12 := 48
const SP16 := 64

var _pixel_font: Font = null

func _ready() -> void:
	var path := "res://assets/fonts/PressStart2P-Regular.ttf"
	if ResourceLoader.exists(path):
		_pixel_font = load(path)

func apply_font(label: Label, size: int = FONT_MD) -> void:
	if _pixel_font:
		label.add_theme_font_override("font", _pixel_font)
	label.add_theme_font_size_override("font_size", size)

func get_faction_colors(faction: String) -> Dictionary:
	match faction:
		"fallen": return {"light": FALLEN_LIGHT, "dark": FALLEN_DARK}
		"hive":   return {"light": HIVE_LIGHT,   "dark": HIVE_DARK}
		"cabal":  return {"light": CABAL_LIGHT,  "dark": CABAL_DARK}
	return {"light": TEXT_SECONDARY, "dark": BORDER}

func get_faction_display(faction: String) -> Dictionary:
	match faction:
		"fallen": return {"name": "House of Devils", "subtitle": "Fallen · House of Devils"}
		"hive":   return {"name": "The Hive Rise",   "subtitle": "Hive · Hellmouth"}
		"cabal":  return {"name": "Cabal Assault",   "subtitle": "Cabal · Meridian Bay"}
	return {"name": "Enemies Inbound", "subtitle": "Unknown Faction"}
