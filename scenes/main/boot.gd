extends Control
## First scene. Goes to the title screen once Codex builds it (H2); until then shows a placeholder.


func _ready() -> void:
	if ResourceLoader.exists(SceneRouter.TITLE_SCENE):
		SceneRouter.go_to.call_deferred(SceneRouter.TITLE_SCENE)
		return
	var box := DebugUi.panel(self, 1.0)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(DebugUi.label("Unser Game — Alpha", Color("#3ff0f0")))
	box.add_child(DebugUi.label("Noch kein Titelbildschirm (kommt mit H2)."))
	box.add_child(DebugUi.button("Debug-Menü öffnen (F1)", SceneRouter.toggle_debug_menu))
