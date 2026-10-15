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
## German comes straight from the .dialogue files (so edited German shows at once, even before
## the translation sync ran). English comes from localization/dialogue.csv; a line id the CSV
## doesn't know yet shows the German text with an "[EN?]" prefix instead of the raw id.
var _de := Translation.new()
var _en_missing := Translation.new()
var _registered: Dictionary = {}   # resource path -> true
## The balloon showing the current dialogue. Dialogue Manager puts it under the current scene,
## so a scene change frees it, and the runner then finishes the dialogue.
var balloon: Node = null


func _ready() -> void:
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)
	_de.locale = "de"
	_en_missing.locale = "en"
	TranslationServer.add_translation(_de)
	TranslationServer.add_translation(_en_missing)
	for path in dialogue_files("res://dialogue"):
		register_source_text(load(path) as DialogueResource)


## Every .dialogue file under a folder (also in exported builds, where files carry .remap/.import).
static func dialogue_files(dir_path: String) -> PackedStringArray:
	var found := PackedStringArray()
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return found
	for sub in dir.get_directories():
		found.append_array(dialogue_files(dir_path.path_join(sub)))
	for file in dir.get_files():
		var name := file.trim_suffix(".remap").trim_suffix(".import")
		if name.ends_with(".dialogue") and not found.has(dir_path.path_join(name)):
			found.append(dir_path.path_join(name))
	return found


## Makes the German text of every line in this dialogue the "de" translation of its line id.
## Called for every dialogue the runner loads; the dialogue tester and tests call it directly.
func register_source_text(resource: DialogueResource) -> void:
	if resource == null or _registered.has(resource.resource_path):
		return
	if not resource.resource_path.is_empty():
		_registered[resource.resource_path] = true
	var english := _english_translation()
	for line: Dictionary in resource.lines.values():
		var id := str(line.get("static_id", ""))
		if id.is_empty() or not line.has("text"):
			continue
		var text := str(line.text)
		for context in ["", "dialogue"]:
			_de.add_message(id, text, context)
		if english == null or str(english.get_message(id)).is_empty():
			for context in ["", "dialogue"]:
				_en_missing.add_message(id, "[EN?] " + text, context)


## The imported English dialogue table (compiled translations can't list their keys, only look them up).
func _english_translation() -> Translation:
	var path := "res://localization/dialogue.en.translation"
	return load(path) as Translation if ResourceLoader.exists(path) else null


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
	register_source_text(resource)
	if not resource.get_cues().has(title):
		push_warning("DialogueRunner: %s has no cue \"%s\"" % [file, title])
		return null
	return resource


func _missing_text_resource(file: String, title: String) -> DialogueResource:
	var line := "system: " + tr("DLG_MISSING_TEXT") % [file.trim_prefix("res://"), title]
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
