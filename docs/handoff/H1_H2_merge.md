# H1 + H2 — Integration and unified visual pass — Codex

## Done
- The human explicitly authorized merging `claude/h1-combat` and `codex/h2-world-ui` into `main`, resolving conflicts and using Codex's new graphics. They then explicitly extended the task to restyling Claude's graphics too.
- Integrated H1 at `3861631` and H2 at `21101b0` on a temporary integration branch before advancing main. Both Git merges completed without textual conflicts.
- Resolved the behavioral connections: player/menu now call `SceneRouter.is_debug_menu_open()`; inventory uses H1's `GameState.equip_weapon()`; the runtime flow test now completes real combat instead of simulating `combat_finished`.
- Main-menu background and the new-game route now use Codex's original streetscape. The older platforming interaction laboratory remains reachable through F1. No active aliens or glitch events occur in the ordinary street art sample.
- Updated H1's existing player and raider graphics and added matching cook/tinkerer/clerk/cultist sprite resources and seven portraits. Every sprite has all nine existing animation names. Existing resource ids and existing SpriteFrames UIDs are preserved.
- Added a native-pixel combat backdrop using the original street layers, fighter grounding shadows, and the machine-shard swarm scene through H1's existing optional FX hook. No combat rules were changed by the visual pass.
- Added **Grafikübersicht / Art gallery** to the title menu; all seven characters, portraits and animation states can be reviewed there.
- Updated the common debug-screen theme to use the shared visual style. Updated `docs/ART_GUIDE.md` under the human's explicit visual-work authorization: side view, richer 80s atmosphere, ordinary shop neon allowed, no active aliens in the opening. Palette, viewport, renderer and sprite sizes are retained.
- Editable character/portrait sources are `.pxl`; regeneration templates are `tools/build_character_visuals.gd`. Existing street art sources remain in `tools/build_visual_street.gd`. No outside character art or reference-image pixels were imported.

## Summary of both handoffs
### Claude H1
- Working turn-based combat for all three encounters and five jobs: skills/cooldowns, items, defend, talking, fleeing, breakable holy sword, downed/death/retry and three alien-cheat paths.
- Supports encounters involving the whole living roster, a full combat screen and a configurable test scene. Rules/data are separate from the scene; autopilot hooks support automated playthroughs.
- Added `GameState.equip_weapon()`, start weapon in inventory, `SceneRouter.is_debug_menu_open()`, `data/talk.json`, enemy initiative and skill cooldown data.
- Balance findings are from H1's simulations: all jobs perform well with the intended party; solo scientist/Beamter are much less reliable. The raider brute is now HP 44/power 7.
### Codex H2 and visual follow-ups
- Working platformer movement, following companions, configurable interactables, persistent HUD, pause/inventory/party/options, DE/EN UI and saved preferences.
- Added an interaction laboratory and side room, plus the separate ordinary 80s street art sample with layered backdrop, warm shops, neon, reflections and optional weather.
- Audio/save hooks remain placeholders for H4. Partial H0 dialogue translation and missing examine text remain H3 work. The new visual pass supersedes old handoff statements that cook/tinkerer have only shape placeholders.

## How to try it
1. Open `C:\Users\marco\Desktop\Unser Game - codex\project.godot` on main, press F5, select a language, then New game -> job -> the new street graphics.
2. Use **Grafikübersicht / Art gallery** on the title to inspect portraits and sprites. It cycles idle/walk/jump/fall/combat/attack/skill/hurt/downed automatically.
3. F1 -> `combat/test_combat.tscn` to play fights; F1 -> `levels/test_platforming.tscn` for interactables and platforms. The peaceful visual sample itself contains no forced fights or story events.
4. CLI: use the console executable listed in AGENTS.md with `--headless --path . res://tests/test_runner.tscn` and `--headless --path . --quit-after 300`.
5. Runtime flow: `res://scenes/ui/test_h2_flow.tscn`. Visual/animation and real-combat QA: `res://scenes/ui/test_visual_merge.tscn`; add `-- --capture` without headless to save actual DE/EN renderings in ignored `builds/merged_art/`.

## Validation
- 61 tests passed, 0 failed, including every job/encounter in both locales through the actual combat screen.
- Bilingual H2 flow passed with 0 failures: new-game route uses the new graphics, inventory equips a weapon through H1, level/combat/HUD transitions and return all work.
- Merged visual QA passed with 0 failures: all seven sprites/portraits exist, every animation is present, and all three real combats complete in both languages.
- Title smoke test (300 frames) printed no errors. Only the expected H4 audio stub warning remained.
- All 33 project PNGs passed the shared-palette lint. Rendered gallery, street, camp and swarm views were visually inspected at 640x360.

## Contract changes (the other agent must know)
- No shared signal or method was renamed/removed. H1's documented additions are now available with H2's consumers.
- The title's interim new-game destination is now `test_visual_street.tscn`, replacing the plain test laboratory. H4/H5 still need to wire the actual intro and Area 1.
- `scenes/fx/alien_swarm.tscn` now exists and implements H1's `set_mood("idle"|"agitated"|"dispersed")` hook. It is instantiated only for an explicit alien encounter.
- Existing character resource ids now resolve for all seven agreed characters. Portraits use the existing 64x64 path convention; sprites remain 32x32.
- The visual pass edits in Claude-owned areas were explicitly requested by the human: character/portrait resources and sources, `scenes/combat/combat.gd` (backdrop attachment only), `combatant_view.gd` (visual shadow only), `scenes/debug/debug_ui.gd` (shared theme), and `docs/ART_GUIDE.md` (visual direction).

## Requests to the other agent
- Claude should start H3 from the updated main, not continue from the pre-merge H1 state. The original Claude worktree/branch was left untouched.
- H3: replace the H0 dialogue UI/test text and finish bilingual dialogue/examine content. Human story files were not edited.
- H4: implement save/audio, preserve the settings keys documented in H2, restore level music after combat, and wire the actual levels using the new art direction.
- Later handwritten `.pxl` changes must also be incorporated into `tools/build_character_visuals.gd` before regenerating from templates, or use the normal pixelart builder directly on the edited sources.

## New content ids
- Scenes: `test_art_gallery`, `test_visual_merge` (visual/debug tools); existing optional `alien_swarm` FX hook fulfilled.
- UI keys: `UI_EQUIP`, `UI_EQUIPPED`, `UI_ART_GALLERY`, `UI_ART_ANIMATION`, `UI_ART_<character_id>` (all in `localization/ui.csv`).
- No story/encounter/item/flag/audio ids added. Existing character ids were filled, not renamed.

## Questions for the humans (story/design)
- H1's open decisions: show talk success percentages? Keep the swarm's fatal damage to downed companions? Is the camp's party-dependent difficulty right?
- H2's open feedback: movement/jump feel, UI readability, and the new visual direction. The new figures are still [TEMP] designs, not final character identities.

## Known issues / not done
- This is the merged H1/H2 milestone, not the finished story alpha. H3/H4 and end-to-end H5 remain.
- Audio/save are still intentional H4 stubs. Dialogue translations/examine text are incomplete as documented in H0/H2.
- Full tests involving the vendored dialogue addon still print the previously documented ObjectDB/resources-at-exit diagnostics after reporting passing tests. Normal title smoke runs do not print errors; no new gameplay script errors occurred.
- Reference-level polish is not claimed: this is a unified first visual pass under the existing 640x360/32-color source constraints.
