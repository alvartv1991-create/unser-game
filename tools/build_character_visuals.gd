extends SceneTree
## Human-authorized visual refresh of the H1 character art; no combat-rule changes.
## Sources remain editable .pxl files and retain the established 32x32 contract.
const Builder := preload("res://tools/pixelart/pixel_builder.gd")
const IDS := ["player", "cook", "tinkerer", "clerk", "cultist", "raider_scavenger", "raider_brute"]
## Emotional portrait variants for the main cast: assets/portraits/<id>_<mood>.png ([#mood=happy] in dialogue).
const MOODS := {"player": ["happy", "sad"], "cook": ["happy", "sad"], "tinkerer": ["happy", "sad"]}
var palette: Dictionary

func _initialize() -> void:
	palette = Builder.load_palette()
	for id: String in IDS:
		build_character(id)
		build_portrait(id)
		for mood: String in MOODS.get(id, []):
			build_portrait(id, mood)
	quit()

func blank(size: int = 32) -> Array[String]:
	var rows: Array[String] = []
	for i in size:
		rows.append(".".repeat(size))
	return rows

func stamp(rows: Array[String], pixels: Array, at: Vector2i) -> void:
	for y in pixels.size():
		for x in str(pixels[y]).length():
			var pixel: String = str(pixels[y])[x]
			if pixel != "." and at.y + y >= 0 and at.y + y < rows.size() and at.x + x >= 0 and at.x + x < rows[0].length():
				rows[at.y + y][at.x + x] = pixel

func fill(rows: Array[String], box: Rect2i, color: String) -> void:
	for y in range(maxi(0, box.position.y), mini(rows.size(), box.end.y)):
		for x in range(maxi(0, box.position.x), mini(rows[0].length(), box.end.x)):
			rows[y][x] = color

func head(id: String) -> Array:
	# Shared three-quarter construction, individual hair/hat/glasses silhouettes.
	var rows: Array = [
		"....000000....",
		"...067777700..",
		"..06778877770.",
		".0677877777770",
		".067777ooooo70",
		".06777ooo0ooo0",
		".0677oo5o05oo0",
		"..07nooo0o0oo0",
		"..00nnooooooo0",
		"...0nnnooomo0.",
		"....0nnnnno0..",
		".....00nn00...",
	]
	if id == "cook":
		rows[0] = "...00000000..."
		rows[1] = "..0455555540.."
		rows[2] = ".045555555540."
		rows[3] = ".044444444440."
		rows[4] = ".077777oooo70."
	elif id == "tinkerer":
		rows[1] = "..0067777700.."
		rows[2] = ".067788777770."
		rows[6] = ".0770044044000"
		rows[7] = ".077no40o040o0"
		rows[8] = "..07nnooooooo0"
	elif id == "clerk":
		# Hair bun at the back of the head, so the clerk is not a recolored protagonist.
		rows[1] = "...066666600.."
		rows[2] = "0006777776660."
		rows[3] = "06677776666660"
		rows[4] = "0667777ooooo70"
		rows[5] = "006777ooo0ooo0"
	elif id == "cultist":
		# Pointed hood with the face in its shadow: the only figure without a visible hairline.
		rows = [
			"...00000000...",
			"..01pppppppp0.",
			".01pppppppppp0",
			".01pppp1111pp0",
			"01ppppp1mmmmp0",
			"01pppp1mmnnnp0",
			"01pppp1mn0n0p0",
			"01pppp1mnnnnp0",
			"01ppppp1mmmp10",
			".01pppppppppp0",
			".01ppppppppp0.",
			"..0011111100..",
		]
	elif id == "raider_scavenger":
		rows[0] = "...00000000..."
		rows[1] = "..0efffffef0.."
		rows[2] = ".0efggfffef0.."
		rows[3] = ".0effffffffff0"
		rows[9] = "...0nmmmmmmo0."
	elif id == "raider_brute":
		# Shaved head with a rust mohawk: reads as the brute at a glance, even next to the scavengers.
		rows = [
			".....00000....",
			"....0cccb0....",
			"..000cbbb000..",
			".0onnnbbnnnnn0",
			".0onnnnooooon0",
			".0nnnnooo0ooo0",
			".0nnnoo5o05oo0",
			"..0nnooo0o0oo0",
			"..00nnoooomoo0",
			"...0mmmmmmmo0.",
			"....0nnnnno0..",
			".....00nn00...",
		]
	return rows

## Changes the face of a head template: a smile and blush (happy), or a frown, lowered brows and a tear (sad).
func with_mood(rows: Array, mood: String) -> Array:
	var out: Array = rows.duplicate()
	var put := func(row: int, col: int, color: String) -> void:
		out[row] = str(out[row]).substr(0, col) + color + str(out[row]).substr(col + 1)
	if mood == "happy":
		put.call(8, 8, "m")
		put.call(8, 12, "m")
		for col in [9, 10, 11]:
			put.call(9, col, "m")
		put.call(8, 6, "r")
	elif mood == "sad":
		put.call(9, 10, "o")
		put.call(8, 10, "m")
		put.call(9, 9, "m")
		put.call(9, 11, "m")
		put.call(5, 8, "0")
		put.call(7, 11, "l")
	return out


