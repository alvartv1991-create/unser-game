class_name TestCase
extends RefCounted
## Base class for tests. Put files named test_*.gd in tests/<area>/, extend TestCase,
## and write methods named test_*. Optional: before_each() runs before every test.
## Run all: "<godot>" --headless --path . res://tests/test_runner.tscn

var failures: PackedStringArray = []


func assert_true(condition: bool, message: String = "expected true") -> void:
	if not condition:
		failures.append(message)


func assert_false(condition: bool, message: String = "expected false") -> void:
	if condition:
		failures.append(message)


func assert_eq(actual: Variant, expected: Variant, message: String = "") -> void:
	if typeof(actual) != typeof(expected) and not (_is_number(actual) and _is_number(expected)):
		failures.append("%s: expected %s (%s), got %s (%s)" % [message, expected, type_string(typeof(expected)), actual, type_string(typeof(actual))])
	elif actual != expected:
		failures.append("%s: expected %s, got %s" % [message, expected, actual])


func fail(message: String) -> void:
	failures.append(message)


func _is_number(value: Variant) -> bool:
	return value is int or value is float
