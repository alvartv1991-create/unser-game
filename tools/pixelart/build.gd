extends SceneTree
## Builds every .pxl file under res://assets into a PNG (plus a SpriteFrames .tres for @sprite files),
## and writes the palette files for drawing programs into docs/art/.
## Run from the project folder (see tools/pixelart/README.md):
##   "<godot>" --headless --path . --script res://tools/pixelart/build.gd
##   "<godot>" --headless --path . --script res://tools/pixelart/build.gd -- --file res://assets/sprites/characters/src/player.pxl
##   "<godot>" --headless --path . --script res://tools/pixelart/build.gd -- --lint
## Afterwards run "<godot>" --headless --path . --import so Godot picks up new or changed PNGs.

const Builder := preload("res://tools/pixelart/pixel_builder.gd")
const ASSETS_DIR := "res://assets"
const SKIP_LINT_DIRS: PackedStringArray = ["res://assets/fonts"]
const ART_DOCS_DIR := "res://docs/art"


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var palette := Builder.load_palette()
	var ok := true
	if args.has("--lint"):
		ok = _lint(palette)
	else:
		_write_palette_files()
		var files := PackedStringArray()
		var file_index := args.find("--file")
		if file_index >= 0 and file_index + 1 < args.size():
			files.append(args[file_index + 1])
		else:
			files = _find(ASSETS_DIR, ".pxl")
		print("Building %d sprite file(s)..." % files.size())
		for path in files:
			ok = _build(path, palette) and ok
	print("Done." if ok else "Finished with errors (see above).")
	quit(0 if ok else 1)


func _build(path: String, palette: Dictionary) -> bool:
	if not FileAccess.file_exists(path):
		printerr("  x %s: file not found" % path)
		return false
	var parsed := Builder.parse(FileAccess.get_file_as_string(path), palette, path)
	if not parsed.errors.is_empty():
		for message in parsed.errors:
			printerr("  x " + message)
		return false
	var rendered := Builder.render(parsed, palette, path.get_base_dir())
	if not rendered.errors.is_empty():
		for message in rendered.errors:
			printerr("  x %s: %s" % [path, message])
		return false
	# Sources in a "src" folder write their output one folder up (src/player.pxl -> player.png).
	var out_dir := path.get_base_dir()
	if out_dir.get_file() == "src":
		out_dir = out_dir.get_base_dir()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))
	var png_path := out_dir.path_join(parsed.name + ".png")
	rendered.image.save_png(png_path)
	var outputs := png_path
	if parsed.kind == "sprite":
		var tres_path := out_dir.path_join(parsed.name + ".tres")
		var text := Builder.spriteframes_tres(parsed, rendered.regions, png_path)
		text = _keep_uid(tres_path, text)
		var file := FileAccess.open(tres_path, FileAccess.WRITE)
		file.store_string(text)
		file.close()
		outputs += " + " + tres_path.get_file()
	print("  ok %s -> %s" % [path, outputs])
	return true


## Keeps the uid of an existing .tres, so scenes that reference it by uid stay happy.
func _keep_uid(tres_path: String, text: String) -> String:
	if not FileAccess.file_exists(tres_path):
		return text
	var header := FileAccess.get_file_as_string(tres_path).get_slice("\n", 0)
	var found := RegEx.create_from_string('uid="(uid://[a-z0-9]+)"').search(header)
	if found == null:
		return text
	return text.replace('format=3]', 'format=3 uid="%s"]' % found.get_string(1))


func _lint(palette: Dictionary) -> bool:
	var ok := true
	var files := _find(ASSETS_DIR, ".png")
	for path in files:
		if Array(SKIP_LINT_DIRS).any(func(dir: String) -> bool: return path.begins_with(dir)):
			continue
		var image := Image.load_from_file(ProjectSettings.globalize_path(path))
		if image == null or image.is_empty():
			continue
		image.convert(Image.FORMAT_RGBA8)
		var wrong := Builder.off_palette_pixels(image, palette)
		if wrong > 0:
			printerr("  x %s: %d pixel(s) not in the palette" % [path, wrong])
			ok = false
	print("Checked %d PNG(s) against the palette." % files.size())
	return ok


## docs/art/palette.png (swatches) and docs/art/unser_game.gpl (for Aseprite, LibreSprite, GIMP).
func _write_palette_files() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Builder.PALETTE_PATH))
	var colors: Array = data.colors
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(ART_DOCS_DIR))
	var swatch := 16
	var image := Image.create_empty(swatch * 8, swatch * ceili(colors.size() / 8.0), false, Image.FORMAT_RGBA8)
	var gpl := PackedStringArray(["GIMP Palette", "Name: " + str(data.name), "Columns: 8", "#"])
	for i in colors.size():
		var color := Color.html(str(colors[i].hex))
		image.fill_rect(Rect2i((i % 8) * swatch, (i / 8) * swatch, swatch, swatch), color)
		gpl.append("%3d %3d %3d\t%s (%s)" % [color.r8, color.g8, color.b8, colors[i].name, colors[i].char])
	image.save_png(ART_DOCS_DIR.path_join("palette.png"))
	var file := FileAccess.open(ART_DOCS_DIR.path_join("unser_game.gpl"), FileAccess.WRITE)
	file.store_string("\n".join(gpl) + "\n")
	file.close()


func _find(root: String, extension: String) -> PackedStringArray:
	var found := PackedStringArray()
	var dir := DirAccess.open(root)
	if dir == null:
		return found
	for sub in dir.get_directories():
		found.append_array(_find(root.path_join(sub), extension))
	for file in dir.get_files():
		if file.ends_with(extension):
			found.append(root.path_join(file))
	return found
