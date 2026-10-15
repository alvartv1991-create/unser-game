# Alpha scope

## Goal
The alpha is a playable slice of Area 1, about 20–30 minutes long. It shows **every pillar of docs/VISION.md once**, in first-pass pixel art, with `[TEMP]` text in German and English and with audio hooks. It exists so the humans can feel the vision and decide what is fun. Final story, balance and polish come later.

## The humans' answers, as alpha rules
| VISION question | Alpha rule |
|---|---|
| 1 Era | The 1980s. The military had GPS and its own network, and those fail first. Civilians have CRT TVs, landlines, payphones, radios and arcades, but no internet and no smartphones. |
| 2 Protagonist | A fixed, ordinary person for now (`data/protagonist.json`, `[TEMP]` name). Customization may come later, so the name is always read through `GameState.player_name()` and never hard-coded. The player picks the former job. **Up to 10 jobs:** the alpha ships the 5 from the script, the humans add more in `data/jobs.json`, and the job selection screen must fit 10. |
| 3 Cheating | Both kinds: in-world tech (tinkerer, jammer) and real cheat codes that are hidden in the world. Cheat codes live in `data/cheats.json`, so later bosses can get their own. |
| 4 Body mods / weapons | Not in the alpha. |
| 5 Companion death | Both: through story decisions **and** in combat (downed state first, see Combat rules). This can be switched off in `data/rules.json`. |
| 6 Cult | Appears early but hidden: a teaser spot that's easy to miss, rewarding a second playthrough. |
| 7 Art | Pixel art drawn by the agents. Claude draws the characters; Codex draws the environment, UI and FX. |
| 8 Language | German and English, both complete from the start. |
| 10 Companions | The roster can hold up to 4 and the active party 2 (both configurable). The alpha has 2 companions. **Some quests and fights bring in all living companions**, whoever is in the active party, so every companion matters on every route. In data: an encounter has `"party": "all"` instead of `"active"`, and dialogue can check any recruited companion. Which situations do this is still open. The combat layout must fit the player + 4. |
| 11 Moral | Moral unlocks **hidden** options: at low moral you can kill people, at high moral people help or join you. These options are hidden, never greyed out, because moral itself is hidden. |

## Pillar → how the alpha shows it
| Pillar | Shown in the alpha by |
|---|---|
| Story and humor | Look-at comments on everything, the holy sword, the Beamter class |
| Choices that hurt | A dilemma that can kill the cook. Companions can die in fights. Options gated by moral. The end summary shows the consequences. |
| Fight humans, not aliens | Two raider fights, both of which can be talked out of. A choice to spare or kill afterwards. |
| Aliens are OP, so you cheat | An alien fight that can only be won by cheating, three different ways |
| Technology is the key | Glitching TVs, payphones, radios and arcade cabinets. The tinkerer studies them. |
| Jobs as classes | 5 jobs, each with its own skill and its own dialogue options |
| New areas unlock + replayability | A gate leads to an area select screen where Area 2 is shown as "Demnächst". The hidden cult teaser. |

## Playthrough (the beats)
0. **Title** (choose the language on first start) → Neues Spiel → **"Was warst du vorher?"**, the job selection.
1. **Intro** (`intro:start`): text cards. Military satellites pick up strange signals, then GPS and the military network die. TV screens flicker and phones ring by themselves. Then *they* arrive… and mostly ignore us.
2. **Bunker** (`area1_bunker`): the protagonist wakes up. The **cook** is here and can be recruited (`cook:first_meet`). A campfire saves the game and rests the party; the cook makes resting better.
3. **Street** (`area1_vorstadt`, west part): platforming tutorial, with a flickering TV, a ringing payphone and a burnt car to examine. First fight: `raiders_street` (2 scavengers), started from `raiders:street`.
4. **Video game store** (`area1_videostore`): cartridges, arcade cabinets and a clerk who still keeps the shop open. You can take the **Heiliges Schwert von [TEMP]** (`videostore:sword_shelf`), a promo prop and the strongest weapon in the game, which breaks after one hit. A poster on the wall shows the cheat code ↑↑↓↓←→←→ (`examine:cheat_poster`).
5. **Rooftop**: the **tinkerer** at a satellite dish, studying the signals (`tinkerer:first_meet`). You choose whether to recruit them.
   - *Hidden, optional:* a side route (sewer, back yard or crawlspace) leads to the **cult teaser** (`cult:teaser`): a strange symbol and someone humming along to TV static. Only cryptic `[TEMP]` lines. Sets `cult_teaser_found`.
