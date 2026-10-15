class_name AreaLevel
extends Node2D
## Shared builder for the Area 1 story levels (scenes/levels/area1_*.tscn).
## A level script extends this and fills build(): set dressing (painted pixel rectangles in palette
## colors plus the existing street art), floors and platforms, spawn points, interactables wired to
## dialogue, NPC sprites and blockers that open when a story flag is set.
## Also shows companion barks above the followers and a short screen flicker on device glitches.
## Built by Claude on the humans' request ("implement the test things into the game"); see
## docs/handoff/area1_playable.md. Environment art is placeholder until Codex's H4 art pass.

const FLOOR_Y := 286.0
const BARK_SECONDS := 3.0

## Palette (docs/ART_GUIDE.md).
const C := {
	"outline": "14101a", "charcoal": "2b2532", "slate": "4a4552", "concrete": "77727a", "ash": "a8a3a6",
	"bone": "e3dccb", "dark_brown": "3b2a24", "brown": "63452f", "tan": "9a6e47", "sand": "c9a26b",
	"dark_rust": "5a2a22", "rust": "8e3b2b", "orange": "c2622f", "yellow": "e0a94a", "dark_olive": "2f3a26",
	"olive": "4f5e33", "moss": "7b8a48", "pale_green": "b4bb7c", "night": "1c2238", "denim": "344a6b",
	"faded_blue": "5d7a99", "pale_sky": "9db4c4", "plum": "3d2440", "red": "b04a5a", "pink": "d68a8a",
	"cyan_dark": "127a8a", "cyan": "3ff0f0", "magenta_dark": "8a1a7a", "magenta": "ff4fd8",
}

var world_width := 1280
var music_id := "music_area1"
var ambience_id := "amb_wind"
var player: WorldPlayer
var back: Painter        # behind characters
var front: Painter       # in front of characters (foreground silhouettes)
var _parallax: Array = []        # [Sprite2D, factor]
var _blockers: Array = []        # [StaticBody2D, CollisionShape2D, flag, Node2D visual]
var _flagged: Array = []         # [CanvasItem, required_flag, hidden_if_flag]
var _barks: Dictionary = {}      # speaker id -> Label
var _flicker: ColorRect
var _flicker_time := 0.0
var _flicker_strength := 0.0


## Draws a list of colored rectangles once; cheap and pixel-exact.
class Painter extends Node2D:
	var shapes: Array = []   # [Rect2, Color]
	func _draw() -> void:
		for shape: Array in shapes:
			draw_rect(shape[0], shape[1])


func _ready() -> void:
	if GameState.player.is_empty():
		GameState.new_game("doctor")
	RenderingServer.set_default_clear_color(Color(C.night))
	back = Painter.new()
	back.z_index = -8
	add_child(back)
	front = Painter.new()
	front.z_index = 30
	add_child(front)
	build()
	back.queue_redraw()
	front.queue_redraw()
	_add_player()
	_build_flicker()
	EventBus.bark_requested.connect(_on_bark)
	EventBus.device_glitch.connect(_on_glitch)
	AudioManager.play_music(music_id)
	AudioManager.play_ambience(ambience_id)
	_after_scene_change()


func _after_scene_change() -> void:
	await get_tree().process_frame
	while SceneRouter.is_changing_scene():
		await get_tree().process_frame
	after_build()


## Override: build the level.
func build() -> void:
	pass


## Override: runs once the level and the player are in place (e.g. start the intro).
func after_build() -> void:
	pass


# --- Set dressing -------------------------------------------------------------

func color(name: String, alpha := 1.0) -> Color:
	var c := Color(str(C.get(name, name)))
	c.a = alpha
	return c


func rect(bounds: Rect2, color_name: String, painter: Painter = null, alpha := 1.0) -> void:
	(painter if painter else back).shapes.append([bounds, color(color_name, alpha)])


## A street-art layer (assets/backgrounds/street_<suffix>.png), repeated across the level.
func parallax_layer(suffix: String, factor: float, depth: int, repeat := true) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = load("res://assets/backgrounds/street_%s.png" % suffix)
	sprite.centered = false
	sprite.z_index = depth
	if repeat:
		sprite.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		sprite.region_enabled = true
		sprite.region_rect = Rect2(0, 0, world_width, 360)
	add_child(sprite)
	if factor > 0.0:
		_parallax.append([sprite, factor])
	return sprite


func sprite_at(path: String, at: Vector2, depth := -4, flip := false) -> Sprite2D:
	var sprite := Sprite2D.new()
	if ResourceLoader.exists(path):
		sprite.texture = load(path)
	sprite.position = at
	sprite.z_index = depth
	sprite.flip_h = flip
	add_child(sprite)
	return sprite


