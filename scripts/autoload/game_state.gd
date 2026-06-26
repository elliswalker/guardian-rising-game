extends Node

signal glimmer_changed(new_value: int)
signal ghost_captured
signal ghost_released
signal game_over
signal wave_changed(new_wave: int)
signal action_prompt_show(text: String)
signal action_prompt_hide
signal redjack_job_created
signal sweeperbot_job_created
signal builder_job_created
signal dusk_timer_updated(seconds: int)
signal dusk_triggered(day_number: int)
signal dawn_triggered(day_number: int)
signal day_started(day_number: int)
signal build_job_queued
signal attack_ordered
signal portal_broken(faction: String)
signal victory

const GLIMMER_CAP := 1000
const ENCAMPMENT_X: float = -100.0

var glimmer: int = 0:
	set(value):
		glimmer = clampi(value, 0, GLIMMER_CAP)
		glimmer_changed.emit(glimmer)

var is_ghost_captured := false
var wave_number: int = 0
var day_number: int = 0
var redjack_jobs_available: int = 0
var sweeperbot_jobs_available: int = 0
var builder_jobs_available: int = 0
var current_run := 0
var is_attack_phase: bool = false
var portal_active: bool = true
var run_time_seconds: float = 0.0

var _game_over_triggered: bool = false
var _build_queue: Array[Node] = []
var _prompt_owner: Object = null
var _prompt_priority: int = 0
var _prompt_text: String = ""

func add_glimmer(amount: int) -> void:
	glimmer += amount

func spend_glimmer(amount: int) -> bool:
	if glimmer >= amount:
		glimmer -= amount
		return true
	return false

func on_ghost_captured() -> void:
	is_ghost_captured = true
	ghost_captured.emit()

func on_ghost_released() -> void:
	is_ghost_captured = false
	ghost_released.emit()

func trigger_game_over() -> void:
	if _game_over_triggered:
		return
	_game_over_triggered = true
	game_over.emit()
	await get_tree().create_timer(0.1).timeout
	get_tree().change_scene_to_file("res://scenes/ui/game_over.tscn")

func trigger_victory() -> void:
	victory.emit()
	await get_tree().create_timer(0.1).timeout
	get_tree().change_scene_to_file("res://scenes/ui/victory.tscn")

func queue_build_job(site: Node, priority: bool = false) -> void:
	if site not in _build_queue:
		if priority:
			_build_queue.push_front(site)
		else:
			_build_queue.push_back(site)
	build_job_queued.emit()

func claim_next_build_job() -> Node:
	while _build_queue.size() > 0:
		var site: Node = _build_queue[0]
		_build_queue.remove_at(0)
		if is_instance_valid(site):
			return site
	return null

func show_action_prompt(owner: Object, text: String, priority: int = 5) -> void:
	var owner_valid: bool = _prompt_owner != null and is_instance_valid(_prompt_owner)
	if owner_valid and owner != _prompt_owner and priority < _prompt_priority:
		return
	if owner != _prompt_owner or text != _prompt_text:
		_prompt_owner = owner
		_prompt_priority = priority
		_prompt_text = text
		action_prompt_show.emit(text)

func hide_action_prompt(owner: Object) -> void:
	if _prompt_owner == owner:
		_prompt_owner = null
		_prompt_priority = 0
		_prompt_text = ""
		action_prompt_hide.emit()

func new_run() -> void:
	current_run += 1
	glimmer = 0
	wave_number = 0
	day_number = 0
	redjack_jobs_available = 0
	sweeperbot_jobs_available = 0
	builder_jobs_available = 0
	is_ghost_captured = false
	is_attack_phase = false
	portal_active = true
	run_time_seconds = 0.0
	_game_over_triggered = false
	_build_queue.clear()
	_prompt_owner = null
	_prompt_priority = 0
	_prompt_text = ""
	action_prompt_hide.emit()
