extends AreaLevel
## Beats 3-8, west to east: the street (first raiders), the video store door, the tinkerer's rooftop
## (with the hidden way to the cult behind the chimney), the raider camp, the alien zone and the gate.
## The further east, the darker it gets: the swarm drains the power (docs/VISION.md).

const BUNKER := "res://scenes/levels/area1_bunker.tscn"
const STORE := "res://scenes/levels/area1_videostore.tscn"
const CRAWLSPACE := "res://scenes/levels/area1_crawlspace.tscn"
const RAIDERS := "res://dialogue/area1/raiders.dialogue"
const TINKERER := "res://dialogue/area1/tinkerer.dialogue"
const ALIEN := "res://dialogue/area1/alien_zone.dialogue"
const GATE := "res://dialogue/area1/gate.dialogue"
const ROOF_Y := 118.0

var _swarm_block: Node2D
var _swarm_far: Node2D


func build() -> void:
	world_width = 4600
	music_id = "music_area1"
	ambience_id = "amb_wind"
	walls()
	parallax_layer("sky", 0.82, -30)
	parallax_layer("distance", 0.38, -20)
	parallax_layer("world", 0.0, -10, false)
	parallax_layer("foreground", 0.0, 30, false)
	ground(0, world_width, FLOOR_Y, false)
	rect(Rect2(1280, FLOOR_Y, world_width - 1280, 4), "concrete")
	rect(Rect2(1280, FLOOR_Y + 4, world_width - 1280, 80), "charcoal")
	_build_street()
	_build_rooftop()
	_build_camp()
	_build_alien_zone()
	_build_gate()


func _build_street() -> void:
	# The shelter hatch at the far left.
	rect(Rect2(8, 246, 30, 40), "outline")
	rect(Rect2(11, 249, 24, 37), "concrete")
	rect(Rect2(14, 262, 18, 2), "slate")
	spawn("from_bunker", 60)
	var hatch := thing("BunkerHatch", 24, "Door")
	hatch.destination = BUNKER
	hatch.spawn_id = "from_vorstadt"

	# The arcade front in the street art becomes the video store.
	sign_text(Vector2(56, 154), "AREA_SIGN_VIDEOSTORE", 18, "magenta", "magenta_dark")
	sign_text(Vector2(62, 206), "AREA_SIGN_OPEN", 9, "pink", "plum")
	light(Vector2(195, 169), Vector2i(384, 144), "magenta", 0.12)
	light(Vector2(192, 222), Vector2i(320, 112), "cyan_dark", 0.11)
	light(Vector2(648, 219), Vector2i(272, 152), "yellow", 0.1)
	spawn("from_videostore", 315)
	var door := thing("VideostoreDoor", 315, "Door")
	door.destination = STORE
	door.spawn_id = "from_vorstadt"

	# Devices that react to the signals, and things to look at.
	var phone := thing("Payphone", 403, "GlitchDevice")
	phone.kind = "payphone"
	phone.examine_id = "payphone"
	phone.intensity = 0.2
	phone.sprite.texture = null   # the street art already shows the booth
	var tv := thing("ShopTv", 505, "GlitchDevice")
	tv.kind = "tv"
	tv.examine_id = "tv_flicker"
	tv.intensity = 0.25
	_burnt_car(1150)
	examine("BurntCar", 1170, "burnt_car")

	# The first raiders block the street until they're dealt with.
	var raiders := talk("StreetRaiders", 1010, RAIDERS, "street", "raider_scavenger")
	npc(raiders, "raider_scavenger", Vector2(22, 0))
	raiders.hidden_if_flag = "raiders_street_done"
	blocker(1050, "raiders_street_done")