## A localized sign. The key lives in localization/story.csv or ui.csv.
func sign_text(at: Vector2, key: String, size: int, tint: String, shadow: String = "outline", depth := -5) -> Label:
	var label := Label.new()
	label.position = at
	label.text = tr(key)
	label.z_index = depth
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color(tint))
	label.add_theme_color_override("font_outline_color", color(shadow))
	label.add_theme_constant_override("outline_size", 3)
	add_child(label)
	EventBus.locale_changed.connect(func(_l: String) -> void: label.text = tr(key))
	return label


func light(at: Vector2, size: Vector2i, tint: String, energy: float) -> Sprite2D:
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([Color(1, 1, 1, energy), Color(1, 1, 1, 0)])
	var texture := GradientTexture2D.new()
	texture.width = size.x
	texture.height = size.y
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1, 0.5)
	texture.gradient = gradient
	var glow := Sprite2D.new()
	glow.position = at
	glow.texture = texture
	glow.modulate = color(tint)
	glow.z_index = -6
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	glow.material = additive
	add_child(glow)
	return glow


## A simple building front: wall, roof edge, a grid of windows (lit or dark).
func building(x: float, width: float, top: float, wall: String, lit := false, floor_y := FLOOR_Y) -> void:
	rect(Rect2(x, top, width, floor_y - top), wall)
	rect(Rect2(x - 2, top - 4, width + 4, 4), "outline")
	rect(Rect2(x, top, width, 2), "slate")
	var rows := int((floor_y - top - 40) / 34)
	var cols := int((width - 16) / 30)
	for row in rows:
		for col in cols:
			var w := Rect2(x + 12 + col * 30, top + 14 + row * 34, 16, 20)
			rect(w, "outline")
			var on := lit and (row + col * 3 + int(x)) % 4 == 0
			rect(w.grow(-2), "yellow" if on else "night")
			if on:
				light(w.get_center(), Vector2i(40, 40), "yellow", 0.07)


# --- Collision ------------------------------------------------------------------

func solid(bounds: Rect2, one_way := false) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.collision_layer = 2 if one_way else 1
	body.collision_mask = 0
	body.position = bounds.position + bounds.size / 2
	var collider := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = bounds.size
	collider.shape = shape
	collider.one_way_collision = one_way
	body.add_child(collider)
	add_child(body)
	return body


func ground(from_x: float, to_x: float, y := FLOOR_Y, paint := true) -> void:
	solid(Rect2(from_x, y, to_x - from_x, 360 - y + 40))
	if paint:
		rect(Rect2(from_x, y, to_x - from_x, 4), "concrete")
		rect(Rect2(from_x, y + 4, to_x - from_x, 360 - y), "charcoal")
		for x in range(int(from_x), int(to_x), 24):
			rect(Rect2(x, y + 4, 1, 3), "slate")


## A one-way platform you can jump through from below and drop through with down + jump.
func platform(x: float, y: float, width: float, paint := "slate") -> void:
	solid(Rect2(x, y, width, 6), true)
	rect(Rect2(x, y, width, 3), paint)
	rect(Rect2(x, y + 3, width, 2), "outline")


func walls() -> void:
	solid(Rect2(-16, -200, 16, 600))
	solid(Rect2(world_width, -200, 16, 600))


# --- Spawns, things, NPCs -------------------------------------------------------

func spawn(id: String, x: float, y := FLOOR_Y) -> Node2D:
	var point := preload("res://scenes/world/spawn_point.tscn").instantiate() as Node2D
	point.set("spawn_id", id)
	point.position = Vector2(x, y)
	add_child(point)
	return point


func thing(id: String, x: float, interaction: String, prop := "", y := FLOOR_Y) -> WorldInteractable:
	var object := WorldInteractable.new()
	object.name = id
	object.position = Vector2(x, y)
	object.interaction = interaction
	object.prop = prop
	add_child(object)
	return object


func examine(id: String, x: float, examine_id: String, prop := "", y := FLOOR_Y) -> WorldInteractable:
	var object := thing(id, x, "Examine", prop, y)
	object.examine_id = examine_id
	return object


## A Talk point. With npc_id, the character stands there (and vanishes with the interactable).
func talk(id: String, x: float, file: String, cue: String, npc_id := "", y := FLOOR_Y, face_left := true) -> WorldInteractable:
	var object := thing(id, x, "Talk", "", y)
	object.file = file
	object.title = cue
	if npc_id != "":
		npc(object, npc_id, Vector2.ZERO, face_left)
	return object


func trigger(id: String, x: float, file: String, cue: String, y := FLOOR_Y) -> WorldInteractable:
	var object := thing(id, x, "StoryTrigger", "", y)
	object.file = file
	object.title = cue
	object.once_flag = "trigger_" + id.to_snake_case()
	return object


