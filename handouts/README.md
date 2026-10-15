# Handouts: who builds what

**Goal:** a playable alpha (Area 1, 20–30 minutes, pixel art, German + English) that shows every pillar of the game once, so you two can test the vision and decide what to keep. Scope: [docs/ALPHA_SCOPE.md](../docs/ALPHA_SCOPE.md). Your answers from docs/VISION.md are already built in (see the table at the top of ALPHA_SCOPE).

## The split
| Phase | Claude (lead, integrator, character art) | Codex (world, presentation, environment art) |
|---|---|---|
| 0 | **H0 Foundation:** Godot project, shared APIs, data files, DE/EN setup, dialogue addon, pixel pipeline + art guide, test runner | waits |
| 1 | **H1 Combat:** turn-based combat, downed/death, cheat codes, jobs, party. Draws the player and the raiders. | **H2 World + UI:** platformer controller, interactable objects, pixel UI kit, menus, language selection, HUD, test tileset |
| 2 | **H3 Dialogue + story:** dialogue UI, DE/EN translation workflow, writing guide for you, `[TEMP]` story, hidden moral options, cult teaser. Draws the companions, NPCs and portraits. | **H4 Area 1:** levels and their pixel art, alien glitch FX, swarm, hidden cult route, audio manager + audio guide, save/load |
| 3 | **H5 Integration:** the full alpha playthrough works end to end, in both languages | **H6 QA + build:** review, smoke tests, pixel check, Windows `.exe` for playtesters |

**Why this split:** Claude gets the systems where rules, story and consequences meet (combat, dialogue, choices, integration) and the characters that live in them. Codex gets the self-contained, visual systems (movement, levels, menus, FX, saving, builds) and the places they show. The two parts connect only through the contracts in AGENTS.md and the shared art guide, so both agents can work at the same time without overwriting each other.

**What stays with you two:** story, characters, dialogue, jokes, names, English translation of your own text, audio, and the final say on the art. The agents write `[TEMP]` placeholders in both languages, plus guides that show you how to replace them (H3: writing guide, H4: audio guide, H0: `data/README.md`).

## Before H0 (your part)
1. Godot 4.7 is already on this PC (the "Random Thing" project and Downloads), and AGENTS.md points to it. Nothing to install.
2. Before H6: in the Godot editor, go to *Editor → Manage Export Templates → Download*.

## How to start a handout
Paste this to the agent, changing the file name:
> Read AGENTS.md and handouts/H1_claude_combat.md, then do the task.

Each handout names its branch. H0 works directly on `main`.

## Running both agents in parallel (once, after H0)
Two agents must never work in the same folder. When H0 is done, run this in PowerShell:
```powershell
cd "C:\Users\marco\Desktop\Unser Game"
git worktree add "..\Unser Game - codex" -b codex/h2-world-ui
```
- Claude works in `Unser Game`.
- Codex works in `Unser Game - codex` (open Codex in that folder).
- For Codex's next handout, inside its folder, after the merge: `git switch -c codex/h4-area1-fx-audio-save main`

## Between phases: merge
When both agents of a phase are done, paste this to Claude:
> Merge claude/<branch> and codex/<branch> into main. Resolve conflicts, run the tests and the smoke test, and summarize both handoff notes for me.

Then read the "Questions for the humans" sections. That's where your story decisions are needed.

## Order
```
H0 (Claude) ──merge──► H1 (Claude) ∥ H2 (Codex) ──merge──► H3 (Claude) ∥ H4 (Codex) ──merge──► H5 (Claude) ∥ H6 part A (Codex)
                                                                                                 ──merge──► H6 part B (Codex) ──► you two playtest
```

## Passing messages between agents
- If an agent reports a **CONTRACT CHANGE** or a request to the other agent, include it in your next prompt to that agent.
- Your story decisions go into `docs/VISION.md` or `docs/story/` (your files). Then tell the agent: "Re-read docs/VISION.md, I answered questions X and Y."
- After the playtest, the next round of handouts comes from your feedback in `docs/PLAYTEST.md`.
