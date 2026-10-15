extends Node2D
## Non-humanoid machine shards. Origin remains at the fighter's feet.
const SHARD_COUNT := 48
var mood: String = "idle"
var time: float = 0.0
var spread: float = 1.0
var shards: Array[Vector4] = []

func _ready() -> void:
	var random := RandomNumberGenerator.new()
	random.seed = 1984
	for i in SHARD_COUNT:
		shards.append(Vector4(random.randf() * TAU, random.randf_range(8, 40), random.randf_range(0.3, 0.9), random.randf() * TAU))

func set_mood(value: String) -> void:
	mood = value if value in ["idle", "agitated", "dispersed"] else "idle"
	if mood != "dispersed":
		spread = 1.0
		modulate.a = 1.0

func _process(delta: float) -> void:
	var ui := get_tree().get_first_node_in_group("global_ui") as WorldUI
	var reduced: bool = ui != null and ui.settings.get_value("display", "reduce_effects", false)
	time += delta * (0.25 if reduced else (1.7 if mood == "agitated" else 0.65))
	if mood == "dispersed":
		spread += delta * 1.5
		modulate.a = maxf(0.0, modulate.a - delta * 0.7)
	queue_redraw()

func _draw() -> void:
	for i in shards.size():
		var shard := shards[i]
		var phase := shard.x + time * shard.z
		var cluster := Vector2(cos(i % 3 * TAU / 3), sin(i % 3 * TAU / 3)) * (10 + 8 * sin(time * 0.7))
		var at := (Vector2(cos(phase) * shard.y, sin(phase) * shard.y * 0.65) + cluster) * spread
		at = (at + Vector2(0, -43)).round()
		var width := 4 + i % 4
		var outline := PackedVector2Array([at + Vector2(-width, 0), at + Vector2(-2, -3), at + Vector2(width, -2), at + Vector2(width - 1, 2), at + Vector2(-3, 3)])
		draw_colored_polygon(outline, Color("14101a"))
		draw_line(at + Vector2(-width + 1, 0), at + Vector2(width - 1, -1), Color("77727a"), 2)
		draw_line(at + Vector2(-2, -2), at + Vector2(width - 2, -2), Color("9db4c4"), 1)
		draw_line(at + Vector2(-2, 1), at + Vector2(2, 1), Color("3ff0f0") if i % 5 else Color("ff4fd8"), 1)
