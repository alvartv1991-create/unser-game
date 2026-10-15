extends CanvasLayer
## The game's dialogue box: speaker name, 64x64 portrait, typewriter text and choices.
## DialogueRunner opens it through Dialogue Manager. Layout fits 640x360 with long German lines.
## Line tags writers can use: [#mood=happy] picks assets/portraits/<speaker>_happy.png if it exists.
## Choice tags: [#show_locked] shows an unavailable choice greyed out with its reason (see ChoiceRules).

const PORTRAIT_DIR := "res://assets/portraits/"
const PANEL_TEXTURE := "res://assets/ui/panel.png"
const NEXT_ACTIONS: Array[StringName] = [&"ui_accept", &"interact"]

var dialogue_resource: DialogueResource
var temporary_game_states: Array = []
var is_waiting_for_input := false
var _locale := TranslationServer.get_locale()
var _will_hide := false
var _hide_timer := Timer.new()
var _choices: Array = []   # [{button, response}]

var dialogue_line: DialogueLine:
	set(value):
		dialogue_line = value
		if value:
			_apply_line()
		else:
			queue_free()

var _box: PanelContainer
var _portrait: TextureRect
var _portrait_frame: PanelContainer
var _name_label: Label
var _text: DialogueLabel
var _next_marker: Label
var _choice_box: PanelContainer
var _choice_list: VBoxContainer
var _choice_scroll: ScrollContainer
const CHOICE_MAX_HEIGHT := 236.0   # the space above the dialogue box at 640x360
const CHOICE_WIDTH := 460.0


func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	_box.hide()
	_choice_box.hide()
	DialogueManager.mutated.connect(_on_mutated)
	_hide_timer.one_shot = true
	_hide_timer.timeout.connect(func() -> void:
		if _will_hide:
			_box.hide())
	add_child(_hide_timer)


## Called by Dialogue Manager's show_dialogue_balloon_scene().
func start(resource: DialogueResource, cue: String = "", extra_game_states: Array = []) -> void:
	temporary_game_states = [self] + extra_game_states
	dialogue_resource = resource
	dialogue_line = await resource.get_next_dialogue_line(cue, temporary_game_states)


func next(next_id: String) -> void:
	is_waiting_for_input = false
	dialogue_line = await dialogue_resource.get_next_dialogue_line(next_id, temporary_game_states)


func _process(_delta: float) -> void:
	if is_instance_valid(dialogue_line) and is_instance_valid(_text):
		_next_marker.visible = is_waiting_for_input and not _text.is_typing


func _notification(what: int) -> void:
	# Re-translate the shown line when the language changes. The addon's DialogueLine.refresh()
	# fetches the NEXT line (and crashes at the end of a dialogue, see H0), so fetch this one again.
	if what == NOTIFICATION_TRANSLATION_CHANGED and _locale != TranslationServer.get_locale():
		_locale = TranslationServer.get_locale()
		if not is_instance_valid(dialogue_line) or dialogue_resource == null or not "@" in dialogue_line.id:
			return
		var fresh := await dialogue_resource.get_next_dialogue_line(dialogue_line.id.split("@")[1], temporary_game_states)
		if is_instance_valid(fresh) and is_inside_tree():
			dialogue_line = fresh
			_text.skip_typing()


func _unhandled_input(event: InputEvent) -> void:
	# The dialogue owns all input while it is shown.
	get_viewport().set_input_as_handled()
	if not is_instance_valid(dialogue_line) or not _box.visible:
		return
	var pressed: bool = _is_next(event) or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT)
	if not pressed:
		return
	if _text.is_typing:
		_text.skip_typing()
	elif is_waiting_for_input and dialogue_line.responses.is_empty():
		next(dialogue_line.next_id)


func _is_next(event: InputEvent) -> bool:
	for action in NEXT_ACTIONS:
		if InputMap.has_action(action) and event.is_action_pressed(action):
			return true
	return false


func _apply_line() -> void:
	_hide_timer.stop()
	_will_hide = false
	is_waiting_for_input = false
	_clear_choices()
	_show_speaker()
	_box.show()
	_text.dialogue_line = dialogue_line
	if not dialogue_line.text.is_empty():
		_text.type_out()
		await _text.finished_typing
	if not is_instance_valid(dialogue_line):
		return
	if not dialogue_line.responses.is_empty():
		_fill_choices()
	elif dialogue_line.time != "":
		var seconds := dialogue_line.text.length() * 0.02 if dialogue_line.time == "auto" else dialogue_line.time.to_float()
		await get_tree().create_timer(seconds).timeout
		next(dialogue_line.next_id)
	else:
		is_waiting_for_input = true


func _show_speaker() -> void:
	var id := dialogue_line.character.strip_edges()
	_name_label.text = speaker_name(id)
	_name_label.visible = not _name_label.text.is_empty()
	var texture := portrait_for(id.to_lower(), dialogue_line.get_tag_value("mood"))
	_portrait.texture = texture
	_portrait_frame.visible = texture != null
	id = id.to_lower()
	if texture == null and Data.all("speakers").has(id) and id != "system":
		# A speaker without portrait art gets a colored placeholder square.
		_portrait_frame.visible = true
		_portrait.texture = _color_texture(Color(str(Data.all("speakers")[id].get("color", "#77727a"))))


## The shown name for a speaker id from the dialogue file ("player" = the protagonist).
static func speaker_name(id: String) -> String:
	if id == "player":
		return GameState.player_name()
	var speakers := Data.all("speakers")
	if speakers.has(id.to_lower()):
		return Data.text(speakers[id.to_lower()].get("name", id))
	return TranslationServer.translate(id)


