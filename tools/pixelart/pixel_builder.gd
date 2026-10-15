class_name PixelBuilder
extends RefCounted
## Turns .pxl text sprites into PNG sheets and SpriteFrames (.tres). Pure functions, no file writing:
## build.gd does the I/O. Format and usage: tools/pixelart/README.md.

const PALETTE_PATH := "res://tools/pixelart/palette.json"
const KINDS: PackedStringArray = ["sprite", "image", "tiles"]
const TRANSPARENT := "."


## char -> Color, from palette.json.
static func load_palette(path: String = PALETTE_PATH) -> Dictionary:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	var palette := {}
	if data is Dictionary:
		for entry in data.get("colors", []):
			palette[str(entry.char)] = Color.html(str(entry.hex))
	return palette


## Parses .pxl text into:
## {kind, name, size: Vector2i, columns, anims: [{name, fps, loop, frames: [PackedStringArray], copy, png}], errors}
static func parse(text: String, palette: Dictionary, source: String = "<text>") -> Dictionary:
	var result := {kind = "", name = "", size = Vector2i.ZERO, columns = 8, anims = [], errors = PackedStringArray()}
	var anim: Dictionary = {}
	var frame := PackedStringArray()
	var line_number := 0
	for raw_line in text.split("\n"):
		line_number += 1
		var line := raw_line.trim_suffix("\r")
		var where := "%s:%d" % [source, line_number]
		if line.begins_with("#"):
			continue
		if line.strip_edges() == "":
			_end_frame(anim, frame, result, where)
			frame = PackedStringArray()
			continue
		if line.begins_with("@"):
			_end_frame(anim, frame, result, where)
			frame = PackedStringArray()
			var words := line.strip_edges().split(" ", false)
			match words[0]:
				"@sprite", "@image", "@tiles":
					result.kind = words[0].substr(1)
					result.name = words[1] if words.size() > 1 else ""
					if result.kind != "sprite":
						anim = _new_anim("frames")
						result.anims.append(anim)
				"@size":
					var parts := (words[1] if words.size() > 1 else "").split("x")
					if parts.size() == 2 and parts[0].is_valid_int() and parts[1].is_valid_int():
						result.size = Vector2i(int(parts[0]), int(parts[1]))
					else:
						result.errors.append(where + ": @size must look like 32x32")
				"@columns":
					result.columns = maxi(1, int(words[1])) if words.size() > 1 else 8
				"@anim" when result.kind != "sprite":
					result.errors.append(where + ": @anim only works in @sprite files")
				"@anim":
					anim = _new_anim(words[1] if words.size() > 1 else "")
					for option in words.slice(2):
						if option == "loop":
							anim.loop = true
						elif option == "once":
							anim.loop = false
						elif option.begins_with("fps="):
							anim.fps = float(option.substr(4))
						elif option.begins_with("copy="):
							anim.copy = option.substr(5)
						elif option.begins_with("png="):
							anim.png = option.substr(4)
						elif option.begins_with("from="):
							anim.from = option.substr(5)
						elif option.begins_with("rotate="):
							anim.rotate = option.substr(7)
						else:
							result.errors.append("%s: unknown option \"%s\"" % [where, option])
					result.anims.append(anim)
				_:
					result.errors.append("%s: unknown command %s" % [where, words[0]])
			continue
		# A grid row.
		if anim.is_empty():
			result.errors.append(where + ": pixels before @sprite/@image/@tiles or @anim")
			continue
		for character in line:
			if character != TRANSPARENT and character != " " and not palette.has(character):
				result.errors.append("%s: \"%s\" is not a palette letter (use . for transparent)" % [where, character])
				break
		frame.append(line)
	_end_frame(anim, frame, result, "%s:end" % source)

	if not KINDS.has(result.kind):
		result.errors.append(source + ": needs @sprite, @image or @tiles at the top")
	if result.name == "":
		result.errors.append(source + ": needs a name, e.g. @sprite player")
	if result.size == Vector2i.ZERO:
		result.errors.append(source + ": needs @size, e.g. @size 32x32")
	var names := {}
	for each in result.anims:
		names[each.name] = each
	for each in result.anims:
		if each.from != "":
			_resolve_from(each, names, result, source)
		if each.copy != "" and not names.has(each.copy):
			result.errors.append("%s: @anim %s copies unknown animation \"%s\"" % [source, each.name, each.copy])
		elif each.copy == "" and each.png == "" and each.frames.is_empty():
			result.errors.append("%s: @anim %s has no frames" % [source, each.name])
	return result


