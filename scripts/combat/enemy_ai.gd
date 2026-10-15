class_name EnemyAI
extends RefCounted
## Simple, readable enemy behavior, picked by the enemy's "ai" field in data/enemies.json:
## - scavenger: hits a random standing fighter, runs away at low HP, never hits the downed.
## - brute: picks its next target a turn ahead (shown to the player), prefers the weakest,
##   and sometimes finishes off a downed companion.
## - swarm: ignores you, then sweeps the whole party every "attack_every" turns.


static func choose(state: CombatState, actor: Combatant) -> CombatAction:
	match actor.ai:
		"swarm":
			if actor.turns_taken % maxi(1, actor.attack_every) == 0:
				return CombatAction.make(CombatAction.Type.ATTACK, actor.id)
			return CombatAction.make(CombatAction.Type.WAIT, actor.id)
		"scavenger":
			if actor.flee_below > 0.0 and actor.hp_ratio() < actor.flee_below:
				return CombatAction.make(CombatAction.Type.FLEE, actor.id)
			return _attack_random_standing(state, actor)
		"brute":
			var target := state.fighter(actor.intent_target)
			if target == null or target.is_out() or (target.downed and not _may_finish(state, target)):
				target = pick_target(state, actor)
			if target == null:
				return CombatAction.make(CombatAction.Type.WAIT, actor.id)
			return CombatAction.attack(actor.id, target.id)
	return _attack_random_standing(state, actor)


## Chooses the brute's next target and announces it ("The brute is eyeing the cook …").
static func plan_intent(state: CombatState, actor: Combatant) -> void:
	var target := pick_target(state, actor)
	actor.intent_target = target.id if target else ""
	if target:
		state.add_event("intent", {actor = actor.id, target = target.id})


static func pick_target(state: CombatState, actor: Combatant) -> Combatant:
	var downed := state.party().filter(func(f: Combatant) -> bool: return f.downed and not f.dead and _may_finish(state, f))
	if not downed.is_empty() and actor.finishes_downed > 0.0 and state.rng.randf() < actor.finishes_downed:
		return downed[0]
	var standing := _standing(state)
	if standing.is_empty():
		return null
	standing.sort_custom(func(a: Combatant, b: Combatant) -> bool: return a.hp < b.hp)
	return standing[0]


static func _may_finish(state: CombatState, f: Combatant) -> bool:
	return f.is_companion and state.death_enabled()


static func _standing(state: CombatState) -> Array[Combatant]:
	return state.party().filter(func(f: Combatant) -> bool: return f.can_act())


static func _attack_random_standing(state: CombatState, actor: Combatant) -> CombatAction:
	var standing := _standing(state)
	if standing.is_empty():
		return CombatAction.make(CombatAction.Type.WAIT, actor.id)
	return CombatAction.attack(actor.id, standing[state.rng.randi() % standing.size()].id)
