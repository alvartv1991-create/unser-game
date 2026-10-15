extends Control
## Test scene for dialogue/test/hello.dialogue: plays it and shows flags and moral live.

const FILE := "res://dialogue/test/hello.dialogue"

var _status: Label


func _ready() -> void:
	if GameState.player.is_empty():
		GameState.new_game("doctor")
	var box := DebugUi.panel(self)
	box.add_child(DebugUi.label("Test: hello.dialogue (F1 = Debug-Menü)", Color("#3ff0f0")))
	var row := HBoxContainer.new()
	row.add_child(DebugUi.button("Dialog starten", _start))
	row.add_child(DebugUi.button("Moral +30", GameState.add_moral.bind(30)))
	row.add_child(DebugUi.button("Moral -30", GameState.add_moral.bind(-30)))
	row.add_child(DebugUi.button("DE", DebugUi.set_locale.bind("de")))
	row.add_child(DebugUi.button("EN", DebugUi.set_locale.bind("en")))
	row.add_child(DebugUi.button("Fehlender Text", DialogueRunner.start.bind(FILE, "does_not_exist")))
	box.add_child(row)
	_status = DebugUi.label("")
	box.add_child(_status)
	EventBus.flag_changed.connect(_refresh.unbind(2))
	EventBus.moral_changed.connect(_refresh.unbind(1))
	EventBus.dialogue_started.connect(_refresh.unbind(2))
	EventBus.dialogue_finished.connect(_refresh.unbind(2))
	EventBus.locale_changed.connect(_refresh.unbind(1))
	_refresh()


func _start() -> void:
	DialogueRunner.start(FILE, "start")


func _refresh() -> void:
	_status.text = "Sprache: %s · Job: %s · Moral: %d (%s) · Dialog läuft: %s\nFlags: %s" % [
		TranslationServer.get_locale(), GameState.player.get("job_id", "-"), GameState.moral,
		"hoch" if GameState.moral_is("high") else ("niedrig" if GameState.moral_is("low") else "neutral"),
		DialogueRunner.is_running(), GameState.flags,
	]
