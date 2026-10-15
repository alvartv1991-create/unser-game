extends TestCase
## Area 1 story: every required cue exists and compiles, every line is [TEMP] and translated,
## moral-gated choices appear only at the right moral, and choices change the game state.

const AREA := "res://dialogue/area1/"
const REQUIRED := {
	"res://dialogue/area1/intro.dialogue": ["start"],
	"res://dialogue/area1/cook.dialogue": ["first_meet", "idle", "campfire"],
	"res://dialogue/area1/tinkerer.dialogue": ["first_meet", "idle"],
	"res://dialogue/area1/videostore.dialogue": ["clerk", "sword_shelf"],
	"res://dialogue/area1/raiders.dialogue": ["street", "camp", "camp_after_fight"],
	"res://dialogue/area1/cult.dialogue": ["teaser"],
	"res://dialogue/area1/alien_zone.dialogue": ["enter", "snatching", "dilemma", "swarm_blocks_gate", "after_cheat"],
	"res://dialogue/area1/gate.dialogue": ["locked", "open", "coming_soon"],
	"res://dialogue/examine.dialogue": ["tv_flicker", "payphone", "arcade_cabinet", "satellite_dish", "burnt_car", "cheat_poster", "alien_structure", "bunker_door", "cult_symbol"],
}


func before_each() -> void:
	GameState.new_game("craftsman")
	TranslationServer.set_locale("de")


## Plays a cue. At each choice, picks the first allowed response containing one of `picks`
## (in order); without a match it picks the last allowed one. Returns every text seen.
func play(file: String, cue: String, picks: Array = []) -> Array[String]:
	var resource := load(file) as DialogueResource
	DialogueRunner.register_source_text(resource)
	var seen: Array[String] = []
	var line := await DialogueManager.get_next_dialogue_line(resource, cue)
	var guard := 0
	while line != null and guard < 200:
		guard += 1
		seen.append(line.text)
		if line.responses.is_empty():
			line = await DialogueManager.get_next_dialogue_line(resource, line.next_id)
			continue
		var chosen: DialogueResponse = null
		for pick in picks:
			for response in line.responses:
				if response.is_allowed and response.text.contains(pick):
					chosen = response
					break
			if chosen:
				break
		if chosen == null:
			for response in line.responses:
				if response.is_allowed:
					chosen = response
		for response in line.responses:
			if response.is_allowed:
				seen.append("> " + response.text)
		line = await DialogueManager.get_next_dialogue_line(resource, chosen.next_id)
	return seen


## Texts of the choices the player can see at the first choice point of a cue.
func visible_choices(file: String, cue: String) -> Array[String]:
	var resource := load(file) as DialogueResource
	DialogueRunner.register_source_text(resource)
	var line := await DialogueManager.get_next_dialogue_line(resource, cue)
	while line != null and line.responses.is_empty():
		line = await DialogueManager.get_next_dialogue_line(resource, line.next_id)
	var out: Array[String] = []
	if line:
		for response in line.responses:
			if ChoiceRules.state(response.is_allowed, response.condition_as_text, response.tags) != ChoiceRules.HIDDEN:
				out.append(response.text)
	return out


func _any_contains(texts: Array[String], part: String) -> bool:
	for text in texts:
		if text.contains(part):
			return true
	return false


func test_required_cues_exist_and_compile() -> void:
	for file: String in REQUIRED:
		var result := DMCompiler.compile_string(FileAccess.get_file_as_string(file), file)
		assert_eq(result.errors.size(), 0, file + " compiles: " + str(result.errors))
		var resource := load(file) as DialogueResource
		assert_true(resource != null, file + " loads")
		if resource == null:
			continue
		for cue: String in REQUIRED[file]:
			assert_true(resource.get_cues().has(cue), "%s has cue %s" % [file, cue])


func test_every_line_is_temp_and_has_english() -> void:
	var english := TranslationSync.read_csv(TranslationSync.CSV_PATH)
	for file: String in REQUIRED:
		var source := FileAccess.get_file_as_string(file)
		var result := TranslationSync.process_source(source, file.get_file().get_basename(), {})
		assert_eq(result.source, source, file + ": every line already has an id (run the translation sync)")
		for id: String in result.texts:
			var text: String = result.texts[id]
			assert_true(text.begins_with("[TEMP]"), "%s %s starts with [TEMP]: %s" % [file, id, text])
			assert_true(english.has(id), "%s: %s is in dialogue.csv" % [file, id])
			if english.has(id):
				var en: String = english[id].en
				assert_false(en.begins_with(TranslationSync.MISSING_EN), "%s has English" % id)
				assert_true(en.begins_with("[TEMP]"), "%s English is [TEMP]" % id)


func test_every_speaker_is_known() -> void:
	var speakers := Data.all("speakers")
	for file: String in REQUIRED:
		var resource := load(file) as DialogueResource
		for character in resource.character_names:
			assert_true(character == "player" or speakers.has(character), "%s: speaker \"%s\" is in speakers.json" % [file, character])


func test_english_line_is_shown_in_english() -> void:
	TranslationServer.set_locale("en")
	var seen := await play(AREA + "cook.dialogue", "first_meet", ["Halbe"])
	assert_true(seen[0].begins_with("[TEMP] Oh, you're alive!"), "English first line: " + seen[0])


func test_cook_recruit_and_moral() -> void:
	await play(AREA + "cook.dialogue", "first_meet", ["Halbe", "Komm mit"])
	assert_true(GameState.in_party("cook"), "cook recruited")
	assert_true(GameState.get_flag("cook_recruited"), "flag cook_recruited")
	assert_eq(GameState.moral, 10, "sharing food gives +10")
	assert_eq(GameState.objective, "OBJ_LEAVE_BUNKER", "objective after meeting the cook")