func body(id: String) -> Array:
	var rows: Array = [
		".00jjjjjj00.", "0jkkjqqqjjj0", "0jkjjqqqjij0", "0jkjjqqqjij0",
		"0jijjqqqjij0", "0jijjqqqjij0", "0jijjjjjjij0", "0njjj7777jn0",
		"0n0jj22220n0", ".0022222200.", "..02222220..",
	]
	if id == "cook":
		rows = [".0055555500.", "0455q5555540", "04545qq55440", "044450554440", "04n555554n40", "04n555554n40", "01n555554n10", "0nn455554nn0", "0n04555540n0", ".0022222200.", "..02222220.."]
	elif id == "tinkerer":
		rows = [".00fffff00..", "0fggfjjjfff0", "0fgffjjjfef0", "0fgffjjjfef0", "0fefjjjjfef0", "0fefj44jfef0", "0fefj04jfef0", "0nf777777fn0", "0n0f2222f0n0", ".0022222200.", "..02222220.."]
	elif id == "clerk":
		for i in rows.size():
			rows[i] = str(rows[i]).replace("j", "p").replace("k", "2").replace("q", "r")
	elif id == "cultist":
		rows = [".001pppp100.", "01pp2ppp1p10", "01pppppp1p10", "01pppppp1p10", "01pppppp1p10", "01pp7pp71p10", "01pp77771p10", "01nppppp1n10", "01nppppp1n10", ".01pppppp10.", "..01111110.."]
	elif id == "raider_scavenger":
		for i in rows.size():
			rows[i] = str(rows[i]).replace("j", "f").replace("k", "g").replace("q", "7")
	elif id == "raider_brute":
		# 16 px wide with scrap-metal shoulder pads and bare arms: the widest figure in the cast.
		rows = [".0000bbbbbb0000.", "0344bbbcc1bbb440", "0333bbcbb1bbb330", "0nn0cbbb1bbc0nn0", "0nn0cbbb1bbc0nn0", "0nm0bbbb1bbb0mn0", "0nm07bbb1bb70mn0", "0mn0777777770nm0", "0nn0022222200nn0", ".00002222220000.", "....02222220...."]
	return rows

func robe(step: int) -> Array:
	# The cultist's robe covers the legs down to the ankles; the hem sways one pixel while walking.
	var rows: Array = ["01pppppppp10", "01pppppppp10", "01ppppppppp10", "01ppppppppp10", "01pppppppppp10", "00111111111100"]
	# Shift the hem (step 1) or the upper robe (step 3) one pixel right; the other part stays put.
	var shifted := [4, 5] if step % 4 == 1 else ([0, 1, 2, 3] if step % 4 == 3 else [])
	for i: int in shifted:
		rows[i] = "." + str(rows[i])
	return rows

func frame(id: String, pose: String, step: int = 0) -> Array[String]:
	var rows := blank()
	var bob := -1 if pose in ["walk", "idle", "combat_idle"] and step % 2 == 1 else 0
	stamp(rows, head(id), Vector2i(8, 1 + bob))
	stamp(rows, body(id), Vector2i(7 if id == "raider_brute" else 9, 13 + bob))
	var legs: Array = ["02222022220", "02222022220", "02220.22220", "01220.22210", "01210.21210", "0110..0110.", "0550..05550", "0000..00000"]
	if pose == "walk":
		if step % 4 == 1:
			legs = ["02222022220", "02220.22220", "01220..2220", "01210...2210", "0110....2110", "0550....0550", "0000....05550", "........00000"]
		elif step % 4 == 3:
			legs = ["02222022220", "022220.2220", ".02220.2210", "..022202210", "...0110110", "...0550550", "..05550000", "..0000...."]
	if pose == "jump":
		legs = ["02222022220", "01222022210", ".012222210.", "..0110110..", "..0550550..", "..0000000.."]
	if pose == "fall":
		legs = ["02222022220", "02220.22220", "01220..2210", "01210..2110", "0110...0110", "0550...0550", "0000...05550", ".......00000"]
	stamp(rows, legs, Vector2i(10, 24))
	if id == "cultist" and pose != "jump":
		stamp(rows, robe(step if pose == "walk" else 0), Vector2i(9, 24))
	elif id == "cultist":
		stamp(rows, robe(0).slice(0, 4), Vector2i(9, 24))
	var sleeve := "j" if id == "player" else ("5" if id == "cook" else ("f" if id in ["tinkerer", "raider_scavenger"] else ("b" if id == "raider_brute" else "p")))
	if pose == "attack":
		stamp(rows, ["00000000", sleeve.repeat(5) + "nno", sleeve.repeat(4) + "nno0", "00000000"], Vector2i(21, 16 - step % 2))
	elif pose == "skill":
		stamp(rows, ["000", "0n0", "0o0", "0n0", "0" + sleeve + "0", "0" + sleeve + "0", "0" + sleeve + "0", "0" + sleeve + "0", "0" + sleeve + "0"], Vector2i(22, 8))
	elif pose == "combat_idle":
		stamp(rows, ["0000", "0oo0", "0nn0", "0" + sleeve.repeat(2) + "0", "0" + sleeve.repeat(2) + "0", "0000"], Vector2i(20, 17 - step))
	elif pose == "hurt":
		fill(rows, Rect2i(19, 7, 3, 1), "0")
	return rows

