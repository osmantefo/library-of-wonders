package main

import "core:encoding/json"
import "core:fmt"
import "core:os"

BOOK_COUNT :: 14
FIRST_BOOK_RELIC_COUNT :: 1
PROGRESSION_SAVE_PATH :: "save\\progression.json"

Book_Progress :: struct {
	cleared:      bool,
	relics_found: int,
}

Progression :: struct {
	books: [BOOK_COUNT]Book_Progress,
}

load_progression :: proc() -> Progression {
	progression: Progression
	if !os.exists(PROGRESSION_SAVE_PATH) {
		return progression
	}

	data, read_error := os.read_entire_file(PROGRESSION_SAVE_PATH, context.allocator)
	if read_error != nil {
		fmt.eprintln("Could not read progression save: %v", read_error)
		return progression
	}
	defer delete(data)

	if decode_progression(data, &progression) {
		return progression
	}
	fmt.eprintln("Could not parse progression save; starting with empty progression.")
	return {}
}

decode_progression :: proc(data: []byte, progression: ^Progression) -> bool {
	if err := json.unmarshal(data, progression); err != nil {
		fmt.eprintln("Progression JSON decode error:", err)
		return false
	}
	return true
}

save_progression :: proc(progression: Progression) -> bool {
	if !os.exists("save") {
		if err := os.make_directory_all("save"); err != nil {
			fmt.eprintln("Could not create save directory: %v", err)
			return false
		}
	}

	data, marshal_error := json.marshal(progression, {pretty = true})
	if marshal_error != nil {
		fmt.eprintln("Could not serialize progression: %v", marshal_error)
		return false
	}
	defer delete(data)

	if err := os.write_entire_file(PROGRESSION_SAVE_PATH, data); err != nil {
		fmt.eprintln("Could not write progression save: %v", err)
		return false
	}
	return true
}

start_new_game :: proc(game: ^Game_State) -> bool {
	fresh_progression: Progression
	if !save_progression(fresh_progression) {
		return false
	}

	reset_progression_state(game)
	game.title_confirming_new_game = false
	enter_library(game)
	return true
}

reset_progression_state :: proc(game: ^Game_State) {
	game.progression = {}
	for i in 0..<len(game.world.books) {
		game.world.books[i].completed = false
	}
}

relic_information_available :: proc(book: Book_Progress) -> bool {
	return book.cleared
}
