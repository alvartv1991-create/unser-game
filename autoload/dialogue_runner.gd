extends Node
## Starts dialogue from Dialogue Manager files and tells the game when it begins and ends.
## While a dialogue runs, the player must not move (listen to dialogue_started/finished).
## A missing file or cue shows a placeholder line instead of crashing. See AGENTS.md § DialogueRunner.

## H3 builds the real balloon here. Until then, the addon's small example balloon is used.
const BALLOON_SCENE := "res://scenes/dialogue/balloon.tscn"
const FALLBACK_BALLOON := "res://addons/dialogue_manager/example_balloon/small_example_balloon.tscn"

var _running := false
var _file := ""
var _title := ""
var _resource: DialogueResource = null
var _session := 0
## The balloon showing the current dialogue. Dialogue Manager puts it under the current scene,
## so a scene change frees it, and the runner then finishes the dialogue.
var balloon: Node = null


func _ready() -> void:
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)


## Plays a cue ("title") from a .dialogue file, e.g. start("res://dialogue/area1/cook.dialogue", "first_meet").
func start(file: String, title: String = "start") -> void:
	if _running:
		push_warning("DialogueRunner.start(%s, %s) ignored: a dialogue is already running" % [file, title])
		return
	_running = true
	if SceneRouter.is_changing_scene():
		# Wait for the new scene. Otherwise the balloon lands in the old scene and vanishes with it.
		await EventBus.scene_changed
	var resource := _load_resource(file, title)
	var cue := title
	if resource == null:
		resource = _missing_text_resource(file, title)
		cue = "start"
	_file = file
	_title = title
	_resource = resource
	_session += 1
	EventBus.dialogue_started.emit(file, title)
	var balloon_path := BALLOON_SCENE if ResourceLoader.exists(BALLOON_SCENE) else FALLBACK_BALLOON
	balloon = DialogueManager.show_dialogue_balloon_scene(balloon_path, resource, cue)
	# Safety net: if the balloon disappears without the dialogue ending (scene change), still finish.
	# Bound to this session, so an old balloon closing late can't end a newer dialogue.
	if balloon:
		balloon.tree_exited.connect(_finish_session.bind(_session), CONNECT_ONE_SHOT)


func is_running() -> bool:
	return _running


func _load_resource(file: String, title: String) -> DialogueResource:
	if not ResourceLoader.exists(file):
		push_warning("DialogueRunner: missing dialogue file " + file)
		return null
	var resource := load(file) as DialogueResource
	if resource == null:
		push_warning("DialogueRunner: %s is not a dialogue file" % file)
		return null
	if not resource.get_cues().has(title):
		push_warning("DialogueRunner: %s has no cue \"%s\"" % [file, title])
		return null
	return resource


func _missing_text_resource(file: String, title: String) -> DialogueResource:
	var line := "System: [TEMP] Kein Text: %s : %s" % [file.trim_prefix("res://"), title]
	return DialogueManager.create_resource_from_text("~ start\n" + line + "\n=> END") as DialogueResource


func _on_dialogue_ended(resource: DialogueResource) -> void:
	# Tools and tests may run other dialogue through Dialogue Manager; only react to ours.
	if resource == _resource:
		_finish()


func _finish_session(session: int) -> void:
	if session == _session:
		_finish()


func _finish() -> void:
	if not _running:
		return
	_running = false
	_resource = null
	balloon = null
	EventBus.dialogue_finished.emit(_file, _title)
