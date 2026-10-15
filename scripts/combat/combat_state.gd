class_name CombatState
extends RefCounted
## One fight: fighters, turn order and rules. Every change produces an event (a Dictionary such as
## {type = "attack", actor = "player", target = "enemy_1", amount = 4}) that the combat scene turns
## into animations and log lines. It never touches GameState: CombatSetup writes the result back
## when the fight is over, so "try again" just builds a new CombatState.
##
## Flow: start(), then repeat { actor = next_turn(); if actor: perform(choice) } until is_over().

var encounter_id: String = ""
var encounter: Dictionary = {}
var rules: Dictionary = {}
var rng: RandomNumberGenerator
var fighters: Array[Combatant] = []
var inventory: Dictionary = {}       # copy of GameState.inventory, changed during the fight
var round_number: int = 0
var order: Array[Combatant] = []
var turn_index: int = 0
var current: Combatant = null
var outcome: String = ""             # "" while running, then "win", "lose", "flee", "talk" or "cheat"
var moral_delta: int = 0
var flags: Dictionary = {}           # flags to set once the fight is over
var used_well_fed := false

## Test hooks: forced chance rolls (true/false, used in order) and a fixed damage variance.
var forced_rolls: Array = []
var fixed_variance: Variant = null

var _events: Array[Dictionary] = []


func _init(p_encounter_id: String, p_encounter: Dictionary, p_fighters: Array[Combatant],
		p_inventory: Dictionary, p_rules: Dictionary, p_rng: RandomNumberGenerator) -> void:
	encounter_id = p_encounter_id
	encounter = p_encounter
	fighters = p_fighters
	inventory = p_inventory.duplicate()
	rules = p_rules
	rng = p_rng


# --- Queries ---------------------------------------------------------------

func party() -> Array[Combatant]:
	return fighters.filter(func(f: Combatant) -> bool: return f.side == Combatant.PARTY)


func enemies() -> Array[Combatant]:
	return fighters.filter(func(f: Combatant) -> bool: return f.side == Combatant.ENEMY)


func fighter(id: String) -> Combatant:
	for f in fighters:
		if f.id == id:
			return f
	return null


func player() -> Combatant:
	return fighter("player")


func is_over() -> bool:
	return outcome != ""


func death_enabled() -> bool:
	return bool(rules.get("companion_combat_death", true))


func has_aliens() -> bool:
	return enemies().any(func(e: Combatant) -> bool: return not e.is_out() and e.kind == "alien")


## Human enemies that can still be talked to.
func talkable_enemies() -> Array[Combatant]:
	return enemies().filter(func(e: Combatant) -> bool: return not e.is_out() and e.talkable and e.kind == "human")


## Companion ids who died in this fight.
func dead_companions() -> Array[String]:
	var ids: Array[String] = []
	for f in party():
		if f.dead and f.is_companion:
			ids.append(f.source_id)
	return ids


## Why a skill can't be used right now: "" if it can, otherwise a localization key.
func skill_block_reason(actor: Combatant, skill_id: String) -> String:
	var skill := Data.skill(skill_id)
	if not actor.skill_ready(skill_id):
		return "COMBAT_COOLDOWN"
	match str(skill.get("only_vs", "")):
		"human":
			if talkable_enemies().is_empty() and not enemies().any(func(e: Combatant) -> bool: return not e.is_out() and e.kind == "human"):
				return "COMBAT_ONLY_HUMANS"
		"alien":
			if not has_aliens():
				return "COMBAT_ONLY_ALIENS"
	return ""


## Items the party can use in a fight, in inventory order.
func usable_items() -> Array[String]:
	var ids: Array[String] = []
	for item_id in inventory:
		if int(inventory[item_id]) <= 0 or not Data.has("items", item_id):
			continue
		var item := Data.item(item_id)
		if item.get("type", "") == "consumable" and int(item.get("heal", 0)) > 0:
			ids.append(item_id)
		elif item.get("tags", []).has("alien_signal"):
			ids.append(item_id)
	return ids


