package main

import "core:strings"
import rl "vendor:raylib"

update_title_screen :: proc(game: ^Game_State) {
    if rl.IsKeyPressed(.UP) || rl.IsKeyPressed(.W) {
        game.title_choice = (game.title_choice + 2) % 3
    }
    if rl.IsKeyPressed(.DOWN) || rl.IsKeyPressed(.S) {
        game.title_choice = (game.title_choice + 1) % 3
    }
    if rl.IsKeyPressed(.ENTER) || rl.IsKeyPressed(.SPACE) {
        switch game.title_choice {
        case 0:
            game.screen = .LOBBY
            set_message(game, "The library awaits.")
        case 1:
            set_message(game, "Options will be added here.")
        case 2:
            game.should_quit = true
        }
    }
}

render_title_screen :: proc(game: ^Game_State) {
    rl.ClearBackground(COLOR_BACKGROUND)
    rl.DrawRectangle(38, 38, WINDOW_WIDTH - 76, WINDOW_HEIGHT - 76, rl.Color{28, 24, 49, 255})
    rl.DrawRectangleLines(48, 48, WINDOW_WIDTH - 96, WINDOW_HEIGHT - 96, COLOR_GOLD)
    for i in 0..<7 {
        x := 110 + i * 175
        y := 125 + (i % 2) * 26
        rl.DrawRectangle(i32(x), i32(y), 28, 38, COLOR_ACCENT)
        rl.DrawRectangle(i32(x + 5), i32(y + 5), 18, 28, rl.Color{55, 49, 91, 255})
    }

    title_width := rl.MeasureText(strings.clone_to_cstring(SCREEN_TITLE, context.temp_allocator), 48)
    rl.DrawText(strings.clone_to_cstring(SCREEN_TITLE, context.temp_allocator), i32((WINDOW_WIDTH - title_width) / 2), 225, 48, COLOR_GOLD)
    subtitle_width := rl.MeasureText(strings.clone_to_cstring(SCREEN_SUBTITLE, context.temp_allocator), 18)
    rl.DrawText(strings.clone_to_cstring(SCREEN_SUBTITLE, context.temp_allocator), i32((WINDOW_WIDTH - subtitle_width) / 2), 285, 18, COLOR_TEXT)

    options := [3]string{"Enter the Library", "Options (coming soon)", "Quit"}
    for i in 0..<3 {
        y := 390 + i * 48
        if i == game.title_choice {
            rl.DrawText(strings.clone_to_cstring(">", context.temp_allocator), i32(WINDOW_WIDTH / 2 - 145), i32(y), 24, COLOR_ACCENT)
            rl.DrawText(strings.clone_to_cstring(options[i], context.temp_allocator), i32(WINDOW_WIDTH / 2 - 115), i32(y), 24, COLOR_ACCENT)
        } else {
            rl.DrawText(strings.clone_to_cstring(options[i], context.temp_allocator), i32(WINDOW_WIDTH / 2 - 115), i32(y), 24, COLOR_MUTED)
        }
    }
    rl.DrawText(strings.clone_to_cstring("WASD / Arrow Keys to navigate  |  Enter to confirm", context.temp_allocator), i32(WINDOW_WIDTH / 2 - 235), 625, 18, COLOR_MUTED)
}