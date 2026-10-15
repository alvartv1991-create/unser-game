extends Control
## Dialogue tester: the writers' main tool. Pick any file and cue, set up the job, party, items,
## flags, moral and language, then play it. Choices remain in the state, so you can play on.
## The last setup is remembered (user://dialogue_tester.cfg). Open it with F1 -> dialogue/test_dialogue.tscn.
## Developer screen: labels are German like the rest of the debug tools.

const SETTINGS := "user://dialogue_tester.cfg"
const ITEMS := ["canned_food", "bandage", "jammer", "holy_sword", "scrap"]

var _files: PackedStringArray = []
var _file_pick: OptionButton
var _cue_pick: OptionButton
var _job_pick: OptionButton
var _moral: SpinBox
var _flags: LineEdit
var _companions: Dictionary = {}   # id -> {recruited: CheckBox, dead: CheckBox}
var _items: Dictionary = {}        # id -> CheckBox
var _status: Label
var _panel: Control


func _ready() -> void:
	var box := DebugUi.panel(self)
	_panel = get_child(0)
	var header := HBoxContainer.new()
	header.add_child(DebugUi.label("Dialog-Tester  (F1 = Debug-Menü)", Color("#3ff0f0")))
	header.add_child(DebugUi.button("DE", _set_locale.bind("de")))
	header.add_child(DebugUi.button("EN", _set_locale.bind("en")))
	box.add_child(header)

	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 6)
	box.add_child(grid)

	_file_pick = OptionButton.new()
	_files = DialogueRunner.dialogue_files("res://dialogue")
	for path in _files:
		_file_pick.add_item(path.trim_prefix("res://dialogue/"))
	_file_pick.item_selected.connect(func(_i: int) -> void: _fill_cues())
	_add_row(grid, "Datei", _file_pick)
	_cue_pick = OptionButton.new()
	_add_row(grid, "Cue", _cue_pick)

	_job_pick = OptionButton.new()
	for id: String in Data.all("jobs"):
		_job_pick.add_item(Data.text(Data.job(id).name))
		_job_pick.set_item_metadata(_job_pick.item_count - 1, id)
	_add_row(grid, "Beruf", _job_pick)
	var moral_row := HBoxContainer.new()
	_moral = SpinBox.new()
	_moral.min_value = -100
	_moral.max_value = 100
	_moral.step = 5
	moral_row.add_child(_moral)
	for preset: Array in [["niedrig", -40], ["neutral", 0], ["hoch", 40]]:
		moral_row.add_child(DebugUi.button(preset[0], func() -> void: _moral.value = preset[1]))
	_add_row(grid, "Moral", moral_row)

	var party_row := HBoxContainer.new()
	for id: String in Data.all("companions"):
		var recruited := CheckBox.new()
		recruited.text = Data.text(Data.companion(id).name).trim_prefix("[TEMP] ")
		var dead := CheckBox.new()
		dead.text = "tot"
		party_row.add_child(recruited)
		party_row.add_child(dead)
		_companions[id] = {"recruited": recruited, "dead": dead}
	box.add_child(_labeled("Gruppe", party_row))

	var item_row := HBoxContainer.new()
	for id: String in ITEMS:
		if not Data.has("items", id):
			continue
		var check := CheckBox.new()
		check.text = Data.text(Data.item(id).name).trim_prefix("[TEMP] ")
		item_row.add_child(check)
		_items[id] = check
	box.add_child(_labeled("Items", item_row))

	_flags = LineEdit.new()
	_flags.placeholder_text = "z. B. tinkerer_met, raiders_camp_resolved=talk"
	_flags.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(_labeled("Flags", _flags))

	var actions := HBoxContainer.new()
	actions.add_child(DebugUi.button("▶ Abspielen", _play))
	actions.add_child(DebugUi.button("Nur Zustand setzen", _apply_setup))
	actions.add_child(DebugUi.button("Weiterspielen (Zustand behalten)", _play_keep_state))
	if OS.has_feature("editor"):
		actions.add_child(DebugUi.button("Übersetzungen syncen", _sync))
	box.add_child(actions)

	_status = DebugUi.label("", Color("#e0a94a"))
	box.add_child(_status)

	_load_settings()
	_fill_cues(_cue_from_settings)
	EventBus.dialogue_started.connect(func(_f: String, _t: String) -> void: _panel.modulate.a = 0.35)
	EventBus.dialogue_finished.connect(func(_f: String, _t: String) -> void:
		_panel.modulate.a = 1.0
		_refresh())
	_refresh()


var _cue_from_settings := ""


func _add_row(grid: GridContainer, title: String, control: Control) -> void:
	grid.add_child(DebugUi.label(title))
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_child(control)


func _labeled(title: String, control: Control) -> Control:
	var row := HBoxContainer.new()
	var label := DebugUi.label(title)
	label.size_flags_horizontal = Control.SIZE_FILL
	label.custom_minimum_size.x = 40
	row.add_child(label)
	row.add_child(control)
	return row


