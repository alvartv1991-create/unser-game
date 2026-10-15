extends Node
## Finds every tests/**/test_*.gd, runs each test_* method and quits with exit code 1 on any failure.
## Run: "<godot>" --headless --path . res://tests/test_runner.tscn
## Optional filter: ... -- --only game_state   (runs files whose path contains "game_state")

const TESTS_DIR := "res://tests"


func _ready() -> void:
	# Let every autoload finish its _ready first.
	await get_tree().process_frame
	var filter := ""
	var args := OS.get_cmdline_user_args()
	var only_index := args.find("--only")
	if only_index >= 0 and only_index + 1 < args.size():
		filter = args[only_index + 1]

	var passed := 0
	var failed := 0
	for path in _find_test_files(TESTS_DIR):
		if filter != "" and not path.contains(filter):
			continue
		var script := load(path) as GDScript
		if script == null or not script.can_instantiate():
			printerr("FAIL %s: script does not load" % path)
			failed += 1
			continue
		for method in script.get_script_method_list():
			if not str(method.name).begins_with("test_"):
				continue
			var test: Object = script.new()
			if test.has_method("before_each"):
				await test.call("before_each")
			await test.call(method.name)
			var label := "%s :: %s" % [path.trim_prefix(TESTS_DIR + "/"), method.name]
			if test.failures.is_empty():
				print("pass  " + label)
				passed += 1
			else:
				printerr("FAIL  %s\n        %s" % [label, "\n        ".join(test.failures)])
				failed += 1
	print("\n%d passed, %d failed" % [passed, failed])
	GameState.reset()
	get_tree().quit(1 if failed > 0 else 0)


func _find_test_files(root: String) -> PackedStringArray:
	var found := PackedStringArray()
	var dir := DirAccess.open(root)
	if dir == null:
		return found
	for sub in dir.get_directories():
		found.append_array(_find_test_files(root.path_join(sub)))
	for file in dir.get_files():
		if file.begins_with("test_") and file.ends_with(".gd") and file != "test_runner.gd" and file != "test_case.gd":
			found.append(root.path_join(file))
	found.sort()
	return found
