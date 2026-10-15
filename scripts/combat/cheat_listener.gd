class_name CheatListener
extends RefCounted
## Watches direction presses for cheat codes from data/cheats.json (e.g. ↑↑↓↓←→←→).
## Only the codes passed in (the current encounter's "cheats" list) can trigger.
## Reusable: later bosses just list their own code.

var _codes: Dictionary = {}          # cheat_id -> PackedStringArray
var _recent := PackedStringArray()
var _longest := 0


func _init(cheat_ids: Array) -> void:
	for cheat_id in cheat_ids:
		if Data.has("cheats", cheat_id):
			var sequence := PackedStringArray(Data.cheat(cheat_id).sequence)
			_codes[cheat_id] = sequence
			_longest = maxi(_longest, sequence.size())


## Feed one input ("up", "down", "left", "right"). Returns the cheat id when a code is complete.
func feed(input: String) -> String:
	if _codes.is_empty() or input == "":
		return ""
	_recent.append(input)
	if _recent.size() > _longest:
		_recent.remove_at(0)
	for cheat_id in _codes:
		var code: PackedStringArray = _codes[cheat_id]
		if _recent.size() >= code.size() and _recent.slice(_recent.size() - code.size()) == code:
			_recent.clear()
			return cheat_id
	return ""


## Maps a raw key or gamepad press to "up"/"down"/"left"/"right" ("" for anything else).
## Raw keys on purpose: the arrows also move the menu focus, and that's fine.
static func input_from_event(event: InputEvent) -> String:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_UP:
				return "up"
			KEY_DOWN:
				return "down"
			KEY_LEFT:
				return "left"
			KEY_RIGHT:
				return "right"
	elif event is InputEventJoypadButton and event.pressed:
		match event.button_index:
			JOY_BUTTON_DPAD_UP:
				return "up"
			JOY_BUTTON_DPAD_DOWN:
				return "down"
			JOY_BUTTON_DPAD_LEFT:
				return "left"
			JOY_BUTTON_DPAD_RIGHT:
				return "right"
	return ""
