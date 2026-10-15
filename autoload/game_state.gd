extends Node
## The whole state of a playthrough: protagonist, companions, party, items, flags and the hidden moral.
## Everything here must survive to_dict() -> JSON -> from_dict(). See AGENTS.md § GameState.

const SAVE_VERSION := 1

var player: Dictionary = {}        # {name, job_id, stats: {int, str, end, kno}, hp, max_hp, weapon_id}; name "" = protagonist default
var companions: Dictionary = {}    # id -> {recruited, alive, hp, max_hp, death_reason}
var party: Array[String] = []      # active companion ids (recruited and alive)
var inventory: Dictionary = {}     # item_id -> count
var flags: Dictionary = {}         # flag_id -> Variant
var moral: int = 0                 # hidden "Solidarität". Never show it in the UI (debug overlay only).
var objective: String = ""         # translation key from localization/story.csv; show it with tr()
var unlocked_areas: Array[String] = []


func _ready() -> void:
	reset()


## Empty state, as on the title screen. Companions from data/companions.json start unrecruited and alive.
func reset() -> void:
	player = {}
	party.clear()
	inventory.clear()
	flags.clear()
	moral = 0
	objective = ""
	unlocked_areas.clear()
	companions.clear()
	for id in Data.all("companions"):
		var max_hp := max_hp_for(Data.companion(id).get("stats", {}))
		companions[id] = {recruited = false, alive = true, hp = max_hp, max_hp = max_hp, death_reason = ""}


## Starts a playthrough. The protagonist is a fixed person (for now), so only the former job is chosen.
func new_game(job_id: String) -> void:
	reset()
	var job: Dictionary = Data.job(job_id)
	var stats := _int_stats(job.get("stats", {}))
	var max_hp := max_hp_for(stats)
	player = {
		name = "",
		job_id = job_id,
		stats = stats,
		hp = max_hp,
		max_hp = max_hp,
		weapon_id = str(job.get("start_weapon", "fists")),
	}
	# The equipped weapon is always an inventory item too (except bare fists).
	if player.weapon_id != "fists":
		add_item(player.weapon_id)
	var start_items: Dictionary = job.get("start_items", {})
	for item_id in start_items:
		add_item(item_id, int(start_items[item_id]))
	unlocked_areas.append("area1_vorstadt")
	party_changed_all()


func max_hp_for(stats: Dictionary) -> int:
	return int(Data.rule("hp_base", 20)) + int(stats.get("end", 1)) * int(Data.rule("hp_per_end", 4))


## Always use this for the protagonist's name: a custom name (possible later), otherwise data/protagonist.json.
func player_name() -> String:
	var custom := str(player.get("name", ""))
	if custom != "":
		return custom
	return Data.text(Data.protagonist().get("name", "?"))


func job_is(job_id: String) -> bool:
	return player.get("job_id", "") == job_id


# --- Flags and moral -------------------------------------------------------

func set_flag(id: String, value: Variant = true) -> void:
	if flags.has(id) and flags[id] == value:
		return
	flags[id] = value
	EventBus.flag_changed.emit(id, value)


func get_flag(id: String, default: Variant = false) -> Variant:
	return flags.get(id, default)


func add_moral(delta: int) -> void:
	moral = clampi(moral + delta, int(Data.rule("moral_min", -100)), int(Data.rule("moral_max", 100)))
	EventBus.moral_changed.emit(moral)


## "low", "neutral" or "high", using the thresholds in data/rules.json. Gate hidden dialogue options with this.
func moral_is(band: String) -> bool:
	var low := int(Data.rule("moral_low", -25))
	var high := int(Data.rule("moral_high", 25))
	match band:
		"low":
			return moral <= low
		"high":
			return moral >= high
		"neutral":
			return moral > low and moral < high
	push_error("GameState.moral_is: unknown band \"%s\" (use low, neutral or high)" % band)
	return false


# --- Companions ------------------------------------------------------------

func recruit(companion_id: String) -> void:
	if not companions.has(companion_id):
		push_error("GameState.recruit: unknown companion \"%s\"" % companion_id)
		return
	var comp: Dictionary = companions[companion_id]
	if not comp.alive or comp.recruited:
		return
	if recruited_alive().size() >= int(Data.rule("max_roster", 4)):
		push_warning("GameState.recruit: roster is full, \"%s\" not recruited" % companion_id)
		return
	comp.recruited = true
	if party.size() < int(Data.rule("max_active_companions", 2)):
		party.append(companion_id)
	EventBus.companion_recruited.emit(companion_id)
	EventBus.party_changed.emit()


## Permanent. Works for recruited and unrecruited companions (a story death can happen before recruiting).
func kill_companion(companion_id: String, reason: String) -> void:
	if not companions.has(companion_id):
		push_error("GameState.kill_companion: unknown companion \"%s\"" % companion_id)
		return
	var comp: Dictionary = companions[companion_id]
	if not comp.alive:
		return
	comp.alive = false
	comp.hp = 0
	comp.death_reason = reason
	party.erase(companion_id)
	EventBus.companion_died.emit(companion_id, reason)
	EventBus.party_changed.emit()


