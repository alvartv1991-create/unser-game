class_name WorldUI
extends CanvasLayer

var settings := ConfigFile.new()
var menu: Control
var hud: VBoxContainer
var toast_label: Label
var debug_label: Label
var toast_time: float = 0.0
var page: String = ""
var prior_pause: bool = false

func _ready() -> void:
	add_to_group("global_ui")
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	settings.load("user://settings.cfg")
	TranslationServer.set_locale(str(settings.get_value("display", "language", "de")))
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if settings.get_value("display", "fullscreen", false) else DisplayServer.WINDOW_MODE_WINDOWED)
	for bus in ["Master", "Music", "SFX", "Ambience"]:
		AudioManager.set_volume(bus, float(settings.get_value("audio", bus, 0.8)))
	hud = VBoxContainer.new()
	hud.position = Vector2(8, 6)
	hud.size.x = 270
	add_child(hud)
	menu = Control.new()
	menu.set_anchors_preset(Control.PRESET_FULL_RECT)
	menu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(menu)
	toast_label = UiKit.label("", self)
	toast_label.position = Vector2(20, 320)
	toast_label.size.x = 600
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	debug_label = UiKit.label("", self)
	debug_label.position = Vector2(8, 100)
	debug_label.size = Vector2(620, 210)
	debug_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	debug_label.visible = false
	EventBus.hp_changed.connect(refresh_hud)
	EventBus.party_changed.connect(refresh_hud)
	EventBus.objective_changed.connect(func(_text: String) -> void: refresh_hud())
	EventBus.locale_changed.connect(func(_locale: String) -> void: refresh_hud())
	EventBus.item_changed.connect(func(id: String, amount: int) -> void: toast(tr("UI_ITEM_CHANGED") % [Data.text(Data.item(id).name), amount]))
	EventBus.companion_recruited.connect(func(id: String) -> void: toast(tr("UI_RECRUITED") % Data.text(Data.companion(id).name)))
	EventBus.companion_died.connect(func(id: String, _reason: String) -> void: toast(tr("UI_DIED") % Data.text(Data.companion(id).name)))
	EventBus.area_unlocked.connect(func(_id: String) -> void: toast_key("UI_AREA_UNLOCKED"))
	EventBus.scene_changed.connect(func(_path: String) -> void: close_menu(); refresh_hud())
	refresh_hud()

func _process(delta: float) -> void:
	if page != "" and is_instance_valid(SceneRouter.get("_debug_menu")):
		close_menu()
	hud.visible = not GameState.player.is_empty() and get_tree().get_first_node_in_group("player") != null and not SceneRouter.is_in_combat()
	toast_time = maxf(0, toast_time - delta)
	toast_label.visible = toast_time > 0 and page == ""
	if debug_label.visible:
		debug_label.text = tr("UI_DEBUG") % [GameState.moral, str(GameState.party), str(GameState.inventory), str(GameState.flags)]

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_overlay") and OS.is_debug_build():
		debug_label.visible = not debug_label.visible
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("pause") and not SceneRouter.is_changing_scene() and not SceneRouter.is_in_combat() and not DialogueRunner.is_running() and not is_instance_valid(SceneRouter.get("_debug_menu")):
		if page != "":
			close_menu()
		elif get_tree().get_first_node_in_group("player"):
			open_menu("pause")
		get_viewport().set_input_as_handled()

func toast(value: String) -> void:
	toast_label.text = value
	toast_time = 3.0

func toast_key(key: String) -> void:
	toast(tr(key))

func refresh_hud() -> void:
	UiKit.clear(hud)
	if GameState.player.is_empty():
		return
	var cards := HBoxContainer.new()
	cards.add_theme_constant_override("separation", 5)
	hud.add_child(cards)
	add_hud_card(cards, "player", GameState.player_name(), GameState.player)
	for id in GameState.party:
		add_hud_card(cards, id, Data.text(Data.companion(id).name), GameState.companions[id])
	if GameState.objective != "":
		UiKit.label(tr(GameState.objective), hud, true)

