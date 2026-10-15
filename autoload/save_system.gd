extends Node
# Owner: Codex — stub from H0. Codex replaces this in H4 (see AGENTS.md § SaveSystem).
# Until then nothing is saved, and every call warns once.

var _warned: Dictionary = {}


func save_game(slot: int) -> bool:
	_stub("save_game", slot)
	return false


func load_game(slot: int) -> bool:
	_stub("load_game", slot)
	return false


func has_save(_slot: int) -> bool:
	return false


func get_info(_slot: int) -> Dictionary:
	return {}


func _stub(method: String, slot: int) -> void:
	if _warned.has(method):
		return
	_warned[method] = true
	push_warning("SaveSystem stub: %s(%d) does nothing until H4" % [method, slot])
