@tool
extends EditorScript
## One click in the Godot editor: open this file in the script editor, then File -> Run (Ctrl+Shift+X).
## Adds missing line ids to every .dialogue file and updates localization/dialogue.csv (see TranslationSync).

func _run() -> void:
	var report := TranslationSync.run()
	print(TranslationSync.summary(report))
	EditorInterface.get_resource_filesystem().scan()
