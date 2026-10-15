extends CanvasLayer
## F1 debug menu (debug builds only). Lists every test_*.tscn under res://scenes/,
## prepares a test playthrough, switches the language and shows data errors.

const TEST_ITEMS := {"bandage": 3, "canned_food": 2, "jammer": 1, "holy_sword": 1}

var _job_picker: OptionButton
var _companion_boxes: Dictionary = {}
var _moral_input: SpinBox
var _items_box: CheckBox
var _status: Label


func _ready() -> void:
	layer = 120
	process_mode = Node.PROCESS_MODE_ALWAYS
	var box := DebugUi.panel(self)

	var header := HBoxContainer.new()
	header.add_child(DebugUi.label("Debug-Menü  (F1 schließt)", Color("#3ff0f0")))
	header.add_child(DebugUi.button("DE", DebugUi.set_locale.bind("de")))
	header.add_child(DebugUi.button("EN", DebugUi.set_locale.bind("en")))
	box.add_child(header)

	if not Data.errors.is_empty():
		var shown := Data.errors.slice(0, 6)
		var more := "" if Data.errors.size() <= 6 else "\n… und %d weitere (siehe Konsole)" % (Data.errors.size() - 6)
		box.add_child(DebugUi.label("Fehler in data/:\n" + "\n".join(shown) + more, Color("#ff4fd8")))

	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 12)
	box.add_child(columns)
	columns.add_child(_build_scene_list())
	columns.add_child(_build_test_game())
	_refresh_status()


func _build_scene_list() -> Control:
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(DebugUi.label("Testszenen"))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	var scenes := find_test_scenes("res://scenes")
	if scenes.is_empty():
		list.add_child(DebugUi.label("(noch keine test_*.tscn)"))
	for path in scenes:
		list.add_child(DebugUi.button(path.trim_prefix("res://scenes/"), _open_scene.bind(path)))
	return column


func _build_test_game() -> Control:
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(DebugUi.label("Testspiel vorbereiten"))

	_job_picker = OptionButton.new()
	for job_id in Data.all("jobs"):
		_job_picker.add_item(Data.text(Data.job(job_id).name))
		_job_picker.set_item_metadata(_job_picker.item_count - 1, job_id)
	column.add_child(_job_picker)

	for companion_id in Data.all("companions"):
		var check := CheckBox.new()
		check.text = Data.text(Data.companion(companion_id).name)
		check.button_pressed = true
		_companion_boxes[companion_id] = check
		column.add_child(check)

	var moral_row := HBoxContainer.new()
	moral_row.add_child(DebugUi.label("Moral"))
	_moral_input = SpinBox.new()
	_moral_input.min_value = -100
	_moral_input.max_value = 100
	_moral_input.step = 5
	moral_row.add_child(_moral_input)
	column.add_child(moral_row)

	_items_box = CheckBox.new()
	_items_box.text = "Test-Items (Verbände, Dosen, Störsender, Schwert)"
	_items_box.button_pressed = true
	column.add_child(_items_box)

	column.add_child(DebugUi.button("Anwenden", _apply_test_game))
	_status = DebugUi.label("")
	column.add_child(_status)
	return column


func _apply_test_game() -> void:
	GameState.new_game(str(_job_picker.get_selected_metadata()))
	for companion_id in _companion_boxes:
		if _companion_boxes[companion_id].button_pressed:
			GameState.recruit(companion_id)
	GameState.add_moral(int(_moral_input.value))
	if _items_box.button_pressed:
		for item_id in TEST_ITEMS:
			GameState.add_item(item_id, TEST_ITEMS[item_id])
	_refresh_status()


func _refresh_status() -> void:
	if GameState.player.is_empty():
		_status.text = "Kein Spiel aktiv."
		return
	_status.text = "Job: %s · Party: %s · Moral: %d\nItems: %s\nFlags: %s" % [
		GameState.player.job_id, ", ".join(GameState.party), GameState.moral,
		GameState.inventory, GameState.flags,
	]


func _open_scene(path: String) -> void:
	SceneRouter.go_to(path)


## Every test_*.tscn below root, sorted. Handles exported builds, where scenes end in .remap.
static func find_test_scenes(root: String) -> PackedStringArray:
	var found: PackedStringArray = []
	var dir := DirAccess.open(root)
	if dir == null:
		return found
	for sub in dir.get_directories():
		found.append_array(find_test_scenes(root.path_join(sub)))
	for file in dir.get_files():
		var name := file.trim_suffix(".remap")
		if name.begins_with("test_") and name.ends_with(".tscn"):
			found.append(root.path_join(name))
	found.sort()
	return found
