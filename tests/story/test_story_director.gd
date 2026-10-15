extends TestCase
## StoryDirector: companion barks and the story reactions to fights.

var barks: Array = []
var _saved_path := ""


func before_each() -> void:
	GameState.new_game("craftsman")
	TranslationServer.set_locale("de")
	barks.clear()
	StoryDirector._last_bark.clear()
	_saved_path = SceneRouter.current_scene_path


func _listen() -> Callable:
	var on_bark := func(speaker: String, text: String) -> void: barks.append([speaker, text])
	EventBus.bark_requested.connect(on_bark)
	return on_bark


func _stop(on_bark: Callable) -> void:
	EventBus.bark_requested.disconnect(on_bark)
	SceneRouter.current_scene_path = _saved_path


func test_bark_texts_exist_in_both_languages() -> void:
	for speaker: String in Data.all("barks"):
		if speaker.begins_with("_"):
			continue
		for situation: String in Data.all("barks")[speaker]:
			for line: Dictionary in Data.all("barks")[speaker][situation]:
				assert_true(str(line.get("de", "")).begins_with("[TEMP]"), "%s/%s de is [TEMP]" % [speaker, situation])
				assert_true(str(line.get("en", "")).begins_with("[TEMP]"), "%s/%s en is [TEMP]" % [speaker, situation])


func test_every_companion_has_the_required_barks() -> void:
	for id in ["cook", "tinkerer"]:
		for situation in ["glitch", "after_fight", "enter_area", "sword_broke"]:
			assert_true(StoryDirector.has_bark(id, situation), "%s has a %s bark" % [id, situation])
	assert_true(StoryDirector.has_bark("tinkerer", "died_cook"), "tinkerer reacts to the cook's death")
	assert_true(StoryDirector.has_bark("cook", "died_tinkerer"), "cook reacts to the tinkerer's death")


func test_glitch_bark_has_a_cooldown_and_is_localized() -> void:
	var on_bark := _listen()
	GameState.recruit("tinkerer")
	TranslationServer.set_locale("en")
	EventBus.device_glitch.emit(0.5, 1.0)
	EventBus.device_glitch.emit(0.5, 1.0)
	_stop(on_bark)
	TranslationServer.set_locale("de")
	assert_eq(barks.size(), 1, "second glitch right after is on cooldown")
	if barks.size() == 1:
		assert_eq(barks[0][0], "tinkerer", "tinkerer reacts")
		assert_false(str(barks[0][1]).contains("Grammatik"), "English text: " + str(barks[0][1]))


func test_no_bark_without_party() -> void:
	var on_bark := _listen()
	EventBus.device_glitch.emit(0.5, 1.0)
	_stop(on_bark)
	assert_eq(barks.size(), 0, "nobody to bark")


func test_companion_death_makes_the_other_one_react() -> void:
	var on_bark := _listen()
	GameState.recruit("cook")
	GameState.recruit("tinkerer")
	GameState.kill_companion("cook", "combat:raiders_camp")
	_stop(on_bark)
	assert_eq(barks.size(), 1, "one reaction")
	if barks.size() == 1:
		assert_eq(barks[0][0], "tinkerer", "the tinkerer reacts to the cook")


func test_sword_breaking_gets_a_reaction() -> void:
	var on_bark := _listen()
	GameState.recruit("cook")
	GameState.set_flag("holy_sword_broken")
	_stop(on_bark)
	assert_eq(barks.size(), 1, "sword bark")


func test_fights_outside_story_levels_change_nothing() -> void:
	var on_bark := _listen()
	SceneRouter.current_scene_path = "res://scenes/levels/test_platforming.tscn"
	EventBus.combat_finished.emit({"encounter_id": "raiders_camp", "outcome": "talk", "loot": {}, "died": []})
	_stop(on_bark)
	assert_eq(GameState.get_flag("raiders_camp_resolved"), false, "test scenes don't run story wiring")


func test_talking_out_of_the_camp_fight_resolves_the_camp() -> void:
	var on_bark := _listen()
	SceneRouter.current_scene_path = "res://scenes/levels/area1_vorstadt.tscn"
	EventBus.combat_finished.emit({"encounter_id": "raiders_camp", "outcome": "talk", "loot": {}, "died": []})
	_stop(on_bark)
	assert_eq(GameState.get_flag("raiders_camp_resolved"), "talk", "resolved by talking")
	assert_true(GameState.has_item("jammer"), "jammer received")
	assert_eq(GameState.objective, "OBJ_CROSS_ALIEN_ZONE", "next objective")


func test_street_fight_sets_its_flag() -> void:
	var on_bark := _listen()
	SceneRouter.current_scene_path = "res://scenes/levels/area1_vorstadt.tscn"
	EventBus.combat_finished.emit({"encounter_id": "raiders_street", "outcome": "win", "loot": {}, "died": []})
	_stop(on_bark)
	assert_true(GameState.get_flag("raiders_street_done"), "raiders_street_done")