func _build_rooftop() -> void:
	# A block of flats, power out: dark windows. Fire escape on the left, flat roof on top.
	rect(Rect2(1280, 0, 1100, FLOOR_Y), "night", null, 0.35)
	building(1360, 560, ROOF_Y, "plum")
	building(1960, 260, 170, "charcoal")
	for i in 5:
		var y := FLOOR_Y - 34 - i * 34
		platform(1300 + (i % 2) * 26, y, 46, "concrete")
	rect(Rect2(1298, ROOF_Y, 2, FLOOR_Y - ROOF_Y), "concrete")
	rect(Rect2(1346, ROOF_Y, 2, FLOOR_Y - ROOF_Y), "concrete")
	platform(1350, ROOF_Y, 570, "slate")
	# Optional corner: a ledge with a bandage.
	platform(1452, 196, 40, "concrete")
	var bandage := thing("LedgeBandage", 1472, "Pickup", "crate", 196)
	bandage.item_id = "bandage"

	# The tinkerer and the dish.
	_satellite_dish(1780, ROOF_Y)
	examine("SatelliteDish", 1790, "satellite_dish", "", ROOF_Y)
	var first := talk("TinkererFirstMeet", 1700, TINKERER, "first_meet", "tinkerer", ROOF_Y)
	first.hidden_if_flag = "tinkerer_met"
	var idle := talk("TinkererIdle", 1700, TINKERER, "idle", "tinkerer", ROOF_Y)
	idle.required_flag = "tinkerer_met"
	idle.hidden_if_flag = "tinkerer_recruited"

	# Hidden: behind the chimney, a loose hatch. A faint chalk mark is the only hint.
	rect(Rect2(1840, ROOF_Y - 26, 22, 26), "rust")
	rect(Rect2(1838, ROOF_Y - 30, 26, 4), "outline")
	solid(Rect2(1840, ROOF_Y - 26, 22, 26))
	for i in 3:
		rect(Rect2(1846 + i * 4, ROOF_Y - 18 + (i % 2) * 3, 3, 3), "ash", null, 0.55)
	spawn("from_crawlspace", 1870, ROOF_Y)
	var secret := thing("CultHatch", 1906, "SecretPassage", "secret", ROOF_Y)
	secret.destination = CRAWLSPACE
	secret.spawn_id = "start"
	secret.once_flag = "cult_route_found"


func _build_camp() -> void:
	rect(Rect2(2380, 0, 900, FLOOR_Y), "night", null, 0.45)
	sign_text(Vector2(2470, 196), "AREA_SIGN_CAMP", 10, "bone", "outline")
	# Fence, tents, barrels, a fire.
	for x in range(2440, 2560, 14):
		rect(Rect2(x, 226, 3, 60), "brown")
	rect(Rect2(2440, 236, 120, 3), "concrete")
	rect(Rect2(2440, 258, 120, 3), "concrete")
	for t in [[2780, "olive"], [2900, "rust"]]:
		var x: int = t[0]
		for row in 40:
			rect(Rect2(x + 40 - row, 246 + row, row * 2, 1), t[1])
		rect(Rect2(x + 34, 266, 12, 20), "outline")
	for x in [2600, 2620, 3000]:
		rect(Rect2(x, 262, 16, 24), "rust")
		rect(Rect2(x, 268, 16, 2), "dark_rust")
	sprite_at("res://assets/props/campfire.png", Vector2(2700, 270), -4)
	light(Vector2(2700, 262), Vector2i(220, 120), "orange", 0.18)

	var camp := talk("CampRaiders", 2640, RAIDERS, "camp", "raider_brute")
	npc(camp, "raider_scavenger", Vector2(26, 0))
	npc(camp, "raider_scavenger", Vector2(48, 0))
	camp.hidden_if_flag = "raiders_camp_resolved"
	blocker(2700, "raiders_camp_resolved")
	var rest := thing("CampFire", 2730, "Campfire")
	rest.required_flag = "raiders_camp_resolved"
	rest.file = "res://dialogue/area1/cook.dialogue"
	rest.after_title = "campfire"
	var can := thing("CampCans", 2960, "Pickup", "crate")
	can.item_id = "canned_food"
	can.required_flag = "raiders_camp_resolved"


