class_name CombatAutoPilot
extends RefCounted
## Plays the party's side without a human: for balance tests and H5's automated walkthrough.
## Sensible, not clever: revive the downed, heal the hurt, cheat against aliens, else hit the weakest.


static func choose(state: CombatState, actor: Combatant) -> CombatAction:
	var allies := state.party()
	# 1. Aliens: cheat if any way is available.
	if state.has_aliens():
		if actor.skills.has("send_signal") and state.skill_block_reason(actor, "send_signal") == "":
			return CombatAction.skill(actor.id, "send_signal")
		if state.usable_items().has("jammer"):
			return CombatAction.item(actor.id, "jammer")
	# 2. Someone is down: revive them.
	var downed := allies.filter(func(f: Combatant) -> bool: return f.downed and not f.dead)
	if not downed.is_empty():
		var revive := _heal_action(state, actor, downed[0], true)
		if revive:
			return revive
	# 3. Someone is hurt badly: heal.
	var hurt := allies.filter(func(f: Combatant) -> bool: return f.can_act() and f.hp_ratio() < 0.35)
	if not hurt.is_empty():
		var heal := _heal_action(state, actor, hurt[0], false)
		if heal:
			return heal
	# 4. Hit the weakest enemy.
	var targets := state.enemies().filter(func(e: Combatant) -> bool: return not e.is_out())
	if targets.is_empty():
		return CombatAction.make(CombatAction.Type.WAIT, actor.id)
	targets.sort_custom(func(a: Combatant, b: Combatant) -> bool: return a.hp < b.hp)
	return CombatAction.attack(actor.id, targets[0].id)


static func _heal_action(state: CombatState, actor: Combatant, target: Combatant, need_revive: bool) -> CombatAction:
	for skill_id in actor.skills:
		var skill := Data.skill(skill_id)
		if skill.get("effect", "") == "heal" and state.skill_block_reason(actor, skill_id) == "" \
				and (not need_revive or skill.get("revives", false)):
			return CombatAction.skill(actor.id, skill_id, target.id)
	for item_id in state.usable_items():
		var item := Data.item(item_id)
		if int(item.get("heal", 0)) > 0 and (not need_revive or item.get("revives", false)):
			return CombatAction.item(actor.id, item_id, target.id)
	return null


## Runs a whole fight: the autopilot for the party, EnemyAI for the enemies. Returns the outcome.
static func simulate(state: CombatState, max_turns: int = 400) -> String:
	state.start()
	var turns := 0
	while not state.is_over() and turns < max_turns:
		turns += 1
		var actor := state.next_turn()
		if actor != null and not state.is_over():
			var action := EnemyAI.choose(state, actor) if actor.is_enemy() else choose(state, actor)
			state.perform(action)
		state.take_events()
	return state.outcome if state.is_over() else "timeout"
