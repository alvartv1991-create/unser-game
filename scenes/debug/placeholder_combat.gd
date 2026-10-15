extends CanvasLayer
## Stands in for scenes/combat/combat.tscn until H1 exists. Lets you pick how the fight ends.
## Follows the combat contract: start(encounter_id), then EventBus.combat_finished(result).

var _encounter_id := ""


func start(encounter_id: String) -> void:
	_encounter_id = encounter_id
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	var encounter := Data.encounter(encounter_id)
	var box := DebugUi.panel(self, 1.0)
	box.add_child(DebugUi.label("Kampf: %s  (Platzhalter bis H1)" % encounter_id, Color("#3ff0f0")))
	var foes: PackedStringArray = []
	for enemy_id in encounter.get("enemies", []):
		foes.append(Data.text(Data.enemy(enemy_id).name))
	box.add_child(DebugUi.label("Gegner: " + ", ".join(foes)))
	box.add_child(DebugUi.label("Party (%s): %s" % [encounter.party, ", ".join(_fighters())]))
	box.add_child(DebugUi.button("Gewinnen", _finish.bind("win", false)))
	box.add_child(DebugUi.button("Gewinnen, aber ein Begleiter stirbt", _finish.bind("win", true)))
	box.add_child(DebugUi.button("Verlieren", _finish.bind("lose", false)))
	box.add_child(DebugUi.button("Rausreden", _finish.bind("talk", false)))
	box.add_child(DebugUi.button("Cheaten", _finish.bind("cheat", false)))


func _fighters() -> Array[String]:
	return GameState.combat_party(str(Data.encounter(_encounter_id).get("party", "active")))


func _finish(outcome: String, kill_one: bool) -> void:
	var died: Array[String] = []
	var fighters := _fighters()
	if kill_one and not fighters.is_empty():
		GameState.kill_companion(fighters[0], "combat:" + _encounter_id)
		died.append(fighters[0])
	var loot: Dictionary = Data.encounter(_encounter_id).get("loot", {}) if outcome == "win" else {}
	for item_id in loot:
		GameState.add_item(item_id, int(loot[item_id]))
	EventBus.combat_finished.emit({encounter_id = _encounter_id, outcome = outcome, loot = loot, died = died})
