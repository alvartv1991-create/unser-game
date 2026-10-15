extends Node
## Loads every JSON file in res://data/ and checks it for mistakes. See data/README.md.
## The humans edit these files, so every error names the file, the id and the field.
## Keys that start with "_" are notes for humans and are ignored everywhere.
## Returned dictionaries are shared: treat them as read-only, duplicate() before changing.

const DATA_DIR := "res://data/"
## Files that hold {id: entry} tables, readable through all(kind).
const TABLES: PackedStringArray = [
	"jobs", "skills", "items", "companions", "enemies", "encounters", "cheats",
	"speakers", "barks", "combat_text", "audio",
]
const REQUIRED := {
	"jobs": ["name", "description", "stats", "skill"],
	"skills": ["name", "description", "target", "effect"],
	"items": ["name", "description", "type"],
	"companions": ["name", "stats", "skills"],
	"enemies": ["name", "kind", "hp", "power"],
	"encounters": ["enemies", "party"],
	"cheats": ["name", "sequence"],
}
const REQUIRED_RULES: PackedStringArray = [
	"max_active_companions", "max_roster", "companion_combat_death", "downed_turns",
	"moral_low", "moral_high", "moral_min", "moral_max", "hp_base", "hp_per_end",
]
const STAT_KEYS: PackedStringArray = ["int", "str", "end", "kno"]
const ENEMY_KINDS: PackedStringArray = ["human", "alien", "animal"]
const PARTY_MODES: PackedStringArray = ["active", "all"]
const CHEAT_INPUTS: PackedStringArray = ["up", "down", "left", "right"]
const LOCALES: PackedStringArray = ["de", "en"]

## Problems found by the last reload(). The debug menu shows them.
var errors: PackedStringArray = []

var _tables: Dictionary = {}
var _rules: Dictionary = {}
var _protagonist: Dictionary = {}


func _ready() -> void:
	reload()


func reload() -> void:
	var found: PackedStringArray = []
	_tables.clear()
	for kind in TABLES:
		_tables[kind] = _load_json(DATA_DIR + kind + ".json", found)
	_rules = _load_json(DATA_DIR + "rules.json", found)
	_protagonist = _load_json(DATA_DIR + "protagonist.json", found)
	found.append_array(validate(_tables, _rules, _protagonist))
	errors = found
	for message in errors:
		push_error("[Data] " + message)


# --- Lookups ---------------------------------------------------------------

func job(id: String) -> Dictionary:
	return _entry("jobs", id)


func skill(id: String) -> Dictionary:
	return _entry("skills", id)


func item(id: String) -> Dictionary:
	return _entry("items", id)


func companion(id: String) -> Dictionary:
	return _entry("companions", id)


func enemy(id: String) -> Dictionary:
	return _entry("enemies", id)


func encounter(id: String) -> Dictionary:
	return _entry("encounters", id)


func cheat(id: String) -> Dictionary:
	return _entry("cheats", id)


## Whole table, e.g. all("jobs") -> {id: entry}. Order follows the JSON file.
func all(kind: String) -> Dictionary:
	return _tables.get(kind, {})


## True if the id exists in that table. Use this to probe without logging an error.
func has(kind: String, id: String) -> bool:
	return _tables.get(kind, {}).has(id)


func rules() -> Dictionary:
	return _rules


## One value from data/rules.json, with a fallback if it's missing.
func rule(key: String, default: Variant = null) -> Variant:
	return _rules.get(key, default)


func protagonist() -> Dictionary:
	return _protagonist


## Turns a {"de": ..., "en": ...} text into a string for the current locale.
## Missing English shows the German text with an [EN?] prefix. Never returns an empty string.
func text(value: Variant) -> String:
	if value is String:
		return value
	if value is Dictionary:
		var locale := TranslationServer.get_locale().left(2)
		var wanted := str(value.get(locale, ""))
		if wanted != "":
			return wanted
		var german := str(value.get("de", ""))
		if german != "":
			return german if locale == "de" else "[EN?] " + german
		for other in value.values():
			if str(other) != "":
				return str(other)
	return "[?]"


# --- Validation ------------------------------------------------------------

