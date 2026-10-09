package main

import rl "vendor:raylib"

main :: proc() {
    rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "The Grand Archive")
    rl.SetExitKey(.KEY_NULL)
    rl.SetTargetFPS(TARGET_FPS)

    game := new_game()
    defer rl.CloseWindow()

    for !rl.WindowShouldClose() && !game.should_quit {
        dt := rl.GetFrameTime()
        update_game(&game, dt)

        rl.BeginDrawing()
        rl.ClearBackground(COLOR_BACKGROUND)
        render_game(&game)
        rl.EndDrawing()
        free_all(context.temp_allocator)
    }
}