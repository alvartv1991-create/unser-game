extends TestCase


func before_each() -> void:
	GameState.new_game("doctor")


func test_new_game_uses_job_stats_and_items() -> void:
	assert_eq(GameState.player.job_id, "doctor", "job")
	assert_eq(GameState.player.stats.int, 8, "int from jobs.json")
	assert_eq(GameState.player.max_hp, 20 + 4 * 4, "max_hp = hp_base + end * hp_per_end")
	assert_eq(GameState.player.hp, GameState.player.max_hp, "starts at full HP")
	assert_true(GameState.has_item("bandage", 2), "doctor starts with 2 bandages")
	assert_true(GameState.unlocked_areas.has("area1_vorstadt"), "area 1 unlocked")


func test_player_name_falls_back_to_protagonist() -> void:
	assert_eq(GameState.player_name(), Data.text(Data.protagonist().name), "default name")
	GameState.player.name = "Custom"
	assert_eq(GameState.player_name(), "Custom", "custom name wins")


func test_flags() -> void:
	assert_eq(GameState.get_flag("nope"), false, "missing flag defaults to false")
	assert_eq(GameState.get_flag("nope", 7), 7, "custom default")
	GameState.set_flag("door_open")
	assert_eq(GameState.get_flag("door_open"), true, "set without value = true")
	GameState.set_flag("dilemma_choice", "left_behind")
	assert_eq(GameState.get_flag("dilemma_choice"), "left_behind", "string flag")


func test_moral_clamps_and_bands() -> void:
	assert_true(GameState.moral_is("neutral"), "starts neutral")
	GameState.add_moral(30)
	assert_true(GameState.moral_is("high"), "30 is high")
	GameState.add_moral(500)
	assert_eq(GameState.moral, 100, "clamped to moral_max")
	GameState.add_moral(-1000)
	assert_eq(GameState.moral, -100, "clamped to moral_min")
	assert_true(GameState.moral_is("low"), "-100 is low")


func test_party_respects_max_active() -> void:
	GameState.recruit("cook")
	GameState.recruit("tinkerer")
	assert_eq(GameState.party.size(), 2, "both fit with max_active_companions = 2")
	assert_eq(GameState.recruited_alive().size(), 2, "both recruited")
	assert_eq(GameState.combat_party("all").size(), 2, "all mode")


func test_kill_companion_is_permanent() -> void:
	var died: Array = []
	var on_died := func(id: String, reason: String) -> void: died.append([id, reason])
	EventBus.companion_died.connect(on_died)
	GameState.recruit("cook")
	GameState.kill_companion("cook", "story:dilemma")
	EventBus.companion_died.disconnect(on_died)
	assert_false(GameState.is_alive("cook"), "cook is dead")
	assert_false(GameState.in_party("cook"), "removed from party")
	assert_eq(died, [["cook", "story:dilemma"]], "signal emitted once with reason")
	assert_eq(GameState.companions.cook.death_reason, "story:dilemma", "reason stored")
	GameState.recruit("cook")
	assert_false(GameState.in_party("cook"), "the dead can't be recruited again")
	assert_false(GameState.recruited_alive().has("cook"), "not in recruited_alive")


func test_items() -> void:
	GameState.add_item("canned_food", 2)
	assert_true(GameState.remove_item("canned_food"), "remove one")
	assert_eq(GameState.inventory.canned_food, 1, "one left")
	assert_false(GameState.remove_item("canned_food", 5), "can't remove more than you have")
	assert_true(GameState.remove_item("canned_food"), "remove last")
	assert_false(GameState.inventory.has("canned_food"), "empty entries are removed")


func test_rest_heals_and_cook_bonus() -> void:
	GameState.recruit("cook")
	GameState.player.hp = 1
	GameState.companions.cook.hp = 1
	GameState.rest()
	assert_eq(GameState.player.hp, GameState.player.max_hp, "player healed")
	assert_eq(GameState.companions.cook.hp, GameState.companions.cook.max_hp, "cook healed")
	assert_eq(GameState.get_flag("well_fed"), true, "cook in party gives well_fed")


func test_save_round_trip_through_json() -> void:
	GameState.recruit("cook")
	GameState.recruit("tinkerer")
	GameState.kill_companion("cook", "combat:raiders_camp")
	GameState.add_moral(-30)
	GameState.set_flag("raiders_camp_resolved", "fight")
	GameState.set_objective("OBJ_TEST_DEBUG_MENU")
	GameState.player.hp = 7
	var saved: Dictionary = JSON.parse_string(JSON.stringify(GameState.to_dict()))
	GameState.reset()
	GameState.from_dict(saved)
	assert_eq(GameState.player.hp, 7, "hp restored")
	assert_eq(typeof(GameState.player.hp), TYPE_INT, "hp is an int again after JSON")
	assert_eq(typeof(GameState.player.stats.end), TYPE_INT, "stats are ints again")
	assert_false(GameState.is_alive("cook"), "dead stays dead")
	assert_eq(GameState.companions.cook.death_reason, "combat:raiders_camp", "death reason restored")
	assert_eq(Array(GameState.party), ["tinkerer"], "party restored")
	assert_eq(GameState.moral, -30, "moral restored")
	assert_eq(GameState.get_flag("raiders_camp_resolved"), "fight", "flag restored")
	assert_eq(GameState.objective, "OBJ_TEST_DEBUG_MENU", "objective restored")
	assert_eq(GameState.inventory.bandage, 2, "inventory restored")
