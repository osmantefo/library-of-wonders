package main

import "core:fmt"
import "core:strings"
import rl "vendor:raylib"

LEVEL_CHECKPOINT_X :: [2]f32{2240, 4260}

start_level_run :: proc(game: ^Game_State, level_id: int) {
	game.active_level = level_id
	game.player.position = LEVELS[level_id].spawn
	game.player.position.y = level_ground_y() - game.player.radius
	game.player.velocity_y = 0
	game.player.coyote_timer = 0
	game.player.jump_buffer_timer = 0
	game.player.grounded = true
	game.player.animation_time = 0
	game.player.is_attacking = false
	game.player.is_crouching = false
	game.player.action = .NONE
	game.player.action_time = 0
	game.player.is_hurt = false
	game.player.hurt_time = 0
	game.player.heal_time = 0
	game.player.health_feedback = .NONE
	game.player.health_feedback_time = 0
	game.player.knockback_x = 0
	game.player.health = game.player.max_health
	game.player.last_hit_enemy = -1
	game.player.last_hit_damage = 0
	game.player.invulnerability_time = 0
	game.camera.target = {game.player.position.x, WINDOW_HEIGHT / 2.0}
	game.camera.zoom = 1.0
	if level_id == 0 {
		game.camera.zoom = 0.82
	}
	initialize_level_run(game)
	game.screen = .LEVEL
}

activate_level_checkpoint :: proc(game: ^Game_State) {
	checkpoint_positions := LEVEL_CHECKPOINT_X
	if game.active_level != 0 || game.level_run.checkpoint_index >= len(checkpoint_positions) {
		return
	}
	checkpoint_x := checkpoint_positions[game.level_run.checkpoint_index]
	if game.player.position.x < checkpoint_x {
		return
	}

	game.level_run.checkpoint_x = checkpoint_x
	game.level_run.checkpoint_index += 1
	set_message(game, "Checkpoint reached.")
}

render_level_checkpoints :: proc(game: ^Game_State) {
	checkpoint_positions := LEVEL_CHECKPOINT_X
	for i in 0..<len(checkpoint_positions) {
		checkpoint_x := checkpoint_positions[i]
		ground_y := level_ground_y()
		active := checkpoint_x <= game.level_run.checkpoint_x
		color := rl.Color{111, 111, 137, 255}
		if active {
			color = COLOR_ACCENT
		}
		rl.DrawRectangle(i32(checkpoint_x - 4), i32(ground_y - 76), 8, 76, rl.Color{39, 34, 57, 255})
		rl.DrawCircle(i32(checkpoint_x), i32(ground_y - 82), 13, rl.Color{20, 17, 33, 220})
		rl.DrawCircleLines(i32(checkpoint_x), i32(ground_y - 82), 13, color)
		rl.DrawCircle(i32(checkpoint_x), i32(ground_y - 82), 5, color)
		rl.DrawText(rl.TextFormat("%d", i32(i+1)), i32(checkpoint_x - 4), i32(ground_y - 88), 12, rl.WHITE)
	}
}

update_pause_menu :: proc(game: ^Game_State) {
	if rl.IsKeyPressed(.ESCAPE) {
		game.screen = .LEVEL
		return
	}
	if rl.IsKeyPressed(.UP) || rl.IsKeyPressed(.W) {
		game.pause_choice = (game.pause_choice + 2) % 3
	}
	if rl.IsKeyPressed(.DOWN) || rl.IsKeyPressed(.S) {
		game.pause_choice = (game.pause_choice + 1) % 3
	}
	if !rl.IsKeyPressed(.ENTER) && !rl.IsKeyPressed(.SPACE) {
		return
	}

	switch game.pause_choice {
	case 0:
		game.screen = .LEVEL
	case 1:
		restart_from_checkpoint(game)
	case 2:
		return_to_lobby(game, false)
	}
}

restart_from_checkpoint :: proc(game: ^Game_State) {
	if game.active_level != 0 {
		start_level_run(game, game.active_level)
		return
	}
	set_player_at_checkpoint(game, game.player.max_health)
	game.screen = .LEVEL
	set_message(game, "Restarted from the last checkpoint.")
}

respawn_at_checkpoint :: proc(game: ^Game_State) {
	if game.active_level != 0 {
		return_to_lobby(game, false)
		set_message(game, "You were defeated and returned to the library.")
		return
	}
	respawn_health := game.player.max_health * 3 / 5
	if respawn_health < 1 {
		respawn_health = 1
	}
	set_player_at_checkpoint(game, respawn_health)
	set_message(game, "You were rescued at the last checkpoint.")
}