6. **Raider camp**: a checkpoint (`raiders:camp`) with these ways through:
   - talking
   - bribing with canned food
   - a job-specific option
   - a **high-moral-only** option (e.g. a raider remembers you helped someone and lets you through)
   - the fight `raiders_camp`

   If you win the fight, `raiders:camp_after_fight` gives a choice to spare or kill the surrendering raider. Killing is a **low-moral-only** option, with a big moral cost. The `jammer` key item is in the camp. Sets `raiders_camp_resolved`.
7. **Alien zone**: the swarm snatches things in the background (`alien_zone:snatching`). **The dilemma** (`alien_zone:dilemma`): one option kills the cook. Then the swarm blocks the gate (`alien_zone:swarm_blocks_gate`), leading to `alien_swarm_zone`, which can only be won by cheating. Sets `aliens_dispersed`.
8. **Gate** (`gate:locked` / `gate:open`) → `area2_unlocked` → area select screen → Area 2 (`gate:coming_soon`) → **end-of-alpha summary**.

**Three ways to cheat in the alien fight**, so the player can never get stuck: the tinkerer in the party (skill `send_signal`), the `jammer` item, or typing the code from the poster during the fight.

**Moral must be reachable:** before the raider camp, the alpha offers enough moral choices (helping the clerk, sharing food, how you treat the cook, …) that both the high and the low gated options can be reached in a normal playthrough.

## Default numbers (all editable in `data/`)
Stats range from 1 to 10: `int` Intelligenz, `str` Stärke, `end` Ausdauer, `kno` Wissen. Hidden: `moral`, from −100 to 100, starting at 0.

### `data/rules.json`
| Key | Default | Meaning |
|---|---|---|
| `max_active_companions` | 2 | Companions in the active party |
| `max_roster` | 4 | How many companions you can have at all |
| `companion_combat_death` | true | Can companions die in fights? |
| `downed_turns` | 2 | Turns a downed companion has before they die |
| `moral_low` / `moral_high` | −25 / 25 | Thresholds for `moral_is("low"/"high")` |

### Jobs
| id | Name (de / en) | int | str | end | kno | Skill | Extra |
|---|---|---|---|---|---|---|---|
| `doctor` | Arzt/Ärztin / Doctor | 8 | 3 | 4 | 6 | `first_aid`: heal one ally for 6 + int, also revives a downed ally | Healing items heal 50% more |
| `craftsman` | Handwerker/in / Craftsman | 3 | 8 | 7 | 3 | `barricade`: the party takes 50% less damage for 1 round | Starts with a `crowbar` |
| `police` | Polizist/in / Police officer | 5 | 6 | 6 | 4 | `arrest`: stun a human enemy for 1 turn (fails on aliens) | Bonus to intimidating when talking |
| `scientist` | Wissenschaftler/in / Scientist | 7 | 2 | 3 | 9 | `analyze`: reveal a weakness; the party deals +30% damage to that target for 3 turns | Understands glitches earlier in dialogue |
| `civil_servant` | Beamter/Beamtin / Civil servant | 2 | 2 | 3 | 2 | `file_form`: nothing happens ("Bearbeitungszeit: 6–8 Wochen") | None. On purpose. |

