package main

import "core:fmt"
import "core:strings"
import rl "vendor:raylib"

STAIR_INTERACTION_DISTANCE :: 58.0

update_lobby :: proc(game: ^Game_State, dt: f32) {
    if rl.IsKeyPressed(.ESCAPE) {
        game.screen = .TITLE
        game.current_room = 0
        game.floor_index = 0
        set_message(game, "Returned to the main menu.")
        return
    }

    room := &game.world.rooms[game.current_room]
    update_player(&game.player, dt)
    resolve_room_bounds(&game.player, room^, game.floor_index)

    if change_room_at_exit(game, room^) {
        return
    }

    if change_floor_at_stairs(game, room^) {
        resolve_room_bounds(&game.player, room^, game.floor_index)
    }

    nearest := nearest_room_book(game, room^, game.floor_index)
    if nearest >= 0 && rl.IsKeyPressed(.E) {
        book := game.world.books[nearest]
        if book.unlocked {
            game.lobby_return_position = game.player.position
            game.lobby_return_floor = game.floor_index
            start_level_run(game, book.level_id)
            return
        }
        set_message(game, "This book is sealed.")
    } else if room.is_lobby && rl.IsKeyPressed(.E) && distance_squared(game.player.position, director_position(room^, game.player.radius)) < f32(INTERACTION_DISTANCE * INTERACTION_DISTANCE) {
        set_message(game, "Director: Welcome. The halls are open while the archive is being prepared.")
    }
}

change_room_at_exit :: proc(game: ^Game_State, room: Room) -> bool {
    if game.floor_index != 0 {
        return false
    }

    if game.player.position.x <= game.player.radius && (rl.IsKeyDown(.A) || rl.IsKeyDown(.LEFT)) {
        target := room.left_room
        game.current_room = target
        destination := &game.world.rooms[target]
        game.player.position = {WINDOW_WIDTH - game.player.radius - 70, destination.floor_y[0] - game.player.radius}
        set_message(game, fmt.aprintf("Entered %s", destination.name))
        return true
    }

    if game.player.position.x >= WINDOW_WIDTH - game.player.radius && (rl.IsKeyDown(.D) || rl.IsKeyDown(.RIGHT)) {
        target := room.right_room
        game.current_room = target
        destination := &game.world.rooms[target]
        game.player.position = {game.player.radius + 70, destination.floor_y[0] - game.player.radius}
        set_message(game, fmt.aprintf("Entered %s", destination.name))
        return true
    }

    return false
}

change_floor_at_stairs :: proc(game: ^Game_State, room: Room) -> bool {
    if rl.IsKeyPressed(.W) || rl.IsKeyPressed(.UP) {
        for stair_index in 0..<room.floor_count - 1 {
            stair := room.stairs[stair_index]
            if game.floor_index == stair_index && abs_f32(game.player.position.x - stair.lower_x) <= STAIR_INTERACTION_DISTANCE {
                game.floor_index += 1
                game.player.position.x = stair.upper_x
                set_message(game, fmt.aprintf("Climbed to Floor %d.", game.floor_index + 1))
                return true
            }
        }
    }

    if rl.IsKeyPressed(.S) || rl.IsKeyPressed(.DOWN) {
        for stair_index in 0..<room.floor_count - 1 {
            stair := room.stairs[stair_index]
            if game.floor_index == stair_index + 1 && abs_f32(game.player.position.x - stair.upper_x) <= STAIR_INTERACTION_DISTANCE {
                game.floor_index -= 1
                game.player.position.x = stair.lower_x
                set_message(game, fmt.aprintf("Descended to Floor %d.", game.floor_index + 1))
                return true
            }
        }
    }

    return false
}

nearest_room_book :: proc(game: ^Game_State, room: Room, floor_index: int) -> int {
    nearest := -1
    nearest_distance := f32(INTERACTION_DISTANCE * INTERACTION_DISTANCE)
    for book_index in 0..<room.book_count {
        book_id := room.book_ids[book_index]
        book := game.world.books[book_id]
        if book.floor_index != floor_index {
            continue
        }

        distance := distance_squared(game.player.position, book.position)
        if distance < nearest_distance {
            nearest = book_id
            nearest_distance = distance
        }
    }
    return nearest
}

director_position :: proc(room: Room, player_radius: f32) -> rl.Vector2 {
    return {WINDOW_WIDTH / 2.0, room.floor_y[0] - player_radius}
}

abs_f32 :: proc(value: f32) -> f32 {
    if value < 0 {
        return -value
    }
    return value
}

