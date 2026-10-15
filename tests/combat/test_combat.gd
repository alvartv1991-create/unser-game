extends TestCase
## Combat logic, headless. Covers the H1 test list.


func before_each() -> void:
	GameState.new_game("doctor")
	GameState.recruit("cook")
	GameState.recruit("tinkerer")


func _state(encounter_id: String, seed_value: int = 7) -> CombatState:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var state := CombatSetup.from_game(encounter_id, rng)
	state.fixed_variance = 0
	state.take_events()
	return state


func _types(state: CombatState) -> Array:
	return state.take_events().map(func(e: Dictionary) -> String: return e.type)


func test_damage_and_defending() -> void:
	var state := _state("raiders_street")
	var cook := state.fighter("cook")  # fists 2 + str 5 / 2 = 4
	var scavenger := state.fighter("enemy_1")
	state.perform(CombatAction.attack("cook", "enemy_1"))
	assert_eq(scavenger.hp, 18 - 4, "fists + str/2")
	scavenger.defending = true
	state.perform(CombatAction.attack("cook", "enemy_1"))
	assert_eq(scavenger.hp, 14 - 2, "defending halves the damage")
	assert_eq(cook.hp, cook.max_hp, "attacker unhurt")


func test_initiative_order() -> void:
	var state := _state("raiders_camp")
	state.next_turn()
	var ids: Array = state.order.map(func(f: Combatant) -> String: return f.id)
	# doctor: end 4 + int 8 / 2 = 8 · cook: 6 + 2 = 8 · tinkerer: 4 + 3.5 = 7.5 · scavengers 6 · brute 4
	assert_true(ids.slice(0, 2).has("player") and ids.slice(0, 2).has("cook"), "the 8s go first: %s" % [ids])
	assert_eq(ids[2], "tinkerer", "then 7.5")
	assert_eq(ids[5], "enemy_1", "the brute (initiative 4) goes last")


func test_holy_sword_breaks_after_exactly_one_hit() -> void:
	GameState.add_item("holy_sword")
	assert_true(GameState.equip_weapon("holy_sword"), "equip")
	var state := _state("raiders_camp")
	var brute := state.fighter("enemy_1")
	state.perform(CombatAction.attack("player", "enemy_1"))
	assert_eq(brute.hp, 44 - (15 + 1), "first hit: sword power 15 + str 3 / 2")
	assert_true(_types(state).has("weapon_broke"), "it breaks")
	assert_eq(state.player().weapon_id, "fists", "back to fists (the doctor has no other weapon)")
	state.perform(CombatAction.attack("player", "enemy_1"))
	assert_eq(brute.hp, 28 - 3, "second hit is a normal punch")
	var result := CombatSetup.apply_result(state)
	assert_eq(GameState.get_flag("holy_sword_broken"), true, "flag set")
	assert_false(GameState.has_item("holy_sword"), "sword gone from the inventory")
	assert_eq(GameState.player.weapon_id, "fists", "weapon written back")
	assert_eq(result.encounter_id, "raiders_camp", "result has the encounter")


func test_broken_weapon_falls_back_to_best_weapon() -> void:
	GameState.add_item("crowbar")
	GameState.add_item("holy_sword")
	GameState.equip_weapon("holy_sword")
	var state := _state("raiders_street")
	state.perform(CombatAction.attack("player", "enemy_1"))
	assert_eq(state.player().weapon_id, "crowbar", "picks the crowbar after the sword breaks")


func test_downed_then_revived_by_heal() -> void:
	var state := _state("raiders_street")
	var cook := state.fighter("cook")
	cook.hp = 1
	state.perform(CombatAction.attack("enemy_1", "cook"))
	assert_true(cook.downed, "cook is down")
	assert_eq(cook.downed_turns_left, 2, "countdown from rules.downed_turns")
	state.perform(CombatAction.skill("player", "first_aid", "cook"))
	assert_false(cook.downed, "first aid gets them up")
	assert_eq(cook.hp, 6 + 8, "first aid heals 6 + int")


func test_downed_dies_when_the_countdown_runs_out() -> void:
	var state := _state("raiders_street")
	var cook := state.fighter("cook")
	cook.hp = 1
	state.perform(CombatAction.attack("enemy_1", "cook"))
	var cook_turns := 0
	var guard := 0
	while not cook.dead and guard < 40:
		guard += 1
		var actor := state.next_turn()
		if state.current == cook:
			cook_turns += 1
		if actor != null:
			state.perform(CombatAction.make(CombatAction.Type.DEFEND, actor.id))
	assert_true(cook.dead, "cook died while nobody helped")
	assert_eq(cook_turns, 2, "after exactly downed_turns of their own turns")
	assert_eq(state.dead_companions(), ["cook"], "listed as dead")


