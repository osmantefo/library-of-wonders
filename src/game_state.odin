package main

import rl "vendor:raylib"

Screen :: enum {
    TITLE,
    LOBBY,
    LEVEL,
}

Game_State :: struct {
    screen:       Screen,
    should_quit:  bool,
    title_choice: int,
    player:       Player,
    lobby_return_position: rl.Vector2,
    world:        World,
    current_room: int,
    active_level: int,
    camera:       rl.Camera2D,
    message:      string,
    message_time: f32,
}

new_game :: proc() -> Game_State {
    world := create_world()
    player := Player{position = {180, 220}, radius = PLAYER_RADIUS, speed = PLAYER_SPEED}
    camera := rl.Camera2D{target = player.position, offset = {WINDOW_WIDTH / 2.0, WINDOW_HEIGHT / 2.0}, rotation = 0, zoom = 1.0}
    return Game_State{
        screen = .TITLE,
        should_quit = false,
        title_choice = 0,
        player = player,
        lobby_return_position = player.position,
        world = world,
        current_room = 0,
        active_level = -1,
        camera = camera,
        message = "Welcome, Keeper of the Archive.",
        message_time = 3.0,
    }
}

set_message :: proc(game: ^Game_State, message: string, duration: f32 = 2.0) {
    game.message = message
    game.message_time = duration
}

update_game :: proc(game: ^Game_State, dt: f32) {
    if game.message_time > 0 {
        game.message_time -= dt
    }

    switch game.screen {
    case .TITLE:
        update_title_screen(game)
    case .LOBBY:
        update_lobby(game, dt)
    case .LEVEL:
        update_level(game, dt)
    }
}

render_game :: proc(game: ^Game_State) {
    switch game.screen {
    case .TITLE:
        render_title_screen(game)
    case .LOBBY:
        render_lobby(game)
    case .LEVEL:
        render_level(game)
    }
}