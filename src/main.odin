package main

import rl "vendor:raylib"

main :: proc() {
    rl.SetConfigFlags({.FULLSCREEN_MODE})
    rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "The Grand Archive")
    rl.SetExitKey(.KEY_NULL)
    rl.SetTargetFPS(TARGET_FPS)
    defer rl.CloseWindow()

    rl.InitAudioDevice()
    defer rl.CloseAudioDevice()

    player_config := load_player_config()
    creature_catalog := load_creature_catalog()
    assets := load_game_assets(player_config, creature_catalog)
    defer unload_game_assets(assets)
    game := new_game(assets, player_config, creature_catalog)

    for !rl.WindowShouldClose() && !game.should_quit {
        dt := rl.GetFrameTime()
        update_game(&game, dt)
        update_game_audio(game.assets)

        rl.BeginDrawing()
        rl.ClearBackground(COLOR_BACKGROUND)
        rl.BeginTextureMode(game.assets.render_target)
        rl.ClearBackground(COLOR_BACKGROUND)
        render_game(&game)
        rl.EndTextureMode()
        screen_width := f32(rl.GetScreenWidth())
        screen_height := f32(rl.GetScreenHeight())
        scale_x := screen_width / WINDOW_WIDTH
        scale_y := screen_height / WINDOW_HEIGHT
        scale := scale_x
        if scale_y < scale_x {
            scale = scale_y
        }
        draw_width := WINDOW_WIDTH * scale
        draw_height := WINDOW_HEIGHT * scale
        rl.DrawTexturePro(
            game.assets.render_target.texture,
            rl.Rectangle{0, 0, f32(WINDOW_WIDTH), -f32(WINDOW_HEIGHT)},
            rl.Rectangle{(screen_width - draw_width) / 2, (screen_height - draw_height) / 2, draw_width, draw_height},
            rl.Vector2{0, 0},
            0,
            rl.WHITE,
        )
        rl.EndDrawing()
        free_all(context.temp_allocator)
    }
}
