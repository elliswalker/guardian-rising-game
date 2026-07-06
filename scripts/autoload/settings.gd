extends Node

# Settings (#48) — audio buses + video mode, persisted to
# user://settings.cfg. Loaded before Sound so the Music/SFX buses exist
# by the time any player is created.

const CFG_PATH := "user://settings.cfg"

# Volumes are stored 0..10 (menu steps); 0 = mute, 10 = full
var master_volume: int = 8
var music_volume: int = 7
var sfx_volume: int = 8
var fullscreen: bool = false
var vsync: bool = true

func _enter_tree() -> void:
	_ensure_bus("Music")
	_ensure_bus("SFX")
	_load()
	apply()

func _ensure_bus(bus: String) -> void:
	if AudioServer.get_bus_index(bus) == -1:
		AudioServer.add_bus()
		var idx: int = AudioServer.bus_count - 1
		AudioServer.set_bus_name(idx, bus)
		AudioServer.set_bus_send(idx, "Master")

func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(CFG_PATH) != OK:
		return
	master_volume = clampi(int(cfg.get_value("audio", "master", master_volume)), 0, 10)
	music_volume = clampi(int(cfg.get_value("audio", "music", music_volume)), 0, 10)
	sfx_volume = clampi(int(cfg.get_value("audio", "sfx", sfx_volume)), 0, 10)
	fullscreen = bool(cfg.get_value("video", "fullscreen", fullscreen))
	vsync = bool(cfg.get_value("video", "vsync", vsync))

func save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "master", master_volume)
	cfg.set_value("audio", "music", music_volume)
	cfg.set_value("audio", "sfx", sfx_volume)
	cfg.set_value("video", "fullscreen", fullscreen)
	cfg.set_value("video", "vsync", vsync)
	cfg.save(CFG_PATH)

func apply() -> void:
	_apply_bus("Master", master_volume)
	_apply_bus("Music", music_volume)
	_apply_bus("SFX", sfx_volume)
	var mode: int = DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.window_get_mode() != mode:
		DisplayServer.window_set_mode(mode)
	var vs: int = DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED
	DisplayServer.window_set_vsync_mode(vs)

func _apply_bus(bus: String, steps: int) -> void:
	var idx: int = AudioServer.get_bus_index(bus)
	if idx == -1:
		return
	if steps <= 0:
		AudioServer.set_bus_mute(idx, true)
		return
	AudioServer.set_bus_mute(idx, false)
	# 10 steps -> 0 dB, each step down -3 dB: gentle, audible curve
	AudioServer.set_bus_volume_db(idx, float(steps - 10) * 3.0)
