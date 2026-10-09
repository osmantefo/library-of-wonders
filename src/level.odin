package main

import "core:strings"
import rl "vendor:raylib"

Book_Entrance :: struct {
    id:        int,
    title:     string,
    subtitle:  string,
    position:  rl.Vector2,
    level_id:  int,
    unlocked:  bool,
    completed: bool,
}

Level_Data :: struct {
    name:        string,
    description: string,
    spawn:       rl.Vector2,
    bounds:      rl.Rectangle,
}

LEVELS := []Level_Data{
    {name = "The Clockwork Orchard", description = "Explore a garden of brass trees and broken timepieces.", spawn = {100, 450}, bounds = {0, 0, 1800, 600}},
    {name = "The Drowned Kingdom", description = "Find the lost route through a sunken royal library.", spawn = {100, 450}, bounds = {0, 0, 1800, 600}},
    {name = "Atlas of the Starless Sky", description = "A sealed record of constellations that no longer exist.", spawn = {100, 450}, bounds = {0, 0, 1800, 600}},
}

update_level :: proc(game: ^Game_State, dt: f32) {
    if rl.IsKeyPressed(.ESCAPE) {
        game.screen = .LOBBY
        game.player.position = game.lobby_return_position
        game.camera.target = game.lobby_return_position
        set_message(game, "You return to the library.")
        return
    }

    update_player(&game.player, dt)
    level := LEVELS[game.active_level]
    game.player.position.x = clamp_f32(game.player.position.x, level.bounds.x + 16, level.bounds.x + level.bounds.width - 16)
    game.player.position.y = level.spawn.y
}

render_level :: proc(game: ^Game_State) {
    level := LEVELS[game.active_level]
    rl.ClearBackground(rl.Color{19, 31, 42, 255})
    rl.DrawText(strings.clone_to_cstring(level.name, context.temp_allocator), 32, 28, 28, COLOR_GOLD)
    rl.DrawText(strings.clone_to_cstring("LEVEL PLACEHOLDER - ESC returns to the lobby", context.temp_allocator), 32, 66, 18, COLOR_MUTED)
    rl.DrawRectangle(0, i32(WINDOW_HEIGHT - 110), WINDOW_WIDTH, 110, rl.Color{52, 66, 75, 255})
    rl.DrawRectangle(0, i32(WINDOW_HEIGHT - 110), WINDOW_WIDTH, 6, COLOR_ACCENT)
    rl.DrawCircleV({game.player.position.x, WINDOW_HEIGHT - 135}, game.player.radius, COLOR_ACCENT)
    rl.DrawText(strings.clone_to_cstring(level.description, context.temp_allocator), 32, i32(WINDOW_HEIGHT - 50), 18, COLOR_TEXT)
}