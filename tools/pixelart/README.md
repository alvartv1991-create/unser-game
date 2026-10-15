# Pixel-art pipeline

Turns text sprites (`.pxl`) into PNGs and Godot `SpriteFrames` (`.tres`). Every pixel is one letter from the palette in `docs/ART_GUIDE.md`. Owner: Claude. Anyone may use it.

## Commands
Run these from the project folder. `<godot>` is the path in AGENTS.md § Local setup.

```sh
# Build every .pxl under assets/ (also refreshes docs/art/palette.png and unser_game.gpl)
"<godot>" --headless --path . --script res://tools/pixelart/build.gd

# Build one file
"<godot>" --headless --path . --script res://tools/pixelart/build.gd -- --file res://assets/sprites/characters/src/player.pxl

# Check that every PNG under assets/ only uses palette colors
"<godot>" --headless --path . --script res://tools/pixelart/build.gd -- --lint

# Afterwards, so Godot picks up new or changed PNGs:
"<godot>" --headless --path . --import
```

## The `.pxl` format
```text
# Lines starting with # are comments.
@sprite player          <- @sprite (animations + .tres), @image (one picture) or @tiles (a tile sheet)
@size 32x32             <- frame size

@anim idle fps=4 loop   <- options: fps=N, loop or once, copy=<other anim>, png=<strip.png>
..........00000
.........0777770
.........0oooo0
                        <- an empty line ends a frame
..........00000
.........0777770
.........0oooo0

@anim jump copy=idle once   <- reuses idle's frames (handy for placeholders)
@anim walk fps=8 loop png=walk_strip.png   <- frames from a PNG strip next to the .pxl
```

- `.` (or a space) is transparent. Every other letter is a palette color (`0`–`9`, `a`–`v`).
- **Short rows** are padded with transparency on the right. **Short frames** get transparent rows added **on top**, so a character stands on the bottom edge. You only need to write the rows that contain the drawing.
- Rows wider than the width, or frames taller than the height, are errors (with file and line).
- `@tiles` files: every frame is one tile; `@columns N` sets the sheet width (default 8).
- `@image` files: one frame, no animations.

## Output
- `src/<name>.pxl` writes `<name>.png` (and `<name>.tres` for `@sprite`) **one folder up**. Without a `src/` folder, the output goes next to the source.
- `@sprite` sheets have one row per animation. The `.tres` also contains a `default` animation (a copy of the first one).
- An existing `.tres` keeps its uid, so scenes that use it don't break.

## Tips for drawing as text
- Copy a whole frame, then change only the rows that move. For a walk cycle, usually only the legs change.
- Keep the outline (`0`) closed, and draw facing right.
- After building, look at the PNG (or run the game) and check the silhouette at 1× zoom.
