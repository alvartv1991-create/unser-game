# H1 — Turn-based combat, jobs, party, first characters — Claude
**Phase 1** · branch `claude/h1-combat` · folder `Unser Game` · depends on H0 · runs in parallel with H2 (Codex)

## Goal
`SceneRouter.start_combat(encounter_id)` opens a working turn-based fight. It uses the party from GameState and the numbers from `data/`, then returns a result through `EventBus.combat_finished`. All three alpha encounters can be played with every job, in German and English, through `scenes/combat/test_combat.tscn`. You also draw the first characters, so the game gets its pixel look early.

## Design
The numbers and rules are in ALPHA_SCOPE § Default numbers, including **downed and death**. In addition:
- **Layout** (640×360): side view, with the party on the left and enemies on the right. Each character has a pixel sprite, a name and an HP bar. The turn order is shown as a row of icons at the top. A combat log at the bottom displays the funny lines.
- **Party size:** the encounter's `party` field decides who fights. `"active"` uses `GameState.party`; `"all"` uses every recruited, living companion (`GameState.combat_party(mode)`). The layout must fit the player + 4 companions at 640×360.
- **Actions:** Angriff, Fähigkeit, Gegenstand, Verteidigen, Reden, Fliehen.
- **Reden** (humans only) carries the "you mostly fight people" pillar. It offers 2–3 approaches: Überzeugen (persuade, int), Fakten (facts, kno), Einschüchtern (intimidate, str), plus one job approach:
  - Polizist: "Dienstausweis zeigen"
  - Arzt: "Wunde versorgen" (also +moral)
  - Beamter: "Antrag auf Waffenstillstand" (never works, but logs a great line)

  Success ends the fight with `talk`. Moral changes depending on the approach.
- **Downed and death:**
  - A downed companion shows a visible countdown ("Am Boden — 2").
  - Death is a real moment: a short pause, a log line, `sfx_death`, and `GameState.kill_companion(id, "combat:<encounter>")`. Put the ids of dead companions in `result.died`.
  - Make it hurt, but keep it fair: a downed ally is always clearly marked, and healing them is always an obvious option.
  - Respect `rules.companion_combat_death == false` (in that case, downed = KO as in classic RPGs).
- **Weapons:** one per character. `holy_sword` deals big damage on the first hit, then breaks. That logs a funny line, sets `holy_sword_broken` and plays `sfx_sword_break`.
- **Aliens** (`alien_swarm_zone`):
  - Every attack does 0 damage and shows a rotating line of indifference (e.g. "Der Schwarm hat dich nicht bemerkt.").
  - Fleeing always fails ("Wohin denn?").
  - Every 2nd turn the swarm absent-mindedly hurts the whole party.
  - The fight emits `device_glitch` repeatedly.
  - It can only be won by **cheating**, with outcome `cheat`:
    1. The "Signal senden" action, if `tinkerer` is in the party **or** the player has `jammer`
    2. Typing a code from `data/cheats.json` that the current encounter lists (`konami` = ↑↑↓↓←→←→). Build this as a reusable cheat-code listener, since later bosses will get their own codes. The log openly admits that you cheated, and `sfx_cheat` plays.
- **Losing:** if the whole party is downed or dead, a "Game Over" panel offers "Nochmal versuchen" (restores the snapshot from before the fight, including dead companions) and "Letzten Spielstand laden" (`SaveSystem`, hidden if there's no save).
- **Enemy AI:** simple and readable. Scavengers flee at low HP and never hit downed characters. Brutes target the ally with the lowest HP and sometimes finish off downed ones; show their intent a turn ahead ("Der Schläger sieht Koch an…") so the player can react.
- **Text:**
  - Fixed UI labels use `tr()` with `localization/combat.csv`.
  - Skill names, barks and log templates come from `data/skills.json` and `data/combat_text.json` as `{"de", "en"}`, marked `[TEMP]`. The humans will rewrite them, so keep the templates easy to edit.

## Character art (your first pixel art, following docs/ART_GUIDE.md)
Draw these with the H0 pipeline, at the paths and with the animation names from AGENTS.md § Art:
- **`player`:** all animations (world: idle, walk, jump, fall; combat: combat_idle, attack, skill, hurt, downed). The protagonist is a fixed, ordinary 80s person. Codex's player controller will use this sprite.
- **`raider_scavenger`** and **`raider_brute`:** idle, walk, combat_idle, attack, hurt, downed.
- Readability beats detail at 32×32: a clear silhouette and one strong color accent per character.

Don't draw the cook or the tinkerer yet (that's H3); use placeholders that follow the contract fallback.

## Structure
- `scripts/combat/` contains pure logic with no nodes: `Combatant`, `CombatState`, `CombatRules` (damage, initiative, talking, fleeing, downed/death), `EnemyAI`, `CombatAction`, `CheatListener`. The RNG is injectable, so tests can use a fixed seed.
- `scenes/combat/combat.tscn` is presentation only. It uses `ui/theme.tres` if it exists; don't build your own theme, because Codex styles the UI.
- At the end, write HP back to GameState, emit `combat_finished` with the contract dictionary, and let SceneRouter return to the level. Replace H0's combat placeholder.
- Audio ids: `music_combat`, `music_alien_zone`, `sfx_hit`, `sfx_heal`, `sfx_ko`, `sfx_death`, `sfx_sword_break`, `sfx_glitch`, `sfx_cheat`.
- Codex will export a swarm visual at `scenes/fx/alien_swarm.tscn` in H4. Until then, use a placeholder and leave a `# TODO(H5)` comment.

## Test scene
`scenes/combat/test_combat.tscn`: choose the encounter, the player's job, the companions (none, cook, tinkerer or both, plus a "4 Testbegleiter" option for checking the full layout), the starting items and the language, then press Start. Afterwards it shows the result dictionary.

## Tests
- Damage and defending
- Initiative order
- The sword breaks after exactly one hit
- Downed → revived by a heal
- Downed → dies after `downed_turns`
- Downed + hit → dies, and `result.died` is correct
- The rule switch turns off combat death
- Lose → retry restores the snapshot
- Talking succeeds and fails with a fixed seed
- Fleeing, including always failing against aliens
- Aliens take 0 damage
- Both cheat paths end with `cheat`
- A code only works in encounters that list it
- The Beamter skill does nothing (but logs a line)

## Done when
The DoD from AGENTS.md passes. All 3 encounters can be played with all 5 jobs in the test scene, in both languages. Every job can win `raiders_street`. The player and both raider types have finished sprites.
