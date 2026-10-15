extends SceneTree
## Original pixel-art streetscape. Deterministic source, shared 32-color palette.
## The opening is an ordinary 80s street: no alien presence or interference.
var p: Array[Color] = []
var rng := RandomNumberGenerator.new()

func _initialize() -> void:
	rng.seed = 198401
	var source: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tools/pixelart/palette.json"))
	for entry: Dictionary in source.colors:
		p.append(Color(entry.hex))
	sky()
	distance_layer()
	street()
	foreground()
	quit()

func canvas() -> Image:
	return Image.create(1280, 360, false, Image.FORMAT_RGBA8)

func pixel(im: Image, x: int, y: int, c: int) -> void:
	if x >= 0 and x < im.get_width() and y >= 0 and y < im.get_height():
		im.set_pixel(x, y, p[c])

func rect(im: Image, x: int, y: int, w: int, h: int, c: int) -> void:
	var clipped := Rect2i(x, y, w, h).intersection(Rect2i(0, 0, im.get_width(), im.get_height()))
	if clipped.has_area():
		im.fill_rect(clipped, p[c])

func line(im: Image, a: Vector2i, b: Vector2i, c: int, thickness: int = 1) -> void:
	var steps := maxi(absi(b.x - a.x), absi(b.y - a.y))
	for i in steps + 1:
		var at := Vector2(a).lerp(Vector2(b), float(i) / maxi(1, steps))
		rect(im, roundi(at.x), roundi(at.y), thickness, thickness, c)

func ellipse(im: Image, center: Vector2i, rx: int, ry: int, c: int) -> void:
	for y in range(-ry, ry + 1):
		for x in range(-rx, rx + 1):
			if float(x * x) / maxi(1, rx * rx) + float(y * y) / maxi(1, ry * ry) <= 1:
				pixel(im, center.x + x, center.y + y, c)

func save(im: Image, file: String) -> void:
	var target := "res://assets/backgrounds/street_%s.png" % file
	DirAccess.make_dir_recursive_absolute(target.get_base_dir())
	im.save_png(target)

func sky() -> void:
	var im := canvas()
	im.fill(p[18])
	# Broken cloud clusters; no smooth gradients or filtered textures.
	for i in 95:
		var x := rng.randi_range(-40, 1280)
		var y := rng.randi_range(20, 170)
		var w := rng.randi_range(20, 95)
		for row in rng.randi_range(2, 5):
			var offset := rng.randi_range(-8, 8)
			rect(im, x + offset, y + row * 2, w, 2, 1)
			for k in 8:
				rect(im, x + offset + rng.randi_range(0, w), y + row * 2, rng.randi_range(2, 8), 1, 18)
	# Moon and deliberately broken halo on the cool night sky.
	ellipse(im, Vector2i(489, 48), 20, 19, 19)
	ellipse(im, Vector2i(489, 48), 15, 15, 20)
	ellipse(im, Vector2i(487, 46), 12, 13, 21)
	ellipse(im, Vector2i(490, 50), 5, 4, 20)
	ellipse(im, Vector2i(480, 42), 3, 3, 20)
	for i in 100:
		var x := rng.randi_range(0, 1279)
		var y := rng.randi_range(8, 115)
		if im.get_pixel(x, y) == p[18]:
			pixel(im, x, y, 20 if i % 5 == 0 else 19)
	save(im, "sky")

func pine(im: Image, x: int, base: int, height: int, c: int) -> void:
	rect(im, x - 1, base - height, 3, height, c)
	for row in range(7, height, 4):
		var span := int(row * 0.27)
		for y in 4:
			var edge := rng.randi_range(0, 4)
			rect(im, x - span - y + edge, base - height + row + y, maxi(1, span * 2 + y * 2 - edge), 1, c)
		if c != 0:
			for k in maxi(1, span / 3):
				var xx := x + rng.randi_range(-span, span)
				rect(im, xx, base - height + row + rng.randi_range(0, 2), rng.randi_range(1, 4), 1, 1 if c == 19 else 14)

