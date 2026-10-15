class_name CombatRules
extends RefCounted
## The formulas. All numbers come from data/rules.json, so the humans can tune them.
## See docs/ALPHA_SCOPE.md § Combat rules and data/README.md.


## Damage of a normal attack before the defender's modifiers. variance: -1, 0 or +1.
static func base_damage(attacker: Combatant, variance: int) -> int:
	var base: int
	if attacker.is_enemy():
		base = attacker.power
	else:
		var weapon_power := int(Data.item(attacker.weapon_id).get("power", 2))
		base = weapon_power + floori(attacker.stats.get("str", 1) / 2.0)
	return base + variance + attacker.damage_bonus


## Applies analyze, defending and barricades. Invulnerable fighters take 0, everyone else at least 1.
static func modified_damage(amount: float, defender: Combatant, rules: Dictionary) -> int:
	if defender.invulnerable:
		return 0
	var value := amount
	if defender.exposed_rounds > 0:
		value *= 1.0 + defender.exposed_bonus
	if defender.defending:
		value *= float(rules.get("defend_factor", 0.5))
	if defender.guard > 0.0:
		value *= 1.0 - defender.guard
	return maxi(1, roundi(value))


## Chance in percent (5..95) that talking with this approach ends the fight.
## talk_base + approach stat × talk_per_point × 2 + job bonus + perk − highest enemy resolve.
static func talk_chance(actor: Combatant, approach_id: String, approach: Dictionary, enemies: Array, rules: Dictionary) -> int:
	if approach.get("always_fails", false):
		return 0
	var stat := int(actor.stats.get(str(approach.get("stat", "int")), 1))
	var chance := int(rules.get("talk_base", 25)) + stat * int(rules.get("talk_per_point", 3)) * 2
	if approach.has("job"):
		chance += int(rules.get("talk_job_bonus", 15))
	chance += int(actor.perks.get("talk_bonus_" + approach_id, 0))
	var resolve := 0
	for enemy in enemies:
		if not enemy.is_out():
			resolve = maxi(resolve, enemy.resolve)
	return clampi(chance - resolve, 5, 95)


static func flee_chance(actor: Combatant, rules: Dictionary) -> int:
	var chance := int(rules.get("flee_base", 40)) + int(actor.stats.get("end", 1)) * int(rules.get("flee_per_end", 4))
	return clampi(chance, 5, 95)


## Heal amount of a skill (power + scaling stat) or an item (heal × doctor bonus).
static func skill_heal(actor: Combatant, skill: Dictionary) -> int:
	var amount := int(skill.get("power", 0))
	if skill.has("scales_with"):
		amount += int(actor.stats.get(str(skill.scales_with), 0))
	return amount


static func item_heal(actor: Combatant, item: Dictionary) -> int:
	var bonus := float(actor.perks.get("healing_item_bonus", 0.0))
	return roundi(float(item.get("heal", 0)) * (1.0 + bonus))


## Party: Ausdauer + Intelligenz / 2. Enemies: their "initiative" value.
static func initiative_of(stats: Dictionary) -> float:
	return float(stats.get("end", 1)) + float(stats.get("int", 1)) / 2.0


## Turn order for one round: highest initiative first, ties broken at random.
static func turn_order(fighters: Array, rng: RandomNumberGenerator) -> Array[Combatant]:
	var keyed := []
	for fighter in fighters:
		keyed.append([fighter.initiative + rng.randf() * 0.25, fighter])
	keyed.sort_custom(func(a: Array, b: Array) -> bool: return a[0] > b[0])
	var order: Array[Combatant] = []
	for pair in keyed:
		order.append(pair[1])
	return order
