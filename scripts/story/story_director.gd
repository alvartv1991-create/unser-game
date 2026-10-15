extends Node
## Story wiring that reacts to events instead of being started by a level:
## - follow-up dialogue after fights (the surrendering raider, the swarm dispersing)
## - flags and objectives for fights that end without dialogue (talking, fleeing)
## - companion barks: after a glitch, after a fight, when entering an area, when someone died,
##   when the holy sword breaks. Texts live in data/barks.json (speaker -> situation -> [{de, en}]).
## Autoload "StoryDirector". Barks go out through EventBus.bark_requested; Codex shows them (H4).

const RAIDERS_FILE := "res://dialogue/area1/raiders.dialogue"
const ALIEN_FILE := "res://dialogue/area1/alien_zone.dialogue"
const GLITCH_COOLDOWN := 6.0     # seconds between two glitch barks
const AREA_COOLDOWN := 20.0      # seconds between two "entering an area" barks

var _last_bark: Dictionary = {}  # situation -> seconds
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	EventBus.combat_finished.connect(_on_combat_finished)
	EventBus.device_glitch.connect(_on_device_glitch)
	EventBus.scene_changed.connect(_on_scene_changed)
	EventBus.companion_died.connect(_on_companion_died)
	EventBus.flag_changed.connect(_on_flag_changed)


## Story reactions only happen in the real Area 1 levels (scenes/levels/area*.tscn), never in
## test scenes, art previews or the dialogue tester, so automated tests and previews stay predictable.
func in_story_level() -> bool:
	return SceneRouter.current_scene_path.get_file().begins_with("area")


func _on_combat_finished(result: Dictionary) -> void:
	if not in_story_level():
		return
	var id := str(result.get("encounter_id", ""))
	var outcome := str(result.get("outcome", ""))
	var won := outcome in ["win", "talk", "cheat"]
	match id:
		"raiders_street":
			if won:
				GameState.set_flag("raiders_street_done")
				GameState.set_objective("OBJ_VISIT_VIDEOSTORE")
		"raiders_camp":
			if outcome == "win":
				_follow_up(RAIDERS_FILE, "camp_after_fight")
			elif outcome == "talk":
				GameState.set_flag("raiders_camp_resolved", "talk")
				GameState.add_item("jammer")
				GameState.set_objective("OBJ_CROSS_ALIEN_ZONE")
		"alien_swarm_zone":
			if won:
				_follow_up(ALIEN_FILE, "after_cheat")
	if won:
		bark_from_party("after_fight")


## Starts a dialogue once the combat screen is gone and the level runs again.
func _follow_up(file: String, cue: String) -> void:
	for i in 300:
		if not SceneRouter.is_in_combat() and not SceneRouter.is_changing_scene():
			break
		await get_tree().process_frame
	DialogueRunner.start(file, cue)


func _on_device_glitch(_intensity: float, _duration: float) -> void:
	if _cooled_down("glitch", GLITCH_COOLDOWN):
		# The tinkerer studies the signals, so they get the first word when they're around.
		if GameState.in_party("tinkerer") and rng.randf() < 0.75:
			bark("tinkerer", "glitch")
		else:
			bark_from_party("glitch")


func _on_scene_changed(scene_path: String) -> void:
	if scene_path.get_file().begins_with("area") and _cooled_down("enter_area", AREA_COOLDOWN):
		bark_from_party("enter_area")


func _on_companion_died(id: String, _reason: String) -> void:
	for other in GameState.party:
		if other != id and GameState.is_alive(other) and has_bark(other, "died_" + id):
			bark(other, "died_" + id)
			return


func _on_flag_changed(id: String, value: Variant) -> void:
	if id == "holy_sword_broken" and value:
		bark_from_party("sword_broke")


## A random living party member who has a line for this situation says it.
func bark_from_party(situation: String) -> bool:
	var speakers: Array[String] = []
	for id in GameState.party:
		if GameState.is_alive(id) and has_bark(id, situation):
			speakers.append(id)
	if speakers.is_empty():
		return false
	return bark(speakers[rng.randi_range(0, speakers.size() - 1)], situation)


func bark(speaker_id: String, situation: String) -> bool:
	var lines: Array = Data.all("barks").get(speaker_id, {}).get(situation, [])
	if lines.is_empty():
		return false
	EventBus.bark_requested.emit(speaker_id, Data.text(lines[rng.randi_range(0, lines.size() - 1)]))
	return true


func has_bark(speaker_id: String, situation: String) -> bool:
	return not Data.all("barks").get(speaker_id, {}).get(situation, []).is_empty()


func _cooled_down(situation: String, seconds: float) -> bool:
	var now := Time.get_ticks_msec() / 1000.0
	if now - float(_last_bark.get(situation, -1000.0)) < seconds:
		return false
	_last_bark[situation] = now
	return true
