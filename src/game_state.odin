package main

import rl "vendor:raylib"

Screen :: enum {
    TITLE,
    LOBBY,
    LEVEL,
    PAUSED,
    LEVEL_RESULTS,
}

Game_State :: struct {
    screen:       Screen,
    should_quit:  bool,
    title_choice: int,
    title_confirming_new_game: bool,
    title_confirm_choice: int,
    pause_choice: int,
    results_choice: int,
    player:       Player,
	librarian:    Librarian,
    assets:       Game_Assets,
    creature_catalog: [CREATURE_COUNT]Creature_Config,
    level_run:    Level_Run,
    progression:  Progression,
    lobby_return_position: rl.Vector2,
    floor_index: int,
    lobby_return_floor: int,
    world:        World,
    current_room: int,
    active_level: int,
    camera:       rl.Camera2D,
    message:      string,
    message_time: f32,
}

new_game :: proc(assets: Game_Assets, player_config: Player_Config, creature_catalog: [CREATURE_COUNT]Creature_Config) -> Game_State {
    world := create_world()
    progression := load_progression()
    for i in 0..<min_int(len(world.books), BOOK_COUNT) {
        world.books[i].completed = progression.books[i].cleared
    }
    lobby_spawn := rl.Vector2{WINDOW_WIDTH / 2.0, world.rooms[0].floor_y[0] - player_config.radius}
    player := Player{
        position = lobby_spawn,
        radius = player_config.radius,
        speed = player_config.move_speed,
        config = player_config,
		health = player_config.max_health,
		max_health = player_config.max_health,
		last_hit_enemy = -1,
    }
    camera := rl.Camera2D{target = {WINDOW_WIDTH / 2.0, WINDOW_HEIGHT / 2.0}, offset = {WINDOW_WIDTH / 2.0, WINDOW_HEIGHT / 2.0}, rotation = 0, zoom = 1.0}
    return Game_State{
        screen = .TITLE,
        should_quit = false,
        title_choice = 0,
        player = player,
		librarian = new_librarian(world.rooms[0].floor_y[0]),
        assets = assets,
        creature_catalog = creature_catalog,
        progression = progression,
        lobby_return_position = player.position,
        floor_index = 0,
        lobby_return_floor = 0,
        world = world,
        current_room = 0,
        active_level = -1,
        camera = camera,
        message = "Welcome, Keeper of the Archive.",
        message_time = 3.0,
    }
}

enter_library :: proc(game: ^Game_State) {
    game.current_room = 0
    game.floor_index = 0
    game.player.position = {WINDOW_WIDTH / 2.0, game.world.rooms[0].floor_y[0] - game.player.radius}
    game.camera.target = {WINDOW_WIDTH / 2.0, WINDOW_HEIGHT / 2.0}
    game.player.velocity_y = 0
    game.player.grounded = true
    game.player.is_attacking = false
    game.player.is_crouching = false
    game.player.action = .NONE
    game.player.is_hurt = false
    game.player.health = game.player.max_health
	game.player.health_feedback = .NONE
	game.player.health_feedback_time = 0
    game.player.last_hit_enemy = -1
    game.player.last_hit_damage = 0
    game.player.invulnerability_time = 0
    game.screen = .LOBBY
    set_message(game, "Welcome to the Grand Lobby.")
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
    case .PAUSED:
        update_pause_menu(game)
    case .LEVEL_RESULTS:
        update_level_results(game)
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
    case .PAUSED:
        render_level(game)
        render_pause_menu(game)
    case .LEVEL_RESULTS:
        render_level(game)
        render_level_results(game)
    }
}
