extends TestCase
## Checks Dialogue Manager integration with hello.dialogue: commands, conditions,
## the [TEMP] marker, translations and the missing-text fallback.

const FILE := "res://dialogue/test/hello.dialogue"


func before_each() -> void:
	GameState.new_game("craftsman")
	TranslationServer.set_locale("de")


## Walks from the start until the line with the choices.
func _choice_line() -> DialogueLine:
	var resource := load(FILE) as DialogueResource
	var line := await DialogueManager.get_next_dialogue_line(resource, "start")
	while line != null and line.responses.is_empty():
		line = await DialogueManager.get_next_dialogue_line(resource, line.next_id)
	return line


func _response(line: DialogueLine, part: String) -> DialogueResponse:
	for response in line.responses:
		if response.text.contains(part):
			return response
	return null


func test_first_line_keeps_temp_marker_and_fills_name() -> void:
	var line := await DialogueManager.get_next_dialogue_line(load(FILE), "start")
	assert_true(line.text.begins_with("[TEMP]"), "[TEMP] marker survives: " + line.text)
	assert_true(line.text.contains(GameState.player_name()), "{{GameState.player_name()}} filled in: " + line.text)


func test_static_id_line_is_translated() -> void:
	TranslationServer.set_locale("en")
	var resource := load(FILE) as DialogueResource
	var line := await DialogueManager.get_next_dialogue_line(resource, "start")
	line = await DialogueManager.get_next_dialogue_line(resource, line.next_id)
	assert_eq(line.text, "[TEMP] This line comes from the translation table.", "English from localization/dialogue.csv")
	TranslationServer.set_locale("de")


func test_conditions_follow_job_and_moral() -> void:
	var line := await _choice_line()
	assert_false(_response(line, "Puls").is_allowed, "doctor option closed for craftsman")
	assert_false(_response(line, "Umarmen").is_allowed, "high-moral option closed at moral 0")
	GameState.new_game("doctor")
	GameState.add_moral(30)
	line = await _choice_line()
	assert_true(_response(line, "Puls").is_allowed, "doctor option open for doctor")
	assert_true(_response(line, "Umarmen").is_allowed, "high-moral option open at moral 30")


func test_choice_runs_its_command() -> void:
	var line := await _choice_line()
	var nice := _response(line, "Nett sein")
	await DialogueManager.get_next_dialogue_line(load(FILE), nice.next_id)
	assert_eq(GameState.moral, 10, "$> GameState.add_moral(10) ran")


func test_runner_survives_missing_cue() -> void:
	var started: Array = []
	var on_started := func(file: String, title: String) -> void: started.append(title)
	EventBus.dialogue_started.connect(on_started)
	DialogueRunner.start(FILE, "does_not_exist")
	EventBus.dialogue_started.disconnect(on_started)
	assert_true(DialogueRunner.is_running(), "a placeholder dialogue runs instead of crashing")
	assert_eq(started, ["does_not_exist"], "dialogue_started reports the requested cue")
	# Dialogue Manager adds the balloon one frame later. Then close it the way a scene change would.
	var tree := Engine.get_main_loop() as SceneTree
	await tree.process_frame
	assert_true(is_instance_valid(DialogueRunner.balloon) and DialogueRunner.balloon.is_inside_tree(), "balloon is shown")
	DialogueRunner.balloon.queue_free()
	await tree.process_frame
	assert_false(DialogueRunner.is_running(), "runner finished when its balloon disappeared")