func take_events() -> Array[Dictionary]:
	var taken := _events
	_events = []
	return taken


## For EnemyAI and other combat helpers that need to announce something.
func add_event(type: String, data: Dictionary = {}) -> void:
	_event(type, data)


# --- Turn flow -------------------------------------------------------------

func start() -> void:
	_event("start")
	if used_well_fed:
		_event("well_fed")
	for e in enemies():
		if e.ai == "brute":
			EnemyAI.plan_intent(self, e)


## Moves to the next fighter. Returns who must choose an action now, or null when this turn
## needs no choice (skipped, downed, or the fight just ended). Check is_over() afterwards.
func next_turn() -> Combatant:
	if is_over():
		return null
	if turn_index >= order.size():
		_new_round()
	current = order[turn_index]
	turn_index += 1
	var f := current
	if f.is_out():
		return null
	_start_turn(f)
	if f.downed:
		_tick_downed(f)
		_check_end()
		return null
	if f.stunned > 0:
		f.stunned -= 1
		_event("stunned_skip", {target = f.id})
		return null
	return f


func perform(action: CombatAction) -> void:
	if is_over():
		return
	var actor := fighter(action.actor_id)
	if actor == null or not actor.can_act():
		return
	var target := fighter(action.target_id)
	match action.type:
		CombatAction.Type.ATTACK:
			if actor.attack_all:
				_attack_all(actor)
			else:
				_attack(actor, target)
		CombatAction.Type.SKILL:
			_use_skill(actor, action.skill_id, target)
		CombatAction.Type.ITEM:
			_use_item(actor, action.item_id, target)
		CombatAction.Type.DEFEND:
			actor.defending = true
			_event("defend", {actor = actor.id})
		CombatAction.Type.TALK:
			_talk(actor, action.approach_id)
		CombatAction.Type.FLEE:
			_flee(actor)
		CombatAction.Type.CHEAT_CODE:
			_end_by_cheat("cheat_code", actor)
		CombatAction.Type.WAIT:
			_event("swarm_idle" if actor.ai == "swarm" else "wait", {actor = actor.id})
	_check_end()
	if not is_over() and actor.ai == "brute" and actor.can_act():
		EnemyAI.plan_intent(self, actor)


func _new_round() -> void:
	round_number += 1
	if round_number > 1:
		for f in fighters:
			f.exposed_rounds = maxi(0, f.exposed_rounds - 1)
	order = CombatRules.turn_order(fighters.filter(func(f: Combatant) -> bool: return not f.is_out()), rng)
	turn_index = 0
	_event("round", {round = round_number, order = order.map(func(f: Combatant) -> String: return f.id)})


func _start_turn(f: Combatant) -> void:
	f.turns_taken += 1
	f.defending = false
	for other in fighters:
		if other.guarded_by == f.id:
			other.guard = 0.0
			other.guarded_by = ""
	for skill_id in f.cooldowns.keys():
		f.cooldowns[skill_id] = maxi(0, int(f.cooldowns[skill_id]) - 1)
	_event("turn", {actor = f.id})


func _tick_downed(f: Combatant) -> void:
	if f.is_player or not death_enabled():
		_event("downed_wait", {target = f.id})
		return
	f.downed_turns_left -= 1
	if f.downed_turns_left <= 0:
		_kill(f)
	else:
		_event("downed_tick", {target = f.id, turns = f.downed_turns_left})


func _check_end() -> void:
	if is_over():
		return
	if enemies().all(func(e: Combatant) -> bool: return e.is_out()):
		outcome = "win"
		_event("win")
	elif party().all(func(f: Combatant) -> bool: return f.dead or f.downed):
		outcome = "lose"
		_event("lose")


# --- Actions ---------------------------------------------------------------

func _attack(actor: Combatant, target: Combatant) -> void:
	if target == null or target.is_out() or target.side == actor.side:
		target = _first_opponent(actor)
		if target == null:
			return
	if target.invulnerable:
		_event("alien_ignores", {actor = actor.id, target = target.id})
		return
	var amount := CombatRules.modified_damage(CombatRules.base_damage(actor, _variance()), target, rules)
	_event("attack", {actor = actor.id, target = target.id, amount = amount})
	_hurt(target, amount)
	if not actor.is_enemy():
		_wear_weapon(actor)