static func _new_anim(anim_name: String) -> Dictionary:
	return {name = anim_name, fps = 4.0, loop = true, frames = [], copy = "", png = "", from = "", rotate = ""}


## from=<anim>[:frame] takes one frame of another animation; rotate=cw|ccw turns it a quarter
## (e.g. a standing pose becomes a lying one). The result is moved down to stand on the bottom edge.
static func _resolve_from(anim: Dictionary, names: Dictionary, result: Dictionary, source: String) -> void:
	var parts: PackedStringArray = anim.from.split(":")
	var source_anim: Dictionary = names.get(parts[0], {})
	var index := int(parts[1]) if parts.size() > 1 else 0
	if source_anim.is_empty() or index >= source_anim.frames.size():
		result.errors.append("%s: @anim %s: from=%s has no such frame" % [source, anim.name, anim.from])
		return
	var grid: PackedStringArray = source_anim.frames[index]
	if anim.rotate != "":
		if result.size.x != result.size.y:
			result.errors.append("%s: @anim %s: rotate needs a square @size" % [source, anim.name])
			return
		if anim.rotate != "cw" and anim.rotate != "ccw":
			result.errors.append("%s: @anim %s: rotate must be cw or ccw" % [source, anim.name])
			return
		grid = _drop_to_bottom(_rotate(grid, anim.rotate == "cw"))
	anim.frames.append(grid)


static func _rotate(grid: PackedStringArray, clockwise: bool) -> PackedStringArray:
	var n := grid.size()
	var rotated := PackedStringArray()
	for new_y in n:
		var row := ""
		for new_x in n:
			row += grid[n - 1 - new_x][new_y] if clockwise else grid[new_x][n - 1 - new_y]
		rotated.append(row)
	return rotated


static func _drop_to_bottom(grid: PackedStringArray) -> PackedStringArray:
	var empty_rows := 0
	for i in range(grid.size() - 1, -1, -1):
		if grid[i].replace(TRANSPARENT, "").replace(" ", "") != "":
			break
		empty_rows += 1
	if empty_rows == 0:
		return grid
	var dropped := grid.slice(grid.size() - empty_rows)
	dropped.append_array(grid.slice(0, grid.size() - empty_rows))
	return dropped


## Validates and pads a finished frame: rows padded on the right, missing rows added on TOP
## (so short sprites stand on the bottom edge).
static func _end_frame(anim: Dictionary, frame: PackedStringArray, result: Dictionary, where: String) -> void:
	if frame.is_empty() or anim.is_empty():
		return
	var size: Vector2i = result.size
	if frame.size() > size.y:
		result.errors.append("%s: frame has %d rows, more than the height %d" % [where, frame.size(), size.y])
		return
	var padded := PackedStringArray()
	for i in size.y - frame.size():
		padded.append(TRANSPARENT.repeat(size.x))
	for row in frame:
		if row.length() > size.x:
			result.errors.append("%s: a row has %d pixels, more than the width %d" % [where, row.length(), size.x])
			return
		padded.append(row + TRANSPARENT.repeat(size.x - row.length()))
	anim.frames.append(padded)


## Renders the sheet. Returns {image: Image, regions: {anim_name: [Rect2i]}, errors}.
## base_dir is used to find png= strips.
static func render(parsed: Dictionary, palette: Dictionary, base_dir: String = "") -> Dictionary:
	var size: Vector2i = parsed.size
	var errors := PackedStringArray()
	var regions := {}
	# Gather the frames of each real (non-copy) animation as Images.
	var rows: Array = []  # [{name, images: [Image]}]
	for anim in parsed.anims:
		if anim.copy != "":
			continue
		var images: Array[Image] = []
		if anim.png != "":
			images = _split_strip(base_dir.path_join(anim.png), size, errors)
		for grid in anim.frames:
			images.append(_grid_to_image(grid, size, palette))
		rows.append({name = anim.name, images = images})

	var sheet: Image
	if parsed.kind == "tiles":
		var all_images: Array[Image] = []
		for row in rows:
			all_images.append_array(row.images)
		var columns := mini(int(parsed.columns), maxi(all_images.size(), 1))
		var row_count := ceili(all_images.size() / float(columns))
		sheet = Image.create_empty(size.x * columns, size.y * maxi(row_count, 1), false, Image.FORMAT_RGBA8)
		var tile_regions: Array[Rect2i] = []
		for i in all_images.size():
			var at := Vector2i((i % columns) * size.x, (i / columns) * size.y)
			sheet.blit_rect(all_images[i], Rect2i(Vector2i.ZERO, size), at)
			tile_regions.append(Rect2i(at, size))
		regions["frames"] = tile_regions
	else:
		var widest := 1
		for row in rows:
			widest = maxi(widest, row.images.size())
		sheet = Image.create_empty(size.x * widest, size.y * maxi(rows.size(), 1), false, Image.FORMAT_RGBA8)
		for y in rows.size():
			var row_regions: Array[Rect2i] = []
			for x in rows[y].images.size():
				var at := Vector2i(x * size.x, y * size.y)
				sheet.blit_rect(rows[y].images[x], Rect2i(Vector2i.ZERO, size), at)
				row_regions.append(Rect2i(at, size))
			regions[rows[y].name] = row_regions
		for anim in parsed.anims:
			if anim.copy != "":
				regions[anim.name] = regions.get(anim.copy, [])
	return {image = sheet, regions = regions, errors = errors}


