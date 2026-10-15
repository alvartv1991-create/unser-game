# AGENTS.md — rules for every AI agent on this project

Claude Code reads this through `CLAUDE.md`. Codex reads it directly. Read all of it before every task.

## The project
Working title **"Unser Game"** (the final title is still open). It is a 2D side-view **pixel-art** game where you explore as a platformer and fight in turn-based combat. It is set in an alternate **1980s** after an indifferent alien machine swarm arrived. It is story-rich with humor in the style of *Edna bricht aus*. Companions can die, both from wrong decisions and in combat.

- Vision and the humans' answers to the open questions: [docs/VISION.md](docs/VISION.md)
- What we build right now: [docs/ALPHA_SCOPE.md](docs/ALPHA_SCOPE.md)
- Your current task: the handout in `handouts/` that the human gave you

## Team and roles
| Who | Role |
|---|---|
| The humans (project owner + co-writer, who also does audio) | Story, dialogue, humor, characters, audio, all final design decisions. They pass messages between the agents. |
| Claude (Claude Code) | Lead and integrator. Owns the architecture, combat and party systems, the dialogue system and story wiring, **character art** (sprites and portraits), and final integration. |
| Codex | World and presentation. Owns the platformer, levels, UI and menus, save/load, the audio manager, visual FX, **environment and UI art** (tiles, props, backgrounds, UI, FX), QA and builds. |

The agents cannot talk to each other. They communicate through handoff notes (see Workflow).

## Story and text rules
- The humans write the story. Anything an agent writes (dialogue, names, item descriptions, barks) is a placeholder. Prefix every such line with `[TEMP]`.
- Keep placeholders short and funny, in the tone of docs/VISION.md. Never add big lore, such as alien origins, the cult's beliefs, endings or character backstories. If you need lore, add a question to your handoff note instead.
- **The game ships in German and English at the same time.** German is the source language. Every player-facing string exists in both languages, including `[TEMP]` placeholders (see Localization below).
- Code, ids, file names, comments and docs are English. Ids are `snake_case`.
- Player-facing text lives in `dialogue/`, `data/` or `localization/`. Scripts never contain player-facing text.
- **Era:** the 1980s. CRT TVs, landline phones and payphones, radios, walkie-talkies, arcade cabinets, cassettes. The military had GPS and its own network; civilians had no internet and no smartphones. Nothing anachronistic.