## The swarm's sweep: hits every fighter of the party, downed ones included.
func _attack_all(actor: Combatant) -> void:
	_event("swarm_hit", {actor = actor.id, amount = actor.power})
	for f in party():
		if f.is_out():
			continue
		var amount := CombatRules.modified_damage(actor.power, f, rules)
		_event("hit", {actor = actor.id, target = f.id, amount = amount})
		_hurt(f, amount)


func _hurt(target: Combatant, amount: int) -> void:
	if target.side == Combatant.PARTY:
		if target.downed:
			# Hit while down: companions die (if the rule is on); the protagonist just stays down.
			if target.is_companion and death_enabled():
				_kill(target)
			return
		target.hp = maxi(0, target.hp - amount)
		if target.hp == 0:
			_down(target)
	else:
		target.hp = maxi(0, target.hp - amount)
		if target.hp == 0:
			target.defeated = true
			_event("defeated", {target = target.id})


func _down(f: Combatant) -> void:
	f.downed = true
	f.defending = false
	if f.is_player:
		_event("downed_player", {target = f.id})
	elif not death_enabled():
		_event("ko", {target = f.id})
	else:
		f.downed_turns_left = int(rules.get("downed_turns", 2))
		_event("downed", {target = f.id, turns = f.downed_turns_left})


func _kill(f: Combatant) -> void:
	f.dead = true
	f.downed = false
	f.hp = 0
	_event("died", {target = f.id})


func _heal(actor: Combatant, target: Combatant, amount: int, can_revive: bool) -> void:
	if target == null or target.dead or target.is_enemy():
		return
	if target.downed:
		if not can_revive:
			_event("no_revive", {actor = actor.id, target = target.id})
			return
		target.downed = false
		target.downed_turns_left = 0
		target.hp = clampi(amount, 1, target.max_hp)
		_event("revive", {actor = actor.id, target = target.id, amount = target.hp})
		return
	var before := target.hp
	target.hp = mini(target.max_hp, target.hp + amount)
	_event("heal", {actor = actor.id, target = target.id, amount = target.hp - before})


func _wear_weapon(actor: Combatant) -> void:
	if actor.weapon_uses < 0:
		return
	actor.weapon_uses -= 1
	if actor.weapon_uses > 0:
		return
	var broken := actor.weapon_id
	_event("weapon_broke", {actor = actor.id, weapon = broken})
	if broken == "holy_sword":
		flags["holy_sword_broken"] = true
	if actor.is_player:
		_take_item(broken)
		actor.weapon_id = _best_weapon()
	else:
		actor.weapon_id = "fists"
	actor.weapon_uses = int(Data.item(actor.weapon_id).get("durability", -1))


## The strongest weapon left in the inventory, or bare fists.
func _best_weapon() -> String:
	var best := "fists"
	var best_power := int(Data.item("fists").get("power", 2))
	for item_id in inventory:
		var item := Data.item(item_id)
		if item.get("type", "") == "weapon" and int(inventory[item_id]) > 0 and int(item.get("power", 0)) > best_power:
			best = item_id
			best_power = int(item.power)
	return best