## <speaker>_<mood>.png, else <speaker>.png, else null.
static func portrait_for(id: String, mood: String = "") -> Texture2D:
	if id.is_empty() or id == "system":
		return null
	var paths: Array[String] = [PORTRAIT_DIR + id + ".png"]
	if mood != "":
		paths.push_front(PORTRAIT_DIR + "%s_%s.png" % [id, mood])
	for path in paths:
		if ResourceLoader.exists(path):
			return load(path) as Texture2D
	return null


func _fill_choices() -> void:
	_clear_choices()
	if not is_instance_valid(dialogue_line) or dialogue_line.responses.is_empty():
		_choice_box.hide()
		return
	var first: Button = null
	for response: DialogueResponse in dialogue_line.responses:
		var state := ChoiceRules.state(response.is_allowed, response.condition_as_text, response.tags)
		if state == ChoiceRules.HIDDEN:
			continue
		var button := Button.new()
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.custom_minimum_size = Vector2(CHOICE_WIDTH - 12, 0)
		button.text = response.text
		if state == ChoiceRules.LOCKED:
			button.text = "[%s] %s" % [ChoiceRules.reason(response.condition_as_text, response.tags), response.text]
			button.disabled = true
			button.focus_mode = Control.FOCUS_NONE
		else:
			button.pressed.connect(_choose.bind(response))
			if first == null:
				first = button
		_choice_list.add_child(button)
		_choices.append({"button": button, "response": response})
	_choice_box.show()
	# Many choices (e.g. greyed-out job options) scroll instead of leaving the screen.
	_choice_scroll.custom_minimum_size.y = 0
	await get_tree().process_frame
	if not is_instance_valid(_choice_list):
		return
	_choice_scroll.custom_minimum_size.y = minf(_choice_list.get_combined_minimum_size().y, CHOICE_MAX_HEIGHT)
	if first and is_instance_valid(first):
		first.grab_focus()


func _choose(response: DialogueResponse) -> void:
	_clear_choices()
	next(response.next_id)


func _clear_choices() -> void:
	for child in _choice_list.get_children():
		child.queue_free()
	_choices.clear()
	_choice_box.hide()


func _on_mutated(mutation: Dictionary) -> void:
	if not mutation.get("is_inline", false):
		is_waiting_for_input = false
		_will_hide = true
		_hide_timer.start(0.1)


func _color_texture(color: Color) -> Texture2D:
	var image := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	image.fill(color.darkened(0.4))
	image.fill_rect(Rect2i(4, 4, 56, 56), color)
	return ImageTexture.create_from_image(image)


func _panel_style() -> StyleBox:
	if ResourceLoader.exists(PANEL_TEXTURE):
		var style := StyleBoxTexture.new()
		style.texture = load(PANEL_TEXTURE)
		for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
			style.set_texture_margin(side, 4)
			style.set_content_margin(side, 6)
		return style
	var flat := StyleBoxFlat.new()
	flat.bg_color = Color("14101a")
	flat.border_color = Color("a8a3a6")
	flat.set_border_width_all(1)
	flat.set_content_margin_all(6)
	return flat


func _build() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_box = PanelContainer.new()
	_box.add_theme_stylebox_override("panel", _panel_style())
	_box.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_box.offset_left = 8
	_box.offset_right = -8
	_box.offset_bottom = -6
	_box.offset_top = -100
	_box.grow_vertical = Control.GROW_DIRECTION_BEGIN
	root.add_child(_box)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	_box.add_child(row)

	_portrait_frame = PanelContainer.new()
	var frame_style := StyleBoxFlat.new()
	frame_style.bg_color = Color("1c2238")
	frame_style.border_color = Color("4a4552")
	frame_style.set_border_width_all(1)
	_portrait_frame.add_theme_stylebox_override("panel", frame_style)
	_portrait_frame.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.add_child(_portrait_frame)
	_portrait = TextureRect.new()
	_portrait.custom_minimum_size = Vector2(64, 64)
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	_portrait_frame.add_child(_portrait)

	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 2)
	row.add_child(column)
	_name_label = Label.new()
	_name_label.add_theme_color_override("font_color", Color("e0a94a"))
	column.add_child(_name_label)
	_text = DialogueLabel.new()
	_text.fit_content = true
	_text.scroll_active = false
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_text.skip_action = &""
	_text.seconds_per_step = 0.025
	_text.add_theme_color_override("default_color", Color("e3dccb"))
	column.add_child(_text)

	_next_marker = Label.new()
	_next_marker.text = "▼"
	_next_marker.add_theme_color_override("font_color", Color("e0a94a"))
	_next_marker.position = Vector2(614, 336)
	_next_marker.hide()
	root.add_child(_next_marker)

	_choice_box = PanelContainer.new()
	_choice_box.add_theme_stylebox_override("panel", _panel_style())
	_choice_box.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_choice_box.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_choice_box.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_choice_box.offset_right = -8
	_choice_box.offset_bottom = -110
	root.add_child(_choice_box)
	_choice_scroll = ScrollContainer.new()
	_choice_scroll.follow_focus = true
	_choice_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_choice_scroll.custom_minimum_size.x = CHOICE_WIDTH
	_choice_box.add_child(_choice_scroll)
	_choice_list = VBoxContainer.new()
	_choice_list.add_theme_constant_override("separation", 2)
	_choice_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_choice_scroll.add_child(_choice_list)