func build_character(id: String) -> void:
	var source := "# Original visual refresh authorized by the humans. All character designs remain [TEMP].\n@sprite %s\n@size 32x32\n\n" % id
	for config: Array in [["idle", 2, 3], ["walk", 4, 8], ["jump", 1, 8], ["fall", 1, 8], ["combat_idle", 2, 4], ["attack", 3, 10], ["skill", 2, 8], ["hurt", 1, 6]]:
		source += "@anim %s fps=%d %s\n" % [config[0], config[2], "loop" if config[0] in ["idle", "walk", "combat_idle"] else "once"]
		for step in int(config[1]):
			source += "\n".join(frame(id, config[0], step)) + "\n\n"
	source += "@anim downed from=idle:0 rotate=cw once\n"
	var path := "res://assets/sprites/characters/src/%s.pxl" % id
	write(path, source)
	build_source(path, source)

func build_portrait(id: String, mood: String = "") -> void:
	var rows := blank(64)
	fill(rows, Rect2i(0, 0, 64, 64), "i")
	for y in range(6, 63):
		fill(rows, Rect2i(4, y, 1, 1), "j" if y % 4 else "i")
	# Two-pixel portrait clusters, then extra one-pixel material highlights.
	var h := with_mood(head(id), mood)
	for y in h.size():
		for x in str(h[y]).length():
			if str(h[y])[x] != ".":
				fill(rows, Rect2i(10 + x * 3, 2 + y * 3, 3, 3), str(h[y])[x])
	var b := body(id)
	for y in range(39, 64):
		var spread := mini(28, 12 + (y - 39))
		fill(rows, Rect2i(32 - spread, y, spread * 2, 1), "0")
		fill(rows, Rect2i(33 - spread, y, spread * 2 - 2, 1), "j" if id == "player" else ("5" if id == "cook" else ("f" if id in ["tinkerer", "raider_scavenger"] else ("b" if id == "raider_brute" else "p"))))
	for y in b.size():
		for x in str(b[y]).length():
			if str(b[y])[x] != ".":
				fill(rows, Rect2i(13 + x * 3, 40 + y * 3, 3, 3), str(b[y])[x])
	# The hood keeps the cultist's neck in shadow.
	fill(rows, Rect2i(28, 36, 10, 7), "1" if id == "cultist" else "n")
	fill(rows, Rect2i(28, 36, 10, 2), "0" if id == "cultist" else "m")
	if id == "player":
		fill(rows, Rect2i(25, 46, 3, 18), "k")
		fill(rows, Rect2i(39, 46, 2, 18), "i")
		fill(rows, Rect2i(28, 46, 9, 2), "r")
	var name := id if mood == "" else "%s_%s" % [id, mood]
	var source := "# [TEMP] Visual portrait; matches the world sprite, no fixed character identity implied.\n@image %s\n@size 64x64\n\n%s\n" % [name, "\n".join(rows)]
	var path := "res://assets/portraits/src/%s.pxl" % name
	write(path, source)
	build_source(path, source)

func write(path: String, source: String) -> void:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	FileAccess.open(path, FileAccess.WRITE).store_string(source)

func build_source(path: String, source: String) -> void:
	var parsed := Builder.parse(source, palette, path)
	if not parsed.errors.is_empty():
		push_error(str(parsed.errors))
		quit(1)
		return
	var result := Builder.render(parsed, palette, path.get_base_dir())
	if not result.errors.is_empty():
		push_error(str(result.errors))
		quit(1)
		return
	var png_path := path.get_base_dir().get_base_dir().path_join(parsed.name + ".png")
	result.image.save_png(png_path)
	if parsed.kind == "sprite":
		var tres_path := png_path.get_basename() + ".tres"
		var text := Builder.spriteframes_tres(parsed, result.regions, png_path)
		if FileAccess.file_exists(tres_path):
			var old := FileAccess.get_file_as_string(tres_path).get_slice("\n", 0)
			var found := RegEx.create_from_string('uid="(uid://[a-z0-9]+)"').search(old)
			if found:
				text = text.replace('format=3]', 'format=3 uid="%s"]' % found.get_string(1))
		write(tres_path, text)