render_lobby :: proc(game: ^Game_State) {
    room := game.world.rooms[game.current_room]
    rl.ClearBackground(COLOR_BACKGROUND)
    rl.BeginMode2D(game.camera)

    rl.DrawRectangle(0, 0, WINDOW_WIDTH, WINDOW_HEIGHT, room.color)
    rl.DrawRectangle(0, 64, WINDOW_WIDTH, 4, rl.Color{12, 11, 27, 180})
    rl.DrawRectangle(0, WINDOW_HEIGHT - 64, WINDOW_WIDTH, 4, rl.Color{12, 11, 27, 180})
    render_lobby_floor_decor(game.floor_index, room.floor_y[game.floor_index])

    for floor_index in 0..<room.floor_count {
        floor_y := room.floor_y[floor_index]
        rl.DrawRectangle(0, i32(floor_y), WINDOW_WIDTH, 16, COLOR_WALL)
        rl.DrawRectangle(0, i32(floor_y), WINDOW_WIDTH, 4, rl.Color{94, 82, 126, 255})
        rl.DrawLine(0, i32(floor_y + 16), WINDOW_WIDTH, i32(floor_y + 16), rl.Color{12, 11, 27, 255})
    }

    for stair_index in 0..<room.floor_count - 1 {
        render_staircase(room, stair_index)
    }
    render_room_exits(room.floor_y[0], game.assets.ui_font)

    if room.is_lobby {
        render_director(director_position(room, game.player.radius))
    }
    for book_index in 0..<room.book_count {
        book_id := room.book_ids[book_index]
        book := game.world.books[book_id]
        if book.floor_index == game.floor_index {
            render_book(game, book)
        }
    }
    render_player(game.player, game.assets)
    rl.EndMode2D()

    room_name := strings.clone_to_cstring(room.name, context.temp_allocator)
    room_width := ui_text_width(game.assets.ui_font, room_name, 20)
    rl.DrawRectangle(0, 0, WINDOW_WIDTH, 64, rl.Color{12, 11, 27, 235})
    ui_text(game.assets.ui_font, strings.clone_to_cstring("THE GRAND ARCHIVE", context.temp_allocator), 22, 14, 24, COLOR_GOLD)
    ui_text(game.assets.ui_font, room_name, i32(f32(WINDOW_WIDTH) - room_width - 24), 18, 20, COLOR_TEXT)

    if room.is_lobby {
        ui_text(game.assets.ui_font, strings.clone_to_cstring("MAIN LOBBY  |  8 / 8", context.temp_allocator), 22, 77, 18, COLOR_ACCENT)
    } else {
        ui_text(game.assets.ui_font, strings.clone_to_cstring(fmt.aprintf("HALL %d / %d  |  FLOOR %d / %d", game.current_room, HALL_COUNT, game.floor_index + 1, room.floor_count), context.temp_allocator), 22, 77, 18, COLOR_ACCENT)
    }
    floor_titles := [3]string{"WELCOME ARCHIVE", "RESEARCH GALLERIES", "RESTRICTED STACKS"}
    ui_text(game.assets.ui_font, strings.clone_to_cstring(fmt.aprintf("FLOOR %d  |  %s", game.floor_index+1, floor_titles[game.floor_index]), context.temp_allocator), 22, 102, 16, COLOR_GOLD)

    rl.DrawRectangle(0, WINDOW_HEIGHT - 48, WINDOW_WIDTH, 48, rl.Color{12, 11, 27, 235})
    ui_text(game.assets.ui_font, strings.clone_to_cstring("Move: A/D or Arrows    Stairs: W/S or Up/Down    Book / Director: E    Main Menu: Esc", context.temp_allocator), 22, i32(WINDOW_HEIGHT - 33), 16, COLOR_MUTED)

    if game.message_time > 0 {
        width := ui_text_width(game.assets.ui_font, strings.clone_to_cstring(game.message, context.temp_allocator), 20)
        rl.DrawRectangle(i32(WINDOW_WIDTH / 2 - width / 2 - 18), 108, i32(width + 36), 38, rl.Color{12, 11, 27, 230})
        ui_text(game.assets.ui_font, strings.clone_to_cstring(game.message, context.temp_allocator), i32(f32(WINDOW_WIDTH) / 2 - width / 2), 117, 20, COLOR_TEXT)
    }

    nearest := nearest_room_book(game, room, game.floor_index)
    if nearest >= 0 {
        book := game.world.books[nearest]
        hint := fmt.aprintf("E - Open: %s", book.title)
        if !book.unlocked {
            hint = fmt.aprintf("SEALED - %s", book.title)
        }
        ui_text(game.assets.ui_font, strings.clone_to_cstring(hint, context.temp_allocator), 22, i32(WINDOW_HEIGHT - 82), 18, COLOR_ACCENT)
        render_book_info_panel(game, book)
    } else if room.is_lobby {
        ui_text(game.assets.ui_font, strings.clone_to_cstring("E - Speak with the Library Director", context.temp_allocator), 22, i32(WINDOW_HEIGHT - 82), 18, COLOR_ACCENT)
    } else if game.floor_index == 2 {
        ui_text(game.assets.ui_font, strings.clone_to_cstring("The restricted stacks await a later chapter.", context.temp_allocator), 22, i32(WINDOW_HEIGHT - 82), 18, COLOR_MUTED)
    }
}

