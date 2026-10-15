# Writing guide

How to write and translate dialogue for Unser Game. No programming needed. Everything you write is German first; English goes into a table.

## 1. Where dialogue lives
- `dialogue/area1/*.dialogue`: one file per character or place, e.g. `cook.dialogue`.
- `dialogue/examine.dialogue`: look-at comments ("examine" texts).
- Open them in Godot (they open in the Dialogue tab) or in any text editor.
- Every placeholder line starts with `[TEMP]`. When you replace a line with your final text, drop the `[TEMP]`.

## 2. What a dialogue file looks like
```
~ first_meet
cook: [TEMP] Oh, du lebst! Gut.
cook: [TEMP] Nimmst du mich mit?
- Komm mit.
	$> GameState.recruit("cook")
	cook: Ich hol nur schnell meine Pfanne. [#mood=happy]
- Lieber nicht.
	cook: Ich bleibe hier.
=> END
```
| Part | Meaning |
|---|---|
| `~ first_meet` | A **cue**: where a conversation starts. The game starts dialogue by file and cue. |
| `cook: Text` | A line. Before the colon is the **speaker id** (see below). |
| A line without a speaker | Narration, e.g. `[TEMP] Der Fernseher flackert.` |
| `- Text` | A **choice**. What happens after it is indented with **one Tab**. |
| `$> …` | A **command** (see section 4). |
| `=> END` | Ends the dialogue. `=> other_cue` jumps to another cue. |
| `[#mood=happy]` | Shows the speaker's `happy` portrait for this line, if it exists (`assets/portraits/cook_happy.png`). Moods: `happy`, `sad`. |
| `# …` | A comment. Players never see it. |
| `{{GameState.player_name()}}` | Inserts the protagonist's name. Keep it exactly like this in German and English. |

**Speaker ids:** `player` (the protagonist), `cook`, `tinkerer`, `clerk`, `cultist`, `raider_scavenger`, `raider_brute`, `system`. The shown names and portrait colors are in `data/speakers.json`. To add a new character, add an entry there.

**The colon trap:** in a line, everything before the **first colon** counts as the speaker. `[TEMP] Darunter steht: Hallo` would make "[TEMP] Darunter steht" a speaker. In narration and choices, use a comma or a dash instead of a colon. (The test `test_every_speaker_is_known` catches this.)

**Random lines:** start lines with `%` and one of them is picked: `% cook: Ich hab Salz dabei.`

## 3. Conditions
**On a choice** (after the text):
```
- Ich bin Arzt/Ärztin. [if GameState.job_is("doctor") /]
- Ich bin Arzt/Ärztin. [if GameState.job_is("doctor") /] [#show_locked]
- Erinnert ihr euch an mich? [if GameState.moral_is("high") /]
```
- Without `[#show_locked]`, the choice is **hidden** when the condition isn't met.
- With `[#show_locked]`, it's **shown greyed out** with the reason, e.g. "[Arzt/Ärztin] Ich bin Arzt/Ärztin." The reason is found automatically for jobs, items and companions.
- **Moral choices are always hidden**, even with `[#show_locked]`. Moral is secret.

**On lines** (indent what belongs to it with a Tab):
```
if GameState.in_party("tinkerer")
	tinkerer: Das ist das gleiche Muster!
elif GameState.job_is("scientist")
	player: Das Flimmern hat einen Takt.
else
	player: Wenigstens läuft kein Dallas.
```
Combine with `and`, `or`, `not`: `if GameState.is_recruited("cook") and not GameState.is_alive("cook")`.

| Condition | True when … |
|---|---|
| `GameState.job_is("doctor")` | the player's former job is … (`doctor`, `craftsman`, `police`, `scientist`, `civil_servant`) |
| `GameState.in_party("cook")` | the companion is in the active party (and alive) |
| `GameState.is_recruited("cook")` | the companion was ever recruited (also if dead now) |
| `GameState.is_alive("cook")` | the companion lives. **Use this for deaths**, so combat deaths count too. |
| `GameState.has_item("canned_food")` | the item is in the inventory; `has_item("bandage", 2)` for at least 2 |
| `GameState.get_flag("tinkerer_met")` | a flag is set; compare values with `== "talk"` |
| `GameState.moral_is("high")` | moral is high (`low`, `neutral`, `high`) |

