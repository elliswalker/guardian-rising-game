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

# Music layer (#39): Kingdom's rule — the crossfade IS the announcement.
# A warm pad owns the day, a dark drone owns the night; both are seamless
# generated loops (tools/gen_music_loops.py).
const MUSIC: Dictionary = {
	"day":   preload("res://assets/audio/music_day.wav"),
	"night": preload("res://assets/audio/music_night.wav"),
}
const MUSIC_DB := -14.0      # sits far under the SFX
const MUSIC_SILENT_DB := -60.0
const MUSIC_FADE := 5.0      # slow — day into night, not track into track

var _last_played: Dictionary = {}
var _last_glimmer: int = 0
var _music_a: AudioStreamPlayer
var _music_b: AudioStreamPlayer
var _music_active: AudioStreamPlayer = null
var _current_track: String = ""

func _ready() -> void:
	GameState.glimmer_changed.connect(_on_glimmer_changed)
	GameState.dusk_triggered.connect(func(_d: int) -> void: play("dusk"))
	GameState.dawn_triggered.connect(func(_d: int) -> void: play("dawn"))
	GameState.wave_changed.connect(func(_w: int) -> void: play("wave"))
	GameState.encampment_upgraded.connect(func(_t: int) -> void: play("ding"))
	GameState.shards_changed.connect(_on_shards_changed)
	GameState.portal_broken.connect(func(_f: String) -> void: play("wave", -2.0, 0.8))
	_setup_music()

func _setup_music() -> void:
	# WAV imports don't loop by default — flip it on the shared resources
	for key: String in MUSIC:
		var ws: AudioStreamWAV = MUSIC[key] as AudioStreamWAV
		if ws:
			ws.loop_mode = AudioStreamWAV.LOOP_FORWARD
			ws.loop_begin = 0
			ws.loop_end = ws.data.size() / 2  # 16-bit mono: 2 bytes per frame
	_music_a = AudioStreamPlayer.new()
	_music_b = AudioStreamPlayer.new()
	_music_a.bus = "Music"
	_music_b.bus = "Music"
	add_child(_music_a)
	add_child(_music_b)
	# The signal contract covers every planet — Moon's lull/surge phases
	# emit the same day/dusk signals, so it needs no special casing.
	GameState.day_started.connect(func(_d: int) -> void: play_music("day"))
	GameState.dawn_triggered.connect(func(_d: int) -> void: play_music("day"))
	GameState.dusk_triggered.connect(func(_d: int) -> void: play_music("night"))
	GameState.game_over.connect(func() -> void: stop_music(2.0))
	GameState.victory.connect(func() -> void: stop_music(6.0))

func play_music(track: String) -> void:
	if track == _current_track or not MUSIC.has(track):
		return
	_current_track = track
	var incoming: AudioStreamPlayer = _music_b if _music_active == _music_a else _music_a
	var outgoing: AudioStreamPlayer = _music_active
	_music_active = incoming
	incoming.stream = MUSIC[track]
	incoming.volume_db = MUSIC_SILENT_DB
	incoming.play()
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(incoming, "volume_db", MUSIC_DB, MUSIC_FADE)
	if outgoing and outgoing.playing:
		tween.tween_property(outgoing, "volume_db", MUSIC_SILENT_DB, MUSIC_FADE)
		tween.chain().tween_callback(outgoing.stop)

func stop_music(fade: float = 2.0) -> void:
	_current_track = ""
	for p: AudioStreamPlayer in [_music_a, _music_b]:
		if p and p.playing:
			var tween: Tween = create_tween()
			tween.tween_property(p, "volume_db", MUSIC_SILENT_DB, fade)
			tween.tween_callback(p.stop)

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
	p.bus = "SFX"
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
