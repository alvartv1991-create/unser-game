extends TestCase
## The real combat screen, end to end, with the autopilot playing the party and no pauses.

const SCENE := preload("res://scenes/combat/combat.tscn")
const FINISHED := ["win", "talk", "flee", "cheat", "game_over_screen"]


func _fight(encounter_id: String) -> Dictionary:
	var tree := Engine.get_main_loop() as SceneTree
	var combat := SCENE.instantiate()
	combat.speed = 0.0
	combat.autopilot = true
	tree.root.add_child(combat)
	var results: Array = []
	var on_finished := func(result: Dictionary) -> void: results.append(result)
	EventBus.combat_finished.connect(on_finished)
	combat.start(encounter_id)
	var frames := 0
	while results.is_empty() and frames < 600 and combat._overlay == null:
		frames += 1
		await tree.process_frame
	EventBus.combat_finished.disconnect(on_finished)
	var lost_screen: bool = combat._overlay != null
	combat.queue_free()
	await tree.process_frame
	return results[0] if not results.is_empty() else {outcome = "game_over_screen" if lost_screen else "timeout"}


func test_street_fight_plays_to_the_end() -> void:
	GameState.new_game("police")
	GameState.recruit("cook")
	var result := await _fight("raiders_street")
	assert_eq(result.outcome, "win", "won through the real screen")
	assert_true(GameState.has_item("canned_food"), "loot reached the inventory")


func test_alien_fight_ends_by_cheating() -> void:
	GameState.new_game("scientist")
	GameState.recruit("tinkerer")
	var result := await _fight("alien_swarm_zone")
	assert_eq(result.outcome, "cheat", "the tinkerer's signal")


func test_lost_fight_shows_the_game_over_panel() -> void:
	GameState.new_game("civil_servant")
	var result := await _fight("raiders_camp")
	assert_eq(result.outcome, "game_over_screen", "a lone civil servant loses the camp")
	assert_eq(GameState.player.hp, GameState.player.max_hp, "nothing written back after a loss")


func test_every_job_every_fight_both_languages() -> void:
	for locale in ["de", "en"]:
		TranslationServer.set_locale(locale)
		for job_id in Data.all("jobs"):
			for encounter_id in Data.all("encounters"):
				GameState.new_game(job_id)
				GameState.recruit("cook")
				GameState.recruit("tinkerer")
				var result := await _fight(encounter_id)
				assert_true(FINISHED.has(result.outcome), "%s/%s/%s ended: %s" % [locale, job_id, encounter_id, result.outcome])
	TranslationServer.set_locale("de")


func test_scene_router_runs_the_fight_and_returns() -> void:
	GameState.new_game("craftsman")
	GameState.recruit("cook")
	CombatScreen.force_autopilot = true
	CombatScreen.force_speed = 0.0
	var results: Array = []
	var on_finished := func(result: Dictionary) -> void: results.append(result)
	EventBus.combat_finished.connect(on_finished)
	SceneRouter.start_combat("raiders_street")
	assert_true(SceneRouter.is_in_combat(), "combat overlay open")
	var tree := Engine.get_main_loop() as SceneTree
	var frames := 0
	while results.is_empty() and frames < 600:
		frames += 1
		await tree.process_frame
	await tree.process_frame
	EventBus.combat_finished.disconnect(on_finished)
	CombatScreen.force_autopilot = false
	CombatScreen.force_speed = -1.0
	assert_eq(results.size(), 1, "combat_finished emitted once")
	assert_false(SceneRouter.is_in_combat(), "SceneRouter closed the fight")
