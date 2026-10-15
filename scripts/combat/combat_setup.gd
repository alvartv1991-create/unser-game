class_name CombatSetup
extends RefCounted
## Builds a CombatState from GameState + data, and writes the result back when the fight is over.
## Nothing reaches GameState during the fight, so a lost fight can simply be tried again.

const SUFFIXES := ["A", "B", "C", "D", "E", "F"]


static func from_game(encounter_id: String, rng: RandomNumberGenerator = null) -> CombatState:
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	var encounter := Data.encounter(encounter_id)
	var fighters: Array[Combatant] = [_player()]
	for companion_id in GameState.combat_party(str(encounter.get("party", "active"))):
		fighters.append(_companion(companion_id))
	fighters.append_array(_enemies(encounter.get("enemies", [])))
	var state := CombatState.new(encounter_id, encounter, fighters, GameState.inventory, Data.rules(), rng)
	if GameState.get_flag("well_fed"):
		state.used_well_fed = true
		for f in state.party():
			f.damage_bonus += int(Data.rule("well_fed_damage", 1))
	return state


static func _player() -> Combatant:
	var f := Combatant.new()
	var job := Data.job(str(GameState.player.job_id))
	f.id = "player"
	f.source_id = "player"
	f.name_text = GameState.player_name()
	f.is_player = true
	f.art_id = str(Data.protagonist().get("art_id", "player"))
	f.stats = GameState.player.stats.duplicate()
	f.max_hp = int(GameState.player.max_hp)
	f.hp = clampi(int(GameState.player.hp), 1, f.max_hp)
	f.weapon_id = str(GameState.player.get("weapon_id", "fists"))
	f.weapon_uses = int(Data.item(f.weapon_id).get("durability", -1))
	f.skills.assign([str(job.skill)])
	f.perks = job.get("perks", {})
	f.initiative = CombatRules.initiative_of(f.stats)
	return f


static func _companion(companion_id: String) -> Combatant:
	var data := Data.companion(companion_id)
	var saved: Dictionary = GameState.companions[companion_id]
	var f := Combatant.new()
	f.id = companion_id
	f.source_id = companion_id
	f.name_text = data.name
	f.is_companion = true
	f.art_id = str(data.get("art_id", companion_id))
	f.stats = data.stats.duplicate()
	f.max_hp = int(saved.max_hp)
	f.hp = clampi(int(saved.hp), 1, f.max_hp)
	f.weapon_id = str(data.get("weapon", "fists"))
	f.weapon_uses = int(Data.item(f.weapon_id).get("durability", -1))
	f.skills.assign(data.get("skills", []))
	f.initiative = CombatRules.initiative_of(f.stats)
	return f


static func _enemies(enemy_ids: Array) -> Array[Combatant]:
	var result: Array[Combatant] = []
	var totals := {}
	for enemy_id in enemy_ids:
		totals[enemy_id] = int(totals.get(enemy_id, 0)) + 1
	var seen := {}
	for i in enemy_ids.size():
		var enemy_id: String = enemy_ids[i]
		var data := Data.enemy(enemy_id)
		var f := Combatant.new()
		f.id = "enemy_%d" % (i + 1)
		f.source_id = enemy_id
		f.side = Combatant.ENEMY
		f.name_text = data.name
		if int(totals[enemy_id]) > 1:
			f.suffix = " " + SUFFIXES[mini(int(seen.get(enemy_id, 0)), SUFFIXES.size() - 1)]
		seen[enemy_id] = int(seen.get(enemy_id, 0)) + 1
		f.kind = str(data.get("kind", "human"))
		f.art_id = str(data.get("art_id", enemy_id))
		f.max_hp = int(data.hp)
		f.hp = f.max_hp
		f.power = int(data.power)
		f.initiative = float(data.get("initiative", 5))
		f.ai = str(data.get("ai", ""))
		f.resolve = int(data.get("resolve", 0))
		f.flee_below = float(data.get("flee_below", 0.0))
		f.finishes_downed = float(data.get("finishes_downed", 0.0))
		f.talkable = bool(data.get("talkable", false))
		f.invulnerable = bool(data.get("invulnerable", false))
		f.attack_every = int(data.get("attack_every", 1))
		f.attack_all = bool(data.get("attack_all", false))
		result.append(f)
	return result


## Writes the fight's result into GameState and returns the combat_finished dictionary.
## HP, deaths (permanent), used items, broken weapons, loot (on a win), flags and moral.
static func apply_result(state: CombatState) -> Dictionary:
	for f in state.party():
		var hp := f.hp
		if f.downed:
			hp = 1
		if f.is_player:
			GameState.player.hp = maxi(1, hp)
			GameState.player.weapon_id = f.weapon_id
		elif f.dead:
			GameState.kill_companion(f.source_id, "combat:" + state.encounter_id)
		elif GameState.companions.has(f.source_id):
			GameState.companions[f.source_id].hp = maxi(1, hp)
	# Items: remove what the fight used up (state.inventory is the fight's copy).
	for item_id in GameState.inventory.keys():
		var used := int(GameState.inventory[item_id]) - int(state.inventory.get(item_id, 0))
		if used > 0:
			GameState.remove_item(item_id, used)
	var loot: Dictionary = state.encounter.get("loot", {}) if state.outcome == "win" else {}
	for item_id in loot:
		GameState.add_item(item_id, int(loot[item_id]))
	for flag in state.flags:
		GameState.set_flag(flag, state.flags[flag])
	if state.moral_delta != 0:
		GameState.add_moral(state.moral_delta)
	if state.used_well_fed:
		GameState.set_flag("well_fed", false)
	EventBus.hp_changed.emit()
	return {
		encounter_id = state.encounter_id,
		outcome = state.outcome,
		loot = loot.duplicate(),
		died = state.dead_companions(),
	}