### Combat rules
- `max_hp = 20 + end × 4`
- Initiative: `end + int / 2`, ties broken at random
- Attack damage: `weapon.power + str / 2`, ±1 random. Defending halves the damage you take until your next turn.
- **Talking** (humans only): chance = `25% + (int + kno) × 3% − enemy.resolve`, plus 15% for a matching job approach. Success ends the fight with outcome `talk`.
- Fleeing: `40% + end × 4%`. Always fails against aliens.
- **Downed and death:**
  - A companion at 0 HP is **"Am Boden"** (downed) for `downed_turns` of their own turns. Any heal revives them.
  - If they take damage while downed, or the counter runs out, they **die permanently**: `kill_companion(id, "combat:<encounter_id>")`.
  - If the fight ends while they're downed, they survive with 1 HP.
- The **player** can be downed but never dies permanently. If the player and every companion are downed or dead, the outcome is `lose`. "Nochmal versuchen" restores the state from before the fight, including companions who died in it.
- Who finishes off downed characters: scavengers never do (they're people, too). Brutes sometimes do. The swarm's area hits catch everyone, so cheat fast.

### Companions (`[TEMP]` names, the humans decide the real characters)
| id | Role | int | str | end | kno | Skill |
|---|---|---|---|---|---|---|
| `cook` | Koch/Köchin from the bunker | 4 | 5 | 6 | 4 | `emergency_ration`: heal the whole party for 5. Makes resting at the campfire stronger. |
| `tinkerer` | Bastler/in and ham-radio nerd studying the signals | 7 | 3 | 4 | 8 | `send_signal`: only usable against aliens; wins the fight by cheating. Comments on glitches. |

### Items
| id | Effect |
|---|---|
| `fists` | Weapon, power 2 (the default, never in the inventory) |
| `crowbar` | Weapon, power 4 |
| `holy_sword` | Weapon, power 15, durability 1. Breaks after the first hit. |
| `bandage` | Heals 10, revives a downed character |
| `canned_food` | Heals 6. Can be used as a bribe. Gives the cook's campfire bonus. |
| `scrap` | Does nothing yet (crafting later) |
| `jammer` | Key item, a home-made 80s radio jammer. Unlocks "Signal senden" against aliens. |

### Enemies, encounters, cheats
| id | Stats |
|---|---|
| `raider_scavenger` | HP 18, power 3, resolve 0. Flees below 30% HP. |
| `raider_brute` | HP 34, power 6, resolve 25. Targets the ally with the lowest HP and sometimes finishes off downed ones. |
| `alien_swarm` | Invulnerable. Ignores you, then hits the whole party for 12 every 2nd turn. |

| Encounter id | Enemies | Party | Notes |
|---|---|---|---|
| `raiders_street` | 2× `raider_scavenger` | active | Tutorial |
| `raiders_camp` | `raider_brute` + 2× `raider_scavenger` | active | Avoidable through dialogue |
| `alien_swarm_zone` | `alien_swarm` | all | Invulnerable, no fleeing, can only be won by cheating, cheats: `konami` |

`data/cheats.json`: `konami` = ↑↑↓↓←→←→. It works in the encounters that list it, and its in-world hint is `examine:cheat_poster`.

## Content ids
Both agents use these ids exactly. If you add a new id, list it in your handoff note.

**Scenes:** `res://scenes/levels/area1_bunker.tscn`, `area1_vorstadt.tscn`, `area1_videostore.tscn`, `res://scenes/ui/area_select.tscn`, `res://scenes/ui/alpha_end.tscn`
**Spawn ids:** `start` for the new game in the bunker, otherwise `from_<scene>` (e.g. `from_bunker` in area1_vorstadt)
**Areas:** `area1_vorstadt`, `area2`

**Dialogue (`file:titles`):**
- `dialogue/area1/intro.dialogue`: `start`
- `dialogue/area1/cook.dialogue`: `first_meet`, `idle`, `campfire`
- `dialogue/area1/tinkerer.dialogue`: `first_meet`, `idle`
- `dialogue/area1/videostore.dialogue`: `clerk`, `sword_shelf`
- `dialogue/area1/raiders.dialogue`: `street`, `camp`, `camp_after_fight`
- `dialogue/area1/cult.dialogue`: `teaser`
- `dialogue/area1/alien_zone.dialogue`: `enter`, `snatching`, `dilemma`, `swarm_blocks_gate`, `after_cheat`
- `dialogue/area1/gate.dialogue`: `locked`, `open`, `coming_soon`
- `dialogue/examine.dialogue`: `tv_flicker`, `payphone`, `arcade_cabinet`, `satellite_dish`, `burnt_car`, `cheat_poster`, `alien_structure`, `bunker_door`, `cult_symbol`

**Flags:** `intro_done`, `cook_recruited`, `tinkerer_met`, `tinkerer_recruited`, `holy_sword_taken`, `holy_sword_broken`, `raiders_street_done`, `raiders_camp_resolved` (`"fight"|"talk"|"bribe"|"job"|"moral"`), `raider_spared` (bool), `cult_teaser_found`, `dilemma_choice` (string), `aliens_dispersed`, `area2_unlocked`

**Ids:**
- Jobs: `doctor`, `craftsman`, `police`, `scientist`, `civil_servant`
- Companions: `cook`, `tinkerer`
- Skills: `first_aid`, `barricade`, `arrest`, `analyze`, `file_form`, `emergency_ration`, `send_signal`
- Items: `fists`, `crowbar`, `holy_sword`, `bandage`, `canned_food`, `scrap`, `jammer`
- Enemies: `raider_scavenger`, `raider_brute`, `alien_swarm`
- Encounters: `raiders_street`, `raiders_camp`, `alien_swarm_zone`
- Cheats: `konami`

**Character art ids (Claude):** `player`, `cook`, `tinkerer`, `clerk`, `cultist`, `raider_scavenger`, `raider_brute`. Portraits use the same ids.

**Audio:** `music_title`, `music_area1`, `music_combat`, `music_alien_zone`, `amb_wind`, `amb_alien_hum`, `sfx_jump`, `sfx_land`, `sfx_pickup`, `sfx_hit`, `sfx_heal`, `sfx_ko`, `sfx_death`, `sfx_sword_break`, `sfx_glitch`, `sfx_phone_ring`, `sfx_snatch`, `sfx_cheat`, `sfx_ui_click`, `sfx_ui_confirm`

**Data files:** `data/rules.json`, `protagonist.json`, `jobs.json`, `skills.json`, `items.json`, `companions.json`, `enemies.json`, `encounters.json`, `cheats.json`, `combat_text.json`, `speakers.json`, `barks.json`, `audio.json`
**Localization files:** `localization/ui.csv`, `combat.csv`, `story.csv`, `dialogue.csv`

## Not in the alpha
Final story, text or audio. Areas beyond Area 1. Body modification. The cult's actual story. Endings (only the flags get recorded). Skill trees. Balancing beyond "every job can finish the alpha". Swapping companions in and out of the party (both alpha companions fit). Recruiting extra people through high moral (later; the alpha only proves that moral-gated options work).

## Alpha checklist (H5 confirms each item)
- [ ] Title → job selection → intro → Area 1 → gate → area select → end summary, all without the debug menu
- [ ] The whole game is playable in German **and** English, with no missing text and no overflowing text boxes
- [ ] Every job can finish the alpha (Beamter just barely)
- [ ] Both raider fights can be won by fighting **and** avoided by talking
- [ ] The holy sword breaks after exactly one hit
- [ ] The cook can die through the dilemma, and any companion can die in combat (downed → dead). The game remembers both.
- [ ] Moral-gated options appear only at high or low moral, both can be reached, and moral is never visible except in the debug overlay (F3) and the end summary
- [ ] All 3 cheat paths win the alien fight, and none of them can be missed without another one remaining
- [ ] The cult teaser can be found, but it's off the main path
- [ ] Saving and loading at the campfire works at every beat
- [ ] Every audio id plays, or stays silent without errors
- [ ] All art follows the ART_GUIDE palette; there are no placeholder shapes left on the main path
