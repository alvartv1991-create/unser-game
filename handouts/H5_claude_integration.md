# H5 — Integration: the playable alpha — Claude
**Phase 3** · branch `claude/h5-integration` · folder `Unser Game` · depends on H3 + H4 being merged · runs in parallel with H6 part A (Codex)

## Goal
Someone who has never seen the project can play from the title screen to "Ende der Alpha" in 20–30 minutes, in German or English, without the debug menu, and every item on the ALPHA_SCOPE checklist is true.

## Tasks
1. **Wire the full flow:** language → title → job selection → intro → all Area 1 beats → gate → area select → end. Resolve every `TODO(H5)`. Use Codex's `alien_swarm.tscn` in the alien fight. Replace any remaining placeholder character art.
2. **End of the alpha** (`scenes/ui/alpha_end.tscn`), the summary:
   - Job, how the raider camp was resolved, whether you spared the raider, and the dilemma choice
   - Who lived and who died, and **how** (story or combat)
   - The holy sword's fate, and whether you found the cult (a mysterious "???" line if you didn't, to hint that there's more)
   - Moral as a funny word instead of a number (e.g. from "Heiliger" to "Arschloch" [TEMP])
   - "Danke fürs Testen", and "Neues Spiel" to try a different job
3. **Content lint** (`tests/content/test_content_lint.gd`) checks every cross-reference:
   - Dialogue files and titles used in levels exist
   - Encounter, item, companion, job, cheat, audio and character art ids exist
   - Every flag that is read is also set somewhere
   - Every examine point has text
   - **Every string has both `de` and `en`**: data JSON, all localization CSVs and dialogue lines

   The humans will run this after writing new dialogue, so the error messages must be readable for non-programmers. Add a one-line command for it to WRITING_GUIDE.md.
4. **Automated walkthrough** (`tests/story/`): for each of the 5 jobs and with a fixed seed, walk through the story by driving the dialogue choices and the combat logic headlessly. Each run must reach `area2_unlocked`. Cover:
   - both sides of the dilemma
   - all 3 cheat paths
   - low and high moral runs (the gated options appear)
   - a run where a companion dies in combat

   Also check that no path exists where the player has no way left to cheat.
5. **Balance pass:** every job, including Beamter (just barely), can finish both raider fights by fighting. Combat deaths should happen if you play carelessly, but not when you play carefully. The alien fight feels hopeless until you cheat.
6. **Fix integration bugs** wherever they are. You may touch Codex's files only for integration fixes, and you must list each of those in your handoff so Codex knows.
7. **`docs/PLAYTEST.md`** for the humans:
   - How to start the game
   - What to try: each job, both languages, both sides of the dilemma, all 3 cheat paths, talking vs. fighting, a deliberately cruel run and a deliberately kind run, and finding the cult
   - About 10 feedback questions about the **vision**, not about bugs. For example:
     - Does the humor land?
     - Is combat fun or just a speed bump?
     - Does losing a companion in combat feel fair or cheap?
     - Is being powerless against the aliens fun or frustrating?
     - Do the hidden moral options feel rewarding?
     - Does the pixel art work for this tone?
     - Which job would you play again?
     - What's missing for the game to feel like "ours"?

## Done when
The DoD from AGENTS.md passes. Every item on the ALPHA_SCOPE checklist is ticked (in your handoff, say how each one was verified). The content lint and the walkthrough tests pass.