static func _grid_to_image(grid: PackedStringArray, size: Vector2i, palette: Dictionary) -> Image:
	var image := Image.create_empty(size.x, size.y, false, Image.FORMAT_RGBA8)
	for y in grid.size():
		var row := grid[y]
		for x in row.length():
			var character := row[x]
			if palette.has(character):
				image.set_pixel(x, y, palette[character])
	return image


static func _split_strip(path: String, size: Vector2i, errors: PackedStringArray) -> Array[Image]:
	var frames: Array[Image] = []
	var strip := Image.load_from_file(ProjectSettings.globalize_path(path))
	if strip == null or strip.is_empty():
		errors.append("cannot read PNG strip " + path)
		return frames
	strip.convert(Image.FORMAT_RGBA8)
	for i in strip.get_width() / size.x:
		frames.append(strip.get_region(Rect2i(i * size.x, 0, size.x, size.y)))
	return frames


## SpriteFrames resource as .tres text, pointing at the sheet PNG (no import needed to write it).
## Adds a "default" animation (same frames as the first one) so AnimatedSprite2D never complains.
static func spriteframes_tres(parsed: Dictionary, regions: Dictionary, png_path: String) -> String:
	var sub_ids := {}  # "x,y" -> sub-resource id, so copies reuse the same AtlasTextures
	var subs := PackedStringArray()
	var anim_texts := PackedStringArray()
	var order: Array = parsed.anims.duplicate()
	if not order.is_empty() and not order.any(func(a: Dictionary) -> bool: return a.name == "default"):
		var first: Dictionary = order[0].duplicate()
		first.name = "default"
		first.copy = order[0].name
		order.push_front(first)
	for anim in order:
		var source_name: String = anim.name if regions.has(anim.name) else anim.copy
		var frame_texts := PackedStringArray()
		for rect in regions.get(source_name, []):
			var key := "%d,%d" % [rect.position.x, rect.position.y]
			if not sub_ids.has(key):
				sub_ids[key] = "AtlasTexture_%d" % sub_ids.size()
				subs.append('[sub_resource type="AtlasTexture" id="%s"]\natlas = ExtResource("1_sheet")\nregion = Rect2(%d, %d, %d, %d)\n'
					% [sub_ids[key], rect.position.x, rect.position.y, rect.size.x, rect.size.y])
			frame_texts.append('{\n"duration": 1.0,\n"texture": SubResource("%s")\n}' % sub_ids[key])
		anim_texts.append('{\n"frames": [%s],\n"loop": %s,\n"name": &"%s",\n"speed": %s\n}'
			% [", ".join(frame_texts), "true" if anim.loop else "false", anim.name, str(float(anim.fps))])
	return '[gd_resource type="SpriteFrames" format=3]\n\n[ext_resource type="Texture2D" path="%s" id="1_sheet"]\n\n%s\n[resource]\nanimations = [%s]\n' % [
		png_path, "\n".join(subs), ", ".join(anim_texts)]


## Counts visible pixels whose color is not in the palette (alpha 0 is ignored).
static func off_palette_pixels(image: Image, palette: Dictionary) -> int:
	var allowed := {}
	for color in palette.values():
		allowed[Color(color, 1.0).to_rgba32()] = true
	var count := 0
	for y in image.get_height():
		for x in image.get_width():
			var pixel := image.get_pixel(x, y)
			if pixel.a > 0.0 and not allowed.has(Color(pixel, 1.0).to_rgba32()):
				count += 1
	return count
