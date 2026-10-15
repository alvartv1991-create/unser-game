extends AreaLevel
## Beat 2: the protagonist wakes up in the bunker. The cook can be recruited, the campfire rests
## (and plays the cook's campfire scene once the cook is in the party). The hatch leads to the street.

const STREET := "res://scenes/levels/area1_vorstadt.tscn"
const COOK := "res://dialogue/area1/cook.dialogue"


func build() -> void:
	world_width = 800
	music_id = "music_area1"
	ambience_id = "amb_wind"
	walls()
	# Concrete shell: back wall, ceiling, support beams, a strip light that still works (battery).
	rect(Rect2(0, 0, world_width, 360), "charcoal")
	rect(Rect2(0, 40, world_width, FLOOR_Y - 40), "slate")
	for x in range(0, world_width, 64):
		rect(Rect2(x, 40, 2, FLOOR_Y - 40), "charcoal")
		rect(Rect2(x, 120, 64, 1), "concrete")
	rect(Rect2(0, 30, world_width, 12), "outline")
	for x in [120, 400, 680]:
		rect(Rect2(x - 20, 42, 40, 4), "bone")
		light(Vector2(x, 90), Vector2i(220, 170), "yellow", 0.08)
	sign_text(Vector2(300, 60), "AREA_SIGN_BUNKER", 14, "yellow", "outline")
	ground(0, world_width)
	# Bunks on the left, where you wake up.
	for y in [214, 250]:
		rect(Rect2(40, y, 120, 8), "brown")
		rect(Rect2(44, y - 6, 110, 6), "denim")
		rect(Rect2(40, y + 8, 4, FLOOR_Y - y - 8), "dark_brown")
		rect(Rect2(156, y + 8, 4, FLOOR_Y - y - 8), "dark_brown")
	# Shelves full of cans.
	for row in 4:
		rect(Rect2(220, 140 + row * 30, 110, 4), "brown")
		for i in 9:
			rect(Rect2(224 + i * 12, 130 + row * 30, 8, 10), ["concrete", "ash", "rust"][(row + i) % 3])
	# The stove where the cook stands.
	rect(Rect2(400, 238, 70, 48), "concrete")
	rect(Rect2(400, 238, 70, 4), "ash")
	rect(Rect2(412, 230, 18, 8), "slate")
	light(Vector2(430, 250), Vector2i(120, 90), "orange", 0.12)
	# The campfire in an oil drum, and the hatch to the street.
	rect(Rect2(700, 120, 60, FLOOR_Y - 120), "outline")
	rect(Rect2(704, 124, 52, FLOOR_Y - 124), "concrete")
	rect(Rect2(728, 150, 4, 90), "slate")

	spawn("start", 100)
	spawn("from_vorstadt", 690)

	var cook_first := talk("CookFirstMeet", 450, COOK, "first_meet", "cook")
	cook_first.hidden_if_flag = "cook_met"
	var cook_idle := talk("CookIdle", 450, COOK, "idle", "cook")
	cook_idle.required_flag = "cook_met"
	cook_idle.hidden_if_flag = "cook_recruited"

	var fire := thing("Campfire", 580, "Campfire", "campfire")
	fire.file = COOK
	fire.after_title = "campfire"
	light(Vector2(580, 266), Vector2i(140, 90), "orange", 0.16)

	examine("BunkerDoor", 650, "bunker_door")
	var hatch := thing("Hatch", 730, "Door")
	hatch.destination = STREET
	hatch.spawn_id = "from_bunker"


func after_build() -> void:
	if not GameState.get_flag("intro_done", false):
		DialogueRunner.start("res://dialogue/area1/intro.dialogue", "start")
