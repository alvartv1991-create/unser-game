# H2 follow-up — Playable visual street sample — Codex

## Done
- Implemented the human's request to start the visuals in `codex/h2-world-ui`.
- Followed their clarification: the supplied images illustrate art style; **aliens are not active at the beginning**. This sample contains ordinary steady shop lights and weather. It does not emit `device_glitch`, spawn aliens, show a rift or invent an opening story event.
- Added `scenes/levels/test_visual_street.tscn`, a playable 1280x360 side-view scene using the existing player controller and pixel-grid camera.
- Original, reproducible environment art in four layers: moon/clouds, distant houses/trees/water tank, street/storefronts/props/reflections, and foreground silhouettes. Backdrop layers scroll at different rates.
- Detailed the arcade and cafe with brickwork, warm interior lamps, cabinets, tables, small wall notices, glass highlights and neon fascia. Added payphone booth, old car, benches, bins, power poles and overhead lines.
- Steady additive shop lighting, subtle animated rain and puddle ripples. Rain and ripples stop when Reduce effects is enabled; no flickering or camera-wide flashes.
- Replaced the bare HUD rows with compact framed cards using existing portraits when available and existing sprite frames as fallback. HP and names still follow GameState; party/memorial menu remains available.
- Added the bilingual title-menu entry **Grafikvorschau / Art preview**. It opens the standalone art sample without changing the story/new-game route. F1 also discovers the test scene.
- Asset source: `tools/build_visual_street.gd`. All 20 source PNGs in the project passed the existing 32-color palette lint. Runtime light compositing uses the existing Compatibility renderer, with no palette/source format change.
- Verification: 27 unit/integration tests passed; existing bilingual H2 runtime flow passed with 0 failures; visual-street movement/floor/jump checks passed in both locales, with no alien interference events; title and new scene smoke runs printed no errors. DE/EN rendered views of the arcade, cafe and tree edge were inspected at the actual viewport size.

## How to try it
1. Open the Codex worktree's `project.godot`, press F5, choose a language if needed, then **Grafikvorschau / Art preview**.
2. Alternatively, open `scenes/levels/test_visual_street.tscn` and press F6.
3. A/D or arrows: walk. Space/W/up: jump. Esc: menus. Walk right past the cafe and car to the tree-lined edge. There is no alien event in this sample.
4. Switch language in Options. Enable Reduce effects to disable the animated weather.
5. Rebuild assets with the Godot console executable and `--headless --path . --script res://tools/build_visual_street.gd`, then `--headless --path . --import`.
6. Scene QA: `--headless --path . res://scenes/levels/test_visual_street.tscn -- --visual-qa`. For rendered DE/EN screenshots, omit `--headless` and add `--capture`; output is in ignored `builds/visual_street/`.

## Contract changes (the other agent must know)
- No shared API or existing content id changed. Player, spawn and UI hooks are preserved.
- Per the human's explicit style direction, ordinary shop neon now uses cyan/magenta. Color alone is therefore not a reliable alien marker. `docs/ART_GUIDE.md` still needs Claude's corresponding update.
- The new scene is an art-direction test, not the actual intro or Area 1. Choosing its night/weather presentation does not decide the story's opening time, location or weather.
- Existing character resources are reused. No character/portrait files or human story files were changed in this pass.

## Requests to the other agent
- Claude: read the human clarification above before integrating visuals or writing the opening. Do not import attacks, rifts or active interference from the reference pictures into the start of the game.
- Claude: align the art guide's neon restriction with the human's references. The source palette, sprite sizes, viewport and renderer remain compatible.
- Integration: preserve the title's art-preview button while the sample is useful. Remove or hide it for a release build if requested later.
- Character/portrait replacements can continue to use the existing resource ids; the new HUD will pick them up.

## New content ids
- Scene: `test_visual_street` (debug/art preview only).
- UI keys: `UI_VISUAL_PREVIEW`, `UI_STREET_CONTROLS`, `UI_STREET_ARCADE`, `UI_STREET_CAFE`, `UI_STREET_OPEN`.
- No story flags, dialogue cues, item ids or audio ids added.

## Questions for the humans (story/design)
- Perspective is resolved: side view.
- This is the first playable environment art pass. Feedback on lighting, density and the relative size of the character will guide the next art pass; no story decisions are inferred from it.

## Known issues / not done
- This is a first visual pass at 640x360, below the supplied example images' detail density. It does not claim to match their final polish.
- The player still uses the inherited H0 character placeholder, and the HUD uses its sprite until portrait art is available. Companion art also retains the established fallback.
- The scene demonstrates environment presentation and movement; it is not a story chapter and has no scripted interactions or gameplay objectives.
- Audio/save implementation remains H4 work. Expected H0 stub warnings remain.
- The existing dialog-addon exit-resource diagnostics remain when running the full dialogue tests; title/world smoke runs have no errors.