## A character standing still, e.g. a raider next to a Talk point.
func npc(parent: Node, id: String, offset := Vector2.ZERO, face_left := true) -> AnimatedSprite2D:
	var sprite := WorldPlayer.make_visual(id)
	sprite.position += offset
	sprite.flip_h = face_left
	sprite.z_index = 5
	parent.add_child(sprite)
	return sprite


## Shows or hides any canvas item depending on flags (checked every frame).
func show_when(item: CanvasItem, required_flag := "", hidden_if_flag := "") -> void:
	_flagged.append([item, required_flag, hidden_if_flag])


## An invisible wall that disappears once the flag is set (e.g. the raider checkpoint).
func blocker(x: float, flag: String, visual: Node2D = null) -> void:
	var body := solid(Rect2(x, -200, 12, FLOOR_Y + 200))
	var collider := body.get_child(0) as CollisionShape2D
	_blockers.append([body, collider, flag, visual])


func _add_player() -> void:
	player = preload("res://scenes/world/player.tscn").instantiate() as WorldPlayer
	var first := get_tree().get_nodes_in_group("spawn_points")
	player.position = (first[0] as Node2D).position if not first.is_empty() else Vector2(48, FLOOR_Y)
	player.camera_bounds = Rect2i(0, 0, world_width, 360)
	player.z_index = 10
	add_child(player)
	player.camera.reset_smoothing()


## True when a flag is set to anything but false/""/0 (flags may hold text, e.g. "fight").
static func flag_on(id: String) -> bool:
	var value: Variant = GameState.get_flag(id, false)
	return not (value == null or (value is bool and not value) or (value is String and value.is_empty()) or (value is int and value == 0))


func _process(delta: float) -> void:
	if is_instance_valid(player) and is_instance_valid(player.camera):
		var offset := maxf(0.0, player.camera.get_screen_center_position().x - 320.0)
		for entry: Array in _parallax:
			(entry[0] as Sprite2D).position.x = floorf(offset * float(entry[1]))
	for entry: Array in _flagged:
		var item := entry[0] as CanvasItem
		if is_instance_valid(item):
			item.visible = (entry[1] == "" or flag_on(entry[1])) and (entry[2] == "" or not flag_on(entry[2]))
	for entry: Array in _blockers:
		var open := flag_on(entry[2])
		(entry[1] as CollisionShape2D).set_deferred("disabled", open)
		if entry[3] and is_instance_valid(entry[3]):
			(entry[3] as Node2D).visible = not open
	_update_flicker(delta)
	_update_barks(delta)


# --- Barks and glitches -------------------------------------------------------------

func _on_bark(speaker_id: String, text: String) -> void:
	var anchor: Node2D = null
	for follower in player.followers:
		if is_instance_valid(follower) and follower.get_meta("companion_id", "") == speaker_id:
			anchor = follower
	if anchor == null:
		anchor = player
	if _barks.has(speaker_id) and is_instance_valid(_barks[speaker_id]):
		_barks[speaker_id].queue_free()
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.custom_minimum_size = Vector2(170, 0)
	label.position = Vector2(-85, -78)
	label.z_index = 40
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", color("bone"))
	label.add_theme_color_override("font_outline_color", color("outline"))
	label.add_theme_constant_override("outline_size", 3)
	label.set_meta("time", BARK_SECONDS)
	anchor.add_child(label)
	_barks[speaker_id] = label


func _update_barks(delta: float) -> void:
	for id: String in _barks.keys():
		if not is_instance_valid(_barks[id]):
			_barks.erase(id)
			continue
		var label: Label = _barks[id]
		var left := float(label.get_meta("time")) - delta
		label.set_meta("time", left)
		label.modulate.a = clampf(left / 0.6, 0.0, 1.0)
		if left <= 0.0:
			label.queue_free()
			_barks.erase(id)


func _build_flicker() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 6
	add_child(layer)
	_flicker = ColorRect.new()
	_flicker.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flicker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flicker.color = Color(color("cyan"), 0.0)
	layer.add_child(_flicker)


func _on_glitch(intensity: float, duration: float) -> void:
	var ui := get_tree().get_first_node_in_group("global_ui") as WorldUI
	if ui != null and bool(ui.settings.get_value("display", "reduce_effects", false)):
		return
	_flicker_time = maxf(_flicker_time, duration)
	_flicker_strength = clampf(intensity, 0.0, 1.0)


func _update_flicker(delta: float) -> void:
	if _flicker == null:
		return
	_flicker_time = maxf(0.0, _flicker_time - delta)
	if _flicker_time <= 0.0:
		_flicker.color.a = 0.0
		return
	# A soft, irregular CRT-style flicker in the signal colors; never a full-screen white flash.
	var pulse := absf(sin(Time.get_ticks_msec() * 0.031)) * absf(sin(Time.get_ticks_msec() * 0.013))
	_flicker.color = Color(color("cyan") if pulse > 0.5 else color("magenta"), pulse * 0.16 * _flicker_strength)
