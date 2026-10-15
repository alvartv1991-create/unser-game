extends Node
## Repeatable runtime/visual QA. -- --capture writes viewport PNGs to builds/h2_qa.
var capture: bool = false
var failures: Array[String] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	capture = OS.get_cmdline_user_args().has("--capture")
	_run.call_deferred()

func check(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
		push_error(message)

func frames(count: int = 4) -> void:
	for i in count:
		await get_tree().process_frame

func shot(id: String) -> void:
	await frames()
	if capture:
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute("res://builds/h2_qa")
		get_viewport().get_texture().get_image().save_png("res://builds/h2_qa/%s.png" % id)

func _run() -> void:
	# Survive scene changes without affecting normal gameplay.
	get_parent().remove_child(self)
	get_tree_safe_attach.call_deferred()

func get_tree_safe_attach() -> void:
	(Engine.get_main_loop() as SceneTree).root.add_child(self)
	await frames()
	var overlay := get_tree().get_first_node_in_group("global_ui") as WorldUI
	check(overlay != null, "Persistent overlay missing")
	var original_settings := overlay.settings.encode_to_text()
	for locale in ["de", "en"]:
		TranslationServer.set_locale(locale)
		EventBus.locale_changed.emit(locale)
		await SceneRouter.go_to("res://scenes/ui/title.tscn")
		await frames()
		var title_node := get_tree().current_scene
		title_node.page = "language"
		title_node.rebuild()
		await shot(locale + "_language")
		title_node.page = "title"
		title_node.rebuild()
		await shot(locale + "_title")
		title_node.page = "jobs"
		title_node.rebuild()
		title_node.select_job("civil_servant")
		await shot(locale + "_jobs")
		GameState.new_game("doctor")
		GameState.recruit("cook")
		GameState.recruit("tinkerer")
		await SceneRouter.go_to("res://scenes/levels/test_platforming.tscn", "start")
		await get_tree().create_timer(0.15).timeout
		var player := get_tree().get_first_node_in_group("player") as WorldPlayer
		check(player != null, "Player missing")
		check(player.followers.size() == 2, "Followers not created")
		await shot(locale + "_world")
		var start_x := player.position.x
		Input.action_press("move_right")
		await get_tree().create_timer(0.3).timeout
		Input.action_release("move_right")
		check(player.position.x > start_x + 10, "Player does not run")
		Input.action_press("jump")
		await get_tree().create_timer(0.1).timeout
		Input.action_release("jump")
		check(player.position.y < 290, "Player does not jump")
		await get_tree().create_timer(0.6).timeout
		# Land on a one-way platform and explicitly drop through it.
		player.position = Vector2(700, 240)
		player.velocity = Vector2.ZERO
		await get_tree().create_timer(0.4).timeout
		check(absf(player.position.y - 272) < 2, "One-way platform does not support player")
		Input.action_press("move_down")
		Input.action_press("jump")
		await get_tree().create_timer(0.12).timeout
		Input.action_release("jump")
		Input.action_release("move_down")
		await get_tree().create_timer(0.4).timeout
		check(player.position.y > 290, "Cannot drop through one-way platform")
		player.position = Vector2(80, 304)
		for menu_page in ["pause", "options", "inventory", "party"]:
			overlay.open_menu(menu_page)
			var stopped := player.position
			Input.action_press("move_right")
			await frames(8)
			Input.action_release("move_right")
			check(player.position == stopped, "Movement during menu")
			await shot(locale + "_" + menu_page)
			overlay.close_menu()
		GameState.kill_companion("cook", "combat:raiders_street")
		check(player.followers.size() == 1, "Dead follower remains")
		overlay.open_menu("party")
		await shot(locale + "_memory")
		overlay.close_menu()
		var pickup := get_tree().current_scene.get_node("Pickup") as WorldInteractable
		var bandages: int = GameState.inventory.get("bandage", 0)
		pickup.activate()
		pickup.activate()
		check(GameState.inventory.bandage == bandages + 1, "Pickup fired more than once")
		var campfire := get_tree().current_scene.get_node("Campfire") as WorldInteractable
		GameState.player.hp = 1
		campfire.activate()
		check(GameState.player.hp == GameState.player.max_hp, "Campfire did not rest")
		var talk := get_tree().current_scene.get_node("Talk") as WorldInteractable
		talk.activate()
		await frames()
		check(DialogueRunner.is_running(), "Talk did not start dialogue")
		var dialogue_x := player.position.x
		Input.action_press("move_right")
		await get_tree().create_timer(0.15).timeout
		Input.action_release("move_right")
		check(absf(player.position.x - dialogue_x) < 1, "Player moves during dialogue")
		if is_instance_valid(DialogueRunner.balloon):
			DialogueRunner.balloon.queue_free()
		await frames()
		var encounter := get_tree().current_scene.get_node("Encounter") as WorldInteractable
		encounter.activate()
		await frames()
		check(SceneRouter.is_in_combat(), "Encounter did not start")
		check(not overlay.hud.visible, "HUD visible in combat")
		EventBus.combat_finished.emit({"encounter_id": "raiders_street", "outcome": "win", "loot": {}, "died": []})
		await frames()
		check(not SceneRouter.is_in_combat(), "Combat did not return to level")
		await SceneRouter.go_to("res://scenes/levels/test_side_room.tscn", "start")
		await shot(locale + "_room")
		await SceneRouter.go_to("res://scenes/levels/test_platforming.tscn", "from_room")
		player = get_tree().get_first_node_in_group("player") as WorldPlayer
		check(absf(player.position.x - 580) < 1, "Return spawn is wrong")
		check(get_tree().get_nodes_in_group("global_ui").size() == 1, "Overlay duplicated")
	# This test does not save language or settings.
	check(overlay.settings.encode_to_text() == original_settings, "QA changed settings")
	print("H2 flow: %d failures" % failures.size())
	get_tree().quit(0 if failures.is_empty() else 1)