func _build_alien_zone() -> void:
	# No power at all; the alien structure fills the horizon.
	rect(Rect2(3280, 0, 1320, FLOOR_Y), "plum", null, 0.45)
	var structure := Polygon2D.new()
	structure.polygon = PackedVector2Array([Vector2(3500, FLOOR_Y), Vector2(3620, 40), Vector2(3700, 90), Vector2(3800, 10), Vector2(3920, 120), Vector2(4040, 60), Vector2(4160, FLOOR_Y)])
	structure.color = color("outline", 0.85)
	structure.z_index = -9
	add_child(structure)
	for i in 14:
		rect(Rect2(3560 + i * 40, 60 + (i * 37) % 160, 2, 12 + (i * 13) % 30), "cyan_dark" if i % 2 else "magenta_dark")
	# Half-taken-apart cars and a bus.
	for x in [3330, 3460]:
		_car_frame(x)
	_bus(3820)

	trigger("ZoneEnter", 3300, ALIEN, "enter")
	trigger("ZoneSnatching", 3560, ALIEN, "snatching")
	_swarm_far = _swarm(Vector2(3640, 120), "idle")
	examine("AlienStructure", 3720, "alien_structure")
	trigger("Dilemma", 3880, ALIEN, "dilemma")

	# The swarm blocks the gate. First time: a story trigger. Afterwards: talk to retry.
	var block := trigger("SwarmBlocksGate", 4180, ALIEN, "swarm_blocks_gate")
	block.hidden_if_flag = "aliens_dispersed"
	var again := talk("SwarmAgain", 4200, ALIEN, "swarm_blocks_gate")
	again.required_flag = block.once_flag
	again.hidden_if_flag = "aliens_dispersed"
	_swarm_block = _swarm(Vector2(4290, 220), "agitated")
	show_when(_swarm_block, "", "aliens_dispersed")
	blocker(4240, "aliens_dispersed")


func _build_gate() -> void:
	rect(Rect2(4400, 150, 140, FLOOR_Y - 150), "outline")
	for x in range(4404, 4536, 12):
		rect(Rect2(x, 154, 6, FLOOR_Y - 154), "slate")
	rect(Rect2(4400, 196, 140, 4), "concrete")
	spawn("from_gate", 4360)
	var gate := thing("Gate", 4470, "Gate")
	gate.gate_flag = "aliens_dispersed"
	gate.file = GATE
	gate.title = "locked"
	gate.after_title = "open"
	gate.destination = "res://scenes/ui/area_select.tscn"
	gate.spawn_id = ""


# --- Pieces ---------------------------------------------------------------------

func _swarm(at: Vector2, mood: String) -> Node2D:
	var swarm := (load("res://scenes/fx/alien_swarm.tscn") as PackedScene).instantiate() as Node2D
	swarm.position = at
	swarm.z_index = -3
	add_child(swarm)
	if swarm.has_method("set_mood"):
		swarm.call("set_mood", mood)
	return swarm


func _burnt_car(x: float) -> void:
	rect(Rect2(x, 262, 70, 18), "dark_rust")
	rect(Rect2(x + 12, 248, 40, 14), "outline")
	rect(Rect2(x + 16, 251, 14, 9), "charcoal")
	rect(Rect2(x + 34, 251, 14, 9), "charcoal")
	rect(Rect2(x + 2, 266, 66, 2), "rust")
	for wx in [x + 10, x + 50]:
		rect(Rect2(wx, 278, 12, 8), "outline")


func _car_frame(x: float) -> void:
	rect(Rect2(x, 266, 60, 12), "denim")
	rect(Rect2(x + 10, 254, 18, 12), "slate")
	rect(Rect2(x + 44, 270, 16, 8), "night")
	for wx in [x + 6]:
		rect(Rect2(wx, 278, 12, 8), "outline")


func _bus(x: float) -> void:
	rect(Rect2(x, 222, 150, 56), "yellow")
	rect(Rect2(x, 222, 150, 4), "sand")
	for i in 6:
		rect(Rect2(x + 8 + i * 24, 232, 18, 16), "night")
	rect(Rect2(x + 100, 222, 50, 56), "outline")
	rect(Rect2(x + 104, 226, 6, 50), "slate")
	for wx in [x + 14, x + 70]:
		rect(Rect2(wx, 278, 16, 8), "outline")


func _satellite_dish(x: float, y: float) -> void:
	for row in 12:
		var width := 24 - absi(row - 6) * 3
		rect(Rect2(x - width / 2.0 + row, y - 30 + row, width, 1), "ash")
	rect(Rect2(x + 2, y - 18, 3, 18), "concrete")
	rect(Rect2(x - 6, y - 2, 18, 2), "slate")
