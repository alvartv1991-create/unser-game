extends Node2D
@export var side_room: bool = false

func _ready() -> void:
	if GameState.player.is_empty():
		GameState.new_game("doctor")
	RenderingServer.set_default_clear_color(Color("1c2238"))
	var background := Sprite2D.new()
	background.texture = load("res://assets/backgrounds/title.png")
	background.centered = false
	add_child(background)
	var width := 640 if side_room else 1920
	for x in range(0, width, 16):
		tile(Vector2(x, 304), 0)
		tile(Vector2(x, 320), 1)
		tile(Vector2(x, 336), 1)
	solid(Rect2(0, 304, width, 56), false)
	solid(Rect2(-16, 0, 16, 360), false)
	solid(Rect2(width, 0, 16, 360), false)
	var spawn := Marker2D.new()
	spawn.set_script(load("res://scripts/world/spawn_point.gd"))
	spawn.set("spawn_id", "start")
	spawn.position = Vector2(48, 304)
	add_child(spawn)
	var returning := Marker2D.new()
	returning.set_script(load("res://scripts/world/spawn_point.gd"))
	returning.set("spawn_id", "from_room")
	returning.position = Vector2(580, 304)
	add_child(returning)
	var player := preload("res://scenes/world/player.tscn").instantiate() as WorldPlayer
	player.position = spawn.position
	player.camera_bounds = Rect2i(0, 0, width, 360)
	add_child(player)
	if side_room:
		caption(Vector2(60, 180), "UI_LAB_ROOM")
		var door := object_at("ReturnDoor", 180, "Door", "door")
		door.destination = "res://scenes/levels/test_platforming.tscn"
		door.spawn_id = "from_room"
		return
	caption(Vector2(18, 125), "UI_LAB_TITLE")
	caption(Vector2(18, 145), "UI_LAB_CONTROLS")
	caption(Vector2(18, 165), "UI_LAB_HINT")
	caption(Vector2(670, 140), "UI_LAB_PLATFORMS")
	caption(Vector2(1040, 155), "UI_LAB_DEVICES")
	object_at("Talk", 120, "Talk", "radio")
	caption(Vector2(74, 240), "UI_LAB_TALK")
	object_at("Examine", 240, "Examine", "crate")
	object_at("Pickup", 340, "Pickup", "crate")
	caption(Vector2(310, 240), "UI_LAB_PICKUP")
	object_at("Campfire", 450, "Campfire", "campfire")
	caption(Vector2(420, 240), "UI_LAB_REST")
	var door := object_at("Door", 560, "Door", "door")
	door.destination = "res://scenes/levels/test_side_room.tscn"
	caption(Vector2(530, 240), "UI_LAB_DOOR")
	for step in 3:
		var start := Vector2(660 + step * 112, 272 - step * 32)
		for x in 5:
			tile(start + Vector2(x * 16, 0), 2)
		solid(Rect2(start, Vector2(80, 8)), true)
	for i in 4:
		var device := object_at("Device%d" % i, 1040 + i * 72, "GlitchDevice", "tv")
		device.kind = ["tv", "payphone", "radio", "arcade"][i]
		device.examine_id = ["tv_flicker", "payphone", "tv_flicker", "arcade_cabinet"][i]
		device.sprite.texture = load("res://assets/props/%s.png" % device.kind)
	object_at("Story", 1380, "StoryTrigger", "crate")
	caption(Vector2(1330, 230), "UI_LAB_STORY")
	object_at("Encounter", 1490, "EncounterTrigger", "crate")
	caption(Vector2(1460, 190), "UI_LAB_COMBAT")
	var gate := object_at("Gate", 1610, "Gate", "door")
	gate.destination = "res://scenes/levels/test_side_room.tscn"
	caption(Vector2(1570, 240), "UI_LAB_GATE")
	var secret := object_at("Secret", 1820, "SecretPassage", "secret")
	secret.destination = "res://scenes/levels/test_side_room.tscn"
	caption(Vector2(1740, 190), "UI_LAB_SECRET")

func caption(at: Vector2, key: String) -> void:
	var label := Label.new()
	label.position = at
	label.text = tr(key)
	label.add_theme_font_size_override("font_size", 12)
	add_child(label)
	EventBus.locale_changed.connect(func(_locale: String) -> void: label.text = tr(key))

func tile(at: Vector2, index: int) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = load("res://assets/tiles/test_tiles.png")
	sprite.region_enabled = true
	sprite.region_rect = Rect2(index * 16, 0, 16, 16)
	sprite.centered = false
	sprite.position = at
	add_child(sprite)

func solid(bounds: Rect2, one_way: bool) -> void:
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

func object_at(id: String, x: float, interaction: String, prop: String) -> WorldInteractable:
	var object := WorldInteractable.new()
	object.name = id
	object.position = Vector2(x, 304)
	object.interaction = interaction
	object.prop = prop
	add_child(object)
	return object
