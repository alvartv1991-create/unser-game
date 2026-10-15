extends Control
const IDS := ["player", "cook", "tinkerer", "clerk", "cultist", "raider_scavenger", "raider_brute"]
const ANIMATIONS := ["idle", "walk", "jump", "fall", "combat_idle", "attack", "skill", "hurt", "downed"]
var figures: Array[AnimatedSprite2D] = []
var phase: int = 0
var elapsed: float = 0.0
var status: Label

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	build()
	EventBus.locale_changed.connect(func(_locale: String) -> void: build())

func build() -> void:
	UiKit.clear(self)
	figures.clear()
	var background := ColorRect.new()
	background.color = Color("1c2238")
	background.size = get_viewport_rect().size
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var heading := UiKit.label(tr("UI_ART_GALLERY"), self)
	heading.position = Vector2(12, 6)
	status = UiKit.label(tr("UI_ART_ANIMATION") % ANIMATIONS[phase], self)
	status.position = Vector2(12, 26)
	var back := UiKit.button("UI_BACK", self, func() -> void: SceneRouter.go_to("res://scenes/ui/title.tscn"))
	back.position = Vector2(540, 8)
	back.size.x = 88
	for i in IDS.size():
		var id: String = IDS[i]
		var panel := PanelContainer.new()
		panel.position = Vector2(8 + (i % 4) * 156, 52 + (i / 4) * 142)
		panel.size = Vector2(150, 134)
		add_child(panel)
		var content := Control.new()
		content.custom_minimum_size = Vector2(128, 114)
		panel.add_child(content)
		var caption := UiKit.label(tr("UI_ART_" + id.to_upper()), content)
		caption.size = Vector2(128, 20)
		caption.add_theme_font_size_override("font_size", 11)
		caption.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		var portrait := TextureRect.new()
		portrait.texture = load("res://assets/portraits/%s.png" % id)
		portrait.position = Vector2(0, 22)
		portrait.size = Vector2(64, 64)
		content.add_child(portrait)
		var figure := AnimatedSprite2D.new()
		figure.sprite_frames = load("res://assets/sprites/characters/%s.tres" % id)
		figure.scale = Vector2(2, 2)
		figure.position = Vector2(101, 56)
		figure.play(ANIMATIONS[phase])
		content.add_child(figure)
		figures.append(figure)
	back.grab_focus.call_deferred()

func _process(delta: float) -> void:
	elapsed += delta
	if elapsed < 1.8:
		return
	elapsed = 0.0
	phase = (phase + 1) % ANIMATIONS.size()
	status.text = tr("UI_ART_ANIMATION") % ANIMATIONS[phase]
	for figure in figures:
		figure.play(ANIMATIONS[phase])
