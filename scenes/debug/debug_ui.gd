class_name DebugUi
extends RefCounted
## Small helpers for developer-only screens (debug menu, placeholders, test scenes).
## Player-facing UI uses Codex's ui/theme.tres instead.

const FONT_SIZE := 10


static func small_theme() -> Theme:
	var theme := (load("res://ui/theme.tres") as Theme).duplicate() as Theme
	theme.default_font_size = FONT_SIZE
	return theme


static func label(text: String, color := Color.WHITE) -> Label:
	var node := Label.new()
	node.text = text
	node.add_theme_color_override("font_color", color)
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# Wrapping labels have no minimum width; without this they shrink to one letter per line.
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return node


static func button(text: String, on_pressed: Callable) -> Button:
	var node := Button.new()
	node.text = text
	node.pressed.connect(on_pressed)
	return node


## Full-screen dark panel with a margin, returns the VBoxContainer to fill.
static func panel(parent: Node, alpha := 0.92) -> VBoxContainer:
	var background := ColorRect.new()
	background.color = Color(0.08, 0.06, 0.1, alpha)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.theme = small_theme()
	parent.add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 8)
	background.add_child(margin)
	var box := VBoxContainer.new()
	margin.add_child(box)
	return box


static func set_locale(locale: String) -> void:
	TranslationServer.set_locale(locale)
	EventBus.locale_changed.emit(locale)
