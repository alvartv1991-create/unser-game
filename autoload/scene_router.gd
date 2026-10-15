extends Node
## Scene changes with fades, the combat overlay, and the global hooks. See AGENTS.md § SceneRouter.

const TITLE_SCENE := "res://scenes/ui/title.tscn"
const GLOBAL_UI_SCENE := "res://scenes/ui/global_ui.tscn"
const COMBAT_SCENE := "res://scenes/combat/combat.tscn"
const PLACEHOLDER_COMBAT := "res://scenes/debug/placeholder_combat.gd"
const DEBUG_MENU_SCENE := "res://scenes/debug/debug_menu.tscn"
const FADE_SECONDS := 0.25

var current_scene_path: String = ""
var last_spawn_id: String = ""

var _fade_rect: ColorRect
var _changing_scene := false
var _combat_node: Node = null
var _queued_combat := ""
var _paused_level: Node = null
var _paused_level_mode := Node.PROCESS_MODE_INHERIT
var _hidden: Array[Node] = []
var _debug_menu: Node = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_fade()
	EventBus.combat_finished.connect(_on_combat_finished)
	EventBus.dialogue_finished.connect(_on_dialogue_finished)
	if ResourceLoader.exists(GLOBAL_UI_SCENE):
		var global_ui: Node = (load(GLOBAL_UI_SCENE) as PackedScene).instantiate()
		get_tree().root.add_child.call_deferred(global_ui)
	_remember_start_scene.call_deferred()


func _input(event: InputEvent) -> void:
	if OS.is_debug_build() and event.is_action_pressed("debug_menu"):
		toggle_debug_menu()
		get_viewport().set_input_as_handled()


# --- Scene changes ---------------------------------------------------------

## Fades out, swaps the scene, puts the player at the SpawnPoint with spawn_id, fades in.
func go_to(scene_path: String, spawn_id: String = "") -> void:
	if _changing_scene:
		push_warning("SceneRouter.go_to(%s) ignored: a scene change is already running" % scene_path)
		return
	if not ResourceLoader.exists(scene_path):
		push_error("SceneRouter.go_to: scene not found: " + scene_path)
		return
	_changing_scene = true
	_close_debug_menu()
	await _fade_to(1.0)
	_drop_combat()
	get_tree().paused = false
	var tree := get_tree()
	var old_scene := tree.current_scene
	if old_scene:
		tree.root.remove_child(old_scene)
		old_scene.queue_free()
	var new_scene: Node = (load(scene_path) as PackedScene).instantiate()
	tree.root.add_child(new_scene)
	tree.current_scene = new_scene
	current_scene_path = scene_path
	last_spawn_id = spawn_id
	place_player(spawn_id)
	EventBus.scene_changed.emit(scene_path)
	await _fade_to(0.0)
	_changing_scene = false


## Moves the node in group "player" to the node in group "spawn_points" whose spawn_id matches.
func place_player(spawn_id: String) -> void:
	if spawn_id == "":
		return
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	for spawn in get_tree().get_nodes_in_group("spawn_points"):
		if spawn is Node2D and spawn.get("spawn_id") == spawn_id:
			player.global_position = spawn.global_position
			return
	push_warning("SceneRouter: no SpawnPoint with spawn_id \"%s\" in %s" % [spawn_id, current_scene_path])


func is_changing_scene() -> bool:
	return _changing_scene


# --- Combat ----------------------------------------------------------------

## Pauses and hides the level, then shows the combat scene on top. The level resumes afterwards.
func start_combat(encounter_id: String) -> void:
	if not Data.has("encounters", encounter_id):
		push_error("SceneRouter.start_combat: unknown encounter \"%s\"" % encounter_id)
		return
	if DialogueRunner.is_running():
		_queued_combat = encounter_id
		return
	if _combat_node != null:
		push_warning("SceneRouter.start_combat(%s) ignored: already in a fight" % encounter_id)
		return
	_pause_level()
	var combat: Node
	if ResourceLoader.exists(COMBAT_SCENE):
		combat = (load(COMBAT_SCENE) as PackedScene).instantiate()
	else:
		combat = (load(PLACEHOLDER_COMBAT) as GDScript).new()
	_combat_node = combat
	get_tree().root.add_child(combat)
	EventBus.combat_started.emit(encounter_id)
	combat.call("start", encounter_id)


func is_in_combat() -> bool:
	return _combat_node != null


func _on_combat_finished(_result: Dictionary) -> void:
	# Deferred, so every other listener can still read the combat scene's state this frame.
	_drop_combat.call_deferred()


func _on_dialogue_finished(_file: String, _title: String) -> void:
	if _queued_combat == "":
		return
	var encounter_id := _queued_combat
	_queued_combat = ""
	start_combat.call_deferred(encounter_id)


func _drop_combat() -> void:
	if is_instance_valid(_combat_node):
		_combat_node.queue_free()
	_combat_node = null
	_resume_level()


func _pause_level() -> void:
	var level := get_tree().current_scene
	if level == null:
		return
	_paused_level = level
	_paused_level_mode = level.process_mode
	level.process_mode = Node.PROCESS_MODE_DISABLED
	_hidden.clear()
	_hide_level(level)


func _resume_level() -> void:
	if not is_instance_valid(_paused_level):
		_paused_level = null
		return
	_paused_level.process_mode = _paused_level_mode
	for node in _hidden:
		if is_instance_valid(node):
			node.set("visible", true)
	_hidden.clear()
	_paused_level = null


## Hides the level and every CanvasLayer inside it (CanvasLayers ignore their parent's visibility).
func _hide_level(level: Node) -> void:
	var targets: Array[Node] = []
	if level is CanvasItem:
		targets.append(level)
	else:
		targets.append_array(level.get_children().filter(func(child: Node) -> bool: return child is CanvasItem))
	targets.append_array(level.find_children("*", "CanvasLayer", true, false))
	for node in targets:
		if node.get("visible"):
			node.set("visible", false)
			_hidden.append(node)


# --- Debug menu (F1, debug builds only) ------------------------------------

func toggle_debug_menu() -> void:
	if is_instance_valid(_debug_menu):
		_close_debug_menu()
		return
	if ResourceLoader.exists(DEBUG_MENU_SCENE):
		_debug_menu = (load(DEBUG_MENU_SCENE) as PackedScene).instantiate()
		get_tree().root.add_child(_debug_menu)


func _close_debug_menu() -> void:
	if is_instance_valid(_debug_menu):
		_debug_menu.queue_free()
	_debug_menu = null


# --- Fade ------------------------------------------------------------------

func _build_fade() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	_fade_rect = ColorRect.new()
	_fade_rect.color = Color.BLACK
	_fade_rect.modulate.a = 0.0
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(_fade_rect)


func _fade_to(alpha: float) -> void:
	var tween := create_tween()
	tween.tween_property(_fade_rect, "modulate:a", alpha, FADE_SECONDS)
	await tween.finished


func _remember_start_scene() -> void:
	var scene := get_tree().current_scene
	if scene and current_scene_path == "":
		current_scene_path = scene.scene_file_path
