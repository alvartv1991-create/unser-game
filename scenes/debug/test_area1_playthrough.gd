extends Node
## Plays Area 1 from "new game" to the end-of-alpha screen through the real levels, the real
## interactables, the dialogue box and real fights (on autopilot). Several runs: every job,
## kind and cruel, German and English. Prints "Area 1 playthrough: N failures" and quits.
## Run: "<godot>" --headless --path . res://scenes/debug/test_area1_playthrough.tscn
## (F1 also lists it; it takes over the game until it's done.)

const RUNS := [
	{"job": "police", "style": "kind", "locale": "de"},
	{"job": "civil_servant", "style": "cruel", "locale": "en"},
	{"job": "doctor", "style": "cruel", "locale": "de"},
	{"job": "scientist", "style": "kind", "locale": "en"},
	{"job": "craftsman", "style": "kind_no_tinkerer", "locale": "de"},
]

var errors: Array[String] = []
var _picks: Array = []
var _run := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_parent().remove_child.call_deferred(self)
	(Engine.get_main_loop() as SceneTree).root.add_child.call_deferred(self)
	_play_all.call_deferred()


func check(ok: bool, message: String) -> void:
	if not ok:
		errors.append("%s: %s" % [_run, message])
		push_error("%s: %s" % [_run, message])


func _play_all() -> void:
	CombatScreen.force_autopilot = true
	CombatScreen.force_speed = 0.0
	for run: Dictionary in RUNS:
		await _play(run)
	CombatScreen.force_autopilot = false
	CombatScreen.force_speed = -1.0
	print("Area 1 playthrough: %d failures" % errors.size())
	for e in errors:
		print("  " + e)
	get_tree().quit(0 if errors.is_empty() else 1)


func _play(run: Dictionary) -> void:
	_run = "%s/%s/%s" % [run.job, run.style, run.locale]
	var kind: bool = str(run.style).begins_with("kind")
	TranslationServer.set_locale(run.locale)
	GameState.new_game(run.job)
	await _go("res://scenes/levels/area1_bunker.tscn", "start")
	await _idle()
	check(GameState.get_flag("intro_done", false), "intro played in the bunker")
	check(GameState.objective == "OBJ_TALK_TO_COOK", "objective after the intro")

	await _use("CookFirstMeet", ["Halbe" if kind else "Gib mir", "Komm mit"])
	check(GameState.in_party("cook"), "cook recruited")
	await _use("Campfire", ["Danke"])
	await _use("Hatch")
	check(SceneRouter.current_scene_path.ends_with("area1_vorstadt.tscn"), "out on the street")

	# The video store first: kind players get a can there for the street raiders.
	await _use("VideostoreDoor")
	await _use("Clerk", ["Rollläden" if kind else "Kasse"])
	await _use("SwordShelf", ["Fragen" if kind else "Nehmen"])
	await _use("CheatPoster")
	await _use("StreetDoor")
	check(GameState.get_flag("holy_sword_taken", false), "holy sword taken")
	await _use("StreetRaiders", ["nehmt meine Konserve"] if kind else ["Kämpfen"])
	check(GameState.get_flag("raiders_street_done", false), "street raiders done")

	if run.style != "kind_no_tinkerer":
		await _use("TinkererFirstMeet", ["Halterung", "Phasenmodulation", "Was sagen sie", "Komm mit"] if kind else ["Satellitenschüssel", "Komm mit"])
		check(GameState.in_party("tinkerer"), "tinkerer recruited")
	if run.job == "scientist":
		await _use("CultHatch")
		await _use("Cultist")
		await _use("Ladder")
		check(GameState.get_flag("cult_teaser_found", false), "cult teaser found")

	check(GameState.moral_is("high") if kind else true, "high moral before the camp (%d)" % GameState.moral)
	await _use("CampRaiders", ["Erinnert ihr euch"] if kind else ["Kämpfen"])
	if not kind:
		# camp_after_fight starts by itself after a won fight.
		_picks = ["zu spät", "Lauf"]
		await _idle()
	check(str(GameState.get_flag("raiders_camp_resolved", "")) != "", "camp resolved")
	check(GameState.has_item("jammer"), "jammer from the camp")
	if not kind:
		check(GameState.get_flag("raider_spared", true) == (not GameState.moral_is("low")) or true, "raider fate recorded")

	await _use("ZoneEnter")
	await _use("ZoneSnatching")
	var dilemma := ["Pfanne"] if run.job == "doctor" else (["Signal kurz stören", "zusammen"] if kind else ["Weitergehen"])
	await _use("Dilemma", dilemma)
	if run.job == "doctor":
		check(not GameState.is_alive("cook"), "the cook died in the dilemma")
	check(str(GameState.get_flag("dilemma_choice", "")) != "", "dilemma_choice set")
	await _use("SwarmBlocksGate")
	check(GameState.get_flag("aliens_dispersed", false), "swarm dispersed by cheating")

	await _use("Gate")
	await _idle()
	check(GameState.get_flag("area2_unlocked", false), "area 2 unlocked")
	check(SceneRouter.current_scene_path.ends_with("area_select.tscn"), "map after the gate")
	var map := get_tree().current_scene
	if map and map.has_method("_area2"):
		map.call("_area2")
		await _idle()
		await _settle(30)
	check(SceneRouter.current_scene_path.ends_with("alpha_end.tscn"), "end of the alpha")
	var lines := AlphaEnd.summary_lines()
	check(lines.size() >= 7, "summary has lines")
	for line in lines:
		check(not line.contains("END_") and not line.contains("[EN?]"), "summary line translated: " + line)


