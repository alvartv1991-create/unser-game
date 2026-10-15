class_name CombatText
extends RefCounted
## Turns combat events into log lines, using the templates in data/combat_text.json.
## Events without a template (turn, round, hit, ...) have no line.


static func line(event: Dictionary, state: CombatState, rng: RandomNumberGenerator) -> String:
	var templates: Dictionary = Data.all("combat_text").get("log", {})
	var template: Variant = templates.get(event.type)
	if event.type == "talk_fail":
		var approach: Dictionary = Data.all("talk").get(str(event.get("approach", "")), {})
		if approach.has("fail"):
			template = approach.fail
	if template == null:
		return ""
	if template is Array:
		if template.is_empty():
			return ""
		template = template[rng.randi() % template.size()]
	return Data.text(template).format(params(event, state))


static func params(event: Dictionary, state: CombatState) -> Dictionary:
	var result := {}
	for key in ["actor", "target"]:
		var f := state.fighter(str(event.get(key, "")))
		result[key] = f.display_name() if f else ""
	result.amount = event.get("amount", 0)
	result.turns = event.get("turns", 0)
	if event.has("item"):
		result.item = Data.text(Data.item(str(event.item)).name)
	if event.has("weapon"):
		result.weapon = Data.text(Data.item(str(event.weapon)).name)
	if event.has("approach"):
		result.approach = Data.text(Data.all("talk").get(str(event.approach), {}).get("name", ""))
	return result
