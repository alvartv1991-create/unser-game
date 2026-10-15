extends Control
## "Karte / Map" after the gate: Area 1 is explored, Area 2 is "coming soon".
## Choosing Area 2 plays gate:coming_soon, then the end-of-alpha summary.

const VORSTADT := "res://scenes/levels/area1_vorstadt.tscn"
const ALPHA_END := "res://scenes/ui/alpha_end.tscn"

var _going_on := false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var backdrop := ColorRect.new()
	backdrop.color = Color("1c2238")
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	var map := Control.new()
	map.set_anchors_preset(Control.PRESET_FULL_RECT)
	map.draw.connect(_draw_map.bind(map))
	add_child(map)
	EventBus.locale_changed.connect(func(_l: String) -> void: _build())
	EventBus.dialogue_finished.connect(_on_dialogue_finished)
	_build()


func _build() -> void:
	for child in get_children():
		if child.has_meta("ui"):
			child.queue_free()
	var column := UiKit.panel(self, Rect2(366, 24, 254, 312))
	column.get_parent().set_meta("ui", true)
	UiKit.label(tr("AREA_MAP_TITLE"), column)
	var area1 := UiKit.button("", column, func() -> void: SceneRouter.go_to(VORSTADT, "from_gate"))
	area1.text = tr("AREA_MAP_AREA1")
	var area2 := UiKit.button("", column, _area2)
	area2.text = tr("AREA_MAP_AREA2")
	area2.disabled = not GameState.get_flag("area2_unlocked", false)
	UiKit.focus_first(column.get_parent())


func _area2() -> void:
	if DialogueRunner.is_running():
		return
	_going_on = true
	DialogueRunner.start("res://dialogue/area1/gate.dialogue", "coming_soon")


func _on_dialogue_finished(_file: String, title: String) -> void:
	if _going_on and title == "coming_soon":
		_going_on = false
		SceneRouter.go_to(ALPHA_END)


## A pixel map: the suburb (explored) and a fogged area 2 behind a dashed road.
func _draw_map(canvas: Control) -> void:
	canvas.draw_rect(Rect2(24, 24, 330, 312), Color("2b2532"))
	canvas.draw_rect(Rect2(24, 24, 330, 312), Color("4a4552"), false, 2)
	for i in 30:
		canvas.draw_rect(Rect2(40 + (i * 37) % 290, 40 + (i * 53) % 280, 6, 4), Color("344a6b"))
	# Area 1: little houses.
	for i in 6:
		canvas.draw_rect(Rect2(60 + i * 16, 230 - (i % 3) * 10, 12, 18 + (i % 3) * 10), Color("8e3b2b"))
		canvas.draw_rect(Rect2(63 + i * 16, 236 - (i % 3) * 10, 4, 4), Color("e0a94a"))
	canvas.draw_rect(Rect2(56, 256, 110, 3), Color("a8a3a6"))
	# The road east, dashed, to the fog of area 2.
	for x in range(170, 260, 12):
		canvas.draw_rect(Rect2(x, 257, 7, 2), Color("e3dccb"))
	canvas.draw_rect(Rect2(260, 120, 80, 150), Color("4a4552"))
	for i in 20:
		canvas.draw_rect(Rect2(262 + (i * 13) % 74, 124 + (i * 29) % 140, 10, 6), Color("77727a"))
	canvas.draw_string(get_theme_default_font(), Vector2(286, 200), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color("e3dccb"))