## 4. Commands writers may use
| Command | Example |
|---|---|
| Change moral | `$> GameState.add_moral(10)` or `$> GameState.add_moral(-15)` |
| Set a flag | `$> GameState.set_flag("tinkerer_met")` or `$> GameState.set_flag("raiders_camp_resolved", "talk")` |
| Recruit a companion | `$> GameState.recruit("cook")` |
| **Kill a companion** (permanent) | `$> GameState.kill_companion("cook", "story:dilemma")` (the reason is `story:<cue>`) |
| Give an item | `$> GameState.add_item("canned_food")` or `$> GameState.add_item("bandage", 2)` |
| Take an item | `$> GameState.remove_item("canned_food")` |
| Equip a weapon | `$> GameState.equip_weapon("holy_sword")` (add it first) |
| New objective | `$> GameState.set_objective("OBJ_OPEN_GATE")` (text in `localization/story.csv`) |
| Unlock an area | `$> GameState.unlock_area("area2")` |
| Rest (full heal) | `$> GameState.rest()` |
| **Start a fight** | `$> SceneRouter.start_combat("raiders_camp")`. It begins when the dialogue ends; put `=> END` after it. |
| Device glitch | `$> EventBus.device_glitch.emit(0.5, 1.5)` (strength 0–1, seconds) |
| Sound | `$> AudioManager.play_sfx("sfx_phone_ring")` (ids in `docs/ALPHA_SCOPE.md`) |

Item ids are in `data/items.json`, fight ids in `data/encounters.json`, flag ids in `docs/ALPHA_SCOPE.md` § Content ids. New flags are fine; tell the agents.

**After a fight:** you don't need to write anything. After the camp fight is won, `raiders:camp_after_fight` starts by itself; after the alien fight, `alien_zone:after_cheat`. Companion one-liners ("barks") are in `data/barks.json`.

## 5. English, step by step
1. Write or change the German in the `.dialogue` file and save it.
2. Run the **translation sync**:
   - in the game: F1 → `dialogue/test_dialogue.tscn` → **Übersetzungen syncen**, or
   - in the Godot editor: open `scripts/dialogue/sync_translations_editor.gd`, then *File → Run* (Ctrl+Shift+X).
3. Every line now ends with an id like `[ID:COOK_FIRST_MEET_03]`. **Don't change or delete these ids**; they connect German and English. (Copying a line? Delete the copied id, and the sync makes a new one.)
4. Open `localization/dialogue.csv` in LibreOffice, Excel or Google Sheets (UTF-8, comma-separated). Columns: `keys`, `de`, `en`.
   - New lines have `[EN?] <German>` in `en`. Replace it with the English.
   - If you changed German text that already had English, the sync lists the id ("please re-check the English of …"). Check that English line.
5. Save as CSV (UTF-8). In Godot, the new English appears after the editor reimports the file (switch to the editor window once).

German is always read straight from the `.dialogue` files, so German changes show up immediately. Untranslated lines show the German with `[EN?]` in English.

## 6. Testing a scene
F1 (debug menu) → `dialogue/test_dialogue.tscn`, the **dialogue tester**:
- pick the file and cue, the job, which companions are recruited or dead, items, flags (`tinkerer_met, raiders_camp_resolved=talk`) and moral (buttons for low/neutral/high),
- **▶ Abspielen** resets the game to that setup and plays,
- **Weiterspielen** plays the next cue but keeps the state (e.g. play the dilemma, then the gate),
- DE/EN switches the language, also while a line is shown,
- the bottom shows moral, flags, party, items and the objective after each dialogue,
- it remembers your last setup.

Fights started from a dialogue really start in the tester. Story follow-ups after fights only run in the real levels.

**In the real game:** the levels start the dialogue (see the table in `docs/handoff/H3.md`). To check that the whole of Area 1 still plays through after your changes, run the automated playthrough: F1 → `debug/test_area1_playthrough.tscn` (it plays 5 runs by itself and prints "Area 1 playthrough: 0 failures" in the console).

## 7. Naming and placeholders
- Cues and ids: `snake_case`, English (`first_meet`, `camp_after_fight`).
- One file per character or place. Look-at comments go into `examine.dialogue`, one cue per thing.
- `[TEMP]` marks text the agents wrote. The agents never write big lore (alien origins, the cult, endings); they leave questions in their handoff notes.
- The 1980s: payphones, CRTs, cassettes, Walkmans, arcades. No smartphones, no internet.
- Keep lines short: the box shows about three lines at a time, and German runs longer than English.
