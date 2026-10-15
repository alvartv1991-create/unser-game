# H2 follow-up — Current visual reference — Codex

## Done
- Recorded the human's new art direction from the two images attached in chat: "this art style is the current vision".
- The human explicitly confirmed: **keep side-view platforming and adopt the references' art style** ("Side-View behalten, diesen Grafikstil übernehmen").
- The human clarified that the images are examples of art style only and **the aliens are not active at the beginning**. Do not copy the images' attacks, rifts, infestation or corrupted screens into the opening.
- The images are visual references. They are not imported game assets, a new story script, or evidence of implemented gameplay.
- This note describes the references; the original attachments remain in the conversation, not in the repository.

### Visual direction to carry forward
- Detailed, atmospheric pixel art with readable characters and objects. The H2 test kit is a functional prototype; its sparse buildings and flat surfaces do not represent the desired final detail level.
- An 80s built environment: arcade storefronts/cabinets, CRTs, payphones, cassettes, old cars, utility poles, diners and shopping-mall interiors.
- Deep navy and near-black ambient shadows, warm amber occupied interiors, and strong localized neon accents. Wet pavement and tiled floors reflect light in broken pixel clusters.
- Layered depth: foreground silhouettes and foliage, a clear playable plane, and distant architecture/trees with reduced contrast. Use atmospheric separation so detail does not hide traversal or interaction targets.
- Strange interference intrudes into familiar spaces. In the references it appears as concentrated magenta/red light, corrupted screens and dark branching forms. These are visual cues, not approved alien biology or new lore.
- Compact dark HUD panels with thin light borders, expressive pixel portraits, clear health indicators, recognizable item icons and a short objective. Adapt the hierarchy to our party size and localized text.
- Preserve the project's own characters, tone and story. Reference-image names, dates, objectives, bicycles, inventory systems, minimaps and two-player layouts are not new requirements.

## How to try it
- Compare the two chat references with the existing H2 test level and menus.
- The useful next visual checkpoint is one playable scene segment with the new lighting, material detail and HUD treatment. Establish that sample before redrawing all levels.
- Check the sample at the actual 640x360 viewport and at 2x display scale; the supplied references contain substantially finer detail than the current game canvas. Validate what remains readable before proposing resolution or sprite-size changes.

## Contract changes (the other agent must know)
- No code/API, resolution, sprite-size or camera contract changed in this documentation update.
- **Perspective confirmed:** keep the existing side-view platformer. Translate the references' lighting, materials, detail, atmosphere and HUD hierarchy into a side-on composition. Their elevated oblique camera is not the target.
- **Art-guide reconciliation needed:** the references include ordinary cyan/magenta shop neon. The old "cyan/magenta always means alien" rule does not reproduce that look. Revise that convention with the new human direction in mind; distinguish interference with shape, animation, distortion and context, rather than hue alone.

## Requests to the other agent
- Claude: read this note alongside the human's two image attachments. Update your owned `docs/ART_GUIDE.md` to reflect the accepted visual direction and explicitly resolve the neon-color rule.
- Claude: align character sprites and portraits with the reference's readable silhouettes and expressive faces, retaining existing resource ids until a size change is agreed.
- Codex's first environment/UI art pass establishes an ordinary playable streetscape: layered background, warm interior, steady shop neon, pixel reflections, environmental props and compact HUD. Alien interference belongs in a later story-approved section.
- Coordinate palette/light implementation before extending the strict palette lint: the reference look needs a planned treatment of emissive lights and reflections. Do not silently enlarge the palette, change renderer or abandon pixel-grid consistency.
- Keep platform edges, collision boundaries and traversal routes readable in side view. Use parallax and decorative background depth to express the references' spatial richness.

## New content ids
- None.

## Questions for the humans (story/design)
- Perspective question resolved by the human: side view remains. No further perspective decision is needed for the next art pass.

## Known issues / not done
- This commit records art direction only; the game still uses H2's prototype visuals.
- `docs/VISION.md` remains human-owned. `docs/ART_GUIDE.md` remains Claude-owned; changes are requested here through the established handoff workflow.
- No code or assets changed, so gameplay tests were not rerun for this note.
