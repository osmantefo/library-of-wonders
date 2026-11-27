# Game assets

`assets.odin` loads and unloads the resources used by the game:

- `texture/menu_screen.png` — title-screen background
- `texture/player/player/Sprites/Idle.png` and `Run.png` — player animations
- `texture/player/player/Sprites/` — jump, fall, attack, hit, and death animations
- `texture/Cold Corridors Files/` — layered corridor and torch animation for the first book level
- `texture/Monster_Creatures_Fantasy(Version 1.3)/` — creature attack and projectile sheets
- `fonts/monogram/` — regular and italic UI fonts
- `audio/top-down-fantasy-1.ogg` — looping background music

Keep resource loading and cleanup in `assets.odin`; do not load assets in per-frame update or draw functions.