render_staircase :: proc(room: Room, stair_index: int) {
    stair := room.stairs[stair_index]
    lower_y := room.floor_y[stair_index]
    upper_y := room.floor_y[stair_index + 1]
    step_count := 10
    step_width := abs_f32(stair.upper_x - stair.lower_x) / f32(step_count)
    step_height := (lower_y - upper_y) / f32(step_count)

    for step in 0..<step_count {
        progress := f32(step)
        x := stair.lower_x + (stair.upper_x - stair.lower_x) * progress / f32(step_count)
        y := lower_y - progress * step_height
        rl.DrawRectangleRec({x, y - step_height, step_width + 2, step_height + 3}, rl.Color{70, 61, 91, 255})
        rl.DrawRectangleLinesEx({x, y - step_height, step_width + 2, step_height + 3}, 2, rl.Color{117, 105, 145, 255})
    }
}

render_room_exits :: proc(ground_floor_y: f32, font: rl.Font) {
    door_y := ground_floor_y - 108
    door_height := 108
    rl.DrawRectangle(0, i32(door_y), 36, i32(door_height), rl.Color{19, 17, 34, 255})
    rl.DrawRectangleLinesEx({0, door_y, 36, f32(door_height)}, 4, COLOR_ACCENT)
    rl.DrawRectangle(i32(WINDOW_WIDTH - 36), i32(door_y), 36, i32(door_height), rl.Color{19, 17, 34, 255})
    rl.DrawRectangleLinesEx({WINDOW_WIDTH - 36, door_y, 36, f32(door_height)}, 4, COLOR_ACCENT)
    ui_text(font, strings.clone_to_cstring("<", context.temp_allocator), 8, i32(door_y + 34), 32, COLOR_TEXT)
    ui_text(font, strings.clone_to_cstring(">", context.temp_allocator), WINDOW_WIDTH - 30, i32(door_y + 34), 32, COLOR_TEXT)
}

render_director :: proc(position: rl.Vector2) {
    rl.DrawRectangle(i32(position.x - 15), i32(position.y - 39), 30, 36, rl.Color{88, 68, 104, 255})
    rl.DrawCircleV({position.x, position.y - 46}, 12, rl.Color{232, 190, 150, 255})
    rl.DrawCircleLines(i32(position.x), i32(position.y - 46), 13, COLOR_GOLD)
    rl.DrawLine(i32(position.x - 8), i32(position.y - 51), i32(position.x + 8), i32(position.y - 51), COLOR_WALL)
}

render_book :: proc(game: ^Game_State, book: Book_Entrance) {
    color := COLOR_GOLD
    if !book.unlocked {
        color = COLOR_LOCKED
    }
    if book.completed {
        color = rl.Color{114, 230, 154, 255}
    }

    rl.DrawRectangle(i32(book.position.x - 24), i32(book.position.y + 19), 48, 8, rl.Color{13, 12, 28, 255})
    rl.DrawRectangle(i32(book.position.x - 16), i32(book.position.y - 23), 32, 42, color)
    rl.DrawRectangle(i32(book.position.x - 10), i32(book.position.y - 17), 20, 30, rl.Color{45, 39, 78, 255})
    rl.DrawLine(i32(book.position.x), i32(book.position.y - 17), i32(book.position.x), i32(book.position.y + 12), color)
    rl.DrawCircleLines(i32(book.position.x), i32(book.position.y - 3), 27, color)

    if book.id == 0 && book.completed && relic_information_available(game.progression.books[book.id]) {
        found := game.progression.books[book.id].relics_found
        label := fmt.aprintf("Secret relic: %d / %d", found, FIRST_BOOK_RELIC_COUNT)
        ui_text(game.assets.ui_font, strings.clone_to_cstring(label, context.temp_allocator), i32(book.position.x - 56), i32(book.position.y + 35), 13, COLOR_ACCENT)
    }
}
