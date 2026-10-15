# H0 — Foundation — Claude
**Phase 0** · branch: `main` (nothing else exists yet) · depends on: nothing · blocks: everything else

## Goal
Create an empty but runnable Godot project with:
- all shared APIs (the contracts in AGENTS.md)
- seed data in German and English
- the dialogue addon
- the pixel-art pipeline and style guide
- the test runner

After H0, Claude (H1) and Codex (H2) can work in parallel without waiting for each other.

## Tasks
1. **Setup.**
   - Confirm that the Godot path in AGENTS.md § Local setup works (`--version`). Use the 4.7.2 console executable for headless runs. If neither copy works, ask the human.
   - There may be a `test/` folder with an empty default Godot project, which the human created while trying out Godot. Don't build on it or delete it. Ask the human whether it can go, because a nested `project.godot` inside our project causes confusion (and `test/` vs. our `tests/` is easy to mix up).
   - Run `git init` and add a Godot `.gitignore` (ignore `.godot/`, `builds/`, `*.tmp`; keep `*.import`). Make the first commit with the existing docs and handouts.
2. **project.godot.**
   - Name "Unser Game", with the pixel-art settings from AGENTS.md § Tech stack (640×360 → 1280×720, `viewport`, `integer`, Nearest, pixel snap) and the **Compatibility** renderer.
   - Locales `de` and `en`, with `de` as the fallback.
   - Input map, keyboard and gamepad: `move_left` (A, ←), `move_right` (D, →), `move_up` (W, ↑), `move_down` (S, ↓), `jump` (Space, W, ↑), `interact` (E), `pause` (Esc), `debug_menu` (F1), `debug_overlay` (F3).
   - The overlap is fine: the cheat code listener (H1) reads raw direction presses, not game actions.
3. **Folders** exactly as in AGENTS.md, with a `.gitkeep` in each empty folder.
4. **Autoloads**, in this order: `EventBus`, `Data`, `GameState`, `SceneRouter`, `DialogueRunner`, `AudioManager`, `SaveSystem`.
   - Implement the first five completely, as specified in the contracts, including `Data.text()`, `GameState.moral_is()` and `new_game(job_id)`.
   - SceneRouter runs combat as an overlay while the level stays loaded but paused and hidden. Calling `start_combat` during a dialogue queues the fight until the dialogue ends. Until H1 exists, `start_combat` shows a placeholder with buttons for Win, Lose, Talk and "Win + Begleiter stirbt", which emits `combat_finished`.
   - `AudioManager` and `SaveSystem` belong to Codex. Create them as stubs: the contract methods, each with only `push_warning("stub")` and a neutral return value, plus the header `# Owner: Codex — stub from H0`.
5. **Data.**
   - Create all files from ALPHA_SCOPE § Data files, using the values from § Default numbers. Every player-facing text is `{"de": "[TEMP] …", "en": "[TEMP] …"}`. `combat_text.json` and `speakers.json` can stay minimal (H1/H3 fill them). `audio.json` maps every audio id to `""`.
   - `Data` validates on load: a missing required field, an unknown id reference, or a text missing `de` or `en` triggers a `push_error` naming the file and id.
   - Add `data/README.md` for the humans, with one short section per file explaining each field in plain words. Highlight `rules.json`, since that's where they tune the game.
6. **Localization skeleton.** Create `localization/ui.csv` (with one example key, which Codex then owns) and `localization/combat.csv` and `localization/story.csv` (yours), each with the columns `keys,de,en`, registered in the project settings. Show that `tr()` switches when the locale changes (`EventBus.locale_changed`).
7. **Dialogue Manager.**
   - Vendor the latest release that works with Godot 4.7 into `addons/dialogue_manager/` and enable the plugin. `DialogueRunner.start()` uses the addon's example balloon for now (H3 replaces it).
   - Add `dialogue/test/hello.dialogue` with a choice, a flag, `GameState.add_moral()`, a job condition and a hidden `moral_is("high")` option, to prove that mutations and conditions work.
   - A missing file or title shows a `[TEMP] Kein Text` line. It never crashes.
   - Check whether the addon's translation feature (static line ids + CSV) works with this version, and write the answer in your handoff (H3 relies on it).
8. **Pixel-art pipeline and style guide.**
   - **`docs/ART_GUIDE.md`:**
     - One shared palette of about 32 colors, as a palette PNG plus hex codes. Use muted, dusty post-apocalyptic 80s tones, and reserve **cyan/magenta "signal" colors for alien technology and glitches only**, so you can always see what reacts to the aliens.
     - Sizes: tiles 16×16, character frames 32×32, portraits 64×64.
     - Outline and light-direction rules, animation frame counts, and the naming rules.
     - This guide is the art contract for both agents.
   - **`tools/pixelart/`:** a headless Godot tool script that turns text-grid sprites (one character per pixel, mapped to palette indices, frames separated by blank lines) plus a small JSON describing the animations into PNG sheets and `SpriteFrames .tres` files at the paths in AGENTS.md § Art.
     - It must also accept plain PNG strips, so the humans can draw in Aseprite or LibreSprite later.
     - Add `tools/pixelart/README.md`.
     - Prove it with a 2-frame test sprite.
9. **Scenes.**
   - `scenes/main/boot.tscn` is the main scene. It goes to `res://scenes/ui/title.tscn` if that exists (Codex builds it in H2); otherwise it shows a placeholder with "Debug-Menü".
   - `scenes/debug/debug_menu.tscn` opens with F1 from anywhere and lists every `test_*.tscn` under `res://scenes/`. It also has:
     - "Testspiel vorbereiten": choose a job, both companions, starting items, and a moral value
     - a DE/EN language switch
10. **Tests.** Create `tests/test_runner.tscn` + `.gd`. The runner finds `tests/**/test_*.gd`, runs every `test_*` method, prints the results and quits with exit code 1 on any failure. Write tests for:
    - GameState: flags, moral clamping, `moral_is` thresholds, party max from rules, `kill_companion` (removes from party, emits a signal, is permanent), `rest()`, `to_dict`/`from_dict` round trip
    - Data: all files load, all cross-references resolve, every text has `de` and `en`, `Data.text()` falls back correctly
    - The pixel tool: a grid becomes a PNG with the right size and colors
11. **Docs.** Write `docs/handoff/H0.md`. If you had to deviate from a contract, update AGENTS.md and mark it as a CONTRACT CHANGE.

## Done when
The DoD from AGENTS.md passes. F1 opens the debug menu. `hello.dialogue` plays, changes a flag and moral, and shows the hidden option only at high moral. Switching to `en` changes the test texts. The pixel tool builds the test sprite. Everything is committed on `main`.

In your final message, tell the human to create the Codex worktree (handouts/README.md) and then start H1 and H2.