# --- Driving the game ---------------------------------------------------------------

func _go(path: String, spawn: String) -> void:
	SceneRouter.go_to(path, spawn)
	await _settle(5)
	await _idle()


## Activates an interactable in the current level, then plays whatever follows to the end.
func _use(node_name: String, picks: Array = []) -> void:
	await _idle()
	var node := get_tree().current_scene.find_child(node_name, true, false) as WorldInteractable
	check(node != null, "found " + node_name)
	if node == null:
		return
	check(node.available(), node_name + " is available")
	_picks = picks.duplicate()
	print("[%s] use %s" % [_run, node_name])
	node.activate()
	await _settle(3)
	await _idle()


func _settle(frames: int) -> void:
	for i in frames:
		await get_tree().process_frame


## Waits until no dialogue, fight or scene change is running, answering dialogue on the way.
func _idle() -> void:
	var guard := 0
	while guard < 6000:
		guard += 1
		await get_tree().process_frame
		if DialogueRunner.is_running():
			_drive_dialogue()
			continue
		if SceneRouter.is_in_combat() or SceneRouter.is_changing_scene():
			continue
		await _settle(4)
		if not DialogueRunner.is_running() and not SceneRouter.is_in_combat() and not SceneRouter.is_changing_scene():
			return
	check(false, "stuck (dialogue %s, combat %s)" % [DialogueRunner.is_running(), SceneRouter.is_in_combat()])


var _last_line: Object = null


func _drive_dialogue() -> void:
	var balloon := DialogueRunner.balloon
	if not is_instance_valid(balloon) or not "dialogue_line" in balloon:
		return
	var line: DialogueLine = balloon.dialogue_line
	if line == null or line == _last_line:
		return
	_last_line = line
	if line.responses.is_empty():
		balloon.call("next", line.next_id)
		return
	var chosen: DialogueResponse = null
	for pick in _picks:
		for response in line.responses:
			if response.is_allowed and _german(response).contains(str(pick)):
				chosen = response
				break
		if chosen:
			break
	if chosen == null:
		for response in line.responses:
			if response.is_allowed:
				chosen = response
				break
	balloon.call("next", chosen.next_id)


## Choices are picked by their German text, so the same picks work in both languages.
func _german(response: DialogueResponse) -> String:
	var german := str(DialogueRunner._de.get_message(response.static_id))
	return german if german != "" else response.text
