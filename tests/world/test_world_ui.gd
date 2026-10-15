extends TestCase

func before_each() -> void:
	GameState.new_game("doctor")

func test_healing_consumes_once_and_applies_job_bonus() -> void:
	GameState.player.hp = 1
	var amount: int = GameState.inventory.bandage
	assert_true(WorldUI.use_healing("bandage", "player"))
	assert_eq(GameState.player.hp, 16)
	assert_eq(GameState.inventory.bandage, amount - 1)

func test_healing_never_revives_dead_companion_or_wastes_full_health_item() -> void:
	GameState.recruit("cook")
	GameState.kill_companion("cook", "story:test")
	var before: Dictionary = GameState.inventory.duplicate()
	assert_false(WorldUI.use_healing("bandage", "cook"))
	assert_false(WorldUI.use_healing("bandage", "player"))
	assert_eq(GameState.inventory, before)
	assert_false(GameState.is_alive("cook"))

func test_interaction_conditions_hide_unavailable_content() -> void:
	var object := WorldInteractable.new()
	object.required_flag = "h2_test_flag"
	assert_false(object.available())
	GameState.set_flag("h2_test_flag")
	assert_true(object.available())
	object.required_moral = "high"
	assert_false(object.available())
	GameState.add_moral(50)
	assert_true(object.available())
	object.hidden_if_flag = "h2_test_flag"
	assert_false(object.available())
	object.free()

func test_pickup_is_permanent_and_one_shot() -> void:
	var object := WorldInteractable.new()
	object.interaction = "Pickup"
	object.once_flag = "h2_test_pickup"
	object.item_id = "scrap"
	object.count = 2
	object.activate()
	object.activate()
	assert_eq(GameState.inventory.scrap, 2)
	var saved := GameState.to_dict()
	GameState.reset()
	GameState.from_dict(saved)
	assert_false(object.available())
	object.free()

func test_ui_translations_and_font_cover_both_languages() -> void:
	var font := load("res://assets/fonts/pixelify_sans.ttf") as Font
	for character in "äöüÄÖÜß":
		assert_true(font.has_char(character.unicode_at(0)), "Font missing " + character)
	var file := FileAccess.open("res://localization/ui.csv", FileAccess.READ)
	file.get_csv_line()
	while not file.eof_reached():
		var row := file.get_csv_line()
		if row.size() < 3:
			continue
		assert_true(not row[1].is_empty() and not row[2].is_empty(), row[0])
		for locale in ["de", "en"]:
			TranslationServer.set_locale(locale)
			assert_true(TranslationServer.translate(row[0]) != row[0], "Missing " + locale + ": " + row[0])
	TranslationServer.set_locale("de")
