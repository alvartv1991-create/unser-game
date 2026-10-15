# Area 1 playable — the test content wired into the game — Claude

The human asked Claude to "implement all the test things into the game" and re-check the vision. That covers parts of **Codex's H4** (levels, area select, bark display) and **Claude's H5** (flow, end summary, walkthrough). Branch `claude/area1-playable`, from `main` after the H3 merge.

## Done
- **The full flow works without the debug menu:** Title → New game → job → **bunker** (the intro plays) → street → video store → rooftop → (hidden cult crawlspace) → raider camp → alien zone → gate → **map** → Area 2 "coming soon" → **end of the alpha**.
- **Levels** (built in code on a shared builder, `scripts/world/area_level.gd`):
  - `area1_bunker`: the cook (first meeting, then idle until recruited), a campfire (rest, and the cook's campfire scene), the bunker door, the hatch.
  - `area1_vorstadt`, west to east:
    - Codex's street art, with the arcade as "Videospiele Krüger", a payphone and a TV that glitch, the burnt car, and the street raiders blocking the road.
    - The tinkerer's rooftop with the dish, a fire escape and an optional ledge with a bandage. A hidden hatch behind the chimney (faint chalk mark) leads to the cult.
    - The raider camp, which blocks the way until resolved; afterwards a campfire and cans.
    - The alien zone: the structure on the horizon, the swarm, half-dismantled cars, the bus of the dilemma, and the swarm blocking the gate.
    - The gate.
  - `area1_videostore`: shelves, two arcade cabinets, a cheat poster with legible pixel arrows, the holy sword on its stand, and the clerk.
  - `area1_crawlspace` (new, hidden): a TV with static, the cultist, the chalk symbol.
- **Vision check** (`docs/VISION.md`):
  - The intro now also says the military nuked the swarm and was then gone, and that the swarm drains water, metal and electricity.
  - The Vorstadt gets darker towards the east (power drained).
  - Aliens stay indifferent "weather". The opening street has no aliens (as the human asked).
  - Devices glitch, fights are against humans, and the alien fight needs a cheat.
- **Barks** float above the right follower for 3 s. **Device glitches** give a soft cyan/magenta screen flicker (off with "Reduce effects").
- **Area select** `scenes/ui/area_select.tscn`: a small pixel map with Area 1 (explored) and Area 2 (coming soon, playing `gate:coming_soon`).
- **End of the alpha** `scenes/ui/alpha_end.tscn` (`scripts/story/alpha_end.gd`): your job, how the camp was resolved, the raider's fate, the dilemma, who lives or died and how (decision or combat), the sword, the cult ("???" if missed), moral as a word ("Arschloch" … "Heilige/r"), thanks, and New game.
- **Automated playthrough** `scenes/debug/test_area1_playthrough.tscn`: 5 runs through the real levels and fights:
  - every job, kind and cruel, German and English;
  - the cook's death in the dilemma, the tinkerer's jam, walking away;
  - the high-moral camp pass and the low-moral raider kill;
  - the cult route.
  
  Result: **0 failures**.
- Fixed on the way: a dialogue started during a scene change waited for a signal that had already fired (the intro showed up a level late), and a freed bark label error.

## How to try it
1. `git switch claude/area1-playable` (or `main` once merged), open in Godot, F5.
2. Title → Neues Spiel → pick a job → Los geht's. Controls: A/D or arrows, Space to jump, E to talk/use, down + Space to drop through platforms, Esc for the menu.
3. Hidden cult: on the tinkerer's roof, jump over the chimney to the hatch behind it.
4. Automated: `"<godot>" --headless --path . res://scenes/debug/test_area1_playthrough.tscn` → "Area 1 playthrough: 0 failures".

## Contract changes (the other agent must know)
Additions only:
- `WorldInteractable.after_title`. On a **Gate**: plays `file : after_title` when the gate opens, then goes to `destination`. On a **Campfire**: plays it after resting.
- `AreaLevel` (`class_name`) base for story levels. `AlphaEnd.summary_lines()` (static).
- `DialogueRunner.start()` now waits until any scene change is finished, instead of waiting for the next `scene_changed` signal.
- Title → New game goes to `area1_bunker` (spawn `start`) instead of `test_visual_street`. The art preview button is still there.

## Requests to the other agent (Codex)
**Integration edits in Codex-owned files** (the human asked for this work; please keep or redo them in H4):
- `scripts/ui/title.gd`: new-game destination.
- `scripts/world/interactables/interactable.gd`: `after_title` for Gate and Campfire.
- `scripts/ui/test_h2_flow.gd`: expects the bunker; closes the intro before the movement checks.
- New files in your folders: `scripts/world/area_level.gd`, `scripts/world/levels/area1_*.gd`, `scenes/levels/area1_*.tscn`, `scripts/ui/area_select.gd`, `scenes/ui/area_select.tscn`.

**H4 can now focus on:**
- Replacing the painted placeholder set dressing with real tiles, props and backgrounds (keep node names and positions, or update the playthrough test).
- The glitch shader (the flicker in `AreaLevel` is a stand-in).
- Audio and save. The campfire still says saving comes in H4.
- Making the snatching event visible.
- Placing the `jammer` as a camp pickup if you want (the camp dialogue already gives it).

## New content ids
- Scene: `res://scenes/levels/area1_crawlspace.tscn`. Spawns: `from_bunker`, `from_vorstadt`, `from_videostore`, `from_crawlspace`, `from_gate`.
- Flags: `cook_met`, `cult_route_found`, `trigger_<id>` (story triggers, e.g. `trigger_dilemma`).
- Story keys: `AREA_SIGN_*`, `AREA_MAP_*`, `END_*` in `localization/story.csv`. Dialogue: `INTRO_START_06/07`, `COOK_CAMPFIRE_07`.

## Questions for the humans (story/design)
1. The intro's two new lines (the nuke, the blackouts) come straight from VISION.md. Keep them?
2. The end-summary moral words ("Arschloch", "Eher unangenehm", "Ganz normal verzweifelt", "Guter Mensch", "Heilige/r") are placeholders. Your words?
3. The hidden cult hatch is behind a chimney on the tinkerer's roof. Hidden enough, or too hidden?
4. The questions in `merge-2026-10-15.md` are still open.

## Known issues / not done
- **Placeholder look:** buildings, camp, zone and interiors are simple painted pixel rectangles in the palette, around Codex's street art. Real environment art is H4.
- No audio files yet, and saving is a stub (the campfire shows "saving available in H4").
- The snatching and the old man in the bus are told in text, not animated.
- Talking to companions once they've joined isn't possible yet (their barks work).
