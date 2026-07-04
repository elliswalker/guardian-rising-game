extends CanvasLayer

# Planet select — shown after ship launch. Left/Right to aim, Action to fly.
# The flight always lands the next morning (day counter is global).

const PLANETS: Array[Dictionary] = [
	{"id": "earth", "label": "EARTH — Last City", "desc": "Fallen · single front"},
	{"id": "cosmodrome", "label": "EARTH — Cosmodrome", "desc": "Fallen · attacks from BOTH sides"},
	{"id": "moon", "label": "MOON — Hellmouth", "desc": "Hive · it is ALWAYS night here"},
	{"id": "mars", "label": "MARS — Meridian Bay", "desc": "Cabal · drop pods land INSIDE your lines"},
]

@onready var _title: Label = $Title
@onready var _option_labels: Array[Label] = [$Option0, $Option1, $Option2, $Option3]
@onready var _desc: Label = $Desc
@onready var _hint: Label = $Hint

var _cursor: int = 0

func _ready() -> void:
	_title.text = "SELECT DESTINATION"
	_hint.text = "[ UP / DOWN ]  choose      [ SPACE ]  launch"
	# default cursor to somewhere you aren't
	for i in PLANETS.size():
		if PLANETS[i]["id"] != GameState.current_planet:
			_cursor = i
			break
	_refresh()

func _unhandled_input(event: InputEvent) -> void:
	# vertical list, vertical keys (arrows / d-pad)
	if event.is_action_pressed("ui_up"):
		_cursor = maxi(_cursor - 1, 0)
		_refresh()
	elif event.is_action_pressed("ui_down"):
		_cursor = mini(_cursor + 1, PLANETS.size() - 1)
		_refresh()
	elif event.is_action_pressed("action"):
		GameState.travel_to(PLANETS[_cursor]["id"])

func _refresh() -> void:
	for i in PLANETS.size():
		var p: Dictionary = PLANETS[i]
		var cleared: String = "  ✦ CLEARED" if GameState.planets_cleared.get(p["id"], false) else ""
		var here: String = "  (you are here)" if p["id"] == GameState.current_planet else ""
		_option_labels[i].text = ("▶  " if i == _cursor else "   ") + str(p["label"]) + cleared + here
		_option_labels[i].modulate = Color(1, 1, 1, 1.0 if i == _cursor else 0.55)
	_desc.text = str(PLANETS[_cursor]["desc"])