func distance_layer() -> void:
	var im := canvas()
	for x in range(-15, 1300, 23):
		pine(im, x, 255, rng.randi_range(55, 125), 18)
	for i in 16:
		var x := i * 93 - 25
		var top := rng.randi_range(174, 224)
		rect(im, x, top, 76, 90, 1)
		line(im, Vector2i(x - 4, top), Vector2i(x + 38, top - 23), 1, 3)
		line(im, Vector2i(x + 38, top - 23), Vector2i(x + 80, top), 1, 3)
		for y in range(top + 12, 264, 19):
			for wx in range(x + 8, x + 66, 17):
				var lit := rng.randf() > 0.75
				rect(im, wx, y, 7, 11, 7 if lit else 18)
				if lit:
					rect(im, wx + 1, y + 1, 5, 6, 9)
					rect(im, wx + 3, y, 1, 11, 1)
	# A distant water tank and cross-bracing, kept behind the shops.
	rect(im, 748, 111, 37, 27, 19)
	ellipse(im, Vector2i(766, 111), 19, 6, 19)
	line(im, Vector2i(752, 136), Vector2i(742, 236), 19, 2)
	line(im, Vector2i(781, 136), Vector2i(792, 236), 19, 2)
	for y in range(147, 225, 24):
		line(im, Vector2i(751, y), Vector2i(786, y + 24), 19)
		line(im, Vector2i(751, y + 24), Vector2i(786, y), 19)
	save(im, "distance")

func brick(im: Image, box: Rect2i, base: int, mortar: int) -> void:
	rect(im, box.position.x, box.position.y, box.size.x, box.size.y, base)
	for y in range(box.position.y, box.end.y, 6):
		rect(im, box.position.x, y, box.size.x, 1, mortar)
		for x in range(box.position.x - 10 + ((y / 6) as int % 2) * 10, box.end.x, 20):
			if x >= box.position.x:
				rect(im, x, y, 1, 6, mortar)
			if rng.randf() > 0.6:
				var highlight := Rect2i(x + 3, y + 2, rng.randi_range(3, 10), 1).intersection(box)
				rect(im, highlight.position.x, highlight.position.y, highlight.size.x, highlight.size.y, 2 if base == 25 else 7)

func tube(im: Image, a: Vector2i, b: Vector2i, dark: int, bright: int) -> void:
	line(im, a + Vector2i(-2, -2), b + Vector2i(-2, -2), dark, 5)
	line(im, a + Vector2i(-1, -1), b + Vector2i(-1, -1), bright, 3)
	line(im, a, b, 5)

func window(im: Image, x: int, y: int, w: int, h: int, lit: bool = true) -> void:
	rect(im, x - 3, y - 3, w + 6, h + 6, 0)
	rect(im, x - 2, y - 2, w + 4, h + 4, 3)
	rect(im, x, y, w, h, 7 if lit else 18)
	if lit:
		rect(im, x + 1, y + 1, w - 2, 5, 13)
		rect(im, x + 1, y + 6, w - 2, h - 7, 8)
		for i in range(4, w - 2, 9):
			rect(im, x + i, y + 6, 1, h - 7, 9)
	else:
		line(im, Vector2i(x + 3, y + h - 3), Vector2i(x + w / 2, y + 4), 19)
	rect(im, x + w / 2, y, 2, h, 1)
	rect(im, x - 4, y + h, w + 8, 3, 3)

func cabinet(im: Image, x: int, y: int, accent: int) -> void:
	rect(im, x, y, 22, 45, 0)
	rect(im, x + 1, y + 1, 20, 7, accent)
	rect(im, x + 2, y + 9, 18, 21, 2)
	rect(im, x + 4, y + 11, 14, 15, 18)
	for i in 12:
		pixel(im, x + rng.randi_range(5, 16), y + rng.randi_range(12, 24), 20)
	line(im, Vector2i(x + 8, y + 23), Vector2i(x + 11, y + 16), 21)
	line(im, Vector2i(x + 11, y + 16), Vector2i(x + 14, y + 23), 21)
	rect(im, x + 1, y + 30, 20, 4, accent)
	rect(im, x + 6, y + 29, 2, 4, 0)
	pixel(im, x + 15, y + 31, 5)
	rect(im, x + 3, y + 35, 16, 10, 1)
	rect(im, x + 9, y + 38, 4, 2, 3)

