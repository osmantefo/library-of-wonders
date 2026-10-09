package main

import rl "vendor:raylib"

Room :: struct {
    name:       string,
    bounds:     rl.Rectangle,
    color:      rl.Color,
    obstacles:  []rl.Rectangle,
    exits:      []Doorway,
    book_ids:   []int,
}

Doorway :: struct {
    target_room: int,
    trigger:     rl.Rectangle,
    spawn:       rl.Vector2,
    label:       string,
}

World :: struct {
    rooms: []Room,
    books: []Book_Entrance,
}

create_world :: proc() -> World {
    room_a_obstacles := make([]rl.Rectangle, 3, allocator=context.allocator)
    room_a_obstacles[0] = {x = 110, y = 120, width = 100, height = 34}
    room_a_obstacles[1] = {x = 430, y = 105, width = 34, height = 150}
    room_a_obstacles[2] = {x = 270, y = 410, width = 150, height = 34}

    room_b_obstacles := make([]rl.Rectangle, 3, allocator=context.allocator)
    room_b_obstacles[0] = {x = 760, y = 115, width = 34, height = 170}
    room_b_obstacles[1] = {x = 940, y = 390, width = 160, height = 34}
    room_b_obstacles[2] = {x = 680, y = 440, width = 130, height = 34}

    room_a_exits := make([]Doorway, 1, allocator=context.allocator)
    room_a_exits[0] = {target_room = 1, trigger = {x = 560, y = 205, width = 50, height = 100}, spawn = {660, 255}, label = "Astronomy Wing"}
    room_b_exits := make([]Doorway, 1, allocator=context.allocator)
    room_b_exits[0] = {target_room = 0, trigger = {x = 590, y = 205, width = 50, height = 100}, spawn = {540, 255}, label = "Entrance Hall"}

    room_a_books := make([]int, 2, allocator=context.allocator)
    room_a_books[0] = 0
    room_a_books[1] = 1
    room_b_books := make([]int, 1, allocator=context.allocator)
    room_b_books[0] = 2

    rooms := make([]Room, 2, allocator=context.allocator)
    rooms[0] = Room{
        name = "The Entrance Hall",
        bounds = {x = 0, y = 0, width = 600, height = 520},
        color = rl.Color{37, 32, 61, 255},
        obstacles = room_a_obstacles,
        exits = room_a_exits,
        book_ids = room_a_books,
    }
    rooms[1] = Room{
        name = "The Astronomy Wing",
        bounds = {x = 600, y = 0, width = 600, height = 520},
        color = rl.Color{27, 40, 67, 255},
        obstacles = room_b_obstacles,
        exits = room_b_exits,
        book_ids = room_b_books,
    }

    books := make([]Book_Entrance, 3, allocator=context.allocator)
    books[0] = {id = 0, title = "The Clockwork Orchard", subtitle = "A book of curious machines", position = {300, 230}, level_id = 0, unlocked = true, completed = false}
    books[1] = {id = 1, title = "The Drowned Kingdom", subtitle = "A memory beneath the waves", position = {350, 330}, level_id = 1, unlocked = true, completed = false}
    books[2] = {id = 2, title = "Atlas of the Starless Sky", subtitle = "A sealed celestial record", position = {850, 260}, level_id = 2, unlocked = false, completed = false}
    return World{rooms = rooms, books = books}
}

current_room_ptr :: proc(world: ^World, room_index: int) -> ^Room {
    return &world.rooms[room_index]
}