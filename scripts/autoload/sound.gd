extends Node

# Diegetic audio bus (EP-04). Kingdom replaces most of its HUD with sound —
# these cues are the first layer: economy feedback, threat warnings, and the
# day/night emotional beats. All streams are generated placeholders
# (tools/gen_placeholder_audio.py).

const STREAMS: Dictionary = {
	"clink":   preload("res://assets/audio/glimmer_clink.wav"),
	"scatter": preload("res://assets/audio/glimmer_scatter.wav"),
	"thunk":   preload("res://assets/audio/build_thunk.wav"),
	"dusk":    preload("res://assets/audio/dusk_stinger.wav"),
	"dawn":    preload("res://assets/audio/dawn_chime.wav"),
	"wave":    preload("res://assets/audio/wave_cue.wav"),
	"chitter": preload("res://assets/audio/fallen_chitter.wav"),
	"shot":    preload("res://assets/audio/golden_shot.wav"),
	"ding":    preload("res://assets/audio/upgrade_ding.wav"),
}

# Per-cue minimum interval so rapid events don't machine-gun the mixer
const THROTTLE: Dictionary = {
	"clink": 0.08, "scatter": 0.2, "chitter": 1.2, "thunk": 0.15,
}

var _last_played: Dictionary = {}
var _last_glimmer: int = 0

func _ready() -> void:
	GameState.glimmer_changed.connect(_on_glimmer_changed)
	GameState.dusk_triggered.connect(func(_d: int) -> void: play("dusk"))
	GameState.dawn_triggered.connect(func(_d: int) -> void: play("dawn"))
	GameState.wave_changed.connect(func(_w: int) -> void: play("wave"))
	GameState.encampment_upgraded.connect(func(_t: int) -> void: play("ding"))
	GameState.shards_changed.connect(_on_shards_changed)
	GameState.portal_broken.connect(func(_f: String) -> void: play("wave", -2.0, 0.8))

func play(cue: String, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	if not STREAMS.has(cue):
		return
	var now: float = Time.get_ticks_msec() / 1000.0
	var min_gap: float = float(THROTTLE.get(cue, 0.0))
	if min_gap > 0.0 and now - float(_last_played.get(cue, -100.0)) < min_gap:
		return
	_last_played[cue] = now
	var p: AudioStreamPlayer = AudioStreamPlayer.new()
	p.stream = STREAMS[cue]
	p.volume_db = volume_db
	p.pitch_scale = pitch
	add_child(p)
	p.finished.connect(p.queue_free)
	p.play()

func _on_glimmer_changed(value: int) -> void:
	if value > _last_glimmer:
		play("clink", -4.0, randf_range(0.95, 1.08))
	_last_glimmer = value

func _on_shards_changed(value: int) -> void:
	if value > 0:
		play("ding", -2.0, 1.3)
