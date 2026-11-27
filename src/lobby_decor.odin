package main

import "core:strings"
import rl "vendor:raylib"

LOBBY_SHELF_COLORS :: [6]rl.Color{
	{145, 92, 63, 255},
	{83, 130, 153, 255},
	{172, 143, 75, 255},
	{112, 91, 151, 255},
	{89, 143, 111, 255},
	{171, 106, 92, 255},
}

render_lobby_floor_decor :: proc(floor_index: int, floor_y: f32) {
	if floor_index == 0 {
		shelf_positions := [4]f32{44, 228, 868, 1052}
		for x in shelf_positions {
			render_bookcase(x, floor_y)
		}
		rl.DrawCircle(125, 175, 62, rl.Color{238, 187, 94, 24})
		rl.DrawCircle(1075, 175, 62, rl.Color{238, 187, 94, 24})
		rl.DrawCircleLines(125, 175, 38, rl.Color{238, 187, 94, 105})
		rl.DrawCircleLines(1075, 175, 38, rl.Color{238, 187, 94, 105})
	} else if floor_index == 1 {
		arch_positions := [3]f32{150, 560, 970}
		for x in arch_positions {
			rl.DrawRectangle(i32(x), i32(floor_y-168), 220, 4, rl.Color{102, 111, 153, 120})
			rl.DrawRectangle(i32(x+16), i32(floor_y-142), 4, 116, rl.Color{102, 111, 153, 120})
			rl.DrawRectangle(i32(x+200), i32(floor_y-142), 4, 116, rl.Color{102, 111, 153, 120})
		}
	} else {
		rl.DrawRectangle(0, i32(floor_y-192), WINDOW_WIDTH, 192, rl.Color{13, 10, 29, 100})
		shelf_positions := [5]f32{96, 330, 564, 798, 1032}
		for x in shelf_positions {
			rl.DrawRectangle(i32(x), i32(floor_y-180), 18, 180, rl.Color{36, 27, 55, 255})
			rl.DrawRectangle(i32(x-12), i32(floor_y-180), 42, 8, rl.Color{89, 67, 117, 255})
		}
	}
}

render_bookcase :: proc(x, floor_y: f32) {
	book_colors := LOBBY_SHELF_COLORS
	y := floor_y - 226
	rl.DrawRectangle(i32(x), i32(y), 126, 222, rl.Color{31, 24, 42, 255})
	rl.DrawRectangleLinesEx({x, y, 126, 222}, 5, rl.Color{115, 77, 55, 255})
	for shelf in 0..<4 {
		shelf_y := i32(y + f32(shelf)*53 + 49)
		rl.DrawRectangle(i32(x+5), shelf_y, 116, 5, rl.Color{133, 91, 60, 255})
		for book in 0..<7 {
			width := i32(9 + ((book+shelf)%3)*3)
			book_x := i32(x + 10 + f32(book)*14)
			book_height := i32(25 + ((book*3+shelf)%3)*7)
			rl.DrawRectangle(book_x, shelf_y-book_height, width, book_height, book_colors[(book+shelf)%len(book_colors)])
		}
	}
}

render_book_info_panel :: proc(game: ^Game_State, book: Book_Entrance) {
	rl.DrawRectangle(WINDOW_WIDTH-370, 72, 346, 74, rl.Color{12, 11, 27, 220})
	rl.DrawRectangleLines(WINDOW_WIDTH-370, 72, 346, 74, rl.Color{111, 95, 137, 200})
	ui_text(game.assets.ui_font, strings.clone_to_cstring(book.title, context.temp_allocator), WINDOW_WIDTH-352, 85, 19, COLOR_TEXT)
	status := "E - Enter this story"
	if book.completed {
		status = "Story cleared"
	}
	ui_text(game.assets.ui_font, strings.clone_to_cstring(status, context.temp_allocator), WINDOW_WIDTH-352, 114, 16, COLOR_ACCENT)
}
