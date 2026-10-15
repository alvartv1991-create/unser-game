class_name CombatAction
extends RefCounted
## What one fighter does on their turn. Built by the menu (party) or EnemyAI (enemies).

enum Type { ATTACK, SKILL, ITEM, DEFEND, TALK, FLEE, CHEAT_CODE, WAIT }

var type: Type = Type.WAIT
var actor_id: String = ""
var target_id: String = ""
var skill_id: String = ""
var item_id: String = ""
var approach_id: String = ""
var cheat_id: String = ""


static func make(action_type: Type, actor: String, target: String = "") -> CombatAction:
	var action := CombatAction.new()
	action.type = action_type
	action.actor_id = actor
	action.target_id = target
	return action


static func attack(actor: String, target: String) -> CombatAction:
	return make(Type.ATTACK, actor, target)


static func skill(actor: String, skill_name: String, target: String = "") -> CombatAction:
	var action := make(Type.SKILL, actor, target)
	action.skill_id = skill_name
	return action


static func item(actor: String, item_name: String, target: String = "") -> CombatAction:
	var action := make(Type.ITEM, actor, target)
	action.item_id = item_name
	return action


static func talk(actor: String, approach: String) -> CombatAction:
	var action := make(Type.TALK, actor)
	action.approach_id = approach
	return action


static func cheat_code(actor: String, cheat: String) -> CombatAction:
	var action := make(Type.CHEAT_CODE, actor)
	action.cheat_id = cheat
	return action
