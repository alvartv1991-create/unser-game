# H2 — Platformer, interactables, UI shell — Codex
**Phase 1** · branch `codex/h2-world-ui` · folder `Unser Game - codex` · depends on H0 · runs in parallel with H1 (Claude)

## Goal
Build a 2D platformer character that feels good to control, a reusable kit of interactable objects, and every menu except combat and dialogue, all in pixel art at 640×360 and in German and English. All of it must be playable in test scenes without the story.

Read `docs/ART_GUIDE.md` first. It is the shared art contract with Claude: palette, sizes and rules.

## 1. Player (`scenes/world/player.tscn`, `scripts/world/player.gd`)
- CharacterBody2D with acceleration-based running, jumping with coyote time, jump buffering and variable jump height, and dropping through one-way platforms (down + jump).
- The player can't move between `dialogue_started` and `dialogue_finished`, during the transition into combat, or while a menu is open.
- Camera2D with smoothing and per-level limits, pixel-snapped so nothing jitters.
- Use `assets/sprites/characters/player.tres` (Claude draws it in H1). Until it exists, use the contract fallback: load by id, show a placeholder if it's missing.
- Companions in `GameState.party` follow the player as trailing figures (sprites by id, same fallback). Update them on `companion_recruited`, `companion_died` and `party_changed`.
- **Movement is the first thing people judge.** Spend time on the feel.

## 2. Interactables (`scripts/world/interactables/`, `scenes/world/interactables/`)
Build one base `Interactable` (Area2D) that shows "[E] <Aktion>" (localized) when the player is in range. Every interactable has the optional exports `required_flag`, `hidden_if_flag` and `required_moral` (`"low"`/`"high"`, for hidden things). The types, all configured in the inspector:

| Type | What it does |
|---|---|
| Talk | `DialogueRunner.start(file, title)` |
| Examine | `DialogueRunner.start("res://dialogue/examine.dialogue", examine_id)`. This is the Edna-style look-at, the main source of humor. |
| Pickup | `GameState.add_item(id, n)`, shows a toast and disappears for good (store a flag `picked_<scene>_<node>`) |
| Door | `SceneRouter.go_to(scene, spawn_id)` |
| EncounterTrigger | `SceneRouter.start_combat(id)`, once only (flag) |
| StoryTrigger | Area2D that starts a dialogue automatically when the player enters it, once only (flag) |
| Campfire | `SaveSystem.save_game(0)` + `GameState.rest()` + toast |
| GlitchDevice | `kind`: `tv`, `payphone`, `radio` or `arcade` (80s only). When the player is near, it emits `device_glitch(intensity, duration)` and plays its own effect: static, ringing, noise, garbled screen. |
| Gate | Blocked until a flag is set (shows the "locked" dialogue), then works like a door |
| SecretPassage | Looks like the background until you touch or examine it, then opens a hidden route. It's for the cult teaser and other secrets. |

Add a `SpawnPoint` node with a `spawn_id`, which SceneRouter uses to place the player.

## 3. UI shell (`scenes/ui/`, `scripts/ui/`, `ui/theme.tres`, `localization/ui.csv`)
- **`scenes/ui/global_ui.tscn`** is the persistent overlay that SceneRouter loads once (see the AGENTS.md scene hooks). The HUD, pause menu, toasts and F3 overlay go here, so they work in every level without being placed per level. Hide the HUD on the title screen and during combat.
- **Global theme** in pixel style: one OFL/CC0 pixel font with ä ö ü ß (credit it in `assets/CREDITS.md`), 9-slice panels in the ART_GUIDE palette, and clear focus states for keyboard and gamepad. Claude's combat and dialogue UIs will use it.
- **Every label goes through `tr()`.** There is no hard-coded text, in either language.
- **First start:** a language selection screen (Deutsch / English), saved in `user://settings.cfg`.
- **Title** (`scenes/ui/title.tscn`, which boot already routes to): Neues Spiel, Laden (disabled while there's no save), Optionen, Beenden. Use a simple pixel title placeholder; the game has no name yet.
- **Job selection** ("Was warst du vorher?"): the protagonist is a fixed person for now (`GameState.player_name()`, never hard-coded, because customization may come later), so this screen only picks the former job. Show **all** jobs from `data/jobs.json` (5 now, **up to 10** later, so design the layout for 10) with stat bars, the description and the skill. Show Beamter honestly as terrible. Confirming calls `GameState.new_game(job_id)` and goes to your test level (H4 changes this to the bunker).
- **HUD:** party HP bars (a dead companion's bar disappears), the current objective (`objective_changed`) and toasts for `item_changed`, `companion_recruited`, `companion_died` and `area_unlocked`.
- **Pause (Esc):** Weiter, Inventar, Party, Optionen, Hauptmenü.
- **Inventory:** items with their descriptions. Healing items can be used outside of combat.
- **Party:** stats, job and skills for each member. Dead companions get a small "In Erinnerung" section with the cause of death. Moral is never shown.
- **Options:** language (switches live, emits `locale_changed`), Master/Music/SFX/Ambience volume (through `AudioManager.set_volume`), fullscreen, and "Effekte reduzieren" (H4 uses it for the glitch shader). Save them in `user://settings.cfg`.
- **Debug overlay (F3):** flags, inventory, party and **moral**. This is the only place in the game where moral is visible.

## 4. Art in this handout (yours, following ART_GUIDE)
- The UI kit: panels, buttons, icons for items and HP, and the interact prompt
- A first 16×16 test tileset for the test level (ground, platform, one-way platform, wall, a few 80s props: a CRT TV, a payphone, an arcade cabinet)

## 5. Test scene
`scenes/levels/test_platforming.tscn`: a small level with every interactable type, normal and one-way platforms, a gate, a door to a second tiny room, a secret passage, and one GlitchDevice of each kind. Use `dialogue/test/hello.dialogue` for Talk.

## Notes
- Don't build the real Area 1 yet (that's H4).
- `AudioManager` and `SaveSystem` stay stubs until H4, but call them already (`sfx_jump`, `sfx_land`, `sfx_pickup`, `sfx_phone_ring`, `sfx_ui_click`, `sfx_ui_confirm`).
- Don't touch Claude's files. If you need something from them, add it to "Requests to the other agent" in your handoff.

## Done when
The DoD from AGENTS.md passes, and this whole flow works in both languages: language selection → New game → job selection → test level → walk, jump, drop, talk, examine, pick up, campfire, gate, door, secret passage → pause, inventory, party and options all work → F3 shows the state.
