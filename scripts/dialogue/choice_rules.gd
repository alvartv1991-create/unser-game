class_name ChoiceRules
extends RefCounted
## Decides how a dialogue choice whose condition is not met is shown.
## - Moral conditions (moral_is) are ALWAYS hidden: moral is a secret.
## - Other conditions are hidden, unless the choice has the tag [#show_locked]:
##   then it is shown greyed out with the reason, e.g. "[Arzt/Ärztin]".
##   The reason is worked out from the condition (job, item, companion) or set by hand with [#show_locked=KEY]
##   (KEY is a translation key from localization/story.csv).

enum { SHOW, LOCKED, HIDDEN }

const TAG := "show_locked"
static var _call := RegEx.create_from_string("(job_is|has_item|in_party|is_recruited|is_alive)\\(\\s*\"([a-z0-9_]+)\"")


## SHOW, LOCKED or HIDDEN for a response with these properties.
static func state(is_allowed: bool, condition: String, tags: PackedStringArray) -> int:
	if is_allowed:
		return SHOW
	if condition.contains("moral"):
		return HIDDEN
	for tag in tags:
		if tag == TAG or tag.begins_with(TAG + "="):
			return LOCKED
	return HIDDEN


## The localized reason shown in front of a locked choice, without brackets.
static func reason(condition: String, tags: PackedStringArray) -> String:
	for tag in tags:
		if tag.begins_with(TAG + "=") and tag.length() > TAG.length() + 1:
			return TranslationServer.translate(tag.substr(TAG.length() + 1))
	var found := _call.search(condition)
	if found == null:
		return "?"
	var id := found.get_string(2)
	match found.get_string(1):
		"job_is":
			return Data.text(Data.job(id).get("name", id)) if Data.has("jobs", id) else id
		"has_item":
			return Data.text(Data.item(id).get("name", id)) if Data.has("items", id) else id
		_:
			return Data.text(Data.companion(id).get("name", id)) if Data.has("companions", id) else id