func _use_skill(actor: Combatant, skill_id: String, target: Combatant) -> void:
	if not actor.skills.has(skill_id) or skill_block_reason(actor, skill_id) != "":
		return
	var skill := Data.skill(skill_id)
	var cooldown := int(skill.get("cooldown", 0))
	if cooldown > 0:
		actor.cooldowns[skill_id] = cooldown + 1
	match str(skill.effect):
		"heal":
			var amount := CombatRules.skill_heal(actor, skill)
			var revives := bool(skill.get("revives", false))
			if skill.target == "all_allies":
				for f in party():
					_heal(actor, f, amount, revives)
			else:
				_heal(actor, target, amount, revives)
		"damage_reduction":
			_event("barricade", {actor = actor.id})
			for f in party():
				if not f.is_out():
					f.guard = float(skill.get("power", 50)) / 100.0
					f.guarded_by = actor.id
		"stun":
			if target == null or target.is_out():
				return
			if target.kind != "human":
				_event("stun_fail", {actor = actor.id, target = target.id})
			else:
				target.stunned = int(skill.get("duration", 1))
				_event("stun", {actor = actor.id, target = target.id})
		"analyze":
			if target == null or target.is_out():
				return
			if target.invulnerable:
				_event("analyze_alien", {actor = actor.id, target = target.id})
			else:
				target.exposed_rounds = int(skill.get("duration", 3))
				target.exposed_bonus = float(skill.get("power", 30)) / 100.0
				_event("analyze", {actor = actor.id, target = target.id})
		"nothing":
			# The log line is looked up by skill id (e.g. "file_form").
			_event(skill_id, {actor = actor.id})
		"cheat":
			if has_aliens():
				_end_by_cheat("signal", actor)
			else:
				_event("signal_no_alien", {actor = actor.id})


func _use_item(actor: Combatant, item_id: String, target: Combatant) -> void:
	if int(inventory.get(item_id, 0)) <= 0:
		return
	var item := Data.item(item_id)
	_event("item", {actor = actor.id, item = item_id, target = target.id if target else ""})
	if item.get("tags", []).has("alien_signal"):
		# Key item: not used up.
		if has_aliens():
			_end_by_cheat("signal", actor)
		else:
			_event("signal_no_alien", {actor = actor.id})
		return
	_take_item(item_id)
	_heal(actor, target, CombatRules.item_heal(actor, item), bool(item.get("revives", false)))


func _take_item(item_id: String) -> void:
	inventory[item_id] = int(inventory.get(item_id, 0)) - 1
	if int(inventory[item_id]) <= 0:
		inventory.erase(item_id)


func _talk(actor: Combatant, approach_id: String) -> void:
	var approach: Dictionary = Data.all("talk").get(approach_id, {})
	if approach.is_empty() or talkable_enemies().is_empty():
		return
	moral_delta += int(approach.get("moral", 0))
	_event("talk_attempt", {actor = actor.id, approach = approach_id})
	var chance := CombatRules.talk_chance(actor, approach_id, approach, enemies(), rules)
	if chance > 0 and _roll(chance):
		outcome = "talk"
		moral_delta += int(rules.get("talk_win_moral", 0))
		_event("talk_success", {actor = actor.id})
	else:
		_event("talk_fail", {actor = actor.id, approach = approach_id})


func _flee(actor: Combatant) -> void:
	if actor.is_enemy():
		actor.fled = true
		_event("enemy_fled", {target = actor.id})
		return
	if has_aliens():
		_event("flee_alien", {actor = actor.id})
	elif not encounter.get("can_flee", true):
		_event("flee_blocked", {actor = actor.id})
	elif _roll(CombatRules.flee_chance(actor, rules)):
		outcome = "flee"
		_event("flee_success", {actor = actor.id})
	else:
		_event("flee_fail", {actor = actor.id})


func _end_by_cheat(kind: String, actor: Combatant) -> void:
	outcome = "cheat"
	_event(kind, {actor = actor.id})


func _first_opponent(actor: Combatant) -> Combatant:
	for f in fighters:
		if f.side != actor.side and not f.is_out() and not f.downed:
			return f
	return null


# --- Chance ----------------------------------------------------------------

## True with the given chance in percent (or the next forced result in tests).
func roll(chance: int) -> bool:
	return _roll(chance)


func _roll(chance: int) -> bool:
	if not forced_rolls.is_empty():
		return bool(forced_rolls.pop_front())
	return rng.randi_range(1, 100) <= chance


func _variance() -> int:
	if fixed_variance != null:
		return int(fixed_variance)
	return rng.randi_range(-1, 1)


func _event(type: String, data: Dictionary = {}) -> void:
	data.type = type
	_events.append(data)
