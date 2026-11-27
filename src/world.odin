package main

import rl "vendor:raylib"

ROOM_COUNT :: 8
HALL_COUNT :: 7
FLOOR_COUNT :: 3
BOOKS_PER_HALL :: 2

HALL_NAMES :: [7]string{
    "Fiction and Literature",
    "History and Geography",
    "Science and Nature",
    "Arts and Music",
    "Philosophy and Religion",
    "Travel and Adventure",
    "Reference and Biography",
}

HALL_COLORS :: [7]rl.Color{
    {37, 32, 61, 255},
    {43, 34, 51, 255},
    {29, 43, 57, 255},
    {49, 34, 57, 255},
    {37, 43, 54, 255},
    {43, 39, 54, 255},
    {31, 43, 49, 255},
}

Room :: struct {
    name:       string,
    color:      rl.Color,
    is_lobby:   bool,
    left_room:  int,
    right_room: int,
    floor_y:    [3]f32,
    floor_count: int,
    stairs:     [2]Staircase,
    book_ids:   [2]int,
    book_count: int,
}

Staircase :: struct {
    lower_x: f32,
    upper_x: f32,
}

World :: struct {
    rooms: []Room,
    books: []Book_Entrance,
}

HALL_BOOK_TITLES :: [7][2]string{
    {"The Clockwork Orchard", "The Drowned Kingdom"},
    {"Atlas of Empires", "The Cartographer's Chronicle"},
    {"Field Guide to Impossible Beasts", "The Greenhouse at World's End"},
    {"The Silent Orchestra", "Gallery of Living Color"},
    {"Questions for the Stars", "The Lantern of First Light"},
    {"Beyond the Western Map", "The Road Between Worlds"},
    {"Lives of Inventors", "The Unwritten Index"},
}

HALL_BOOK_DESCRIPTIONS :: [7][2]string{
    {"Explore a garden of brass trees and broken timepieces.", "Find the lost route through a sunken royal library."},
    {"Trace the rise and fall of kingdoms lost to time.", "Follow the maps drawn by a restless royal historian."},
    {"Meet creatures found only in unfinished stories.", "Discover a garden growing beyond the edge of the world."},
    {"Restore a concert hall where every instrument is silent.", "Step inside paintings that change when no one is looking."},
    {"Seek answers to questions older than the archive.", "Carry a light through the first stories ever told."},
    {"Travel beyond the last known edge of the map.", "Follow a road that connects places that should not meet."},
    {"Uncover the hidden lives of history's great inventors.", "Find the missing entry that describes every other book."},
}

create_world :: proc() -> World {
    hall_names := HALL_NAMES
    hall_colors := HALL_COLORS
    hall_book_titles := HALL_BOOK_TITLES
    hall_book_descriptions := HALL_BOOK_DESCRIPTIONS
    rooms := make([]Room, ROOM_COUNT, allocator=context.allocator)
    books := make([]Book_Entrance, HALL_COUNT * BOOKS_PER_HALL, allocator=context.allocator)

    rooms[0] = Room{
        name = "The Grand Lobby",
        color = rl.Color{28, 25, 45, 255},
        is_lobby = true,
        left_room = 1,
        right_room = HALL_COUNT,
        floor_y = {570, 0, 0},
        floor_count = 1,
    }

    for hall in 0..<HALL_COUNT {
        room_index := hall + 1
        left_room := room_index + 1
        if room_index == HALL_COUNT {
            left_room = 0
        }
        right_room := room_index - 1
        if room_index == 1 {
            right_room = 0
        }

        room := Room{
            name = hall_names[hall],
            color = hall_colors[hall],
            left_room = left_room,
            right_room = right_room,
            floor_y = {570, 405, 240},
            floor_count = FLOOR_COUNT,
            stairs = {
                {lower_x = 350, upper_x = 485},
                {lower_x = 930, upper_x = 795},
            },
            book_count = BOOKS_PER_HALL,
        }

        first_book_id := hall * BOOKS_PER_HALL
        room.book_ids[0] = first_book_id
        room.book_ids[1] = first_book_id + 1
        rooms[room_index] = room

        books[first_book_id] = Book_Entrance{
            id = first_book_id,
            room_id = room_index,
            floor_index = 0,
            title = hall_book_titles[hall][0],
            subtitle = hall_book_descriptions[hall][0],
            position = {600, room.floor_y[0] - 30},
            level_id = first_book_id,
            unlocked = true,
        }
        books[first_book_id + 1] = Book_Entrance{
            id = first_book_id + 1,
            room_id = room_index,
            floor_index = 1,
            title = hall_book_titles[hall][1],
            subtitle = hall_book_descriptions[hall][1],
            position = {675, room.floor_y[1] - 30},
            level_id = first_book_id + 1,
            unlocked = true,
        }
    }

    return World{rooms = rooms, books = books}
}
