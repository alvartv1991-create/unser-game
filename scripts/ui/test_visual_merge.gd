extends Node
## Verifies and optionally renders the integrated character/street/combat graphics.
var errors: Array[String] = []
var capture: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	capture = OS.get_cmdline_user_args().has("--capture")
	get_parent().remove_child.call_deferred(self)
	(Engine.get_main_loop() as SceneTree).root.add_child.call_deferred(self)
	run_checks.call_deferred()

func check(ok: bool, message: String) -> void:
	if not ok:
		errors.append(message)
		push_error(message)

func screenshot(id: String) -> void:
	await get_tree().process_frame
	if capture:
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute("res://builds/merged_art")
		get_viewport().get_texture().get_image().save_png("res://builds/merged_art/%s.png" % id)

func run_checks() -> void:
	await get_tree().process_frame
	for id in ["player", "cook", "tinkerer", "clerk", "cultist", "raider_scavenger", "raider_brute"]:
		var frames := load("res://assets/sprites/characters/%s.tres" % id) as SpriteFrames
		check(frames != null, "Missing sprite: " + id)
		if frames:
			for anim in ["idle", "walk", "jump", "fall", "combat_idle", "attack", "skill", "hurt", "downed"]:
				check(frames.has_animation(anim) and frames.get_frame_count(anim) > 0, id + ": missing " + anim)
		check(ResourceLoader.exists("res://assets/portraits/%s.png" % id), "Missing portrait: " + id)
	for locale in ["de", "en"]:
		TranslationServer.set_locale(locale)
		EventBus.locale_changed.emit(locale)
		await SceneRouter.go_to("res://scenes/ui/test_art_gallery.tscn")
		await screenshot(locale + "_gallery")
		await SceneRouter.go_to("res://scenes/levels/test_visual_street.tscn", "start")
		await screenshot(locale + "_street")
		for encounter in ["raiders_street", "raiders_camp", "alien_swarm_zone"]:
			GameState.new_game("police")
			GameState.recruit("cook")
			GameState.recruit("tinkerer")
			SceneRouter.start_combat(encounter)
			var screen: CombatScreen = null
			for child in get_tree().root.get_children():
				if child is CombatScreen:
					screen = child
			check(screen != null, "Combat screen did not open")
			if screen == null:
				continue
			screen.speed = 0.0
			var count := 0
			while screen._asking == null and count < 120:
				count += 1
				await get_tree().process_frame
			await screenshot(locale + "_" + encounter)
			screen.autopilot = true
			if screen._asking:
				screen._choose(CombatAutoPilot.choose(screen.state, screen._asking))
			count = 0
			while SceneRouter.is_in_combat() and count < 600:
				count += 1
				await get_tree().process_frame
			check(not SceneRouter.is_in_combat(), "Combat did not finish: " + encounter)
			if SceneRouter.is_in_combat():
				await SceneRouter.go_to("res://scenes/levels/test_visual_street.tscn", "start")
	print("Merged visual QA: %d failures" % errors.size())
	get_tree().quit(0 if errors.is_empty() else 1)
