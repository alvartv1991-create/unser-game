# The game data, explained

These files hold the game's numbers and short texts. **You can edit them without touching code.** Open them in any text editor (VS Code shows mistakes right away).

## Basics
- **Text** is always written in both languages: `{"de": "Verband", "en": "Bandage"}`. If one language is missing, the game shows `[EN?]` and the debug menu lists the mistake.
- **Notes for humans:** any key starting with `_` (like `"_note"`) is ignored by the game.
- **Ids** (`"doctor"`, `"canned_food"`) are the names the code and the dialogue use. Write them in lowercase with `_`, and never rename one without asking an agent, because other files refer to them.
- `[TEMP]` marks placeholder text by the agents. Replace it whenever you like.
- **Did it work?** Start the game and press **F1**: data mistakes appear at the top of the debug menu, in red, with the file and the line.

## `rules.json`: game rules, the most fun file to tune
| Key | Meaning |
|---|---|
| `max_active_companions` | How many companions travel with you at once |
| `max_roster` | How many companions you can have in total |
| `companion_combat_death` | `true`: companions can die in fights. `false`: they are only knocked out. |
| `downed_turns` | How many turns a downed companion has before they die |
| `moral_low` / `moral_high` | From which value moral counts as "low"/"high" (unlocks hidden options) |
| `moral_min` / `moral_max` | Lowest and highest possible moral |
| `hp_base`, `hp_per_end` | Max HP = hp_base + Ausdauer × hp_per_end |
| `talk_base`, `talk_per_point`, `talk_job_bonus` | Chance in % to talk your way out: talk_base + (the approach's stat × talk_per_point × 2), + talk_job_bonus for a job approach, − the highest resolve among the enemies (always between 5 and 95) |
| `talk_win_moral` | Moral bonus for ending a fight by talking |
| `well_fed_damage` | Extra damage for everyone in the fight after resting with the cook |
| `flee_base`, `flee_per_end` | Chance in % to flee: flee_base + Ausdauer × flee_per_end |
| `defend_factor` | Damage multiplier while defending (0.5 = half) |

## `protagonist.json`: the main character
For now a fixed person. `name`, `bio` and `art_id` (which sprite to use).

## `jobs.json`: former jobs (= classes)
Up to 10 jobs are planned; add one by copying an existing block.

| Field | Meaning |
|---|---|
| `name`, `description` | Shown in the job selection |
| `stats` | `int` Intelligenz, `str` Stärke, `end` Ausdauer, `kno` Wissen, each 1–10 |
| `skill` | Id of the job's skill (from `skills.json`) |
| `start_weapon` | Weapon id at the start (from `items.json`) |
| `start_items` | Items at the start, e.g. `{"bandage": 2}` |
| `perks` | Special bonuses that combat or dialogue use, e.g. `{"healing_item_bonus": 0.5}` |

## `skills.json`: skills of jobs and companions
`name`, `description`, `target` (`ally`, `all_allies`, `enemy`, `none`), `effect` (what it does: `heal`, `damage_reduction`, `stun`, `analyze`, `nothing`, `cheat`), plus numbers like `power`, `duration`, `scales_with` (which stat makes it stronger), `revives` (gets downed people up), `only_vs` (`human` or `alien`) and `cooldown` (how many of your own turns you wait before using it again; 0 = every turn).

## `talk.json`: ways to talk enemies out of a fight
`name`, `stat` (which stat makes it work: `int`, `str`, `end`, `kno`), `job` (only that job gets this option), `moral` (moral change whenever it's used), `always_fails` (never works) and `fail` (its own line when it fails).

## `items.json`: items
`type` is `weapon`, `consumable`, `material` or `key`. Weapons have `power` and `durability` (−1 = never breaks, 1 = breaks after one hit, like the holy sword). Consumables have `heal`. `tags` are extra markers, e.g. `bribe` (can be used as a bribe). `hidden: true` keeps it out of the inventory.

## `companions.json`: all companions
`name`, `role` (a short description), `stats`, `skills`, `weapon`, `art_id`. Whether a companion is recruited or dead is saved per playthrough, not here.

## `enemies.json`: enemies
`kind` is `human`, `alien` or `animal`. `hp`, `power` (damage), `initiative` (who acts first; the party's is Ausdauer + Intelligenz / 2), `resolve` (how hard to talk down, in %), `flee_below` (flees below this share of HP, e.g. 0.3 = 30%), `finishes_downed` (chance to finish off a downed character), `talkable`, `invulnerable`, `ai` (behavior), `art_id`.

## `encounters.json`: fights
`enemies` (list of enemy ids), `party` (`"active"` = the active party fights, `"all"` = every recruited, living companion fights), `can_flee`, `music` (audio id), `cheats` (cheat codes that work here), `loot` (items after winning), `backdrop` (optional art id behind the fight: `street`, `camp` or `alien_zone`; unknown ids fall back to the street).

## `cheats.json`: cheat codes hidden in the world
`sequence` is a list of `up`, `down`, `left`, `right`. A code only works in fights whose `cheats` list contains it. `hint` says where the player can find it.

## `speakers.json`, `barks.json`, `combat_text.json`
Who can talk in dialogue (name and placeholder color), short lines companions say on their own, and combat log lines. `{actor}`, `{target}` and `{amount}` are filled in by the game.

## `audio.json`
Which sound file plays for each audio id. See `docs/AUDIO_GUIDE.md` (comes with H4).
