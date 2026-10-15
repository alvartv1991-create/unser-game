# H3 — Dialogue, writer pipeline, alpha story, characters — Claude
**Phase 2** · branch `claude/h3-dialogue-story` · folder `Unser Game` · depends on H1 + H2 being merged · runs in parallel with H4 (Codex)

## Goal
Dialogue feels good to play in German and English. The humans can write and translate scenes without a programmer. The whole Area 1 story runs with `[TEMP]` text, including companion death, the hidden moral options and the cult teaser. Every character has a sprite and a portrait.

## 1. Dialogue UI (`scenes/dialogue/balloon.tscn`)
Replace the example balloon, in pixel style:
- Speaker name and a 64×64 portrait from `assets/portraits/<speaker_id>.png` (speakers are defined in `data/speakers.json`)
- Typewriter text that can be skipped with E or a click
- Choices that work with keyboard and gamepad
- Uses `ui/theme.tres`
- Long German sentences must fit at 640×360, so test the worst cases

Choice conditions:
- **Job, party or item conditions:** support two ways of handling an unmet condition, chosen by a tag in the dialogue file: hidden, or shown greyed out with the reason (e.g. "[Arzt]").
- **Moral conditions** (`GameState.moral_is("low"/"high")`) are **always hidden**. Moral is a secret, so the player should only notice that an option is *there*.

## 2. Two languages
Set up Dialogue Manager's translation workflow (static line ids + `localization/dialogue.csv`), based on what H0 found out about it:
- German is written in the `.dialogue` files. English goes into the `en` column, which is editable in LibreOffice, Excel or Google Sheets.
- Add a one-click way (an editor button or a script) to regenerate line ids and the CSV after the humans edit German text, without losing existing English.
- Fill in English for every `[TEMP]` line you write.

If this workflow turns out clunky with the installed version, propose an alternative in your handoff before you build it.

## 3. Writer pipeline: `docs/WRITING_GUIDE.md`
This is for the humans, so keep it short and full of examples. It covers:
- How a `.dialogue` file looks: speakers, choices, conditions (job, party, items, flags, hidden moral options)
- The complete list of commands writers may use, each with one example line: `GameState.*`, `SceneRouter.start_combat`, `EventBus.device_glitch.emit`, `AudioManager.play_sfx`, …
- How to start a fight, kill a companion, give an item, or change moral
- How the English translation works, step by step
- How to test a single scene
- The `[TEMP]` convention and naming rules

Also build the **dialogue tester**, `scenes/dialogue/test_dialogue.tscn`: choose any file and title, set the job, party, flags, moral and language, then play it. This is the humans' main tool for writing, so make it convenient.

## 4. Area 1 story wiring
Write every dialogue file and title listed in ALPHA_SCOPE § Content ids, following the beats in § Playthrough. Rules:
- Short and funny, in the tone of docs/VISION.md, with `[TEMP]` on every line. Set it in the 80s, with no anachronisms. Invent no big lore; put lore questions in the handoff.
- Each companion gets a first meeting with a recruit choice, 2–3 idle lines, one reaction to a glitch and one to the holy sword breaking.
- Every job gets at least one unique option somewhere in Area 1. Beamter options are always useless and always funny.
- **Moral:**
  - Offer enough moral choices *before* the raider camp that both `low` and `high` can be reached.
  - At least one hidden high-moral option: a raider lets you through at `raiders:camp`.
  - At least one hidden low-moral option: killing the surrendering raider at `raiders:camp_after_fight`. Set `raider_spared`.
  - `docs/MORAL_LOG.md`: a table of every choice that changes moral (file, title, choice, delta) and every gated option, so the humans can tune it.
- **The dilemma** (`alien_zone:dilemma`):
  - At least 3 options.
  - One option that *sounds* reasonable permanently kills the cook (`GameState.kill_companion("cook", "story:dilemma")`).
  - One option costs moral.
  - The outcome may depend on the job or the party.
  - Set `dilemma_choice`.
- **Deaths are remembered:** whether a companion died in the dilemma or in combat, later dialogue reacts to it (at least the tinkerer, if alive, and the gate scene). Check `GameState.is_alive()`, not one specific flag, so combat deaths count too.
- **The cult teaser** (`cult:teaser`): cryptic, a little funny and a little unsettling. No answers. Sets `cult_teaser_found`.
- Set objectives with `GameState.set_objective()` at every beat (localized through `localization/story.csv`).
- Write examine texts for every examine id in ALPHA_SCOPE, plus any new ids Codex lists in `docs/handoff/H2.md` and `H4.md`. Those notes may arrive late; leave missing ones to H5.

## 5. Companions and barks (`scripts/story/`)
- Recruiting goes through dialogue and `GameState.recruit()`. Respect `rules.max_active_companions`. Both alpha companions fit; the swap UI comes later.
- Companions react with short barks through `EventBus.bark_requested(speaker_id, text)` (Codex shows them above the follower in H4):
  - to `device_glitch`, with a cooldown (the tinkerer reacts the most)
  - after fights
  - when entering an area
  - when a companion has died

  Bark texts live in `data/barks.json` as `{"de", "en"}`, not in scripts.

## 6. Character art (following ART_GUIDE)
- Sprites: `cook`, `tinkerer` (all world + combat animations), `clerk` and `cultist` (idle + talk-friendly idle)
- Portraits (64×64) for `player`, `cook`, `tinkerer`, `clerk`, `cultist`, `raider_scavenger` and `raider_brute`, each with at least a neutral and one emotional variant for the main cast

## Done when
The DoD from AGENTS.md passes. Every Area 1 dialogue plays in the tester in both languages. Moral-gated options appear only at the right moral. The bad dilemma choice kills the cook, and the HUD, party screen and later dialogue all reflect it. A combat death is reflected the same way. A human could follow WRITING_GUIDE.md to add and translate a new NPC conversation without help.