## Checks tables, rules and protagonist. Returns readable error messages (empty = all good).
func validate(tables: Dictionary, rules_data: Dictionary, protagonist_data: Dictionary) -> PackedStringArray:
	var out: PackedStringArray = []
	for kind in REQUIRED:
		var table: Dictionary = tables.get(kind, {})
		for id in table:
			var where: String = "%s.json › %s" % [kind, id]
			var entry: Variant = table[id]
			if not entry is Dictionary:
				out.append("%s: must be an object { ... }" % where)
				continue
			for field in REQUIRED[kind]:
				if not entry.has(field):
					out.append("%s: missing field \"%s\"" % [where, field])

	for id in tables.get("jobs", {}):
		var job_entry: Dictionary = tables.jobs[id]
		var where: String = "jobs.json › " + id
		_check_stats(job_entry.get("stats", {}), where, out)
		_check_ref(tables, "skills", job_entry.get("skill", ""), where + " › skill", out)
		if job_entry.has("start_weapon"):
			_check_ref(tables, "items", job_entry.start_weapon, where + " › start_weapon", out)
		for item_id in job_entry.get("start_items", {}):
			_check_ref(tables, "items", item_id, where + " › start_items", out)

	for id in tables.get("companions", {}):
		var comp: Dictionary = tables.companions[id]
		var where: String = "companions.json › " + id
		_check_stats(comp.get("stats", {}), where, out)
		for skill_id in comp.get("skills", []):
			_check_ref(tables, "skills", skill_id, where + " › skills", out)
		if comp.has("weapon"):
			_check_ref(tables, "items", comp.weapon, where + " › weapon", out)

	for id in tables.get("enemies", {}):
		var foe: Dictionary = tables.enemies[id]
		if not ENEMY_KINDS.has(str(foe.get("kind", ""))):
			out.append("enemies.json › %s › kind: must be one of %s" % [id, ", ".join(ENEMY_KINDS)])

	for id in tables.get("encounters", {}):
		var enc: Dictionary = tables.encounters[id]
		var where: String = "encounters.json › " + id
		var foes: Variant = enc.get("enemies", [])
		if not foes is Array or foes.is_empty():
			out.append(where + " › enemies: needs at least one enemy")
		else:
			for enemy_id in foes:
				_check_ref(tables, "enemies", enemy_id, where + " › enemies", out)
		if not PARTY_MODES.has(str(enc.get("party", ""))):
			out.append(where + " › party: must be \"active\" or \"all\"")
		for cheat_id in enc.get("cheats", []):
			_check_ref(tables, "cheats", cheat_id, where + " › cheats", out)
		for item_id in enc.get("loot", {}):
			_check_ref(tables, "items", item_id, where + " › loot", out)
		var music := str(enc.get("music", ""))
		if music != "":
			_check_ref(tables, "audio", music, where + " › music", out)

	for id in tables.get("cheats", {}):
		var sequence: Variant = tables.cheats[id].get("sequence", [])
		if not sequence is Array or sequence.is_empty():
			out.append("cheats.json › %s › sequence: needs at least one input" % id)
		else:
			for step in sequence:
				if not CHEAT_INPUTS.has(str(step)):
					out.append("cheats.json › %s › sequence: \"%s\" is not one of %s" % [id, step, ", ".join(CHEAT_INPUTS)])

	for key in REQUIRED_RULES:
		if not rules_data.has(key):
			out.append("rules.json: missing \"%s\"" % key)
	if not protagonist_data.has("name"):
		out.append("protagonist.json: missing \"name\"")

	for kind in tables:
		_check_texts(tables[kind], kind + ".json", out)
	_check_texts(protagonist_data, "protagonist.json", out)
	return out


func _check_stats(stats: Variant, where: String, out: PackedStringArray) -> void:
	if not stats is Dictionary:
		out.append(where + " › stats: must be an object")
		return
	for key in STAT_KEYS:
		var value: Variant = stats.get(key)
		if not (value is int or value is float):
			out.append("%s › stats: missing number \"%s\"" % [where, key])
		elif value < 1 or value > 10:
			out.append("%s › stats › %s: must be between 1 and 10 (is %s)" % [where, key, value])


func _check_ref(tables: Dictionary, kind: String, id: Variant, where: String, out: PackedStringArray) -> void:
	if not tables.get(kind, {}).has(str(id)):
		out.append("%s: unknown id \"%s\" (not in %s.json)" % [where, id, kind])


## Every {"de": .., "en": ..} object must have both languages filled in.
func _check_texts(value: Variant, where: String, out: PackedStringArray) -> void:
	if value is Dictionary:
		if value.has("de") or value.has("en"):
			for locale in LOCALES:
				if str(value.get(locale, "")).strip_edges() == "":
					out.append("%s: missing \"%s\" text" % [where, locale])
			return
		for key in value:
			_check_texts(value[key], "%s › %s" % [where, key], out)
	elif value is Array:
		for i in value.size():
			_check_texts(value[i], "%s › %d" % [where, i + 1], out)


# --- Loading ---------------------------------------------------------------

func _entry(kind: String, id: String) -> Dictionary:
	var table: Dictionary = _tables.get(kind, {})
	if not table.has(id):
		push_error("[Data] Unknown id \"%s\" in %s.json" % [id, kind])
		return {}
	return table[id]


func _load_json(path: String, out: PackedStringArray) -> Dictionary:
	if not FileAccess.file_exists(path):
		out.append("%s is missing" % path.trim_prefix(DATA_DIR))
		return {}
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		out.append("%s, line %d: %s" % [path.trim_prefix(DATA_DIR), json.get_error_line(), json.get_error_message()])
		return {}
	if not json.data is Dictionary:
		out.append("%s: must start with { and end with }" % path.trim_prefix(DATA_DIR))
		return {}
	return _strip_notes(json.data)


## Removes every key starting with "_" (notes for humans), at any depth.
func _strip_notes(value: Variant) -> Variant:
	if value is Dictionary:
		var clean := {}
		for key in value:
			if not str(key).begins_with("_"):
				clean[key] = _strip_notes(value[key])
		return clean
	if value is Array:
		var clean_list := []
		for element in value:
			clean_list.append(_strip_notes(element))
		return clean_list
	return value