func add_hud_card(parent: Node, art_id: String, display_name: String, state: Dictionary) -> void:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(169, 48)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	panel.add_child(row)
	var portrait := TextureRect.new()
	portrait.custom_minimum_size = Vector2(32, 32)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var portrait_path := "res://assets/portraits/%s.png" % art_id
	var frames_path := "res://assets/sprites/characters/%s.tres" % art_id
	if ResourceLoader.exists(portrait_path):
		portrait.texture = load(portrait_path)
	elif ResourceLoader.exists(frames_path):
		var frames := load(frames_path) as SpriteFrames
		if frames.has_animation("idle") and frames.get_frame_count("idle") > 0:
			portrait.texture = frames.get_frame_texture("idle", 0)
	else:
		portrait.texture = load("res://assets/ui/heart.png")
	row.add_child(portrait)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 1)
	row.add_child(column)
	var caption := UiKit.label(display_name, column)
	caption.add_theme_font_size_override("font_size", 11)
	caption.custom_minimum_size.x = 110
	caption.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(110, 6)
	bar.max_value = state.max_hp
	bar.value = state.hp
	bar.show_percentage = false
	column.add_child(bar)
	var hp_caption := UiKit.label("%d / %d" % [state.hp, state.max_hp], column)
	hp_caption.add_theme_font_size_override("font_size", 10)

func add_health(parent: Node, display_name: String, state: Dictionary) -> void:
	var row := HBoxContainer.new()
	parent.add_child(row)
	var icon := TextureRect.new()
	icon.texture = load("res://assets/ui/heart.png")
	icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	row.add_child(icon)
	UiKit.label("%s  %d/%d" % [display_name, state.hp, state.max_hp], row)
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(65, 6)
	bar.max_value = state.max_hp
	bar.value = state.hp
	bar.show_percentage = false
	row.add_child(bar)

func open_menu(target: String) -> void:
	if page == "":
		prior_pause = get_tree().paused
	page = target
	get_tree().paused = true
	UiKit.clear(menu)
	var shade := ColorRect.new()
	shade.color = Color(0.078, 0.063, 0.102, 0.9)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	menu.add_child(shade)
	var column := UiKit.panel(menu, Rect2(80, 20, 480, 320))
	UiKit.label(tr("UI_" + target.to_upper()), column)
	match target:
		"pause":
			UiKit.button("UI_RESUME", column, close_menu)
			for section in ["inventory", "party", "options"]:
				UiKit.button("UI_" + section.to_upper(), column, open_menu.bind(section))
			UiKit.button("UI_MAIN_MENU", column, func() -> void:
				close_menu()
				GameState.reset()
				SceneRouter.go_to("res://scenes/ui/title.tscn"))
		"options": build_options(column)
		"inventory": build_inventory(UiKit.scroll(column))
		"party": build_party(UiKit.scroll(column))
		"load": build_load(column)
	if target != "pause":
		UiKit.button("UI_BACK", column, close_menu)
	UiKit.focus_first(menu)

func close_menu() -> void:
	if page == "":
		return
	page = ""
	UiKit.clear(menu)
	get_tree().paused = prior_pause
	var title_node := get_tree().get_first_node_in_group("title_ui")
	if title_node:
		UiKit.focus_first(title_node)

func choose_language(locale: String) -> void:
	TranslationServer.set_locale(locale)
	settings.set_value("display", "language", locale)
	save_settings()
	EventBus.locale_changed.emit(locale)
	if page == "options":
		open_menu("options")

func save_settings() -> void:
	if settings.save("user://settings.cfg") != OK:
		toast_key("UI_SETTINGS_FAILED")

func build_options(column: VBoxContainer) -> void:
	var languages := HBoxContainer.new()
	column.add_child(languages)
	UiKit.button("UI_DE", languages, choose_language.bind("de"))
	UiKit.button("UI_EN", languages, choose_language.bind("en"))
	for bus in ["Master", "Music", "SFX", "Ambience"]:
		var row := HBoxContainer.new()
		column.add_child(row)
		var caption := UiKit.label(tr("UI_BUS_" + bus.to_upper()), row)
		caption.custom_minimum_size.x = 120
		var slider := HSlider.new()
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slider.max_value = 1.0
		slider.step = 0.05
		slider.value = float(settings.get_value("audio", bus, 0.8))
		row.add_child(slider)
		slider.value_changed.connect(func(value: float) -> void:
			settings.set_value("audio", bus, value)
			AudioManager.set_volume(bus, value)
			save_settings())
	for option in ["fullscreen", "reduce_effects"]:
		var check := CheckBox.new()
		check.text = tr("UI_" + option.to_upper())
		check.button_pressed = settings.get_value("display", option, false)
		column.add_child(check)
		check.toggled.connect(func(value: bool) -> void:
			settings.set_value("display", option, value)
			if option == "fullscreen":
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if value else DisplayServer.WINDOW_MODE_WINDOWED)
			save_settings())

