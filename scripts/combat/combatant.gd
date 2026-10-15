class_name Combatant
extends RefCounted
## One fighter in a combat: plain data that CombatState changes. No nodes, no drawing.

const PARTY := "party"
const ENEMY := "enemy"

# Who this is
var id: String = ""              # unique in this fight: "player", "cook", "enemy_1"
var source_id: String = ""       # "player", a companion id or an enemy id
var side: String = PARTY
var name_text: Variant = ""      # {"de", "en"} or a plain String; shown via display_name()
var suffix: String = ""          # " A", " B" when several enemies share a name
var kind: String = "human"       # human, alien or animal
var art_id: String = ""
var is_player := false
var is_companion := false

# Numbers
var stats: Dictionary = {"int": 1, "str": 1, "end": 1, "kno": 1}
var max_hp: int = 1
var hp: int = 1
var power: int = 0               # enemies: base damage
var initiative: float = 0.0
var weapon_id: String = "fists"
var weapon_uses: int = -1        # hits left before the weapon breaks; -1 = never breaks
var damage_bonus: int = 0
var skills: Array[String] = []
var perks: Dictionary = {}

# Enemy behavior (enemies.json)
var ai: String = ""
var resolve: int = 0
var flee_below: float = 0.0
var finishes_downed: float = 0.0
var talkable := false
var invulnerable := false
var attack_every: int = 1
var attack_all := false

# State during the fight
var downed := false
var downed_turns_left: int = 0
var dead := false
var defeated := false            # enemies at 0 HP
var fled := false
var defending := false
var guard: float = 0.0           # 0..1 damage reduction from a barricade
var guarded_by: String = ""      # id of the fighter whose next turn ends the guard
var stunned: int = 0             # turns to skip
var exposed_rounds: int = 0      # rounds left of "analyze"
var exposed_bonus: float = 0.0
var cooldowns: Dictionary = {}   # skill_id -> own turns left until usable
var turns_taken: int = 0
var intent_target: String = ""   # brute: who it will attack next (shown to the player)


func display_name() -> String:
	return Data.text(name_text) + suffix


## For the crowded combat screen and log lines: the name without the "[TEMP] " marker
## (the data and the log template still carry it, so nothing is hidden from the humans).
func short_name() -> String:
	return display_name().trim_prefix("[TEMP] ")


func is_enemy() -> bool:
	return side == ENEMY


## Gone from the fight for good (dead, beaten or run away).
func is_out() -> bool:
	return dead or defeated or fled


func can_act() -> bool:
	return not is_out() and not downed


func hp_ratio() -> float:
	return float(hp) / float(max_hp) if max_hp > 0 else 0.0


func skill_ready(skill_id: String) -> bool:
	return int(cooldowns.get(skill_id, 0)) <= 0