func arcade(im: Image) -> void:
	# Layered brick fascia, drainage, roof trim and warm upper windows.
	brick(im, Rect2i(30, 102, 334, 182), 25, 0)
	rect(im, 22, 96, 350, 7, 0)
	rect(im, 24, 96, 346, 2, 3)
	rect(im, 28, 103, 338, 2, 2)
	for x in [60, 139, 218, 297]:
		window(im, x, 114, 32, 32, x != 218)
		rect(im, x + 2, 128, 29, 2, 6)
		# Small individual panes, old plaster chips and sill shadows.
		rect(im, x - 4, 149, 40, 1, 0)
	for i in 420:
		var x := rng.randi_range(31, 362)
		var y := rng.randi_range(105, 280)
		if im.get_pixel(x, y) == p[25]:
			pixel(im, x, y, 1 if i % 4 else 2)
	# Shop front behind glass, frames and open entrance.
	rect(im, 42, 183, 310, 99, 0)
	rect(im, 47, 188, 228, 88, 25)
	rect(im, 48, 189, 226, 5, 12)
	rect(im, 48, 194, 226, 4, 8)
	rect(im, 48, 257, 226, 17, 1)
	for y in range(260, 276, 6):
		for x in range(48, 274, 10):
			rect(im, x + ((y / 6) as int % 2) * 4, y, 5, 3, 25)
	for i in 6:
		cabinet(im, 54 + i * 35, 224, 28 if i % 2 == 0 else 26)
	# Ceiling lamps, exposed conduit, and a framed wall notice behind glass.
	rect(im, 50, 201, 220, 1, 1)
	for x in [75, 145, 215]:
		rect(im, x, 198, 1, 6, 0)
		rect(im, x - 8, 204, 17, 2, 13)
		rect(im, x - 5, 206, 11, 1, 5)
		rect(im, x + 12, 210, 9, 10, 7)
		rect(im, x + 13, 211, 7, 1, 9)
		rect(im, x + 14, 215, 5, 1, 2)
	# Floor light inside; dark window muntins keep readable silhouettes.
	for x in [46, 117, 188, 273]:
		rect(im, x, 186, 4, 94, 0)
		line(im, Vector2i(x + 2, 189), Vector2i(x + 2, 276), 3)
	for x in [85, 156, 227]:
		line(im, Vector2i(x, 193), Vector2i(x - 23, 219), 2)
		line(im, Vector2i(x + 4, 193), Vector2i(x - 8, 207), 3)
	rect(im, 286, 190, 55, 90, 6)
	rect(im, 291, 193, 45, 82, 8)
	rect(im, 294, 195, 39, 62, 9)
	rect(im, 294, 258, 39, 16, 7)
	rect(im, 315, 193, 3, 83, 1)
	rect(im, 321, 234, 2, 9, 5)
	rect(im, 282, 279, 65, 4, 4)
	# Ordinary 80s shop neon: human art direction supersedes alien-only hues.
	rect(im, 42, 150, 310, 32, 0)
	rect(im, 45, 153, 304, 26, 25)
	tube(im, Vector2i(45, 151), Vector2i(349, 151), 30, 31)
	tube(im, Vector2i(45, 179), Vector2i(349, 179), 28, 29)
	# Power boxes, downpipes and roof ventilation.
	rect(im, 353, 108, 4, 170, 0)
	rect(im, 354, 108, 1, 170, 3)
	rect(im, 335, 118, 14, 20, 2)
	rect(im, 337, 120, 10, 3, 4)
	for y in range(126, 135, 3):
		rect(im, 338, y, 7, 1, 0)
	# Worn paper notices on the brick piers, without invented story text.
	for x in [34, 275]:
		rect(im, x, 220, 7, 15, 9)
		rect(im, x + 1, 222, 5, 4, 11)
		for y in range(229, 233, 2):
			rect(im, x + 1, y, 4, 1, 7)
	rect(im, 70, 86, 45, 10, 1)
	rect(im, 68, 83, 49, 3, 3)
	for x in range(74, 112, 5):
		rect(im, x, 87, 1, 7, 0)

func diner(im: Image) -> void:
	brick(im, Rect2i(530, 159, 240, 125), 6, 0)
	rect(im, 523, 151, 254, 9, 1)
	rect(im, 526, 152, 248, 2, 3)
	rect(im, 540, 168, 220, 24, 0)
	tube(im, Vector2i(543, 170), Vector2i(757, 170), 10, 12)
	tube(im, Vector2i(543, 191), Vector2i(757, 191), 10, 12)
	for i in 4:
		var x := 541 + i * 55
		window(im, x, 202, 46, 63)
		rect(im, x + 1, 203, 44, 61, 7)
		rect(im, x + 1, 228, 44, 34, 6)
		rect(im, x + 21, 204, 1, 7, 0)
		rect(im, x + 15, 211, 14, 3, 13)
		rect(im, x + 18, 214, 8, 1, 5)
		rect(im, x + 3, 217, 10, 13, 0)
		rect(im, x + 4, 218, 8, 11, 9)
		for y in [221, 224, 227]:
			rect(im, x + 5, y, 5, 1, 7)
		rect(im, x + 34, 223, 1, 8, 14)
		rect(im, x + 32, 218, 6, 7, 15)
		rect(im, x + 4, 244, 13, 13, 11)
		rect(im, x + 29, 244, 12, 13, 11)
		rect(im, x + 4, 241, 4, 14, 12)
		rect(im, x + 37, 241, 4, 14, 12)
		rect(im, x + 14, 241, 19, 2, 9)
		rect(im, x + 23, 244, 2, 16, 1)
		rect(im, x + 19, 238, 3, 3, 5)
		rect(im, x + 27, 237, 2, 4, 12)
		rect(im, x + 22, 202, 2, 62, 1)
		line(im, Vector2i(x + 42, 205), Vector2i(x + 31, 216), 8)
	rect(im, 529, 272, 241, 11, 2)
	rect(im, 530, 273, 239, 2, 4)