func test_hit_while_downed_kills_and_result_reports_it() -> void:
	var state := _state("raiders_street")
	var cook := state.fighter("cook")
	cook.hp = 1
	state.perform(CombatAction.attack("enemy_1", "cook"))
	state.perform(CombatAction.attack("enemy_2", "cook"))
	assert_true(cook.dead, "hit while down = dead")
	assert_true(_types(state).has("died"), "died event")
	for enemy in state.enemies():
		enemy.defeated = true
	state.perform(CombatAction.make(CombatAction.Type.DEFEND, "player"))
	assert_eq(state.outcome, "win", "fight won")
	var result := CombatSetup.apply_result(state)
	assert_eq(result.died, ["cook"], "result.died")
	assert_false(GameState.is_alive("cook"), "permanent in GameState")
	assert_eq(GameState.companions.cook.death_reason, "combat:raiders_street", "reason")
	assert_true(GameState.has_item("canned_food"), "loot added on a win")


func test_rule_switch_turns_off_combat_death() -> void:
	var state := _state("raiders_street")
	state.rules = state.rules.duplicate()
	state.rules.companion_combat_death = false
	var cook := state.fighter("cook")
	cook.hp = 1
	state.perform(CombatAction.attack("enemy_1", "cook"))
	assert_true(_types(state).has("ko"), "knocked out instead of a countdown")
	state.perform(CombatAction.attack("enemy_2", "cook"))
	assert_false(cook.dead, "hitting a KO'd companion doesn't kill")


func test_protagonist_never_dies() -> void:
	var state := _state("raiders_street")
	var hero := state.player()
	hero.hp = 1
	state.perform(CombatAction.attack("enemy_1", "player"))
	state.perform(CombatAction.attack("enemy_2", "player"))
	assert_true(hero.downed and not hero.dead, "down, never dead")


func test_lose_leaves_game_state_untouched_for_retry() -> void:
	GameState.add_item("bandage", 3)
	var bandages := int(GameState.inventory.bandage)
	var state := _state("raiders_camp")
	state.perform(CombatAction.item("player", "bandage", "player"))
	for f in state.party():
		f.hp = 1
		state.perform(CombatAction.attack("enemy_1", f.id))
	state.perform(CombatAction.attack("enemy_1", "cook"))
	assert_eq(state.outcome, "lose", "everyone down")
	assert_true(GameState.is_alive("cook"), "nothing written yet: cook alive")
	assert_eq(int(GameState.inventory.bandage), bandages, "no bandage used up")
	var retry := _state("raiders_camp")
	assert_eq(retry.fighter("cook").hp, GameState.companions.cook.hp, "retry starts from the same state")


func test_talking_succeeds_and_fails() -> void:
	var state := _state("raiders_street")
	var approach: Dictionary = Data.all("talk").persuade
	assert_eq(CombatRules.talk_chance(state.player(), "persuade", approach, state.enemies(), state.rules), 25 + 8 * 3 * 2, "doctor persuade")
	state.forced_rolls = [false]
	state.perform(CombatAction.talk("player", "persuade"))
	assert_eq(state.outcome, "", "failed: still fighting")
	state.forced_rolls = [true]
	state.perform(CombatAction.talk("player", "treat_wound"))
	assert_eq(state.outcome, "talk", "succeeded")
	assert_eq(state.moral_delta, 5 + 2, "treat_wound moral + talk_win_moral")


func test_ceasefire_form_always_fails() -> void:
	GameState.new_game("civil_servant")
	var state := _state("raiders_street")
	state.forced_rolls = [true, true, true]
	state.perform(CombatAction.talk("player", "ceasefire_form"))
	assert_eq(state.outcome, "", "never works, even with luck")
	var lines := state.take_events().map(func(e: Dictionary) -> String: return CombatText.line(e, state, state.rng))
	assert_true("".join(lines).contains("[TEMP]"), "but it logs its own line")


func test_brute_resolve_lowers_the_chance() -> void:
	var state := _state("raiders_camp")
	var approach: Dictionary = Data.all("talk").persuade
	assert_eq(CombatRules.talk_chance(state.player(), "persuade", approach, state.enemies(), state.rules), 73 - 25, "brute resolve 25")


func test_fleeing() -> void:
	var state := _state("raiders_street")
	state.forced_rolls = [false]
	state.perform(CombatAction.make(CombatAction.Type.FLEE, "player"))
	assert_eq(state.outcome, "", "failed flight")
	state.forced_rolls = [true]
	state.perform(CombatAction.make(CombatAction.Type.FLEE, "player"))
	assert_eq(state.outcome, "flee", "got away")
	var aliens := _state("alien_swarm_zone")
	aliens.forced_rolls = [true]
	aliens.perform(CombatAction.make(CombatAction.Type.FLEE, "player"))
	assert_eq(aliens.outcome, "", "never against aliens")
	assert_true(_types(aliens).has("flee_alien"), "\"Wohin denn?\"")