func is_alive(companion_id: String) -> bool:
	return companions.has(companion_id) and companions[companion_id].alive


func is_recruited(companion_id: String) -> bool:
	return companions.has(companion_id) and companions[companion_id].recruited


func in_party(companion_id: String) -> bool:
	return party.has(companion_id)


## Every recruited, living companion, in data order. For encounters and quests with "party": "all".
func recruited_alive() -> Array[String]:
	var result: Array[String] = []
	for id in companions:
		if companions[id].recruited and companions[id].alive:
			result.append(id)
	return result


## Who fights: "active" -> the active party, "all" -> every recruited, living companion.
func combat_party(mode: String) -> Array[String]:
	if mode == "all":
		return recruited_alive()
	return party.duplicate()


# --- Items -----------------------------------------------------------------

func add_item(id: String, count: int = 1) -> void:
	if not Data.has("items", id):
		push_error("GameState.add_item: unknown item \"%s\"" % id)
		return
	inventory[id] = int(inventory.get(id, 0)) + count
	EventBus.item_changed.emit(id, inventory[id])


func remove_item(id: String, count: int = 1) -> bool:
	if not has_item(id, count):
		return false
	inventory[id] = int(inventory[id]) - count
	var left: int = inventory[id]
	if left <= 0:
		inventory.erase(id)
	EventBus.item_changed.emit(id, maxi(left, 0))
	return true


func has_item(id: String, count: int = 1) -> bool:
	return int(inventory.get(id, 0)) >= count


## Equips a weapon the player owns ("fists" always works). Use it in dialogue after giving a weapon:
## $> GameState.equip_weapon("holy_sword")
func equip_weapon(item_id: String) -> bool:
	if item_id != "fists" and not has_item(item_id):
		push_warning("GameState.equip_weapon: \"%s\" is not in the inventory" % item_id)
		return false
	if not Data.has("items", item_id) or Data.item(item_id).get("type", "") != "weapon":
		push_warning("GameState.equip_weapon: \"%s\" is not a weapon" % item_id)
		return false
	player.weapon_id = item_id
	EventBus.party_changed.emit()
	return true


# --- Progress --------------------------------------------------------------

## Pass a translation key from localization/story.csv, e.g. "OBJ_FIND_THE_COOK".
func set_objective(key: String) -> void:
	objective = key
	EventBus.objective_changed.emit(key)


func unlock_area(area_id: String) -> void:
	if unlocked_areas.has(area_id):
		return
	unlocked_areas.append(area_id)
	EventBus.area_unlocked.emit(area_id)


## Full heal for the protagonist and every recruited, living companion.
## If the cook is alive and in the party, the flag "well_fed" is set: a bonus that combat may use.
func rest() -> void:
	if not player.is_empty():
		player.hp = player.max_hp
	for id in recruited_alive():
		companions[id].hp = companions[id].max_hp
	if in_party("cook"):
		set_flag("well_fed", true)
	EventBus.hp_changed.emit()


# --- Saving ----------------------------------------------------------------

func to_dict() -> Dictionary:
	return {
		version = SAVE_VERSION,
		player = player.duplicate(true),
		companions = companions.duplicate(true),
		party = Array(party),
		inventory = inventory.duplicate(),
		flags = flags.duplicate(true),
		moral = moral,
		objective = objective,
		unlocked_areas = Array(unlocked_areas),
	}


## Restores a state from to_dict(). Numbers coming back from JSON are floats, so they are turned back into ints.
func from_dict(data: Dictionary) -> void:
	reset()
	player = data.get("player", {}).duplicate(true)
	if not player.is_empty():
		player.stats = _int_stats(player.get("stats", {}))
		player.hp = int(player.get("hp", 0))
		player.max_hp = int(player.get("max_hp", 1))
	var saved_companions: Dictionary = data.get("companions", {})
	for id in saved_companions:
		if not companions.has(id):
			push_warning("GameState.from_dict: companion \"%s\" no longer exists, skipped" % id)
			continue
		var saved: Dictionary = saved_companions[id]
		companions[id] = {
			recruited = bool(saved.get("recruited", false)),
			alive = bool(saved.get("alive", true)),
			hp = int(saved.get("hp", 0)),
			max_hp = int(saved.get("max_hp", 1)),
			death_reason = str(saved.get("death_reason", "")),
		}
	party.assign(data.get("party", []).filter(func(id: Variant) -> bool: return companions.has(id)))
	var saved_inventory: Dictionary = data.get("inventory", {})
	for id in saved_inventory:
		inventory[id] = int(saved_inventory[id])
	flags = data.get("flags", {}).duplicate(true)
	moral = int(data.get("moral", 0))
	objective = str(data.get("objective", ""))
	unlocked_areas.assign(data.get("unlocked_areas", []))
	party_changed_all()
	EventBus.moral_changed.emit(moral)
	EventBus.objective_changed.emit(objective)


## Tells every listener to refresh after a big change (new game, load).
func party_changed_all() -> void:
	EventBus.party_changed.emit()
	EventBus.hp_changed.emit()


func _int_stats(stats: Dictionary) -> Dictionary:
	var result := {}
	for key in Data.STAT_KEYS:
		result[key] = int(stats.get(key, 1))
	return result
