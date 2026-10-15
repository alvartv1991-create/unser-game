class_name TranslationSync
extends RefCounted
## Keeps the English translation of dialogue in step with the German .dialogue files.
## 1. Every spoken line and choice in res://dialogue/ gets a static id, e.g. [ID:COOK_FIRST_MEET_03].
##    Existing ids are never changed, so editing German text never loses the English.
## 2. localization/dialogue.csv gets one row per id: de = the current German text,
##    en = the existing English. New lines get "[EN?] <German>" until someone translates them.
## Run it: Godot script editor -> open scripts/dialogue/sync_translations_editor.gd -> File -> Run,
## or from the command line: --headless --path . --script res://scripts/dialogue/sync_translations.gd

const DIALOGUE_DIR := "res://dialogue"
const CSV_PATH := "res://localization/dialogue.csv"
const MISSING_EN := "[EN?] "

static var _id_re := RegEx.create_from_string("\\[ID:([^\\]]*)\\]")
static var _speaker_re := RegEx.create_from_string("^([A-Za-z_][A-Za-z0-9_]*): ")
static var _cond_re := RegEx.create_from_string("\\[if [^\\]]*\\]")
static var _tag_re := RegEx.create_from_string("\\[#[^\\]]*\\]")
static var _goto_re := RegEx.create_from_string("\\s*=>.*$")
const NOT_TEXT: Array[String] = ["#", "~", "=>", "$>", "if ", "elif ", "else", "match ", "when ", "while ", "do ", "set ", "import ", "using "]


## Report of one run: {added: [ids], changed_german: [ids], removed: [ids], files_changed: [paths]}
static func run(dialogue_dir: String = DIALOGUE_DIR, csv_path: String = CSV_PATH) -> Dictionary:
	var report := {"added": [], "changed_german": [], "removed": [], "files_changed": []}
	var old_rows := read_csv(csv_path)
	var used: Dictionary = {}
	for id in old_rows:
		used[id] = true
	var new_rows: Dictionary = {}   # id -> de, in file order
	for path in find_dialogue_files(dialogue_dir):
		var source := FileAccess.get_file_as_string(path)
		var result := process_source(source, path.get_file().get_basename(), used)
		for id in result.texts:
			new_rows[id] = result.texts[id]
		if result.source != source:
			var file := FileAccess.open(path, FileAccess.WRITE)
			file.store_string(result.source)
			file.close()
			report.files_changed.append(path)
	var lines: Array = []
	for id in new_rows:
		var de: String = new_rows[id]
		var en := ""
		if old_rows.has(id):
			en = old_rows[id].en
			if old_rows[id].de != de and not en.begins_with(MISSING_EN):
				report.changed_german.append(id)
		if en.is_empty() or (en.begins_with(MISSING_EN) and en != MISSING_EN + de):
			if not old_rows.has(id):
				report.added.append(id)
			en = MISSING_EN + de
		lines.append([id, de, en])
	for id in old_rows:
		if not new_rows.has(id):
			report.removed.append(id)
	var out := FileAccess.open(csv_path, FileAccess.WRITE)
	out.store_csv_line(PackedStringArray(["keys", "de", "en"]))
	for row in lines:
		out.store_csv_line(PackedStringArray(row))
	out.close()
	return report


## Human-readable result for the console.
static func summary(report: Dictionary) -> String:
	var out := "Dialogue translations synced.\n"
	out += "  New lines (English still missing, marked [EN?]): %d\n" % report.added.size()
	if not report.changed_german.is_empty():
		out += "  German changed, please re-check the English of: %s\n" % ", ".join(report.changed_german)
	if not report.removed.is_empty():
		out += "  Removed (no longer in any file): %s\n" % ", ".join(report.removed)
	out += "  Files that got new ids: %d" % report.files_changed.size()
	return out


## Adds missing ids to one file's text. Returns {source, texts: {id: German text}}.
## `used` holds every id already taken (it is updated).
static func process_source(source: String, file_id: String, used: Dictionary) -> Dictionary:
	var out_lines: PackedStringArray = []
	var texts: Dictionary = {}
	var cue := "start"
	var counter := 0
	for raw in source.split("\n"):
		var line: String = raw
		var body := line.strip_edges()
		if body.begins_with("~ "):
			cue = body.substr(2).strip_edges()
			counter = 0
		if is_text_line(body):
			var found := _id_re.search(body)
			var id := ""
			if found:
				id = found.get_string(1)
			else:
				id = _next_id(file_id, cue, counter, used)
				line = line.rstrip(" \t") + " [ID:%s]" % id
			counter += 1
			used[id] = true
			texts[id] = display_text(body)
		out_lines.append(line)
	return {"source": "\n".join(out_lines), "texts": texts}


## True for spoken lines and choices; false for cues, commands, conditions, jumps and comments.
static func is_text_line(body: String) -> bool:
	if body.is_empty():
		return false
	for start in NOT_TEXT:
		if body.begins_with(start):
			return false
	return true


## The text players see: no choice dash, speaker, condition, tags, id or jump.
static func display_text(body: String) -> String:
	var text := body
	if text.begins_with("- "):
		text = text.substr(2)
	elif text.begins_with("% "):
		text = text.substr(2)
	text = _id_re.sub(text, "", true)
	text = _cond_re.sub(text, "", true)
	text = _tag_re.sub(text, "", true)
	text = _goto_re.sub(text, "", true)
	var speaker := _speaker_re.search(text)
	if speaker:
		text = text.substr(speaker.get_end())
	return text.strip_edges()


static func read_csv(path: String) -> Dictionary:
	var rows: Dictionary = {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return rows
	var header := file.get_csv_line()
	var de_col := header.find("de")
	var en_col := header.find("en")
	while not file.eof_reached():
		var row := file.get_csv_line()
		if row.size() < 2 or row[0].is_empty():
			continue
		rows[row[0]] = {
			"de": row[de_col] if de_col >= 0 and de_col < row.size() else "",
			"en": row[en_col] if en_col >= 0 and en_col < row.size() else "",
		}
	return rows


static func find_dialogue_files(dir_path: String) -> PackedStringArray:
	var found := PackedStringArray()
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return found
	for sub in dir.get_directories():
		found.append_array(find_dialogue_files(dir_path.path_join(sub)))
	for file in dir.get_files():
		if file.ends_with(".dialogue"):
			found.append(dir_path.path_join(file))
	found.sort()
	return found


static func _next_id(file_id: String, cue: String, counter: int, used: Dictionary) -> String:
	var n := counter + 1
	while true:
		var id := "%s_%s_%02d" % [file_id.to_upper(), cue.to_upper(), n]
		if not used.has(id):
			return id
		n += 1
	return ""
