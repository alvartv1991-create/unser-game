extends TestCase
## The art guide asks for readable silhouettes: no two characters may share the same idle outline,
## and every character stands on the bottom row of its 32x32 frame.

const IDS := ["player", "cook", "tinkerer", "clerk", "cultist", "raider_scavenger", "raider_brute"]


func _idle_image(id: String) -> Image:
	var frames := load("res://assets/sprites/characters/%s.tres" % id) as SpriteFrames
	if frames == null or not frames.has_animation("idle"):
		return null
	var atlas := frames.get_frame_texture("idle", 0) as AtlasTexture
	if atlas == null:
		return null
	return atlas.atlas.get_image().get_region(Rect2i(atlas.region))


func _mask(image: Image) -> PackedByteArray:
	var bits := PackedByteArray()
	for y in image.get_height():
		for x in image.get_width():
			bits.append(1 if image.get_pixel(x, y).a > 0.5 else 0)
	return bits


func test_every_character_has_its_own_silhouette() -> void:
	var seen: Dictionary = {}   # mask -> character id
	for id: String in IDS:
		var image := _idle_image(id)
		assert_true(image != null, id + ": idle frame loads")
		if image == null:
			continue
		var mask := _mask(image)
		assert_false(seen.has(mask), "%s has the same idle silhouette as %s" % [id, seen.get(mask, "")])
		seen[mask] = id


func test_feet_are_on_the_bottom_row() -> void:
	for id: String in IDS:
		var image := _idle_image(id)
		if image == null:
			fail(id + ": idle frame missing")
			continue
		assert_eq(image.get_size(), Vector2i(32, 32), id + ": frame size")
		var bottom := 0
		for x in 32:
			if image.get_pixel(x, 31).a > 0.5:
				bottom += 1
		assert_true(bottom > 0, id + ": feet touch the bottom row")