func _fill_cues(select: String = "") -> void:
	_cue_pick.clear()
	if _file_pick.selected < 0:
		return
	var resource := load(_files[_file_pick.selected]) as DialogueResource
	if resource == null:
		return
	for cue in resource.get_cues():
		_cue_pick.add_item(cue)
		if cue == select:
			_cue_pick.select(_cue_pick.item_count - 1)


func _selected_job() -> String:
	return str(_job_pick.get_item_metadata(_job_pick.selected)) if _job_pick.selected >= 0 else "doctor"


## Resets the game to the setup in the form: new game with the job, then party, items, flags, moral.
func _apply_setup() -> void:
	GameState.new_game(_selected_job())
	for id: String in _companions:
		if _companions[id].recruited.button_pressed:
			GameState.recruit(id)
		if _companions[id].dead.button_pressed:
			GameState.kill_companion(id, "story:dialogue_tester")
	for id: String in _items:
		if _items[id].button_pressed and not GameState.has_item(id):
			GameState.add_item(id)
	for part in _flags.text.split(",", false):
		var pair := part.strip_edges().split("=")
		if pair[0].is_empty():
			continue
		var value: Variant = true
		if pair.size() > 1:
			value = pair[1].strip_edges()
			if value == "true" or value == "false":
				value = value == "true"
		GameState.set_flag(pair[0], value)
	GameState.add_moral(int(_moral.value))
	_save_settings()
	_refresh()


func _play() -> void:
	_apply_setup()
	_play_keep_state()


func _play_keep_state() -> void:
	if DialogueRunner.is_running() or _file_pick.selected < 0 or _cue_pick.selected < 0:
		return
	if GameState.player.is_empty():
		_apply_setup()
	_save_settings()
	DialogueRunner.start(_files[_file_pick.selected], _cue_pick.get_item_text(_cue_pick.selected))


func _set_locale(locale: String) -> void:
	DebugUi.set_locale(locale)
	_save_settings()
	_refresh()


func _sync() -> void:
	var report := TranslationSync.run()
	_status.text = TranslationSync.summary(report) + "\nNeue englische Texte erscheinen nach dem nächsten Import (Editor neu fokussieren)."
	_fill_cues(_cue_pick.get_item_text(_cue_pick.selected) if _cue_pick.selected >= 0 else "")


func _refresh() -> void:
	if GameState.player.is_empty():
		_status.text = "Noch kein Zustand. ▶ Abspielen setzt ihn."
		return
	var party: Array[String] = []
	for id: String in GameState.companions:
		var c: Dictionary = GameState.companions[id]
		if c.recruited or not c.alive:
			party.append("%s%s" % [id, "" if c.alive else " (tot: %s)" % c.death_reason])
	var flags: Array[String] = []
	for id: String in GameState.flags:
		flags.append("%s=%s" % [id, GameState.flags[id]])
	var items: Array[String] = []
	for id: String in GameState.inventory:
		items.append("%s×%d" % [id, GameState.inventory[id]])
	var band := "hoch" if GameState.moral_is("high") else ("niedrig" if GameState.moral_is("low") else "neutral")
	_status.text = "Sprache %s · Beruf %s · Moral %d (%s) · Ziel %s\nGruppe: %s\nItems: %s\nFlags: %s" % [
		TranslationServer.get_locale(), GameState.player.get("job_id", "?"), GameState.moral, band,
		tr(GameState.objective) if GameState.objective != "" else "-",
		", ".join(party) if not party.is_empty() else "-",
		", ".join(items) if not items.is_empty() else "-",
		", ".join(flags) if not flags.is_empty() else "-"]


func _save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("tester", "file", _files[_file_pick.selected] if _file_pick.selected >= 0 else "")
	config.set_value("tester", "cue", _cue_pick.get_item_text(_cue_pick.selected) if _cue_pick.selected >= 0 else "")
	config.set_value("tester", "job", _selected_job())
	config.set_value("tester", "moral", _moral.value)
	config.set_value("tester", "flags", _flags.text)
	config.set_value("tester", "locale", TranslationServer.get_locale())
	for id: String in _companions:
		config.set_value("party", id, [_companions[id].recruited.button_pressed, _companions[id].dead.button_pressed])
	for id: String in _items:
		config.set_value("items", id, _items[id].button_pressed)
	config.save(SETTINGS)


func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS) != OK:
		return
	var file_index := _files.find(str(config.get_value("tester", "file", "")))
	if file_index >= 0:
		_file_pick.select(file_index)
	_cue_from_settings = str(config.get_value("tester", "cue", ""))
	for i in _job_pick.item_count:
		if str(_job_pick.get_item_metadata(i)) == str(config.get_value("tester", "job", "")):
			_job_pick.select(i)
	_moral.value = float(config.get_value("tester", "moral", 0))
	_flags.text = str(config.get_value("tester", "flags", ""))
	var locale := str(config.get_value("tester", "locale", ""))
	if locale in ["de", "en"]:
		DebugUi.set_locale(locale)
	for id: String in _companions:
		var pair: Array = config.get_value("party", id, [false, false])
		_companions[id].recruited.button_pressed = pair[0]
		_companions[id].dead.button_pressed = pair[1]
	for id: String in _items:
		_items[id].button_pressed = bool(config.get_value("items", id, false))
