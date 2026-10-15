# Credits and licenses

All art is drawn for this project (see docs/ART_GUIDE.md) unless listed here.

## Third-party
| What | Where | License |
|---|---|---|
| Dialogue Manager 4.1.0 by Nathan Hoad (addon, code) | `addons/dialogue_manager/` | MIT, see `addons/dialogue_manager/LICENSE` |
| Pixelify Sans by Stefie Justprince | `assets/fonts/pixelify_sans.ttf`; https://github.com/google/fonts/tree/main/ofl/pixelifysans | SIL Open Font License 1.1, `assets/fonts/OFL.txt` |

## H2 environment and UI
Original palette-based pixel drawings by Codex: `assets/tiles/test_tiles.png`,
`assets/props/*.png`, `assets/ui/*.png`, `assets/backgrounds/title.png`.
Reproducible drawing source: `tools/build_h2_art.gd`. No third-party visual assets.

## Side-view visual street sample
Original 1280x360 pixel layers: `assets/backgrounds/street_{sky,distance,world,foreground}.png`.
Drawing source: `tools/build_visual_street.gd`, seeded with `198401`, using the shared palette.
Runtime rain, small puddle ripples and steady light pools are implemented in
`scripts/world/visual_street.gd`. The human's chat images are style references;
neither reference image is embedded or shipped as a game asset.

Add every font, sound or other outside asset to this table, with its source link and license.
