extends Control

var page: String = "title"
var selected_job: String = "doctor"
var body: Control
var detail: VBoxContainer

func _ready() -> void:
	add_to_group("title_ui")
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var backdrop := ColorRect.new()
	backdrop.color = Color("1c2238")
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	for suffix in ["sky", "distance", "world", "foreground"]:
		var skyline := TextureRect.new()
		var crop := AtlasTexture.new()
		crop.atlas = load("res://assets/backgrounds/street_%s.png" % suffix)
		crop.region = Rect2(0, 0, 640, 360)
		skyline.texture = crop
		skyline.set_anchors_preset(Control.PRESET_FULL_RECT)
		skyline.stretch_mode = TextureRect.STRETCH_SCALE
		skyline.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(skyline)
	body = Control.new()
	body.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(body)
	EventBus.locale_changed.connect(func(_locale: String) -> void: rebuild())
	await get_tree().process_frame
	var overlay := get_tree().get_first_node_in_group("global_ui") as WorldUI
	if overlay and not overlay.settings.has_section_key("display", "language"):
		page = "language"
	rebuild()

func rebuild() -> void:
	if not is_instance_valid(body):
		return
	UiKit.clear(body)
	var column := UiKit.panel(body, Rect2(130, 36, 380, 286) if page != "jobs" else Rect2(20, 14, 600, 332))
	UiKit.label(tr("UI_TITLE"), column)
	UiKit.label(tr("UI_SUBTITLE"), column)
	match page:
		"language":
			UiKit.button("UI_DE", column, language.bind("de"))
			UiKit.button("UI_EN", column, language.bind("en"))
		"title":
			UiKit.button("UI_NEW_GAME", column, func() -> void: page = "jobs"; rebuild())
			var load_button := UiKit.button("UI_LOAD", column, overlay_menu.bind("load"))
			load_button.disabled = not SaveSystem.has_save(0) and not SaveSystem.has_save(1)
			UiKit.button("UI_VISUAL_PREVIEW", column, func() -> void:
				SceneRouter.go_to("res://scenes/levels/test_visual_street.tscn", "start"))
			UiKit.button("UI_ART_GALLERY", column, func() -> void:
				SceneRouter.go_to("res://scenes/ui/test_art_gallery.tscn"))
			UiKit.button("UI_OPTIONS", column, overlay_menu.bind("options"))
			UiKit.button("UI_QUIT", column, func() -> void: get_tree().quit())
		"jobs": build_jobs(column)
	UiKit.focus_first(body)

func language(locale: String) -> void:
	page = "title"
	var overlay := get_tree().get_first_node_in_group("global_ui") as WorldUI
	if overlay:
		overlay.choose_language(locale)

func overlay_menu(target: String) -> void:
	get_tree().call_group("global_ui", "open_menu", target)

func build_jobs(column: VBoxContainer) -> void:
	UiKit.label(tr("UI_JOBS"), column)
	var row := HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(row)
	var jobs := UiKit.scroll(row)
	jobs.get_parent().custom_minimum_size.x = 180
	for id in Data.all("jobs"):
		var action := UiKit.button("", jobs, select_job.bind(id))
		action.text = Data.text(Data.job(id).name)
	detail = UiKit.scroll(row)
	detail.get_parent().custom_minimum_size.x = 350
	select_job(selected_job)
	var footer := HBoxContainer.new()
	column.add_child(footer)
	UiKit.button("UI_BACK", footer, func() -> void: page = "title"; rebuild())
	UiKit.button("UI_START", footer, func() -> void:
		GameState.new_game(selected_job)
		AudioManager.play_sfx("sfx_ui_confirm")
		SceneRouter.go_to("res://scenes/levels/area1_bunker.tscn", "start"))

func select_job(id: String) -> void:
	selected_job = id
	UiKit.clear(detail)
	var job := Data.job(id)
	UiKit.label(GameState.player_name(), detail)
	UiKit.label(Data.text(job.description), detail, true)
	for stat in ["int", "str", "end", "kno"]:
		var row := HBoxContainer.new()
		detail.add_child(row)
		var caption := UiKit.label(tr("UI_STAT_" + stat.to_upper()), row)
		caption.custom_minimum_size.x = 105
		var bar := ProgressBar.new()
		bar.custom_minimum_size = Vector2(175, 16)
		bar.max_value = 10
		bar.value = job.stats[stat]
		bar.show_percentage = false
		row.add_child(bar)
		UiKit.label(str(job.stats[stat]), row)
	var skill := Data.skill(job.skill)
	UiKit.label(Data.text(skill.name), detail)
	UiKit.label(Data.text(skill.description), detail, true)
