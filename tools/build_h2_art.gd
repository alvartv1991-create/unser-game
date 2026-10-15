extends SceneTree
## Reproducible hand-drawn pixel assets; palette from the shared art contract.
var palette: Array[Color] = []

func _initialize() -> void:
	var source: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tools/pixelart/palette.json"))
	for entry: Dictionary in source.colors:
		palette.append(Color(entry.hex))
	build_tiles()
	for kind in ["tv", "payphone", "radio", "arcade", "crate", "door", "campfire", "secret"]:
		build_prop(kind)
	build_ui()
	build_background()
	quit()

func rect(img: Image, x: int, y: int, w: int, h: int, color: int) -> void:
	img.fill_rect(Rect2i(x, y, w, h), palette[color])

func save(img: Image, path: String) -> void:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	img.save_png(path)

func build_tiles() -> void:
	var img := Image.create(64, 16, false, Image.FORMAT_RGBA8)
	for tile in 4:
		var x := tile * 16
		rect(img, x, 0, 16, 16, 2 if tile != 3 else 10)
		rect(img, x, 0, 16, 3, 4 if tile < 2 else 9)
		rect(img, x, 3, 16, 1, 1)
		for y in range(6, 16, 5):
			rect(img, x, y, 16, 1, 1)
			rect(img, x + (4 if y % 2 == 0 else 11), y - 2, 1, 2, 3)
		if tile == 2:
			rect(img, x, 4, 16, 12, 1)
			rect(img, x + 2, 4, 2, 8, 7)
			rect(img, x + 12, 4, 2, 8, 7)
	save(img, "res://assets/tiles/test_tiles.png")

func build_prop(kind: String) -> void:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	rect(img, 3, 3, 26, 29, 0)
	rect(img, 4, 4, 24, 27, 7)
	rect(img, 4, 4, 23, 2, 9)
	match kind:
		"tv":
			rect(img, 5, 7, 20, 17, 2)
			rect(img, 6, 8, 17, 14, 14)
			rect(img, 7, 9, 15, 10, 17)
			rect(img, 25, 10, 2, 2, 9)
			rect(img, 25, 16, 2, 2, 9)
			rect(img, 7, 27, 3, 5, 0)
			rect(img, 23, 27, 3, 5, 0)
		"payphone":
			rect(img, 5, 6, 22, 24, 3)
			rect(img, 8, 8, 5, 12, 0)
			rect(img, 9, 20, 2, 6, 1)
			rect(img, 16, 7, 8, 4, 17)
			for y in range(14, 23, 3):
				for x in range(16, 24, 3):
					rect(img, x, y, 2, 2, 5)
		"arcade":
			rect(img, 5, 5, 22, 4, 13)
			rect(img, 6, 11, 20, 13, 0)
			rect(img, 8, 12, 16, 10, 17)
			rect(img, 5, 25, 22, 4, 2)
			rect(img, 10, 24, 2, 3, 0)
			rect(img, 19, 25, 2, 2, 26)
		"radio":
			img.fill(Color.TRANSPARENT)
			rect(img, 21, 0, 1, 12, 4)
			rect(img, 2, 12, 28, 20, 0)
			rect(img, 3, 13, 26, 18, 9)
			rect(img, 5, 15, 22, 4, 17)
			for y in range(22, 29, 2):
				rect(img, 5, y, 15, 1, 7)
			rect(img, 23, 23, 3, 3, 0)
		"door":
			rect(img, 6, 6, 20, 26, 1)
			rect(img, 8, 8, 16, 24, 2)
			rect(img, 20, 20, 2, 2, 13)
		"campfire":
			img.fill(Color.TRANSPARENT)
			rect(img, 3, 27, 26, 4, 7)
			rect(img, 9, 17, 14, 10, 11)
			rect(img, 12, 9, 8, 17, 12)
			rect(img, 14, 18, 4, 8, 13)
		"secret":
			img.fill(palette[2])
			for y in [8, 16, 24]:
				rect(img, 0, y, 32, 1, 1)
			rect(img, 14, 0, 1, 32, 1)
		_:
			rect(img, 7, 8, 18, 19, 8)
			rect(img, 14, 7, 3, 23, 7)
			rect(img, 5, 16, 22, 3, 7)
	save(img, "res://assets/props/%s.png" % kind)

func build_ui() -> void:
	for style in ["panel", "button", "focus"]:
		var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
		img.fill(palette[0])
		rect(img, 1, 1, 14, 14, 13 if style == "focus" else 3)
		rect(img, 2, 2, 12, 12, 1 if style == "panel" else 2)
		rect(img, 2, 2, 12, 1, 9)
		save(img, "res://assets/ui/%s.png" % style)
	var heart := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	rect(heart, 1, 1, 6, 4, 26)
	rect(heart, 2, 5, 4, 1, 26)
	rect(heart, 3, 6, 2, 1, 26)
	heart.set_pixel(3, 1, Color.TRANSPARENT)
	save(heart, "res://assets/ui/heart.png")
	var item := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	rect(item, 1, 1, 6, 7, 9)
	rect(item, 1, 1, 6, 1, 5)
	rect(item, 3, 3, 2, 4, 7)
	save(item, "res://assets/ui/item.png")

func build_background() -> void:
	var img := Image.create(640, 360, false, Image.FORMAT_RGBA8)
	img.fill(palette[18])
	rect(img, 0, 150, 640, 210, 1)
	for i in 15:
		var x := i * 48 - 20
		var top := 120 + (i * 29) % 75
		rect(img, maxi(0, x), top, 43, 210, 2)
		for y in range(top + 12, 300, 24):
			for wx in range(maxi(0, x) + 6, maxi(0, x) + 38, 12):
				rect(img, wx, y, 5, 10, 1)
	rect(img, 0, 304, 640, 56, 0)
	save(img, "res://assets/backgrounds/title.png")
