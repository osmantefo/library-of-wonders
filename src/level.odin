package main

import "core:math"
import "core:strings"
import rl "vendor:raylib"

Book_Entrance :: struct {
    id:        int,
    room_id:   int,
    floor_index: int,
    title:     string,
    subtitle:  string,
    position:  rl.Vector2,
    level_id:  int,
    unlocked:  bool,
    completed: bool,
}

Level_Data :: struct {
    name:        string,
    description: string,
    spawn:       rl.Vector2,
    bounds:      rl.Rectangle,
}

LEVELS := []Level_Data{
    {name = "The Clockwork Orchard", description = "Follow the old corridor to its far arch.", spawn = {120, 0}, bounds = {0, 0, 5000, 720}},
    {name = "The Drowned Kingdom", description = "Find the lost route through a sunken royal library.", spawn = {100, 450}, bounds = {0, 0, 1800, 600}},
    {name = "Atlas of Empires", description = "Trace the rise and fall of kingdoms lost to time.", spawn = {100, 450}, bounds = {0, 0, 1800, 600}},
    {name = "The Cartographer's Chronicle", description = "Follow the maps drawn by a restless royal historian.", spawn = {100, 450}, bounds = {0, 0, 1800, 600}},
    {name = "Field Guide to Impossible Beasts", description = "Meet creatures found only in unfinished stories.", spawn = {100, 450}, bounds = {0, 0, 1800, 600}},
    {name = "The Greenhouse at World's End", description = "Discover a garden growing beyond the edge of the world.", spawn = {100, 450}, bounds = {0, 0, 1800, 600}},
    {name = "The Silent Orchestra", description = "Restore a concert hall where every instrument is silent.", spawn = {100, 450}, bounds = {0, 0, 1800, 600}},
    {name = "Gallery of Living Color", description = "Step inside paintings that change when no one is looking.", spawn = {100, 450}, bounds = {0, 0, 1800, 600}},
    {name = "Questions for the Stars", description = "Seek answers to questions older than the archive.", spawn = {100, 450}, bounds = {0, 0, 1800, 600}},
    {name = "The Lantern of First Light", description = "Carry a light through the first stories ever told.", spawn = {100, 450}, bounds = {0, 0, 1800, 600}},
    {name = "Beyond the Western Map", description = "Travel beyond the last known edge of the map.", spawn = {100, 450}, bounds = {0, 0, 1800, 600}},
    {name = "The Road Between Worlds", description = "Follow a road that connects places that should not meet.", spawn = {100, 450}, bounds = {0, 0, 1800, 600}},
    {name = "Lives of Inventors", description = "Uncover the hidden lives of history's great inventors.", spawn = {100, 450}, bounds = {0, 0, 1800, 600}},
    {name = "The Unwritten Index", description = "Find the missing entry that describes every other book.", spawn = {100, 450}, bounds = {0, 0, 1800, 600}},
}

update_level :: proc(game: ^Game_State, dt: f32) {
    if rl.IsKeyPressed(.ESCAPE) {
        game.pause_choice = 0
        game.screen = .PAUSED
        return
    }

    update_platformer_player(game, dt)
	if game.screen != .LEVEL {
    	return
    }
	level := LEVELS[game.active_level]
	game.level_run.elapsed_time += dt
	activate_level_checkpoint(game)
	camera_half_width := game.camera.offset.x / game.camera.zoom
	camera_target_x := level.bounds.width / 2.0
	if level.bounds.width > camera_half_width * 2 {
	    camera_target_x = clamp_f32(game.player.position.x, camera_half_width, level.bounds.width - camera_half_width)
	}
	game.camera.target.x += (camera_target_x - game.camera.target.x) * min_f32(1, dt * 7)
	game.camera.target.y = WINDOW_HEIGHT / 2.0
	if game.active_level == 0 && !game.level_run.relic_collected {
	    relic_position := rl.Vector2{3160, LEVEL_PLATFORMS[1].bounds.y - 38}
	    if distance_squared(game.player.position, relic_position) <= 46 * 46 {
	        game.level_run.relic_collected = true
	        set_message(game, "You found a secret relic. Reach the exit to keep it.")
	    }
	}
	update_enemies(game, dt)
    if game.screen != .LEVEL {
    	return
    }

    if game.player.position.x >= level.bounds.width - 90 {
        complete_level(game)
    }
}