func test_aliens_take_no_damage_and_sweep_every_second_turn() -> void:
	var state := _state("alien_swarm_zone")
	var swarm := state.fighter("enemy_1")
	state.perform(CombatAction.attack("player", "enemy_1"))
	assert_eq(swarm.hp, swarm.max_hp, "0 damage")
	assert_true(_types(state).has("alien_ignores"), "indifference line")
	swarm.turns_taken = 1
	assert_eq(EnemyAI.choose(state, swarm).type, CombatAction.Type.WAIT, "1st turn: ignores you")
	swarm.turns_taken = 2
	var sweep := EnemyAI.choose(state, swarm)
	state.perform(sweep)
	assert_eq(state.fighter("cook").hp, state.fighter("cook").max_hp - 12, "2nd turn: hits everyone for 12")


func test_alien_fight_brings_the_whole_roster() -> void:
	GameState.party.erase("tinkerer")
	var state := _state("alien_swarm_zone")
	assert_true(state.fighter("tinkerer") != null, "party: all brings the tinkerer even when not in the active party")


func test_cheat_by_signal_skill() -> void:
	var state := _state("alien_swarm_zone")
	state.perform(CombatAction.skill("tinkerer", "send_signal"))
	assert_eq(state.outcome, "cheat", "tinkerer's signal wins")


func test_cheat_by_jammer_item() -> void:
	GameState.add_item("jammer")
	GameState.kill_companion("tinkerer", "story:test")
	var state := _state("alien_swarm_zone")
	assert_true(state.usable_items().has("jammer"), "jammer usable")
	state.perform(CombatAction.item("player", "jammer"))
	assert_eq(state.outcome, "cheat", "jammer wins")
	CombatSetup.apply_result(state)
	assert_true(GameState.has_item("jammer"), "key item is not used up")


func test_cheat_by_code() -> void:
	var listener := CheatListener.new(Data.encounter("alien_swarm_zone").cheats)
	var found := ""
	for input in ["left", "up", "up", "down", "down", "left", "right", "left", "right"]:
		found = listener.feed(input)
	assert_eq(found, "konami", "code recognized, even after a stray press")
	var state := _state("alien_swarm_zone")
	state.perform(CombatAction.cheat_code("player", found))
	assert_eq(state.outcome, "cheat", "code wins")


func test_code_only_works_where_listed() -> void:
	var listener := CheatListener.new(Data.encounter("raiders_street").get("cheats", []))
	var found := ""
	for input in Data.cheat("konami").sequence:
		found = listener.feed(input)
	assert_eq(found, "", "raiders_street lists no cheats")


func test_signal_does_nothing_against_humans() -> void:
	var state := _state("raiders_street")
	assert_eq(state.skill_block_reason(state.fighter("tinkerer"), "send_signal"), "COMBAT_ONLY_ALIENS", "blocked in the menu")


func test_civil_servant_skill_does_nothing() -> void:
	GameState.new_game("civil_servant")
	var state := _state("raiders_street")
	var before := state.enemies().map(func(e: Combatant) -> int: return e.hp)
	state.perform(CombatAction.skill("player", "file_form"))
	var events := state.take_events()
	assert_eq(events[0].type, "file_form", "its own event")
	assert_true(CombatText.line(events[0], state, state.rng).contains("6–8"), "logs the line")
	assert_eq(state.enemies().map(func(e: Combatant) -> int: return e.hp), before, "nothing happened")


func test_skill_cooldown() -> void:
	var state := _state("raiders_street")
	state.perform(CombatAction.skill("player", "first_aid", "cook"))
	assert_eq(state.skill_block_reason(state.player(), "first_aid"), "COMBAT_COOLDOWN", "blocked right after")


func test_brute_announces_its_target() -> void:
	var state := CombatSetup.from_game("raiders_camp")
	state.start()
	var intents := state.take_events().filter(func(e: Dictionary) -> bool: return e.type == "intent")
	assert_eq(intents.size(), 1, "brute announces one target at the start")
	assert_eq(state.fighter("enemy_1").intent_target, intents[0].target, "and remembers it")


func test_all_log_lines_exist_in_both_languages() -> void:
	var state := _state("raiders_camp")
	for locale in ["de", "en"]:
		TranslationServer.set_locale(locale)
		for type in Data.all("combat_text").log:
			var line := CombatText.line({type = type, actor = "player", target = "enemy_1", amount = 3, turns = 1,
				item = "bandage", weapon = "holy_sword", approach = "persuade"}, state, state.rng)
			assert_false(line.contains("{"), "%s/%s has an unknown placeholder: %s" % [locale, type, line])
			assert_false(line.begins_with("[EN?]"), "%s/%s missing English" % [locale, type])
	TranslationServer.set_locale("de")
