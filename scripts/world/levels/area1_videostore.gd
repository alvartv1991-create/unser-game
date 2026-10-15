extends AreaLevel
## Beat 4: the video game store. The clerk keeps it open, the holy sword stands on a shelf,
## and a poster shows the cheat code that wins the alien fight.

const STREET := "res://scenes/levels/area1_vorstadt.tscn"
const STORE := "res://dialogue/area1/videostore.dialogue"


func build() -> void:
	world_width = 720
	music_id = "music_area1"
	ambience_id = ""
	walls()
	rect(Rect2(0, 0, world_width, 360), "outline")
	rect(Rect2(0, 50, world_width, FLOOR_Y - 50), "plum")
	rect(Rect2(0, 50, world_width, 3), "magenta_dark")
	for x in range(0, world_width, 48):
		rect(Rect2(x, 53, 1, FLOOR_Y - 53), "outline")
	ground(0, world_width)
	for x in [160, 420, 640]:
		rect(Rect2(x - 18, 56, 36, 3), "bone")
		light(Vector2(x, 110), Vector2i(200, 160), "magenta", 0.07)

	# Shelves with cartridges and cassette boxes.
	for shelf in [[80, 3], [560, 2]]:
		var x: int = shelf[0]
		for row in 4:
			rect(Rect2(x, 120 + row * 34, 120, 4), "brown")
			for i in 12:
				rect(Rect2(x + 3 + i * 10, 104 + row * 34, 7, 16), ["red", "denim", "olive", "yellow", "bone"][(row * 3 + i + x) % 5])
	# The cheat poster: "Galaxy Raiders - Profi-Tipp!" with arrows you can read.
	rect(Rect2(232, 92, 104, 72), "outline")
	rect(Rect2(234, 94, 100, 68), "night")
	rect(Rect2(234, 94, 100, 12), "magenta_dark")
	var arrows := ["up", "up", "down", "down", "left", "right", "left", "right"]
	for i in arrows.size():
		_arrow(Vector2(241 + (i % 4) * 23, 114 + (i / 4) * 22), arrows[i])
	examine("CheatPoster", 284, "cheat_poster")

	# The holy sword on its promo stand.
	rect(Rect2(392, 190, 56, 96), "brown")
	rect(Rect2(392, 190, 56, 3), "tan")
	var sword := Node2D.new()
	add_child(sword)
	var blade := Polygon2D.new()
	blade.polygon = PackedVector2Array([Vector2(418, 120), Vector2(422, 120), Vector2(422, 176), Vector2(418, 176)])
	blade.color = color("ash")
	blade.z_index = -7
	sword.add_child(blade)
	var guard := Polygon2D.new()
	guard.polygon = PackedVector2Array([Vector2(408, 176), Vector2(432, 176), Vector2(432, 180), Vector2(408, 180)])
	guard.color = color("yellow")
	guard.z_index = -7
	sword.add_child(guard)
	var grip := Polygon2D.new()
	grip.polygon = PackedVector2Array([Vector2(418, 180), Vector2(422, 180), Vector2(422, 190), Vector2(418, 190)])
	grip.color = color("rust")
	grip.z_index = -7
	sword.add_child(grip)
	light(Vector2(420, 150), Vector2i(90, 120), "yellow", 0.12)
	show_when(sword, "", "holy_sword_taken")
	var shelf := talk("SwordShelf", 420, STORE, "sword_shelf")
	shelf.hidden_if_flag = "holy_sword_taken"

	# Arcade cabinets that react to the signals.
	for i in 2:
		var cabinet := thing("Arcade%d" % i, 500 + i * 40, "GlitchDevice", "")
		cabinet.kind = "arcade"
		cabinet.examine_id = "arcade_cabinet"
		cabinet.intensity = 0.2
		cabinet.sprite.texture = load("res://assets/props/arcade.png")

	# The counter and the clerk.
	rect(Rect2(600, 246, 100, 40), "brown")
	rect(Rect2(600, 246, 100, 4), "tan")
	talk("Clerk", 640, STORE, "clerk", "clerk", FLOOR_Y)

	spawn("from_vorstadt", 60)
	rect(Rect2(20, 190, 44, 96), "outline")
	rect(Rect2(24, 194, 36, 92), "night")
	var door := thing("StreetDoor", 42, "Door")
	door.destination = STREET
	door.spawn_id = "from_videostore"


## A 9x9 pixel arrow in the poster.
func _arrow(at: Vector2, direction: String) -> void:
	var cells := {
		"up": ["....#....", "...###...", "..#####..", ".#######.", "...###...", "...###...", "...###...", "...###...", "........."],
		"down": ["...###...", "...###...", "...###...", "...###...", ".#######.", "..#####..", "...###...", "....#....", "........."],
		"left": ["...#.....", "..##.....", ".########", "#########", ".########", "..##.....", "...#.....", ".........", "........."],
		"right": [".....#...", ".....##..", "########.", "#########", "########.", ".....##..", ".....#...", ".........", "........."],
	}
	var rows: Array = cells[direction]
	for y in rows.size():
		for x in str(rows[y]).length():
			if str(rows[y])[x] == "#":
				rect(Rect2(at.x + x * 2, at.y + y * 2, 2, 2), "cyan")