render_level :: proc(game: ^Game_State) {
    level := LEVELS[game.active_level]
    rl.ClearBackground(rl.Color{13, 15, 32, 255})

    rl.BeginMode2D(game.camera)
    view_height := f32(WINDOW_HEIGHT) / game.camera.zoom
    view_y := (f32(WINDOW_HEIGHT) - view_height) / 2
    view_bottom := view_y + view_height
    if game.active_level == 0 {
        render_corridor_layer(game.assets.corridor_back, 32, level.bounds.width, view_y, view_height)
        render_corridor_layer(game.assets.corridor_far, 32, level.bounds.width, view_y, view_height)
        render_corridor_layer(game.assets.corridor_middle, 80, level.bounds.width, view_y, view_height)
    } else {
        rl.DrawRectangle(0, 0, i32(level.bounds.width), WINDOW_HEIGHT, rl.Color{19, 31, 42, 255})
    }

    ground_y := level_ground_y()
    rl.DrawRectangle(0, i32(ground_y), i32(level.bounds.width), i32(view_bottom - ground_y), rl.Color{21, 19, 39, 255})
    rl.DrawRectangle(0, i32(ground_y), i32(level.bounds.width), 5, rl.Color{108, 75, 158, 255})
    if game.active_level == 0 {
        render_level_platforms()
        render_corridor_torches(game)
        render_level_checkpoints(game)
        if !game.level_run.relic_collected {
            render_secret_relic(game.level_run.animation_time)
        }
        exit_x := i32(level.bounds.width - 120)
        rl.DrawRectangle(exit_x, i32(ground_y - 154), 76, 154, rl.Color{17, 12, 35, 230})
        rl.DrawRectangleLines(exit_x, i32(ground_y - 154), 76, 154, COLOR_GOLD)
        rl.DrawRectangle(exit_x + 12, i32(ground_y - 142), 52, 142, rl.Color{81, 56, 120, 230})
        rl.DrawCircle(exit_x + 58, i32(ground_y - 77), 3, COLOR_GOLD)
    }

    render_enemies(game)
    render_level_player(game.player, game.assets)

    if game.active_level == 0 {
        render_corridor_layer(game.assets.corridor_near, 224, level.bounds.width, view_y, view_height)
        render_corridor_layer(game.assets.corridor_foreground, 224, level.bounds.width, view_y, view_height)
    }
    rl.EndMode2D()

    ui_text(game.assets.ui_font, strings.clone_to_cstring(level.name, context.temp_allocator), 28, 20, 24, COLOR_GOLD)
    render_player_health(game)
    if game.active_level == 0 {
        ui_text(game.assets.ui_font, strings.clone_to_cstring("Move: A/D    Jump: Space/W/Up    Attack: J/X    Esc: pause", context.temp_allocator), 28, WINDOW_HEIGHT - 40, 18, COLOR_TEXT)
        ui_text(game.assets.ui_font, strings.clone_to_cstring("Reach the glowing arch at the end of the corridor", context.temp_allocator), 28, 56, 16, COLOR_MUTED)
    } else {
        ui_text(game.assets.ui_font, strings.clone_to_cstring("LEVEL PLACEHOLDER - ESC returns to the lobby", context.temp_allocator), 28, 56, 18, COLOR_MUTED)
        ui_text(game.assets.ui_font, strings.clone_to_cstring(level.description, context.temp_allocator), 28, WINDOW_HEIGHT - 40, 18, COLOR_TEXT)
    }

}

complete_level :: proc(game: ^Game_State) {
	record_level_completion(game)
	save_progression(game.progression)
	game.results_choice = 0
	game.screen = .LEVEL_RESULTS
}

render_corridor_layer :: proc(texture: rl.Texture2D, tile_width: i32, world_width, view_y, view_height: f32) {
	scale := view_height / 224
	scaled_width := f32(tile_width) * scale
	tile_count := int(world_width / scaled_width) + 1
	for tile in 0..<tile_count {
		x := f32(tile) * scaled_width
		rl.DrawTexturePro(
			texture,
			rl.Rectangle{0, 0, f32(texture.width), f32(texture.height)},
			rl.Rectangle{x, view_y, scaled_width, view_height},
			rl.Vector2{0, 0},
			0,
			rl.WHITE,
		)
	}
}

render_secret_relic :: proc(animation_time: f32) {
	position := rl.Vector2{3160, LEVEL_PLATFORMS[1].bounds.y - 38}
	pulse := 1 + math.sin(animation_time * 3) * 0.12
	rl.DrawCircleV(position, 24 * pulse, rl.Color{112, 221, 246, 40})
	rl.DrawPoly(position, 4, 17 * pulse, 45, rl.Color{135, 231, 255, 255})
	rl.DrawPoly(position, 4, 9 * pulse, 45, rl.Color{247, 249, 216, 255})
}

render_corridor_torches :: proc(game: ^Game_State) {
	texture := game.assets.corridor_torch
	frame := int(game.level_run.animation_time / 0.14) % 4
	for x := f32(760); x < LEVELS[0].bounds.width; x += 960 {
		rl.DrawTexturePro(
			texture,
			rl.Rectangle{f32(frame * 32), 0, 32, 32},
			rl.Rectangle{x, 150, 64, 64},
			rl.Vector2{0, 0},
			0,
			rl.WHITE,
		)
	}
}

return_to_lobby :: proc(game: ^Game_State, completed: bool) {
	if completed {
		record_level_completion(game)
		save_progression(game.progression)
	}
	game.screen = .LOBBY
	game.player.position = game.lobby_return_position
	game.player.velocity_y = 0
	game.player.grounded = true
	game.player.is_attacking = false
	game.player.is_crouching = false
	game.player.action = .NONE
	game.player.action_time = 0
	game.player.is_hurt = false
	game.player.knockback_x = 0
	game.floor_index = game.lobby_return_floor
	game.camera.target = {WINDOW_WIDTH / 2.0, WINDOW_HEIGHT / 2.0}
	game.camera.zoom = 1.0
	if completed {
		set_message(game, "Level complete. You return to the library.")
	} else {
		set_message(game, "You return to the library.")
	}
}

record_level_completion :: proc(game: ^Game_State) {
	if game.active_level < 0 ||
	   game.active_level >= len(game.world.books) ||
	   game.active_level >= BOOK_COUNT {
		return
	}
	game.world.books[game.active_level].completed = true
	game.progression.books[game.active_level].cleared = true
	if game.active_level == 0 && game.level_run.relic_collected {
		game.progression.books[game.active_level].relics_found = FIRST_BOOK_RELIC_COUNT
	}
}
