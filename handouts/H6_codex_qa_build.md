# H6 — Review, smoke tests, Windows build — Codex
**Phase 3** · branch `codex/h6-qa-build` · folder `Unser Game - codex` · **Part A** runs in parallel with H5 · **Part B** starts after H5 is merged into main

## Part A (start right away, only touch your own files)
1. **Windows export:**
   - `export_presets.cfg` for Windows Desktop, including both translations
   - `tools/build_windows.ps1`, which exports to `builds/windows/UnserGame_<version>.exe` and reads the version from a `VERSION` file (start at `0.1.0-alpha`)
   - If the export templates are missing, tell the human exactly how to install them, then stop.
2. **Smoke test** (`tests/smoke/`): load every `.tscn` under `scenes/` headlessly, instantiate it, run a few frames **in both locales**, and fail on any error or warning that isn't a known audio stub warning.
3. **Performance:** the glitch shader plus the swarm should run at 60 fps on modest hardware (integrated graphics). Add a particle or boid limit if needed.
4. **Pixel check:** at 1280×720, 1920×1080 and 2560×1440 (integer scaling), check for blurry sprites, jitter while the camera moves, and mixed pixel sizes.

## Part B (after H5 is merged; run `git merge main` into your branch first)
1. **Second-pair-of-eyes review** of the whole project, especially Claude's areas (combat, dialogue, story):
   - Crashes and errors in the log
   - **Softlocks:** can the player get stuck anywhere? Think of a dead cook, a dead tinkerer, a skipped tinkerer, a missed jammer, or a broken sword plus no crowbar.
   - Save/load at every beat, including mid-level, right after the dilemma and right after a combat death
   - Input conflicts (menu + dialogue + combat at the same time, F1/F3 during combat, arrow keys during the cheat code entry)
   - **Text in both languages:** German overflowing its boxes (long words!), missing English, `[EN?]` markers visible, umlauts rendering in the pixel font
2. **Fixing:** fix bugs in your own areas directly. For bugs in Claude's areas, **don't edit**. List them in `docs/handoff/H6.md` with file:line, how to reproduce, and a suggested fix, sorted by severity.
3. **Final build:** export the build and tell the human where the `.exe` is. The co-writer should be able to play it without installing Godot. Check that the build starts on a clean path with no Godot editor involved.

## Done when
The DoD from AGENTS.md passes. The smoke test covers every scene in both languages. The `.exe` exists and starts. The bug list for Claude is in the handoff, sorted by severity.
