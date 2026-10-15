class_name WorldInteractable
extends Area2D

@export_enum("Talk", "Examine", "Pickup", "Door", "EncounterTrigger", "StoryTrigger", "Campfire", "GlitchDevice", "Gate", "SecretPassage") var interaction: String = "Talk"
@export var required_flag: String = ""
@export var hidden_if_flag: String = ""
@export var required_moral: String = ""
@export var file: String = "res://dialogue/test/hello.dialogue"
@export var title: String = "start"
@export var examine_id: String = "tv_flicker"
@export var item_id: String = "bandage"
@export var count: int = 1
@export_file("*.tscn") var destination: String = ""
@export var spawn_id: String = "start"
@export var encounter_id: String = "raiders_street"
@export var once_flag: String = ""
@export var gate_flag: String = "hello_flag"
@export_enum("tv", "payphone", "radio", "arcade") var kind: String = "tv"
@export var intensity: float = 0.25
@export var prop: String = "crate"
## Gate: cue in `file` to play when the gate opens (instead of going to `destination` directly).
## Campfire: cue in `file` to play after resting (e.g. the cook's campfire scene). Empty = none.
@export var after_title: String = ""
var prompt: Label
var sprite: Sprite2D
var cooldown: float = 0.0
var glow_time: float = 0.0

func _ready() -> void:
	add_to_group("interactables")
	collision_layer = 0
	collision_mask = 4
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(42, 46)
	shape.shape = rect
	shape.position.y = -20
	add_child(shape)
	sprite = Sprite2D.new()
	var asset := kind if interaction == "GlitchDevice" else prop
	var path := "res://assets/props/%s.png" % asset
	if ResourceLoader.exists(path):
		sprite.texture = load(path)
	sprite.position.y = -16
	add_child(sprite)
	prompt = Label.new()
	prompt.position = Vector2(-65, -55)
	prompt.size.x = 130
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_font_size_override("font_size", 12)
	add_child(prompt)

func persistence_flag() -> String:
	if not once_flag.is_empty():
		return once_flag
	return "picked_%s_%s" % [get_tree().current_scene.scene_file_path.get_file().get_basename(), name.to_snake_case()]

func available() -> bool:
	if required_flag != "" and not GameState.get_flag(required_flag, false):
		return false
	if hidden_if_flag != "" and GameState.get_flag(hidden_if_flag, false):
		return false
	if required_moral != "" and not GameState.moral_is(required_moral):
		return false
	if interaction in ["Pickup", "EncounterTrigger", "StoryTrigger"] and GameState.get_flag(persistence_flag(), false):
		return false
	return true

func nearest(player: Node2D) -> bool:
	for other in get_tree().get_nodes_in_group("interactables"):
		if other != self and other.available() and other.get_overlapping_bodies().has(player):
			if other.global_position.distance_squared_to(player.global_position) < global_position.distance_squared_to(player.global_position):
				return false
	return true

func _process(delta: float) -> void:
	cooldown = maxf(0, cooldown - delta)
	glow_time = maxf(0, glow_time - delta)
	visible = available()
	prompt.visible = false
	sprite.modulate = Color("3ff0f0") if glow_time > 0 else Color.WHITE
	if not visible:
		return
	var player := get_tree().get_first_node_in_group("player") as WorldPlayer
	if player == null or player.blocked() or not get_overlapping_bodies().has(player):
		return
	if interaction == "GlitchDevice" and cooldown <= 0:
		cooldown = 3.0
		glow_time = 0.3
		EventBus.device_glitch.emit(intensity, 0.3)
		AudioManager.play_sfx("sfx_phone_ring" if kind == "payphone" else "sfx_glitch")
	if interaction in ["StoryTrigger", "EncounterTrigger"]:
		activate()
	elif interaction == "SecretPassage":
		GameState.set_flag(persistence_flag())
		sprite.visible = false
		if not destination.is_empty():
			activate()
	elif nearest(player):
		prompt.visible = true
		prompt.text = tr("UI_INTERACT") % tr("UI_ACTION_" + interaction.to_upper())

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and prompt.visible:
		get_viewport().set_input_as_handled()
		activate()

func activate() -> void:
	if not available():
		return
	match interaction:
		"Talk": DialogueRunner.start(file, title)
		"Examine", "GlitchDevice": DialogueRunner.start("res://dialogue/examine.dialogue", examine_id)
		"Pickup":
			GameState.set_flag(persistence_flag())
			GameState.add_item(item_id, count)
			AudioManager.play_sfx("sfx_pickup")
		"Door", "SecretPassage":
			if not destination.is_empty():
				SceneRouter.go_to(destination, spawn_id)
		"Gate":
			if GameState.get_flag(gate_flag, false) and after_title != "":
				DialogueRunner.start(file, after_title)
				await EventBus.dialogue_finished
				if not destination.is_empty():
					SceneRouter.go_to(destination, spawn_id)
			elif GameState.get_flag(gate_flag, false):
				SceneRouter.go_to(destination, spawn_id)
			else:
				DialogueRunner.start(file, title)
		"EncounterTrigger":
			GameState.set_flag(persistence_flag())
			SceneRouter.start_combat(encounter_id)
		"StoryTrigger":
			GameState.set_flag(persistence_flag())
			DialogueRunner.start(file, title)
		"Campfire":
			GameState.rest()
			var saved := SaveSystem.save_game(0)
			get_tree().call_group("global_ui", "toast_key", "UI_SAVED" if saved else "UI_SAVE_UNAVAILABLE")
			if after_title != "":
				DialogueRunner.start(file, after_title)
