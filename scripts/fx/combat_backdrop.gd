extends Node2D
## Uses the project's own streetscape at native pixel size behind the combat UI.
var alien: bool = false
var layers: Array[Texture2D] = []
var road: Texture2D

func _ready() -> void:
	for id in ["sky", "distance", "world"]:
		layers.append(load("res://assets/backgrounds/street_%s.png" % id) as Texture2D)
	road = layers[2]
	queue_redraw()

func set_alien(active: bool) -> void:
	alien = active
	queue_redraw()

func _draw() -> void:
	for texture in layers:
		draw_texture_rect_region(texture, Rect2(0, -120, 640, 360), Rect2(0, 0, 640, 360))
	draw_rect(Rect2(0, 0, 640, 236), Color(0.04, 0.05, 0.10, 0.48))
	if road:
		for y in [88, 148, 208]:
			draw_texture_rect_region(road, Rect2(0, y, 640, 60), Rect2(0, 295, 640, 60), Color(0.58, 0.65, 0.8))
	draw_line(Vector2(0, 86), Vector2(640, 86), Color("4a4552"), 2)
	draw_line(Vector2(0, 88), Vector2(640, 88), Color("14101a"), 1)
	if alien:
		# Only appears inside an explicitly started alien fight, never in the opening.
		draw_rect(Rect2(0, 0, 640, 236), Color(0.08, 0.02, 0.12, 0.22))
		for i in 12:
			var at := Vector2(340 + i * 23, 105 + (i * 13) % 110)
			draw_line(at, at + Vector2(7, 0), Color("127a8a"), 1)
