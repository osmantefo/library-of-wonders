# The Grand Archive — Odin + Raylib starter

A modular starter for a magical-library game. It currently has a title screen, an 8-room side-view library hub, a central director's lobby, seven connected subject halls, walkable stair transitions between floors, and book-shaped level entrances.

## Requirements

- Odin compiler installed and available on your PATH
- Odin's `vendor:raylib` package available in your Odin installation

## Run

Open a terminal in this directory and run:

```sh
odin run .
```

The game opens fullscreen.

## Controls

- **Title screen:** W/S or Up/Down, then Enter/Space. Choose **New Game** to clear saved book and relic progress; **Enter the Library** preserves it.
- **Library:** A/D or Left/Right to move; reach a doorway at either end of the ground floor to enter the next room
- **Stairs:** W/Up at the bottom of a staircase to climb; S/Down at the top to descend
- **Books and director:** E near a hall book to enter its story, or near the lobby director to interact. The second book in each hall is on the middle floor; the top floor is the restricted stacks.
- **Library:** Esc returns to the main menu
- **First book level:** A/D or Left/Right to move, Space/W/Up to jump, J/X to attack, and reach the corridor arch to complete the level. Jump buffering, coyote time, and variable jump height make platforming more forgiving. Reach the glowing checkpoints to set your respawn point. Esc opens pause; choose Resume, Restart from Checkpoint, or Return to Library. Clearing the book shows time, damage, and relic results, with an option to replay.
- **Other level placeholders:** Esc opens the pause menu; choose Return to Library to leave
- **Window:** Close with the window's close button or select Quit from the title screen; Esc is reserved for in-game navigation

## Project structure

- `main.odin` — window/audio setup and main loop
- `assets.odin` — loading, playback, and unloading of textures and music
- `creature_data.odin` — loading and validating editable enemy definitions
- `enemy.odin` — enemy behavior, projectiles, collision, and sprite animation
- `enemy_ai.odin` — per-creature patrol, aggro, orbit, and attack decisions
- `player_health.odin` — damage, hit attribution, health UI, and kill-based health siphon
- `platformer.odin` — level movement, jumping, attacks, and hit response
- `platformer_physics.odin` — one-way platform collision and platform rendering
- `level_flow.odin` — checkpoints, pause/restart, death respawns, and completion results
- `lobby_decor.odin` — floor-specific library dressing and book information panels
- `progression.odin` — save/load for cleared books and collected relics
- `GAME_ROADMAP.md` — proposed gameplay improvements and content plan for the books and library floors
- `ui.odin` — shared rendering and measurement for the downloaded UI font
- `player_config.odin` — loading and validating editable player settings
- `rules.odin` — constants and shared theme colors
- `game_state.odin` — global game state and screen dispatch
- `title_screen.odin` — title screen input and drawing
- `lobby.odin` — hall navigation, stair transitions, book/director interactions, and room rendering
- `world.odin` — the main lobby, seven subject halls, room connections, and book placement
- `player.odin` — side-view lobby movement and Idle/Run sprite animation
- `physics.odin` — room bounds and floor positioning
- `level.odin` — corridor rendering, camera, relic pickup, and level completion
- `data/player.json` — movement, jump assistance, sprite-sheet, animation, render, health, and recovery settings for the player
- `data/enemies/` — per-creature sprite paths, animation dimensions, AI, damage, movement, collision, and hit counts
- `save/progression.json` — created on level completion; stores book clears and discovered relics
- `assets/fonts/` — Monogram regular and italic UI fonts
- `assets/texture/` — title-screen background and player sprite sheets
- `assets/audio/` — looping background music

All `.odin` files currently use `package main`, which means they compile together as one package. The file boundaries organize responsibilities without forcing you to manage a large set of package imports yet.

## Important starter limitations

- The player uses the supplied Idle, Run, Jump, Fall, Attack, Hit, and Death sprite sheets. Books and library environments remain placeholders.
- The first book has a looping corridor backdrop, simple enemy combat, and an exit arch; other books remain level placeholders.
- Enemy packs only include attack and projectile sheets, so idle, hit, and death states use the supplied attack frames with hit flashes and a fading death effect. Enemies only aggro or pursue the player while visible to the camera; goblin and skeleton patrols can continue off-screen.
- Each enemy has distinct damage and behavior tuning in its JSON file. Killing the most recent enemy to damage the player restores a portion of the damage it caused.
- The library hub uses walkable stair transitions; the first book has its own gravity, jump, ground, and combat system.
- The first library floor has procedural bookshelves and a clear story prompt; the middle floor now hosts the second book in each hall, while the top floor is presented as the restricted stacks.
- Book 1 has pause/restart controls, two checkpoints, checkpoint respawns, and a clear summary. Pause and results screens freeze level simulation.
- The first level has elevated one-way platforms and a missable relic. Clearing the level is independent of collecting it.
- The lobby reveals the relic's found status and total only after the first book has been cleared. Progression is saved to `save/progression.json`.
- All eight library rooms are currently accessible for testing. Progression locks and requirements will be added later.
- Room layout and the circular hall connections are defined in `world.odin`.

## Suggested next steps

1. Replace the placeholder hall layout with background art and refine the director and interactables.
2. Add level completion events that unlock the next books.
3. Extend the progression save with relics, cards, skills, and floor unlocks.
4. Move room and level definitions into data files after the structures stabilize.

## Suggested future files

- `interactions.odin` — reusable interaction targeting and prompts
- `collectibles.odin` — pickups, hidden items, traps, and fake items
- `puzzles.odin` — puzzle state and puzzle-specific rules
- `save_system.odin` — save/load player progress
- `data/rooms.json` and `data/levels.json` — external content definitions (optional later)
