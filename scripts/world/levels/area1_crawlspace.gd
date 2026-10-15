extends AreaLevel
## Hidden and optional: the cult teaser. Reached through the loose hatch behind the chimney on the
## tinkerer's roof. A TV hums with static; someone hums along. The symbol stays on the wall.

const STREET := "res://scenes/levels/area1_vorstadt.tscn"

var _tv_glow: Sprite2D
var _time := 0.0


func build() -> void:
	world_width = 640
	music_id = ""
	ambience_id = "amb_alien_hum"
	walls()
	rect(Rect2(0, 0, world_width, 360), "outline")
	rect(Rect2(0, 150, world_width, FLOOR_Y - 150), "charcoal")
	rect(Rect2(0, 146, world_width, 4), "dark_brown")
	for x in range(0, world_width, 40):
		rect(Rect2(x, 150, 3, FLOOR_Y - 150), "dark_brown")
	ground(0, world_width)
	# Pipes along the low ceiling.
	rect(Rect2(0, 160, world_width, 4), "rust")
	rect(Rect2(0, 170, world_width, 2), "dark_rust")

	# The TV with static.
	rect(Rect2(380, 236, 44, 36), "slate")
	rect(Rect2(384, 240, 36, 26), "concrete")
	for i in 30:
		rect(Rect2(386 + (i * 7) % 32, 242 + (i * 11) % 22, 2, 1), "bone")
	rect(Rect2(388, 272, 28, 14), "brown")
	_tv_glow = light(Vector2(402, 252), Vector2i(180, 110), "pale_sky", 0.14)

	# The symbol: three circles, one of them upside down.
	for i in 3:
		var center := Vector2(150 + i * 26, 214)
		for a in 16:
			var angle := TAU * a / 16.0
			rect(Rect2(center + Vector2(cos(angle), sin(angle)) * 9, Vector2(2, 2)), "ash", null, 0.8)
		if i == 1:
			rect(Rect2(center + Vector2(-1, 2), Vector2(2, 6)), "ash", null, 0.8)
		else:
			rect(Rect2(center + Vector2(-1, -8), Vector2(2, 6)), "ash", null, 0.8)
	examine("CultSymbol", 176, "cult_symbol")

	var cultist := talk("Cultist", 450, "res://dialogue/area1/cult.dialogue", "teaser", "cultist")
	cultist.hidden_if_flag = "cult_teaser_found"

	spawn("start", 60)
	rect(Rect2(30, 240, 30, 46), "slate")
	rect(Rect2(34, 244, 22, 42), "outline")
	var ladder := thing("Ladder", 44, "Door")
	ladder.destination = STREET
	ladder.spawn_id = "from_crawlspace"


func _process(delta: float) -> void:
	super(delta)
	_time += delta
	if is_instance_valid(_tv_glow):
		_tv_glow.modulate.a = 0.75 + 0.25 * sin(_time * 9.0) * sin(_time * 2.3)
