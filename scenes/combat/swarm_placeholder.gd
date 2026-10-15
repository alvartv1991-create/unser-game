extends Node2D
## Stand-in for Codex's swarm visual (scenes/fx/alien_swarm.tscn, H4): a cloud of small
## signal-colored shards drifting around. Same API: set_mood("idle"|"agitated"|"dispersed").
# TODO(H5): delete this once scenes/fx/alien_swarm.tscn exists (combat.gd already prefers it).

const SHARDS := 70
const COLORS := [Color("#3ff0f0"), Color("#127a8a"), Color("#ff4fd8"), Color("#8a1a7a")]

var _mood := "idle"
var _time := 0.0
var _shards: Array[Dictionary] = []
var _spread := 1.0


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1986
	for i in SHARDS:
		_shards.append({
			radius = rng.randf_range(6.0, 46.0),
			angle = rng.randf() * TAU,
			speed = rng.randf_range(0.6, 2.2) * (1 if rng.randf() < 0.5 else -1),
			wobble = rng.randf() * TAU,
			size = 2.0 if rng.randf() < 0.75 else 3.0,
			color = COLORS[i % COLORS.size()],
		})


func set_mood(mood: String) -> void:
	_mood = mood


func _process(delta: float) -> void:
	_time += delta
	var speed := 2.4 if _mood == "agitated" else 1.0
	if _mood == "dispersed":
		_spread = minf(_spread + delta * 1.5, 8.0)
		modulate.a = maxf(0.0, modulate.a - delta * 0.7)
	for shard in _shards:
		shard.angle += shard.speed * delta * speed
	queue_redraw()


func _draw() -> void:
	for shard in _shards:
		var wobble := sin(_time * 3.0 + shard.wobble) * 4.0
		var at := Vector2(cos(shard.angle) * shard.radius * 1.3, sin(shard.angle) * shard.radius * 0.8 + wobble)
		at = (at * _spread).round()
		draw_rect(Rect2(at - Vector2(0, 40), Vector2(shard.size, shard.size)), shard.color)