set_player_at_checkpoint :: proc(game: ^Game_State, health: int) {
	player := &game.player
	player.position.x = game.level_run.checkpoint_x
	player.position.y = level_support_y(player.position.x) - player.radius
	player.velocity_y = 0
	player.coyote_timer = 0
	player.jump_buffer_timer = 0
	player.grounded = true
	player.is_attacking = false
	player.attack_time = 0
	player.is_crouching = false
	player.action = .NONE
	player.action_time = 0
	player.is_hurt = false
	player.hurt_time = 0
	player.heal_time = 0
	player.health_feedback = .NONE
	player.health_feedback_time = 0
	player.knockback_x = 0
	player.health = health
	player.last_hit_enemy = -1
	player.last_hit_damage = 0
	player.invulnerability_time = 1.8
	game.camera.target.x = player.position.x
	for i in 0..<MAX_ENEMY_PROJECTILES {
		game.level_run.projectiles[i].active = false
	}
	game.level_run.projectile_count = 0
}

update_level_results :: proc(game: ^Game_State) {
	if rl.IsKeyPressed(.ESCAPE) {
		return_to_lobby(game, false)
		return
	}
	if rl.IsKeyPressed(.UP) || rl.IsKeyPressed(.W) {
		game.results_choice = (game.results_choice + 1) % 2
	}
	if rl.IsKeyPressed(.DOWN) || rl.IsKeyPressed(.S) {
		game.results_choice = (game.results_choice + 1) % 2
	}
	if !rl.IsKeyPressed(.ENTER) && !rl.IsKeyPressed(.SPACE) {
		return
	}
	if game.results_choice == 0 {
		return_to_lobby(game, false)
	} else {
		start_level_run(game, game.active_level)
	}
}

render_pause_menu :: proc(game: ^Game_State) {
	render_flow_panel(game, "PAUSED")
	options := [3]string{"Resume", "Restart from Checkpoint", "Return to Library"}
	for i in 0..<len(options) {
		render_flow_option(game, options[i], i, game.pause_choice, i32(326+i*52))
	}
	render_flow_text(game, strings.clone_to_cstring("Esc to resume", context.temp_allocator), 495, 520, 17, rl.Color{255, 255, 255, 255})
}

render_level_results :: proc(game: ^Game_State) {
	render_flow_panel(game, "BOOK COMPLETE")
	run := game.level_run
	total_seconds := int(run.elapsed_time)
	minutes := total_seconds / 60
	seconds := total_seconds % 60
	render_flow_text(game, strings.clone_to_cstring(LEVELS[game.active_level].name, context.temp_allocator), 420, 238, 24, rl.Color{255, 232, 173, 255})
	render_flow_text(game, strings.clone_to_cstring(fmt.aprintf("Time: %02d:%02d", minutes, seconds), context.temp_allocator), 430, 284, 21, rl.Color{255, 255, 255, 255})
	render_flow_text(game, strings.clone_to_cstring(fmt.aprintf("Damage taken: %d", run.damage_taken), context.temp_allocator), 430, 318, 21, rl.Color{255, 255, 255, 255})
	relic_status := "Secret relic: not found"
	if run.relic_collected {
		relic_status = "Secret relic: found"
	}
	render_flow_text(game, strings.clone_to_cstring(relic_status, context.temp_allocator), 430, 352, 21, rl.Color{255, 255, 255, 255})
	options := [2]string{"Return to Library", "Replay Book"}
	for i in 0..<len(options) {
		render_flow_option(game, options[i], i, game.results_choice, i32(420+i*48))
	}
}

render_flow_panel :: proc(game: ^Game_State, title: string) {
	rl.DrawRectangle(0, 0, WINDOW_WIDTH, WINDOW_HEIGHT, rl.Color{6, 8, 19, 190})
	panel := rl.Rectangle{330, 170, 620, 410}
	rl.DrawRectangleRec(panel, rl.Color{21, 17, 34, 235})
	draw_ui_nine_slice(game.assets.ui_inventory, {16, 48, 48, 48}, panel, 8, 24, rl.WHITE)
	render_flow_text(game, strings.clone_to_cstring(title, context.temp_allocator), 420, 200, 30, rl.Color{255, 232, 173, 255})
}

render_flow_option :: proc(game: ^Game_State, label: string, index, selected: int, y: i32) {
	color := rl.Color{255, 255, 255, 255}
	if selected == index {
		color = rl.Color{255, 239, 177, 255}
		render_flow_text(game, strings.clone_to_cstring(">", context.temp_allocator), 418, y, 22, color)
	}
	render_flow_text(game, strings.clone_to_cstring(label, context.temp_allocator), 448, y, 22, color)
}

render_flow_text :: proc(game: ^Game_State, text: cstring, x, y, size: i32, color: rl.Color) {
	ui_text(game.assets.ui_font, text, x+2, y+2, size, rl.Color{16, 10, 23, 255})
	ui_text(game.assets.ui_font, text, x, y, size, color)
}