func test_job_options_are_hidden_or_greyed() -> void:
	var choices := await visible_choices(AREA + "cook.dialogue", "first_meet")
	# [#show_locked] options stay visible (greyed out) for other jobs.
	assert_true(_any_contains(choices, "Haltbarkeitsdatum"), "doctor option shown locked to a craftsman")


func test_camp_high_moral_option_only_at_high_moral() -> void:
	var choices := await visible_choices(AREA + "raiders.dialogue", "camp")
	assert_false(_any_contains(choices, "Erinnert ihr euch"), "hidden at neutral moral")
	GameState.add_moral(30)
	choices = await visible_choices(AREA + "raiders.dialogue", "camp")
	assert_true(_any_contains(choices, "Erinnert ihr euch"), "shown at high moral")
	await play(AREA + "raiders.dialogue", "camp", ["Erinnert ihr euch"])
	assert_eq(GameState.get_flag("raiders_camp_resolved"), "moral", "resolved by moral")
	assert_true(GameState.has_item("jammer"), "jammer received")


func test_kill_option_only_at_low_moral_and_sets_raider_spared() -> void:
	var choices := await visible_choices(AREA + "raiders.dialogue", "camp_after_fight")
	assert_false(_any_contains(choices, "zu spät"), "kill option hidden at neutral moral")
	await play(AREA + "raiders.dialogue", "camp_after_fight", ["Lauf"])
	assert_eq(GameState.get_flag("raider_spared"), true, "spared")
	GameState.new_game("craftsman")
	GameState.add_moral(-40)
	await play(AREA + "raiders.dialogue", "camp_after_fight", ["zu spät"])
	assert_eq(GameState.get_flag("raider_spared", true), false, "killed")
	assert_eq(GameState.get_flag("raiders_camp_resolved"), "fight", "resolved by fight")


func test_both_moral_bands_reachable_before_the_camp() -> void:
	# Kind route: cook, street raiders (needs a can), clerk, tinkerer (craftsman job option).
	await play(AREA + "cook.dialogue", "first_meet", ["Halbe", "Komm mit"])
	await play(AREA + "videostore.dialogue", "clerk", ["Rollläden"])
	await play(AREA + "raiders.dialogue", "street", ["nehmt meine Konserve"])
	await play(AREA + "tinkerer.dialogue", "first_meet", ["Halterung", "Komm mit"])
	assert_true(GameState.moral_is("high"), "high moral reachable: %d" % GameState.moral)
	GameState.new_game("craftsman")
	await play(AREA + "cook.dialogue", "first_meet", ["Gib mir die Dose", "Komm mit"])
	await play(AREA + "videostore.dialogue", "clerk", ["Kasse"])
	await play(AREA + "videostore.dialogue", "sword_shelf", ["Nehmen"])
	assert_true(GameState.moral_is("low"), "low moral reachable: %d" % GameState.moral)


func test_dilemma_can_kill_the_cook_and_later_dialogue_remembers() -> void:
	GameState.recruit("cook")
	GameState.recruit("tinkerer")
	var choices := await visible_choices(AREA + "alien_zone.dialogue", "dilemma")
	assert_true(choices.size() >= 3, "at least 3 options: %s" % [choices])
	await play(AREA + "alien_zone.dialogue", "dilemma", ["Pfanne"])
	assert_false(GameState.is_alive("cook"), "the cook died")
	assert_eq(GameState.companions.cook.death_reason, "story:dilemma", "death reason")
	assert_eq(GameState.get_flag("dilemma_choice"), "cook_distraction", "dilemma_choice")
	var idle := await play(AREA + "tinkerer.dialogue", "idle")
	assert_true(_any_contains(idle, "Pfanne"), "tinkerer remembers the cook: %s" % [idle])
	var gate := await play(AREA + "gate.dialogue", "open")
	assert_true(_any_contains(gate, "Pfanne"), "the gate remembers the cook")
	assert_true(GameState.get_flag("area2_unlocked"), "area 2 unlocked")


func test_combat_death_is_remembered_like_a_story_death() -> void:
	GameState.recruit("cook")
	GameState.recruit("tinkerer")
	GameState.kill_companion("tinkerer", "combat:raiders_camp")
	var gate := await play(AREA + "gate.dialogue", "open")
	assert_true(_any_contains(gate, "Batterie"), "gate remembers the tinkerer: %s" % [gate])
	var idle := await play(AREA + "cook.dialogue", "idle")
	assert_true(_any_contains(idle, "eine Person weniger"), "cook remembers the tinkerer")


func test_walking_away_costs_moral() -> void:
	await play(AREA + "alien_zone.dialogue", "dilemma", ["Weitergehen"])
	assert_eq(GameState.moral, -15, "walking away costs moral")
	assert_eq(GameState.get_flag("dilemma_choice"), "walk_away", "dilemma_choice")


func test_cult_teaser_sets_flag() -> void:
	await play(AREA + "cult.dialogue", "teaser")
	assert_true(GameState.get_flag("cult_teaser_found"), "cult_teaser_found")


func test_sword_shelf_equips_the_holy_sword() -> void:
	await play(AREA + "videostore.dialogue", "sword_shelf", ["Fragen"])
	assert_true(GameState.get_flag("holy_sword_taken"), "holy_sword_taken")
	assert_eq(GameState.player.weapon_id, "holy_sword", "equipped")
