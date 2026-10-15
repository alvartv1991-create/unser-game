extends TestCase

const SPRITE := """# test sprite
@sprite dummy
@size 4x4

@anim idle fps=2 loop
.00.
0tt0
0tt0

.00.
0vv0
0vv0
.00.

@anim hurt copy=idle once
"""


func test_parse_pads_rows_and_reads_animations() -> void:
	var parsed := PixelBuilder.parse(SPRITE, PixelBuilder.load_palette(), "dummy")
	assert_eq(parsed.errors.size(), 0, "no errors: " + "; ".join(parsed.errors))
	assert_eq(parsed.size, Vector2i(4, 4), "size")
	assert_eq(parsed.anims.size(), 2, "two animations")
	var first: PackedStringArray = parsed.anims[0].frames[0]
	assert_eq(first.size(), 4, "short frame padded to 4 rows")
	assert_eq(first[0], "....", "padding goes on top")
	assert_eq(parsed.anims[1].copy, "idle", "copy animation")


func test_render_sheet_size_and_colors() -> void:
	var palette := PixelBuilder.load_palette()
	var parsed := PixelBuilder.parse(SPRITE, palette, "dummy")
	var rendered := PixelBuilder.render(parsed, palette)
	var image: Image = rendered.image
	assert_eq(image.get_size(), Vector2i(8, 4), "2 frames side by side, 1 row (copies get no row)")
	assert_eq(image.get_pixel(0, 0).a, 0.0, "transparent pixel")
	assert_eq(image.get_pixel(1, 2).to_html(false), palette["t"].to_html(false), "frame 1 uses signal cyan")
	assert_eq(image.get_pixel(5, 1).to_html(false), palette["v"].to_html(false), "frame 2 uses signal magenta")
	assert_eq(rendered.regions.hurt, rendered.regions.idle, "copy shares regions")
	assert_eq(PixelBuilder.off_palette_pixels(image, palette), 0, "only palette colors")


func test_spriteframes_text_has_all_animations() -> void:
	var palette := PixelBuilder.load_palette()
	var parsed := PixelBuilder.parse(SPRITE, palette, "dummy")
	var text := PixelBuilder.spriteframes_tres(parsed, PixelBuilder.render(parsed, palette).regions, "res://dummy.png")
	for anim_name in ["default", "idle", "hurt"]:
		assert_true(text.contains('&"%s"' % anim_name), "animation " + anim_name)
	assert_eq(text.count('[sub_resource type="AtlasTexture"'), 2, "copies reuse atlas textures")


func test_from_rotate_turns_and_drops_frame() -> void:
	var text := "@sprite x\n@size 4x4\n@anim idle\n.0..\n.0..\n.0..\n.5..\n@anim downed from=idle rotate=ccw\n"
	var parsed := PixelBuilder.parse(text, PixelBuilder.load_palette(), "rot")
	assert_eq(parsed.errors.size(), 0, "no errors: " + "; ".join(parsed.errors))
	var lying: PackedStringArray = parsed.anims[1].frames[0]
	assert_eq(lying[3], "0005", "standing column became the bottom row, feet (5) to the right")
	assert_eq(lying[0], "....", "empty rows moved to the top")


func test_bad_input_is_reported() -> void:
	var parsed := PixelBuilder.parse("@sprite x\n@size 2x2\n@anim a\nZZ\n", PixelBuilder.load_palette(), "bad")
	assert_true("\n".join(parsed.errors).contains("not a palette letter"), "unknown letter reported")
	var too_big := PixelBuilder.parse("@sprite x\n@size 2x2\n@anim a\n...\n", PixelBuilder.load_palette(), "big")
	assert_true("\n".join(too_big.errors).contains("more than the width"), "too wide reported")
