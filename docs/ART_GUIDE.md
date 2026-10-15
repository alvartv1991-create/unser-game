# Art guide

The art contract for everyone who draws: Claude (characters, portraits), Codex (tiles, props, backgrounds, UI, FX) and the humans. Owner: Claude. Change it only together with the humans.

## The look
- **An 80s suburb after the end of the world.** Dusty, faded, muted: concrete, rust, olive, denim, nicotine yellow. Nothing modern (no smartphones, no flat screens).
- **The aliens are the only bright thing.** Cyan and magenta "signal" colors belong only to alien tech, glitches, and devices that are reacting to the aliens at that moment. Players should learn: *if it glows cyan/magenta, it's them.*
- **Readability beats detail.** At 640×360, a clear silhouette and one strong accent color per character matter more than shading.

![palette](art/palette.png)

## Resolution and sizes
| What | Size | Notes |
|---|---|---|
| Game screen | 640×360 | Scaled by whole numbers only: 2× at 1280×720, 3× at 1920×1080 |
| Tiles | 16×16 | |
| Character frames | 32×32 | Body about 12–16 px wide and 24–30 px tall. Feet on the **bottom row**, body centered on x = 16. |
| Portraits | 64×64 | Head and shoulders, facing right |
| Props | multiples of 16 where possible | |

Never scale pixel art by non-whole factors, and never rotate it (FX excepted).

## Palette
32 colors. The letter is what you type in `.pxl` sprites. Source of truth: `tools/pixelart/palette.json`. For drawing programs: `docs/art/unser_game.gpl`.

| Letter | Hex | Name | Typical use |
|---|---|---|---|
| `0` | #14101a | outline | Outlines, deepest shadows |
| `1` | #2b2532 | charcoal | Dark clothes, night shadows |
| `2` | #4a4552 | slate | Jeans, asphalt |
| `3` | #77727a | concrete | Concrete, metal |
| `4` | #a8a3a6 | ash | Light metal, grey hair |
| `5` | #e3dccb | bone | Sneakers, paper, highlights |
| `6` | #3b2a24 | dark brown | Dark hair, dark skin shadow |
| `7` | #63452f | brown | Hair, wood, leather |
| `8` | #9a6e47 | tan | Cardboard, dark skin |
| `9` | #c9a26b | sand | Dust, dark skin highlight |
| `a` | #5a2a22 | dark rust | Rust shadows, dried blood |
| `b` | #8e3b2b | rust | Rust, bricks |
| `c` | #c2622f | burnt orange | 80s orange, fire |
| `d` | #e0a94a | dusty yellow | Lamps, signs, blond hair |
| `e` | #2f3a26 | dark olive | Military, dead plants (shadow) |
| `f` | #4f5e33 | olive | Military, dead plants |
| `g` | #7b8a48 | moss | Plants |
| `h` | #b4bb7c | pale green | Plant highlights, old CRT phosphor |
| `i` | #1c2238 | night | Night sky, denim shadow |
| `j` | #344a6b | denim | Denim, car paint |
| `k` | #5d7a99 | faded blue | Denim highlight, sky |
| `l` | #9db4c4 | pale sky | Day sky, glass |
| `m` | #6b4434 | skin shadow | |
| `n` | #a8705a | skin | |
| `o` | #d8a58a | skin light | |
| `p` | #3d2440 | plum | Night shadows, 80s purple |
| `q` | #b04a5a | 80s red | Accent: clothes, signs |
| `r` | #d68a8a | washed pink | Accent: 80s pastel |
| `s` | #127a8a | **SIGNAL** cyan dark | **Alien only** |
| `t` | #3ff0f0 | **SIGNAL** cyan | **Alien only** |
| `u` | #8a1a7a | **SIGNAL** magenta dark | **Alien only** |
| `v` | #ff4fd8 | **SIGNAL** magenta | **Alien only** |

**Suggested ramps (light → dark):** skin `o n m 6`, darker skin `9 8 7 6`, denim `l k j i`, concrete `5 4 3 2 1`, rust `c b a`, plants `h g f e`, alien `t s` / `v u`.

## Rules
1. **Outline:** 1 px of `0` around characters and interactive props. Tiles and backgrounds have no black outline; use the darker color of the same ramp.
2. **Light comes from the top left.** Shade with the next darker color of the same ramp, at most about 4 shades per material.
3. **One accent color per character**, e.g. the protagonist's red shirt (`q`).
4. **Signal colors (`s t u v`)** are only for the swarm, alien structures, glitch effects, devices that are reacting right now, and (as a hint) cult symbols. Never use them for normal clothes or props.
5. **Backgrounds stay darker and lower in contrast** (`1 2 3 i p e`), so characters and interactive things stand out.
6. **Characters face right.** The engine flips them.
7. Interactive objects get a slightly brighter edge or highlight than pure decoration.

## Animations
Contract names from AGENTS.md § Art. Missing animations fall back to `idle`.

| Animation | Frames | fps | Loop |
|---|---|---|---|
| `idle` | 2–4 | 4 | yes |
| `walk` | 4–6 | 8 | yes |
| `jump`, `fall` | 1–2 | 8 | no |
| `combat_idle` | 2 | 4 | yes |
| `attack`, `skill` | 3–4 | 10 | no |
| `hurt` | 1–2 | 8 | no |
| `downed` | 1–2 | 2 | yes |

## Files and naming
`snake_case` everywhere. Sources go in a `src/` folder; the tool writes the results one folder up.

| What | Source | Result | Who |
|---|---|---|---|
| Characters | `assets/sprites/characters/src/<id>.pxl` | `<id>.png` + `<id>.tres` | Claude |
| Portraits | `assets/portraits/src/<speaker_id>.pxl` (`@image`, 64×64) | `<speaker_id>.png` | Claude |
| Tiles | `assets/tiles/src/<set>.pxl` (`@tiles`) | `<set>.png` | Codex |
| Props, backgrounds, UI, FX | `assets/<kind>/src/…` | `assets/<kind>/…` | Codex |

## How to make art
- **As text (the agents' way):** `.pxl` files, one letter per pixel. See `tools/pixelart/README.md`.
- **In a drawing program (the humans' way):** load `docs/art/unser_game.gpl` as the palette in Aseprite, LibreSprite or GIMP. Export animations as horizontal strips and reference them with `png=` in a `.pxl` file, or save finished PNGs directly.
- **Check:** the tool's `--lint` mode lists every PNG that uses colors outside the palette.
