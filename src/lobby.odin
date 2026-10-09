package main

import "core:fmt"
import "core:strings"
import rl "vendor:raylib"

update_lobby :: proc(game: ^Game_State, dt: f32) {
    if rl.IsKeyPressed(.ESCAPE) {
        game.screen = .TITLE
        return
    }

    update_player(&game.player, dt)
    room := current_room_ptr(&game.world, game.current_room)
    resolve_room_collisions(&game.player, room^)

    for door in room.exits {
        if circle_rect_overlap(game.player.position, game.player.radius, door.trigger) {
            game.current_room = door.target_room
            game.player.position = door.spawn
            set_message(game, fmt.aprintf("Entered %s", game.world.rooms[game.current_room].name))
            break
        }
    }

    nearest := -1
    nearest_distance := f32(INTERACTION_DISTANCE * INTERACTION_DISTANCE)
    for i in 0..<len(game.world.books) {
        book := game.world.books[i]
        if book_in_room(book.id, game.world.rooms[game.current_room]) {
            d := distance_squared(game.player.position, book.position)
            if d < nearest_distance {
                nearest = i
                nearest_distance = d
            }
        }
    }

    if nearest >= 0 && rl.IsKeyPressed(.E) {
        book := &game.world.books[nearest]
        if !book.unlocked {
            set_message(game, "This book is sealed. Complete more of the archive first.")
        } else {
            game.lobby_return_position = game.player.position
            game.active_level = book.level_id
            game.player.position = LEVELS[game.active_level].spawn
            game.screen = .LEVEL
        }
    }

    game.camera.target = game.player.position
}

book_in_room :: proc(book_id: int, room: Room) -> bool {
    for id in room.book_ids {
        if id == book_id { return true }
    }
    return false
}

render_lobby :: proc(game: ^Game_State) {
    rl.ClearBackground(COLOR_BACKGROUND)
    rl.BeginMode2D(game.camera)

    for room in game.world.rooms {
        rl.DrawRectangleRec(room.bounds, room.color)
        rl.DrawRectangleLinesEx(room.bounds, 6, COLOR_GOLD)
        for obstacle in room.obstacles {
            rl.DrawRectangleRec(obstacle, COLOR_WALL)
            rl.DrawRectangleLinesEx(obstacle, 2, rl.Color{94, 82, 126, 255})
        }
        for door in room.exits {
            rl.DrawRectangleRec(door.trigger, rl.Color{71, 64, 112, 255})
            rl.DrawRectangleLinesEx(door.trigger, 3, COLOR_ACCENT)
        }
    }

    for book in game.world.books {
        if book_in_room(book.id, game.world.rooms[game.current_room]) {
            render_book(book)
        }
    }
    render_player(game.player)
    rl.EndMode2D()

    room_name := game.world.rooms[game.current_room].name
    rl.DrawRectangle(0, 0, WINDOW_WIDTH, 64, rl.Color{12, 11, 27, 225})
    rl.DrawText(strings.clone_to_cstring("THE GRAND ARCHIVE", context.temp_allocator), 22, 14, 24, COLOR_GOLD)
    rl.DrawText(strings.clone_to_cstring(room_name, context.temp_allocator), i32(WINDOW_WIDTH - rl.MeasureText(strings.clone_to_cstring(room_name, context.temp_allocator), 20) - 24), 18, 20, COLOR_TEXT)
    rl.DrawText(strings.clone_to_cstring("Move: WASD / Arrows    Interact: E    Return to title: Esc", context.temp_allocator), 22, i32(WINDOW_HEIGHT - 30), 18, COLOR_MUTED)

    if game.message_time > 0 {
        width := rl.MeasureText(strings.clone_to_cstring(game.message, context.temp_allocator), 20)
        rl.DrawRectangle(i32(WINDOW_WIDTH / 2 - width / 2 - 18), 78, i32(width + 36), 38, rl.Color{12, 11, 27, 230})
        rl.DrawText(strings.clone_to_cstring(game.message, context.temp_allocator), i32(WINDOW_WIDTH / 2 - width / 2), 87, 20, COLOR_TEXT)
    }

    nearest := -1
    nearest_distance := f32(INTERACTION_DISTANCE * INTERACTION_DISTANCE)
    for i in 0..<len(game.world.books) {
        book := game.world.books[i]
        if book_in_room(book.id, game.world.rooms[game.current_room]) {
            d := distance_squared(game.player.position, book.position)
            if d < nearest_distance { nearest = i; nearest_distance = d }
        }
    }
    if nearest >= 0 {
        book := game.world.books[nearest]
        hint := fmt.aprintf("E - Open: %s", book.title)
        if !book.unlocked { hint = fmt.aprintf("SEALED - %s", book.title) }
        rl.DrawRectangle(0, WINDOW_HEIGHT - 72, WINDOW_WIDTH, 34, rl.Color{12, 11, 27, 225})
        rl.DrawText(strings.clone_to_cstring(hint, context.temp_allocator), i32(WINDOW_WIDTH / 2 - rl.MeasureText(strings.clone_to_cstring(hint, context.temp_allocator), 20) / 2), i32(WINDOW_HEIGHT - 66), 20, COLOR_ACCENT)
    }
}

render_book :: proc(book: Book_Entrance) {
    color := COLOR_GOLD
    if !book.unlocked { color = COLOR_LOCKED }
    if book.completed { color = rl.Color{114, 230, 154, 255} }

    rl.DrawRectangle(i32(book.position.x - 24), i32(book.position.y + 19), 48, 8, rl.Color{13, 12, 28, 255})
    rl.DrawRectangle(i32(book.position.x - 16), i32(book.position.y - 23), 32, 42, color)
    rl.DrawRectangle(i32(book.position.x - 10), i32(book.position.y - 17), 20, 30, rl.Color{45, 39, 78, 255})
    rl.DrawLine(i32(book.position.x), i32(book.position.y - 17), i32(book.position.x), i32(book.position.y + 12), color)
    rl.DrawCircleLines(i32(book.position.x), i32(book.position.y - 3), 27, color)
}