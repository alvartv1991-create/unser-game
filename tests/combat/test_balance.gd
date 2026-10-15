extends TestCase
## Plays many fights with the autopilot and checks the win rates (H1 "Done when": every job
## can win raiders_street). Prints the numbers so balancing changes are visible.

const RUNS := 60


func _win_rate(job_id: String, companions: Array, encounter_id: String) -> float:
	var wins := 0
	for i in RUNS:
		GameState.new_game(job_id)
		for companion_id in companions:
			GameState.recruit(companion_id)
		var rng := RandomNumberGenerator.new()
		rng.seed = 1000 + i
		var outcome := CombatAutoPilot.simulate(CombatSetup.from_game(encounter_id, rng))
		if outcome == "win":
			wins += 1
	return wins / float(RUNS)


func test_every_job_can_win_the_street_fight() -> void:
	var report := PackedStringArray()
	for job_id in Data.all("jobs"):
		var with_cook := _win_rate(job_id, ["cook"], "raiders_street")
		var alone := _win_rate(job_id, [], "raiders_street")
		report.append("%s: %d%% with cook, %d%% alone" % [job_id, with_cook * 100, alone * 100])
		assert_true(with_cook >= 0.8, "%s + cook should usually win raiders_street (%d%%)" % [job_id, with_cook * 100])
	print("    raiders_street: " + " · ".join(report))


func test_camp_fight_is_hard_but_winnable() -> void:
	var report := PackedStringArray()
	for job_id in Data.all("jobs"):
		var rate := _win_rate(job_id, ["cook", "tinkerer"], "raiders_camp")
		report.append("%s %d%%" % [job_id, rate * 100])
		assert_true(rate >= 0.3, "%s + both companions should have a real chance at raiders_camp (%d%%)" % [job_id, rate * 100])
	print("    raiders_camp (full party): " + " · ".join(report))


func test_alien_fight_needs_a_cheat() -> void:
	GameState.new_game("craftsman")
	GameState.recruit("cook")
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	assert_eq(CombatAutoPilot.simulate(CombatSetup.from_game("alien_swarm_zone", rng)), "lose", "no tinkerer, no jammer: hopeless")
	GameState.recruit("tinkerer")
	assert_eq(CombatAutoPilot.simulate(CombatSetup.from_game("alien_swarm_zone", rng)), "cheat", "with the tinkerer: cheat")
