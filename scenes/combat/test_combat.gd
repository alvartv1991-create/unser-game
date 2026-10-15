extends Control
## Combat test scene: choose fight, job, companions, items, rules and language, then start.
## Shows the result dictionary afterwards. Debug tool, so labels here are fixed German text.

const COMPANION_SETS := [
	["Keine Begleiter", []],
	["Koch/Köchin", ["cook"]],
	["Bastler/in", ["tinkerer"]],
	["Beide", ["cook", "tinkerer"]],
	["4 Testbegleiter (Layout)", ["cook", "tinkerer", "test_1", "test_2"]],
]

var _encounter: OptionButton
var _job: OptionButton
var _companions: OptionButton
var _items: CheckBox
var _sword: CheckBox
var _jammer: CheckBox
var _death: CheckBox
var _result: Label


func _ready() -> void:
	var box := DebugUi.panel(self, 1.0)
	box.add_child(DebugUi.label("Kampf-Test (F1 = Debug-Menü)", Color("#3ff0f0")))
	_encounter = _picker(box, "Kampf", Data.all("encounters").keys(), Data.all("encounters").keys())
	var jobs: Array = Data.all("jobs").keys()
	_job = _picker(box, "Job", jobs, jobs.map(func(id: String) -> String: return Data.text(Data.job(id).name)))
	_companions = _picker(box, "Begleiter", range(COMPANION_SETS.size()), COMPANION_SETS.map(func(entry: Array) -> String: return entry[0]))
	_companions.select(3)
	_items = _check(box, "Verbände ×3 + Konserven ×2", true)
	_sword = _check(box, "Heiliges Schwert ausrüsten (zerbricht nach einem Treffer)", false)
	_jammer = _check(box, "Störsender dabei", false)
	_death = _check(box, "Begleiter können im Kampf sterben (rules.json)", bool(Data.rule("companion_combat_death", true)))
	var row := HBoxContainer.new()
	row.add_child(DebugUi.button("Kampf starten", _start))
	row.add_child(DebugUi.button("DE", DebugUi.set_locale.bind("de")))
	row.add_child(DebugUi.button("EN", DebugUi.set_locale.bind("en")))
	box.add_child(row)
	box.add_child(DebugUi.label("Cheat-Code im Alien-Kampf: ↑ ↑ ↓ ↓ ← → ← →", Color("#ff4fd8")))
	_result = DebugUi.label("")
	box.add_child(_result)
	EventBus.combat_finished.connect(_on_finished)


func _exit_tree() -> void:
	# Undo the test-only changes to the data tables (test companions, rules).
	Data.reload()


func _start() -> void:
	var companion_ids: Array = COMPANION_SETS[_companions.get_selected_id()][1]
	if companion_ids.has("test_1"):
		_add_test_companions()
	Data.rules().companion_combat_death = _death.button_pressed
	GameState.new_game(str(_job.get_selected_metadata()))
	for companion_id in companion_ids:
		GameState.recruit(companion_id)
	if _items.button_pressed:
		GameState.add_item("bandage", 3)
		GameState.add_item("canned_food", 2)
	if _sword.button_pressed:
		GameState.add_item("holy_sword")
		GameState.equip_weapon("holy_sword")
	if _jammer.button_pressed:
		GameState.add_item("jammer")
	_result.text = ""
	SceneRouter.start_combat(str(_encounter.get_selected_metadata()))


func _add_test_companions() -> void:
	var table := Data.all("companions")
	for i in 2:
		var id := "test_%d" % (i + 1)
		var copy: Dictionary = table.cook.duplicate(true)
		copy.name = {"de": "Test %d" % (i + 1), "en": "Test %d" % (i + 1)}
		copy.art_id = id
		table[id] = copy
	Data.rules().max_active_companions = 4
	Data.rules().max_roster = 4


func _on_finished(result: Dictionary) -> void:
	var alive := PackedStringArray()
	for id in GameState.companions:
		var c: Dictionary = GameState.companions[id]
		if c.recruited:
			alive.append("%s %s (%d HP)" % [id, "lebt" if c.alive else "TOT", c.hp])
	_result.text = "Ergebnis: %s\nBegleiter: %s\nSpieler: %d/%d HP, Waffe: %s · Moral: %d\nInventar: %s" % [
		result, ", ".join(alive), GameState.player.hp, GameState.player.max_hp,
		GameState.player.weapon_id, GameState.moral, GameState.inventory]


func _picker(parent: Node, title: String, ids: Array, labels: Array) -> OptionButton:
	var row := HBoxContainer.new()
	var caption := DebugUi.label(title)
	caption.size_flags_horizontal = Control.SIZE_FILL
	caption.custom_minimum_size.x = 80
	row.add_child(caption)
	var picker := OptionButton.new()
	for i in ids.size():
		picker.add_item(str(labels[i]))
		picker.set_item_metadata(i, ids[i])
	row.add_child(picker)
	parent.add_child(row)
	return picker


func _check(parent: Node, text: String, pressed: bool) -> CheckBox:
	var check := CheckBox.new()
	check.text = text
	check.button_pressed = pressed
	parent.add_child(check)
	return check
