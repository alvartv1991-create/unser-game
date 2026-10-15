class_name AlphaEnd
extends Control
## "Ende der Alpha": what your playthrough did. Moral appears only here, as a word, never a number.
## All texts are [TEMP] keys in localization/story.csv (END_*).

const MORAL_WORDS := [[-60, "END_MORAL_1"], [-25, "END_MORAL_2"], [25, "END_MORAL_3"], [60, "END_MORAL_4"], [101, "END_MORAL_5"]]

var _column: VBoxContainer


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var backdrop := ColorRect.new()
	backdrop.color = Color("14101a")
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	EventBus.locale_changed.connect(func(_l: String) -> void: _build())
	AudioManager.play_music("music_title")
	_build()


func _build() -> void:
	for child in get_children():
		if child.has_meta("ui"):
			child.queue_free()
	_column = UiKit.panel(self, Rect2(40, 14, 560, 332))
	_column.get_parent().set_meta("ui", true)
	var heading := UiKit.label(tr("END_TITLE"), _column)
	heading.add_theme_color_override("font_color", Color("e0a94a"))
	var list := UiKit.scroll(_column)
	for line in summary_lines():
		UiKit.label(line, list, true)
	UiKit.label(tr("END_THANKS"), _column, true)
	var row := HBoxContainer.new()
	_column.add_child(row)
	UiKit.button("END_NEW_GAME", row, func() -> void:
		GameState.reset()
		SceneRouter.go_to("res://scenes/ui/title.tscn"))
	UiKit.focus_first(_column.get_parent())


## Every line of the summary, already translated. Static so tests can check it without a scene.
static func summary_lines() -> Array[String]:
	var t := TranslationServer
	var lines: Array[String] = []
	var job_id := str(GameState.player.get("job_id", ""))
	var job_name := Data.text(Data.job(job_id).name) if Data.has("jobs", job_id) else job_id
	job_name = job_name.trim_prefix("[TEMP] ")
	lines.append(t.translate("END_JOB") % job_name)
	var camp := str(GameState.get_flag("raiders_camp_resolved", ""))
	lines.append(t.translate("END_CAMP") % inner("END_CAMP_" + (camp.to_upper() if camp != "" else "NONE")))
	if camp == "fight":
		lines.append(t.translate("END_RAIDER_SPARED" if GameState.get_flag("raider_spared", true) else "END_RAIDER_KILLED"))
	var dilemma := str(GameState.get_flag("dilemma_choice", ""))
	lines.append(t.translate("END_DILEMMA") % inner("END_DILEMMA_" + (dilemma.to_upper() if dilemma != "" else "NONE")))
	for id: String in GameState.companions:
		var c: Dictionary = GameState.companions[id]
		var name := Data.text(Data.companion(id).name).trim_prefix("[TEMP] ")
		if c.alive and c.recruited:
			lines.append(t.translate("END_ALIVE") % name)
		elif not c.alive:
			var how := "END_DIED_COMBAT" if str(c.death_reason).begins_with("combat:") else "END_DIED_STORY"
			lines.append(t.translate(how) % name)
		else:
			lines.append(t.translate("END_NOT_RECRUITED") % name)
	if GameState.get_flag("holy_sword_broken", false):
		lines.append(t.translate("END_SWORD_BROKEN"))
	elif GameState.get_flag("holy_sword_taken", false):
		lines.append(t.translate("END_SWORD_INTACT"))
	else:
		lines.append(t.translate("END_SWORD_LEFT"))
	lines.append(t.translate("END_CULT_FOUND" if GameState.get_flag("cult_teaser_found", false) else "END_CULT_MISSED"))
	lines.append(t.translate("END_MORAL") % inner(moral_word(GameState.moral)))
	return lines


## A translated piece that goes inside another [TEMP] line.
static func inner(key: String) -> String:
	return TranslationServer.translate(key).trim_prefix("[TEMP] ")


static func moral_word(moral: int) -> String:
	for entry: Array in MORAL_WORDS:
		if moral < int(entry[0]):
			return entry[1]
	return "END_MORAL_5"
