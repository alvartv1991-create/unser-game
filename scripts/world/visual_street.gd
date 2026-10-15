extends Node2D
## A playable art-direction sample, not the story's opening sequence.
const WORLD_SIZE := Vector2i(1280, 360)
const FLOOR_Y := 286.0
var sky: Sprite2D
var distant: Sprite2D
var player: WorldPlayer
var weather: Node2D
var time: float = 0.0
var reduced_effects: bool = false
var rain: Array[Vector2] = []
var preview_layer: CanvasLayer

func _ready() -> void:
	if GameState.player.is_empty():
		GameState.new_game("doctor")
	RenderingServer.set_default_clear_color(Color("1c2238"))
	sky = layer("sky", -30)
	distant = layer("distance", -20)
	layer("world", -10)
	layer("foreground", 30)
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	add_child(body)
	add_collider(body, Rect2(0, FLOOR_Y, WORLD_SIZE.x, 74))
	add_collider(body, Rect2(-16, -80, 16, 440))
	add_collider(body, Rect2(WORLD_SIZE.x, -80, 16, 440))
	var spawn := preload("res://scenes/world/spawn_point.tscn").instantiate()
	spawn.position = Vector2(195, FLOOR_Y)
	add_child(spawn)
	player = preload("res://scenes/world/player.tscn").instantiate() as WorldPlayer
	player.position = spawn.position
	player.camera_bounds = Rect2i(Vector2i.ZERO, WORLD_SIZE)
	player.z_index = 10
	add_child(player)
	# Clear silhouettes and feet: no collision is attached to background props.
	player.camera.reset_smoothing()
	neon_sign(Vector2(48, 152), Vector2(298, 26), "UI_STREET_ARCADE", 22, Color("ff4fd8"), Color("8a1a7a"))
	neon_sign(Vector2(548, 168), Vector2(208, 24), "UI_STREET_CAFE", 20, Color("e0a94a"), Color("8e3b2b"))
	neon_sign(Vector2(60, 206), Vector2(49, 16), "UI_STREET_OPEN", 10, Color("d68a8a"), Color("3d2440"))
	# Steady shop/street lighting, separate from the alien/glitch event system.
	light_pool(Vector2(195, 169), Vector2i(384, 144), Color("ff4fd8"), 0.12)
	light_pool(Vector2(192, 222), Vector2i(320, 112), Color("127a8a"), 0.11)
	light_pool(Vector2(648, 219), Vector2i(272, 152), Color("e0a94a"), 0.1)
	for x in [430, 784, 1170]:
		light_pool(Vector2(x, 222), Vector2i(96, 160), Color("e0a94a"), 0.08)
	weather = Node2D.new()
	weather.z_index = 20
	weather.draw.connect(draw_weather)
	add_child(weather)
	var random := RandomNumberGenerator.new()
	random.seed = 1984
	for i in 100:
		rain.append(Vector2(random.randf_range(0, 1280), random.randf_range(0, 360)))
	build_preview_caption()
	EventBus.locale_changed.connect(refresh_caption)
	# QA is opt-in and leaves user settings/save files untouched.
	if OS.get_cmdline_user_args().has("--visual-qa"):
		run_visual_qa.call_deferred()

func layer(suffix: String, depth: int) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = load("res://assets/backgrounds/street_%s.png" % suffix)
	sprite.centered = false
	sprite.z_index = depth
	add_child(sprite)
	return sprite

func add_collider(parent: Node, bounds: Rect2) -> void:
	var shape := RectangleShape2D.new()
	shape.size = bounds.size
	var collision := CollisionShape2D.new()
	collision.position = bounds.position + bounds.size / 2
	collision.shape = shape
	parent.add_child(collision)

func light_pool(at: Vector2, bounds: Vector2i, tint: Color, energy: float) -> void:
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([Color(1, 1, 1, energy), Color(1, 1, 1, 0)])
	var texture := GradientTexture2D.new()
	texture.width = bounds.x
	texture.height = bounds.y
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1, 0.5)
	texture.gradient = gradient
	var glow := Sprite2D.new()
	glow.position = at
	glow.texture = texture
	glow.modulate = tint
	glow.z_index = -6
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	glow.material = additive
	add_child(glow)

func neon_sign(at: Vector2, bounds: Vector2, key: String, font_size: int, color: Color, shadow: Color) -> void:
	var caption := Label.new()
	caption.position = at
	caption.size = bounds
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption.text = tr(key)
	caption.add_theme_font_size_override("font_size", font_size)
	caption.add_theme_color_override("font_color", color)
	caption.add_theme_color_override("font_outline_color", shadow)
	caption.add_theme_constant_override("outline_size", 3)
	caption.z_index = -5
	add_child(caption)
	EventBus.locale_changed.connect(func(_locale: String) -> void: caption.text = tr(key))

