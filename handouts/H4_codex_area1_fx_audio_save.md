# H4 — Area 1, alien FX, audio, saving — Codex
**Phase 2** · branch `codex/h4-area1-fx-audio-save` · folder `Unser Game - codex` · depends on H1 + H2 being merged · runs in parallel with H3 (Claude)

Start with `git switch -c codex/h4-area1-fx-audio-save main` in your folder.

## 1. Area 1 levels (`scenes/levels/`)
Build `area1_bunker`, `area1_vorstadt` and `area1_videostore` following ALPHA_SCOPE § Playthrough. Area1_vorstadt runs from west to east: street → video store door → the tinkerer's rooftop with a satellite dish → raider camp → alien zone → gate.
- **The setting is an 80s suburb after the end:** CRT TVs in shop windows, payphones, a dead arcade, cassette posters, boxy cars, military vehicles left behind after the alien counterstrike. Nothing modern.
- Use TileMapLayer. **Draw the tiles, props and parallax backgrounds yourself** following ART_GUIDE. Add a huge alien structure on the horizon that gets closer as you go east, and use the reserved cyan/magenta signal colors only for alien tech and glitches.
- Platforming should be easy but fun: a rooftop route, one optional corner with a pickup, and nothing that can softlock the player.
- **Hidden cult spot:** an optional side route behind a SecretPassage (sewer, back yard or crawlspace) with the `cult_symbol` examine point and the `cultist` NPC (`cult:teaser`). Most players should miss it on a first playthrough, but it must be fair to find (a subtle visual hint).
- Place every interactable with the **exact ids** from ALPHA_SCOPE § Content ids (dialogue files and titles, encounters, items, examine ids, flags). Put `jammer` as a pickup in the raider camp. Put the `cheat_poster` examine point in the video store, and make the poster itself show ↑↑↓↓←→←→ legibly in pixel art.
- Want more examine points? Add them freely and list the new ids in your handoff, so Claude and the humans can write the texts. Missing texts show a placeholder and never crash.
- Story moments without an NPC, such as entering the alien zone, use StoryTrigger.
- Job selection now goes to `area1_bunker`, spawn `start`, and plays `intro:start` first.
- Set the music and ambience per level (`music_area1`, `music_alien_zone`, `amb_wind`, `amb_alien_hum`).

## 2. Alien presence (`scripts/fx/`, `scenes/fx/`, `shaders/`)
- **Glitch shader:** a full-screen effect that looks like a bad CRT or VHS signal (scanlines, chromatic shift, horizontal tearing, tracking noise, brief signal loss), reacting to `device_glitch(intensity, duration)`. Respect the "Effekte reduzieren" option.
- **The world reacts:** TVs show static, payphones ring by themselves (`sfx_phone_ring`), radios pick up strange tones, arcade screens show garbage, streetlights flicker. All of it gets more frequent closer to the alien zone.
- **The swarm** (`scenes/fx/alien_swarm.tscn`): many small pixel machine shards (boids) that split into groups and merge again. This is the visual idea of the aliens, so make it look interesting. Claude will reuse this scene in the combat screen, so give it a simple API (`set_mood("idle"|"agitated"|"dispersed")`).
- **Snatching:** a background event in the alien zone where the swarm lifts a car, a cow and a person off-screen (`sfx_snatch`), synced with `alien_zone:snatching`.

## 3. AudioManager (replace the stub)
- Buses: Master, Music, SFX, Ambience, Voice. Ids map to files through `data/audio.json`.
- Music crossfades, one ambience layer, and the volume settings from the options menu.
- An unknown id or missing file logs one warning and stays silent.
- Build a "sound board" test scene that plays every id.
- Write **`docs/AUDIO_GUIDE.md`** for the co-writer who makes the audio:
  - Where to put files, and which formats (OGG for music and ambience loops, WAV for short SFX)
  - How looping works, a loudness target and naming rules
  - How to hear a new sound in the game quickly (the sound board)
  - **A table of every audio id with a description of what it should sound like**, with an 80s flavor where it fits (e.g. "sfx_phone_ring: an old rotary phone bell, slightly out of tune, as if something else is calling")
  - A note that voice lines (if any, later) would need both a German and an English version

## 4. SaveSystem (replace the stub)
- Save as JSON in `user://saves/slot_<n>.json`, with a `version` field, `GameState.to_dict()`, the current scene, the spawn id, the playtime and a timestamp.
- Slot 0 is for the campfire, slot 1 is the autosave on every area change.
- Title → Laden shows the slots with timestamp, area and job (localized).
- Tests: a round trip (including dead companions and moral), a corrupt file (no crash, shows a message), and a file with an older version.

## 5. Barks and area select
- Show `bark_requested(speaker_id, text)` as short floating pixel text above the right follower (or the player). They fade out, and new barks don't overlap old ones.
- `scenes/ui/area_select.tscn` ("Karte"/"Map"): a pixel map of the region that opens after the gate. It shows Area 1 and Area 2 in a locked "Demnächst" style. Choosing Area 2 plays `gate:coming_soon`, then goes to `res://scenes/ui/alpha_end.tscn`. Claude builds the summary there in H5, so create only a placeholder.

## Done when
The DoD from AGENTS.md passes. You can walk from the bunker to the gate, with the secret cult route working. Every id from ALPHA_SCOPE is placed. There are no placeholder shapes left in Area 1. Glitches and the swarm are visible. Save and load work at the campfire and through the autosave. AUDIO_GUIDE.md and the sound board exist.
