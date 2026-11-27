# Game data

- `player.json` — editable player movement, sprite-sheet dimensions, animation timing, rendering, health, and siphon settings. It is loaded and validated by `player_config.odin`.
- `enemies/` — editable definitions for each creature's animation sheets, hit count, damage, projectile speed, patrol, aggro, and collision dimensions.

Room layouts, levels, and progression are still defined in `world.odin` and `level.odin`.
