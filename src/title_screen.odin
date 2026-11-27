package main

import "core:strings"
import rl "vendor:raylib"

update_title_screen :: proc(game: ^Game_State) {
    if game.title_confirming_new_game {
        if rl.IsKeyPressed(.ESCAPE) {
            game.title_confirming_new_game = false
            return
        }
        if rl.IsKeyPressed(.UP) || rl.IsKeyPressed(.W) || rl.IsKeyPressed(.DOWN) || rl.IsKeyPressed(.S) {
            game.title_confirm_choice = (game.title_confirm_choice + 1) % 2
        }
        if rl.IsKeyPressed(.ENTER) || rl.IsKeyPressed(.SPACE) {
            if game.title_confirm_choice == 0 {
                game.title_confirming_new_game = false
                if start_new_game(game) {
                    set_message(game, "A new journey begins.")
                } else {
                    set_message(game, "Could not save the new game. Your saved progress is unchanged.")
                }
            } else {
                game.title_confirming_new_game = false
            }
        }
        return
    }

    if rl.IsKeyPressed(.UP) || rl.IsKeyPressed(.W) {
        game.title_choice = (game.title_choice + 3) % 4
    }
    if rl.IsKeyPressed(.DOWN) || rl.IsKeyPressed(.S) {
        game.title_choice = (game.title_choice + 1) % 4
    }
    if rl.IsKeyPressed(.ENTER) || rl.IsKeyPressed(.SPACE) {
        switch game.title_choice {
        case 0:
            enter_library(game)
        case 1:
            game.title_confirming_new_game = true
            game.title_confirm_choice = 1
        case 2:
            set_message(game, "Options will be added here.")
        case 3:
            game.should_quit = true
        }
    }
}

render_title_screen :: proc(game: ^Game_State) {
    rl.ClearBackground(COLOR_BACKGROUND)
    rl.DrawTexturePro(
        game.assets.menu_background,
        rl.Rectangle{0, 0, f32(game.assets.menu_background.width), f32(game.assets.menu_background.height)},
        rl.Rectangle{0, 0, WINDOW_WIDTH, WINDOW_HEIGHT},
        rl.Vector2{0, 0},
        0,
        rl.WHITE,
    )
    rl.DrawRectangle(820, 96, 420, 530, rl.Color{12, 18, 36, 190})
    rl.DrawRectangleLines(820, 96, 420, 530, COLOR_GOLD)

    rl.DrawTextEx(game.assets.title_font, strings.clone_to_cstring(SCREEN_TITLE, context.temp_allocator), rl.Vector2{844, 164}, 32, 1, COLOR_GOLD)
    ui_text(game.assets.ui_font, strings.clone_to_cstring("A library of lives, memories,", context.temp_allocator), 846, 210, 18, COLOR_TEXT)
    ui_text(game.assets.ui_font, strings.clone_to_cstring("and impossible worlds", context.temp_allocator), 846, 234, 18, COLOR_TEXT)

    options := [4]string{"Enter the Library", "New Game", "Options (coming soon)", "Quit"}
    for i in 0..<4 {
        y := 316 + i * 52
        if i == game.title_choice {
            ui_text(game.assets.ui_font, strings.clone_to_cstring(">", context.temp_allocator), 850, i32(y), 24, COLOR_ACCENT)
            ui_text(game.assets.ui_font, strings.clone_to_cstring(options[i], context.temp_allocator), 878, i32(y), 24, COLOR_ACCENT)
        } else {
            ui_text(game.assets.ui_font, strings.clone_to_cstring(options[i], context.temp_allocator), 878, i32(y), 24, COLOR_MUTED)
        }
    }
    ui_text(game.assets.ui_font, strings.clone_to_cstring("W/S or Up/Down to navigate", context.temp_allocator), 846, 548, 16, COLOR_MUTED)
    ui_text(game.assets.ui_font, strings.clone_to_cstring("Enter to confirm", context.temp_allocator), 846, 572, 16, COLOR_MUTED)
    if game.title_confirming_new_game {
        rl.DrawRectangle(0, 0, WINDOW_WIDTH, WINDOW_HEIGHT, rl.Color{6, 8, 19, 190})
        rl.DrawRectangle(340, 230, 600, 260, rl.Color{18, 19, 39, 250})
        rl.DrawRectangleLinesEx({340, 230, 600, 260}, 3, COLOR_GOLD)
        ui_text(game.assets.ui_font, strings.clone_to_cstring("Start a New Game?", context.temp_allocator), 420, 270, 30, COLOR_GOLD)
        ui_text(game.assets.ui_font, strings.clone_to_cstring("This will erase saved book and relic progress.", context.temp_allocator), 390, 320, 20, COLOR_TEXT)
        options := [2]string{"Erase Progress", "Cancel"}
        for i in 0..<len(options) {
            color := COLOR_MUTED
            if i == game.title_confirm_choice {
                color = COLOR_ACCENT
                ui_text(game.assets.ui_font, strings.clone_to_cstring(">", context.temp_allocator), 420, i32(380+i*44), 22, color)
            }
            ui_text(game.assets.ui_font, strings.clone_to_cstring(options[i], context.temp_allocator), 452, i32(380+i*44), 22, color)
        }
        ui_text(game.assets.ui_font, strings.clone_to_cstring("Esc to cancel", context.temp_allocator), 420, 468, 16, COLOR_MUTED)
    }
}