func phone(im: Image, x: int) -> void:
	rect(im, x - 2, 220, 30, 64, 0)
	rect(im, x, 221, 26, 62, 3)
	rect(im, x + 2, 223, 22, 8, 19)
	rect(im, x + 3, 224, 20, 2, 21)
	rect(im, x + 3, 234, 20, 44, 9)
	rect(im, x + 5, 236, 16, 41, 7)
	rect(im, x + 10, 244, 10, 19, 3)
	rect(im, x + 11, 246, 3, 12, 0)
	for y in range(248, 258, 3):
		for xx in [16, 19]:
			pixel(im, x + xx, y, 5)
	line(im, Vector2i(x + 12, 259), Vector2i(x + 8, 269), 0)
	rect(im, x + 1, 231, 2, 50, 4)
	rect(im, x + 23, 231, 2, 50, 2)
	rect(im, x - 4, 281, 34, 4, 2)

func lamp(im: Image, x: int) -> void:
	rect(im, x, 170, 4, 115, 0)
	rect(im, x + 1, 171, 1, 113, 3)
	rect(im, x - 8, 281, 20, 5, 1)
	line(im, Vector2i(x + 1, 171), Vector2i(x - 10, 157), 0, 3)
	rect(im, x - 31, 155, 24, 4, 0)
	rect(im, x - 29, 159, 20, 3, 13)
	rect(im, x - 25, 162, 13, 2, 5)
	# Dithered light cone made from sparse warm pixels, not a smooth overlay.
	for i in 80:
		var y := rng.randi_range(169, 282)
		var span := (y - 150) / 4
		var xx := x - 20 + rng.randi_range(-span, span)
		if i % 3 == 0:
			pixel(im, xx, y, 7)
		if y > 275:
			rect(im, xx, y, 3, 1, 9)

func car(im: Image, x: int, y: int) -> void:
	ellipse(im, Vector2i(x + 19, y + 21), 9, 9, 0)
	ellipse(im, Vector2i(x + 69, y + 21), 9, 9, 0)
	rect(im, x + 20, y - 5, 43, 8, 19)
	line(im, Vector2i(x + 20, y - 4), Vector2i(x + 10, y + 7), 19, 4)
	line(im, Vector2i(x + 61, y - 4), Vector2i(x + 74, y + 6), 19, 4)
	rect(im, x + 2, y + 6, 85, 15, 19)
	rect(im, x, y + 12, 89, 8, 2)
	rect(im, x + 4, y + 7, 78, 2, 20)
	rect(im, x + 22, y - 2, 16, 9, 0)
	rect(im, x + 42, y - 2, 17, 9, 0)
	line(im, Vector2i(x + 26, y - 1), Vector2i(x + 23, y + 5), 20)
	line(im, Vector2i(x + 49, y - 1), Vector2i(x + 46, y + 5), 20)
	rect(im, x + 39, y + 8, 1, 10, 0)
	rect(im, x + 48, y + 10, 5, 1, 4)
	for offset in [19, 69]:
		ellipse(im, Vector2i(x + offset, y + 21), 8, 8, 0)
		ellipse(im, Vector2i(x + offset, y + 21), 4, 4, 3)
		ellipse(im, Vector2i(x + offset, y + 21), 2, 2, 1)
	rect(im, x + 81, y + 10, 5, 4, 13)
	rect(im, x + 1, y + 10, 4, 4, 11)
	rect(im, x, y + 18, 11, 3, 4)
	rect(im, x + 77, y + 18, 12, 3, 4)