## Tech stack (fixed for the alpha)
- Godot 4.7, standard build, GDScript only (no C#), using static typing. **Compatibility** renderer (2D only, runs on weak laptops).
- **Pixel art setup:** base viewport 640×360, window 1280×720, stretch mode `viewport`, scale mode `integer`, default texture filter `Nearest`, snap 2D transforms and vertices to pixel.
- Dialogue: the Dialogue Manager addon **4.1.0** (nathanhoad), vendored in `addons/dialogue_manager/` (the C# files are removed). Version 4 syntax: commands are `$> GameState.add_moral(5)`, choice conditions are `- Text [if GameState.moral_is("high") /]`, and what our API calls a "title" is a **cue** (`~ first_meet`). Don't use the old `do`/`set` syntax.
- Game data: JSON files in `data/`, loaded by the `Data` autoload. The humans edit these files directly, so keep them readable. Tunable game rules live in `data/rules.json`.
- Tests: our own small runner scene, `tests/test_runner.tscn` (no test addon).
- **Art:** all art is pixel art drawn by the agents, following `docs/ART_GUIDE.md` and its shared palette, made with the sprite pipeline in `tools/pixelart/` or as plain PNGs. No third-party art, except one OFL/CC0 pixel font with German umlauts (ä ö ü ß), credited in `assets/CREDITS.md`.

## Localization
- Locales: `de` (the source) and `en`. The language is chosen on first start and in Options.
- **UI labels:** `tr("KEY")` with keys like `UI_NEW_GAME`, from CSV files in `localization/` with the columns `keys,de,en`. Codex uses `localization/ui.csv`; Claude uses `localization/combat.csv` and `localization/story.csv`.
- **Data JSON:** every text field is `{"de": "…", "en": "…"}` and is read through `Data.text(value)`.
- **Dialogue:** written in German in `.dialogue` files. English comes through Dialogue Manager's translation support: a line ending in `[ID:SOME_KEY]` is translated by the row `SOME_KEY,de,en` in `localization/dialogue.csv` (verified in H0). Lines without an id stay German. H3 sets up and documents the full workflow.
- Missing English shows the German text with an `[EN?]` prefix. It never crashes and never shows an empty string.

## Local setup
- **Godot executable** (4.7.2, verified in H0): `C:\Users\marco\Desktop\Random Thing\.tools\godot\Godot_v4.7.2-stable_win64_console.exe` (call it `<godot>` below). Use the `_console.exe` for command-line runs; the editor is the `.exe` next to it.
- **After adding or changing PNG, CSV or .dialogue files, or `class_name` scripts:** `"<godot>" --headless --path . --import` (rebuilds Godot's import cache and class list; it takes a few seconds).
- Run the game: `"<godot>" --path .`
- Run the tests: `"<godot>" --headless --path . res://tests/test_runner.tscn` (exit code 1 = failure). Only some files: add `-- --only <part of path>`.
- Smoke test: `"<godot>" --headless --path . --quit-after 300` (must print no errors)
- Build the sprites: `"<godot>" --headless --path . --script res://tools/pixelart/build.gd`, see `tools/pixelart/README.md`

## Folder layout and ownership
Edit only files you own. If you need a change in someone else's file, write a request in your handoff note and work around it with a local stub.

| Path | Owner |
|---|---|
| `project.godot`, `autoload/event_bus.gd`, `game_state.gd`, `data.gd`, `scene_router.gd`, `dialogue_runner.gd` | Claude |
| `autoload/audio_manager.gd`, `autoload/save_system.gd` | Codex |
| `scripts/combat/`, `scenes/combat/` | Claude |
| `scripts/dialogue/`, `scripts/story/`, `scenes/dialogue/`, `dialogue/` | Claude (placeholder text that the humans replace) |
| `scripts/world/`, `scenes/world/`, `scenes/levels/` | Codex |
| `scripts/ui/`, `scenes/ui/`, `ui/theme.tres` | Codex, except `scenes/ui/alpha_end.tscn` + its script: Claude (Codex only creates the placeholder) |
| `scripts/fx/`, `scenes/fx/`, `shaders/` | Codex |
| `assets/sprites/characters/`, `assets/portraits/`, `tools/pixelart/`, `docs/ART_GUIDE.md` | Claude |
| `assets/tiles/`, `assets/props/`, `assets/backgrounds/`, `assets/ui/`, `assets/fx/`, `assets/fonts/` | Codex |
| `localization/ui.csv` | Codex |
| `localization/combat.csv`, `localization/story.csv`, `localization/dialogue.csv` | Claude |
| `data/*.json` | Claude, except `data/audio.json` (Codex). The humans may change any value. |
| `assets/audio/` | the humans |
| `tools/` (other), `export_presets.cfg`, `VERSION` | Codex |
| `tests/<area>/` | the owner of that area |
| `docs/VISION.md`, `docs/story/` | the humans only |
| Other files in `docs/` | whoever's handout creates them (e.g. WRITING_GUIDE: Claude, AUDIO_GUIDE: Codex) |
| `scenes/debug/`, `docs/handoff/` | shared, but only add your own files |

Exception: anyone may **add** new signals to `autoload/event_bus.gd`. Never rename or remove one. Mention any addition in your handoff note.

## Contracts
These APIs connect the two agents' work. H0 implements them. Adding something is fine. Changing or removing something requires a **CONTRACT CHANGE** entry in your handoff note, so the human can tell the other agent.

### EventBus (signals only)
```gdscript
signal flag_changed(id: String, value: Variant)
signal moral_changed(value: int)                  # only the debug overlay may show this
signal item_changed(id: String, count: int)
signal companion_recruited(id: String)
signal companion_died(id: String, reason: String) # reason: "story:<dialogue title>" or "combat:<encounter_id>"
signal party_changed()
signal hp_changed()
signal objective_changed(text: String)
signal area_unlocked(area_id: String)
signal scene_changed(scene_path: String)
signal locale_changed(locale: String)
signal dialogue_started(file: String, title: String)
signal dialogue_finished(file: String, title: String)
signal combat_started(encounter_id: String)
signal combat_finished(result: Dictionary)        # {encounter_id, outcome: "win"|"lose"|"flee"|"talk"|"cheat", loot: {item_id: count}, died: [companion_id]}
                                                  # the combat scene already added the loot to the inventory and killed the dead; result is for reacting (story, toasts)
signal device_glitch(intensity: float, duration: float)   # alien tech interference; intensity 0..1, duration in seconds
signal bark_requested(speaker_id: String, text: String)   # short floating line above a character (text already localized)
```

### GameState
```gdscript
var player: Dictionary        # {name, job_id, stats: {int, str, end, kno}, hp, max_hp, weapon_id}; name "" = protagonist default
var companions: Dictionary    # id -> {recruited: bool, alive: bool, hp: int, max_hp: int, death_reason: String}
var party: Array[String]      # active companion ids (recruited and alive), max = rules.max_active_companions
var inventory: Dictionary     # item_id -> count
var flags: Dictionary         # flag_id -> Variant
var moral: int                # hidden "Solidarität", clamped to -100..100, never shown in the UI
var objective: String         # translation key from localization/story.csv (e.g. "OBJ_FIND_THE_COOK"); show it with tr()
var unlocked_areas: Array[String]

func reset() -> void                      # empty state (title screen)
func new_game(job_id: String) -> void     # the protagonist is a fixed person (for now), so the player only picks the former job
func job_is(job_id: String) -> bool       # handy in dialogue: [if GameState.job_is("doctor") /]
func player_name() -> String              # ALWAYS use this; custom name if set (later feature), else data/protagonist.json
func recruited_alive() -> Array[String]   # every recruited, living companion; for encounters/quests with "party": "all"
func combat_party(mode: String) -> Array[String]   # "active" -> party, "all" -> recruited_alive()
func set_flag(id: String, value: Variant = true) -> void
func get_flag(id: String, default: Variant = false) -> Variant
func add_moral(delta: int) -> void
func moral_is(band: String) -> bool       # "low" | "neutral" | "high", thresholds from rules.json; used to gate hidden dialogue options
func recruit(companion_id: String) -> void
func kill_companion(companion_id: String, reason: String) -> void   # permanent: alive = false, removed from party
func is_alive(companion_id: String) -> bool
func is_recruited(companion_id: String) -> bool
func in_party(companion_id: String) -> bool
func add_item(id: String, count: int = 1) -> void
func remove_item(id: String, count: int = 1) -> bool
func has_item(id: String, count: int = 1) -> bool
func equip_weapon(item_id: String) -> bool  # must be in the inventory ("fists" always works); the equipped weapon is always an inventory item
func set_objective(key: String) -> void
func unlock_area(area_id: String) -> void
func rest() -> void           # full heal for everyone; if "cook" is in the party, sets flag "well_fed" (combat may use it)
func to_dict() -> Dictionary
func from_dict(data: Dictionary) -> void
```

### Data
```gdscript
func job(id: String) -> Dictionary        # likewise skill(), item(), companion(), enemy(), encounter(), cheat()
func all(kind: String) -> Dictionary      # e.g. Data.all("jobs") -> {id: entry}; also all("audio") -> {audio_id: path}
func has(kind: String, id: String) -> bool   # probe without logging an error
var errors: PackedStringArray             # problems found in data/ (shown in the F1 debug menu)
func rules() -> Dictionary                # data/rules.json
func rule(key: String, default: Variant = null) -> Variant
func protagonist() -> Dictionary          # data/protagonist.json
func text(value: Variant) -> String       # {"de":…, "en":…} -> string in the current locale, with fallback
```

### SceneRouter
```gdscript
var current_scene_path: String
var last_spawn_id: String
func go_to(scene_path: String, spawn_id: String = "") -> void   # fades, puts the player at the SpawnPoint with that id, emits scene_changed
func start_combat(encounter_id: String) -> void
func is_in_combat() -> bool
func is_changing_scene() -> bool
func is_debug_menu_open() -> bool
# The level stays loaded but is paused and hidden under the combat scene, then resumes afterwards.
# If called while a dialogue is running, the combat starts once the dialogue ends.
```
Scene hooks used by SceneRouter. Each one is optional, and a placeholder is used until it exists:
- `res://scenes/ui/title.tscn` (Codex): boot goes here.
- `res://scenes/ui/global_ui.tscn` (Codex): instantiated **once** at startup as a persistent overlay that survives scene changes. Put the HUD, pause menu, toasts and the F3 debug overlay here.
- `res://scenes/combat/combat.tscn` (Claude): the root must have `func start(encounter_id: String)` and must emit `EventBus.combat_finished` when it's done. SceneRouter then frees it. Use a CanvasLayer root so level cameras don't affect it. Test hooks: `CombatScreen.force_autopilot = true` makes every fight play itself, `CombatScreen.force_speed = 0.0` removes all pauses (for automated walkthroughs).
- Spawning: the player is in the group `player`. SpawnPoints are in the group `spawn_points` and have `@export var spawn_id: String`.
- F1 (the debug menu) is handled globally by SceneRouter.

### DialogueRunner
```gdscript
func start(file: String, title: String = "start") -> void   # title = the Dialogue Manager cue; emits dialogue_started/finished; the player cannot move in between
func is_running() -> bool
var balloon: Node             # the balloon of the running dialogue (null when none)
# A missing file or cue shows "[TEMP] Kein Text: <file> : <cue>". It never crashes.
# Called during a scene change, it waits for the new scene first (balloons live under the current scene).
# Dialogue files may call any autoload, e.g. `$> GameState.add_moral(-10)` or `$> SceneRouter.start_combat("raiders_camp")`.
```

### Art
```text
assets/sprites/characters/<character_id>.tres   SpriteFrames, with frames 32×32
  world animations:  idle, walk, jump, fall
  combat animations: combat_idle, attack, skill, hurt, downed
  A missing animation falls back to idle. A missing file falls back to a colored placeholder shape. Never crash.
  character ids: player, cook, tinkerer, clerk, cultist, raider_scavenger, raider_brute
assets/portraits/<speaker_id>.png               64×64 (optional mood variants: <speaker_id>_<mood>.png)
Tiles 16×16. Shared palette: docs/ART_GUIDE.md.
```

### AudioManager (Codex)
```gdscript
func play_music(id: String, fade: float = 1.0) -> void
func stop_music(fade: float = 1.0) -> void
func play_ambience(id: String) -> void
func play_sfx(id: String) -> void
func set_volume(bus: String, linear: float) -> void
# Unknown id or missing file: log one warning and stay silent. Never crash.
```

### SaveSystem (Codex)
```gdscript
func save_game(slot: int) -> bool
func load_game(slot: int) -> bool      # restores GameState, then goes to the saved scene and spawn
func has_save(slot: int) -> bool
func get_info(slot: int) -> Dictionary # {timestamp, playtime, area, job}
```

## Workflow
1. **Before you start:** read this file, docs/ALPHA_SCOPE.md, your handout, and every note in `docs/handoff/`.
2. **Branches:** `main` must always run. Work on the branch named in your handout. Commit often, with messages starting `[claude]` or `[codex]`. Never merge into `main` yourself unless the human asks you to.
3. **Two agents, two folders:** Claude works in `Unser Game/` and Codex in the git worktree `Unser Game - codex/` (see handouts/README.md). Never work in the other agent's folder.
4. **Test scenes:** every system gets a standalone `test_<name>.tscn` that works without the rest of the game. The debug menu (F1) lists all of them automatically.
5. **Tests:** put logic that doesn't need a scene (combat math, state, saving) in plain scripts, with tests in `tests/<area>/test_*.gd`.
6. **Content ids** come from docs/ALPHA_SCOPE.md § Content ids. Use them exactly. If you add a new id, list it in your handoff note.
7. **Check both languages:** before you finish, run your test scenes once in `de` and once in `en`. German words are long, so check that nothing overflows.

## Definition of done (every handout)
- [ ] The smoke test prints no errors.
- [ ] All tests pass.
- [ ] Your test scenes work in German and English.
- [ ] `docs/handoff/H<n>.md` is written, using the template below.
- [ ] Your final chat message to the human is 5–10 lines: what works, how to try it, and what the human must decide or relay to the other agent.

### Handoff note template (`docs/handoff/H<n>.md`)
```markdown
# H<n> — <title> — <agent>
## Done
## How to try it
## Contract changes (the other agent must know)
## Requests to the other agent
## New content ids
## Questions for the humans (story/design)
## Known issues / not done
```
