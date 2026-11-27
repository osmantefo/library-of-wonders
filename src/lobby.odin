package main

import "core:fmt"
import "core:strings"
import rl "vendor:raylib"

STAIR_INTERACTION_DISTANCE :: 58.0
LIBRARIAN_FRAME_WIDTH :: 231
LIBRARIAN_FRAME_HEIGHT :: 190
PLAYER_IDLE_VISIBLE_HEIGHT :: 47
LIBRARIAN_IDLE_VISIBLE_TOP :: 55
LIBRARIAN_IDLE_VISIBLE_BOTTOM :: 140
LIBRARIAN_RUN_VISIBLE_TOPS :: [8]int{65, 67, 67, 64, 64, 66, 66, 62}
LIBRARIAN_RUN_VISIBLE_BOTTOMS :: [8]int{139, 140, 140, 138, 135, 140, 140, 138}
LIBRARIAN_MIN_X :: 390.0
LIBRARIAN_MAX_X :: 835.0
LIBRARIAN_SPEECH_DURATION :: 4.0
LIBRARIAN_SPEECH_FADE_DURATION :: 0.65
LIBRARIAN_LINES :: [4]string{
	"Every shelf holds a new journey.",
	"Take your time, Keeper.",
	"Quiet halls keep the stories safe.",
	"Mind the older books; they bite.",
}

Librarian :: struct {
	position: rl.Vector2,
	animation_time: f32,
	idle_time: f32,
	target_x: f32,
	walk_speed: f32,
	speech_time: f32,
	speech_index: int,
	is_walking: bool,
	facing_left: bool,
}

new_librarian :: proc(floor_y: f32) -> Librarian {
	return Librarian{
		position = {760, floor_y},
		idle_time = f32(rl.GetRandomValue(3, 6)),
	}
}