func street() -> void:
	var im := canvas()
	# Walkable sidewalk is y=286; wet road below is decorative depth.
	rect(im, 0, 281, 1280, 11, 2)
	rect(im, 0, 284, 1280, 2, 4)
	rect(im, 0, 292, 1280, 68, 18)
	for x in range(0, 1280, 24):
		rect(im, x, 286, 1, 7, 0)
		rect(im, x + 2, 289, 20, 1, 3)
	for i in 2600:
		var x := rng.randi_range(0, 1279)
		var y := rng.randi_range(294, 359)
		var col := 1 if i % 4 else 19
		if x < 370 and i % 4 == 0:
			col = 25 if i % 2 == 0 else 28
		rect(im, x, y, rng.randi_range(1, 5), 1, col)
	for pool: Array in [[80, 31], [200, 29], [308, 13], [429, 13], [580, 12], [690, 13], [805, 13]]:
		for i in 100:
			var y := rng.randi_range(295, 355)
			var spread := 10 + (y - 295) / 3
			var x: int = pool[0] + rng.randi_range(-spread, spread)
			rect(im, x, y, rng.randi_range(1, 10), 1, pool[1] if i % 4 == 0 else (30 if pool[1] == 31 else 19))
	# Faded road paint and drain grates.
	for x in range(5, 1280, 112):
		rect(im, x, 341, 42, 2, 3)
		for i in 7:
			rect(im, x + rng.randi_range(0, 40), 341, 2, 2, 18)
	for x in [375, 872]:
		rect(im, x, 287, 26, 4, 0)
		for xx in range(x + 2, x + 24, 3):
			rect(im, xx, 288, 1, 2, 3)
	arcade(im)
	diner(im)
	phone(im, 390)
	car(im, 800, 253)
	# Rooftop aerials and sagging utility lines.
	for x in [140, 286, 654]:
		rect(im, x, 65 if x < 360 else 123, 2, 32, 0)
		var y := 70 if x < 360 else 126
		line(im, Vector2i(x - 15, y + 8), Vector2i(x + 16, y), 3)
		for offset in [-9, 0, 9]:
			line(im, Vector2i(x + offset - 3, y + 1), Vector2i(x + offset + 3, y + 13), 3)
	for x in [490, 936, 1242]:
		rect(im, x, 83, 5, 201, 6)
		rect(im, x + 1, 83, 1, 200, 8)
		rect(im, x - 16, 100, 37, 3, 0)
		for xx in [x - 12, x + 1, x + 14]:
			rect(im, xx, 96, 3, 5, 3)
	for wire in 3:
		var previous := Vector2i(-10, 75 + wire * 8)
		for x in range(0, 1281, 4):
			var y := 85 + wire * 8 + int(27 * sin(float(x % 446) / 446 * PI))
			line(im, previous, Vector2i(x, y), 0)
			previous = Vector2i(x, y)
	# Bushes / forest at the right-hand edge: entirely ordinary landscape.
	for x in range(960, 1290, 29):
		pine(im, x, 282, rng.randi_range(80, 174), 0 if x % 3 == 0 else 14)
	for i in 350:
		var x := rng.randi_range(952, 1279)
		var y := rng.randi_range(264, 282)
		rect(im, x, y, rng.randi_range(2, 5), 2, 14 if i % 3 else 15)
	# Bench, a bin, and simple steps give the walk plane a lived-in edge.
	for x in [460, 910]:
		rect(im, x, 263, 37, 4, 7)
		rect(im, x, 269, 37, 3, 8)
		rect(im, x + 3, 271, 3, 13, 0)
		rect(im, x + 30, 271, 3, 13, 0)
	rect(im, 508, 264, 14, 20, 14)
	rect(im, 507, 263, 16, 3, 2)
	for x in range(510, 521, 3):
		rect(im, x, 269, 1, 12, 0)
	lamp(im, 450)
	lamp(im, 804)
	lamp(im, 1190)
	save(im, "world")

func foreground() -> void:
	var im := canvas()
	# Restrained foreground silhouette: it must not hide feet or the curb.
	for i in 600:
		var x := rng.randi_range(0, 1279)
		var edge := x < 90 or x > 1190
		var y := rng.randi_range(349 if edge else 356, 359)
		rect(im, x, y, rng.randi_range(2, 8), 2, 0)
	# Corner branches frame the view without covering readable UI.
	for i in 8:
		var x := 1100 + i * 25
		line(im, Vector2i(x, 0), Vector2i(x - 60, 47), 0, 2)
		for k in 12:
			rect(im, x - rng.randi_range(0, 60), rng.randi_range(1, 40), rng.randi_range(3, 9), 2, 0)
	save(im, "foreground")
