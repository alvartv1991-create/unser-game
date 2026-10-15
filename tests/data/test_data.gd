extends TestCase


func test_all_data_files_load_without_errors() -> void:
	assert_eq(Data.errors.size(), 0, "data/ errors: " + "; ".join(Data.errors))
	for kind in Data.TABLES:
		if kind != "barks" and kind != "speakers":
			assert_false(Data.all(kind).is_empty(), kind + ".json is empty")


func test_alpha_ids_exist() -> void:
	for job_id in ["doctor", "craftsman", "police", "scientist", "civil_servant"]:
		assert_true(Data.has("jobs", job_id), "job " + job_id)
	for encounter_id in ["raiders_street", "raiders_camp", "alien_swarm_zone"]:
		assert_true(Data.has("encounters", encounter_id), "encounter " + encounter_id)
	assert_eq(Data.encounter("alien_swarm_zone").party, "all", "the alien fight brings everyone")
	assert_true(Data.has("cheats", "konami"), "cheat konami")


func test_text_picks_locale_with_fallback() -> void:
	var old_locale := TranslationServer.get_locale()
	TranslationServer.set_locale("en")
	assert_eq(Data.text({"de": "Hallo", "en": "Hello"}), "Hello", "english")
	assert_eq(Data.text({"de": "Nur Deutsch"}), "[EN?] Nur Deutsch", "missing english is marked")
	TranslationServer.set_locale("de")
	assert_eq(Data.text({"de": "Hallo", "en": "Hello"}), "Hallo", "german")
	assert_eq(Data.text("plain"), "plain", "plain strings pass through")
	assert_eq(Data.text(null), "[?]", "never empty")
	TranslationServer.set_locale(old_locale)


func test_validation_catches_mistakes() -> void:
	var tables := {
		"jobs": {"broken": {"name": {"de": "Kaputt"}, "description": {"de": "x", "en": "x"},
			"stats": {"int": 11, "str": 2, "end": 2}, "skill": "does_not_exist"}},
		"skills": {}, "items": {}, "companions": {}, "enemies": {}, "cheats": {}, "audio": {},
		"encounters": {"empty": {"enemies": [], "party": "everyone"}},
	}
	var found := Data.validate(tables, {}, {})
	var all_text := "\n".join(found)
	assert_true(all_text.contains("missing \"en\" text"), "missing english found")
	assert_true(all_text.contains("between 1 and 10"), "stat range found")
	assert_true(all_text.contains("missing number \"kno\""), "missing stat found")
	assert_true(all_text.contains("unknown id \"does_not_exist\""), "bad reference found")
	assert_true(all_text.contains("needs at least one enemy"), "empty encounter found")
	assert_true(all_text.contains("\"active\" or \"all\""), "bad party mode found")
	assert_true(all_text.contains("rules.json: missing"), "missing rules found")
