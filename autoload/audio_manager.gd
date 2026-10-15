extends Node
# Owner: Codex — stub from H0. Codex replaces this in H4 (see AGENTS.md § AudioManager).
# Until then every call is silent, with one warning per method so the console stays readable.

var _warned: Dictionary = {}


func play_music(id: String, _fade: float = 1.0) -> void:
	_stub("play_music", id)


func stop_music(_fade: float = 1.0) -> void:
	_stub("stop_music", "")


func play_ambience(id: String) -> void:
	_stub("play_ambience", id)


func play_sfx(id: String) -> void:
	_stub("play_sfx", id)


func set_volume(bus: String, _linear: float) -> void:
	_stub("set_volume", bus)


func _stub(method: String, id: String) -> void:
	if _warned.has(method):
		return
	_warned[method] = true
	push_warning("AudioManager stub: %s(%s) does nothing until H4" % [method, id])
