extends SceneTree
## Command line: "<godot>" --headless --path . --script res://scripts/dialogue/sync_translations.gd
## Adds missing line ids to every .dialogue file and updates localization/dialogue.csv (see TranslationSync).

func _initialize() -> void:
	var report := TranslationSync.run()
	print(TranslationSync.summary(report))
	quit()