func build_inventory(column: VBoxContainer) -> void:
	if GameState.inventory.is_empty():
		UiKit.label(tr("UI_EMPTY"), column)
	for id: String in GameState.inventory:
		var item: Dictionary = Data.item(id)
		var row := HBoxContainer.new()
		column.add_child(row)
		var icon := TextureRect.new()
		icon.texture = load("res://assets/ui/item.png")
		icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		row.add_child(icon)
		UiKit.label("%s ×%d" % [Data.text(item.name), GameState.inventory[id]], row)
		UiKit.label(Data.text(item.description), column, true)
		if int(item.get("heal", 0)) > 0:
			for target in ["player"] + GameState.recruited_alive():
				var state: Dictionary = GameState.player if target == "player" else GameState.companions[target]
				var target_name := GameState.player_name() if target == "player" else Data.text(Data.companion(target).name)
				var action := UiKit.button("UI_HEAL", column, func() -> void:
					use_healing(id, target)
					open_menu("inventory"))
				action.text = tr("UI_HEAL") % target_name
				action.disabled = int(state.hp) >= int(state.max_hp)

static func use_healing(id: String, target: String) -> bool:
	if SceneRouter.is_in_combat() or GameState.player.is_empty() or not Data.has("items", id):
		return false
	if target != "player" and (not GameState.is_recruited(target) or not GameState.is_alive(target)):
		return false
	var item := Data.item(id)
	var state: Dictionary = GameState.player if target == "player" else GameState.companions[target]
	if int(item.get("heal", 0)) <= 0 or int(state.hp) >= int(state.max_hp) or not GameState.has_item(id):
		return false
	var bonus: float = float(Data.job(GameState.player.job_id).get("perks", {}).get("healing_item_bonus", 0.0))
	if not GameState.remove_item(id):
		return false
	state.hp = mini(int(state.max_hp), int(state.hp) + roundi(int(item.heal) * (1.0 + bonus)))
	EventBus.hp_changed.emit()
	AudioManager.play_sfx("sfx_heal")
	return true

func build_party(column: VBoxContainer) -> void:
	if GameState.player.is_empty():
		return
	var job: Dictionary = Data.job(GameState.player.job_id)
	member_details(column, GameState.player_name(), GameState.player, job, [job.skill])
	for id in GameState.companions:
		var state: Dictionary = GameState.companions[id]
		if not state.recruited:
			continue
		var entry: Dictionary = Data.companion(id)
		if state.alive:
			member_details(column, Data.text(entry.name), state, entry, entry.skills)
		else:
			UiKit.label(tr("UI_MEMORY") % Data.text(entry.name), column, true)
			UiKit.label(tr("UI_DEATH_COMBAT") if str(state.death_reason).begins_with("combat:") else tr("UI_DEATH_STORY"), column, true)

func member_details(column: VBoxContainer, display_name: String, state: Dictionary, entry: Dictionary, skills: Array) -> void:
	add_health(column, display_name, state)
	UiKit.label(Data.text(entry.get("role", entry.get("name", {}))), column, true)
	var values: Array[String] = []
	for stat in ["int", "str", "end", "kno"]:
		values.append("%s %s" % [tr("UI_STAT_" + stat.to_upper()), str(entry.stats[stat])])
	UiKit.label(" · ".join(values), column, true)
	for id in skills:
		UiKit.label(Data.text(Data.skill(id).name) + ": " + Data.text(Data.skill(id).description), column, true)

func build_load(column: VBoxContainer) -> void:
	for slot in [0, 1]:
		var info := SaveSystem.get_info(slot) if SaveSystem.has_save(slot) else {}
		var action := UiKit.button("UI_SLOT", column, func() -> void:
			if SaveSystem.load_game(slot):
				close_menu()
			else:
				toast_key("UI_LOAD_FAILED"))
		action.text = tr("UI_SLOT") % slot
		action.disabled = info.is_empty()
		if not info.is_empty():
			UiKit.label("%s · %s · %s" % [str(info.get("timestamp", "")), str(info.get("area", "")), str(info.get("job", ""))], column, true)