func build_preview_caption() -> void:
	preview_layer = CanvasLayer.new()
	preview_layer.layer = 8
	add_child(preview_layer)
	var panel := PanelContainer.new()
	panel.name = "Caption"
	panel.position = Vector2(12, 310)
	panel.custom_minimum_size = Vector2(388, 36)
	preview_layer.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 0)
	panel.add_child(column)
	var caption := UiKit.label(tr("UI_VISUAL_PREVIEW"), column)
	caption.name = "Heading"
	caption.add_theme_font_size_override("font_size", 12)
	var controls := UiKit.label(tr("UI_STREET_CONTROLS"), column)
	controls.name = "Controls"
	controls.add_theme_font_size_override("font_size", 11)

func refresh_caption(_locale: String) -> void:
	var column := preview_layer.get_node("Caption").get_child(0)
	column.get_node("Heading").text = tr("UI_VISUAL_PREVIEW")
	column.get_node("Controls").text = tr("UI_STREET_CONTROLS")

func _process(delta: float) -> void:
	time += delta
	var offset := maxf(0, player.camera.get_screen_center_position().x - 320)
	sky.position.x = floorf(offset * 0.82)
	distant.position.x = floorf(offset * 0.38)
	var overlay := get_tree().get_first_node_in_group("global_ui") as WorldUI
	reduced_effects = overlay != null and bool(overlay.settings.get_value("display", "reduce_effects", false))
	preview_layer.visible = overlay == null or overlay.page == ""
	weather.queue_redraw()
	queue_redraw()

func _draw() -> void:
	if not is_instance_valid(player):
		return
	var feet := Vector2(player.position.x, FLOOR_Y + 1).round()
	draw_line(feet + Vector2(-9, 0), feet + Vector2(10, 0), Color("14101a"), 2)

func draw_weather() -> void:
	if reduced_effects:
		return
	for i in rain.size():
		var at := rain[i]
		at.y = fposmod(at.y + time * 95, 358)
		at.x = fposmod(at.x - time * 16, 1280)
		if at.y < 276:
			weather.draw_line(at.round(), (at + Vector2(-1, 4)).round(), Color(0.36, 0.48, 0.60, 0.26), 1)
	# A few small puddle ripples, never camera-wide flashes or screen tearing.
	for i in 14:
		var phase := fposmod(time * 0.6 + i * 0.13, 1.0)
		if phase < 0.55:
			var center := Vector2(45 + i * 87, 303 + (i * 17) % 42)
			weather.draw_line(center - Vector2(phase * 6, 0), center + Vector2(phase * 6, 0), Color(0.36, 0.48, 0.60, 0.4), 1)

func run_visual_qa() -> void:
	var failed := false
	var glitch_events := [0]
	var record_glitch := func(_intensity: float, _duration: float) -> void: glitch_events[0] += 1
	EventBus.device_glitch.connect(record_glitch)
	await get_tree().create_timer(0.2).timeout
	var positions := [190.0, 625.0, 1080.0]
	var capture := OS.get_cmdline_user_args().has("--capture")
	for locale in ["de", "en"]:
		TranslationServer.set_locale(locale)
		EventBus.locale_changed.emit(locale)
		for i in positions.size():
			player.position = Vector2(positions[i], FLOOR_Y)
			player.camera.reset_smoothing()
			await get_tree().create_timer(0.2).timeout
			if absf(player.position.y - FLOOR_Y) > 1:
				failed = true
				push_error("Visual street floor alignment is wrong")
			if capture:
				await RenderingServer.frame_post_draw
				DirAccess.make_dir_recursive_absolute("res://builds/visual_street")
				get_viewport().get_texture().get_image().save_png("res://builds/visual_street/%s_%d.png" % [locale, i])
		var start := player.position.x
		Input.action_press("move_left")
		await get_tree().create_timer(0.3).timeout
		Input.action_release("move_left")
		if player.position.x >= start - 10:
			failed = true
			push_error("Visual street player cannot move")
		Input.action_press("jump")
		await get_tree().create_timer(0.1).timeout
		Input.action_release("jump")
		if player.position.y >= FLOOR_Y - 10:
			failed = true
			push_error("Visual street player cannot jump")
		await get_tree().create_timer(0.7).timeout
	if glitch_events[0] != 0:
		failed = true
		push_error("Ordinary opening visual sample emitted alien interference")
	EventBus.device_glitch.disconnect(record_glitch)
	print("Visual street QA: ", "FAIL" if failed else "PASS")
	get_tree().quit(1 if failed else 0)
