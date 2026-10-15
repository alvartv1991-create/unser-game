class_name UiKit
extends RefCounted

static func label(value: String, parent: Node, wrap: bool = false) -> Label:
	var result := Label.new()
	result.text = value
	if wrap:
		result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		result.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(result)
	return result

static func button(key: String, parent: Node, callback: Callable) -> Button:
	var result := Button.new()
	result.text = TranslationServer.translate(key)
	result.custom_minimum_size.y = 24
	result.pressed.connect(func() -> void:
		AudioManager.play_sfx("sfx_ui_click")
		callback.call())
	parent.add_child(result)
	return result

static func panel(parent: Node, bounds: Rect2) -> VBoxContainer:
	var panel_node := PanelContainer.new()
	panel_node.position = bounds.position
	panel_node.size = bounds.size
	parent.add_child(panel_node)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 5)
	panel_node.add_child(column)
	return column

static func scroll(parent: Node) -> VBoxContainer:
	var container := ScrollContainer.new()
	container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	parent.add_child(container)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.add_child(column)
	return column

static func clear(parent: Node) -> void:
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()

static func focus_first(parent: Node) -> void:
	for child in parent.find_children("*", "Button", true, false):
		if child.is_visible_in_tree() and not child.disabled:
			child.grab_focus.call_deferred()
			return