update_librarian :: proc(librarian: ^Librarian, dt: f32) {
	librarian.animation_time += dt
	librarian.speech_time = max_f32(0, librarian.speech_time-dt)
	if librarian.is_walking {
		delta := librarian.target_x - librarian.position.x
		step := librarian.walk_speed * dt
		librarian.facing_left = delta < 0
		if abs_f32(delta) <= step {
			librarian.position.x = librarian.target_x
			librarian.is_walking = false
			librarian.idle_time = f32(rl.GetRandomValue(3, 7))
		} else {
			librarian.position.x += sign_f32(delta) * step
		}
		return
	}

	librarian.idle_time -= dt
	if librarian.idle_time > 0 {
		return
	}

	direction := f32(1)
	if rl.GetRandomValue(0, 1) == 0 {
		direction = -1
	}
	distance := f32(rl.GetRandomValue(70, 180))
	librarian.target_x = clamp_f32(librarian.position.x + direction*distance, LIBRARIAN_MIN_X, LIBRARIAN_MAX_X)
	if abs_f32(librarian.target_x-librarian.position.x) < 24 {
		if librarian.position.x < (LIBRARIAN_MIN_X+LIBRARIAN_MAX_X)/2 {
			librarian.target_x = LIBRARIAN_MAX_X
		} else {
			librarian.target_x = LIBRARIAN_MIN_X
		}
	}
	librarian.walk_speed = f32(rl.GetRandomValue(24, 42))
	librarian.is_walking = true
}

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
	if room.is_lobby {
		update_librarian(&game.librarian, dt)
	}

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
    } else if room.is_lobby && rl.IsKeyPressed(.E) && distance_squared(game.player.position, game.librarian.position) < STAIR_INTERACTION_DISTANCE*STAIR_INTERACTION_DISTANCE {
		game.librarian.speech_index = int(rl.GetRandomValue(0, i32(len(LIBRARIAN_LINES)-1)))
		game.librarian.speech_time = LIBRARIAN_SPEECH_DURATION
		game.librarian.facing_left = game.player.position.x < game.librarian.position.x
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

    for book_index in 0..<room.book_count {
        book_id := room.book_ids[book_index]
        book := game.world.books[book_id]
        if book.floor_index == game.floor_index {
            render_book(game, book)
        }
    }
    render_player(game.player, game.assets)
	if room.is_lobby {
		render_librarian(game.librarian, game.assets, game.player.config.render_scale)
	}
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
    ui_text(game.assets.ui_font, strings.clone_to_cstring("Move: A/D or Arrows    Stairs: W/S or Up/Down    Book / Librarian: E    Main Menu: Esc", context.temp_allocator), 22, i32(WINDOW_HEIGHT - 33), 16, COLOR_MUTED)

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
		if distance_squared(game.player.position, game.librarian.position) < STAIR_INTERACTION_DISTANCE*STAIR_INTERACTION_DISTANCE {
			ui_text(game.assets.ui_font, strings.clone_to_cstring("E - Speak with the Librarian", context.temp_allocator), 22, i32(WINDOW_HEIGHT - 82), 18, COLOR_ACCENT)
		} else {
			ui_text(game.assets.ui_font, strings.clone_to_cstring("Find the Librarian to talk", context.temp_allocator), 22, i32(WINDOW_HEIGHT - 82), 18, COLOR_MUTED)
		}
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

render_librarian :: proc(librarian: Librarian, assets: Game_Assets, player_render_scale: f32) {
	texture := assets.librarian_idle
	frame_count := 6
	frame_duration := f32(0.16)
	if librarian.is_walking {
		texture = assets.librarian_run
		frame_count = 8
		frame_duration = f32(0.12)
	}
	frame := int(librarian.animation_time / frame_duration) % frame_count
	visible_tops := LIBRARIAN_RUN_VISIBLE_TOPS
	visible_bottoms := LIBRARIAN_RUN_VISIBLE_BOTTOMS
	visible_top := LIBRARIAN_IDLE_VISIBLE_TOP
	visible_bottom := LIBRARIAN_IDLE_VISIBLE_BOTTOM
	if librarian.is_walking {
		visible_top = visible_tops[frame]
		visible_bottom = visible_bottoms[frame]
	}
	source_x := f32(frame * LIBRARIAN_FRAME_WIDTH)
	source_width := f32(LIBRARIAN_FRAME_WIDTH)
	if librarian.facing_left {
		source_x += source_width
		source_width = -source_width
	}
	visible_height := f32(PLAYER_IDLE_VISIBLE_HEIGHT) * player_render_scale
	scale := visible_height / f32(visible_bottom-visible_top+1)
	height := f32(LIBRARIAN_FRAME_HEIGHT) * scale
	width := f32(LIBRARIAN_FRAME_WIDTH) * scale
	draw_y := librarian.position.y - f32(visible_bottom+1)*scale
	rl.DrawTexturePro(
		texture,
		rl.Rectangle{source_x, 0, source_width, f32(LIBRARIAN_FRAME_HEIGHT)},
		rl.Rectangle{librarian.position.x-width/2, draw_y, width, height},
		{0, 0},
		0,
		rl.WHITE,
	)

	if librarian.speech_time <= 0 {
		return
	}
	lines := LIBRARIAN_LINES
	line := strings.clone_to_cstring(lines[librarian.speech_index], context.temp_allocator)
	text_width := ui_text_width(assets.ui_font, line, 16)
	bubble_width := clamp_f32(text_width+24, 150, 264)
	bubble_height := f32(34)
	bubble_x := librarian.position.x - bubble_width/2
	bubble_y := librarian.position.y - visible_height - bubble_height - 12
	alpha := u8(255)
	if librarian.speech_time < LIBRARIAN_SPEECH_FADE_DURATION {
		alpha = u8(255 * librarian.speech_time / LIBRARIAN_SPEECH_FADE_DURATION)
	}
	background := rl.Color{12, 10, 27, alpha}
	border := rl.Color{205, 178, 113, alpha}
	rl.DrawRectangleRec({bubble_x, bubble_y, bubble_width, bubble_height}, background)
	rl.DrawRectangleLinesEx({bubble_x, bubble_y, bubble_width, bubble_height}, 2, border)
	rl.DrawLine(i32(librarian.position.x), i32(bubble_y+bubble_height), i32(librarian.position.x), i32(bubble_y+bubble_height+8), border)
	ui_text(assets.ui_font, line, i32(bubble_x+12), i32(bubble_y+8), 16, rl.Color{247, 239, 222, alpha})
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
